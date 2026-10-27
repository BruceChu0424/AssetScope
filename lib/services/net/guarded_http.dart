import 'dart:convert';
import 'dart:io';

/// 出网请求守卫与共用 JSON POST 客户端。
///
/// 安全约束（docs/06）：对外请求仅允许 http/https，且目标主机
/// 不得是 localhost、环回、私有、链路本地或保留地址（防 SSRF/内网探测）。
/// AI 服务地址允许用户自定义，因此每次请求前都必须过 [validate]。
class GuardedHttp {
  GuardedHttp._();

  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);

  /// 校验 URL；不合法抛 [FormatException]，合法返回解析后的 [Uri]。
  static Uri validate(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('URL 不合法');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw FormatException('仅允许 http/https，当前：${uri.scheme}');
    }
    final host = uri.host.toLowerCase();
    if (host == 'localhost' ||
        host.endsWith('.localhost') ||
        host.endsWith('.local') ||
        host == '0.0.0.0') {
      throw const FormatException('不允许访问本机/本地域名');
    }
    if (_isPrivateIpv4(host)) {
      throw const FormatException('不允许访问私有/保留 IPv4 地址');
    }
    if (_isBlockedIpv6(host)) {
      throw const FormatException('不允许访问环回/本地/组播 IPv6 地址');
    }
    return uri;
  }

  static bool _isPrivateIpv4(String host) {
    final parts = host.split('.');
    if (parts.length != 4) return false;
    final octets = <int>[];
    for (final p in parts) {
      final v = int.tryParse(p);
      if (v == null || v < 0 || v > 255) return false; // 不是 IPv4 字面量
      octets.add(v);
    }
    final a = octets[0], b = octets[1];
    if (a == 0 || a == 10 || a == 127) return true;
    if (a == 169 && b == 254) return true; // 链路本地
    if (a == 172 && b >= 16 && b <= 31) return true;
    if (a == 192 && b == 168) return true;
    if (a >= 224) return true; // 组播 + 保留段
    return false;
  }

  static bool _isBlockedIpv6(String host) {
    if (!host.contains(':')) return false;
    var h = host.replaceAll('[', '').replaceAll(']', '').toLowerCase();
    // IPv4-mapped：按内嵌 IPv4 判定
    final lastColon = h.lastIndexOf(':');
    final tail = lastColon >= 0 ? h.substring(lastColon + 1) : '';
    if (tail.contains('.') && _isPrivateIpv4(tail)) return true;
    if (tail.contains('.')) return false; // 公网 mapped 按外层继续判
    if (h == '::1' || h == '::') return true;
    final first = h.split(':').first;
    if (first.isEmpty) return false;
    final v = int.tryParse(first, radix: 16);
    if (v == null) return false;
    if ((v & 0xfe00) == 0xfc00) return true; // fc00::/7 唯一本地
    if ((v & 0xffc0) == 0xfe80) return true; // fe80::/10 链路本地
    if ((v & 0xff00) == 0xff00) return true; // ff00::/8 组播
    return false;
  }

  /// POST JSON 并解码响应。非 2xx 抛 [HttpException]（附状态码与响应摘录，
  /// 摘录不含请求头，密钥永不进入异常信息）。
  static Future<Map<String, Object?>> postJson(
    String url, {
    Map<String, String> headers = const {},
    Object? body,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final uri = validate(url);
    final req = await _client.postUrl(uri)
      ..followRedirects = true;
    headers.forEach(req.headers.set);
    req.headers.contentType = ContentType.json;
    if (body != null) req.write(jsonEncode(body));
    final res = await req.close().timeout(timeout);
    final text = await res.transform(utf8.decoder).join();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException(
          'HTTP ${res.statusCode}：${text.length > 300 ? text.substring(0, 300) : text}');
    }
    final decoded = jsonDecode(text);
    if (decoded is Map<String, Object?>) return decoded;
    throw const FormatException('响应不是 JSON 对象');
  }
}
