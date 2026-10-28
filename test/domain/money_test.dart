import 'package:flutter_test/flutter_test.dart';
import 'package:assetscope/domain/money/currency.dart';
import 'package:assetscope/domain/money/fx_rate.dart';
import 'package:assetscope/domain/money/money.dart';

void main() {
  group('Money', () {
    test('解析与格式化（含千分位/负数/精度舍入）', () {
      expect(Money.parse('1234.56', CurrencyInfo.cny).format(), '1,234.56');
      expect(Money.parse('-0.01', CurrencyInfo.cny).format(), '-0.01');
      expect(Money.parse('1,234.56', CurrencyInfo.cny).amountMinor,
          BigInt.from(123456));
      // 超出币种精度 → halfEven 舍入：0.5 分 → 0（偶数）
      expect(Money.parse('0.005', CurrencyInfo.cny).amountMinor, BigInt.zero);
    });

    test('精度边界 halfEven', () {
      // 0.005 元 = 0.5 分：halfEven 取 0（偶数）
      expect(Money.parse('0.005', CurrencyInfo.cny).amountMinor, BigInt.zero);
      // 0.015 元 = 1.5 分：halfEven 取 2
      expect(Money.parse('0.015', CurrencyInfo.cny).amountMinor, BigInt.two);
      // halfUp 时 0.5 → 1
      expect(
          Money.parse('0.005', CurrencyInfo.cny,
                  mode: RoundingMode.halfUp)
              .amountMinor,
          BigInt.one);
    });

    test('Rational.rounded 负数对称舍入（回归：曾返回错误正号）', () {
      BigInt r(int n, int d, {RoundingMode mode = RoundingMode.halfEven}) =>
          Rational.fromFrac(BigInt.from(n), BigInt.from(d))
              .rounded(mode: mode);
      // 精确整除：符号不丢（−3000000/5 = −600000）
      expect(r(-3000000, 5), BigInt.from(-600000));
      // −3.5 halfEven → −4（与 +3.5 → 4 镜像，偶数量级）
      expect(r(-7, 2), BigInt.from(-4));
      expect(r(7, 2), BigInt.from(4));
      // −1.5 halfEven → −2（|q|=1 奇 → 进位到偶数 2）
      expect(r(-3, 2), BigInt.from(-2));
      // down 向零截断
      expect(r(-7, 2, mode: RoundingMode.down), BigInt.from(-3));
      // up 远离零
      expect(r(-7, 2, mode: RoundingMode.up), BigInt.from(-4));
      // halfUp：0.5 恒进位
      expect(r(-5, 2, mode: RoundingMode.halfUp), BigInt.from(-3));
    });

    test('JPY 0 位小数', () {
      expect(Money.parse('1000', CurrencyInfo.jpy).amountMinor,
          BigInt.from(1000));
      expect(Money.parse('1000', CurrencyInfo.jpy).format(), '1,000');
    });

    test('同币种运算、跨币种拒绝', () {
      final a = Money.parse('10.00', CurrencyInfo.cny);
      final b = Money.parse('3.50', CurrencyInfo.cny);
      expect((a - b).format(), '6.50');
      expect(
          () => a + Money.parse('1', CurrencyInfo.usd),
          throwsArgumentError);
    });

    test('比例分摊精确', () {
      final m = Money.parse('100.00', CurrencyInfo.cny);
      expect(m.scaleRatio(BigInt.one, BigInt.from(3)).amountMinor,
          BigInt.from(3333)); // 10000/3 = 3333.33 → 3333
    });
  });

  group('Rational', () {
    test('精确十进制与归约', () {
      final r = Rational.parseDecimal('3.85');
      expect(r * Rational.fromInt(BigInt.from(100)), Rational.parseDecimal('385'));
      expect(Rational.parseDecimal('0.1') + Rational.parseDecimal('0.2'),
          Rational.parseDecimal('0.3'));
      expect(Rational.parseDecimal('2') / Rational.parseDecimal('4'),
          Rational.parseDecimal('0.5'));
    });

    test('比较运算', () {
      expect(Rational.parseDecimal('1.5') > Rational.one, isTrue);
      expect(Rational.parseDecimal('-0.5') < Rational.zero(), isTrue);
    });
  });

  group('FxRate', () {
    test('跨币种换算（精确有理数）', () {
      final rate = FxRate(
          from: CurrencyInfo.usd,
          to: CurrencyInfo.cny,
          rate: Rational.parseDecimal('7.2'),
          asOf: DateTime(2026, 1, 1));
      final usd = Money.parse('100.00', CurrencyInfo.usd);
      expect(rate.convert(usd).format(), '720.00');
      // 反向
      final cny = Money.parse('720.00', CurrencyInfo.cny);
      expect(rate.convert(cny).format(withSymbol: false), '100.00');
    });

    test('不同小数位币种换算', () {
      final rate = FxRate(
          from: CurrencyInfo.btc,
          to: CurrencyInfo.cny,
          rate: Rational.parseDecimal('430000'),
          asOf: DateTime(2026, 1, 1));
      final btc = Money.parse('0.5', CurrencyInfo.btc);
      expect(rate.convert(btc).format(), '215,000.00');
    });
  });
}
