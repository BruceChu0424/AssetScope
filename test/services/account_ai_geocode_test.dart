import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/services/ai/account_ai_service.dart';

/// AI 地理编码解析：地址 → 精确坐标（WGS84）。
void main() {
  test('正常解析：POI 级坐标 + 规范化地址', () {
    final g = parseGeocode(
      '{"formatted":"上海市浦东新区前滩某小区 3 号楼","city":"上海",'
      '"lat":31.1839,"lon":121.4756,"precision":"poi"}',
    );
    expect(g.formatted, contains('前滩'));
    expect(g.city, '上海');
    expect(g.lat, closeTo(31.18, 0.01));
    expect(g.lon, closeTo(121.47, 0.01));
    expect(g.precision, 'poi');
  });

  test('城市级近似（precision=city）', () {
    final g = parseGeocode(
      '{"formatted":"浙江省杭州市","city":"杭州","lat":30.27,"lon":120.15,'
      '"precision":"city"}',
    );
    expect(g.precision, 'city');
  });

  test('markdown 围栏与说明文字混杂也能解出', () {
    final g = parseGeocode(
      '好的，结果如下：\n```json\n{"formatted":"北京朝阳区某小区",'
      '"lat":39.92,"lon":116.46,"precision":"poi"}\n```',
    );
    expect(g.lat, closeTo(39.92, 0.001));
  });

  test('error 标记抛 FormatException', () {
    expect(
      () => parseGeocode('{"error":"无法识别"}'),
      throwsA(isA<FormatException>()),
    );
  });

  test('坐标越界/字符串数字', () {
    expect(
      () => parseGeocode('{"formatted":"x","lat":95.0,"lon":116.0}'),
      throwsFormatException,
    );
    // 字符串数字可解（部分模型爱加引号）。
    final g = parseGeocode(
      '{"formatted":"x","lat":"39.9","lon":"116.4","precision":"poi"}',
    );
    expect(g.lat, closeTo(39.9, 0.001));
  });

  test('prompt 含地址与 JSON 格式约定', () {
    final p = buildGeocodePrompt('上海浦东前滩某小区 3 号楼 502');
    expect(p, contains('上海浦东前滩某小区 3 号楼 502'));
    expect(p, contains('WGS84'));
    expect(p, contains('precision'));
  });
}
