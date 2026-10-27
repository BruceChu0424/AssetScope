import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:assetscope/domain/invest/returns.dart';
import 'package:assetscope/domain/invest/risk_metrics.dart';

PeriodReturn _p(int y, int m, double r) =>
    PeriodReturn(DateTime(y, m, 1), DateTime(y, m + 1, 1), r);

void main() {
  test('全为 +1%：年化 = 复利、波动率为 0、无回撤、胜率 100%', () {
    final periods = [for (var k = 0; k < 12; k++) _p(2025, 1 + k, 0.01)];
    final r = RiskMetrics.compute(periods, riskFreeAnnual: 0.0)!;
    expect(r.periods, 12);
    expect(r.annualizedReturn, closeTo(math.pow(1.01, 12) - 1, 1e-9));
    expect(r.annualizedVolatility, isNull); // 常数序列样本方差为 0
    expect(r.sharpe, isNull);
    expect(r.sortino, isNull);
    expect(r.maxDrawdown, isNull); // 单调上涨无回撤
    expect(r.positiveMonthsRatio, 1.0);
    expect(r.hasEnoughPeriods, isTrue);
  });

  test('交替 ±10%：波动率/下行偏差/最大回撤/Sharpe 手算对照', () {
    // 2025-01-01 → 2025-07-01，6 个期间，days = 181。
    final periods = [
      _p(2025, 1, 0.10),
      _p(2025, 2, -0.10),
      _p(2025, 3, 0.10),
      _p(2025, 4, -0.10),
      _p(2025, 5, 0.10),
      _p(2025, 6, -0.10),
    ];
    final r = RiskMetrics.compute(periods, riskFreeAnnual: 0.0)!;

    // 波动率：样本方差 = 6×0.01/5 = 0.012 → std √0.012 × √12 = √0.144。
    expect(r.annualizedVolatility!, closeTo(math.sqrt(0.144), 1e-9));

    // 年化：growth = 0.9^3 × 1.1^3 = 0.970299，按 365/181 复利。
    expect(r.annualizedReturn!, closeTo(math.pow(0.970299, 365 / 181) - 1, 1e-9));

    // Sharpe = (年化 − 0) / 年化波动率。
    expect(r.sharpe!, closeTo(r.annualizedReturn! / r.annualizedVolatility!, 1e-9));

    // 下行偏差 = sqrt(3×0.01/6) × √12。
    expect(r.sortino!,
        closeTo(r.annualizedReturn! / (0.07071067811865475 * math.sqrt(12)), 1e-9));

    // 最大回撤：谷底指数 0.970299 / 峰 1.1 − 1。
    expect(r.maxDrawdown!, closeTo(0.970299 / 1.1 - 1, 1e-9));
    expect(r.drawdownPeakDate, DateTime(2025, 2, 1));
    expect(r.drawdownTroughDate, DateTime(2025, 7, 1));

    expect(r.bestMonth!, closeTo(0.10, 1e-12));
    expect(r.worstMonth!, closeTo(-0.10, 1e-12));
    expect(r.bestMonthDate, DateTime(2025, 2, 1));
    expect(r.worstMonthDate, DateTime(2025, 3, 1));
    expect(r.positiveMonthsRatio, 0.5);
  });

  test('创新高后回撤：峰谷日期与深度', () {
    final periods = [
      _p(2025, 1, 0.5), // 指数 1.5（峰）
      _p(2025, 2, -0.4), // 0.9 → 回撤 −40%
      _p(2025, 3, 0.1), // 0.99 → 仍未收复
    ];
    final r = RiskMetrics.compute(periods, riskFreeAnnual: 0.0)!;
    expect(r.maxDrawdown!, closeTo(0.9 / 1.5 - 1, 1e-12));
    expect(r.drawdownPeakDate, DateTime(2025, 2, 1));
    expect(r.drawdownTroughDate, DateTime(2025, 3, 1));
  });

  test('样本不足返回 null', () {
    expect(RiskMetrics.compute([_p(2025, 1, 0.01)], riskFreeAnnual: 0.0), isNull);
    expect(RiskMetrics.compute(const [], riskFreeAnnual: 0.0), isNull);
    // 首尾同日（days=0）也视为不可计算。
    final sameDay = [
      PeriodReturn(DateTime(2025, 1, 1), DateTime(2025, 1, 1), 0.01),
      PeriodReturn(DateTime(2025, 1, 1), DateTime(2025, 1, 1), 0.02),
    ];
    expect(RiskMetrics.compute(sameDay, riskFreeAnnual: 0.0), isNull);
  });

  test('无风险利率参与 Sharpe/Sortino', () {
    final periods = [
      _p(2025, 1, 0.03),
      _p(2025, 2, 0.01),
    ];
    final r = RiskMetrics.compute(periods, riskFreeAnnual: 0.02)!;
    expect(r.riskFreeAnnual, 0.02);
    expect(r.sharpe, greaterThan(0));
  });
}
