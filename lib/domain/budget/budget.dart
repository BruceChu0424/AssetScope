import '../../l10n/runtime_l10n.dart';

/// 预算：月度总额度或分类额度。
enum BudgetScope {
  total('总预算'),
  category('分类预算');

  const BudgetScope(this._labelZh);
  final String _labelZh;
  String get labelZh => rt(_labelZh);
}

enum RolloverPolicy {
  none('不结转'),
  all('全额结转'),
  capTo('结转并设上限');

  const RolloverPolicy(this._labelZh);
  final String _labelZh;
  String get labelZh => rt(_labelZh);
}

class Budget {
  const Budget({
    required this.id,
    required this.name,
    required this.scope,
    required this.limitMinor,
    required this.currencyCode,
    required this.startMonthKey,
    this.categoryId,
    this.endMonthKey,
    this.rollover = RolloverPolicy.none,
    this.rolloverCapMinor,
    this.active = true,
  });

  final String id;
  final String name;
  final BudgetScope scope;
  final BigInt limitMinor;
  final String currencyCode;

  /// 生效起始月 yyyy-MM。
  final String startMonthKey;
  final String? categoryId;
  final String? endMonthKey;
  final RolloverPolicy rollover;
  final BigInt? rolloverCapMinor;
  final bool active;

  bool coversMonth(String monthKey) =>
      active &&
      startMonthKey.compareTo(monthKey) <= 0 &&
      (endMonthKey == null || monthKey.compareTo(endMonthKey!) <= 0);
}

/// 单月预算信封：额度 + 滚入 − 已花 − 已计划 − 已预留 = 剩余。
class BudgetEnvelope {
  const BudgetEnvelope({
    required this.budgetId,
    required this.name,
    required this.monthKey,
    required this.limitMinor,
    required this.carriedInMinor,
    required this.spentMinor,
    required this.plannedMinor,
    required this.reservedMinor,
    required this.overspentCarryMinor,
  });

  final String budgetId;
  final String name;
  final String monthKey;

  /// 本月自身额度。
  final BigInt limitMinor;

  /// 上月结转进入（按结转策略；超支月为 0 或负，见策略）。
  final BigInt carriedInMinor;

  /// 已花：本月消费发生额（信用卡消费在消费时即占用；退款冲减；
  /// 信用卡还款、贷款本金不占用）。
  final BigInt spentMinor;

  /// 已计划：本月尚未发生、但已被计划支出占用的额度。
  final BigInt plannedMinor;

  /// 已预留：已划入准备金的额度。
  final BigInt reservedMinor;

  /// 历史超支待分摊（v1 只展示，不自动扣减）。
  final BigInt overspentCarryMinor;

  BigInt get availableMinor =>
      limitMinor + carriedInMinor - overspentCarryMinor;

  BigInt get remainingMinor =>
      availableMinor - spentMinor - plannedMinor - reservedMinor;

  double get usedRatio => limitMinor == BigInt.zero
      ? 0
      : spentMinor.toDouble() / limitMinor.toDouble();
}

/// 纯函数：计算上月结转进入本月的额度（服务层提供上月剩余）。
BigInt carriedIn({
  required Budget budget,
  required BigInt previousRemainingMinor,
}) {
  switch (budget.rollover) {
    case RolloverPolicy.none:
      return BigInt.zero;
    case RolloverPolicy.all:
      return previousRemainingMinor > BigInt.zero
          ? previousRemainingMinor
          : BigInt.zero;
    case RolloverPolicy.capTo:
      if (previousRemainingMinor <= BigInt.zero) return BigInt.zero;
      final cap = budget.rolloverCapMinor ?? BigInt.zero;
      return previousRemainingMinor < cap ? previousRemainingMinor : cap;
  }
}

/// 纯函数：本月剩余结转到下月（负数=超支不结转的口径下取 0）。
BigInt carryOut({required Budget budget, required BigInt remainingMinor}) {
  switch (budget.rollover) {
    case RolloverPolicy.none:
      return BigInt.zero;
    case RolloverPolicy.all:
    case RolloverPolicy.capTo:
      return remainingMinor > BigInt.zero ? remainingMinor : BigInt.zero;
  }
}
