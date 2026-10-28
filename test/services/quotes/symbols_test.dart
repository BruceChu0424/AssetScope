import 'package:flutter_test/flutter_test.dart';
import 'package:assetscope/services/quotes/symbols.dart';

void main() {
  test('A 股 6 位数字按首位推断交易所', () {
    expect(SymbolResolver.resolve('600519').tencentSymbol, 'sh600519');
    expect(SymbolResolver.resolve('000001').tencentSymbol, 'sz000001');
    expect(SymbolResolver.resolve('300750').tencentSymbol, 'sz300750');
    expect(SymbolResolver.resolve('510300').tencentSymbol, 'sh510300');
    expect(SymbolResolver.resolve('159915').tencentSymbol, 'sz159915');
    expect(SymbolResolver.resolve('832566').tencentSymbol, 'bj832566');
    expect(SymbolResolver.resolve('600519').market, QuoteMarket.cn);
    expect(SymbolResolver.resolve('600519').currencyCode, 'CNY');
  });

  test('显式交易所前缀原样保留', () {
    final r = SymbolResolver.resolve('SH600519');
    expect(r.market, QuoteMarket.cn);
    expect(r.tencentSymbol, 'sh600519'); // 统一小写
    expect(SymbolResolver.resolve('bj430047').tencentSymbol, 'bj430047');
  });

  test('港股：纯数字 / hk 前缀 → stooq 补零 .hk', () {
    final r = SymbolResolver.resolve('700');
    expect(r.market, QuoteMarket.hk);
    expect(r.stooqSymbol, '0700.hk');
    expect(r.currencyCode, 'HKD');
    expect(SymbolResolver.resolve('hk.00700').stooqSymbol, '0700.hk');
    expect(SymbolResolver.resolve('hk9988').stooqSymbol, '9988.hk');
    expect(SymbolResolver.resolve('1').stooqSymbol, '0001.hk');
    expect(SymbolResolver.resolve('0700.HK').stooqSymbol, '0700.hk');
    expect(SymbolResolver.resolve('0700.HK').currencyCode, 'HKD');
  });

  test('美股：字母 / us 前缀 / sym.us → stooq', () {
    final r = SymbolResolver.resolve('AAPL');
    expect(r.market, QuoteMarket.intl);
    expect(r.stooqSymbol, 'aapl.us');
    expect(r.currencyCode, 'USD');
    expect(SymbolResolver.resolve('usAAPL').stooqSymbol, 'aapl.us');
    expect(SymbolResolver.resolve('brk-b.us').stooqSymbol, 'brk-b.us');
    expect(SymbolResolver.resolve('BRK-B').stooqSymbol, 'brk-b.us');
  });

  test('无法识别 → unknown', () {
    expect(SymbolResolver.resolve('').market, QuoteMarket.unknown);
    expect(SymbolResolver.resolve('贵州茅台').market, QuoteMarket.unknown);
    expect(SymbolResolver.resolve('sec:600519').market, QuoteMarket.unknown);
    expect(SymbolResolver.resolve('1234567890123').market, QuoteMarket.unknown);
  });
}
