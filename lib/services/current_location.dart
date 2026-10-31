import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../ui/globe/city_locations.dart';

/// 当前位置定位结果。
class CurrentLocation {
  const CurrentLocation({
    required this.lat,
    required this.lon,
    required this.placeName,
    required this.exact,
  });

  final double lat;
  final double lon;

  /// 展示用的地名（精确=系统反解或城市表，估计=最近城市名）。
  final String placeName;

  /// true = 系统定位服务给出的真实坐标；false = 按本地时区估计。
  final bool exact;
}

/// 定位当前位置：Windows 定位服务优先（6s 超时，失败/禁用静默降级），
/// 兜底按本地时区推算经度、取城市表中最近城市——地球是示意性可视化
/// （WGS84 近似），估计档足以满足「飞到我所在的位置」。
Future<CurrentLocation> locateCurrent() async {
  try {
    final service = await Geolocator.isLocationServiceEnabled();
    if (service) {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final asked = await Geolocator.requestPermission();
        if (asked == LocationPermission.denied ||
            asked == LocationPermission.deniedForever) {
          throw const LocationServiceDisabledException();
        }
      } else if (permission == LocationPermission.deniedForever) {
        throw const LocationServiceDisabledException();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 6),
        ),
      );
      final name = _nearestCity(pos.latitude, pos.longitude);
      return CurrentLocation(
        lat: pos.latitude,
        lon: pos.longitude,
        placeName: name,
        exact: true,
      );
    }
  } catch (_) {
    // 定位服务不可用/超时/被拒：落到时区估计。
  }
  return _estimateFromTimeZone();
}

/// 时区估计：经度 ≈ UTC 偏移小时 × 15°，取城市表里经度最近的城市
/// （纬度无信号，用最近城市补全）；中国 UTC+8 → 上海一带，误差可
/// 接受——按钮的语义是「地球飞到我这里」，不是测绘。
CurrentLocation _estimateFromTimeZone() {
  final offsetHours =
      DateTime.now().timeZoneOffset.inMinutes / 60.0;
  final lon = (offsetHours * 15.0).clamp(-180.0, 180.0);
  final city = _nearestCityEntry(null, lon);
  return CurrentLocation(
    lat: city.lat,
    lon: city.lon,
    placeName: city.name,
    exact: false,
  );
}

String _nearestCity(double lat, double lon) =>
    _nearestCityEntry(lat, lon).name;

/// 城市表中最近者：经差按球面最短 wraps；lat 为 null 时只按经度。
CityLocation _nearestCityEntry(double? lat, double lon) {
  CityLocation best = kCityLocations.first;
  var bestD = double.infinity;
  for (final c in kCityLocations) {
    var dLon = (c.lon - lon).abs();
    if (dLon > 180) dLon = 360 - dLon;
    final d = lat == null ? dLon : dLon * dLon + math.pow(c.lat - lat, 2);
    if (d < bestD) {
      bestD = d;
      best = c;
    }
  }
  return best;
}
