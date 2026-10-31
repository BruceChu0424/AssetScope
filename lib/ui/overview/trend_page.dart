import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/analytics/health.dart' show NetWorthMilestone;
import '../../domain/utils/dates.dart';
import '../../l10n/app_localizations.dart';
import '../../services/stats_service.dart' show MonthReport;
import '../dashboard/dashboard_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'balance_sheet_parts.dart';
import 'overview_anim.dart';
import 'overview_charts2.dart';
import 'overview_providers.dart';
import 'overview_scaffold.dart';

/// 净资产序列 provider（任意 N 月；与首页走势同锚点）。
final trendSeriesProvider = FutureProvider.autoDispose
    .family<List<(String, BigInt)>, int>((ref, months) async {
      final s = sessionOf(ref.watch(vaultProvider));
      if (s == null) throw StateError('locked');
      return s.statsService.netWorthSeries(months);
    });

/// 净资产走势页：五 KPI + 大型趋势图（关键节点/时间范围）+ 关键洞察 +
/// 本月归因瀑布 + 资产负债双线。
class TrendPage extends ConsumerStatefulWidget {
  const TrendPage({super.key});

  @override
  ConsumerState<TrendPage> createState() => _TrendPageState();
}

class _TrendPageState extends ConsumerState<TrendPage> {
  int _months = 36;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(trendSeriesProvider(_months));
    final dash = ref.watch(dashboardProvider);
    return OverviewScaffold(
      title: t.ovTrTitle,
      titleHint: t.ovTrHint,
      child: async.when(
        loading: () => const Center(child: OrbitSpinner(size: 44)),
        error: (e, _) => Center(child: ErrorPlaceholder(t.homeLoadFailed(e))),
        data: (series) => dash.when(
          loading: () => const Center(child: OrbitSpinner(size: 44)),
          error: (e, _) => Center(child: ErrorPlaceholder(t.homeLoadFailed(e))),
          data: (d) => _Body(
            series: series,
            report: d.report,
            milestone: d.insights.milestone,
            onMonths: (m) => setState(() => _months = m),
            months: _months,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.series,
    required this.report,
    required this.milestone,
    required this.months,
    required this.onMonths,
  });

  final List<(String, BigInt)> series;
  final MonthReport report;
  final NetWorthMilestone? milestone;
  final int months;
  final ValueChanged<int> onMonths;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 1120) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: SingleChildScrollView(
          child: OvStaggerColumn(
            gap: 12,
            children: [
              _kpis(context),
              SizedBox(height: 380, child: _mainChart(context)),
              _insights(context),
              SizedBox(height: 300, child: _waterfall(context)),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: SingleChildScrollView(
        child: OvStaggerColumn(
          gap: 14,
          children: [
            SizedBox(height: 120, child: _kpis(context)),
            SizedBox(
              height: 400,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: _mainChart(context)),
                  const SizedBox(width: 14),
                  SizedBox(width: 330, child: _insights(context)),
                ],
              ),
            ),
            SizedBox(
              height: 320,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _waterfall(context)),
                  const SizedBox(width: 14),
                  Expanded(child: _dual(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpis(BuildContext context) {
    final t = AppLocalizations.of(context);
    // 序列本身不带币种——与页内归因同源的本位币（MonthReport 口径）。
    final base = report.baseCurrencyCode;
    final first = series.first.$2;
    final last = series.last.$2;
    final change = last - first;
    var maxV = series.first.$2, minV = series.first.$2;
    var maxK = series.first.$1, minK = series.first.$1;
    for (final s in series) {
      if (s.$2 > maxV) {
        maxV = s.$2;
        maxK = s.$1;
      }
      if (s.$2 < minV) {
        minV = s.$2;
        minK = s.$1;
      }
    }
    final growth = first == BigInt.zero ? null : change.toDouble() / first.toDouble().abs();
    final cc = Theme.of(context).colorScheme.primary;
    Widget tile(
      IconData i,
      String label,
      String value, {
      Color? color,
      String? hint,
    }) => OvKpiTile(
      icon: i,
      label: label,
      value: value,
      valueColor: color,
      hint: hint,
      accent: color ?? cc,
    );
    final tiles = <Widget>[
      tile(Icons.flag_outlined, t.ovTrCurrent, fmtMinor(last, base)),
      tile(
        Icons.trending_up_outlined,
        t.ovTrChange,
        fmtMinor(change, base, sign: true),
        color: signColor(change, Theme.of(context).brightness),
        hint: t.ovTrChangeHint(series.first.$1, series.last.$1),
      ),
      tile(
        Icons.percent_outlined,
        t.ovTrGrowth,
        growth == null ? '—' : '${(growth * 100).toStringAsFixed(1)}%',
        color: growth == null ? null : signColor(change, Theme.of(context).brightness),
        hint: t.ovTrGrowthHint,
      ),
      tile(Icons.north_outlined, t.ovTrMax, fmtMinor(maxV, base), hint: maxK),
      tile(Icons.south_outlined, t.ovTrMin, fmtMinor(minV, base), hint: minK),
    ];
    // 窄屏两枚一行（KPI 图标+提示的固定开销决定最小宽度）。
    return OvKpiRow(widePerRow: 5, children: tiles);
  }

  Widget _mainChart(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final spots = [
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].$2.toDouble()),
    ];
    var min = spots.first.y, max = spots.first.y;
    var maxIdx = 0, minIdx = 0;
    for (var i = 0; i < spots.length; i++) {
      if (spots[i].y > max) {
        max = spots[i].y;
        maxIdx = i;
      }
      if (spots[i].y < min) {
        min = spots[i].y;
        minIdx = i;
      }
    }
    final pad = (max - min) * 0.18 + 1;
    final options = {1, 6, 12, 36, 120};
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
      child: Column(
        children: [
          OvSectionHead(
            title: t.ovTrChartTitle,
            trailing: Row(
              children: [
                for (final m in options.toList()..sort())
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: _chip(
                      context,
                      m == 120 ? t.ovTrAll : t.ovMonths(m),
                      months == m,
                      () => onMonths(m),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: OvChartSweep(
              duration: 900,
              child: LineChart(
                LineChartData(
                  minY: min - pad < 0 ? min - pad : 0,
                  maxY: max + pad,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touched) => [
                        for (final s in touched)
                          LineTooltipItem(
                            '${series[s.x.toInt().clamp(0, series.length - 1)].$1}\n'
                                '${fmtMinor(series[s.x.toInt().clamp(0, series.length - 1)].$2, report.baseCurrencyCode)}',
                            const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF0F5FB),
                            ),
                          ),
                      ],
                    ),
                    getTouchedSpotIndicator: (bar, spots) => [
                      for (final _ in spots)
                        TouchedSpotIndicatorData(
                          const FlLine(
                            color: Color(0x66BFD9F2),
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
                          const FlDotData(show: false),
                        ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 2.6,
                      color: theme.colorScheme.primary,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, x, _, _) {
                          if (x == maxIdx) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: AppColors.brassOf(theme.brightness),
                              strokeColor: const Color(0xFFF0F5FB),
                              strokeWidth: 1.2,
                            );
                          }
                          if (x == minIdx) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: AppColors.negativeOf(theme.brightness),
                              strokeColor: const Color(0xFFF0F5FB),
                              strokeWidth: 1.2,
                            );
                          }
                          if (x == spots.length - 1) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: theme.colorScheme.primary,
                              strokeColor: const Color(0xFFBFD9F2),
                              strokeWidth: 1.4,
                            );
                          }
                          return FlDotCirclePainter(radius: 0, color: Colors.transparent);
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.26),
                            theme.colorScheme.primary.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                        interval: (max + pad - (min - pad < 0 ? min - pad : 0)) / 3,
                        getTitlesWidget: (v, _) => Text(
                          _axisShort(v),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF71859D),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: math.max(
                          1.0,
                          (series.length / 6).ceilToDouble(),
                        ),
                        getTitlesWidget: (v, _) => Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            series[v.toInt().clamp(0, series.length - 1)].$1,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF71859D),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (max + pad - (min - pad < 0 ? min - pad : 0)) / 3,
                    getDrawingHorizontalLine: (v) => const FlLine(
                      color: Color(0x14E7ECF2),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
                duration: const Duration(milliseconds: 420),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _axisShort(double v) {
    final neg = v < 0;
    final a = v.abs();
    String s;
    if (a >= 1e8) {
      s = '${(a / 1e8).toStringAsFixed(1)}亿';
    } else if (a >= 1e4) {
      s = '${(a / 1e4).toStringAsFixed(0)}万';
    } else {
      s = a.round().toString();
    }
    return neg ? '-$s' : s;
  }

  Widget _chip(BuildContext context, String label, bool active, VoidCallback onTap) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: active
                ? theme.colorScheme.primary.withValues(alpha: 0.22)
                : Colors.transparent,
            border: Border.all(
              color: active
                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                  : const Color(0x2EE7ECF2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: active ? const Color(0xFFBFD9F2) : const Color(0xFF71859D),
            ),
          ),
        ),
      ),
    );
  }

  /// 关键洞察：连涨月数 / 最大单月变动 / 趋势斜率 / 里程碑预测。
  Widget _insights(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    var streak = 0;
    for (var i = series.length - 1; i > 0; i--) {
      if (series[i].$2 > series[i - 1].$2) {
        streak++;
      } else {
        break;
      }
    }
    var bigIdx = 1;
    for (var i = 1; i < series.length; i++) {
      if ((series[i].$2 - series[i - 1].$2).abs() >
          (series[bigIdx].$2 - series[bigIdx - 1].$2).abs()) {
        bigIdx = i;
      }
    }
    final bigDelta = series[bigIdx].$2 - series[bigIdx - 1].$2;
    final ms = milestone;
    return OvPanel(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OvSectionHead(title: t.ovTrInsightTitle, hint: t.ovTrInsightHint),
            const SizedBox(height: 6),
            _ins(
              context,
              icon: Icons.local_fire_department_outlined,
              color: const Color(0xFFD8BE85),
              title: t.ovTrStreak(streak),
              sub: streak > 0 ? t.ovTrStreakSub : null,
            ),
            if (series.length >= 2)
              _ins(
                context,
                icon: Icons.swap_vert,
                color: signColor(bigDelta, theme.brightness),
                title: t.ovTrBigMove(
                  series[bigIdx].$1,
                  fmtMinor(bigDelta, report.baseCurrencyCode, sign: true),
                ),
              ),
            if (ms != null)
              _ins(
                context,
                icon: Icons.flag_outlined,
                color: const Color(0xFF8FBCE8),
                title: t.ovTrMilestone(
                  ms.monthsToTarget,
                  monthKey(DateTime(
                    ms.targetDate.year,
                    ms.targetDate.month,
                  )),
                ),
                sub: t.ovTrMilestoneSub(
                  fmtMinor(ms.slopePerMonthMinor, report.baseCurrencyCode,
                      sign: true),
                ),
              ),
            const Divider(height: 22),
            Text(
              t.ovTrAttributionGo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF71859D),
              ),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => GoRouter.of(context).go('/reports'),
              icon: const Icon(Icons.receipt_long_outlined, size: 15),
              label: Text(t.ovTrGoReport),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ins(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    String? sub,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF71859D),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _waterfall(BuildContext context) {
    final t = AppLocalizations.of(context);
    final a = report.attribution;
    final base = report.baseCurrencyCode;
    final steps = <OvWaterfallStep>[
      OvWaterfallStep(
        label: t.ovTrWfStart,
        delta: a.nwStart,
        color: const Color(0xFF7EA6D9),
        isTotal: true,
      ),
      OvWaterfallStep(
        label: t.ovNwAttrIncomeExpense,
        delta: a.incomeExpense,
        color: signColor(a.incomeExpense, Theme.of(context).brightness),
      ),
      OvWaterfallStep(
        label: t.ovNwAttrInvest,
        delta: a.investTotal,
        color: signColor(a.investTotal, Theme.of(context).brightness),
      ),
      OvWaterfallStep(
        label: t.ovNwAttrFx,
        delta: a.fxEffect,
        color: signColor(a.fxEffect, Theme.of(context).brightness),
      ),
      OvWaterfallStep(
        label: t.ovNwAttrOther,
        delta: a.otherValuation,
        color: signColor(a.otherValuation, Theme.of(context).brightness),
      ),
      OvWaterfallStep(
        label: t.ovTrWfEnd,
        delta: a.nwEnd,
        color: const Color(0xFFD8BE85),
        isTotal: true,
      ),
    ];
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(title: t.ovTrWfTitle, hint: t.ovNwAttributionHint),
          const SizedBox(height: 6),
          Expanded(
            child: OvWaterfallChart(
              steps: steps,
              valueFormatter: (v) => fmtMinor(v, base, sign: v.isNegative),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dual(BuildContext context) {
    return _TrendDualProxy(currency: report.baseCurrencyCode);
  }
}

/// 双线代理：包一层 ProviderScope 读取（避免 _Body 持 ref）。
class _TrendDualProxy extends ConsumerWidget {
  const _TrendDualProxy({required this.currency});

  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(balanceSeriesProvider(12));
    return series.when(
      loading: () => const Center(child: OrbitSpinner(size: 30)),
      error: (e, _) => Center(child: Text('$e')),
      data: (s) => BsDualTrendPanel(series: s, currency: currency),
    );
  }
}
