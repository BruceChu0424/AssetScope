import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/planning/recurrence.dart';
import '../../domain/utils/dates.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common.dart';
import 'overview_anim.dart';

import 'overview_providers2.dart';
import 'overview_scaffold.dart';

/// 未来支出部件：日历（月历/时间线双模式）/ 到期清单 / 周期支出 / 周流出。

const _steel = Color(0xFF7EA6D9);
const _amber = Color(0xFFD8BE85);
const _rose = Color(0xFFF0907C);
const _mint = Color(0xFF8FBCE8);

Color _statusColor(OvUpcomingStatus s) => switch (s) {
  OvUpcomingStatus.pending => _steel,
  OvUpcomingStatus.posted => _mint,
  OvUpcomingStatus.overdue => _rose,
};

/// 支出日历面板：月历模式（事件点+金额+状态色，今日钢圈，3 日内琥珀，
/// 逾期红，已付绿）与时间线模式（按日纵列）切换；点选日期在底部展开
/// 当日明细。
class UpCalendarPanel extends StatefulWidget {
  const UpCalendarPanel({super.key, required this.u});

  final OvUpcomingData u;

  @override
  State<UpCalendarPanel> createState() => _UpCalendarPanelState();
}

class _UpCalendarPanelState extends State<UpCalendarPanel> {
  bool _timelineMode = false;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final byDay = <String, List<OvUpcomingItem>>{};
    for (final i in widget.u.items) {
      byDay.putIfAbsent(dateKey(i.occ.date), () => []).add(i);
    }
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          OvSectionHead(
            title: t.ovUpCalTitle,
            hint: t.ovUpCalHint,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _modeChip(t.ovUpModeCal, !_timelineMode, () {
                  if (_timelineMode) setState(() => _timelineMode = false);
                }),
                const SizedBox(width: 4),
                _modeChip(t.ovUpModeTimeline, _timelineMode, () {
                  if (!_timelineMode) setState(() => _timelineMode = true);
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _timelineMode
                ? _timeline(t, byDay)
                : _monthGrid(t, byDay),
          ),
          if (_selected != null) ...[
            const Divider(height: 16),
            _dayDetail(t, _selected!),
          ],
        ],
      ),
    );
  }

  Widget _modeChip(String label, bool active, VoidCallback onTap) {
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

  /// 月历模式。
  Widget _monthGrid(AppLocalizations t, Map<String, List<OvUpcomingItem>> byDay) {
    final theme = Theme.of(context);
    final first = DateTime(_month.year, _month.month);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = first.weekday - 1;
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 17,
              onPressed: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1),
              ),
              icon: const Icon(Icons.chevron_left, color: Color(0xFFBFD9F2)),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${_month.year} · ${_month.month.toString().padLeft(2, '0')}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 17,
              onPressed: () => setState(
                () => _month = DateTime(_month.year, _month.month + 1),
              ),
              icon: const Icon(Icons.chevron_right, color: Color(0xFFBFD9F2)),
            ),
          ],
        ),
        Row(
          children: [
            for (final w in weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF71859D)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.92,
            ),
            itemCount: offset + days,
            itemBuilder: (context, idx) {
              if (idx < offset) return const SizedBox.shrink();
              final day = idx - offset + 1;
              final date = DateTime(_month.year, _month.month, day);
              final items = byDay[dateKey(date)] ?? const <OvUpcomingItem>[];
              final isToday = date == t0;
              final isPast = date.isBefore(t0);
              final near = !date.isAfter(t0.add(const Duration(days: 3))) &&
                  !isPast;
              final hasOverdue = items.any(
                (i) => i.status == OvUpcomingStatus.overdue,
              );
              final selected = _selected == date;
              return OvRiseIn(
                delay: Duration(milliseconds: idx * 12),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(
                    () => _selected = selected ? null : date,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: selected
                          ? _steel.withValues(alpha: 0.14)
                          : (near && items.isNotEmpty
                                ? _amber.withValues(alpha: 0.07)
                                : Colors.white.withValues(alpha: 0.02)),
                      border: Border.all(
                        color: hasOverdue
                            ? _rose.withValues(alpha: 0.7)
                            : isToday
                            ? _steel
                            : selected
                            ? _steel.withValues(alpha: 0.5)
                            : const Color(0x1EE7ECF2),
                        width: isToday || hasOverdue ? 1.3 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 10,
                            color: isToday
                                ? const Color(0xFFBFD9F2)
                                : const Color(0xFFA5B5C7),
                            fontWeight: isToday ? FontWeight.w700 : null,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        for (final i in items.take(2))
                          Padding(
                            padding: const EdgeInsets.only(top: 1.5),
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: _statusColor(i.status).withValues(
                                  alpha: i.status == OvUpcomingStatus.posted
                                      ? 0.45
                                      : 0.9,
                                ),
                              ),
                            ),
                          ),
                        if (items.length > 2)
                          Text(
                            '+${items.length - 2}',
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: Color(0xFF71859D),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 时间线模式：未来 30 天（含逾期）按日纵列。
  Widget _timeline(AppLocalizations t, Map<String, List<OvUpcomingItem>> byDay) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);
    final days = [
      for (var d = -7; d <= 30; d++) t0.add(Duration(days: d)),
    ];
    return SingleChildScrollView(
      child: Column(
        children: [
          for (var i = 0; i < days.length; i++)
            if ((byDay[dateKey(days[i])] ?? const []).isNotEmpty)
              OvRiseIn(
                delay: Duration(milliseconds: i * 30),
                child: _timelineDay(t, theme, days[i], byDay[dateKey(days[i])]!),
              ),
        ],
      ),
    );
  }

  Widget _timelineDay(
    AppLocalizations t,
    ThemeData theme,
    DateTime day,
    List<OvUpcomingItem> items,
  ) {
    final t0 = DateTime.now();
    final overdue = day.isBefore(DateTime(t0.year, t0.month, t0.day));
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dateKey(day).substring(5),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: const Color(0xFFA5B5C7),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: overdue
                        ? _rose
                        : _statusColor(items.first.status),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 4, bottom: 8),
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(10),
                ),
                border: Border(
                  left: BorderSide(
                    color: overdue ? _rose : _steel,
                    width: 2,
                  ),
                ),
                color: Colors.white.withValues(alpha: 0.03),
              ),
              child: Column(
                children: [
                  for (final i in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              i.occ.eventName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            fmtMinor(i.occ.amountMinor.abs(), widget.u.base),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: _statusColor(i.status),
                              decoration: i.status == OvUpcomingStatus.posted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ],
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

  /// 当日明细（月历点选后展开）。
  Widget _dayDetail(AppLocalizations t, DateTime day) {
    final theme = Theme.of(context);
    final items = widget.u.items
        .where((i) => dateKey(i.occ.date) == dateKey(day))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              dateKey(day),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              t.ovUpItemCount(items.length),
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF71859D),
              ),
            ),
          ],
        ),
        for (final i in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor(i.status),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(i.occ.eventName, style: theme.textTheme.bodyMedium),
                ),
                if (i.paymentAccountName != null) ...[
                  Text(
                    i.paymentAccountName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF71859D),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  fmtMinor(i.occ.amountMinor.abs(), widget.u.base),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 即将到期：紧迫排序 + 状态 + 处理入口（去计划页落地，不伪造扣款）。
class UpDuePanel extends StatelessWidget {
  const UpDuePanel({super.key, required this.u});

  final OvUpcomingData u;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pending = u.items
        .where((i) => i.status != OvUpcomingStatus.posted)
        .toList();
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(title: t.ovUpDueTitle, hint: t.ovUpDueHint),
          const SizedBox(height: 4),
          if (pending.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OvBreathing(
                      color: _mint,
                      radius: 22,
                      child: const Icon(
                        Icons.task_alt,
                        size: 36,
                        color: _mint,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t.ovUpAllSettled,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: const Color(0xFFE7F0FA),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < pending.length; i++)
                      OvRiseIn(
                        delay: Duration(milliseconds: i * 40),
                        child: _dueRow(context, pending[i]),
                      ),
                  ],
                ),
              ),
            ),
          if (pending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => GoRouter.of(context).go('/plans'),
                  icon: const Icon(Icons.event_available_outlined, size: 16),
                  label: Text(t.ovUpGoPost),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dueRow(BuildContext context, OvUpcomingItem i) {
    final theme = Theme.of(context);
    final c = _statusColor(i.status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: c.withValues(alpha: 0.12),
              border: Border.all(color: c.withValues(alpha: 0.4)),
            ),
            child: Text(
              dateKey(i.occ.date).substring(5),
              style: TextStyle(
                fontSize: 11,
                color: c,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i.occ.eventName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                if (i.paymentAccountName != null)
                  Text(
                    i.paymentAccountName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF71859D),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            fmtMinor(i.occ.amountMinor.abs(), u.base),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// 周期固定支出：周期 + 下次执行日。
class UpRecurringPanel extends StatelessWidget {
  const UpRecurringPanel({super.key, required this.u});

  final OvUpcomingData u;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(title: t.ovUpFixedTitle, hint: t.ovUpFixedHint),
          const SizedBox(height: 4),
          if (u.recurring.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  t.ovUpNoFixed,
                  style: const TextStyle(color: Color(0xFF71859D)),
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < u.recurring.length; i++)
                      OvRiseIn(
                        delay: Duration(milliseconds: i * 40),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                u.recurring[i].$1.direction ==
                                        EventDirection.outflow
                                    ? Icons.south_east
                                    : Icons.north_east,
                                size: 15,
                                color: u.recurring[i].$1.direction ==
                                        EventDirection.outflow
                                    ? _rose.withValues(alpha: 0.8)
                                    : _mint,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  u.recurring[i].$1.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                t.ovUpNextAt(dateKey(u.recurring[i].$2)),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFFA5B5C7),
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
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

/// 周流出柱状：未来 4 周每周计划流出。
class UpWeekBarsPanel extends StatelessWidget {
  const UpWeekBarsPanel({super.key, required this.u});

  final OvUpcomingData u;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final now = DateTime.now();
    final t0 = DateTime(now.year, now.month, now.day);
    final weeks = List<BigInt>.filled(5, BigInt.zero);
    for (final i in u.outflows) {
      final w = i.occ.date.difference(t0).inDays ~/ 7;
      if (w < 0 || w >= 5) continue;
      weeks[w] += i.occ.amountMinor.abs();
    }
    var peak = 1.0;
    for (final w in weeks) {
      peak = math.max(peak, w.toDouble());
    }
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(
        children: [
          OvSectionHead(title: t.ovUpWeekTitle, hint: t.ovUpWeekHint),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: peak * 1.15,
                barGroups: [
                  for (var w = 0; w < 5; w++)
                    BarChartGroupData(
                      x: w,
                      barRods: [
                        BarChartRodData(
                          toY: weeks[w].toDouble(),
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                          color: (w == 0 ? _amber : _steel).withValues(
                            alpha: 0.85,
                          ),
                        ),
                      ],
                    ),
                ],
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
                      fmtMinor(weeks[g.x], u.base),
                      const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFF0F5FB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          t.ovUpWeekLabel(v.toInt()),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF71859D),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
              duration: const Duration(milliseconds: 500),
            ),
          ),
        ],
      ),
    );
  }
}
