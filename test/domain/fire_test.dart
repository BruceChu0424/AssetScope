import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/domain/money/fx_rate.dart';
import 'package:assetscope/domain/planning/fire.dart';

void main() {
  final yuan = BigInt.from(100);
  BigInt y(int v) => BigInt.from(v) * yuan;

  FireInput input({
    BigInt? portfolio,
    BigInt? savings,
    BigInt? spend,
    required Rational nominal,
    required Rational inflation,
    required Rational wr,
    int maxYears = 50,
  }) =>
      FireInput(
        portfolioMinor: portfolio ?? BigInt.zero,
        annualSavingsMinor: savings ?? BigInt.zero,
        annualSpendMinor: spend ?? BigInt.zero,
        nominalReturnAnnual: nominal,
        inflationAnnual: inflation,
        withdrawalRate: wr,
        maxYears: maxYears,
      );

  group('FirePlanner.plan', () {
    test('FI 门槛 = 年支出 ÷ 提取率', () {
      final plan = FirePlanner.plan(input(
        spend: y(200000),
        nominal: Rational.zero(),
        inflation: Rational.zero(),
        wr: Rational.parseDecimal('0.04'),
      ));
      expect(plan.fiNumberMinor, y(5000000));
    });

    test('已达标：monthsToFi=0 且 alreadyFi', () {
      final plan = FirePlanner.plan(input(
        portfolio: y(6000000),
        spend: y(200000),
        nominal: Rational.percent('5'),
        inflation: Rational.percent('2'),
        wr: Rational.parseDecimal('0.04'),
      ));
      expect(plan.alreadyFi, isTrue);
      expect(plan.monthsToFi, 0);
      expect(plan.coverage, greaterThan(1));
    });

    test('线性累积（0 利率 0 通胀）逐月精确', () {
      final plan = FirePlanner.plan(input(
        portfolio: y(40000),
        savings: y(12000), // 月储蓄 1000 元
        spend: y(505),
        nominal: Rational.zero(),
        inflation: Rational.zero(),
        wr: Rational.parseDecimal('0.01'), // 门槛 50500
      ));
      // 每月 +1000：10 个月到 50000（不足），11 个月到 51000 ≥ 50500
      expect(plan.monthsToFi, 11);
      expect(plan.curve.last.portfolioMinor, y(51000));
      expect(plan.curve.last.reached, isTrue);
    });

    test('复利累积：月利率 1% 一个月达标', () {
      final plan = FirePlanner.plan(input(
        portfolio: y(10000),
        spend: y(101),
        nominal: Rational.percent('12'), // 月 1%
        inflation: Rational.zero(),
        wr: Rational.parseDecimal('0.01'), // 门槛 10100
      ));
      expect(plan.monthsToFi, 1); // 10000 × 1.01 = 10100
    });

    test('不可达：零储蓄且名义收益追不上通胀', () {
      final plan = FirePlanner.plan(input(
        portfolio: y(10000),
        spend: y(101),
        nominal: Rational.percent('12'),
        inflation: Rational.percent('12'), // 与收益同速 → 永远差 100
        wr: Rational.parseDecimal('0.01'),
      ));
      expect(plan.monthsToFi, -1);
      expect(plan.alreadyFi, isFalse);
    });

    test('无支出目标：曲线可用、门槛 0', () {
      final plan = FirePlanner.plan(input(
        portfolio: y(1000),
        savings: y(1200),
        spend: BigInt.zero,
        nominal: Rational.percent('5'),
        inflation: Rational.percent('2'),
        wr: Rational.parseDecimal('0.04'),
      ));
      expect(plan.fiNumberMinor, BigInt.zero);
      expect(plan.monthsToFi, -1);
      expect(plan.curve.length, greaterThan(1));
    });

    test('曲线按年采样且含达标月', () {
      final plan = FirePlanner.plan(input(
        portfolio: y(40000),
        savings: y(1200), // 月储蓄 100 元 → 105 个月达标
        spend: y(505),
        nominal: Rational.zero(),
        inflation: Rational.zero(),
        wr: Rational.parseDecimal('0.01'),
      ));
      // 105 个月：采样点 = 0,12,...,96,105
      expect(plan.curve.map((p) => p.monthsFromNow).toList(),
          [0, 12, 24, 36, 48, 60, 72, 84, 96, 105]);
    });
  });

  group('FirePlanner.requiredAnnualSavingsMinor', () {
    test('线性反解精确回代', () {
      final inp = input(
        portfolio: y(40000),
        spend: y(505),
        nominal: Rational.zero(),
        inflation: Rational.zero(),
        wr: Rational.parseDecimal('0.01'), // 门槛 50500
      );
      // 1 年内从 40000 到 50500：需年储蓄 10500
      expect(FirePlanner.requiredAnnualSavingsMinor(inp, 1), y(10500));
    });

    test('复利反解：所需储蓄 ≤ 实际储蓄时达标成立', () {
      final inp = input(
        portfolio: y(300000),
        savings: y(60000),
        spend: y(100000),
        nominal: Rational.percent('5'),
        inflation: Rational.percent('2'),
        wr: Rational.parseDecimal('0.04'),
      );
      final plan = FirePlanner.plan(inp);
      expect(plan.monthsToFi, greaterThan(0));
      final years = (plan.monthsToFi / 12).ceil();
      final required =
          FirePlanner.requiredAnnualSavingsMinor(inp, years);
      // 用"恰好 required"应能在同一年限内达标
      final withRequired = FirePlanner.plan(input(
        portfolio: inp.portfolioMinor,
        savings: required,
        spend: inp.annualSpendMinor,
        nominal: inp.nominalReturnAnnual,
        inflation: inp.inflationAnnual,
        wr: inp.withdrawalRate,
      ));
      expect(withRequired.monthsToFi, lessThanOrEqualTo(years * 12));
    });

    test('组合复利即可达标时返回 0', () {
      final inp = input(
        portfolio: y(5000000),
        spend: y(100000),
        savings: BigInt.zero,
        nominal: Rational.percent('5'),
        inflation: Rational.percent('2'),
        wr: Rational.parseDecimal('0.04'),
      );
      expect(FirePlanner.requiredAnnualSavingsMinor(inp, 10), BigInt.zero);
    });

    test('years 非正抛错', () {
      final inp = input(
        spend: y(1000),
        nominal: Rational.zero(),
        inflation: Rational.zero(),
        wr: Rational.parseDecimal('0.04'),
      );
      expect(() => FirePlanner.requiredAnnualSavingsMinor(inp, 0),
          throwsArgumentError);
    });
  });

  group('FirePlanner.sensitivity', () {
    test('方向正确：收益+1pp 或支出-10% 不晚于基准', () {
      final cells = FirePlanner.sensitivity(input(
        portfolio: y(300000),
        savings: y(60000),
        spend: y(100000),
        nominal: Rational.percent('5'),
        inflation: Rational.percent('2'),
        wr: Rational.parseDecimal('0.04'),
      ));
      expect(cells.length, 9);
      int at(int shift, double f) => cells
          .firstWhere((c) =>
              c.returnShiftPercentPoint == shift && c.spendFactor == f)
          .monthsToFi;
      final base = at(0, 1.0);
      expect(base, greaterThan(0));
      expect(at(1, 0.9), lessThanOrEqualTo(base));
      expect(at(-1, 1.1), greaterThanOrEqualTo(base));
    });
  });

  group('FireInput.realReturnAnnual（Fisher）', () {
    test('(1.06/1.02) − 1', () {
      final inp = input(
        spend: BigInt.one,
        nominal: Rational.percent('6'),
        inflation: Rational.percent('2'),
        wr: Rational.parseDecimal('0.04'),
      );
      expect(inp.realReturnAnnual, closeTo(0.0392156862745, 1e-9));
    });
  });

  group('FireMonteCarlo.survival', () {
    test('确定性：同种子同参数结果一致', () {
      final a = FireMonteCarlo.survival(
          initialMultiple: 25,
          realReturnMean: 0.04,
          realVol: 0.12,
          years: 30,
          paths: 500,
          seed: 7);
      final b = FireMonteCarlo.survival(
          initialMultiple: 25,
          realReturnMean: 0.04,
          realVol: 0.12,
          years: 30,
          paths: 500,
          seed: 7);
      expect(a.successRate, b.successRate);
      expect(a.p50, b.p50);
      expect(a.p10 <= a.p50 && a.p50 <= a.p90, isTrue);
      expect(a.paths, 500);
    });

    test('零波动：收益为正必生存，收益为负必耗尽', () {
      final good = FireMonteCarlo.survival(
          initialMultiple: 25,
          realReturnMean: 0.04,
          realVol: 0,
          years: 30,
          paths: 10);
      expect(good.successRate, 1);
      final bad = FireMonteCarlo.survival(
          initialMultiple: 25,
          realReturnMean: -0.10,
          realVol: 0,
          years: 30,
          paths: 10);
      expect(bad.successRate, 0);
    });

    test('高波动降低生存率（同种子对比）', () {
      final low = FireMonteCarlo.survival(
          initialMultiple: 25,
          realReturnMean: 0.04,
          realVol: 0.05,
          years: 30,
          paths: 1000,
          seed: 7);
      final high = FireMonteCarlo.survival(
          initialMultiple: 25,
          realReturnMean: 0.04,
          realVol: 0.25,
          years: 30,
          paths: 1000,
          seed: 7);
      expect(high.successRate, lessThan(low.successRate));
    });

    test('期初倍数更大的生存率不低于更小的', () {
      final rich = FireMonteCarlo.survival(
          initialMultiple: 33,
          realReturnMean: 0.04,
          realVol: 0.12,
          years: 30,
          paths: 1000,
          seed: 7);
      final lean = FireMonteCarlo.survival(
          initialMultiple: 20,
          realReturnMean: 0.04,
          realVol: 0.12,
          years: 30,
          paths: 1000,
          seed: 7);
      expect(rich.successRate, greaterThanOrEqualTo(lean.successRate));
    });
  });
}
