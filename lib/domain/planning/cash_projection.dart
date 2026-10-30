import '../money/currency.dart';
import '../money/fx_rate.dart';
import '../money/money.dart';
import '../utils/dates.dart';

/// 预测中的现金事件（已折算为本位币、带符号）。
class CashEvent {
  const CashEvent({
    required this.date,
    required this.amountBaseMinor,
    required this.label,
    this.accountId,
    this.isEstimate = false,
    this.kind = CashEventKind.planned,
  });

  final DateTime date;

  /// 本位币最小单位；正=流入，负=流出。
  final BigInt amountBaseMinor;
  final String label;
  final String? accountId;
  final bool isEstimate;
  final CashEventKind kind;
}

enum CashEventKind { planned, debtRepay, budgetBaseline, incomeExpected, other }

/// 参与预测的现金账户及其当前余额。
class CashAccountSnapshot {
  const CashAccountSnapshot({
    required this.accountId,
    required this.name,
    required this.currencyCode,
    required this.balanceMinor,
    required this.toBaseRate,
  });

  final String accountId;
  final String name;
  final String currencyCode;

  /// 账户币种最小单位余额。
  final BigInt balanceMinor;

  /// 账户币种 → 本位币 汇率（有理数）。
  final Rational toBaseRate;

  BigInt get balanceBaseMinor =>
      (Rational.fromInt(balanceMinor) * toBaseRate).rounded();
}

/// 准备金占用：到 [date]（含）之后该笔占用释放（对应支出已付/目标已达成）。
class ReserveRelease {
  const ReserveRelease({required this.date, required this.amountBaseMinor});

  final DateTime date;
  final BigInt amountBaseMinor;
}

/// 现金预测输入。
class ProjectionInput {
  const ProjectionInput({
    required this.baseCurrencyCode,
    required this.accounts,
    required this.events,
    required this.reserveBaseMinor,
    required this.baselineMinCashBaseMinor,
    required this.fromDate,
    required this.horizonDays,
    this.reserveReleases = const [],
  });

  final String baseCurrencyCode;
  final List<CashAccountSnapshot> accounts;
  final List<CashEvent> events;

  /// 准备金占用（目标预留 + 应急金，已含在现金余额中，只扣一次）。
  final BigInt reserveBaseMinor;

  /// 准备金释放计划：对应支出发生后占用解除，避免“付款 + 占用”双扣。
  final List<ReserveRelease> reserveReleases;

  /// 额外最低现金底线（应急金若已计入准备金则不得重复计入）。
  final BigInt baselineMinCashBaseMinor;

  /// 预测起点（含当天）。
  final DateTime fromDate;
  final int horizonDays;
}

class ProjectionPoint {
  const ProjectionPoint(this.date, this.balanceBaseMinor);
  final DateTime date;
  final BigInt balanceBaseMinor;
}

class CashShortfall {
  const CashShortfall({
    required this.date,
    required this.amountBaseMinor,
    required this.label,
    this.accountId,
  });

  final DateTime date;
  final BigInt amountBaseMinor;
  final String label;
  final String? accountId;
}

/// 现金预测结果。
class CashProjection {
  const CashProjection({
    required this.series,
    required this.minBalanceBaseMinor,
    required this.minBalanceDate,
    required this.discretionaryBaseMinor,
    required this.shortfalls,
    required this.reserveBaseMinor,
    required this.baselineMinCashBaseMinor,
    required this.throughDate,
  });

  /// 每日现金曲线（本位币）。
  final List<ProjectionPoint> series;
  final BigInt minBalanceBaseMinor;
  final DateTime? minBalanceDate;

  /// 计划外可额外安排的支出上限 = max(0, min_t[C(t) − R − B])。
  final BigInt discretionaryBaseMinor;

  /// 资金缺口事件（总体或单账户）。
  final List<CashShortfall> shortfalls;

  final BigInt reserveBaseMinor;
  final BigInt baselineMinCashBaseMinor;
  final DateTime throughDate;

  bool get hasShortfall => shortfalls.isNotEmpty;
}

/// 预测算法：
///
/// C(t) = Σ账户余额(折本位币) + Σ events(date ≤ t)
/// 计划外可支配额 = max(0, min_t [C(t) − R(t) − B(t)])，
/// v1 中 R(t)、B(t) 在预测期内取常数（保守口径，见 docs/05）。
///
/// 防重复扣减规则：
/// - 期初余额包含已预留现金，准备金只在公式中扣一次；
/// - 事件列表中不应包含“已实际支付”的计划（由服务层过滤）；
/// - 信用卡消费与其还款只能出现一次（消费占用现金预测中的还款流出）。
class CashProjector {
  const CashProjector._();

  static CashProjection project(ProjectionInput input) {
    final start = input.accounts.fold(
      BigInt.zero,
      (s, a) => s + a.balanceBaseMinor,
    );

    final through = input.fromDate.add(Duration(days: input.horizonDays));

    // 事件按日聚合；同日内顺序不明时，支出先于收入（保守情景）。
    final eventsByDay = <String, List<CashEvent>>{};
    for (final e in input.events) {
      if (e.date.isBefore(input.fromDate) || e.date.isAfter(through)) continue;
      eventsByDay.putIfAbsent(dateKey(e.date), () => []).add(e);
    }

    final series = <ProjectionPoint>[];
    var balance = start;
    var minBalance = start;
    DateTime? minDate;
    series.add(ProjectionPoint(input.fromDate, balance));
    final days = input.horizonDays;
    var reserveNow = input.reserveBaseMinor;
    var floor = start - reserveNow - input.baselineMinCashBaseMinor;
    var minFloor = floor;

    // 释放计划按日期排序，逐日推进占用。
    final releases = [...input.reserveReleases]
      ..sort((a, b) => a.date.compareTo(b.date));
    var releaseIdx = 0;

    for (var i = 1; i <= days; i++) {
      final d = input.fromDate.add(Duration(days: i));
      while (releaseIdx < releases.length &&
          !releases[releaseIdx].date.isAfter(d)) {
        reserveNow -= releases[releaseIdx].amountBaseMinor;
        releaseIdx++;
      }
      final evs = eventsByDay[dateKey(d)];
      if (evs != null) {
        // 先扣流出再计流入（日内顺序未知时的保守处理）。
        final sorted = [...evs]
          ..sort((a, b) => a.amountBaseMinor.compareTo(b.amountBaseMinor));
        for (final e in sorted) {
          balance += e.amountBaseMinor;
        }
      }
      series.add(ProjectionPoint(d, balance));
      if (balance < minBalance) {
        minBalance = balance;
        minDate = d;
      }
      final f = balance - reserveNow - input.baselineMinCashBaseMinor;
      if (f < minFloor) minFloor = f;
    }

    final discretionary = minFloor > BigInt.zero ? minFloor : BigInt.zero;

    // 缺口检测：总体低于（准备金+底线）视为缺口；负余额为严重缺口。
    // 逐日重放（含释放）以复现每日占用。
    final shortfalls = <CashShortfall>[];
    var bal = start;
    var reserve = input.reserveBaseMinor;
    var ri = 0;
    final cushionAt = <DateTime, BigInt>{};
    cushionAt[input.fromDate] = bal - reserve - input.baselineMinCashBaseMinor;
    for (var i = 1; i <= days; i++) {
      final d = input.fromDate.add(Duration(days: i));
      while (ri < releases.length && !releases[ri].date.isAfter(d)) {
        reserve -= releases[ri].amountBaseMinor;
        ri++;
      }
      final evs = eventsByDay[dateKey(d)];
      if (evs != null) {
        final sorted = [...evs]
          ..sort((a, b) => a.amountBaseMinor.compareTo(b.amountBaseMinor));
        for (final e in sorted) {
          bal += e.amountBaseMinor;
        }
      }
      cushionAt[d] = bal - reserve - input.baselineMinCashBaseMinor;
    }
    for (final e in cushionAt.entries) {
      if (e.value < BigInt.zero) {
        shortfalls.add(
          CashShortfall(
            date: e.key,
            amountBaseMinor: e.value,
            label: '低于准备金与现金底线',
          ),
        );
      }
    }

    // 单账户维度：同一账户的事件流独立检查（总现金充足≠每张卡充足）。
    for (final acc in input.accounts) {
      final accEvents = <CashEvent>[];
      for (final e in input.events) {
        if (e.accountId == acc.accountId &&
            !e.date.isBefore(input.fromDate) &&
            !e.date.isAfter(through)) {
          accEvents.add(e);
        }
      }
      if (accEvents.isEmpty) continue;
      accEvents.sort((a, b) => a.date.compareTo(b.date));
      var bal = acc.balanceMinor;
      for (final e in accEvents) {
        bal += e.amountBaseMinor;
        if (bal < BigInt.zero) {
          shortfalls.add(
            CashShortfall(
              date: e.date,
              amountBaseMinor: e.amountBaseMinor,
              label: '账户 ${acc.name} 可能余额不足',
              accountId: acc.accountId,
            ),
          );
          break; // 每账户只报首个缺口
        }
      }
    }

    return CashProjection(
      series: series,
      minBalanceBaseMinor: minBalance,
      minBalanceDate: minDate,
      discretionaryBaseMinor: discretionary,
      shortfalls: shortfalls,
      reserveBaseMinor: input.reserveBaseMinor,
      baselineMinCashBaseMinor: input.baselineMinCashBaseMinor,
      throughDate: through,
    );
  }
}

/// 便利：把 [Money] 折算成本位币最小单位（服务层构造事件时用）。
BigInt toBaseMinor(
  Money amount,
  Rational toBaseRate,
  CurrencyInfo baseCurrency,
) {
  if (amount.currency.code == baseCurrency.code) return amount.amountMinor;
  return (Rational.fromInt(amount.amountMinor) * toBaseRate).rounded();
}
