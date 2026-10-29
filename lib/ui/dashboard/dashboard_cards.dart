import 'package:flutter/material.dart';

import '../../../domain/utils/dates.dart';
import '../../../services/insight_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_providers.dart';
import '../widgets/common.dart';

/// 仪表盘核心财务卡：净资产 hero、本月收支、可支配、体检、智慧洞察。
/// 次级卡片（地球入口/走势/未来支出/待处理）见 dashboard_secondary_cards.dart。

class NetWorthHeroCard extends StatelessWidget {
  const NetWorthHeroCard({super.key, required this.d});

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delta = d.report.attribution.netChange;
    final assetRatio = d.nw.totalAssets + d.nw.totalLiabilities == BigInt.zero
        ? 0.0
        : (d.nw.totalAssets.toDouble() /
            (d.nw.totalAssets + d.nw.totalLiabilities).toDouble());
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('净资产',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor)),
                const Spacer(),
                Text('截至 ${dateKey(d.nw.asOf)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor)),
              ],
            ),
            const SizedBox(height: 6),
            MoneyText(d.nw.netWorth,
                currencyCode: d.nw.baseCurrencyCode, size: MoneySize.xl),
            const SizedBox(height: 8),
            Row(
              children: [
                DeltaBadge(
                    minor: delta, currencyCode: d.nw.baseCurrencyCode),
                if (d.report.attribution.hasResidual) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: '差额非 0 通常意味着缺估值、漏记或导入重复（月报页有明细）',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brassOf(theme.brightness)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '待核对 ${fmtMinor(d.report.attribution.residual, d.report.baseCurrencyCode)}',
                        style: TextStyle(
                          color: AppColors.brassOf(theme.brightness),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            // 资产/负债构成条：一段绿一段红，直觉呈现杠杆。
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    Expanded(
                        flex: (assetRatio * 1000).round().clamp(1, 1000),
                        child: Container(color: theme.colorScheme.primary)),
                    Expanded(
                      flex:
                          ((1 - assetRatio) * 1000).round().clamp(0, 999),
                      child: Container(
                          color: AppColors.negativeOf(theme.brightness))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: AmountTile(
                        label: '总资产',
                        amount:
                            fmtMinor(d.nw.totalAssets, d.nw.baseCurrencyCode))),
                Expanded(
                    child: AmountTile(
                        label: '总负债',
                        amount: fmtMinor(
                            d.nw.totalLiabilities, d.nw.baseCurrencyCode))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MonthFlowCard extends StatelessWidget {
  const MonthFlowCard({super.key, required this.d});

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final base = d.report.baseCurrencyCode;
    final a = d.report.attribution;
    return SectionCard(
      title: '本月收支（${d.report.month} 月）',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: AmountTile(
                      label: '收入', amount: fmtMinor(d.income, base))),
              Expanded(
                  child: AmountTile(
                      label: '消费与费用',
                      amount: fmtMinor(d.expense, base))),
              Expanded(
                  child: AmountTile(
                      label: '结余',
                      amount: fmtMinor(d.surplus, base),
                      color: d.surplus.isNegative
                          ? AppColors.negativeOf(Theme.of(context).brightness)
                          : null)),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                  child: AmountTile(
                      label: '投资损益',
                      amount: fmtMinor(a.investTotal, base, sign: true))),
              Expanded(
                  child: AmountTile(
                      label: '还贷本金',
                      amount: fmtMinor(d.report.debtPrincipalRepaidMinor, base))),
              Expanded(
                  child: AmountTile(
                      label: '支付利息',
                      amount: fmtMinor(d.report.debtInterestPaidMinor, base))),
            ],
          ),
        ],
      ),
    );
  }
}

class SpendableCard extends StatelessWidget {
  const SpendableCard({super.key, required this.d});

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = d.nw.baseCurrencyCode;
    final proj = d.projection;
    final pace = d.insights.pace;
    return SectionCard(
      title: '还能花多少（未来 ${d.projectionDays} 天）',
      trailing: Text('截至 ${dateKey(proj.throughDate)}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AmountTile(
            label: '计划外可支配上限',
            amount: fmtMinor(proj.discretionaryBaseMinor, base),
            hint: '已扣除固定计划、还款、准备金与现金底线',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: AmountTile(
                      label: '本月消费预测',
                      amount: fmtMinor(pace.projectedMinor, base),
                      hint: '按当前速度外推到月末')),
              Expanded(
                  child: AmountTile(
                      label: '剩余日均可花',
                      amount: fmtMinor(
                          pace.dailyAvgMinor > BigInt.zero
                              ? pace.dailyAvgMinor
                              : BigInt.zero,
                          base),
                      hint: '已过 ${pace.daysElapsed} 天')),
            ],
          ),
          if (proj.minBalanceDate != null) ...[
            const SizedBox(height: 10),
            AmountTile(
              label: '现金最低点',
              amount:
                  '${fmtMinor(proj.minBalanceBaseMinor, base)} · ${dateKey(proj.minBalanceDate!)}',
              color: proj.hasShortfall
                  ? AppColors.negativeOf(theme.brightness)
                  : null,
            ),
          ],
          if (proj.hasShortfall) ...[
            const SizedBox(height: 8),
            for (final sf in proj.shortfalls.take(3))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                    '⚠ ${sf.label}（${dateKey(sf.date)}）短缺',
                    style: TextStyle(
                        color: AppColors.negativeOf(theme.brightness))),
              ),
          ],
        ],
      ),
    );
  }
}

class HealthCard extends StatelessWidget {
  const HealthCard({super.key, required this.d});

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = d.insights.health;
    Widget cell(String label, String value, String hint) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor)),
              const SizedBox(height: 3),
              Text(value,
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()])),
              Text(hint,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor, fontSize: 11)),
            ],
          ),
        );
    return SectionCard(
      title: '财务体检',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cell('储蓄率', _pct(h.savingsRate), '本月（收入−消费）/收入'),
          cell('应急月数', _num(h.emergencyMonths), '流动资产/月均消费'),
          cell('资产负债率', _pct(h.debtToAsset), '总负债/总资产'),
        ],
      ),
    );
  }

  String _pct(double? v) => v == null ? '—' : '${(v * 100).toStringAsFixed(0)}%';
  String _num(double? v) => v == null ? '—' : v.toStringAsFixed(1);
}

class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key, required this.insights});

  final List<Insight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return SectionCard(
      title: '智慧洞察',
      child: Column(
        children: [
          for (var i = 0; i < insights.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insights[i].icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(insights[i].title,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(insights[i].detail,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor, height: 1.45)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
