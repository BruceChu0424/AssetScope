import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/services/net/guarded_http.dart';

/// 出网 URL 守卫：仅 http/https，拒绝 localhost/环回/私有/保留地址。
void main() {
  test('公网 https / http 放行', () {
    expect(GuardedHttp.validate('https://open.bigmodel.cn/api/paas/v4/chat/completions'),
        isNotNull);
    expect(GuardedHttp.validate('http://api.example.com/v1'), isNotNull);
    expect(GuardedHttp.validate('https://api.deepseek.com/chat/completions'), isNotNull);
  });

  test('非 http(s) 协议拒绝', () {
    expect(() => GuardedHttp.validate('file:///etc/passwd'), throwsA(isA<FormatException>()));
    expect(() => GuardedHttp.validate('ftp://example.com'), throwsA(isA<FormatException>()));
    expect(() => GuardedHttp.validate('ws://example.com'), throwsA(isA<FormatException>()));
  });

  test('localhost 与本地域名拒绝', () {
    expect(() => GuardedHttp.validate('http://localhost:8080/v1'), throwsA(isA<FormatException>()));
    expect(() => GuardedHttp.validate('http://api.localhost/v1'), throwsA(isA<FormatException>()));
    expect(() => GuardedHttp.validate('http://mybox.local/v1'), throwsA(isA<FormatException>()));
  });

  test('环回与私有 IPv4 拒绝', () {
    for (final h in [
      'http://127.0.0.1/v1',
      'http://10.1.2.3/v1',
      'http://172.16.0.1/v1',
      'http://172.31.255.255/v1',
      'http://192.168.1.10/v1',
      'http://169.254.1.1/v1',
      'http://0.0.0.0/v1',
      'http://224.0.0.1/v1',
    ]) {
      expect(() => GuardedHttp.validate(h), throwsA(isA<FormatException>()),
          reason: h);
    }
  });

  test('公网 IPv4 放行', () {
    expect(GuardedHttp.validate('https://8.8.8.8/v1'), isNotNull);
    expect(GuardedHttp.validate('https://1.1.1.1/v1'), isNotNull);
  });

  test('IPv6 环回/本地链路/唯一本地/组播拒绝', () {
    for (final h in [
      'http://[::1]/v1',
      'http://[::]/v1',
      'http://[fe80::1]/v1',
      'http://[fd12::1]/v1',
      'http://[fc00::1]/v1',
      'http://[ff02::1]/v1',
    ]) {
      expect(() => GuardedHttp.validate(h), throwsA(isA<FormatException>()),
          reason: h);
    }
  });

  test('空主机拒绝', () {
    expect(() => GuardedHttp.validate('https:///v1'), throwsA(isA<FormatException>()));
  });
}
