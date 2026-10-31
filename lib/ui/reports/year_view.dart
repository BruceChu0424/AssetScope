import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/reports/year_report.dart';
import '../../domain/utils/dates.dart';
import '../../l10n/app_localizations.dart';
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
    final t = AppLocalizations.of(context);
    final base = report.baseCurrencyCode;
    final rate = report.savingsRate;
    return SectionCard(
      title: t.yearSummaryTitle(report.year),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AmountTile(
                  label: t.yearTotalIncome,
                  amount: fmtMinor(report.totalIncomeMinor, base),
                ),
              ),
              Expanded(
                child: AmountTile(
                  label: t.yearTotalExpense,
                  amount: fmtMinor(report.totalExpenseMinor, base),
                ),
              ),
              Expanded(
                child: AmountTile(
                  label: t.surplus,
                  amount: fmtMinor(report.totalSurplusMinor, base),
                  color: report.totalSurplusMinor.isNegative
                      ? AppColors.negativeOf(Theme.of(context).brightness)
                      : null,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: AmountTile(
                  label: t.savingsRate,
                  amount: rate == null
                      ? '—'
                      : '${(rate * 100).toStringAsFixed(0)}%',
                  tooltip: t.savingsRateTooltip,
                ),
              ),
              Expanded(
                child: AmountTile(
                  label: t.positiveSurplusMonths,
                  amount: '${report.savingsMonths} / 12',
                ),
              ),
              Expanded(
                child: AmountTile(
                  label: t.interestPaid,
                  amount: fmtMinor(report.debtInterestPaidMinor, base),
                  tooltip: t.interestPaidTooltip,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: AmountTile(
                  label: t.realizedPnl,
                  amount: fmtMinor(report.realizedPnlMinor, base),
                  color: report.realizedPnlMinor.isNegative
                      ? AppColors.negativeOf(Theme.of(context).brightness)
                      : AppColors.positiveOf(Theme.of(context).brightness),
                  tooltip: t.realizedPnlTooltip,
                ),
              ),
              Expanded(
                child: AmountTile(
                  label: t.dividends,
                  amount: fmtMinor(report.dividendMinor, base),
                ),
              ),
              Expanded(
                child: AmountTile(
                  label: t.netInvestmentGain,
                  amount: fmtMinor(
                    report.realizedPnlMinor + report.dividendMinor,
                    base,
                  ),
                  tooltip: t.netInvestmentGainTooltip,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthlyChartCard(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final base = report.baseCurrencyCode;
    var maxV = 0.0;
    for (final m in report.months) {
      if (m.incomeMinor.toDouble() > maxV) maxV = m.incomeMinor.toDouble();
      if (m.expenseMinor.toDouble() > maxV) maxV = m.expenseMinor.toDouble();
    }
    if (maxV == 0) return const SizedBox.shrink();
    return SectionCard(
      title: t.monthlyCashflow,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _legend(context, theme.colorScheme.primary, t.incomeLabel),
          const SizedBox(width: 8),
          _legend(context, AppColors.negativeOf(theme.brightness), t.expenseLabel),
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
                  t.barTooltipMonth(
                    group.x,
                    fmtMinor(BigInt.from(rod.toY.round() * 100), base),
                  ),
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
                          top: Radius.circular(3),
                        ),
                      ),
                      BarChartRodData(
                        toY: m.expenseMinor.toDouble(),
                        color: AppColors.negativeOf(theme.brightness),
                        width: 7,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ],
                  ),
            ],
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (v, _) => Text(
                    '${v.toInt()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontSize: 10,
                    ),
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
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );

  Widget _categoryCard(BuildContext context) {
    final t = AppLocalizations.of(context);
    final base = report.baseCurrencyCode;
    final tops = report.topExpenseCategories;
    if (tops.isEmpty) return const SizedBox.shrink();
    final total = report.totalExpenseMinor;
    return SectionCard(
      title: t.yearExpenseRanking,
      child: Column(
        children: [
          for (final c in tops.take(10))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (total != BigInt.zero)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '${(c.totalMinor.toDouble() / total.toDouble() * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      fmtMinor(c.totalMinor, base),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
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
    final t = AppLocalizations.of(context);
    final base = report.baseCurrencyCode;
    final b = report.biggestExpense;
    final incomes = report.topIncomeCategories;
    return SectionCard(
      title: t.yearHighlights,
      child: Column(
        children: [
          if (b != null)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.local_fire_department_outlined,
                color: AppColors.brass,
              ),
              title: Text(t.biggestExpense(b.label)),
              subtitle: Text(
                '${dateKey(b.date)} · ${report.categoryNames[b.categoryId] ?? t.expenseFallback}',
              ),
              trailing: Text(
                fmtMinor(b.amountMinor, base),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.account_balance, size: 20),
            title: Text(t.loanPrincipalRepaid),
            trailing: Text(
              fmtMinor(report.debtPrincipalRepaidMinor, base),
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          for (final c in incomes.take(3))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.trending_up,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              title: Text(t.incomeCategoryEntry(c.name)),
              trailing: Text(
                fmtMinor(c.totalMinor, base),
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
