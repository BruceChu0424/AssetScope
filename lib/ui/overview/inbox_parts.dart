import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/utils/dates.dart';
import '../../l10n/app_localizations.dart';
import 'overview_anim.dart';
import 'overview_providers2.dart';
import 'overview_scaffold.dart';

/// 待处理部件：统计卡 / 任务表 / 快捷操作 / 时间线 / 空状态。

const _rose = Color(0xFFF0907C);
const _amber = Color(0xFFD8BE85);
const _steel = Color(0xFF7EA6D9);
const _mint = Color(0xFF8FBCE8);

/// 统计卡：图标 + 数量，色彩只落在图标与数字上。
class IxStatTile extends StatelessWidget {
  const IxStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.30),
                  color.withValues(alpha: 0.10),
                ],
              ),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFA5B5C7),
                  ),
                ),
                Text(
                  '$count',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: count > 0 ? color : const Color(0xFF71859D),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 任务表：筛选（全部/紧急/今天/本周）+ 行（名称/类型/优先级/截止/
/// 处理按钮 → 真实业务页）。
class IxTaskTable extends StatefulWidget {
  const IxTaskTable({super.key, required this.d});

  final OvInboxData d;

  @override
  State<IxTaskTable> createState() => _IxTaskTableState();
}

enum _IxFilter { all, urgent, today, week }

class _IxTaskTableState extends State<IxTaskTable> {
  _IxFilter _filter = _IxFilter.all;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);
    Iterable<OvTask> tasks = widget.d.tasks;
    switch (_filter) {
      case _IxFilter.urgent:
        tasks = tasks.where(
          (x) => x.priority == OvTaskPriority.high,
        );
      case _IxFilter.today:
        tasks = tasks.where(
          (x) =>
              x.dueDate != null &&
              !x.dueDate!.isAfter(t0.add(const Duration(days: 1))),
        );
      case _IxFilter.week:
        tasks = tasks.where(
          (x) =>
              x.dueDate != null &&
              !x.dueDate!.isAfter(t0.add(const Duration(days: 7))),
        );
      case _IxFilter.all:
        break;
    }
    final list = tasks.toList();
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        children: [
          OvSectionHead(
            title: t.ovIxTableTitle,
            hint: t.ovIxTableHint,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final f in _IxFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: _filterChip(
                      context,
                      switch (f) {
                        _IxFilter.all => t.ovIxFilterAll,
                        _IxFilter.urgent => t.ovIxFilterUrgent,
                        _IxFilter.today => t.ovIxFilterToday,
                        _IxFilter.week => t.ovIxFilterWeek,
                      },
                      _filter == f,
                      () => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 表头。
          Row(
            children: [
              Expanded(flex: 3, child: _h(context, t.ovIxColTask)),
              Expanded(flex: 2, child: _h(context, t.ovIxColType)),
              Expanded(flex: 1, child: _h(context, t.ovIxColPriority)),
              Expanded(flex: 1, child: _h(context, t.ovIxColDue)),
              SizedBox(width: 84),
            ],
          ),
          const Divider(height: 14),
          if (list.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  t.ovIxNoMatch,
                  style: const TextStyle(color: Color(0xFF71859D)),
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < list.length; i++)
                      OvRiseIn(
                        delay: Duration(milliseconds: i * 35),
                        child: _row(context, list[i]),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _h(BuildContext context, String s) {
    return Text(
      s,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: const Color(0xFF71859D),
        fontSize: 11,
      ),
    );
  }

  Widget _filterChip(
    BuildContext context,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: active ? _steel.withValues(alpha: 0.20) : Colors.transparent,
            border: Border.all(
              color: active ? _steel.withValues(alpha: 0.6) : const Color(0x2EE7ECF2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: active ? const Color(0xFFBFD9F2) : const Color(0xFF71859D),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, OvTask task) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (typeLabel, typeColor) = switch (task.type) {
      OvTaskType.duePlan => (t.ovIxTypeDue, _amber),
      OvTaskType.missingValuation => (t.ovIxTypeMissing, _amber),
      OvTaskType.staleValuation => (t.ovIxTypeStale, _steel),
      OvTaskType.residual => (t.ovIxTypeResidual, _rose),
      OvTaskType.shortfall => (t.ovIxTypeShortfall, _rose),
    };
    final (pLabel, pColor) = switch (task.priority) {
      OvTaskPriority.high => (t.ovIxPriorityHigh, _rose),
      OvTaskPriority.medium => (t.ovIxPriorityMedium, _amber),
      OvTaskPriority.low => (t.ovIxPriorityLow, const Color(0xFF71859D)),
    };
    final title = switch (task.type) {
      OvTaskType.residual => t.ovIxResidualTask(title0(task)),
      _ => task.title,
    };
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: Colors.white.withValues(alpha: 0.02),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: typeColor.withValues(alpha: 0.12),
                      border: Border.all(
                        color: typeColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(fontSize: 10.5, color: typeColor),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                pLabel,
                style: TextStyle(fontSize: 11, color: pColor),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                task.dueDate == null ? '—' : dateKey(task.dueDate!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFA5B5C7),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            SizedBox(
              width: 84,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Tooltip(
                  message: t.ovIxAction,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => GoRouter.of(context).go(task.route),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: _steel.withValues(alpha: 0.16),
                          border: Border.all(
                            color: _steel.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_outward,
                              size: 12,
                              color: Color(0xFFBFD9F2),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              t.ovIxGo,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFBFD9F2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String title0(OvTask task) => task.title;
}

/// 快捷操作：两列小卡（去补估值 / 处理到期计划 / 记一笔 / 看缺口预测）。
class IxQuickActions extends StatelessWidget {
  const IxQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final actions = <(IconData, String, String, String)>[
      (
        Icons.gavel_outlined,
        t.ovIxAValuation,
        t.ovIxAValuationSub,
        '/assets',
      ),
      (
        Icons.event_available_outlined,
        t.ovIxAPost,
        t.ovIxAPostSub,
        '/plans',
      ),
      (
        Icons.receipt_long_outlined,
        t.ovIxALedger,
        t.ovIxALedgerSub,
        '/transactions',
      ),
      (
        Icons.query_stats_outlined,
        t.ovIxASpendable,
        t.ovIxASpendableSub,
        '/spendable',
      ),
    ];
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(title: t.ovIxQuickTitle, hint: t.ovIxQuickHint),
          const SizedBox(height: 8),
          for (var i = 0; i < actions.length; i += 2)
            Row(
              children: [
                for (var j = i; j < i + 2; j++) ...[
                  if (j > i) const SizedBox(width: 10),
                  Expanded(child: _card(context, theme, actions[j])),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    ThemeData theme,
    (IconData, String, String, String) a,
  ) {
    return OvRiseIn(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () => GoRouter.of(context).go(a.$4),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(color: const Color(0x2EE7ECF2)),
            ),
            child: Row(
              children: [
                Icon(a.$1, size: 17, color: _steel),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        a.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE7F0FA),
                        ),
                      ),
                      Text(
                        a.$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10.5,
                          color: const Color(0xFF71859D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 提醒时间线：纵向节点 + 优先级配色，按日期排序。
class IxTimeline extends StatelessWidget {
  const IxTimeline({super.key, required this.d});

  final OvInboxData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final items = d.tasks.take(10).toList();
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(title: t.ovIxTimelineTitle, hint: t.ovIxTimelineHint),
          const SizedBox(height: 6),
          for (var i = 0; i < items.length; i++)
            OvRiseIn(
              delay: Duration(milliseconds: i * 40),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 30,
                      child: Column(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: switch (items[i].priority) {
                                OvTaskPriority.high => _rose,
                                OvTaskPriority.medium => _amber,
                                OvTaskPriority.low => _steel,
                              },
                              boxShadow: [
                                BoxShadow(
                                  color: switch (items[i].priority) {
                                    OvTaskPriority.high => _rose,
                                    OvTaskPriority.medium => _amber,
                                    OvTaskPriority.low => _steel,
                                  }.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          if (i < items.length - 1)
                            Expanded(
                              child: Container(
                                width: 1,
                                color: const Color(0x26E7ECF2),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[i].dueDate == null
                                  ? t.ovIxNoDue
                                  : dateKey(items[i].dueDate!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF71859D),
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            Text(
                              items[i].title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 空状态：柔光呼吸 + 简洁文案。
class InboxEmptyState extends StatelessWidget {
  const InboxEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return OvRiseIn(
      duration: const Duration(milliseconds: 600),
      child: OvBreathing(
        color: _mint,
        radius: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF22344A), Color(0xFF0C1929)],
                ),
                border: Border.all(color: _mint.withValues(alpha: 0.6)),
              ),
              child: const Icon(
                Icons.verified_outlined,
                size: 40,
                color: _mint,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              t.ovIxEmptyTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF0F5FB),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.ovIxEmptyMsg,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFA5B5C7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
