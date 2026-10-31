import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/common.dart';
import 'inbox_parts.dart';
import 'overview_anim.dart';
import 'overview_providers2.dart';
import 'overview_scaffold.dart';

/// 待处理页：四统计卡 + 任务表（筛选/优先级/处理入口）+ 快捷操作 +
/// 提醒时间线。任务全部来自真实业务（到期计划/估值缺口/对账差额/资金
/// 预警），清单为空即干净的完成态。
class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(inboxProvider);
    return OverviewScaffold(
      title: t.ovIxTitle,
      titleHint: t.ovIxHint,
      child: async.when(
        loading: () => const Center(child: OrbitSpinner(size: 44)),
        error: (e, _) => Center(child: ErrorPlaceholder(t.homeLoadFailed(e))),
        data: (d) => _Body(d: d),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.d});

  final OvInboxData d;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (d.tasks.isEmpty) {
      return Center(child: InboxEmptyState());
    }
    final stats = Row(
      children: [
        Expanded(
          child: IxStatTile(
            icon: Icons.priority_high,
            label: AppLocalizations.of(context).ovIxStatHigh,
            count: d.highCount,
            color: const Color(0xFFF0907C),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: IxStatTile(
            icon: Icons.help_outline,
            label: AppLocalizations.of(context).ovIxStatMissing,
            count: d.count(OvTaskType.missingValuation),
            color: const Color(0xFFD8BE85),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: IxStatTile(
            icon: Icons.update,
            label: AppLocalizations.of(context).ovIxStatStale,
            count: d.count(OvTaskType.staleValuation),
            color: const Color(0xFF7EA6D9),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: IxStatTile(
            icon: Icons.compare_arrows,
            label: AppLocalizations.of(context).ovIxStatReconcile,
            count: d.count(OvTaskType.residual) +
                d.count(OvTaskType.shortfall),
            color: const Color(0xFF8FBCE8),
          ),
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
              SizedBox(height: 110, child: stats),
              SizedBox(height: 430, child: IxTaskTable(d: d)),
              IxQuickActions(),
              IxTimeline(d: d),
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
            SizedBox(height: 110, child: stats),
            SizedBox(
              height: 430,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: IxTaskTable(d: d)),
                  const SizedBox(width: 14),
                  Expanded(flex: 2, child: IxSideColumn(d: d)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IxSideColumn extends StatelessWidget {
  const IxSideColumn({super.key, required this.d});

  final OvInboxData d;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: OvStaggerColumn(
        gap: 14,
        children: [IxQuickActions(), IxTimeline(d: d)],
      ),
    );
  }
}
