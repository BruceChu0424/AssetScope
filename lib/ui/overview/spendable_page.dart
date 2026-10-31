import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/common.dart';
import 'overview_anim.dart';
import 'overview_providers2.dart';
import 'overview_scaffold.dart';
import 'spendable_parts.dart';

/// 还能花多少页：安全可支配 hero + 三情景重放 + 四 KPI + 90 天预测
/// 曲线 + 流入流出 + 月度分配 + 90 天日历 + 风险提示。
/// 口径：C(t) = Σ现金 + Σ事件；可支配 = min_t[C(t) − R(t) − B]，
/// 情景只换事件流（保守剔估算收入 / 乐观剔估算支出），完全可解释。
class SpendablePage extends ConsumerWidget {
  const SpendablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(scenarioProvider);
    final horizon = async.maybeWhen(data: (s) => s.horizonDays, orElse: () => 90);
    return OverviewScaffold(
      title: t.ovSpTitle(horizon),
      titleHint: t.ovSpHint,
      child: async.when(
        loading: () => const Center(child: OrbitSpinner(size: 44)),
        error: (e, _) => Center(child: ErrorPlaceholder(t.homeLoadFailed(e))),
        data: (s) => _Body(s: s),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.s});

  final OvScenarios s;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final top = SizedBox(
      height: 300,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: SpHeroPanel(s: s)),
          const SizedBox(width: 14),
          Expanded(flex: 3, child: SpScenarioPanel(s: s)),
        ],
      ),
    );
    final kpis = SizedBox(
      height: 118,
      child: Row(
        children: [
          Expanded(child: SpKpis(s: s)),
        ],
      ),
    );
    final mid = SizedBox(
      height: 330,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: SpForecastPanel(s: s)),
          const SizedBox(width: 14),
          Expanded(flex: 3, child: SpFlowPanel(s: s)),
        ],
      ),
    );
    final bottom = SizedBox(
      height: 330,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: SpMonthlyPanel(s: s)),
          const SizedBox(width: 14),
          Expanded(flex: 3, child: SpCalendarPanel(s: s)),
          const SizedBox(width: 14),
          Expanded(flex: 3, child: SpRiskPanel(s: s)),
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
              SizedBox(height: 300, child: SpHeroPanel(s: s)),
              SpScenarioPanel(s: s),
              SpKpis(s: s),
              SizedBox(height: 330, child: SpForecastPanel(s: s)),
              SpFlowPanel(s: s),
              SizedBox(height: 300, child: SpMonthlyPanel(s: s)),
              SpCalendarPanel(s: s),
              SpRiskPanel(s: s),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: SingleChildScrollView(
        child: OvStaggerColumn(gap: 14, children: [top, kpis, mid, bottom]),
      ),
    );
  }
}
