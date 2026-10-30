import 'dart:convert';

import '../../domain/money/fx_rate.dart';

/// stooq 行情（港股/美股/国际，免费无 key，CSV）。
///
/// 端点：`https://stooq.com/q/l/?s=0700.hk,aapl.us&f=sd2t2ohlcv&h&e=csv`。
/// 行格式：`Symbol,Date,Time,Open,High,Low,Close,Volume`；
/// 无数据行值为 `N/D`。
class StooqQuote {
  const StooqQuote({required this.symbol, required this.price, this.asOf});

  final String symbol;
  final Rational price;
  final DateTime? asOf;
}

class StooqSource {
  const StooqSource._();

  static const baseUrl = 'https://stooq.com/q/l/';

  static Uri buildUrl(List<String> stooqSymbols) =>
      Uri.parse('$baseUrl?s=${stooqSymbols.join(',')}&f=sd2t2ohlcv&h&e=csv');

  static (List<StooqQuote>, List<String>) parse(
    String csv,
    List<String> expected,
  ) {
    final lines = const LineSplitter().convert(csv);
    if (lines.isEmpty) return (const [], expected);
    final bySymbol = <String, List<String>>{};
    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final cols = line.split(',');
      if (cols.length < 7) continue;
      bySymbol[cols[0].trim().toLowerCase()] = cols;
    }
    final out = <StooqQuote>[];
    final failed = <String>[];
    for (final sym in expected) {
      final cols = bySymbol[sym.toLowerCase()];
      final close = cols == null ? null : _positive(cols[6]);
      if (close == null) {
        failed.add(sym);
        continue;
      }
      out.add(
        StooqQuote(
          symbol: sym,
          price: close,
          asOf: _parseDate(
            cols![1].trim(),
            cols.length > 2 ? cols[2].trim() : '',
          ),
        ),
      );
    }
    return (out, failed);
  }

  static Rational? _positive(String s) {
    final t = s.trim();
    if (t.isEmpty || t.toUpperCase() == 'N/D') return null;
    try {
      final v = Rational.parseDecimal(t);
      return v > Rational.zero() ? v : null;
    } on FormatException {
      return null;
    }
  }

  /// Date: yyyy-MM-dd，Time: HH:mm:ss。
  static DateTime? _parseDate(String date, String time) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(date);
    if (m == null) return null;
    final t = RegExp(r'^(\d{2}):(\d{2})').firstMatch(time);
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
      t == null ? 0 : int.parse(t.group(1)!),
      t == null ? 0 : int.parse(t.group(2)!),
    );
  }
}
