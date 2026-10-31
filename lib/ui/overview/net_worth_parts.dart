import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/ledger/account.dart';
import '../../domain/utils/dates.dart';
import '../../l10n/app_localizations.dart';
import '../dashboard/dashboard_providers.dart';
import '../globe/asset_globe.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'overview_anim.dart';
import 'overview_charts.dart';
import 'overview_scaffold.dart';

/// 净资产详情页部件：总览 hero / 地球分布 / 类型环形 / 分组横条 /
/// 主要账户 / 走势 / 归因。

/// 资产四桶（分布、类型环形、横条共用一套业务分组）。
enum NwBucket { cash, holdings, steady, longTerm }

NwBucket? nwBucketOf(Account a) {
  final st = a.assetSubtype;
  if (st == null) return null;
  return switch (st) {
    AssetSubtype.cash ||
    AssetSubtype.alipay ||
    AssetSubtype.wechat ||
    AssetSubtype.bank ||
    AssetSubtype.moneyFund ||
    AssetSubtype.brokerCash => NwBucket.cash,
    AssetSubtype.stock ||
    AssetSubtype.fund ||
    AssetSubtype.bond ||
    AssetSubtype.preciousMetal ||
    AssetSubtype.crypto => NwBucket.holdings,
    AssetSubtype.timeDeposit ||
    AssetSubtype.wealthMgmt ||
    AssetSubtype.depositPaid ||
    AssetSubtype.receivable => NwBucket.steady,
    _ => NwBucket.longTerm,
  };
}

/// 左：净资产总览。大数滚动计数、较上月变化、资产/负债构成条、
/// 估值覆盖与双口径（家庭份额）。
class NwHeroPanel extends StatelessWidget {
  const NwHeroPanel({super.key, required this.d});

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final base = d.nw.baseCurrencyCode;
    final delta = d.series36.length >= 2
        ? d.series36.last.$2 - d.series36[d.series36.length - 2].$2
        : d.report.attribution.netChange;
    final covered = d.nw.items.where((i) => !i.valuationMissing).length;
    final total = d.nw.items.length;
    final assetRatio = d.nw.totalAssets + d.nw.totalLiabilities == BigInt.zero
        ? 0.0
        : d.nw.totalAssets.toDouble() /
              (d.nw.totalAssets + d.nw.totalLiabilities).toDouble();
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OvSectionHead(title: t.dashNetWorth, hint: t.ovNwHint),
          const Spacer(),
          OvCountUp(
            minor: d.nw.netWorth,
            builder: (v) => MoneyText(
              v,
              currencyCode: base,
              size: MoneySize.xl,
              roll: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              DeltaBadge(minor: delta, currencyCode: base),
              const SizedBox(width: 8),
              Text(
                t.ovNwMonthDelta,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF71859D),
                ),
              ),
            ],
          ),
          if (d.nw.hasSharedAccounts) ...[
            const SizedBox(height: 6),
            Text(
              t.dashMyShare(fmtMinor(d.nw.myNetWorth, base)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.brassOf(theme.brightness),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: assetRatio),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Row(
                  children: [
                    Expanded(
                      flex: (v * 1000).round().clamp(1, 1000),
                      child: Container(color: theme.colorScheme.primary),
                    ),
                    Expanded(
                      flex: ((1 - v) * 1000).round().clamp(0, 999),
                      child: Container(
                        color: AppColors.negativeOf(theme.brightness),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AmountTile(
                  label: t.dashTotalAssets,
                  amount: fmtMinor(d.nw.totalAssets, base),
                ),
              ),
              Expanded(
                child: AmountTile(
                  label: t.dashTotalLiabilities,
                  amount: fmtMinor(d.nw.totalLiabilities, base),
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              Icon(
                Icons.verified_outlined,
                size: 15,
                color: covered == total
                    ? AppColors.positiveOf(theme.brightness)
                    : AppColors.warnOf(theme.brightness),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  t.ovNwCoverage(covered, total),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFA5B5C7),
                  ),
                ),
              ),
              InfoHint(message: t.ovNwCoverageHint, size: 13),
            ],
          ),
        ],
      ),
    );
  }
}

/// 中：全球资产分布地球（复用首页地球组件，分布模式）。
class NwGlobePanel extends StatelessWidget {
  const NwGlobePanel({super.key, required this.d});

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final unlocated = d.nw.items.where((i) => !i.account.hasLocation).length;
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
            child: OvSectionHead(
              title: t.ovNwGlobe,
              hint: t.ovNwGlobeHint,
              trailing: Text(
                t.ovNwLocatedNote(d.locatedAssets, unlocated),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF71859D),
                ),
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const AssetGlobe(backdrop: false, showActions: false),
            ),
          ),
        ],
      ),
    );
  }
}

/// 右：资产类型环形图 + 图例（四桶）。
class NwTypeDonutPanel extends StatefulWidget {
  const NwTypeDonutPanel({super.key, required this.d});

  final DashboardData d;

  @override
  State<NwTypeDonutPanel> createState() => _NwTypeDonutPanelState();
}

class _NwTypeDonutPanelState extends State<NwTypeDonutPanel> {
  int? _hover;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final base = widget.d.nw.baseCurrencyCode;
    final palette = AppChartPalette.of(theme.brightness);
    final buckets = <NwBucket, BigInt>{};
    for (final i in widget.d.nw.items) {
      if (i.account.type != AccountType.asset) continue;
      final b = nwBucketOf(i.account);
      if (b == null) continue;
      buckets[b] = (buckets[b] ?? BigInt.zero) + i.valueBaseMinor;
    }
    String label(NwBucket b) => switch (b) {
      NwBucket.cash => t.ovNwGroupCash,
      NwBucket.holdings => t.ovNwGroupHold,
      NwBucket.steady => t.ovNwGroupSteady,
      NwBucket.longTerm => t.ovNwGroupLong,
    };
    final order = NwBucket.values.where(buckets.containsKey).toList();
    final slices = [
      for (var k = 0; k < order.length; k++)
        OvSlice(
          label: label(order[k]),
          value: buckets[order[k]]!,
          color: palette[k % palette.length],
          sublabel: fmtMinor(buckets[order[k]]!, base),
        ),
    ];
    if (slices.isEmpty) {
      return OvPanel(
        child: Column(
          children: [
            OvSectionHead(title: t.ovNwAssetTypes),
            const Spacer(),
            EmptyState(
              icon: Icons.donut_small_outlined,
              title: t.ovNwNoAssets,
              message: t.ovNwNoAssetsMsg,
            ),
            const Spacer(),
          ],
        ),
      );
    }
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(
            title: t.ovNwAssetTypes,
            hint: t.ovNwAssetTypesHint,
          ),
          const SizedBox(height: 12),
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
                          t.dashAssetsTotal,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF71859D),
                          ),
                        ),
                        MoneyText(
                          widget.d.nw.totalAssets,
                          currencyCode: base,
                          size: MoneySize.md,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 150,
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

/// 左下：账户分布横条（四桶占比 + 进度条）。
class NwGroupBarsPanel extends StatelessWidget {
  const NwGroupBarsPanel({super.key, required this.d});

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final base = d.nw.baseCurrencyCode;
    final palette = AppChartPalette.of(theme.brightness);
    final buckets = <NwBucket, BigInt>{};
    for (final i in d.nw.items) {
      if (i.account.type != AccountType.asset) continue;
      final b = nwBucketOf(i.account);
      if (b == null) continue;
      buckets[b] = (buckets[b] ?? BigInt.zero) + i.valueBaseMinor;
    }
    final order = NwBucket.values.where(buckets.containsKey).toList();
    return OvPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OvSectionHead(title: t.ovNwGroupTitle, hint: t.ovNwGroupHint),
          const SizedBox(height: 12),
          if (order.isEmpty)
            Expanded(child: Center(child: Text(t.ovNwNoAssets, style: const TextStyle(color: Color(0xFF71859D)))))
          else
            for (var k = 0; k < order.length; k++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: _BarRow(
                  label: switch (order[k]) {
                    NwBucket.cash => t.ovNwGroupCash,
                    NwBucket.holdings => t.ovNwGroupHold,
                    NwBucket.steady => t.ovNwGroupSteady,
                    NwBucket.longTerm => t.ovNwGroupLong,
                  },
                  amount: fmtMinor(buckets[order[k]]!, base),
                  ratio: buckets[order[k]]!.toDouble() /
                      math.max(1, d.nw.totalAssets.toDouble()),
                  color: palette[k % palette.length],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.amount,
    required this.ratio,
    required this.color,
  });

  final String label;
  final String amount;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFE7F0FA),
                ),
              ),
            ),
            Text(
              amount,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 46,
              child: Text(
                '${(ratio * 100).toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFA5B5C7),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(end: ratio.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 640),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 7,
              child: Stack(
                children: [
                  Container(color: color.withValues(alpha: 0.13)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: v,
                      child: Container(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 右下：主要资产账户 Top 6（值 + 占比微条 + 估值状态点）。
class NwTopAccountsPanel extends StatelessWidget {
  const NwTopAccountsPanel({super.key, required this.d});

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final base = d.nw.baseCurrencyCode;
    final items = d.nw.items
        .where((i) => i.account.type == AccountType.asset)
        .toList()
      ..sort((a, b) => b.valueBaseMinor.compareTo(a.valueBaseMinor));
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(
            title: t.ovNwTopAccounts,
            trailing: TextButton(
              onPressed: () => GoRouter.of(context).go('/assets'),
              child: Text(t.ovNwViewAll),
            ),
          ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Expanded(child: Center(child: Text(t.ovNwNoAssets, style: const TextStyle(color: Color(0xFF71859D)))))
          else
            for (final i in items.take(6))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i.valuationMissing
                            ? AppColors.warnOf(theme.brightness)
                            : theme.colorScheme.primary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i.account.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          // 占比微条。
                          LayoutBuilder(
                            builder: (context, c) {
                              final ratio = d.nw.totalAssets == BigInt.zero
                                  ? 0.0
                                  : i.valueBaseMinor.toDouble() /
                                        d.nw.totalAssets.toDouble();
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: SizedBox(
                                  height: 4,
                                  width: c.maxWidth,
                                  child: LinearProgressIndicator(
                                    value: ratio.clamp(0.0, 1.0),
                                    minHeight: 4,
                                    backgroundColor: theme.colorScheme.primary
                                        .withValues(alpha: 0.10),
                                    valueColor: AlwaysStoppedAnimation(
                                      i.valuationMissing
                                          ? AppColors.warnOf(theme.brightness)
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      fmtMinor(i.valueBaseMinor, base),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: i.valuationMissing
                            ? AppColors.warnOf(theme.brightness)
                            : null,
                      ),
                    ),
                    if (i.valuationMissing) ...[
                      const SizedBox(width: 5),
                      InfoHint(message: t.ovNwMissingHint, size: 13),
                    ],
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// 底左：36 个月净资产走势（6/12/36 切换，扫描入场，十字提示）。
class NwTrendPanel extends StatefulWidget {
  const NwTrendPanel({super.key, required this.d});

  final DashboardData d;

  @override
  State<NwTrendPanel> createState() => _NwTrendPanelState();
}

class _NwTrendPanelState extends State<NwTrendPanel> {
  int _months = 12;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final base = widget.d.nw.baseCurrencyCode;
    final series36 = widget.d.series36;
    if (series36.isEmpty) {
      return OvPanel(
        child: Column(
          children: [
            OvSectionHead(title: t.dashNwTrend),
            const Spacer(),
            EmptyState(
              icon: Icons.show_chart,
              title: t.ovNwTrendEmpty,
              message: t.ovNwTrendEmptyMsg,
            ),
            const Spacer(),
          ],
        ),
      );
    }
    final maxMonths = series36.length;
    final months = _months.clamp(1, maxMonths);
    final series = months >= maxMonths
        ? series36
        : series36.sublist(series36.length - months);
    final spots = [
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].$2.toDouble()),
    ];
    var min = spots.first.y, max = spots.first.y;
    for (final s in spots) {
      min = math.min(min, s.y);
      max = math.max(max, s.y);
    }
    final pad = (max - min) * 0.15 + 1;
    return OvPanel(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      child: Column(
        children: [
          OvSectionHead(
            title: t.dashNwTrend,
            hint: t.dashNwTrendHint(maxMonths),
            trailing: _RangeChips(
              months: months,
              maxMonths: maxMonths,
              onChanged: (m) => setState(() => _months = m),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: OvChartSweep(
              child: LineChart(
                LineChartData(
                  minY: min - pad < 0 ? min - pad : 0,
                  maxY: max + pad,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touched) => [
                        for (final s in touched)
                          LineTooltipItem(
                            '${series[s.x.toInt()].$1}  '
                                '${fmtMinor(series[s.x.toInt()].$2, base)}',
                            const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF0F5FB),
                            ),
                          ),
                      ],
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 2.4,
                      dotData: FlDotData(
                        show: spots.length <= 2,
                        getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                          radius: 4,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      color: theme.colorScheme.primary,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.22),
                            theme.colorScheme.primary.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
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
                    leftTitles: const AxisTitles(),
                  ),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: double.infinity,
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
}

class _RangeChips extends StatelessWidget {
  const _RangeChips({
    required this.months,
    required this.maxMonths,
    required this.onChanged,
  });

  final int months;
  final int maxMonths;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final options = {6, 12, 36, maxMonths}.where((m) => m <= maxMonths).toList()
      ..sort();
    return Row(
      children: [
        for (final m in options)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onChanged(m),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: months == m
                        ? theme.colorScheme.primary.withValues(alpha: 0.22)
                        : Colors.transparent,
                    border: Border.all(
                      color: months == m
                          ? theme.colorScheme.primary.withValues(alpha: 0.6)
                          : const Color(0x2EE7ECF2),
                    ),
                  ),
                  child: Text(
                    t.ovMonths(m),
                    style: TextStyle(
                      fontSize: 11,
                      color: months == m
                          ? const Color(0xFFBFD9F2)
                          : const Color(0xFF71859D),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 底右：本月变动归因（收支结余/投资/汇率/其他/修正/待核对）。
class NwAttributionPanel extends StatelessWidget {
  const NwAttributionPanel({super.key, required this.d});

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final base = d.report.baseCurrencyCode;
    final a = d.report.attribution;
    final rows = <(String, BigInt, String)>[
      (t.ovNwAttrIncomeExpense, a.incomeExpense, t.ovNwAttrIncomeHint),
      (t.ovNwAttrInvest, a.investTotal, t.ovNwAttrInvestHint),
      (t.ovNwAttrFx, a.fxEffect, t.ovNwAttrFxHint),
      (t.ovNwAttrOther, a.otherValuation, t.ovNwAttrOtherHint),
      (t.ovNwAttrCorrection, a.correction, t.ovNwAttrCorrectionHint),
    ];
    return OvPanel(
      child: Column(
        children: [
          OvSectionHead(
            title: t.ovNwAttribution,
            hint: t.ovNwAttributionHint,
            trailing: Text(
              dateKey(d.nw.asOf),
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF71859D),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _AttrRow(
            label: t.ovNwNetChange,
            value: a.netChange,
            base: base,
            bold: true,
          ),
          const Divider(height: 18),
          for (final (label, v, hint) in rows)
            _AttrRow(label: label, value: v, base: base, hint: hint),
          if (a.hasResidual) ...[
            const Divider(height: 18),
            _AttrRow(
              label: t.ovNwAttrResidual,
              value: a.residual,
              base: base,
              warn: true,
              hint: t.dashResidualTooltip,
            ),
          ],
        ],
      ),
    );
  }
}

class _AttrRow extends StatelessWidget {
  const _AttrRow({
    required this.label,
    required this.value,
    required this.base,
    this.bold = false,
    this.warn = false,
    this.hint,
  });

  final String label;
  final BigInt value;
  final String base;
  final bool bold;
  final bool warn;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: bold ? FontWeight.w600 : null,
                      color: bold ? const Color(0xFFF0F5FB) : null,
                    ),
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(width: 5),
                  InfoHint(message: hint!, size: 13),
                ],
              ],
            ),
          ),
          Text(
            fmtMinor(value, base, sign: true),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: warn
                  ? AppColors.warnOf(theme.brightness)
                  : signColor(value, theme.brightness),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
