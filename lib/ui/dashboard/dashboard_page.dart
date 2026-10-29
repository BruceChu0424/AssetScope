import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import 'dashboard_cards.dart';
import 'dashboard_providers.dart';
import 'dashboard_secondary_cards.dart';
import '../widgets/common.dart';

/// 首页总览：净资产 hero、财务体检、智慧洞察、预测与提醒。
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('资观 · 本月总览')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorPlaceholder('加载失败：$e'),
        data: (d) => RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const _AutoPostNotice(),
              NetWorthHeroCard(d: d),
              if (d.locatedAssets > 0) ...[
                const SizedBox(height: 10),
                GlobeEntryCard(count: d.locatedAssets),
              ],
              const SizedBox(height: 10),
              MonthFlowCard(d: d),
              const SizedBox(height: 10),
              SpendableCard(d: d),
              const SizedBox(height: 10),
              HealthCard(d: d),
              const SizedBox(height: 10),
              InsightsCard(insights: d.insights.insights),
              const SizedBox(height: 10),
              TrendCard(d: d),
              const SizedBox(height: 10),
              UpcomingCard(d: d),
              const SizedBox(height: 10),
              IssuesCard(d: d),
            ],
          ),
        ),
      ),
    );
  }
}

/// 解锁时自动落地了计划交易的透明提示（只提示一次）。
class _AutoPostNotice extends ConsumerStatefulWidget {
  const _AutoPostNotice();

  @override
  ConsumerState<_AutoPostNotice> createState() => _AutoPostNoticeState();
}

class _AutoPostNoticeState extends ConsumerState<_AutoPostNotice> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = sessionOf(ref.read(vaultProvider));
      if (s == null || s.autoPostedCount <= 0) return;
      final n = s.autoPostedCount;
      s.autoPostedCount = 0;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('已按计划自动记入 $n 笔交易，可在流水中查看（来源：计划）')));
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
