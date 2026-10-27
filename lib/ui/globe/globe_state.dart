import 'dart:math' as math;
import 'dart:ui' show Offset;

/// 地球视图状态：中心经纬 + 缩放系数（纯数据，供 painter 与手势层共用）。
class GlobeView {
  GlobeView({
    this.lambda = 116.4,
    this.phi = 30.0,
    this.zoom = 1.0,
  });

  /// 视野中心经度（东经为正）。中国居中默认北京。
  double lambda;

  /// 视野中心纬度（北纬为正），限制在 ±78° 避免翻转。
  double phi;

  /// 半径缩放（0.75~1.6）。
  double zoom;

  static const _deg = math.pi / 180;

  /// 正交投影：经纬度 → 屏幕偏移与深度 z（>0 可见）。
  /// 返回 null 表示在背面。
  Offset3D? project(double lat, double lon, double radius) {
    final lt = lat * _deg;
    final ln = lon * _deg;
    final la = lambda * _deg;
    final ph = phi * _deg;
    // 球面坐标（y 上、z 朝观察者）。
    final x0 = math.cos(lt) * math.sin(ln - la);
    final y0 = math.sin(lt);
    final z0 = math.cos(lt) * math.cos(ln - la);
    // 绕 x 轴旋转 -phi：把中心纬度转到视野中心。
    final cosP = math.cos(ph);
    final sinP = math.sin(ph);
    final y1 = y0 * cosP + z0 * sinP;
    final z1 = -y0 * sinP + z0 * cosP;
    if (z1 <= 0) return null;
    return Offset3D(x0 * radius, -y1 * radius, z1);
  }

  /// 反向：屏幕点 → 视野中心经纬（点击处的经纬度，用于飞行动画目标）。
  (double, double) centerFor(double lat, double lon) => (lon, lat);

  GlobeView copyWith({double? lambda, double? phi, double? zoom}) => GlobeView(
        lambda: lambda ?? this.lambda,
        phi: (phi ?? this.phi).clamp(-78.0, 78.0),
        zoom: (zoom ?? this.zoom).clamp(0.75, 1.6),
      );
}

/// 带深度的屏幕偏移。
class Offset3D {
  const Offset3D(this.dx, this.dy, this.z);
  final double dx;
  final double dy;
  final double z;
}

/// 地球上的资产标记。
class GlobeMarker {
  const GlobeMarker({
    required this.accountId,
    required this.name,
    required this.lat,
    required this.lon,
    required this.valueBaseMinor,
    required this.currencyCode,
    this.locationName,
    this.valuationMissing = false,
  });

  final String accountId;
  final String name;
  final double lat;
  final double lon;

  /// 本位币价值（决定标记大小）。
  final BigInt valueBaseMinor;
  final String currencyCode;
  final String? locationName;
  final bool valuationMissing;

  /// 命中测试：屏幕点是否点中此标记（[screenPos] 为标记的屏幕坐标）。
  static bool hit(Offset3D projected, Offset point, double markerRadius) {
    if (projected.z <= 0) return false;
    final dx = projected.dx - point.dx;
    final dy = projected.dy - point.dy;
    return dx * dx + dy * dy <= (markerRadius + 12) * (markerRadius + 12);
  }
}

/// 标记大小（按价值开方比例，4~20px）。
double markerRadiusFor(BigInt value, BigInt maxValue) {
  if (maxValue <= BigInt.zero) return 8;
  final ratio =
      math.sqrt(value.toDouble() / maxValue.toDouble()).clamp(0.25, 1.0);
  return 5 + ratio * 15;
}
