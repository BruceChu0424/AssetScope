import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/domain/money/fx_rate.dart';
import 'package:assetscope/domain/planning/life_planner.dart';

/// 人生规划口径测试（docs/05 §14）。
void main() {
  Rational pct(String s) => Rational.percent(s);

  LifeInput base({
    BigInt? invest,
    BigInt? fixed,
    BigInt? income,
    BigInt? expense,
    Rational? ret,
    Rational? inf,
    List<LifeEvent> events = const [],
    int years = 40,
  }) =>
      LifeInput(
        investMinor: invest ?? BigInt.zero,
        fixedAssetsMinor: fixed ?? BigInt.zero,
        monthlyIncomeMinor: income ?? BigInt.zero,
        monthlyExpenseMinor: expense ?? BigInt.zero,
        nominalReturnAnnual: ret ?? Rational.zero(),
        inflationAnnual: inf ?? Rational.zero(),
        events: events,
        years: years,
      );

  group('复利与现金流基线', () {
    test('零收益 + 正储蓄：12 个月终值 = 12×月储蓄', () {
        final r = LifePlanner.simulate(base(
          invest: BigInt.from(100000),
          income: BigInt.from(1000),
          years: 1,
        ));
        expect(r.curve.last.investMinor, BigInt.from(112000));
        expect(r.ok, isTrue);
      },
    );

    test('零收益 + 通胀支出：invest 精确按 x^t 递减', () {
      // 月通胀 1.2%（年 14.4%），月支出 1000，无收入，12 个月。
      // 第 t 月支出 = 1000 × 1.012^t；invest = 100万 − Σ。
      final inf = Rational.parseDecimal('0.144');
      final r = LifePlanner.simulate(base(
        invest: BigInt.from(100000000),
        expense: BigInt.from(1000),
        inf: inf,
        years: 1,
      ));
      Rational x = Rational.one;
      var expectInv = Rational.fromInt(BigInt.from(100000000));
      for (var t = 1; t <= 12; t++) {
        x *= Rational.one + inf / Rational.fromInt(BigInt.from(12));
        expectInv -= Rational.fromInt(BigInt.from(1000)) * x;
      }
      expect(r.curve.last.investMinor, expectInv.rounded());
    });

    test('名义复利：单月增长精确 = invest×g + 储蓄', () {
      final ret = pct('6');
      final g = Rational.one + ret / Rational.fromInt(BigInt.from(12));
      final r = LifePlanner.simulate(base(
        invest: BigInt.from(1000000),
        income: BigInt.from(100),
        ret: ret,
        years: 1,
      ));
      // 采样点只有 t=0 与 t=12；单月精确性由 12 月闭式验证。
      var p = Rational.fromInt(BigInt.from(1000000));
      for (var t = 1; t <= 12; t++) {
        p = p * g + Rational.fromInt(BigInt.from(100));
      }
      expect(r.curve.last.investMinor, p.rounded());
    });
  });

  group('买房事件', () {
    final home = HomePurchase(
      month: 6,
      priceMinor: BigInt.from(200000000), // 200 万
      downPaymentMinor: BigInt.from(60000000), // 60 万
      annualRate: pct('3.6'),
      termYears: 30,
    );

    test('恒等式：首付+贷款=房价时，买房瞬间净资产不变', () {
      // 无现金流（收入=支出=0），零收益：买房月净资产应与上月完全一致
      //（60 万首付从 invest 流出，固定资产 +200 万，负债 +140 万）。
      final r = LifePlanner.simulate(base(
        invest: BigInt.from(100000000),
        income: BigInt.from(10000),
        expense: BigInt.from(10000),
        events: [home],
        years: 1,
      ));
      // 1–5 月零净现金流，netWorth 恒定；买房月（t=6）应与起点一致。
      final at0 = r.curve.first.netWorthMinor;
      final at6 = r.curve.firstWhere((p) => p.month == 6).netWorthMinor;
      expect(at6, at0, reason: '首付+贷款=房价 ⇒ 净资产守恒');
    });

    test('月供 = 等额本息闭式（与债务模块同式）', () {
      final r = LifePlanner.simulate(base(
        invest: BigInt.from(100000000),
        income: BigInt.from(10000),
        expense: BigInt.from(10000),
        events: [home],
        years: 1,
      ));
      final p = Rational.fromInt(home.priceMinor - home.downPaymentMinor);
      final i = home.annualRate / Rational.fromInt(BigInt.from(12));
      final n = home.termYears * 12;
      final growth = _pow(Rational.one + i, n);
      final a = (p * i * growth / (growth - Rational.one)).rounded();
      final at6 = r.curve.firstWhere((p) => p.month == 6);
      final at7 = r.curve.firstWhere((p) => p.month == 7);
      // t=7 现金流 = 基线 0 − 第一期月供 a。
      expect(at7.cashFlowMinor, -a);
      // 首期后负债余额 = P − (a − P·i)。
      final firstInterest = (p * i).rounded();
      expect(at7.debtMinor, p.rounded() - (a - firstInterest));
      expect(at6.debtMinor, p.rounded());
    });

    test('贷款还清后月供退出现金流', () {
      final tiny = HomePurchase(
        month: 0,
        priceMinor: BigInt.from(120000),
        downPaymentMinor: BigInt.zero,
        annualRate: Rational.zero(), // 免息 12 期
        termYears: 1,
      );
      final r = LifePlanner.simulate(base(
        invest: BigInt.from(1000000),
        income: BigInt.from(5000),
        events: [tiny],
        years: 3,
      ));
      final month12 = r.curve.firstWhere((p) => p.month == 12);
      expect(month12.debtMinor, BigInt.zero, reason: '12 期后应已还清');
      expect(month12.cashFlowMinor, BigInt.from(5000) - BigInt.from(10000),
          reason: '末期月供 1 万（免息 12 万 ÷ 12）');
      final month24 = r.curve.firstWhere((p) => p.month == 24);
      expect(month24.cashFlowMinor, BigInt.from(5000), reason: '还清后月供退出');
    });

    test('总利息 = Σ 各期利息（30 年贷款正利息）', () {
      final r = LifePlanner.simulate(base(
        invest: BigInt.from(300000000),
        income: BigInt.from(30000),
        expense: BigInt.from(10000),
        events: [home],
        years: 31,
      ));
      expect(r.newLoanInterestMinor > BigInt.zero, isTrue);
      // 200 万-60 万 30 年 3.6%：总利息约 88 万（±2% 容差防舍入细节）。
      final approx = BigInt.from(88000000);
      final diff = (r.newLoanInterestMinor - approx).abs();
      expect(diff < BigInt.from(2000000), isTrue,
          reason: '实际总利息 ${r.newLoanInterestMinor}');
    });
  });

  group('收入/退休/育儿/大额', () {
    test('退休默认：收入×0.4、支出×0.75', () {
      final r = LifePlanner.simulate(base(
        invest: BigInt.from(1000000),
        income: BigInt.from(10000),
        expense: BigInt.from(4000),
        events: [const Retirement(month: 12)],
        years: 2,
      ));
      final m13 = r.curve.firstWhere((p) => p.month == 13);
      expect(m13.cashFlowMinor, BigInt.from(4000) - BigInt.from(3000));
    });

    test('收入跳变乘法组合：涨 30% 后再降 20% = ×1.04', () {
      final r = LifePlanner.simulate(base(
        invest: BigInt.from(10000000),
        income: BigInt.from(1000),
        events: [
          IncomeChange(
              month: 1, factor: Rational.parseDecimal('1.3')),
          IncomeChange(
              month: 2, factor: Rational.parseDecimal('0.8')),
        ],
        years: 1,
      ));
      final m3 = r.curve.firstWhere((p) => p.month == 3);
      expect(m3.cashFlowMinor, BigInt.from(1040));
    });

    test('育儿成本：出生次月起、大学阶段加成、独立后停止', () {
      // 出生月 11：使大学（t=11+217=228）与独立（t=11+241=252）
      // 恰好落在年度采样点上（228=12×19、252=12×21）。
      final r = LifePlanner.simulate(base(
        invest: BigInt.from(1000000000),
        income: BigInt.from(1000),
        expense: BigInt.from(500),
        events: [
          ChildRearing(
            month: 11,
            monthlyCostMinor: BigInt.from(200),
            collegeExtraMinor: BigInt.from(800),
            dependentMonths: 240, // 240 个成本月（20 年）
          ),
        ],
        years: 21,
      ));
      // 出生次月（t=12，成本月龄 0）：支出 500+200，现金流 300。
      expect(r.curve.firstWhere((p) => p.month == 12).cashFlowMinor,
          BigInt.from(300));
      // 大学（成本月龄 216，t = 11+216+1 = 228）：500+200+800。
      final m228 = r.curve.firstWhere((p) => p.month == 228);
      expect(m228.cashFlowMinor, BigInt.from(1000) - BigInt.from(1500));
      // 独立（240 个成本月用尽后的 t = 11+241 = 252）：回到 500。
      final m252 = r.curve.firstWhere((p) => p.month == 252);
      expect(m252.cashFlowMinor, BigInt.from(500));
    });

    test('现金耗尽：exhaustedAtMonth 为首次 invest < 0', () {
      final r = LifePlanner.simulate(base(
        invest: BigInt.from(10000),
        expense: BigInt.from(1000),
        events: const [],
        years: 2,
      ));
      expect(r.ok, isFalse);
      expect(r.exhaustedAtMonth, 11, reason: '1 万 ÷ 1000/月 → 第 11 月耗尽');
      // 耗尽后继续推演（展示缺口深度）。
      expect(r.curve.last.investMinor < BigInt.zero, isTrue);
    });

    test('一次性流入直接加 invest；大件购置残值进固定资产', () {
      final r = LifePlanner.simulate(base(
        invest: BigInt.from(1000000),
        events: [
          LumpSum(month: 3, amountMinor: BigInt.from(50000)),
          BigPurchase(
              month: 6,
              costMinor: BigInt.from(150000),
              residualMinor: BigInt.from(100000)),
        ],
        years: 1,
      ));
      expect(r.curve.firstWhere((p) => p.month == 3).investMinor,
          BigInt.from(1050000));
      final at6 = r.curve.firstWhere((p) => p.month == 6);
      expect(at6.investMinor, BigInt.from(900000));
      expect(at6.fixedMinor, BigInt.from(100000));
    });

    test('峰值净资产：单调增长时等于终值', () {
      final r = LifePlanner.simulate(base(
        invest: BigInt.from(100000),
        income: BigInt.from(1000),
        years: 2,
      ));
      expect(r.peakNetWorthMinor, r.curve.last.netWorthMinor);
    });
  });
}

Rational _pow(Rational base, int exp) {
  var r = Rational.one;
  for (var i = 0; i < exp; i++) {
    r *= base;
  }
  return r;
}
