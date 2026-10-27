import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/domain/money/fx_rate.dart';
import 'package:assetscope/services/ai/ai_quote.dart';

/// AI 行情应答解析：JSON 提取、校验、无效条目跳过。
void main() {
  test('裸 JSON 与 markdown 围栏 JSON 都能解析', () {
    const bare = '{"prices":[],"rates":[]}';
    expect(AiQuoteParser.parse(bare).prices, isEmpty);
    const fenced =
        '好的，以下是查询结果：\n```json\n{"prices":[{"query":"沪深300ETF","price":"3.852","currency":"CNY","as_of":"2026-10-24","source":"https://x"}],"rates":[{"pair":"USD/CNY","rate":"7.12","as_of":"2026-10-24","source":"https://y"}]}\n```';
    final r = AiQuoteParser.parse(fenced);
    expect(r.prices.single.price, Rational.parseDecimal('3.852'));
    expect(r.rates.single.rate, Rational.parseDecimal('7.12'));
    expect(r.prices.single.asOf, DateTime(2026, 10, 24));
  });

  test('价格与汇率校验：非正数/非数字/缺失跳过并计入告警', () {
    const content = '''
{
  "prices": [
    {"query": "A", "price": "12.5", "currency": "CNY"},
    {"query": "B", "price": "-3", "currency": "CNY"},
    {"query": "C", "price": "abc", "currency": "CNY"},
    {"query": "D"}
  ],
  "rates": [
    {"pair": "USD/CNY", "rate": "7.1"},
    {"pair": "EUR/CNY", "rate": "0"},
    {"pair": "JPY/CNY", "rate": "not-a-number"}
  ]
}
''';
    final r = AiQuoteParser.parse(content);
    expect(r.prices, hasLength(1));
    expect(r.prices.single.query, 'A');
    expect(r.rates, hasLength(1));
    expect(r.rates.single.ccy, 'USD');
    expect(r.warnings, hasLength(5));
  });

  test('千分位与斜杠日期可解析', () {
    const content =
        '{"prices":[{"query":"X","price":"1,852.00","currency":"CNY","as_of":"2026/10/24"}],"rates":[]}';
    final r = AiQuoteParser.parse(content);
    expect(r.prices.single.price, Rational.parseDecimal('1852.00'));
    expect(r.prices.single.asOf, DateTime(2026, 10, 24));
  });

  test('无 JSON 或结构不符时抛 FormatException', () {
    expect(() => AiQuoteParser.parse('抱歉我无法查询'),
        throwsA(isA<FormatException>()));
    expect(() => AiQuoteParser.parse('[1,2,3]'),
        throwsA(isA<FormatException>()));
  });

  test('行情提示词包含查询目标且不含金额', () {
    final prompt = buildQuotePrompt(
      holdingNames: const ['沪深300ETF', '贵州茅台'],
      fxPairs: const ['USD/CNY'],
      baseCcy: 'CNY',
    );
    expect(prompt, contains('沪深300ETF'));
    expect(prompt, contains('USD/CNY'));
    expect(prompt, contains('严格 JSON'));
    expect(prompt, contains('CNY'));
  });
}
