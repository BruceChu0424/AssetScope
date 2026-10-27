import '../utils/dates.dart';

/// 周期类型。
enum Cadence {
  weekly('每周'),
  biweekly('每两周'),
  monthly('每月'),
  quarterly('每季'),
  yearly('每年'),
  customInterval('自定义间隔'),
  once('单次');

  const Cadence(this.labelZh);
  final String labelZh;
}

enum EventDirection { inflow('收入'), outflow('支出');
  const EventDirection(this.labelZh);
  final String labelZh;
}

enum PlanStatus { active, paused, finished, cancelled }

/// 固定开销/预定支出计划。
///
/// 金额支持三档：固定值（[amountMinor]）、区间估算（[amountLow]/[amountHigh]）。
/// 覆盖：试用期结束涨价、单次跳过、从某月起改金额，通过 [overrides] 表达。
class ScheduledEvent {
  const ScheduledEvent({
    required this.id,
    required this.name,
    required this.direction,
    required this.currencyCode,
    required this.cadence,
    required this.anchorDate,
    this.amountMinor,
    this.amountLowMinor,
    this.amountHighMinor,
    this.intervalValue = 1,
    this.monthEndPolicy = MonthEndPolicy.clampToMonthEnd,
    this.endDate,
    this.paymentAccountId,
    this.categoryId,
    this.autoPost = false,
    this.notes,
    this.status = PlanStatus.active,
    this.skippedMonthKeys = const {},
    this.amountOverrides = const {},
  });

  final String id;
  final String name;
  final EventDirection direction;
  final String currencyCode;
  final Cadence cadence;

  /// 锚点日：周期从这天开始；每月周期代表“每月几号”。
  final DateTime anchorDate;

  final BigInt? amountMinor;
  final BigInt? amountLowMinor;
  final BigInt? amountHighMinor;

  /// customInterval 的步长（配合 cadence 的单位）。
  final int intervalValue;
  final MonthEndPolicy monthEndPolicy;
  final DateTime? endDate;
  final String? paymentAccountId;
  final String? categoryId;
  final bool autoPost;
  final String? notes;
  final PlanStatus status;

  /// 跳过的月份（yyyy-MM）。
  final Set<String> skippedMonthKeys;

  /// 从某月（yyyy-MM，含）起生效的金额覆盖。
  final Map<String, BigInt> amountOverrides;

  bool get isEstimate => amountMinor == null;

  /// 计划金额：固定值优先；区间取中位数（估算）。
  BigInt resolvedAmountMinor({String? monthKey}) {
    if (monthKey != null) {
      for (final e in amountOverrides.entries) {
        if (e.key.compareTo(monthKey) <= 0) return e.value;
      }
    }
    final fixed = amountMinor;
    if (fixed != null) return fixed;
    final low = amountLowMinor ?? BigInt.zero;
    final high = amountHighMinor ?? low;
    return (low + high) ~/ BigInt.two;
  }

  /// 展开 [from, to]（含端点）内的所有预期发生日。
  List<Occurrence> expand(DateTime from, DateTime to) {
    if (status == PlanStatus.paused || status == PlanStatus.cancelled) return const [];
    final out = <Occurrence>[];
    switch (cadence) {
      case Cadence.once:
        final d = anchorDate;
        if (!_inRange(d, from, to)) break;
        _emit(out, d);
      case Cadence.weekly:
        _step(out, from, to, (d) => d.add(Duration(days: 7 * intervalValue)));
      case Cadence.biweekly:
        _step(out, from, to, (d) => d.add(const Duration(days: 14)));
      case Cadence.monthly:
        _step(out, from, to,
            (d) => addMonthsClamped(d, intervalValue, policy: monthEndPolicy));
      case Cadence.quarterly:
        _step(out, from, to,
            (d) => addMonthsClamped(d, 3 * intervalValue, policy: monthEndPolicy));
      case Cadence.yearly:
        _step(out, from, to,
            (d) => addMonthsClamped(d, 12 * intervalValue, policy: monthEndPolicy));
      case Cadence.customInterval:
        _step(out, from, to,
            (d) => addMonthsClamped(d, intervalValue, policy: monthEndPolicy));
    }
    return out;
  }

  void _step(List<Occurrence> out, DateTime from, DateTime to, DateTime Function(DateTime) advance) {
    var d = anchorDate;
    // 先推进到窗口内。
    var guard = 0;
    while (d.isBefore(from) && guard++ < 100000) {
      d = advance(d);
    }
    guard = 0;
    while (_inRange(d, from, to) && guard++ < 100000) {
      _emit(out, d);
      d = advance(d);
    }
  }

  void _emit(List<Occurrence> out, DateTime d) {
    if (endDate != null && d.isAfter(endDate!)) return;
    final mk = monthKey(d);
    if (skippedMonthKeys.contains(mk)) return;
    final amount = resolvedAmountMinor(monthKey: mk);
    if (amount == BigInt.zero) return;
    out.add(Occurrence(
      eventId: id,
      eventName: name,
      date: d,
      amountMinor: direction == EventDirection.outflow ? -amount : amount,
      isEstimate: isEstimate,
      paymentAccountId: paymentAccountId,
      categoryId: categoryId,
    ));
  }

  bool _inRange(DateTime d, DateTime from, DateTime to) =>
      !d.isBefore(from) && !d.isAfter(to);
}

/// 一次计划发生。
class Occurrence {
  const Occurrence({
    required this.eventId,
    required this.eventName,
    required this.date,
    required this.amountMinor,
    required this.isEstimate,
    this.paymentAccountId,
    this.categoryId,
  });

  final String eventId;
  final String eventName;
  final DateTime date;

  /// 带符号（收入 + / 支出 −），单位：计划币种最小单位。
  final BigInt amountMinor;
  final bool isEstimate;
  final String? paymentAccountId;
  final String? categoryId;
}

/// 目标（大额支出准备金）：装修、旅行、保险年费、学费、购车等。
class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmountMinor,
    required this.targetDate,
    this.priority = 0,
    required this.reservedAmountMinor,
    this.fundingAccountIds = const [],
    this.notes,
    this.status = GoalStatus.active,
  });

  final String id;
  final String name;
  final BigInt targetAmountMinor;
  final DateTime targetDate;
  final int priority;

  /// 已预留资金（仍属于资产，只是用途被锁定）。
  final BigInt reservedAmountMinor;
  final List<String> fundingAccountIds;
  final String? notes;
  final GoalStatus status;

  BigInt get gapMinor => targetAmountMinor - reservedAmountMinor;

  /// 距目标日期还需每月预留的金额；已过期或无剩余期数时返回 null（只显示缺口）。
  BigInt? monthlyNeedMinor(DateTime now) {
    if (status != GoalStatus.active) return null;
    if (gapMinor <= BigInt.zero) return BigInt.zero;
    final months = monthsBetween(now, targetDate) + 1;
    if (months <= 0) return null;
    final monthsB = BigInt.from(months);
    final q = gapMinor ~/ monthsB;
    final r = gapMinor.remainder(monthsB);
    return r == BigInt.zero ? q : q + BigInt.one;
  }
}

enum GoalStatus { active, achieved, cancelled }
