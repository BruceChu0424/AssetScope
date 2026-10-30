import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show BytesBuilder;

import 'package:meta/meta.dart';

/// 出网请求守卫与共用 JSON POST 客户端。
///
/// 安全约束（docs/06）：对外请求仅允许 http/https，且目标主机
/// 不得是 localhost、环回、私有、链路本地或保留地址（防 SSRF/内网探测）。
/// AI 服务地址允许用户自定义，因此**每一跳**（含重定向）都必须过
/// [validate]——攻击者可让公网端点 302 跳内网/云元数据地址绕过首跳
/// 校验；跨主机重定向还会剥离鉴权头（防 key 被中继到第三方）。
/// 异常文本只含状态码与响应体摘录，且对请求头值脱敏（防恶意端点
/// 回显 Authorization 头把 key 泄漏进错误提示/日志）。
class GuardedHttp {
  GuardedHttp._();

  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);

  /// 手动跟随重定向的上限。
  static const int _maxRedirects = 5;

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
        host.endsWith('.internal') || // 云元数据内网域（AWS/GCP metadata.*）
        host == '0.0.0.0') {
      throw const FormatException('不允许访问本机/本地域名');
    }
    if (_isSuspiciousHost(host)) {
      throw const FormatException('不允许访问疑似 IP 编码的主机名');
    }
    if (_isPrivateIpv4(host)) {
      throw const FormatException('不允许访问私有/保留 IPv4 地址');
    }
    if (_isBlockedIpv6(host)) {
      throw const FormatException('不允许访问环回/本地/组播 IPv6 地址');
    }
    return uri;
  }

  /// 对抗 IP 编码绕过：纯数字主机（十进制 IPv4，如 2130706433 =
  /// 127.0.0.1）、十六进制段（0x7f.0.0.1）、八进制段（0177.0.0.1）、
  /// 超界段（999.1.1.1）——点分四段一律要求每段为 1–3 位纯十进制且
  /// ≤255，否则整体拒绝（而非当作普通域名放行）。
  static bool _isSuspiciousHost(String host) {
    // 整段纯数字：十进制 IPv4 编码（真实域名不可能整串纯数字）。
    if (RegExp(r'^\d{1,10}$').hasMatch(host)) return true;
    final parts = host.split('.');
    if (parts.length != 4) return false;
    for (final p in parts) {
      if (!RegExp(r'^\d{1,3}$').hasMatch(p)) return true; // 0x7f / 0177 等
      final v = int.parse(p);
      if (v > 255) return true; // 999.1.1.1
    }
    return false;
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

  /// 错误体摘录 → 可展示文本：优先取 `error.message`；并对请求头值
  /// 脱敏（恶意端点可能回显 Authorization 头——key 绝不能进 UI/日志）。
  @visibleForTesting
  static String errorDetail(String body, [Map<String, String> headers = const {}]) {
    var detail = body.length > 300 ? body.substring(0, 300) : body;
    try {
      final j = jsonDecode(body);
      if (j is Map<String, Object?>) {
        final err = j['error'];
        if (err is Map && err['message'] is String) {
          detail = err['message'] as String;
        }
      }
    } catch (_) {}
    for (final e in headers.entries) {
      final v = e.value;
      // 只脱敏有意义的秘密值（过短的值如 Accept 不必处理）。
      if (v.length >= 8 && detail.contains(v)) {
        detail = detail.replaceAll(v, '***');
      }
      // 鉴权头额外脱敏裸 token（恶意端点可能只回显 'Bearer ' 后面的
      // key 本体，不带前缀）。
      if (isAuthHeader(e.key)) {
        final token = v.startsWith('Bearer ') ? v.substring(7) : v;
        if (token.length >= 8 && detail.contains(token)) {
          detail = detail.replaceAll(token, '***');
        }
      }
    }
    return detail;
  }

  /// 发起请求并手动跟随重定向：每一跳都过 [validate]；跨主机跳转剥离
  /// 鉴权头；303 转 GET、307/308 保原方法重发请求体；超上限抛异常。
  static Future<HttpClientResponse> _open(
    String method,
    Uri uri, {
    Map<String, String> headers = const {},
    String? body,
    Duration timeout = const Duration(seconds: 20),
    int hop = 0,
  }) async {
    final req = method == 'POST'
        ? await _client.postUrl(uri)
        : await _client.getUrl(uri);
    req.followRedirects = false;
    for (final e in headers.entries) {
      req.headers.set(e.key, e.value);
    }
    if (body != null) {
      req.headers.contentType = ContentType.json;
      req.write(body);
    }
    final res = await req.close().timeout(timeout);
    final status = res.statusCode;
    final isRedirect = status == 301 ||
        status == 302 ||
        status == 303 ||
        status == 307 ||
        status == 308;
    if (!isRedirect) return res;
    if (hop >= _maxRedirects) {
      await res.drain<void>();
      throw const HttpException('重定向次数过多');
    }
    final loc = res.headers.value(HttpHeaders.locationHeader);
    if (loc == null) return res; // 无 Location：按普通响应交给状态码处理
    final next = validate(uri.resolve(loc).toString()); // 每跳守卫
    // 跨主机：剥离鉴权头（防 key 被中继到第三方主机）。
    var nextHeaders = headers;
    if (next.host != uri.host) {
      nextHeaders = {
        for (final e in headers.entries)
          if (!isAuthHeader(e.key)) e.key: e.value,
      };
    }
    await res.drain<void>().catchError((_) {});
    // 301/302/303 → GET（历史语义，丢体）；307/308 → 原方法原体重发。
    final keepBody = status == 307 || status == 308;
    final nextMethod = keepBody && method == 'POST' ? 'POST' : 'GET';
    return _open(
      nextMethod,
      next,
      headers: nextHeaders,
      body: keepBody ? body : null,
      timeout: timeout,
      hop: hop + 1,
    );
  }

  @visibleForTesting
  static bool isAuthHeader(String name) {
    final n = name.toLowerCase();
    return n == 'authorization' || n == 'x-api-key';
  }

  /// GET 并返回原始响应字节（行情源 GBK/CSV/JSON 多编码，由调用方解码）。
  /// 非 2xx 抛 [HttpException]。
  static Future<List<int>> getBytes(
    String url, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final uri = validate(url);
    final res = await _open('GET', uri, headers: headers, timeout: timeout);
    final builder = BytesBuilder(copy: false);
    await for (final chunk in res) {
      builder.add(chunk);
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException('HTTP ${res.statusCode}');
    }
    return builder.takeBytes();
  }

  /// POST JSON 并解码响应。非 2xx 抛 [HttpException]（附状态码与脱敏的
  /// 响应摘录，密钥永不进入异常信息）。
  static Future<Map<String, Object?>> postJson(
    String url, {
    Map<String, String> headers = const {},
    Object? body,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final uri = validate(url);
    final encoded = body == null ? null : jsonEncode(body);
    final res = await _open(
      'POST',
      uri,
      headers: headers,
      body: encoded,
      timeout: timeout,
    );
    final text = await res.transform(utf8.decoder).join();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException(
        'HTTP ${res.statusCode}：${errorDetail(text, headers)}',
      );
    }
    final decoded = jsonDecode(text);
    if (decoded is Map<String, Object?>) return decoded;
    throw const FormatException('响应不是 JSON 对象');
  }
}
