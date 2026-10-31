import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/invest/allocation.dart';
import '../../l10n/app_localizations.dart';
import '../../services/portfolio_analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'allocation_target_sheet.dart';

final allocationProvider = FutureProvider.autoDispose<AllocationReport>((
  ref,
) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) throw StateError('locked');
  return s.portfolioAnalytics.allocationReport();
});

/// 配置类配色：统一取图表调色板（青瓷-鎏金体系，深色模式提亮）。
Color allocationColor(AllocationClass c, Brightness b) {
  const order = [
    AllocationClass.equity,
    AllocationClass.fund,
    AllocationClass.bond,
    AllocationClass.cash,
    AllocationClass.fixedIncome,
    AllocationClass.alternatives,
    AllocationClass.realAssets,
    AllocationClass.longTerm,
    AllocationClass.other,
  ];
  final palette = AppChartPalette.of(b);
  final i = order.indexOf(c);
  return i < 0 ? palette.last : palette[i.clamp(0, palette.length - 1)];
}

/// 资产配置卡：九类配置桶 + 目标对比 + 5/25 带宽再平衡建议（docs/05 §10）。
class AllocationCard extends ConsumerWidget {
  const AllocationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return ref
        .watch(allocationProvider)
        .when(
          loading: () => const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => ErrorPlaceholder(t.loadFailedReports(e.toString())),
          data: (r) => SectionCard(
            title: t.assetAllocation,
            trailing: IconButton(
              tooltip: t.setTargetAllocation,
              icon: const Icon(Icons.flag_outlined, size: 18),
              onPressed: () =>
                  showAllocationTargetSheet(context, ref, r.targets),
            ),
            child: r.slices.isEmpty
                ? Text(
                    t.allocNoAssetsHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  )
                : Column(
                    children: [
                      _stackedBar(context, r),
                      const SizedBox(height: 4),
                      for (final s in r.slices) _sliceTile(context, r, s),
                      if (r.missingValuations > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 4),
                          child: Text(
                            t.allocMissingValuations(r.missingValuations),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.brassOf(theme.brightness),
                            ),
                          ),
                        ),
                      if (r.hasAdvice) ...[
                        const Divider(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            t.rebalanceAdviceTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        for (final a in r.advice)
                          if (a.needsAction) _adviceTile(context, r, a),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            t.rebalanceAdviceNote,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ] else if (r.advice.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            t.allocWithinBand,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.positiveOf(theme.brightness),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        );
  }

  Widget _stackedBar(BuildContext context, AllocationReport r) {
    final b = Theme.of(context).brightness;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (final s in r.slices)
              Expanded(
                flex: s.valueBaseMinor > BigInt.zero
                    ? s.valueBaseMinor.toInt()
                    : 1,
                child: Container(color: allocationColor(s.allocationClass, b)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sliceTile(
    BuildContext context,
    AllocationReport r,
    AllocationSlice s,
  ) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final target = r.targets[s.allocationClass];
    final sharePct = (s.share.asDouble() * 100);
    final drift = target == null ? null : sharePct - target;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: allocationColor(
            s.allocationClass,
            Theme.of(context).brightness,
          ),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(s.allocationClass.labelZh),
      subtitle: target == null
          ? null
          : Text(
              t.allocTargetPct(target),
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (drift != null &&
              r.advice.any(
                (a) => a.allocationClass == s.allocationClass && a.needsAction,
              ))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${drift >= 0 ? '+' : ''}${drift.toStringAsFixed(1)}pp',
                style: TextStyle(
                  fontSize: 12,
                  color: drift >= 0
                      ? AppColors.negativeOf(theme.brightness)
                      : AppColors.positiveOf(theme.brightness),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          SizedBox(
            width: 150,
            child: Text(
              '${fmtMinor(s.valueBaseMinor, r.baseCurrencyCode)} · ${sharePct.toStringAsFixed(1)}%',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adviceTile(
    BuildContext context,
    AllocationReport r,
    RebalanceAdvice a,
  ) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final isBuy = a.action == RebalanceAction.buy;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isBuy ? Icons.south_west : Icons.north_east,
        size: 18,
        color: isBuy
            ? AppColors.positiveOf(theme.brightness)
            : AppColors.negativeOf(theme.brightness),
      ),
      title: Text(
        '${isBuy ? t.rebalanceBuy : t.rebalanceSell}${a.allocationClass.labelZh} ≈ ${fmtMinor(a.tradeMinor, r.baseCurrencyCode)}',
      ),
      subtitle: Text(
        t.rebalanceAdviceDetail(
          (a.currentShare.asDouble() * 100).toStringAsFixed(1),
          (a.targetShare.asDouble() * 100).toStringAsFixed(0),
        ),
        style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
      ),
    );
  }
}
