import '../money/fx_rate.dart';

/// 预算信封的月中执行预测：按当前配速外推到月末 + 剩余日均可花建议。
///
/// 口径：预测已花 = spent × daysInMonth / daysElapsed（与洞察层消费配速
/// 同源的线性外推）；建议日均 = max(0, 限额 − 已花) ÷ 剩余天数（向下取整，
/// 不给"刚好花完"的乐观额度）。月初（daysElapsed = 0）无法外推 → null。
class BudgetForecast {
  const BudgetForecast({
    required this.projectedMinor,
    required this.suggestedDailyMinor,
    required this.willExceed,
    required this.daysLeft,
  });

  /// 预测月末累计已花（线性外推，halfEven 取整到最小单位）。
  final BigInt projectedMinor;

  /// 剩余每天可花（保守向下取整；超支后为 0）。
  final BigInt suggestedDailyMinor;

  /// 按当前配速月末将超支。
  final bool willExceed;

  final int daysLeft;

  static BudgetForecast? of({
    required BigInt spentMinor,
    required BigInt limitMinor,
    required int daysElapsed,
    required int daysInMonth,
  }) {
    if (daysElapsed <= 0 || daysInMonth <= 0) return null;
    final daysLeft = daysInMonth - daysElapsed;
    final s = Rational.fromInt(spentMinor);
    final projected = daysLeft == 0
        ? spentMinor
        : (s *
                  Rational.fromInt(BigInt.from(daysInMonth)) /
                  Rational.fromInt(BigInt.from(daysElapsed)))
              .rounded();
    final room = limitMinor - spentMinor;
    final daily = (room <= BigInt.zero || daysLeft <= 0)
        ? BigInt.zero
        : (Rational.fromInt(room) / Rational.fromInt(BigInt.from(daysLeft)))
              .rounded();
    return BudgetForecast(
      projectedMinor: projected,
      suggestedDailyMinor: daily,
      willExceed: projected > limitMinor,
      daysLeft: daysLeft,
    );
  }
}
