import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/planning/recurrence.dart';
import '../../domain/utils/dates.dart';
import '../../services/plan_execution_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'life_planner_sheet.dart';
import 'plan_edit_dialog.dart';
import 'plan_fields.dart';
import 'plan_post_sheet.dart';
import 'recurring_sheet.dart';
import 'scenario_sheet.dart';

/// 固定开销与预定支出计划：待落地（到期未入账）→ 一键/逐笔记入账本。
class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_plansProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('固定开销 / 计划'),
        actions: [
          IconButton(
            tooltip: '人生规划 · 多年度推演',
            icon: const Icon(Icons.explore_outlined),
            onPressed: () => showLifePlannerSheet(context, ref),
          ),
          IconButton(
            tooltip: '情景模拟 · 现金压力测试',
            icon: const Icon(Icons.shield_outlined),
            onPressed: () => showScenarioSheet(context, ref),
          ),
          IconButton(
            tooltip: '从流水识别固定收支',
            icon: const Icon(Icons.auto_awesome),
            onPressed: () async {
              await showRecurringSheet(context, ref);
              ref.invalidate(_plansProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok = await showDialog<bool>(
              context: context, builder: (_) => const PlanEditDialog());
          if (ok == true) ref.invalidate(_plansProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('新建计划'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorPlaceholder('加载失败：$e'),
        data: (view) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            if (view.due.isNotEmpty) _DueCard(due: view.due),
            _UpcomingBlock(occurrences: view.upcoming),
            const Divider(height: 32),
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text('全部计划'),
            ),
            if (view.events.isEmpty)
              const EmptyState(
                  icon: Icons.event_outlined,
                  title: '还没有计划',
                  message: '点右下角"新建计划"，或用识别功能从流水中生成。'),
            for (final e in view.events)
              _PlanTile(
                event: e,
                onChanged: () => ref.invalidate(_plansProvider),
              ),
          ],
        ),
      ),
    );
  }
}

/// 到期待落地区：逐笔记入（可改金额/账户）或一键全部记入。
class _DueCard extends ConsumerWidget {
  const _DueCard({required this.due});

  final List<DueOccurrence> due;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final net = due.fold<BigInt>(
        BigInt.zero, (s, d) => s + d.occurrence.amountMinor);
    final blocked = due.where((d) => d.blockedReason != null).length;
    return SectionCard(
      title: '待落地 · ${due.length} 笔到期',
      trailing: TextButton.icon(
        onPressed: () => _postAll(context, ref),
        icon: const Icon(Icons.done_all, size: 18),
        label: const Text('全部记入'),
      ),
      child: Column(
        children: [
          for (final d in due.take(8))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: SizedBox(
                width: 52,
                child: Text(dateKey(d.occurrence.date).substring(5),
                    style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()])),
              ),
              title: Row(
                children: [
                  Flexible(child: Text(d.event.name, overflow: TextOverflow.ellipsis)),
                  if (d.blockedReason != null) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: d.blockedReason!,
                      child: Icon(Icons.warning_amber_rounded,
                          size: 15, color: AppColors.warnOf(theme.brightness)),
                    ),
                  ] else if (d.occurrence.isEstimate) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: '估算金额，确认时可修改',
                      child: Text('估',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.hintColor)),
                    ),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fmtMinor(d.occurrence.amountMinor.abs(),
                        d.event.currencyCode),
                    style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                  IconButton(
                    tooltip: '记入账本',
                    icon: const Icon(Icons.post_add, size: 20),
                    onPressed: () async {
                      final changed =
                          await showPlanPostSheet(context, ref, d);
                      if (changed) ref.invalidate(_plansProvider);
                    },
                  ),
                ],
              ),
            ),
          if (due.length > 8)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('…另有 ${due.length - 8} 笔，"全部记入"可一次处理',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor)),
            ),
          const Divider(height: 20),
          Text(
            '净影响 ${fmtMinor(net.abs(), 'CNY')}${net.isNegative ? ' 支出' : ' 收入'}'
            '${blocked > 0 ? ' · $blocked 笔需先在确认页选账户' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                fontFeatures: [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }

  /// 一键全部记入：配置齐全的按计划金额直接入账；配置缺失的留在清单。
  Future<void> _postAll(BuildContext context, WidgetRef ref) async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    final messenger = ScaffoldMessenger.of(context);
    var posted = 0;
    for (final d in due) {
      if (d.blockedReason != null) continue;
      try {
        await s.planExecution.postOne(d);
        posted++;
      } on StateError {
        // 已入账（并发/重复点击）：跳过。
      } catch (_) {
        // 单笔失败不中断其余；失败的留在清单里。
      }
    }
    ref.invalidate(_plansProvider);
    messenger.showSnackBar(SnackBar(
        content: Text(posted > 0
            ? '已记入 $posted 笔计划'
            : '没有可直接记入的计划（需先在确认页选账户）')));
  }
}

class _UpcomingBlock extends StatelessWidget {
  const _UpcomingBlock({required this.occurrences});

  final List<Occurrence> occurrences;

  @override
  Widget build(BuildContext context) {
    if (occurrences.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 16, 0, 4),
          child: Text('未来 30 天'),
        ),
        for (final o in occurrences.take(12))
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(
              width: 52,
              child: Text(dateKey(o.date).substring(5),
                  style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()])),
            ),
            title: Text(o.eventName),
            trailing: Text(
              '${o.amountMinor.isNegative ? '-' : '+'}${fmtMinor(o.amountMinor.abs(), 'CNY')}',
              style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ),
      ],
    );
  }
}

class _PlanTile extends ConsumerWidget {
  const _PlanTile({required this.event, required this.onChanged});

  final ScheduledEvent event;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isActive = event.status == PlanStatus.active;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
          event.direction == EventDirection.outflow
              ? Icons.arrow_outward
              : Icons.arrow_downward,
          color: event.status == PlanStatus.active
              ? null
              : theme.disabledColor),
      title: Row(
        children: [
          Flexible(
              child: Text(event.name,
                  overflow: TextOverflow.ellipsis,
                  style: event.status == PlanStatus.active
                      ? null
                      : TextStyle(color: theme.disabledColor))),
          if (event.autoPost) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: '到期自动记入账本',
              child: Icon(Icons.bolt,
                  size: 15, color: AppColors.brassOf(theme.brightness)),
            ),
          ],
        ],
      ),
      subtitle: Text(
        '${event.cadence.labelZh} · ${fmtMinor(event.resolvedAmountMinor(), event.currencyCode)}'
        '${event.isEstimate ? '（估）' : ''} · ${planStatusLabel(event.status)}',
      ),
      onTap: () async {
        final ok = await showDialog<bool>(
            context: context,
            builder: (_) => PlanEditDialog(initial: event));
        if (ok == true) onChanged();
      },
      trailing: PopupMenuButton<String>(
        onSelected: (action) => _onAction(context, ref, action),
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('编辑')),
          PopupMenuItem(
              value: 'togglePause',
              child: Text(isActive ? '暂停' : '恢复')),
          const PopupMenuItem(value: 'finish', child: Text('标记完成')),
          const PopupMenuItem(value: 'delete', child: Text('删除')),
        ],
      ),
    );
  }

  Future<void> _onAction(
      BuildContext context, WidgetRef ref, String action) async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    switch (action) {
      case 'edit':
        final ok = await showDialog<bool>(
            context: context,
            builder: (_) => PlanEditDialog(initial: event));
        if (ok == true) onChanged();
      case 'togglePause':
        await s.planning.saveScheduledEvent(event.copyWith(
            status: event.status == PlanStatus.active
                ? PlanStatus.paused
                : PlanStatus.active));
        onChanged();
      case 'finish':
        await s.planning.saveScheduledEvent(
            event.copyWith(status: PlanStatus.finished));
        onChanged();
      case 'delete':
        final ok = await confirmDialog(context,
            title: '删除计划',
            message: '删除"${event.name}"不影响已入账的交易。',
            confirmLabel: '删除',
            destructive: true);
        if (ok) {
          await s.planning.deleteScheduledEvent(event.id);
          onChanged();
        }
    }
  }
}

class PlansView {
  const PlansView(this.events, this.due, this.upcoming);
  final List<ScheduledEvent> events;
  final List<DueOccurrence> due;
  final List<Occurrence> upcoming;
}

final _plansProvider = FutureProvider.autoDispose<PlansView>((ref) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) {
    return const PlansView([], [], []);
  }
  final events = await s.planning.scheduledEvents();
  final due = await s.planExecution.pendingDue();
  final postedExtIds = await s.ledger.externalIds();
  final now = DateTime.now();
  final through = now.add(const Duration(days: 30));
  final occ = <Occurrence>[];
  for (final e in events) {
    occ.addAll(e.expand(DateTime(now.year, now.month, now.day), through)
        .where((o) => !postedExtIds.contains(planExternalId(e.id, o.date))));
  }
  occ.sort((a, b) => a.date.compareTo(b.date));
  return PlansView(events, due, occ);
});
