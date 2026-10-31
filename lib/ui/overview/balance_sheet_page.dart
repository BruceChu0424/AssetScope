import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/ledger/account.dart';
import '../../l10n/app_localizations.dart';
import '../dashboard/dashboard_providers.dart';
import '../widgets/common.dart';
import 'balance_sheet_parts.dart';
import 'overview_anim.dart';
import 'overview_providers.dart';
import 'overview_scaffold.dart';

/// 资产负债表详情页：资产/负债/天平三联 → 树图+分类表 → 流动性/负债
/// 构成/双线趋势。全部由真实账户估值汇总，零值与缺口如实展示。
class BalanceSheetPage extends ConsumerWidget {
  const BalanceSheetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(dashboardProvider);
    final series = ref.watch(balanceSeriesProvider(12));
    return OverviewScaffold(
      title: t.ovBsTitle,
      titleHint: t.ovBsHint,
      child: async.when(
        loading: () => const Center(child: OrbitSpinner(size: 44)),
        error: (e, _) => Center(child: ErrorPlaceholder(t.homeLoadFailed(e))),
        data: (d) => series.when(
          loading: () => const Center(child: OrbitSpinner(size: 44)),
          error: (e, _) => Center(child: ErrorPlaceholder(t.homeLoadFailed(e))),
          data: (bSeries) => _Body(d: d, series: bSeries),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.d, required this.series});

  final DashboardData d;
  final List<OvBalancePoint> series;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final top = SizedBox(
      height: 300,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: BsTotalPanel(d: d, series: series, asset: true)),
          const SizedBox(width: 14),
          Expanded(child: BsScalePanel(d: d)),
          const SizedBox(width: 14),
          Expanded(child: BsTotalPanel(d: d, series: series, asset: false)),
        ],
      ),
    );
    final mid = SizedBox(
      height: 360,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: BsTreemapPanel(d: d)),
          const SizedBox(width: 14),
          Expanded(flex: 4, child: BsAssetTablePanel(d: d)),
          const SizedBox(width: 14),
          Expanded(flex: 3, child: BsLiabilityTablePanel(d: d)),
        ],
      ),
    );
    final bottom = SizedBox(
      height: 300,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: BsLiquidityPanel(d: d)),
          const SizedBox(width: 14),
          Expanded(child: BsLiabMixPanel(d: d)),
          const SizedBox(width: 14),
          Expanded(flex: 2, child: BsDualTrendPanel(series: series)),
        ],
      ),
    );
    if (width < 1120) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: SingleChildScrollView(
          child: OvStaggerColumn(
            gap: 12,
            children: [
              SizedBox(height: 240, child: BsTotalPanel(d: d, series: series, asset: true)),
              SizedBox(height: 260, child: BsScalePanel(d: d)),
              SizedBox(height: 240, child: BsTotalPanel(d: d, series: series, asset: false)),
              SizedBox(height: 340, child: BsTreemapPanel(d: d)),
              SizedBox(height: 380, child: BsAssetTablePanel(d: d)),
              SizedBox(height: 300, child: BsLiabilityTablePanel(d: d)),
              SizedBox(height: 280, child: BsLiquidityPanel(d: d)),
              SizedBox(height: 280, child: BsLiabMixPanel(d: d)),
              SizedBox(height: 280, child: BsDualTrendPanel(series: series)),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: SingleChildScrollView(
        child: OvStaggerColumn(gap: 14, children: [top, mid, bottom]),
      ),
    );
  }
}

/// 资产/负债子类型键（表与树图共用排序键）。
(String, int) bsSubtypeKey(Account a) => (
  a.type == AccountType.asset ? 'a' : 'l',
  (a.assetSubtype ?? a.liabilitySubtype)?.index ?? 99,
);
