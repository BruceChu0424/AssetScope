
import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/services/net/guarded_http.dart';

/// 出网守卫 · 攻防对抗测试：以攻击者视角构造绕过向量，断言全部被拦。
/// 覆盖：IP 编码绕过（十进制/十六进制/八进制/超界段）、userinfo 混淆、
/// 重定向每跳校验（302 → 内网）、跨主机重定向剥离鉴权头、错误信息
/// 脱敏（恶意端点回显 Authorization 不泄漏 key）。
void main() {
  group('IP 编码绕过（对抗向量）', () {
    test('十进制 IPv4 编码拒绝（2130706433 = 127.0.0.1）', () {
      expect(() => GuardedHttp.validate('http://2130706433/v1'),
          throwsA(isA<FormatException>()));
      // 3232235777 = 192.168.1.1
      expect(() => GuardedHttp.validate('http://3232235777/v1'),
          throwsA(isA<FormatException>()));
      // 2852039166 = 169.254.169.254（云元数据）
      expect(() => GuardedHttp.validate('http://2852039166/latest/meta'),
          throwsA(isA<FormatException>()));
    });

    test('十六进制/八进制段拒绝', () {
      expect(() => GuardedHttp.validate('http://0x7f.0.0.1/v1'),
          throwsA(isA<FormatException>()));
      expect(() => GuardedHttp.validate('http://0177.0.0.1/v1'),
          throwsA(isA<FormatException>()));
      expect(() => GuardedHttp.validate('http://127.0x0.0.1/v1'),
          throwsA(isA<FormatException>()));
    });

    test('超界段拒绝（999.1.1.1）', () {
      expect(() => GuardedHttp.validate('http://999.1.1.1/v1'),
          throwsA(isA<FormatException>()));
      expect(() => GuardedHttp.validate('http://1.2.3.999/v1'),
          throwsA(isA<FormatException>()));
    });

    test('正常点分公网 IPv4 不误伤', () {
      expect(GuardedHttp.validate('https://8.8.8.8/v1'), isNotNull);
      expect(GuardedHttp.validate('https://110.242.68.66/v1'), isNotNull);
    });

    test('正常域名不误伤（含纯数字子域）', () {
      expect(GuardedHttp.validate('https://open.bigmodel.cn/v4'), isNotNull);
      expect(GuardedHttp.validate('https://12306.cn/api'), isNotNull);
    });

    test('userinfo 混淆拒绝（http://good.com@127.0.0.1）', () {
      expect(() => GuardedHttp.validate('http://expected.com@127.0.0.1/v1'),
          throwsA(isA<FormatException>()));
      expect(() => GuardedHttp.validate('http://u:p@10.0.0.5/v1'),
          throwsA(isA<FormatException>()));
    });
  });

  group('错误信息脱敏（对抗：恶意端点回显密钥）', () {
    test('error.message 中包含 Authorization 值时被替换为 ***', () {
      const key = 'sk-live-abcdef1234567890secret';
      final body = '{"error":{"code":"401","message":"bad key $key"}}';
      final out = GuardedHttp.errorDetail(body, {
        'Authorization': 'Bearer $key',
        'Accept': 'application/json',
      });
      expect(out.contains(key), isFalse, reason: '密钥不得出现在错误文本');
      expect(out.contains('***'), isTrue);
      expect(out.contains('bad key'), isTrue);
    });

    test('非 JSON 错误体同样脱敏', () {
      const key = 'zheshi-yige-henchang-demiyao';
      final out = GuardedHttp.errorDetail('echo back: Bearer $key', {
        'Authorization': 'Bearer $key',
      });
      expect(out.contains(key), isFalse);
    });

    test('无敏感回显时保留原始可读信息', () {
      final out = GuardedHttp.errorDetail(
        '{"error":{"message":"模型不存在：glm-4-flash"}}',
      );
      expect(out, '模型不存在：glm-4-flash');
    });

    test('超长错误体截断到 300 字符', () {
      final out = GuardedHttp.errorDetail('x' * 1000);
      expect(out.length, 300);
    });
  });

  group('重定向与鉴权头（对抗：302 → 内网 / key 中继）', () {
    // 守卫的唯一入口是 validate；_open 对每一跳（含重定向 Location 的
    // resolve 结果）都调用它，因此重定向目标的拦截与下列断言同源。
    test('重定向可能出现的内网/元数据目标全部在守卫黑名单内', () {
      for (final h in [
        'http://169.254.169.254/latest/meta-data/', // 云元数据
        'http://metadata.google.internal/',
        'http://127.0.0.1:8080/',
        'http://[::1]:9000/',
        'http://2852039166/latest/meta', // 十进制编码的 169.254.169.254
      ]) {
        expect(() => GuardedHttp.validate(h), throwsA(isA<FormatException>()),
            reason: h);
      }
    });

    test('跨主机跳转剥离的鉴权头名单（两种协议鉴权）', () {
      expect(GuardedHttp.isAuthHeader('Authorization'), isTrue);
      expect(GuardedHttp.isAuthHeader('authorization'), isTrue);
      expect(GuardedHttp.isAuthHeader('x-api-key'), isTrue);
      expect(GuardedHttp.isAuthHeader('X-API-KEY'), isTrue);
      // 非鉴权头不误伤（Content-Type / Accept 需随跳保留）。
      expect(GuardedHttp.isAuthHeader('Content-Type'), isFalse);
      expect(GuardedHttp.isAuthHeader('Accept'), isFalse);
      expect(GuardedHttp.isAuthHeader('anthropic-version'), isFalse);
    });
  });
}
