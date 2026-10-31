import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/utils/dates.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/runtime_l10n.dart';
import '../theme/app_theme.dart';
import '../transactions/tx_detail_sheet.dart';
import '../widgets/common.dart';
import 'overview_charts.dart';
import 'overview_charts2.dart';
import 'overview_charts3.dart';
import 'overview_providers.dart';
import 'overview_scaffold.dart';

/// 本月收支页部件：月份导航 / KPI / 日现金流 / 消费环形 / 收入来源 /
/// 预算执行 / 月历热力 / 近期交易。

/// 玻璃月份导航：← 2026年10月 →。
class MonthNav extends StatelessWidget implements PreferredSizeWidget {
  const MonthNav({super.key, required this.month, required this.onShift});

  final DateTime month;
  final ValueChanged<int> onShift;

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String label;
    if (RuntimeL10n.english) {
      const en = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      label = '${en[month.month]} ${month.year}';
    } else {
      label = '${month.year} 年 ${month.month} 月';
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: const Color(0x2EE7ECF2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _arrow(Icons.chevron_left, () => onShift(-1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            _arrow(Icons.chevron_right, () => onShift(1)),
          ],
        ),
      ),
    );
  }

  Widget _arrow(IconData i, VoidCallback onTap) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      iconSize: 18,
      onPressed: onTap,
      icon: Icon(i, color: const Color(0xFFBFD9F2)),
    );
  }
}

/// 收支 KPI：OvKpiTile 的收支变体（支出增长=红：invertDelta）。
class CfKpi extends StatelessWidget {
  const CfKpi({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.delta,
    required this.currency,
    required this.hint,
    this.invertDelta = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final BigInt? delta;
  final String currency;
  final String hint;

  /// true 时「增加」视为不利（消费类）。
  final bool invertDelta;

  @override
  Widget build(BuildContext context) {
    return OvKpiTile(
      icon: icon,
      label: label,
      value: value,
      hint: hint,
      delta: delta,
      deltaCurrency: currency,
    );
  }
}

/// 日现金流：自绘双柱 + 累计净额线 + 悬停十字提示。
class DailyPanel extends StatelessWidget {
  const DailyPanel({super.key, required this.d});

  final OvCashFlowData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OvSectionHead(
            title: t.ovCfDailyTitle,
            hint: t.ovCfDailyHint,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(const Color(0xFF8FBCE8), t.dashIncome),
                const SizedBox(width: 10),
                _dot(const Color(0xFFF0907C), t.dashSpendFees),
                const SizedBox(width: 10),
                _dot(const Color(0xFFBFD9F2), t.ovCfNetLine),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: OvDailyFlowChart(
              daily: d.daily,
              format: (v) => fmtMinor(v, d.base),
              dayLabel: (day) {
                const wd = ['一', '二', '三', '四', '五', '六', '日'];
                return RuntimeL10n.english
                    ? '${day.month}/${day.day}'
                    : '${day.month} 月 ${day.day} 日 周${wd[day.weekday - 1]}';
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFFA5B5C7)),
        ),
      ],
    );
  }
}

/// 消费分类环形：中心总消费 + 右侧图例（悬停联动）。
class ExpenseDonutPanel extends StatefulWidget {
  const ExpenseDonutPanel({super.key, required this.d});

  final OvCashFlowData d;

  @override
  State<ExpenseDonutPanel> createState() => _ExpenseDonutPanelState();
}

class _ExpenseDonutPanelState extends State<ExpenseDonutPanel> {
  int? _hover;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = AppChartPalette.of(theme.brightness);
    final cats = widget.d.expenseCategories.take(7).toList();
    final slices = [
      for (var i = 0; i < cats.length; i++)
        OvSlice(
          label: cats[i].$1,
          value: cats[i].$2,
          color: palette[i % palette.length],
          sublabel: fmtMinor(cats[i].$2, widget.d.base),
        ),
    ];
    if (widget.d.expenseCategories.length > 7) {
      final rest = widget.d.expenseCategories
          .skip(7)
          .fold(BigInt.zero, (a, x) => a + x.$2);
      slices.add(
        OvSlice(
          label: t.ovCfOthers,
          value: rest,
          color: palette[8 % palette.length],
          sublabel: fmtMinor(rest, widget.d.base),
        ),
      );
    }
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(
            title: t.ovCfExpenseCatTitle,
            hint: t.ovCfExpenseCatHint,
          ),
          const SizedBox(height: 8),
          if (slices.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  t.ovCfNoExpense,
                  style: const TextStyle(color: Color(0xFF71859D)),
                ),
              ),
            )
          else
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: OvDonutChart(
                      slices: slices,
                      externalHover: _hover,
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t.ovCfMonthExpense,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF71859D),
                            ),
                          ),
                          MoneyText(
                            widget.d.expense,
                            currencyCode: widget.d.base,
                            size: MoneySize.md,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 148,
                    child: SingleChildScrollView(
                      child: OvDonutLegend(
                        slices: slices,
                        total: widget.d.expense,
                        hover: _hover,
                        onHover: (i) => setState(() => _hover = i),
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
}

/// 收入来源：小环形 + 图例。
class IncomePanel extends StatefulWidget {
  const IncomePanel({super.key, required this.d});

  final OvCashFlowData d;

  @override
  State<IncomePanel> createState() => _IncomePanelState();
}

class _IncomePanelState extends State<IncomePanel> {
  int? _hover;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = AppChartPalette.of(theme.brightness);
    final cats = widget.d.incomeCategories.take(5).toList();
    final slices = [
      for (var i = 0; i < cats.length; i++)
        OvSlice(
          label: cats[i].$1,
          value: cats[i].$2,
          color: palette[(i + 1) % palette.length],
          sublabel: fmtMinor(cats[i].$2, widget.d.base),
        ),
    ];
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(title: t.ovCfIncomeTitle, hint: t.ovCfIncomeHint),
          const SizedBox(height: 8),
          if (slices.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  t.ovCfNoIncome,
                  style: const TextStyle(color: Color(0xFF71859D)),
                ),
              ),
            )
          else
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: OvDonutChart(
                      slices: slices,
                      stroke: 20,
                      externalHover: _hover,
                      center: MoneyText(
                        widget.d.income,
                        currencyCode: widget.d.base,
                        size: MoneySize.sm,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 130,
                    child: SingleChildScrollView(
                      child: OvDonutLegend(
                        slices: slices,
                        total: widget.d.income,
                        hover: _hover,
                        onHover: (i) => setState(() => _hover = i),
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
}

/// 预算执行：额度 vs 实际（ProgressMeter + 明细行）。
class BudgetPanel extends StatelessWidget {
  const BudgetPanel({super.key, required this.d});

  final OvCashFlowData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final budget = d.totalBudgetMinor;
    final ratio = budget > BigInt.zero
        ? d.expense.toDouble() / budget.toDouble()
        : 0.0;
    final over = ratio > 1;
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(title: t.ovCfBudgetTitle, hint: t.ovCfBudgetHint),
          const SizedBox(height: 10),
          if (budget == BigInt.zero) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EmptyState(
                      icon: Icons.safety_divider_outlined,
                      title: t.ovCfNoBudget,
                      message: t.ovCfNoBudgetMsg,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: MoneyText(
                d.expense,
                currencyCode: d.base,
                size: MoneySize.lg,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.ovCfBudgetOf(fmtMinor(budget, d.base)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFA5B5C7),
              ),
            ),
            const SizedBox(height: 10),
            ProgressMeter(
              ratio: ratio,
              over: over,
              height: 10,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.ovCfBudgetUsed,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFA5B5C7),
                  ),
                ),
                Text(
                  '${(ratio * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: over
                        ? AppColors.negativeOf(theme.brightness)
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  over ? t.ovCfOverBy : t.ovCfBudgetLeft,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFA5B5C7),
                  ),
                ),
                Text(
                  fmtMinor(
                    over ? d.expense - budget : budget - d.expense,
                    d.base,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: over
                        ? AppColors.negativeOf(theme.brightness)
                        : AppColors.positiveOf(theme.brightness),
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ],
      ),
    );
  }
}

/// 月历热力：净流入蓝 / 净流出红，强度着色；点选日期看数值。
class HeatPanel extends StatelessWidget {
  const HeatPanel({super.key, required this.d});

  final OvCashFlowData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    var peak = BigInt.one;
    for (final c in d.daily) {
      if (c.income > peak) peak = c.income;
      if (c.expense > peak) peak = c.expense;
    }
    final cells = [
      for (final c in d.daily)
        OvHeatCell(
          date: c.date,
          intensity01: (c.net.isNegative ? c.expense : c.income).toDouble() /
              peak.toDouble(),
          income: !c.net.isNegative,
          tooltip:
              '${dateKey(c.date)}\n'
              '${t.dashIncome} ${fmtMinor(c.income, d.base)}\n'
              '${t.dashSpendFees} ${fmtMinor(c.expense, d.base)}',
        ),
    ];
    return OvPanel(
      child: SingleChildScrollView(
        child: Column(
          children: [
            OvSectionHead(title: t.ovCfHeatTitle, hint: t.ovCfHeatHint),
            const SizedBox(height: 10),
            OvMonthHeatmap(
              year: d.report.year,
              month: d.report.month,
              cells: cells,
              cellSize: 30,
            ),
          ],
        ),
      ),
    );
  }
}

/// 近期交易：名称/日期 + 金额（收入蓝/支出红），点击进详情弹层。
class RecentPanel extends ConsumerWidget {
  const RecentPanel({super.key, required this.d});

  final OvCashFlowData d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(title: t.ovCfRecentTitle, hint: t.ovCfRecentHint),
          const SizedBox(height: 4),
          if (d.recent.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  t.ovCfNoTx,
                  style: const TextStyle(color: Color(0xFF71859D)),
                ),
              ),
            )
          else
            for (final r in d.recent)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => showTxDetail(context, ref, r.tx),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (r.income
                                  ? AppColors.positiveOf(theme.brightness)
                                  : AppColors.negativeOf(theme.brightness))
                              .withValues(alpha: 0.16),
                        ),
                        child: Icon(
                          r.income
                              ? Icons.south_west
                              : Icons.north_east,
                          size: 15,
                          color: r.income
                              ? AppColors.positiveOf(theme.brightness)
                              : AppColors.negativeOf(theme.brightness),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.title.isEmpty ? t.ovCfUntitled : r.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              dateKey(r.date),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF71859D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${r.income ? '+' : '-'}${fmtMinor(r.amount, d.base)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: r.income
                              ? AppColors.positiveOf(theme.brightness)
                              : AppColors.negativeOf(theme.brightness),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
