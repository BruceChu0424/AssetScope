import 'dart:convert';

import '../../domain/money/fx_rate.dart';

/// frankfurter 汇率（欧洲央行参考汇率，开源免费无 key，每工作日更新）。
///
/// 端点：`https://api.frankfurter.dev/v1/latest?base=EUR&symbols=USD,CNY`。
/// 任意币种对经 EUR 交叉精确换算：rate(ccy→base) = rates[base] / rates[ccy]。
class FrankfurterFx {
  const FrankfurterFx._();

  static const baseUrl = 'https://api.frankfurter.dev/v1/latest';

  static Uri buildUrl(Set<String> currencies) => Uri.parse(baseUrl).replace(
      queryParameters: {
        'base': 'EUR',
        'symbols': currencies.join(','),
      });

  /// 解析 JSON，返回 币种 → 1 单位该币 = 多少 [baseCcy] 的精确汇率。
  /// 任一币种不在央行列表 → 计入 [missing]。
  static (Map<String, Rational>, DateTime?, List<String>) parse(
      String body, List<String> currencies, String baseCcy) {
    final Object decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const FormatException('frankfurter 应答不是 JSON');
    }
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('frankfurter 应答不是对象');
    }
    final rates = decoded['rates'];
    final dateRaw = decoded['date'];
    if (rates is! Map<String, Object?>) {
      throw const FormatException('frankfurter 应答缺少 rates');
    }
    final eur = <String, Rational>{};
    rates.forEach((k, v) {
      if (v is num) eur[k.toUpperCase()] = Rational.parseDecimal('$v');
    });
    final date = dateRaw is String
        ? DateTime.tryParse(dateRaw.substring(0, 10))
        : null;

    final out = <String, Rational>{};
    final missing = <String>[];
    Rational? toEur(String c) => c == 'EUR' ? Rational.one : eur[c];
    final basePerEur = toEur(baseCcy);
    if (basePerEur == null) {
      return (const {}, date, [...currencies, baseCcy]);
    }
    for (final c in currencies) {
      final perEur = toEur(c);
      if (perEur == null) {
        missing.add(c);
        continue;
      }
      // ccy→base = (EUR→base) / (EUR→ccy)。
      out[c] = basePerEur / perEur;
    }
    return (out, date, missing);
  }
}
