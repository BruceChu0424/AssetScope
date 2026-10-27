import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/reports/year_report.dart';
import '../../domain/utils/dates.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 年度报告视图：全年总览、月度收支柱状、分类排行、亮点。
class YearView extends StatelessWidget {
  const YearView({super.key, required this.report});

  final YearReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _summaryCard(context),
        _monthlyChartCard(context),
        _categoryCard(context),
        _highlightsCard(context),
      ],
    );
  }

  Widget _summaryCard(BuildContext context) {
    final base = report.baseCurrencyCode;
    final rate = report.savingsRate;
    return SectionCard(
      title: '${report.year} 年总览',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: AmountTile(
                      label: '全年收入',
                      amount: fmtMinor(report.totalIncomeMinor, base))),
              Expanded(
                  child: AmountTile(
                      label: '全年消费',
                      amount: fmtMinor(report.totalExpenseMinor, base))),
              Expanded(
                  child: AmountTile(
                      label: '结余',
                      amount: fmtMinor(report.totalSurplusMinor, base),
                      color: report.totalSurplusMinor.isNegative
                          ? AppColors.negativeOf(Theme.of(context).brightness)
                          : null)),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                  child: AmountTile(
                      label: '储蓄率',
                      amount: rate == null ? '—' : '${(rate * 100).toStringAsFixed(0)}%',
                      hint: '结余 / 收入')),
              Expanded(
                  child: AmountTile(
                      label: '结余为正的月份',
                      amount: '${report.savingsMonths} / 12')),
              Expanded(
                  child: AmountTile(
                      label: '支付利息',
                      amount: fmtMinor(report.debtInterestPaidMinor, base),
                      hint: '全年债务成本')),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                  child: AmountTile(
                      label: '已实现投资损益',
                      amount: fmtMinor(report.realizedPnlMinor, base),
                      color: report.realizedPnlMinor.isNegative
                          ? AppColors.negativeOf(Theme.of(context).brightness)
                          : AppColors.positiveOf(Theme.of(context).brightness),
                      hint: '卖出落袋（账面口径）')),
              Expanded(
                  child: AmountTile(
                      label: '分红派息',
                      amount: fmtMinor(report.dividendMinor, base))),
              Expanded(
                  child: AmountTile(
                      label: '投资净收益',
                      amount: fmtMinor(
                          report.realizedPnlMinor + report.dividendMinor,
                          base),
                      hint: '已实现 + 分红')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthlyChartCard(BuildContext context) {
    final theme = Theme.of(context);
    final base = report.baseCurrencyCode;
    var maxV = 0.0;
    for (final m in report.months) {
      if (m.incomeMinor.toDouble() > maxV) maxV = m.incomeMinor.toDouble();
      if (m.expenseMinor.toDouble() > maxV) maxV = m.expenseMinor.toDouble();
    }
    if (maxV == 0) return const SizedBox.shrink();
    return SectionCard(
      title: '月度收支',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _legend(context, theme.colorScheme.primary, '收入'),
          const SizedBox(width: 8),
          _legend(context, AppColors.negativeOf(theme.brightness), '支出'),
        ],
      ),
      child: SizedBox(
        height: 190,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxV * 1.15,
            groupsSpace: 4,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                  '${group.x} 月\n${fmtMinor(BigInt.from(rod.toY.round() * 100), base)}',
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            barGroups: [
              for (final m in report.months)
                if (m.hasData)
                  BarChartGroupData(
                    x: m.month,
                    barRods: [
                      BarChartRodData(
                        toY: m.incomeMinor.toDouble(),
                        color: theme.colorScheme.primary,
                        width: 7,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3)),
                      ),
                      BarChartRodData(
                        toY: m.expenseMinor.toDouble(),
                        color: AppColors.negativeOf(theme.brightness),
                        width: 7,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3)),
                      ),
                    ],
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
                  reservedSize: 22,
                  getTitlesWidget: (v, _) => Text(
                    '${v.toInt()}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor, fontSize: 10),
                  ),
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

  Widget _legend(BuildContext context, Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );

  Widget _categoryCard(BuildContext context) {
    final base = report.baseCurrencyCode;
    final tops = report.topExpenseCategories;
    if (tops.isEmpty) return const SizedBox.shrink();
    final total = report.totalExpenseMinor;
    return SectionCard(
      title: '全年消费排行',
      child: Column(
        children: [
          for (final c in tops.take(10))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (total != BigInt.zero)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                          '${(c.totalMinor.toDouble() / total.toDouble() * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Theme.of(context).hintColor)),
                    ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      fmtMinor(c.totalMinor, base),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _highlightsCard(BuildContext context) {
    final theme = Theme.of(context);
    final base = report.baseCurrencyCode;
    final b = report.biggestExpense;
    final incomes = report.topIncomeCategories;
    return SectionCard(
      title: '年度亮点',
      child: Column(
        children: [
          if (b != null)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.local_fire_department_outlined,
                  color: AppColors.brass),
              title: Text('最大单笔：${b.label}'),
              subtitle: Text('${dateKey(b.date)} · ${report.categoryNames[b.categoryId] ?? '消费'}'),
              trailing: Text(
                fmtMinor(b.amountMinor, base),
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()]),
              ),
            ),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.account_balance, size: 20),
            title: const Text('全年还贷本金'),
            trailing: Text(
              fmtMinor(report.debtPrincipalRepaidMinor, base),
              style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ),
          for (final c in incomes.take(3))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.trending_up,
                  size: 20, color: theme.colorScheme.primary),
              title: Text('收入 · ${c.name}'),
              trailing: Text(
                fmtMinor(c.totalMinor, base),
                style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()]),
              ),
            ),
        ],
      ),
    );
  }
}
