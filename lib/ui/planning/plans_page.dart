import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/planning/recurrence.dart';
import '../../domain/utils/dates.dart';
import '../../l10n/app_localizations.dart';
import '../../services/plan_execution_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'life_planner_sheet.dart';
import 'plan_edit_dialog.dart';
import 'plan_fields.dart';
import 'plan_post_sheet.dart';
import 'recurring_sheet.dart';
import 'scenario_sheet.dart';

/// 计划页 · 落地台：页首汇总（到期笔数/未来 30 天净流）→ 待落地整带
/// （宽幅 SectionCard）→ 大屏双栏（时间线 | 全部计划），小屏纵排。
/// 头部动作：人生规划 / 情景模拟 / 识别固定收支。
class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_plansProvider);
    final brightness = Theme.of(context).brightness;
    final wide = MediaQuery.sizeOf(context).width >= PageMeasure.wide;
    final t = AppLocalizations.of(context);
    return PageFrame(
      title: t.plansPageTitle,
      maxWidth: wide ? AppMeasure.workbench : PageMeasure.contentMax,
      actions: [
        ActionIcon(
          tooltip: t.lifePlanTitle,
          icon: Icons.explore_outlined,
          onTap: () => showLifePlannerSheet(context, ref),
        ),
        ActionIcon(
          tooltip: t.scenarioTitle,
          icon: Icons.shield_outlined,
          onTap: () => showScenarioSheet(context, ref),
        ),
        ActionIcon(
          tooltip: t.recurringOpenTooltip,
          icon: Icons.auto_awesome,
          onTap: () async {
            await showRecurringSheet(context, ref);
            ref.invalidate(_plansProvider);
          },
        ),
      ],
      fab: ParticleEdge(
        band: 12,
        extendBelow: 6,
        child: FloatingActionButton.extended(
          onPressed: () async {
            final ok = await showAppDialog<bool>(
              context,
              builder: (_) => const PlanEditDialog(),
            );
            if (ok == true) ref.invalidate(_plansProvider);
          },
          icon: const Icon(Icons.add),
          label: Text(t.planNew),
        ),
      ),
      child: async.when(
        loading: () => const Center(child: OrbitSpinner(size: 36)),
        error: (e, _) => ErrorPlaceholder(t.loadFailed(e.toString())),
        data: (view) {
          final upcomingNet = view.upcoming.fold<BigInt>(
            BigInt.zero,
            (s, o) => s + o.amountMinor,
          );
          if (wide) {
            // 大屏工作台：左 = 节奏汇总 + 待落地；主区 = 时间线 + 全部计划。
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 320,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SummaryPanel(
                            title: t.planMonthlyRhythm,
                            rows: [
                              SummaryRow(
                                t.planDueUnposted,
                                t.planCount(view.due.length),
                                color: view.due.isNotEmpty
                                    ? AppColors.warnOf(brightness)
                                    : null,
                                tooltip: t.planDueTooltip,
                              ),
                              SummaryRow(
                                t.planNext30Days,
                                t.planCount(view.upcoming.length),
                                tooltip: t.planNext30Tooltip,
                              ),
                              SummaryRow(
                                t.planNext30Net,
                                fmtMinor(upcomingNet.abs(), 'CNY', sign: true),
                                color: upcomingNet.isNegative
                                    ? AppColors.negativeOf(brightness)
                                    : AppColors.positiveOf(brightness),
                                tooltip: t.planNetSignTooltip,
                              ),
                            ],
                          ),
                          if (view.due.isNotEmpty) ...[
                            const SizedBox(height: PageMeasure.gutter),
                            _DueCard(due: view.due),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: PageMeasure.gutter),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _UpcomingCard(occurrences: view.upcoming),
                          const SizedBox(height: PageMeasure.gutter),
                          _AllPlansCard(events: view.events),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              StatBand(
                items: [
                  StatBandItem(
                    t.planDueUnposted,
                    t.planCount(view.due.length),
                    color: view.due.isNotEmpty
                        ? AppColors.warnOf(brightness)
                        : null,
                    tooltip: t.planDueTooltip,
                  ),
                  StatBandItem(
                    t.planNext30Days,
                    t.planCount(view.upcoming.length),
                    tooltip: t.planNext30Tooltip,
                  ),
                  StatBandItem(
                    t.planNext30Net,
                    fmtMinor(upcomingNet.abs(), 'CNY', sign: true),
                    color: upcomingNet.isNegative
                        ? AppColors.negativeOf(brightness)
                        : AppColors.positiveOf(brightness),
                    tooltip: t.planNetSignTooltip,
                  ),
                ],
              ),
              if (view.due.isNotEmpty) ...[
                const SizedBox(height: 16),
                _DueCard(due: view.due),
              ],
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, c) {
                  final twoCol = c.maxWidth >= 760;
                  if (!twoCol) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _UpcomingCard(occurrences: view.upcoming),
                        const SizedBox(height: 16),
                        _AllPlansCard(events: view.events),
                      ],
                    );
                  }
                  final colW = (c.maxWidth - 16) / 2;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: colW,
                        child: _UpcomingCard(occurrences: view.upcoming),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: colW,
                        child: _AllPlansCard(events: view.events),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
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
    final t = AppLocalizations.of(context);
    final net = due.fold<BigInt>(
      BigInt.zero,
      (s, d) => s + d.occurrence.amountMinor,
    );
    final blocked = due.where((d) => d.blockedReason != null).length;
    return SectionCard(
      title: t.planDueTitle(due.length),
      trailing: TextButton.icon(
        onPressed: () => _postAll(context, ref),
        icon: const Icon(Icons.done_all, size: 18),
        label: Text(t.planPostAll),
      ),
      child: Column(
        children: [
          for (final d in due.take(8))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: SizedBox(
                width: 52,
                child: Text(
                  dateKey(d.occurrence.date).substring(5),
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(d.event.name, overflow: TextOverflow.ellipsis),
                  ),
                  if (d.blockedReason != null) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: d.blockedReason!,
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 15,
                        color: AppColors.warnOf(theme.brightness),
                      ),
                    ),
                  ] else if (d.occurrence.isEstimate) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: t.planEstimateTooltip,
                      child: Text(
                        t.planEstimateBadge,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fmtMinor(d.occurrence.amountMinor.abs(), d.event.currencyCode),
                    style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  IconButton(
                    tooltip: t.planPostNow,
                    icon: const Icon(Icons.post_add, size: 20),
                    onPressed: () async {
                      final changed = await showPlanPostSheet(context, ref, d);
                      if (changed) ref.invalidate(_plansProvider);
                    },
                  ),
                ],
              ),
            ),
          if (due.length > 8)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                t.planMoreDue(due.length - 8),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ),
          const Divider(height: 20),
          Text(
            '${t.planNetEffect(fmtMinor(net.abs(), 'CNY'))}'
            '${net.isNegative ? ' ${t.planOutflow}' : ' ${t.planInflow}'}'
            '${blocked > 0 ? t.planBlockedCount(blocked) : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  /// 一键全部记入：配置齐全的按计划金额直接入账；配置缺失的留在清单。
  Future<void> _postAll(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
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
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          posted > 0 ? t.planPostedCount(posted) : t.planNothingToPost,
        ),
      ),
    );
  }
}

/// 未来 30 天时间线：日期 | 事件 | 带符号金额（收支着色）。
class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.occurrences});

  final List<Occurrence> occurrences;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final t = AppLocalizations.of(context);
    if (occurrences.isEmpty) {
      return SectionCard(
        title: t.planNext30Days,
        child: Text(
          t.planNoUpcoming,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).hintColor,
          ),
        ),
      );
    }
    return SectionCard(
      title: t.planNext30Days,
      child: Column(
        children: [
          for (final o in occurrences.take(14))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: SizedBox(
                width: 52,
                child: Text(
                  dateKey(o.date).substring(5),
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              title: Text(o.eventName, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(
                '${o.amountMinor.isNegative ? '−' : '+'}${fmtMinor(o.amountMinor.abs(), 'CNY')}',
                style: TextStyle(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: o.amountMinor.isNegative
                      ? AppColors.negativeOf(brightness)
                      : AppColors.positiveOf(brightness),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 全部计划：ListRow 行（图标位 + 名称 + 周期金额 + 溢出菜单）。
class _AllPlansCard extends ConsumerWidget {
  const _AllPlansCard({required this.events});

  final List<ScheduledEvent> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    if (events.isEmpty) {
      return SectionCard(
        title: t.planAllPlans,
        child: Text(
          t.planEmptyHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).hintColor,
          ),
        ),
      );
    }
    return SectionCard(
      title: t.planAllPlans,
      child: Column(
        children: [
          for (final e in events)
            _PlanRow(
              event: e,
              onChanged: () => ref.invalidate(_plansProvider),
            ),
        ],
      ),
    );
  }
}

class _PlanRow extends ConsumerWidget {
  const _PlanRow({required this.event, required this.onChanged});

  final ScheduledEvent event;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final active = event.status == PlanStatus.active;
    final outflow = event.direction == EventDirection.outflow;
    final brightness = theme.brightness;
    return ListRow(
      icon: outflow ? Icons.arrow_outward : Icons.arrow_downward,
      title: event.name,
      hint: '${event.cadence.labelZh} · ${planStatusLabel(event.status)}'
          '${event.isEstimate ? t.planEstimateAmount : ''}',
      onTap: () async {
        final ok = await showAppDialog<bool>(
          context,
          builder: (_) => PlanEditDialog(initial: event),
        );
        if (ok == true) onChanged();
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (event.autoPost) ...[
            Tooltip(
              message: t.planAutoPostTitle,
              child: Icon(
                Icons.bolt,
                size: 16,
                color: AppColors.brassOf(brightness),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            fmtMinor(event.resolvedAmountMinor(), event.currencyCode),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: active ? null : theme.disabledColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          ParticleMenuButton<String>(
            tooltip: t.planActions,
            onSelected: (action) => _onAction(context, ref, action),
            items: [
              ParticleMenuEntry(value: 'edit', label: t.edit, icon: Icons.edit_outlined),
              ParticleMenuEntry(
                value: 'togglePause',
                label: active ? t.planPause : t.planResume,
                icon: active ? Icons.pause_outlined : Icons.play_arrow_outlined,
              ),
              ParticleMenuEntry(
                value: 'finish',
                label: t.planMarkFinished,
                icon: Icons.task_alt_outlined,
              ),
              ParticleMenuEntry(
                value: 'delete',
                label: t.delete,
                icon: Icons.delete_outline,
                destructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final t = AppLocalizations.of(context);
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    switch (action) {
      case 'edit':
        final ok = await showAppDialog<bool>(
          context,
          builder: (_) => PlanEditDialog(initial: event),
        );
        if (ok == true) onChanged();
      case 'togglePause':
        await s.planning.saveScheduledEvent(
          event.copyWith(
            status: event.status == PlanStatus.active
                ? PlanStatus.paused
                : PlanStatus.active,
          ),
        );
        onChanged();
      case 'finish':
        await s.planning.saveScheduledEvent(
          event.copyWith(status: PlanStatus.finished),
        );
        onChanged();
      case 'delete':
        final ok = await confirmDialog(
          context,
          title: t.planDeleteTitle,
          message: t.planDeleteMessage(event.name),
          confirmLabel: t.delete,
          destructive: true,
        );
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
    occ.addAll(
      e
          .expand(DateTime(now.year, now.month, now.day), through)
          .where((o) => !postedExtIds.contains(planExternalId(e.id, o.date))),
    );
  }
  occ.sort((a, b) => a.date.compareTo(b.date));
  return PlansView(events, due, occ);
});
