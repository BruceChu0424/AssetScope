import '../utils/dates.dart' as dates;

/// 消费配速：按当月已发生支出外推月末总额。
///
/// 口径：
/// - 日均速度 = 已花 / 已过天数（当月第 1 天到今天，首日计入）。
/// - 剩余天数不扣固定计划（计划占用由调用方单独叠加披露），
///   预测值 = 已花 + 日均 × 剩余天数。
/// - 与额度比较给出"预计超支/预计结余"与"剩余日均可用"。
/// 金额全部 BigInt 最小单位，不出现 double。
class SpendingPace {
  const SpendingPace({
    required this.monthKey,
    required this.daysElapsed,
    required this.daysInMonth,
    required this.spentMinor,
    required this.projectedMinor,
    required this.dailyAvgMinor,
    required this.daysRemaining,
  });

  final String monthKey;
  final int daysElapsed;
  final int daysInMonth;
  final int daysRemaining;

  /// 本月已发生消费（含退款冲减后的净额）。
  final BigInt spentMinor;

  /// 外推月末消费预测。
  final BigInt projectedMinor;

  /// 已过天数日均消费。
  final BigInt dailyAvgMinor;

  /// 给定预算额度，计算预测差额（正=预计结余，负=预计超支）
  /// 与剩余每日可花上限。
  BudgetPace versus(BigInt limitMinor) {
    final headroom = limitMinor - projectedMinor;
    final safeDaily = daysRemaining > 0 && headroom > BigInt.zero
        ? headroom ~/ BigInt.from(daysRemaining)
        : BigInt.zero;
    return BudgetPace(
      limitMinor: limitMinor,
      projectedDeltaMinor: headroom,
      safeDailyMinor: safeDaily,
      overPace: projectedMinor > limitMinor,
    );
  }

  /// 由"已花 + 日期 + 月长度"构造。
  factory SpendingPace.of({required DateTime now, required BigInt spentMinor}) {
    final total = DateTime(now.year, now.month + 1, 0).day;
    final elapsed = now.day; // 首日即算 1 天
    final remaining = (total - elapsed).clamp(0, total);
    final dailyAvg = elapsed > 0
        ? spentMinor ~/ BigInt.from(elapsed)
        : BigInt.zero;
    final projected = spentMinor + dailyAvg * BigInt.from(remaining);
    return SpendingPace(
      monthKey: dates.monthKey(now),
      daysElapsed: elapsed,
      daysInMonth: total,
      daysRemaining: remaining,
      spentMinor: spentMinor,
      projectedMinor: projected,
      dailyAvgMinor: dailyAvg,
    );
  }
}

/// 预算对照结果。
class BudgetPace {
  const BudgetPace({
    required this.limitMinor,
    required this.projectedDeltaMinor,
    required this.safeDailyMinor,
    required this.overPace,
  });

  final BigInt limitMinor;

  /// 额度 − 月末预测。正=预计还有结余，负=预计超支。
  final BigInt projectedDeltaMinor;

  /// 剩余天数每天可安全消费的上限（超支风险下为 0）。
  final BigInt safeDailyMinor;

  /// 当前速度是否会在月末超出额度。
  final bool overPace;
}
