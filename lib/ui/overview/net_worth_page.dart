import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/utils/dates.dart';
import '../../l10n/app_localizations.dart';
import '../dashboard/dashboard_providers.dart';
import '../widgets/common.dart';
import 'net_worth_parts.dart';
import 'overview_anim.dart';
import 'overview_scaffold.dart';

/// 净资产详情页：左侧净资产总览 + 中央全球资产分布地球 + 右侧资产
/// 类型环形图；下排账户分布/主要账户；底部 36 个月走势与本月归因。
/// 全部口径与首页仪表盘同一份数据（dashboardProvider）。
class NetWorthPage extends ConsumerWidget {
  const NetWorthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(dashboardProvider);
    return OverviewScaffold(
      title: t.ovNwTitle,
      titleHint: t.ovNwHint,
      updatedLabel: async.maybeWhen(
        data: (d) => t.dashAsOf(dateKey(d.nw.asOf)),
        orElse: () => null,
      ),
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

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 1120) return _narrow(context);
    return _wide(context);
  }

  Widget _wide(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: SingleChildScrollView(
        child: OvStaggerColumn(
          gap: 14,
          children: [
            SizedBox(
              height: 460,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 348, child: NwHeroPanel(d: d)),
                  const SizedBox(width: 14),
                  Expanded(child: NwGlobePanel(d: d)),
                  const SizedBox(width: 14),
                  SizedBox(width: 348, child: NwTypeDonutPanel(d: d)),
                ],
              ),
            ),
            SizedBox(
              height: 300,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: NwGroupBarsPanel(d: d)),
                  const SizedBox(width: 14),
                  Expanded(child: NwTopAccountsPanel(d: d)),
                ],
              ),
            ),
            SizedBox(
              height: 320,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: NwTrendPanel(d: d)),
                  const SizedBox(width: 14),
                  SizedBox(width: 420, child: NwAttributionPanel(d: d)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _narrow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: SingleChildScrollView(
        child: OvStaggerColumn(
          gap: 12,
          children: [
            SizedBox(height: 430, child: NwHeroPanel(d: d)),
            SizedBox(height: 380, child: NwGlobePanel(d: d)),
            SizedBox(height: 330, child: NwTypeDonutPanel(d: d)),
            SizedBox(height: 300, child: NwGroupBarsPanel(d: d)),
            SizedBox(height: 320, child: NwTopAccountsPanel(d: d)),
            SizedBox(height: 320, child: NwTrendPanel(d: d)),
            NwAttributionPanel(d: d),
          ],
        ),
      ),
    );
  }
}
