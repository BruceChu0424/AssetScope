import 'package:fast_gbk/fast_gbk.dart';

import '../../domain/money/fx_rate.dart';

/// 腾讯行情（A股/场内基金，免费无 key，国内直连）。
///
/// 端点：`https://qt.gtimg.cn/q=sh600519,sz000001`（GBK 编码文本）。
/// 行格式：`v_sh600519="1~贵州茅台~600519~现价~昨收~今开~…~yyyymmddHHMMSS~…"`。
/// 现价（停牌为 0）回退昨收；两者皆 0 视为无效。
class TencentQuote {
  const TencentQuote({
    required this.symbol,
    required this.name,
    required this.price,
    this.asOf,
  });

  final String symbol;
  final String name;
  final Rational price;
  final DateTime? asOf;
}

class TencentSource {
  const TencentSource._();

  static const baseUrl = 'https://qt.gtimg.cn/q=';

  static Uri buildUrl(List<String> tencentSymbols) =>
      Uri.parse('$baseUrl${tencentSymbols.join(',')}');

  /// 解析 GBK 字节流；无法解析的行跳过并返回于 [failed]。
  static (List<TencentQuote>, List<String>) parse(
    List<int> gbkBytes,
    List<String> expected,
  ) {
    final text = gbk.decode(gbkBytes);
    final bySymbol = <String, List<String>>{};
    for (final line in text.split('\n')) {
      final m = RegExp(r'v_([a-z]{2}\d{6})="([^"]*)"').firstMatch(line.trim());
      if (m == null) continue;
      bySymbol[m.group(1)!] = m.group(2)!.split('~');
    }
    final out = <TencentQuote>[];
    final failed = <String>[];
    for (final sym in expected) {
      final f = bySymbol[sym];
      if (f == null || f.length < 31) {
        failed.add(sym);
        continue;
      }
      final price = _positive(f[3]);
      final prevClose = _positive(f[4]);
      final effective = price ?? prevClose;
      if (effective == null) {
        failed.add(sym);
        continue;
      }
      out.add(
        TencentQuote(
          symbol: sym,
          name: f.length > 1 ? f[1] : sym,
          price: effective,
          asOf: _parseStamp(f[30]),
        ),
      );
    }
    return (out, failed);
  }

  static Rational? _positive(String s) {
    final t = s.trim();
    if (t.isEmpty || t == '0.00' || t == '0') return null;
    try {
      final v = Rational.parseDecimal(t);
      return v > Rational.zero() ? v : null;
    } on FormatException {
      return null;
    }
  }

  /// yyyymmdd[HHMMSS]（港股/美股格式不同，本源只用 A股）。
  static DateTime? _parseStamp(String s) {
    final m = RegExp(
      r'^(\d{4})(\d{2})(\d{2})(\d{2})?(\d{2})?(\d{2})?',
    ).firstMatch(s.trim());
    if (m == null) return null;
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
      int.parse(m.group(4) ?? '0'),
      int.parse(m.group(5) ?? '0'),
    );
  }
}
