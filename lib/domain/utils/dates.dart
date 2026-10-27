/// 日期工具：月度步进与月末/闰年处理。
library;

/// 在 [date] 基础上加 [months] 个月，保持“日”尽量不变；
/// 目标月没有该日时按 [MonthEndPolicy] 处理（默认 clampToMonthEnd）。
enum MonthEndPolicy {
  /// 1月31日 → 2月28/29日。
  clampToMonthEnd,
  /// 1月31日 → 2月28日 → 3月28日（顺延回退后保持新锚点）。
  shiftBackKeepAnchor,
  /// 1月31日 → 3月1日（跨到下月）。
  shiftForward,
}

DateTime addMonthsClamped(DateTime date, int months, {MonthEndPolicy policy = MonthEndPolicy.clampToMonthEnd}) {
  final targetMonthIndex = (date.month - 1) + months;
  var year = date.year + targetMonthIndex ~/ 12;
  var month = targetMonthIndex % 12 + 1;
  if (date.day == _daysInMonth(date.year, date.month) && policy == MonthEndPolicy.clampToMonthEnd) {
    // 锚点即月末：始终落在目标月末。
    return DateTime(year, month, _daysInMonth(year, month));
  }
  final maxDay = _daysInMonth(year, month);
  var day = date.day;
  if (day > maxDay) {
    switch (policy) {
      case MonthEndPolicy.clampToMonthEnd:
        day = maxDay;
      case MonthEndPolicy.shiftForward:
        // 溢出天数顺延到下个月：1月31日 + 1月 → 3月3日。
        final overflow = day - maxDay;
        return DateTime(year, month, maxDay).add(Duration(days: overflow));
      case MonthEndPolicy.shiftBackKeepAnchor:
        day = maxDay;
    }
  }
  return DateTime(year, month, day);
}

int _daysInMonth(int year, int month) {
  switch (month) {
    case 1 || 3 || 5 || 7 || 8 || 10 || 12:
      return 31;
    case 4 || 6 || 9 || 11:
      return 30;
    case 2:
      return isLeapYear(year) ? 29 : 28;
  }
  throw ArgumentError(month.toString());
}

bool isLeapYear(int year) =>
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

DateTime endOfMonth(DateTime d) => DateTime(d.year, d.month, _daysInMonth(d.year, d.month));

DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// 无时区语义的本地日期比较键（yyyy-MM-dd）。
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String monthKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

/// 本月已过天数（含今天）。
int dayOfMonthNow(DateTime now) => now.day;

/// 两个日期间的整月数（向下取整）。
int monthsBetween(DateTime from, DateTime to) {
  if (to.isBefore(from)) return -monthsBetween(to, from);
  var m = (to.year - from.year) * 12 + (to.month - from.month);
  if (to.day < from.day) m -= 1;
  return m;
}
