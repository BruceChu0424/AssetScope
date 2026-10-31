import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/ledger/account.dart';
import '../../l10n/app_localizations.dart';
import '../../services/stats_service.dart';
import '../dashboard/dashboard_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'overview_anim.dart';
import 'overview_charts.dart';
import 'overview_charts2.dart';
import 'overview_providers.dart';
import 'overview_scaffold.dart';

/// 资产负债表部件：总额卡 / 天平 / 树图 / 资产表 / 负债表 / 流动性 /
/// 负债构成 / 双线。

String _subtypeLabel(Account a) =>
    a.assetSubtype?.labelZh ?? a.liabilitySubtype?.labelZh ?? '';

/// 左右总额卡：大数 + 环比 + 近 12 月迷你面积趋势。
class BsTotalPanel extends StatelessWidget {
  const BsTotalPanel({
    super.key,
    required this.d,
    required this.series,
    required this.asset,
  });

  final DashboardData d;
  final List<OvBalancePoint> series;
  final bool asset;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final base = d.nw.baseCurrencyCode;
    final value = asset ? d.nw.totalAssets : d.nw.totalLiabilities;
    final delta = series.length >= 2
        ? (asset
              ? series.last.assets - series[series.length - 2].assets
              : series.last.liabilities - series[series.length - 2].liabilities)
        : null;
    final spots = [
      for (var i = 0; i < series.length; i++)
        FlSpot(
          i.toDouble(),
          (asset ? series[i].assets : series[i].liabilities).toDouble(),
        ),
    ];
    var min = spots.first.y, max = spots.first.y;
    for (final s in spots) {
      min = math.min(min, s.y);
      max = math.max(max, s.y);
    }
    final pad = (max - min) * 0.2 + 1;
    final color = asset
        ? theme.colorScheme.primary
        : AppColors.warnOf(theme.brightness);
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OvSectionHead(
            title: asset ? t.dashAssetsTotal : t.dashLiabilitiesTotal,
            hint: asset ? t.ovBsAssetsHint : t.ovBsLiabHint,
          ),
          const SizedBox(height: 6),
          OvCountUp(
            minor: value,
            builder: (v) => MoneyText(v, currencyCode: base, size: MoneySize.lg),
          ),
          const SizedBox(height: 6),
          if (delta != null) DeltaBadge(minor: delta, currencyCode: base),
          const Spacer(),
          SizedBox(
            height: 84,
            child: OvChartSweep(
              duration: 900,
              child: LineChart(
                LineChartData(
                  minY: (min - pad).clamp(0, double.infinity),
                  maxY: max + pad,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 2,
                      color: color,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                  titlesData: const FlTitlesData(show: false),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                ),
                duration: const Duration(milliseconds: 360),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 中央天平：倾角随负债率落位，底座净资产。
class BsScalePanel extends StatelessWidget {
  const BsScalePanel({super.key, required this.d});

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final base = d.nw.baseCurrencyCode;
    final dta = d.nw.totalAssets == BigInt.zero
        ? 0.0
        : d.nw.totalLiabilities.toDouble() / d.nw.totalAssets.toDouble();
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(
            title: t.ovBsScaleTitle,
            hint: t.ovBsScaleHint,
            trailing: Text(
              t.dashDebtToAsset,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFA5B5C7),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: OvBalanceScale(
                debtToAsset: dta,
                width: 280,
                height: 210,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.dashNetWorth,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF71859D),
                      ),
                    ),
                    MoneyText(d.nw.netWorth, currencyCode: base, size: MoneySize.md),
                    const SizedBox(height: 4),
                    Text(
                      '${(dta * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: dta > 0.5
                            ? AppColors.negativeOf(theme.brightness)
                            : const Color(0xFFA5B5C7),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
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

/// 树图：资产子类型面积 = 金额。
class BsTreemapPanel extends StatelessWidget {
  const BsTreemapPanel({super.key, required this.d});

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = AppChartPalette.of(theme.brightness);
    final base = d.nw.baseCurrencyCode;
    final sums = <String, BigInt>{};
    for (final i in d.nw.items) {
      if (i.account.type != AccountType.asset) continue;
      final label = _subtypeLabel(i.account);
      sums[label] = (sums[label] ?? BigInt.zero) + i.valueBaseMinor;
    }
    final entries = sums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          OvSectionHead(title: t.ovBsTreemapTitle, hint: t.ovBsTreemapHint),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  t.ovNwNoAssets,
                  style: const TextStyle(color: Color(0xFF71859D)),
                ),
              ),
            )
          else
            Expanded(
              child: OvTreemapChart(
                entries: [
                  for (var i = 0; i < entries.length; i++)
                    OvTreemapEntry(
                      label: entries[i].key,
                      value: entries[i].value,
                      color: palette[i % palette.length],
                      detail: fmtMinor(entries[i].value, base),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 资产分类表：子类型 × (金额/占比/环比/估值状态)。
class BsAssetTablePanel extends StatelessWidget {
  const BsAssetTablePanel({super.key, required this.d});

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final base = d.nw.baseCurrencyCode;
    final prev = d.report.nwStartBreakdown;
    Map<String, BigInt> prevSums(NetWorthBreakdown b) {
      final m = <String, BigInt>{};
      for (final i in b.items) {
        if (i.account.type != AccountType.asset) continue;
        final label = _subtypeLabel(i.account);
        m[label] = (m[label] ?? BigInt.zero) + i.valueBaseMinor;
      }
      return m;
    }

    final now = prevSums(d.nw);
    final before = prevSums(prev);
    final rows = now.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(
            title: t.ovBsAssetTableTitle,
            hint: t.ovBsAssetTableHint,
          ),
          const SizedBox(height: 6),
          _head(context, t.ovBsColClass, t.ovBsColAmount, t.ovBsColShare, t.ovBsColDelta),
          const Divider(height: 12),
          if (rows.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  t.ovNwNoAssets,
                  style: const TextStyle(color: Color(0xFF71859D)),
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final r in rows)
                      _row(
                        context,
                        label: r.key,
                        amount: fmtMinor(r.value, base),
                        share: d.nw.totalAssets == BigInt.zero
                            ? '—'
                            : '${(r.value.toDouble() / d.nw.totalAssets.toDouble() * 100).toStringAsFixed(1)}%',
                        delta: before[r.key] == null
                            ? null
                            : r.value - before[r.key]!,
                        base: base,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _head(
    BuildContext context,
    String a,
    String b,
    String c,
    String dd,
  ) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: const Color(0xFF71859D),
      fontSize: 11,
    );
    return Row(
      children: [
        Expanded(flex: 3, child: Text(a, style: style)),
        Expanded(flex: 2, child: Text(b, style: style, textAlign: TextAlign.right)),
        Expanded(flex: 1, child: Text(c, style: style, textAlign: TextAlign.right)),
        Expanded(flex: 2, child: Text(dd, style: style, textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required String amount,
    required String share,
    required BigInt? delta,
    required String base,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              share,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFA5B5C7),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              delta == null ? '—' : fmtMinor(delta, base, sign: true),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                color: signColor(delta ?? BigInt.zero, theme.brightness),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 负债分类表：子类型 + 金额 + 占比；零负债显示干净空状态。
class BsLiabilityTablePanel extends StatelessWidget {
  const BsLiabilityTablePanel({super.key, required this.d});

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final base = d.nw.baseCurrencyCode;
    final sums = <String, BigInt>{};
    for (final i in d.nw.items) {
      if (i.account.type != AccountType.liability) continue;
      final label = _subtypeLabel(i.account);
      sums[label] = (sums[label] ?? BigInt.zero) + i.valueBaseMinor;
    }
    final rows = sums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(title: t.ovBsLiabTableTitle, hint: t.ovBsLiabTableHint),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OvBreathing(
                      color: const Color(0xFF8FBCE8),
                      radius: 30,
                      child: const Icon(
                        Icons.spa_outlined,
                        size: 44,
                        color: Color(0xFF8FBCE8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t.ovBsNoDebt,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: const Color(0xFFE7F0FA),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.ovBsNoDebtMsg,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF71859D),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final r in rows)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.key,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              fmtMinor(r.value, base),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 44,
                              child: Text(
                                '${(d.nw.totalLiabilities == BigInt.zero ? 0 : r.value.toDouble() / d.nw.totalLiabilities.toDouble() * 100).toStringAsFixed(0)}%',
                                textAlign: TextAlign.right,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFFA5B5C7),
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ],
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

/// 流动性结构：≤1 天 / ≤90 天 / >90 天 三桶环形。
class BsLiquidityPanel extends StatefulWidget {
  const BsLiquidityPanel({super.key, required this.d});

  final DashboardData d;

  @override
  State<BsLiquidityPanel> createState() => _BsLiquidityPanelState();
}

class _BsLiquidityPanelState extends State<BsLiquidityPanel> {
  int? _hover;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final base = widget.d.nw.baseCurrencyCode;
    final palette = AppChartPalette.of(theme.brightness);
    final buckets = <int, BigInt>{}; // 0=活 1=中 2=长
    for (final i in widget.d.nw.items) {
      if (i.account.type != AccountType.asset) continue;
      final days = i.account.liquidityDays;
      final k = days <= 1 ? 0 : (days <= 90 ? 1 : 2);
      buckets[k] = (buckets[k] ?? BigInt.zero) + i.valueBaseMinor;
    }
    final labels = [t.ovBsLiquidNow, t.ovBsLiquidMid, t.ovBsLiquidLong];
    final slices = [
      for (final k in [0, 1, 2])
        if (buckets[k] != null && buckets[k]! > BigInt.zero)
          OvSlice(
            label: labels[k],
            value: buckets[k]!,
            color: palette[k],
            sublabel: fmtMinor(buckets[k]!, base),
          ),
    ];
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(title: t.ovBsLiquidityTitle, hint: t.ovBsLiquidityHint),
          const SizedBox(height: 8),
          if (slices.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  t.ovNwNoAssets,
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
                      center: MoneyText(
                        widget.d.nw.totalAssets,
                        currencyCode: base,
                        size: MoneySize.sm,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 128,
                    child: OvDonutLegend(
                      slices: slices,
                      total: widget.d.nw.totalAssets,
                      hover: _hover,
                      onHover: (i) => setState(() => _hover = i),
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

/// 负债构成环形：按子类型。
class BsLiabMixPanel extends StatefulWidget {
  const BsLiabMixPanel({super.key, required this.d});

  final DashboardData d;

  @override
  State<BsLiabMixPanel> createState() => _BsLiabMixPanelState();
}

class _BsLiabMixPanelState extends State<BsLiabMixPanel> {
  int? _hover;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final base = widget.d.nw.baseCurrencyCode;
    final palette = AppChartPalette.of(theme.brightness);
    final sums = <String, BigInt>{};
    for (final i in widget.d.nw.items) {
      if (i.account.type != AccountType.liability) continue;
      final label = _subtypeLabel(i.account);
      sums[label] = (sums[label] ?? BigInt.zero) + i.valueBaseMinor;
    }
    final entries = sums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final slices = [
      for (var i = 0; i < entries.length; i++)
        OvSlice(
          label: entries[i].key,
          value: entries[i].value,
          color: palette[(i + 3) % palette.length],
          sublabel: fmtMinor(entries[i].value, base),
        ),
    ];
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(title: t.ovBsLiabMixTitle, hint: t.ovBsLiabMixHint),
          const SizedBox(height: 8),
          if (slices.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  t.ovBsNoDebt,
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
                      center: MoneyText(
                        widget.d.nw.totalLiabilities,
                        currencyCode: base,
                        size: MoneySize.sm,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 120,
                    child: OvDonutLegend(
                      slices: slices,
                      total: widget.d.nw.totalLiabilities,
                      hover: _hover,
                      onHover: (i) => setState(() => _hover = i),
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

/// 资产/负债双线 12 个月趋势。
class BsDualTrendPanel extends StatelessWidget {
  const BsDualTrendPanel({super.key, required this.series, this.currency = 'CNY'});

  final List<OvBalancePoint> series;

  /// 本位币（触摸提示格式化用）。
  final String currency;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final assets = [
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].assets.toDouble()),
    ];
    final liabs = [
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].liabilities.toDouble()),
    ];
    var min = assets.first.y, max = assets.first.y;
    for (final s in [...assets, ...liabs]) {
      min = math.min(min, s.y);
      max = math.max(max, s.y);
    }
    final pad = (max - min) * 0.18 + 1;
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      child: Column(
        children: [
          OvSectionHead(
            title: t.ovBsDualTitle,
            hint: t.ovBsDualHint,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(theme.colorScheme.primary, t.dashAssetsTotal),
                const SizedBox(width: 8),
                _dot(AppColors.warnOf(theme.brightness), t.dashLiabilitiesTotal),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: OvChartSweep(
              child: LineChart(
                LineChartData(
                  minY: (min - pad).clamp(0, double.infinity),
                  maxY: max + pad,
                  lineBarsData: [
                    LineChartBarData(
                      spots: assets,
                      isCurved: true,
                      barWidth: 2.2,
                      color: theme.colorScheme.primary,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.10,
                        ),
                      ),
                    ),
                    LineChartBarData(
                      spots: liabs,
                      isCurved: true,
                      barWidth: 2,
                      color: AppColors.warnOf(theme.brightness),
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touched) => [
                        for (final s in touched)
                          LineTooltipItem(
                            '${series[s.x.toInt().clamp(0, series.length - 1)].monthKey}\n'
                                '${fmtMinor(s.y.toBigInt(), currency)}',
                            const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFF0F5FB),
                            ),
                          ),
                      ],
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
                        interval: math.max(
                          1.0,
                          (series.length / 5).ceilToDouble(),
                        ),
                        getTitlesWidget: (v, _) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            series[v.toInt().clamp(0, series.length - 1)]
                                .monthKey,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF71859D),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
                duration: const Duration(milliseconds: 380),
              ),
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

extension on double {
  BigInt toBigInt() => BigInt.from(round());
}
