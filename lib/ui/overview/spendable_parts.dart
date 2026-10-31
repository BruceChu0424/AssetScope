import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/planning/cash_projection.dart';
import '../../domain/utils/dates.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/runtime_l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'overview_anim.dart';
import 'overview_charts2.dart';
import 'overview_providers2.dart';
import 'overview_scaffold.dart';

/// 还能花多少部件：hero / 情景 / KPI / 预测曲线 / 流入流出 / 月度分配 /
/// 90 天日历 / 风险提示。

String _fmt(OvScenarios s, BigInt v) => fmtMinor(v, s.base.baseCurrencyCode);

/// Hero：安全可支配大数 + 构成明细 + 规划/剩余双段进度带。
class SpHeroPanel extends StatelessWidget {
  const SpHeroPanel({super.key, required this.s});

  final OvScenarios s;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final std = s.results[OvScenarioKind.standard]!;
    final plannedOut = s.outflow;
    final base = s.base.baseCurrencyCode;
    // 规划带：期内必要流出占可用现金的比例（上限 100%）。
    final usedRatio = s.cashNow <= BigInt.zero
        ? 0.0
        : (plannedOut + s.reserve + s.baseline).toDouble() /
              s.cashNow.toDouble();
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OvSectionHead(
            title: t.ovSpHeroTitle(s.horizonDays),
            hint: t.ovSpHeroHint,
          ),
          const Spacer(),
          OvCountUp(
            minor: std.discretionaryBaseMinor,
            builder: (v) => MoneyText(v, currencyCode: base, size: MoneySize.xl),
          ),
          const SizedBox(height: 4),
          Text(
            std.discretionaryBaseMinor > BigInt.zero
                ? t.ovSpHeroOk
                : t.ovSpHeroZero,
            style: theme.textTheme.bodySmall?.copyWith(
              color: std.discretionaryBaseMinor > BigInt.zero
                  ? const Color(0xFFA5B5C7)
                  : AppColors.warnOf(theme.brightness),
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: usedRatio.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Row(
                  children: [
                    Expanded(
                      flex: (v * 1000).round().clamp(1, 1000),
                      child: Container(color: theme.colorScheme.primary),
                    ),
                    Expanded(
                      flex: ((1 - v) * 1000).round().clamp(0, 999),
                      child: Container(color: const Color(0xFF0C1929)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _row(context, t.ovSpCashNow, _fmt(s, s.cashNow)),
          _row(context, t.ovSpPlannedOut, _fmt(s, plannedOut), negative: true),
          _row(context, t.ovSpReserved, _fmt(s, s.reserve + s.baseline)),
          _row(
            context,
            t.ovSpRemain,
            _fmt(s, std.discretionaryBaseMinor),
            strong: true,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool negative = false,
    bool strong = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFA5B5C7),
              ),
            ),
          ),
          Text(
            (negative ? '−' : '') + value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: strong ? const Color(0xFFF0F5FB) : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// 情景三卡：保守 / 标准 / 乐观，选中钢蓝描边；各显可支配额度。
class SpScenarioPanel extends StatefulWidget {
  const SpScenarioPanel({super.key, required this.s});

  final OvScenarios s;

  @override
  State<SpScenarioPanel> createState() => _SpScenarioPanelState();
}

class _SpScenarioPanelState extends State<SpScenarioPanel> {
  OvScenarioKind _sel = OvScenarioKind.standard;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(title: t.ovSpScenTitle, hint: t.ovSpScenHint),
          const SizedBox(height: 8),
          for (final e in OvScenarioKind.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _sel == e
                        ? theme.colorScheme.primary.withValues(alpha: 0.75)
                        : const Color(0x2EE7ECF2),
                    width: _sel == e ? 1.6 : 1,
                  ),
                  color: _sel == e
                      ? theme.colorScheme.primary.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.02),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _sel = e),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Row(
                        children: [
                          Icon(
                            switch (e) {
                              OvScenarioKind.conservative =>
                                Icons.shield_outlined,
                              OvScenarioKind.standard => Icons.tune,
                              OvScenarioKind.optimistic =>
                                Icons.rocket_launch_outlined,
                            },
                            size: 17,
                            color: _sel == e
                                ? const Color(0xFFBFD9F2)
                                : const Color(0xFF71859D),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  switch (e) {
                                    OvScenarioKind.conservative =>
                                      t.ovSpScenConservative,
                                    OvScenarioKind.standard =>
                                      t.ovSpScenStandard,
                                    OvScenarioKind.optimistic =>
                                      t.ovSpScenOptimistic,
                                  },
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _sel == e
                                        ? const Color(0xFFF0F5FB)
                                        : null,
                                  ),
                                ),
                                Text(
                                  switch (e) {
                                    OvScenarioKind.conservative =>
                                      t.ovSpScenConsSub,
                                    OvScenarioKind.standard =>
                                      t.ovSpScenStdSub,
                                    OvScenarioKind.optimistic =>
                                      t.ovSpScenOptSub,
                                  },
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: const Color(0xFF71859D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: MoneyText(
                              widget.s.results[e]!.discretionaryBaseMinor,
                              currencyCode: widget.s.base.baseCurrencyCode,
                              size: MoneySize.sm,
                              key: ValueKey(_fmt(
                                widget.s,
                                widget.s.results[e]!.discretionaryBaseMinor,
                              )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 四 KPI：安全可支配 / 建议月上限 / 剩余日均可花 / 最低现金点。
class SpKpis extends StatelessWidget {
  const SpKpis({super.key, required this.s});

  final OvScenarios s;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final std = s.results[OvScenarioKind.standard]!;
    final base = s.base.baseCurrencyCode;
    final months = math.max(1, (s.horizonDays / 30).round());
    return OvKpiRow(
      children: [
        OvKpiTile(
          icon: Icons.shield_moon_outlined,
          label: t.ovSpKpiSafe(s.horizonDays),
          value: fmtMinor(std.discretionaryBaseMinor, base),
          hint: t.ovSpHeroHint,
          accent: const Color(0xFF7EA6D9),
        ),
        OvKpiTile(
          icon: Icons.speed_outlined,
          label: t.ovSpKpiMonthCap,
          value: fmtMinor(std.discretionaryBaseMinor ~/ BigInt.from(months), base),
          hint: t.ovSpKpiMonthCapHint(s.horizonDays),
          accent: const Color(0xFF8FBCE8),
        ),
        OvKpiTile(
          icon: Icons.today_outlined,
          label: t.ovSpKpiDaily,
          value: fmtMinor(
            std.discretionaryBaseMinor ~/ BigInt.from(s.horizonDays),
            base,
          ),
          hint: t.ovSpKpiDailyHint(s.horizonDays),
          accent: const Color(0xFF7EA6D9),
        ),
        OvKpiTile(
          icon: Icons.south_outlined,
          label: t.ovSpKpiLow,
          value: std.minBalanceDate == null
              ? '—'
              : fmtMinor(std.minBalanceBaseMinor, base),
          hint: std.minBalanceDate == null
              ? t.ovSpKpiLowHint
              : t.ovSpKpiLowAt(dateKey(std.minBalanceDate!)),
          valueColor: std.hasShortfall ? const Color(0xFFF0907C) : null,
          accent: std.hasShortfall ? const Color(0xFFF0907C) : const Color(0xFFD8BE85),
        ),
      ],
    );
  }
}

/// 90 天预测曲线：现金余额实线 + 安全底线虚线 + 缺口红点 + 触摸明细。
class SpForecastPanel extends StatelessWidget {
  const SpForecastPanel({super.key, required this.s});

  final OvScenarios s;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final std = s.results[OvScenarioKind.standard]!;
    final series = std.series;
    final base = s.base.baseCurrencyCode;
    final floor = s.reserve + s.baseline;
    final spots = [
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].balanceBaseMinor.toDouble()),
    ];
    var min = spots.first.y, max = spots.first.y;
    for (final sp in spots) {
      min = math.min(min, sp.y);
      max = math.max(max, sp.y);
    }
    min = math.min(min, floor.toDouble());
    final pad = (max - min) * 0.15 + 1;
    final shortfallIdx = {
      for (final sf in std.shortfalls)
        series.indexWhere((p) => dateKey(p.date) == dateKey(sf.date)),
    };
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      child: Column(
        children: [
          OvSectionHead(
            title: t.ovSpFcTitle(s.horizonDays),
            hint: t.ovSpFcHint,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: OvChartSweep(
              child: LineChart(
                LineChartData(
                  minY: min - pad,
                  maxY: max + pad,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touched) => [
                        for (final sp in touched)
                          LineTooltipItem(
                            '${dateKey(series[sp.x.toInt().clamp(0, series.length - 1)].date)}\n'
                                '${fmtMinor(BigInt.from(sp.y.round()), base)}',
                            const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFF0F5FB),
                            ),
                          ),
                      ],
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: floor.toDouble(),
                        color: AppColors.warnOf(theme.brightness)
                            .withValues(alpha: 0.75),
                        strokeWidth: 1.2,
                        dashArray: [6, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFD8BE85),
                          ),
                        labelResolver: (_) => t.ovSpFloorLabel,
                        ),
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      barWidth: 2.2,
                      color: theme.colorScheme.primary,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, x, _, _) => FlDotCirclePainter(
                          radius: shortfallIdx.contains(x) ? 4.5 : 0,
                          color: const Color(0xFFF0907C),
                          strokeColor: const Color(0xFFF0907C),
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.18),
                            theme.colorScheme.primary.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        interval: math.max(
                          1.0,
                          (series.length / 5).ceilToDouble(),
                        ),
                        getTitlesWidget: (v, _) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            dateKey(
                              series[v.toInt().clamp(0, series.length - 1)].date,
                            ).substring(5),
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF71859D),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: double.infinity,
                  ),
                  borderData: FlBorderData(show: false),
                ),
                duration: const Duration(milliseconds: 400),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 流入/流出对比：合计 + 净额 + 按事件类型分列。
class SpFlowPanel extends StatelessWidget {
  const SpFlowPanel({super.key, required this.s});

  final OvScenarios s;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final base = s.base.baseCurrencyCode;
    final byKind = <CashEventKind, BigInt>{};
    for (final e in s.base.events) {
      final v = e.amountBaseMinor.isNegative
          ? -e.amountBaseMinor
          : e.amountBaseMinor;
      final k = e.amountBaseMinor.isNegative
          ? e.kind
          : CashEventKind.incomeExpected;
      byKind[k] = (byKind[k] ?? BigInt.zero) + v;
    }
    String kindLabel(CashEventKind k) => switch (k) {
      CashEventKind.planned => t.ovSpFlowPlanned,
      CashEventKind.debtRepay => t.ovSpFlowDebt,
      CashEventKind.budgetBaseline => t.ovSpFlowBudget,
      CashEventKind.incomeExpected => t.ovSpFlowIncome,
      CashEventKind.other => t.ovSpFlowOther,
    };
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(title: t.ovSpFlowTitle, hint: t.ovSpFlowHint),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.ovSpFlowIn,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFA5B5C7),
                      ),
                    ),
                    MoneyText(s.inflow, currencyCode: base, size: MoneySize.md),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      t.ovSpFlowOut,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFA5B5C7),
                      ),
                    ),
                    MoneyText(s.outflow, currencyCode: base, size: MoneySize.md),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.ovSpFlowNet,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFA5B5C7),
                ),
              ),
              Text(
                fmtMinor(s.inflow - s.outflow, base, sign: true),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: signColor(s.inflow - s.outflow, theme.brightness),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final k in CashEventKind.values)
            if (byKind[k] != null && byKind[k]! > BigInt.zero)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (k == CashEventKind.incomeExpected
                                ? AppColors.positiveOf(theme.brightness)
                                : k == CashEventKind.debtRepay
                                ? AppColors.warnOf(theme.brightness)
                                : theme.colorScheme.primary)
                            .withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        kindLabel(k),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFA5B5C7),
                        ),
                      ),
                    ),
                    Text(
                      fmtMinor(byKind[k]!, base),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
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

/// 月度消费分配：每月计划流出 vs 建议上限（计划 + 可支配摊月）。
class SpMonthlyPanel extends StatelessWidget {
  const SpMonthlyPanel({super.key, required this.s});

  final OvScenarios s;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final std = s.results[OvScenarioKind.standard]!;
    final from = s.base.fromDate;
    // 逐月计划流出（负事件按月聚合）。
    final monthly = <int, BigInt>{}; // 0=本月,1=次月,2=第三月...
    for (final e in s.base.events) {
      if (!e.amountBaseMinor.isNegative) continue;
      final m = (DateTime(e.date.year, e.date.month)
                  .difference(DateTime(from.year, from.month))
                  .inDays /
              30)
          .round();
      monthly[m] = (monthly[m] ?? BigInt.zero) - e.amountBaseMinor;
    }
    final months = [0, 1, 2].where(monthly.containsKey).toList();
    final capMonth = std.discretionaryBaseMinor ~/
        BigInt.from(math.max(1, (s.horizonDays / 30).round()));
    final peak = [
      for (final m in months) monthly[m]!.toDouble(),
      capMonth.toDouble(),
    ].fold(1.0, math.max);
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(
        children: [
          OvSectionHead(title: t.ovSpMonthTitle, hint: t.ovSpMonthHint),
          const SizedBox(height: 6),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: peak * 1.15,
                barGroups: [
                  for (var i = 0; i < months.length; i++)
                    BarChartGroupData(
                      x: months[i],
                      barRods: [
                        BarChartRodData(
                          toY: monthly[months[i]]!.toDouble(),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.85,
                          ),
                        ),
                        BarChartRodData(
                          toY: capMonth.toDouble(),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                          color: AppColors.brassOf(theme.brightness).withValues(
                            alpha: 0.65,
                          ),
                        ),
                      ],
                    ),
                ],
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
                      ri == 0 ? t.ovSpMonthPlanned : t.ovSpMonthCap,
                      TextStyle(
                        fontSize: 11,
                        color: ri == 0
                            ? const Color(0xFFBFD9F2)
                            : const Color(0xFFE5C078),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (v, _) {
                        final d = DateTime(
                          from.year,
                          from.month + v.toInt(),
                        );
                        final label = RuntimeL10n.english
                            ? '${d.month}'
                            : '${d.month}${rt('月')}';
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF71859D),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
              duration: const Duration(milliseconds: 500),
            ),
          ),
        ],
      ),
    );
  }
}

/// 90 天日历：三个月度热力（流出强度 + 缺口红标）。
class SpCalendarPanel extends StatelessWidget {
  const SpCalendarPanel({super.key, required this.s});

  final OvScenarios s;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final std = s.results[OvScenarioKind.standard]!;
    final byDay = <String, BigInt>{};
    var peak = BigInt.one;
    for (final e in s.base.events) {
      if (!e.amountBaseMinor.isNegative) continue;
      final k = dateKey(e.date);
      byDay[k] = (byDay[k] ?? BigInt.zero) - e.amountBaseMinor;
      if (byDay[k]! > peak) peak = byDay[k]!;
    }
    final shortfallDays = {
      for (final sf in std.shortfalls) dateKey(sf.date),
    };
    final from = s.base.fromDate;
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SingleChildScrollView(
        child: Column(
          children: [
            OvSectionHead(title: t.ovSpCalTitle, hint: t.ovSpCalHint),
            const SizedBox(height: 6),
            for (var m = 0; m < 3; m++)
              _monthHeat(from, m, byDay, peak, shortfallDays, t),
          ],
        ),
      ),
    );
  }

  Widget _monthHeat(
    DateTime from,
    int m,
    Map<String, BigInt> byDay,
    BigInt peak,
    Set<String> shortfallDays,
    AppLocalizations t,
  ) {
    final first = DateTime(from.year, from.month + m, 1);
    final days = DateTime(first.year, first.month + 1, 0).day;
    final cells = <OvHeatCell>[];
    for (var d = 1; d <= days; d++) {
      final date = DateTime(first.year, first.month, d);
      if (date.isBefore(DateTime(from.year, from.month, from.day))) continue;
      final k = dateKey(date);
      final v = byDay[k];
      if (v == null) continue;
      cells.add(
        OvHeatCell(
          date: date,
          intensity01: v.toDouble() / peak.toDouble(),
          income: false,
          tooltip:
              '$k · ${t.ovSpCalDay(fmtMinor(v, s.base.baseCurrencyCode))}'
              '${shortfallDays.contains(k) ? '\n⚠ ${t.ovSpCalShortfall}' : ''}',
          marks: shortfallDays.contains(k)
              ? {t.ovSpCalShortfall: const Color(0xFFF0907C)}
              : const {},
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            RuntimeL10n.english
                ? '${first.year}-${first.month.toString().padLeft(2, '0')}'
                : '${first.year} 年 ${first.month} 月',
            style: const TextStyle(fontSize: 11, color: Color(0xFFA5B5C7)),
          ),
          const SizedBox(height: 4),
          OvMonthHeatmap(
            year: first.year,
            month: first.month,
            cells: cells,
            cellSize: 22,
          ),
        ],
      ),
    );
  }
}

/// 风险提示：缺口列表 + 规则化建议。
class SpRiskPanel extends StatelessWidget {
  const SpRiskPanel({super.key, required this.s});

  final OvScenarios s;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final std = s.results[OvScenarioKind.standard]!;
    final base = s.base.baseCurrencyCode;
    final cons = s.results[OvScenarioKind.conservative]!;
    return OvPanel(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OvSectionHead(title: t.ovSpRiskTitle, hint: t.ovSpRiskHint),
            const SizedBox(height: 8),
            if (std.shortfalls.isEmpty) ...[
              Row(
                children: [
                  OvBreathing(
                    color: const Color(0xFF8FBCE8),
                    radius: 20,
                    child: const Icon(
                      Icons.verified_outlined,
                      size: 30,
                      color: Color(0xFF8FBCE8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.ovSpRiskNone(s.horizonDays),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFE7F0FA),
                      ),
                    ),
                  ),
                ],
              ),
            ] else
              for (final sf in std.shortfalls.take(6))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 15,
                        color: Color(0xFFF0907C),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${dateKey(sf.date)} · ${sf.label}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFE7F0FA),
                          ),
                        ),
                      ),
                      Text(
                        fmtMinor(sf.amountBaseMinor, base, sign: true),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFF0907C),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
            const Divider(height: 22),
            Text(
              t.ovSpAdviceTitle,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            _advice(
              context,
              icon: Icons.tune,
              text: t.ovSpAdviceScenario(
                _fmt(s, cons.discretionaryBaseMinor),
              ),
            ),
            if (std.discretionaryBaseMinor == BigInt.zero)
              _advice(
                context,
                icon: Icons.event_busy,
                text: t.ovSpAdviceZero,
              ),
            _advice(
              context,
              icon: Icons.plagiarism_outlined,
              text: t.ovSpAdviceReconcile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _advice(BuildContext context, {required IconData icon, required String text}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFFD8BE85)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFA5B5C7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
