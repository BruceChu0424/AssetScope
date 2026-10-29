import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/utils/dates.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'dashboard_providers.dart';

/// 仪表盘次级卡片：地球入口、净资产走势、未来计划支出、待处理提醒。
/// 核心财务卡（hero/月流/可支配/体检/洞察）见 dashboard_cards.dart。

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
                // 用 spot.x 回查 BigInt 原值——从 double 反推会在大金额下失真。
                getTooltipItems: (touched) => [
                  for (final s in touched)
                    LineTooltipItem(
                        '${d.series[s.x.toInt()].$1}  ${fmtMinor(d.series[s.x.toInt()].$2, d.nw.baseCurrencyCode)}',
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
    final issues = <(String, String?)>[
      if (d.pendingDueCount > 0)
        ('${d.pendingDueCount} 笔到期计划待入账（计划页可一键记入）', '/plans'),
      if (d.nw.missingValuations > 0)
        ('${d.nw.missingValuations} 个账户缺估值（不计为 0，请在账户页补录）', null),
      if (d.nw.staleValuations > 0)
        ('${d.nw.staleValuations} 个账户估值已过期（>30 天）', null),
      if (d.report.attribution.hasResidual)
        ('本月归因存在待核对差额：${fmtMinor(d.report.attribution.residual, d.report.baseCurrencyCode)}', null),
    ];
    if (issues.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      title: '待处理',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (text, path) in issues)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: InkWell(
                onTap: path == null ? null : () => context.go(path),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                          path != null
                              ? Icons.event_available_outlined
                              : Icons.error_outline,
                          size: 16,
                          color: path != null
                              ? AppColors.brassOf(theme.brightness)
                              : AppColors.warnOf(theme.brightness)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: path != null
                                    ? theme.colorScheme.primary
                                    : null)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
