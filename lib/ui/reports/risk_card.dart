import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/invest/risk_metrics.dart';
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
    return ref
        .watch(riskProvider)
        .when(
          loading: () => const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => ErrorPlaceholder('加载失败：$e'),
          data: (result) => _card(context, ref, result),
        );
  }

  Widget _card(BuildContext context, WidgetRef ref, RiskReportResult result) {
    final theme = Theme.of(context);
    final r = result.report;
    return SectionCard(
      title: '风险与风险调整后收益',
      trailing: IconButton(
        tooltip: '无风险利率（Sharpe/Sortino 参数）',
        icon: const Icon(Icons.tune, size: 18),
        onPressed: () => _editRiskFreeRate(context, ref, r),
      ),
      child: r == null
          ? Text(
              '需要至少 2 个有效月末估值点（当前 ${result.valuationPoints} 个）。\n'
              '每月给持仓更新一次价格，即可得到回撤、波动率等风险画像。',
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
                      '⚠ 有效样本 ${r.periods} 个月（< 6），指标波动大，仅供参考',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.brassOf(theme.brightness),
                      ),
                    ),
                  ),
                _row(
                  context,
                  '年化收益（TWR）',
                  _pct(r.annualizedReturn),
                  strong: true,
                ),
                _row(context, '年化波动率', _pct(r.annualizedVolatility)),
                _maxDrawdownRow(context, r),
                _row(
                  context,
                  'Sharpe 比率',
                  _num(r.sharpe),
                  hint: '(年化收益 − 无风险) / 波动率',
                ),
                _row(
                  context,
                  'Sortino 比率',
                  _num(r.sortino),
                  hint: '下行偏差版 Sharpe',
                ),
                _row(
                  context,
                  '最佳 / 最差月',
                  '${_pct(r.bestMonth)} / ${_pct(r.worstMonth)}',
                ),
                _row(context, '月胜率', _pct(r.positiveMonthsRatio)),
                const Divider(height: 12),
                Text(
                  '基于 ${r.periods} 个月度子期间（近 36 个月中 ${result.valuationPoints} 个有效月末估值点）· 无风险利率 ${(r.riskFreeAnnual * 100).toStringAsFixed(1)}%',
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
    final span =
        (mdd != null &&
            r.drawdownPeakDate != null &&
            r.drawdownTroughDate != null)
        ? '${r.drawdownPeakDate!.year}.${r.drawdownPeakDate!.month} 峰 → ${r.drawdownTroughDate!.year}.${r.drawdownTroughDate!.month} 谷'
        : null;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: const Text('最大回撤'),
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('无风险利率（年化 %）'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ParticleTextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(hintText: '如 2.0（十年期国债收益率附近）'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('取消'),
          ),
          ParticleFilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('保存'),
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
