import '../../l10n/runtime_l10n.dart';

/// 内置城市坐标（国内主要城市 + 常见海外城市）。
/// 数据为 WGS84 近似坐标，仅供 3D 地球示意定位，不做导航用途。
class CityLocation {
  const CityLocation(this.name, this.lat, this.lon);
  final String name;
  final double lat;
  final double lon;
}

/// 城市名按当前语言返回（英文译名见 lib/l10n/runtime_map.dart）。
List<CityLocation> get kCityLocations => <CityLocation>[
  CityLocation(rt('北京'), 39.9, 116.4),
  CityLocation(rt('上海'), 31.2, 121.5),
  CityLocation(rt('广州'), 23.1, 113.3),
  CityLocation(rt('深圳'), 22.5, 114.1),
  CityLocation(rt('杭州'), 30.3, 120.2),
  CityLocation(rt('成都'), 30.6, 104.1),
  CityLocation(rt('重庆'), 29.6, 106.5),
  CityLocation(rt('武汉'), 30.6, 114.3),
  CityLocation(rt('西安'), 34.3, 108.9),
  CityLocation(rt('南京'), 32.1, 118.8),
  CityLocation(rt('苏州'), 31.3, 120.6),
  CityLocation(rt('天津'), 39.1, 117.2),
  CityLocation(rt('长沙'), 28.2, 112.9),
  CityLocation(rt('郑州'), 34.7, 113.6),
  CityLocation(rt('青岛'), 36.1, 120.4),
  CityLocation(rt('大连'), 38.9, 121.6),
  CityLocation(rt('厦门'), 24.5, 118.1),
  CityLocation(rt('福州'), 26.1, 119.3),
  CityLocation(rt('合肥'), 31.8, 117.3),
  CityLocation(rt('济南'), 36.7, 117.0),
  CityLocation(rt('沈阳'), 41.8, 123.4),
  CityLocation(rt('哈尔滨'), 45.8, 126.5),
  CityLocation(rt('昆明'), 25.0, 102.7),
  CityLocation(rt('贵阳'), 26.6, 106.6),
  CityLocation(rt('南宁'), 22.8, 108.3),
  CityLocation(rt('兰州'), 36.1, 103.8),
  CityLocation(rt('乌鲁木齐'), 43.8, 87.6),
  CityLocation(rt('拉萨'), 29.7, 91.1),
  CityLocation(rt('呼和浩特'), 40.8, 111.7),
  CityLocation(rt('石家庄'), 38.0, 114.5),
  CityLocation(rt('太原'), 37.9, 112.5),
  CityLocation(rt('南昌'), 28.7, 115.9),
  CityLocation(rt('无锡'), 31.6, 120.3),
  CityLocation(rt('宁波'), 29.9, 121.5),
  CityLocation(rt('佛山'), 23.0, 113.1),
  CityLocation(rt('东莞'), 23.0, 113.7),
  CityLocation(rt('珠海'), 22.3, 113.6),
  CityLocation(rt('海口'), 20.0, 110.3),
  CityLocation(rt('三亚'), 18.3, 109.5),
  CityLocation(rt('香港'), 22.3, 114.2),
  CityLocation(rt('澳门'), 22.2, 113.5),
  CityLocation(rt('台北'), 25.0, 121.6),
  CityLocation(rt('东京'), 35.7, 139.7),
  CityLocation(rt('首尔'), 37.6, 127.0),
  CityLocation(rt('新加坡'), 1.35, 103.8),
  CityLocation(rt('曼谷'), 13.8, 100.5),
  CityLocation(rt('伦敦'), 51.5, -0.13),
  CityLocation(rt('巴黎'), 48.9, 2.35),
  CityLocation(rt('法兰克福'), 50.1, 8.68),
  CityLocation(rt('纽约'), 40.7, -74.0),
  CityLocation(rt('洛杉矶'), 34.05, -118.2),
  CityLocation(rt('旧金山'), 37.8, -122.4),
  CityLocation(rt('西雅图'), 47.6, -122.3),
  CityLocation(rt('多伦多'), 43.65, -79.4),
  CityLocation(rt('悉尼'), -33.9, 151.2),
  CityLocation(rt('墨尔本'), -37.8, 145.0),
  CityLocation(rt('奥克兰'), -36.85, 174.8),
];
