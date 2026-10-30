/// 财务健康：储蓄率、应急月数、资产负债率与净资产里程碑预测。
///
/// 全部口径见 docs/11。金额 BigInt；比率仅展示用 double。
class FinancialHealth {
  const FinancialHealth({
    required this.savingsRate,
    required this.emergencyMonths,
    required this.debtToAsset,
    required this.passiveCushion,
  });

  /// 储蓄率 = (收入 − 消费) / 收入（本月，仅常规收支）。
  /// 无收入时为 null（避免除零产生的假 0%）。
  final double? savingsRate;

  /// 应急月数 = 流动资产 / 近 3 个月月均必要支出。
  /// 支出为 0 时为 null。
  final double? emergencyMonths;

  /// 资产负债率 = 总负债 / 总资产。无资产时 null。
  final double? debtToAsset;

  /// 月末固定收入可覆盖固定支出的比例（<1 说明固定开销已超固定收入）。
  /// 无固定支出时 null。
  final double? passiveCushion;
}

/// 净资产里程碑预测：Theil–Sen 稳健回归。
///
/// 用月度净资产序列的"两两斜率中位数"估计趋势，
/// 对离群月（如一次性大额）不敏感；外推达到 [targetMinor]
/// 所需月数。趋势不向上或数据不足返回 null。
class NetWorthMilestone {
  const NetWorthMilestone._({
    required this.slopePerMonthMinor,
    required this.monthsToTarget,
    required this.targetDate,
  });

  /// 每月净资产变化中位数估计（本位币最小单位）。
  final BigInt slopePerMonthMinor;

  /// 预计还有多少个月达到目标。
  final int monthsToTarget;

  /// 预计达到目标的年月。
  final DateTime targetDate;

  /// [series] 为按月升序的净资产（i=0 最旧），至少 4 个月。
  /// [targetMinor] 为目标净资产。
  static NetWorthMilestone? predict({
    required List<BigInt> series,
    required BigInt targetMinor,
    required DateTime asOf,
  }) {
    if (series.length < 4) return null;
    final last = series.last;
    if (targetMinor <= last) return null; // 已达标
    // 两两斜率中位数（Theil–Sen 核心）。
    final slopes = <double>[];
    for (var i = 0; i < series.length; i++) {
      for (var j = i + 1; j < series.length; j++) {
        final dy = (series[j] - series[i]).toDouble();
        final dx = (j - i).toDouble();
        slopes.add(dy / dx);
      }
    }
    slopes.sort();
    final slope = slopes[slopes.length ~/ 2];
    if (slope <= 0) return null; // 趋势不向上，无法外推
    final gap = (targetMinor - last).toDouble();
    final months = (gap / slope).ceil();
    if (months > 12 * 60) return null; // 超过 60 年视为不可达
    return NetWorthMilestone._(
      slopePerMonthMinor: BigInt.from(slope.round()),
      monthsToTarget: months,
      targetDate: DateTime(asOf.year, asOf.month + months),
    );
  }
}

/// 组装 [FinancialHealth]（数据由 InsightService 收集）。
FinancialHealth computeHealth({
  required BigInt incomeMinor,
  required BigInt expenseMinor,
  required BigInt liquidAssetsMinor,
  required BigInt avgMonthlyEssentialMinor,
  required BigInt totalAssetsMinor,
  required BigInt totalLiabilitiesMinor,
  required BigInt fixedIncomeMonthlyMinor,
  required BigInt fixedExpenseMonthlyMinor,
}) {
  double? savingsRate;
  if (incomeMinor > BigInt.zero) {
    savingsRate =
        (incomeMinor - expenseMinor).toDouble() / incomeMinor.toDouble();
  }
  double? emergencyMonths;
  if (avgMonthlyEssentialMinor > BigInt.zero) {
    emergencyMonths =
        liquidAssetsMinor.toDouble() / avgMonthlyEssentialMinor.toDouble();
  }
  double? debtToAsset;
  if (totalAssetsMinor > BigInt.zero) {
    debtToAsset =
        totalLiabilitiesMinor.toDouble() / totalAssetsMinor.toDouble();
  }
  double? passiveCushion;
  if (fixedExpenseMonthlyMinor > BigInt.zero) {
    passiveCushion =
        fixedIncomeMonthlyMinor.toDouble() /
        fixedExpenseMonthlyMinor.toDouble();
  }
  return FinancialHealth(
    savingsRate: savingsRate,
    emergencyMonths: emergencyMonths,
    debtToAsset: debtToAsset,
    passiveCushion: passiveCushion,
  );
}
