import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/planning/cash_projection.dart';
import '../../domain/planning/recurrence.dart';
import '../../domain/utils/dates.dart';

/// 沉浸式详情页数据层 · 其二：情景重放 / 未来支出 / 待处理任务。

// ─────────────────────────────────────────────────────────────────────────
// 还能花多少 · 三情景重放
// ─────────────────────────────────────────────────────────────────────────

enum OvScenarioKind { conservative, standard, optimistic }

// ─────────────────────────────────────────────────────────────────────────
// 未来 30 天 · 计划支出全景
// ─────────────────────────────────────────────────────────────────────────

enum OvUpcomingStatus { pending, posted, overdue }

class OvScenarios {
  const OvScenarios({
    required this.base,
    required this.horizonDays,
    required this.cashNow,
    required this.reserve,
    required this.baseline,
    required this.results,
    required this.inflow,
    required this.outflow,
  });

  /// 标准情景完整输入元数据（页面展示可用流动资金等）。
  final ProjectionInput base;
  final int horizonDays;
  final BigInt cashNow;
  final BigInt reserve;
  final BigInt baseline;

  /// 情景 → 重放结果。
  final Map<OvScenarioKind, CashProjection> results;

  /// 期内预计流入 / 流出（标准口径，本位币）。
  final BigInt inflow;
  final BigInt outflow;
}

/// 三情景现金重放（ProjectionService.buildInput 专为情景模拟暴露）：
/// - 保守：剔除**估算收入**（只信已确认的流入，流出全留）；
/// - 标准：全部事件照算（与首页预测同口径）；
/// - 乐观：再剔除**估算支出**（可压缩的开销不计）。
/// 同一份期初余额与准备金，只有事件流不同——差异完全可解释。
final scenarioProvider = FutureProvider.autoDispose<OvScenarios>((
  ref,
) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) throw StateError('locked');
  final input = await s.projectionService.buildInput(
    horizonDays: s.projectionHorizonDays,
  );

  CashProjection replay(bool Function(CashEvent e) drop) =>
      CashProjector.project(
        ProjectionInput(
          baseCurrencyCode: input.baseCurrencyCode,
          accounts: input.accounts,
          events: [
            for (final e in input.events)
              if (!drop(e)) e,
          ],
          reserveBaseMinor: input.reserveBaseMinor,
          reserveReleases: input.reserveReleases,
          baselineMinCashBaseMinor: input.baselineMinCashBaseMinor,
          fromDate: input.fromDate,
          horizonDays: input.horizonDays,
        ),
      );

  final standard = CashProjector.project(input);
  final conservative = replay(
    (e) => e.amountBaseMinor > BigInt.zero && e.isEstimate,
  );
  final optimistic = replay(
    (e) => e.amountBaseMinor < BigInt.zero && e.isEstimate,
  );

  var inflow = BigInt.zero;
  var outflow = BigInt.zero;
  for (final e in input.events) {
    if (e.amountBaseMinor.isNegative) {
      outflow += -e.amountBaseMinor;
    } else {
      inflow += e.amountBaseMinor;
    }
  }

  return OvScenarios(
    base: input,
    horizonDays: input.horizonDays,
    cashNow: input.accounts.fold(
      BigInt.zero,
      (a, x) => a + x.balanceBaseMinor,
    ),
    reserve: input.reserveBaseMinor,
    baseline: input.baselineMinCashBaseMinor,
    results: {
      OvScenarioKind.conservative: conservative,
      OvScenarioKind.standard: standard,
      OvScenarioKind.optimistic: optimistic,
    },
    inflow: inflow,
    outflow: outflow,
  );
});

// ─────────────────────────────────────────────────────────────────────────
// 未来 30 天 · 计划支出全景
// ─────────────────────────────────────────────────────────────────────────

class OvUpcomingItem {
  const OvUpcomingItem({
    required this.occ,
    required this.paymentAccountName,
    required this.status,
  });

  final Occurrence occ;
  final String? paymentAccountName;
  final OvUpcomingStatus status;

  bool get isOutflow => occ.amountMinor.isNegative;
}

class OvUpcomingData {
  OvUpcomingData({
    required this.items,
    required this.recurring,
    required this.base,
  });

  /// 未来 30 天 + 已逾期未落地（合并去重，升序）。
  final List<OvUpcomingItem> items;

  /// (事件, 下次发生日)：周期性固定支出/收入清单。
  final List<(ScheduledEvent, DateTime)> recurring;

  final String base;

  Iterable<OvUpcomingItem> get outflows =>
      items.where((i) => i.isOutflow && i.status != OvUpcomingStatus.posted);

  BigInt get totalPlanned => outflows.fold(
    BigInt.zero,
    (a, x) => a + x.occ.amountMinor.abs(),
  );

  BigInt get due7d => outflows
      .where(
        (i) =>
            !i.occ.date.isAfter(DateTime.now().add(const Duration(days: 7))) &&
            !i.occ.date.isBefore(DateTime.now()),
      )
      .fold(BigInt.zero, (a, x) => a + x.occ.amountMinor.abs());

  BigInt get fixedTotal => recurring
      .where((r) => r.$1.direction == EventDirection.outflow)
      .fold(BigInt.zero, (a, x) => a + (x.$1.amountMinor?.abs() ?? BigInt.zero));
}

final upcomingDetailProvider = FutureProvider.autoDispose<OvUpcomingData>((
  ref,
) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) throw StateError('locked');
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final through = today.add(const Duration(days: 30));
  final events = await s.planning.scheduledEvents();
  final posted = await s.ledger.externalIds();
  final accounts = await s.accounts.all();
  final byId = {for (final a in accounts) a.id: a};

  final items = <OvUpcomingItem>[];
  final seen = <String>{};
  for (final e in events) {
    if (!e.isActive) continue;
    for (final occ in e.expand(today, through)) {
      final key = planExternalId(e.id, occ.date);
      if (!seen.add(key)) continue;
      final isPosted = posted.contains(key);
      items.add(
        OvUpcomingItem(
          occ: occ,
          paymentAccountName: occ.paymentAccountId == null
              ? null
              : byId[occ.paymentAccountId]?.name,
          status: occ.date.isBefore(today) && !isPosted
              ? OvUpcomingStatus.overdue
              : (isPosted
                    ? OvUpcomingStatus.posted
                    : OvUpcomingStatus.pending),
        ),
      );
    }
  }
  // 逾期回溯（30 天前起未落地的发生——past-due 一并纳入清单）。
  for (final d in await s.planExecution.pendingDue(now: now, lookbackDays: 30)) {
    final key = planExternalId(d.event.id, d.occurrence.date);
    if (seen.contains(key)) continue;
    if (!seen.add(key)) continue;
    items.add(
      OvUpcomingItem(
        occ: d.occurrence,
        paymentAccountName: d.occurrence.paymentAccountId == null
            ? null
            : byId[d.occurrence.paymentAccountId]?.name,
        status: OvUpcomingStatus.overdue,
      ),
    );
  }
  items.sort((a, b) => a.occ.date.compareTo(b.occ.date));

  final recurring = <(ScheduledEvent, DateTime)>[];
  final yearAhead = today.add(const Duration(days: 365));
  for (final e in events) {
    if (!e.isActive) continue;
    final next = e.expand(today, yearAhead);
    if (next.isEmpty) continue; // 一年内无发生：不列入周期清单
    recurring.add((e, next.first.date));
  }
  recurring.sort((a, b) => a.$2.compareTo(b.$2));

  return OvUpcomingData(
    items: items,
    recurring: recurring,
    base: await s.meta.settingString('baseCurrency') ?? 'CNY',
  );
});

// ─────────────────────────────────────────────────────────────────────────
// 待处理任务
// ─────────────────────────────────────────────────────────────────────────

enum OvTaskType { duePlan, missingValuation, staleValuation, residual, shortfall }

enum OvTaskPriority { high, medium, low }

class OvTask {
  const OvTask({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.dueDate,
    required this.route,
  });

  final String id;
  final OvTaskType type;
  final String title;
  final String subtitle;
  final DateTime? dueDate;

  /// 处理入口（go_router 路径）。
  final String route;

  OvTaskPriority get priority {
    switch (type) {
      case OvTaskType.duePlan:
        final d = dueDate!;
        final today = DateTime.now();
        final t0 = DateTime(today.year, today.month, today.day);
        if (d.isBefore(t0)) return OvTaskPriority.high;
        if (d.isBefore(t0.add(const Duration(days: 3)))) {
          return OvTaskPriority.high;
        }
        return OvTaskPriority.medium;
      case OvTaskType.missingValuation:
      case OvTaskType.residual:
      case OvTaskType.shortfall:
        return OvTaskPriority.high;
      case OvTaskType.staleValuation:
        return OvTaskPriority.low;
    }
  }
}

class OvInboxData {
  OvInboxData({required this.tasks, required this.asOf});

  final List<OvTask> tasks;
  final DateTime asOf;

  int count(OvTaskType t) => tasks.where((x) => x.type == t).length;
  int get highCount =>
      tasks.where((x) => x.priority == OvTaskPriority.high).length;
}

/// 全部真实待办：到期计划 / 缺估值 / 估值过期 / 待核对差额 / 资金缺口
/// 预警。不造一条假任务——清单为空就是干净的空状态。
final inboxProvider = FutureProvider.autoDispose<OvInboxData>((ref) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) throw StateError('locked');
  final now = DateTime.now();
  final tasks = <OvTask>[];

  for (final d in await s.planExecution.pendingDue(now: now)) {
    tasks.add(
      OvTask(
        id: 'due:${d.externalId}',
        type: OvTaskType.duePlan,
        title: d.occurrence.eventName,
        subtitle: d.autoReady
            ? ''
            : (d.blockedReason ?? ''),
        dueDate: d.occurrence.date,
        route: '/plans',
      ),
    );
  }

  final nw = await s.statsService.netWorthAt(now);
  for (final i in nw.items) {
    if (i.valuationMissing) {
      tasks.add(
        OvTask(
          id: 'miss:${i.account.id}',
          type: OvTaskType.missingValuation,
          title: i.account.name,
          dueDate: null,
          route: '/assets',
          subtitle: '',
        ),
      );
    } else if (i.valuationStale) {
      tasks.add(
        OvTask(
          id: 'stale:${i.account.id}',
          type: OvTaskType.staleValuation,
          title: i.account.name,
          subtitle: '',
          route: '/assets',
        ),
      );
    }
  }

  final report = await s.statsService.monthReport(now.year, now.month);
  if (report.attribution.hasResidual) {
    tasks.add(
      OvTask(
        id: 'residual:${dateKey(now)}',
        type: OvTaskType.residual,
        title: report.attribution.residual.abs().toString(),
        subtitle: '',
        route: '/reports',
      ),
    );
  }

  final proj = await s.projectionService.project(
    horizonDays: s.projectionHorizonDays,
  );
  for (final sf in proj.shortfalls.take(6)) {
    tasks.add(
      OvTask(
        id: 'short:${dateKey(sf.date)}:${sf.label}',
        type: OvTaskType.shortfall,
        title: sf.label,
        subtitle: '',
        dueDate: sf.date,
        route: '/spendable',
      ),
    );
  }

  tasks.sort((a, b) {
    final p = a.priority.index.compareTo(b.priority.index);
    if (p != 0) return p;
    final ad = a.dueDate, bd = b.dueDate;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return ad.compareTo(bd);
  });

  return OvInboxData(tasks: tasks, asOf: now);
});
