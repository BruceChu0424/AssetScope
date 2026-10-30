import 'dart:math' as math;

import '../utils/dates.dart';
import 'returns.dart';

/// 风险与风险调整后收益指标（口径见 docs/05 §9）。
///
/// 输入为 TWR 子期间收益序列（月末估值点切分，外部现金流已剔除），
/// 输出均为"比率类展示口径"，允许 double；金额本身从不经过本文件。
class RiskReport {
  const RiskReport({
    required this.periods,
    required this.annualizedReturn,
    required this.annualizedVolatility,
    required this.maxDrawdown,
    this.drawdownPeakDate,
    this.drawdownTroughDate,
    required this.sharpe,
    required this.sortino,
    required this.bestMonth,
    this.bestMonthDate,
    required this.worstMonth,
    this.worstMonthDate,
    required this.positiveMonthsRatio,
    required this.riskFreeAnnual,
  });

  /// 参与计算的月度子期间数。
  final int periods;

  /// 年化收益（与 TWR 年化同口径：按实际天数复利）。
  final double? annualizedReturn;

  /// 年化波动率 = 月收益样本标准差 × √12。
  final double? annualizedVolatility;

  /// 最大回撤（TWR 指数峰到谷，负数；如 −23.4% 存 −0.234）。
  final double? maxDrawdown;
  final DateTime? drawdownPeakDate;
  final DateTime? drawdownTroughDate;

  /// Sharpe = (年化收益 − 无风险利率) / 年化波动率。
  final double? sharpe;

  /// Sortino = (年化收益 − 无风险利率) / 年化下行偏差。
  final double? sortino;

  final double? bestMonth;
  final DateTime? bestMonthDate;
  final double? worstMonth;
  final DateTime? worstMonthDate;

  /// 月胜率：收益 > 0 的子期间占比。
  final double? positiveMonthsRatio;

  /// 计算时采用的无风险年利率（设置项 riskFreeRatePercent）。
  final double riskFreeAnnual;

  /// 样本是否足够给出有统计意义的波动率（业界常用 ≥ 6 个月）。
  bool get hasEnoughPeriods => periods >= 6;
}

/// 风险指标计算器：纯函数，无 IO。
class RiskMetrics {
  const RiskMetrics._();

  /// 子期间数下限（月度标准差至少需要 2 个观测，此处取保守下限）。
  static const minPeriods = 2;

  static RiskReport? compute(
    List<PeriodReturn> periods, {
    required double riskFreeAnnual,
  }) {
    if (periods.length < minPeriods) return null;
    final rs = [for (final p in periods) p.r];
    final first = periods.first;
    final last = periods.last;
    final days = calendarDaysBetween(first.start, last.end);
    if (days <= 0) return null;

    // 年化收益：Π(1+r)^(365/days) − 1（与 TWR 年化一致）。
    var growth = 1.0;
    for (final r in rs) {
      growth *= 1 + r;
    }
    final annualized = math.pow(growth, 365.0 / days).toDouble() - 1;

    // 年化波动率：样本标准差（n−1）× √12。
    // 浮点上"常数序列"的方差可能是 1e-20 级噪声，视为 0。
    final mean = rs.fold(0.0, (a, b) => a + b) / rs.length;
    final varSample = rs.length < 2
        ? 0.0
        : rs.fold(0.0, (a, r) => a + (r - mean) * (r - mean)) / (rs.length - 1);
    final volAnnual = math.sqrt(varSample) * math.sqrt(12);

    // 下行偏差（MAR = 月度无风险利率），除以 n（总体口径，行业标准）。
    final mar = math.pow(1 + riskFreeAnnual, 1 / 12).toDouble() - 1;
    final downsideSq = rs.fold(
      0.0,
      (a, r) => a + math.pow(math.min(r - mar, 0.0), 2),
    );
    final ddAnnual = math.sqrt(downsideSq / rs.length) * math.sqrt(12);

    // 最大回撤：TWR 指数（1 起步复利）峰谷最大跌幅，记录峰/谷日期。
    var index = 1.0;
    var peak = 1.0;
    DateTime peakDate = first.start;
    var mdd = 0.0;
    DateTime? mddPeak, mddTrough;
    for (final p in periods) {
      index *= 1 + p.r;
      if (index > peak) {
        peak = index;
        peakDate = p.end;
      }
      final dd = index / peak - 1;
      if (dd < mdd) {
        mdd = dd;
        mddPeak = peakDate;
        mddTrough = p.end;
      }
    }

    // 最佳/最差月与月胜率。
    var best = rs.first, worst = rs.first;
    var bestDate = periods.first.end, worstDate = periods.first.end;
    var positive = 0;
    for (var i = 0; i < rs.length; i++) {
      if (rs[i] > best) {
        best = rs[i];
        bestDate = periods[i].end;
      }
      if (rs[i] < worst) {
        worst = rs[i];
        worstDate = periods[i].end;
      }
      if (rs[i] > 0) positive++;
    }

    return RiskReport(
      periods: rs.length,
      annualizedReturn: annualized,
      annualizedVolatility: volAnnual > 1e-12 ? volAnnual : null,
      maxDrawdown: mdd < 0 ? mdd : null,
      drawdownPeakDate: mddPeak,
      drawdownTroughDate: mddTrough,
      sharpe: volAnnual > 1e-12
          ? (annualized - riskFreeAnnual) / volAnnual
          : null,
      sortino: ddAnnual > 0 ? (annualized - riskFreeAnnual) / ddAnnual : null,
      bestMonth: best,
      bestMonthDate: bestDate,
      worstMonth: worst,
      worstMonthDate: worstDate,
      positiveMonthsRatio: positive / rs.length,
      riskFreeAnnual: riskFreeAnnual,
    );
  }
}
