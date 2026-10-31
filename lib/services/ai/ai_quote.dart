import 'dart:convert';

import '../../domain/money/fx_rate.dart';
import '../../l10n/runtime_l10n.dart';

/// 单条 AI 抓回的价格（已映射或待映射到持仓账户）。
class FetchedPrice {
  const FetchedPrice({
    required this.query,
    required this.price,
    required this.currency,
    this.asOf,
    this.source,
    this.accountId,
    this.accountName,
    this.currencyMismatch,
  });

  final String query;
  final Rational price;

  /// AI 标注的计价币种（可能与账户币种不一致，见 [currencyMismatch]）。
  final String currency;
  final DateTime? asOf;
  final String? source;

  /// 匹配到的持仓账户（未匹配为 null，不入账）。
  final String? accountId;
  final String? accountName;
  final bool? currencyMismatch;
}

/// 单条 AI 抓回的汇率（1 单位外币 = rate 本位币）。
class FetchedRate {
  const FetchedRate({
    required this.ccy,
    required this.rate,
    this.asOf,
    this.source,
  });

  final String ccy;
  final Rational rate;
  final DateTime? asOf;
  final String? source;
}

class QuoteFetchResult {
  const QuoteFetchResult({
    required this.prices,
    required this.rates,
    required this.warnings,
  });

  final List<FetchedPrice> prices;
  final List<FetchedRate> rates;
  final List<String> warnings;

  bool get isEmpty => prices.isEmpty && rates.isEmpty;
}

/// AI 行情应答解析：容忍 markdown 围栏与前后缀说明文字；
/// 逐条校验（价格/汇率必须为正的十进制数），无效条目跳过并计入告警。
class AiQuoteParser {
  const AiQuoteParser._();

  static QuoteFetchResult parse(String content) {
    final jsonText = _extractJson(content);
    if (jsonText == null) {
      throw FormatException(rt('AI 应答中未找到 JSON 数据'));
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonText);
    } on FormatException {
      throw FormatException(rt('AI 应答 JSON 无法解析'));
    }
    if (decoded is! Map<String, Object?>) {
      throw FormatException(rt('AI 应答 JSON 不是对象'));
    }
    final warnings = <String>[];

    final prices = <FetchedPrice>[];
    final rawPrices = decoded['prices'];
    if (rawPrices is List) {
      for (final e in rawPrices) {
        if (e is! Map) continue;
        final query = e['query'] is String ? e['query'] as String : null;
        if (query == null || query.trim().isEmpty) {
          warnings.add(rt('一条价格缺少查询名，已跳过'));
          continue;
        }
        final price = _parsePositiveDecimal(e['price']);
        if (price == null) {
          warnings.add(
            '${rt('「')}$query${rt('」价格无效（')}${e['price']}${rt('），已跳过')}',
          );
          continue;
        }
        prices.add(
          FetchedPrice(
            query: query.trim(),
            price: price,
            currency: e['currency'] is String ? e['currency'] as String : '',
            asOf: _parseDate(e['as_of'] ?? e['asOf']),
            source: e['source'] is String ? e['source'] as String : null,
          ),
        );
      }
    }

    final rates = <FetchedRate>[];
    final rawRates = decoded['rates'];
    if (rawRates is List) {
      for (final e in rawRates) {
        if (e is! Map) continue;
        final pair = e['pair'] is String ? e['pair'] as String : null;
        if (pair == null || !pair.contains('/')) {
          warnings.add(rt('一条汇率缺少币种对，已跳过'));
          continue;
        }
        final ccy = pair.split('/').first.trim().toUpperCase();
        if (ccy.isEmpty) {
          warnings.add('${rt('汇率币种对格式异常（')}$pair${rt('），已跳过')}');
          continue;
        }
        final rate = _parsePositiveDecimal(e['rate']);
        if (rate == null) {
          warnings.add('$pair${rt(' 汇率无效（')}${e['rate']}${rt('），已跳过')}');
          continue;
        }
        rates.add(
          FetchedRate(
            ccy: ccy,
            rate: rate,
            asOf: _parseDate(e['as_of'] ?? e['asOf']),
            source: e['source'] is String ? e['source'] as String : null,
          ),
        );
      }
    }
    return QuoteFetchResult(prices: prices, rates: rates, warnings: warnings);
  }

  /// 提取 JSON：优先 ```json 围栏，否则首个 '{' 到与之平衡的 '}'。
  static String? _extractJson(String content) {
    final fence = RegExp(
      r'```(?:json)?\s*(\{.*?\})\s*```',
      dotAll: true,
    ).firstMatch(content);
    if (fence != null) return fence.group(1);
    final start = content.indexOf('{');
    if (start < 0) return null;
    var depth = 0;
    var inString = false;
    for (var i = start; i < content.length; i++) {
      final ch = content[i];
      if (inString) {
        if (ch == r'\' && i + 1 < content.length) {
          i++;
        } else if (ch == '"') {
          inString = false;
        }
        continue;
      }
      if (ch == '"') {
        inString = true;
      } else if (ch == '{') {
        depth++;
      } else if (ch == '}') {
        depth--;
        if (depth == 0) return content.substring(start, i + 1);
      }
    }
    return null;
  }

  static Rational? _parsePositiveDecimal(Object? raw) {
    if (raw is! String) return null;
    final s = raw.trim().replaceAll(',', '');
    if (s.isEmpty) return null;
    final Rational v;
    try {
      v = Rational.parseDecimal(s);
    } on FormatException {
      return null;
    }
    return v > Rational.zero() && !v.isNegative ? v : null;
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is! String) return null;
    final m = RegExp(
      r'^(\d{4})[-/年.](\d{1,2})[-/月.](\d{1,2})',
    ).firstMatch(raw.trim());
    if (m == null) return null;
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }
}

/// 行情抓取提示词（只含查询名与币种对，绝不含金额/余额——隐私边界）。
String buildQuotePrompt({
  required List<String> holdingNames,
  required List<String> fxPairs,
  required String baseCcy,
}) {
  final sb = StringBuffer()
    ..writeln('请使用联网搜索查询以下金融数据的最新行情（今日或最近交易日收盘）：')
    ..writeln('');
  if (holdingNames.isNotEmpty) {
    sb.writeln('一、资产价格（按名称搜索其最新单价）：');
    for (final n in holdingNames) {
      sb.writeln('- $n');
    }
  }
  if (fxPairs.isNotEmpty) {
    sb.writeln('二、汇率（每 1 单位外币兑 $baseCcy）：');
    for (final p in fxPairs) {
      sb.writeln('- $p');
    }
  }
  sb
    ..writeln('')
    ..writeln('要求：')
    ..writeln('1. 必须基于联网搜索结果，不得凭记忆编造；查不到的条目直接省略。')
    ..writeln('2. price/rate 为十进制数字字符串（不要带货币符号），rate 表示 1 单位外币 = 多少 $baseCcy。')
    ..writeln('3. as_of 为数据日期（yyyy-MM-dd），source 为信息来源网址。')
    ..writeln('4. 只输出严格 JSON（不要 markdown 围栏、不要解释），格式：')
    ..writeln(
      '{"prices":[{"query":"名称","price":"123.45","currency":"CNY","as_of":"2026-10-27","source":"https://..."}],',
    )
    ..writeln(
      ' "rates":[{"pair":"USD/$baseCcy","rate":"7.12","as_of":"2026-10-27","source":"https://..."}]}',
    );
  return sb.toString();
}
