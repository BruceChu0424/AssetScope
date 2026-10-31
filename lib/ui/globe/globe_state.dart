import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../../domain/ledger/account.dart';
import '../../l10n/runtime_l10n.dart';

/// 地球视图状态：中心经纬 + 缩放系数（纯数据，供 painter 与手势层共用）。
class GlobeView {
  GlobeView({this.lambda = 116.4, this.phi = 30.0, this.zoom = 1.0});

  /// 视野中心经度（东经为正）。中国居中默认北京。
  double lambda;

  /// 视野中心纬度（北纬为正），限制在 ±78° 避免翻转。
  double phi;

  /// 半径缩放（0.75~2.2）：1.6 以内球完整可见，更大用于"贴脸"
  /// 端详某个区域（球缘超出画布是预期效果）。
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
    // 绕 x 轴旋转 phi：把中心纬度（lat = phi）转到视野正中。
    // 符号曾写反导致南北镜像（屏幕中心实为 -phi 纬度，垂直拖拽方向颠倒）。
    final cosP = math.cos(ph);
    final sinP = math.sin(ph);
    final y1 = y0 * cosP - z0 * sinP;
    final z1 = y0 * sinP + z0 * cosP;
    if (z1 <= 0) return null;
    return Offset3D(x0 * radius, -y1 * radius, z1);
  }

  /// 反向：屏幕点 → 视野中心经纬（点击处的经纬度，用于飞行动画目标）。
  (double, double) centerFor(double lat, double lon) => (lon, lat);

  GlobeView copyWith({double? lambda, double? phi, double? zoom}) => GlobeView(
    lambda: lambda ?? this.lambda,
    phi: (phi ?? this.phi).clamp(-78.0, 78.0),
    zoom: (zoom ?? this.zoom).clamp(0.75, 2.2),
  );
}

/// 带深度的屏幕偏移。
class Offset3D {
  const Offset3D(this.dx, this.dy, this.z);
  final double dx;
  final double dy;
  final double z;
}

/// 资产标记类别：资金（现金/存款/理财/证券等可快速变现）与
/// 固定资产（房产/车辆/股权/养老金等）。决定光点配色与弹窗徽标。
enum MarkerKind { liquid, fixed }

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
    this.kind = MarkerKind.liquid,
    this.institution,
    this.subtypeLabel = '资产',
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

  /// 资产类别（光点配色）。
  final MarkerKind kind;

  /// 开户行/机构（弹窗展示，如「招商银行·上海分行」）。
  final String? institution;

  /// 子类型中文名（弹窗展示，如「银行活期」「房产」）。
  final String subtypeLabel;

  String get kindLabel => kind == MarkerKind.fixed ? rt('固定资产') : rt('资金');

  /// 资产子类型 → 光点类别。持仓/存款/现金都算资金，
  /// 只有"搬不走的"才算固定资产。
  static MarkerKind kindOf(AssetSubtype? st) => switch (st) {
    AssetSubtype.realEstate ||
    AssetSubtype.vehicle ||
    AssetSubtype.equityOwnership ||
    AssetSubtype.pension ||
    AssetSubtype.providentFund ||
    AssetSubtype.insuranceCashValue => MarkerKind.fixed,
    _ => MarkerKind.liquid,
  };

  /// 命中测试：屏幕点是否点中此标记（[screenPos] 为标记的屏幕坐标）。
  static bool hit(Offset3D projected, Offset point, double markerRadius) {
    if (projected.z <= 0) return false;
    final dx = projected.dx - point.dx;
    final dy = projected.dy - point.dy;
    return dx * dx + dy * dy <= (markerRadius + 12) * (markerRadius + 12);
  }
}

/// 标记大小（按价值开方比例，5~20px，随缩放轻度放大）。
double markerRadiusFor(BigInt value, BigInt maxValue, {double zoom = 1}) {
  if (maxValue <= BigInt.zero) return 8;
  final ratio = math
      .sqrt(value.toDouble() / maxValue.toDouble())
      .clamp(0.25, 1.0);
  // 缩放耦合系数：zoom=1 时恰为 1，放大到 2.2 时约 1.36——
  // 球变大的同时光点也稍大，但不至于糊成一片。
  final z = (0.7 + 0.3 * zoom).clamp(0.85, 1.35);
  return (5 + ratio * 15) * z;
}
