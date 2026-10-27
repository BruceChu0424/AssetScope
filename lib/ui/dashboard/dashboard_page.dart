import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_cards.dart';
import 'dashboard_providers.dart';
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
