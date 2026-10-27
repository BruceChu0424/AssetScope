import 'package:flutter_test/flutter_test.dart';
import 'package:assetscope/domain/debt/debt_contract.dart';
import 'package:assetscope/domain/money/fx_rate.dart';

void main() {
  DebtContract contract({
    required BigInt principal,
    required String apr,
    required RepaymentMethod method,
    required int months,
  }) =>
      DebtContract(
        liabilityAccountId: 'loan',
        principalOriginalMinor: principal,
        aprPercent: Rational.parseDecimal(apr),
        method: method,
        termMonths: months,
        startDate: DateTime(2026, 1, 10),
        firstPaymentDate: DateTime(2026, 2, 10),
      );

  test('等额本息：本金恰好清零、每期还款额恒定、利息递减', () {
    final c = contract(
        principal: BigInt.from(12000000),
        apr: '6',
        method: RepaymentMethod.annuity,
        months: 12);
    final s = c.generateSchedule();
    expect(s.length, 12);
    expect(s.last.remainingPrincipalMinor, BigInt.zero);
    // 每期总额一致（末期因舍入修正允许差 ≤ 1 分）
    final totals = s.map((e) => e.totalMinor).toSet();
    expect(totals.length <= 2, isTrue);
    // 利息递减
    for (var i = 1; i < s.length; i++) {
      expect(s[i].interestMinor <= s[i - 1].interestMinor, isTrue);
    }
    // 本金之和恰等于本金
    final sumP = s.fold(BigInt.zero, (a, e) => a + e.principalMinor);
    expect(sumP, BigInt.from(12000000));
  });

  test('等额本金：每期本金相同、总利息低于等额本息', () {
    final annuity = contract(
            principal: BigInt.from(12000000),
            apr: '6',
            method: RepaymentMethod.annuity,
            months: 12)
        .generateSchedule();
    final eq = contract(
            principal: BigInt.from(12000000),
            apr: '6',
            method: RepaymentMethod.equalPrincipal,
            months: 12)
        .generateSchedule();
    expect(eq.length, 12);
    expect(eq.last.remainingPrincipalMinor, BigInt.zero);
    final interestAnnuity =
        annuity.fold(BigInt.zero, (a, e) => a + e.interestMinor);
    final interestEq = eq.fold(BigInt.zero, (a, e) => a + e.interestMinor);
    expect(interestEq < interestAnnuity, isTrue);
  });

  test('先息后本：末期一次还本', () {
    final s = contract(
            principal: BigInt.from(1000000),
            apr: '7.2',
            method: RepaymentMethod.bulletInterest,
            months: 6)
        .generateSchedule();
    expect(s.length, 6);
    expect(s.last.principalMinor, BigInt.from(1000000));
    for (var i = 0; i < 5; i++) {
      expect(s[i].principalMinor, BigInt.zero);
      // 本金 1 万元 × 月利率 0.6% = 60 元 = 6000 分
      expect(s[i].interestMinor, BigInt.from(6000));
    }
  });

  test('免息分期：只有本金', () {
    final s = contract(
            principal: BigInt.from(240000),
            apr: '0',
            method: RepaymentMethod.interestFree,
            months: 12)
        .generateSchedule();
    expect(s.fold(BigInt.zero, (a, e) => a + e.interestMinor), BigInt.zero);
    expect(s.last.remainingPrincipalMinor, BigInt.zero);
  });

  test('固定分期费率：有效年化显著高于名义费率', () {
    final c = contract(
        principal: BigInt.from(1200000),
        apr: '7.2', // 名义年费率 7.2% = 月费率 0.6%
        method: RepaymentMethod.fixedInstallment,
        months: 12);
    final s = c.generateSchedule();
    expect(s.length, 12);
    final eff = c.effectiveAprPercent();
    expect(eff, isNotNull);
    // 月费率 0.6%（等本等费）→ IRR 有效年化 ≈ 13%，远高于 7.2% 名义值
    expect(eff!.asDouble(), greaterThan(12));
    expect(eff.asDouble(), lessThan(15));
  });

  test('提前还款：利息净节省为正（无手续费场景）', () {
    final c = contract(
        principal: BigInt.from(12000000),
        apr: '6',
        method: RepaymentMethod.annuity,
        months: 36);
    final schedule = c.generateSchedule();
    final remainingAfter12 = schedule[11].remainingPrincipalMinor;
    final result = c.simulatePrepayment(
      afterEntrySeq: 12,
      extraMinor: remainingAfter12 ~/ BigInt.two,
      remainingPrincipalMinor: remainingAfter12,
      shortenTerm: true,
    );
    expect(result.prepayFeeMinor, BigInt.zero);
    expect(result.interestSavedMinor > BigInt.zero, isTrue,
        reason: '提前还一半本金应节省利息');
    expect(result.monthsSaved > 0, isTrue);
  });

  test('还款日：月末锚点跨月正确（31日→2月末）', () {
    final c = DebtContract(
      liabilityAccountId: 'loan',
      principalOriginalMinor: BigInt.from(100000),
      aprPercent: Rational.zero(),
      method: RepaymentMethod.interestFree,
      termMonths: 3,
      startDate: DateTime(2026, 1, 31),
    );
    final s = c.generateSchedule();
    expect(s[0].dueDate, DateTime(2026, 1, 31));
    expect(s[1].dueDate, DateTime(2026, 2, 28)); // 闰年判断：2026 非闰年
    expect(s[2].dueDate, DateTime(2026, 3, 31));
  });

  test('雪崩 vs 雪球：同样资金下雪崩总利息不高于雪球', () {
    final debts = [
      DebtPosition(
          name: '花呗',
          remainingPrincipalMinor: BigInt.from(30000), // 300 元
          aprPercent: Rational.parseDecimal('15'),
          minMonthlyPaymentMinor: BigInt.from(10000)),
      DebtPosition(
          name: '房贷',
          remainingPrincipalMinor: BigInt.from(50000000), // 50 万
          aprPercent: Rational.parseDecimal('3.85'),
          minMonthlyPaymentMinor: BigInt.from(300000)),
    ];
    final avalanche = DebtPayoffPlanner.simulate(debts, PayoffStrategy.avalanche,
        extraMonthlyMinor: BigInt.from(50000));
    final snowball = DebtPayoffPlanner.simulate(debts, PayoffStrategy.snowball,
        extraMonthlyMinor: BigInt.from(50000));
    expect(avalanche.months, greaterThan(0));
    expect(avalanche.totalInterestMinor <= snowball.totalInterestMinor, isTrue);
  });
}
