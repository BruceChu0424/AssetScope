import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/utils/dates.dart';
import '../../../services/insight_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_providers.dart';
import '../widgets/common.dart';

/// 仪表盘卡片集（按需拆分的小组件，全部无状态）。

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

class GlobeEntryCard extends StatelessWidget {
  const GlobeEntryCard({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: () => context.go('/globe'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D1E30), Color(0xFF143D2F)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.public,
                    color: Color(0xFF2DD4BF), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('资产地球',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('$count 处已定位资产 · 3D 环视全球固定资产',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.hintColor),
            ],
          ),
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

class TrendCard extends StatelessWidget {
  const TrendCard({super.key, required this.d});

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spots = <FlSpot>[
      for (var i = 0; i < d.series.length; i++)
        FlSpot(i.toDouble(), d.series[i].$2.toDouble()),
    ];
    if (spots.isEmpty) return const SizedBox.shrink();
    var min = spots.first.y;
    var max = spots.first.y;
    for (final s in spots) {
      if (s.y < min) min = s.y;
      if (s.y > max) max = s.y;
    }
    final padding = (max - min) * 0.15 + 1;
    return SectionCard(
      title: '净资产走势（近 12 个月）',
      child: SizedBox(
        height: 170,
        child: LineChart(
          LineChartData(
            minY: (min - padding) < 0 ? min - padding : 0,
            maxY: max + padding,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => [
                  for (final s in spots)
                    LineTooltipItem(
                        fmtMinor(
                            BigInt.from(s.y.round() * 100), d.nw.baseCurrencyCode),
                        const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 2.2,
                dotData: const FlDotData(show: false),
                color: theme.colorScheme.primary,
                belowBarData: BarAreaData(
                  show: true,
                  color: theme.colorScheme.primary.withValues(alpha: 0.07),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: spots.length > 6
                      ? (spots.length / 6).ceilToDouble()
                      : 1,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= d.series.length) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(d.series[i].$1.substring(2),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor)),
                    );
                  },
                ),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }
}

class UpcomingCard extends StatelessWidget {
  const UpcomingCard({super.key, required this.d});

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final base = d.nw.baseCurrencyCode;
    return SectionCard(
      title: '未来 30 天要花的钱',
      child: d.upcoming.isEmpty
          ? Text('暂无计划支出',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).hintColor))
          : Column(
              children: [
                for (final o in d.upcoming.take(8))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: SizedBox(
                      width: 44,
                      child: Text(dateKey(o.date).substring(5),
                          style: const TextStyle(
                              fontFeatures: [FontFeature.tabularFigures()])),
                    ),
                    title: Text(o.eventName),
                    trailing: Text(
                      fmtMinor(o.amountMinor.abs(), base),
                      style: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  ),
              ],
            ),
    );
  }
}

class IssuesCard extends StatelessWidget {
  const IssuesCard({super.key, required this.d});

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final issues = <String>[];
    if (d.nw.missingValuations > 0) {
      issues.add('${d.nw.missingValuations} 个账户缺估值（不计为 0，请在账户页补录）');
    }
    if (d.nw.staleValuations > 0) {
      issues.add('${d.nw.staleValuations} 个账户估值已过期（>30 天）');
    }
    if (d.report.attribution.hasResidual) {
      issues.add(
          '本月归因存在待核对差额：${fmtMinor(d.report.attribution.residual, d.report.baseCurrencyCode)}');
    }
    if (issues.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      title: '待处理',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final i in issues)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline,
                      size: 16,
                      color: AppColors.brassOf(theme.brightness)),
                  const SizedBox(width: 8),
                  Expanded(
                      child:
                          Text(i, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
