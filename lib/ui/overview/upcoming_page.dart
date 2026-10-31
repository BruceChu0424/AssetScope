import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/common.dart';
import 'overview_anim.dart';
import 'overview_providers2.dart';
import 'overview_scaffold.dart';
import 'upcoming_parts.dart';

/// 未来 30 天要花的钱：KPI + 支出日历（日历/时间线双模式）+ 即将到期 +
/// 周期固定支出 + 周流出分布。状态口径：pending / posted / overdue，全部
/// 来自真实计划发生与账本幂等键，不做「假装已付」。
class UpcomingPage extends ConsumerWidget {
  const UpcomingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(upcomingDetailProvider);
    return OverviewScaffold(
      title: t.ovUpTitle,
      titleHint: t.ovUpHint,
      child: async.when(
        loading: () => const Center(child: OrbitSpinner(size: 44)),
        error: (e, _) => Center(child: ErrorPlaceholder(t.homeLoadFailed(e))),
        data: (u) => _Body(u: u),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.u});

  final OvUpcomingData u;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final overdue = u.items
        .where((i) => i.status == OvUpcomingStatus.overdue)
        .toList();
    final overdueAmt = overdue.fold(
      BigInt.zero,
      (a, x) => a + x.occ.amountMinor.abs(),
    );
    final kpis = OvKpiRow(
      children: [
        OvKpiTile(
          icon: Icons.event_note_outlined,
          label: t.ovUpPlanned30,
          value: fmtMinor(u.totalPlanned, u.base),
          hint: t.ovUpPlannedHint,
        ),
        OvKpiTile(
          icon: Icons.schedule_outlined,
          label: t.ovUpDue7,
          value: fmtMinor(u.due7d, u.base),
          hint: t.ovUpDue7Hint,
          accent: const Color(0xFFD8BE85),
        ),
        OvKpiTile(
          icon: Icons.warning_amber_outlined,
          label: t.ovUpOverdue,
          value: overdue.isEmpty ? t.ovUpNone : fmtMinor(overdueAmt, u.base),
          hint: t.ovUpOverdueHint,
          valueColor: overdue.isEmpty ? null : const Color(0xFFF0907C),
          accent: const Color(0xFFF0907C),
        ),
        OvKpiTile(
          icon: Icons.repeat_outlined,
          label: t.ovUpRecurring,
          value: '${u.recurring.length}',
          hint: t.ovUpRecurringHint,
          accent: const Color(0xFF8FBCE8),
        ),
      ],
    );
    if (width < 1120) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: SingleChildScrollView(
          child: OvStaggerColumn(
            gap: 12,
            children: [
              kpis,
              SizedBox(height: 430, child: UpCalendarPanel(u: u)),
              SizedBox(height: 360, child: UpDuePanel(u: u)),
              SizedBox(height: 300, child: UpRecurringPanel(u: u)),
              SizedBox(height: 280, child: UpWeekBarsPanel(u: u)),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: SingleChildScrollView(
        child: OvStaggerColumn(
          gap: 14,
          children: [
            SizedBox(height: 120, child: kpis),
            SizedBox(
              height: 430,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: UpCalendarPanel(u: u)),
                  const SizedBox(width: 14),
                  Expanded(flex: 3, child: UpDuePanel(u: u)),
                ],
              ),
            ),
            SizedBox(
              height: 300,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 2, child: UpRecurringPanel(u: u)),
                  const SizedBox(width: 14),
                  Expanded(child: UpWeekBarsPanel(u: u)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
