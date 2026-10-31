import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/invest/risk_metrics.dart';
import '../../l10n/app_localizations.dart';
import '../../services/portfolio_analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

final riskProvider = FutureProvider.autoDispose<RiskReportResult>((ref) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) throw StateError('locked');
  return s.portfolioAnalytics.riskReport();
});

/// 风险卡：年化波动率 / 最大回撤 / Sharpe / Sortino / 最佳最差月 / 月胜率。
/// 基于 TWR 月度子期间收益（外部现金流已剔除），口径见 docs/05 §11。
class RiskCard extends ConsumerWidget {
  const RiskCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return ref
        .watch(riskProvider)
        .when(
          loading: () => const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => ErrorPlaceholder(t.loadFailedReports(e.toString())),
          data: (result) => _card(context, ref, result),
        );
  }

  Widget _card(BuildContext context, WidgetRef ref, RiskReportResult result) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final r = result.report;
    return SectionCard(
      title: t.riskTitle,
      trailing: IconButton(
        tooltip: t.riskFreeRateTooltip,
        icon: const Icon(Icons.tune, size: 18),
        onPressed: () => _editRiskFreeRate(context, ref, r),
      ),
      child: r == null
          ? Text(
              t.riskNeedMorePoints(result.valuationPoints),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                height: 1.5,
              ),
            )
          : Column(
              children: [
                if (!r.hasEnoughPeriods)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      t.riskSmallSample(r.periods),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.brassOf(theme.brightness),
                      ),
                    ),
                  ),
                _row(
                  context,
                  t.annualizedReturnTwr,
                  _pct(r.annualizedReturn),
                  strong: true,
                ),
                _row(context, t.annualizedVolatility, _pct(r.annualizedVolatility)),
                _maxDrawdownRow(context, r),
                _row(
                  context,
                  t.sharpeRatio,
                  _num(r.sharpe),
                  hint: t.sharpeFormulaHint,
                ),
                _row(
                  context,
                  t.sortinoRatio,
                  _num(r.sortino),
                  hint: t.sortinoHint,
                ),
                _row(
                  context,
                  t.bestWorstMonth,
                  '${_pct(r.bestMonth)} / ${_pct(r.worstMonth)}',
                ),
                _row(context, t.monthWinRate, _pct(r.positiveMonthsRatio)),
                const Divider(height: 12),
                Text(
                  t.riskBasisNote(
                    r.periods,
                    result.valuationPoints,
                    (r.riskFreeAnnual * 100).toStringAsFixed(1),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    String? hint,
    bool strong = false,
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: hint == null
          ? null
          : Text(
              hint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _maxDrawdownRow(BuildContext context, RiskReport r) {
    final mdd = r.maxDrawdown;
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final span =
        (mdd != null &&
            r.drawdownPeakDate != null &&
            r.drawdownTroughDate != null)
        ? t.drawdownSpan(
            '${r.drawdownPeakDate!.year}.${r.drawdownPeakDate!.month}',
            '${r.drawdownTroughDate!.year}.${r.drawdownTroughDate!.month}',
          )
        : null;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(t.maxDrawdown),
      subtitle: span == null
          ? null
          : Text(
              span,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
      trailing: Text(
        mdd == null ? '—' : _pct(mdd),
        style: TextStyle(
          color: mdd == null ? null : AppColors.negativeOf(theme.brightness),
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  String _pct(double? v) =>
      v == null ? '—' : '${(v * 100).toStringAsFixed(1)}%';

  String _num(double? v) => v == null ? '—' : v.toStringAsFixed(2);

  Future<void> _editRiskFreeRate(
    BuildContext context,
    WidgetRef ref,
    RiskReport? r,
  ) async {
    final t = AppLocalizations.of(context);
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null || !context.mounted) return;
    final currentPercent = r?.riskFreeAnnual != null
        ? null
        : await s.portfolioAnalytics.riskFreeRatePercent();
    if (!context.mounted) return;
    final ctrl = TextEditingController(
      text:
          (r?.riskFreeAnnual != null
                  ? r!.riskFreeAnnual * 100
                  : currentPercent!)
              .toStringAsFixed(1),
    );
    final ok = await showAppDialog<bool>(
      context,
      builder: (dctx) => AppDialog(
        title: t.riskFreeRateDialogTitle,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ParticleTextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(hintText: t.riskFreeRateHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: Text(t.reportCancel),
          ),
          ParticleFilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: Text(t.reportSave),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final v = double.tryParse(ctrl.text.trim());
    if (v == null || v < 0 || v > 20) return;
    await s.portfolioAnalytics.setRiskFreeRatePercent(v);
    ref.invalidate(riskProvider);
  }
}
