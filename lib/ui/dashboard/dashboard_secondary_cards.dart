import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../domain/utils/dates.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/runtime_l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'dashboard_providers.dart';

/// 仪表盘次级卡片：净资产走势、未来计划支出、待处理提醒。
/// （核心财务卡见 dashboard_cards.dart；卡片列容器由首页
/// globe_home_page.dart 编排。）

/// 净资产走势 + 时间转轴：底缘是一条**机械滚筒滑轨**——按住滚筒左右
/// 拖动即可把时间范围从 1 个月拉长/收短（最长 36 个月），滚筒握纹随
/// 值旋转（转轴手感），标题括号里的月数实时联动。旧版底缘的月份时
/// 间轴已移除；明细仍由图表触摸提示承载。
class TrendCard extends StatefulWidget {
  const TrendCard({super.key, required this.d});

  final DashboardData d;

  @override
  State<TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends State<TrendCard> {
  static const _defaultMonths = 12;
  int _months = _defaultMonths;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final d = widget.d;
    if (d.series36.isEmpty) return const SizedBox.shrink();
    final maxMonths = d.series36.length;
    final months = _months.clamp(1, maxMonths);
    // 任意 N 月区间 = 36 月序列的后缀 N 项（同锚点，无二次计算）。
    final series = months >= maxMonths
        ? d.series36
        : d.series36.sublist(d.series36.length - months);
    final spots = [
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].$2.toDouble()),
    ];
    var min = spots.first.y;
    var max = spots.first.y;
    for (final s in spots) {
      if (s.y < min) min = s.y;
      if (s.y > max) max = s.y;
    }
    final padding = (max - min) * 0.15 + 1;
    return SectionCard(
      title: t.dashNwTrend,
      titleWidget: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.35),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: Text(
          t.dashNwTrendMonths(months),
          key: ValueKey(months),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      trailing: Tooltip(
        message: t.dashNwTrendHint(maxMonths),
        child: Icon(Icons.info_outline, size: 15, color: theme.hintColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 150,
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
                          '${series[s.x.toInt()].$1}  '
                          '${fmtMinor(series[s.x.toInt()].$2, d.nw.baseCurrencyCode)}',
                          const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 2.2,
                    // 区间极短（1–2 个点）时线画不出来，改显点。
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
                      color: theme.colorScheme.primary.withValues(alpha: 0.07),
                    ),
                  ),
                ],
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _TimeRoller(
            months: months,
            maxMonths: maxMonths,
            onChanged: (m) => setState(() => _months = m),
          ),
        ],
      ),
    );
  }
}

/// 时间转轴：凹槽滑轨 + 旋转滚筒。拖动全程 1:1 直达（无补间延迟），
/// 点按轨道跳转时有 160ms 缓动；「减少动画」时跳转也直达。
class _TimeRoller extends StatefulWidget {
  const _TimeRoller({
    required this.months,
    required this.maxMonths,
    required this.onChanged,
  });

  final int months;
  final int maxMonths;
  final ValueChanged<int> onChanged;

  @override
  State<_TimeRoller> createState() => _TimeRollerState();
}

class _TimeRollerState extends State<_TimeRoller> {
  static const knobSize = 22.0;
  bool _dragging = false;
  bool _hover = false;
  bool _reduce = false;
  double _width = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
  }

  /// [x] 为期望的滚筒中心横坐标（跟手）：映射到 1..maxMonths。
  void _updateFromX(double x) {
    final usable = _width - knobSize;
    if (usable <= 0) return;
    final f = ((x - knobSize / 2) / usable).clamp(0.0, 1.0);
    final m = 1 + (f * (widget.maxMonths - 1)).round();
    if (m != widget.months) widget.onChanged(m);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final active = _dragging || _hover;
    final knobX =
        (widget.months - 1) / (widget.maxMonths - 1) * (_width - knobSize);
    final tweenDuration = (_dragging || _reduce)
        ? Duration.zero
        : const Duration(milliseconds: 160);
    return SizedBox(
      key: const Key('trend-roller'),
      height: 36,
      child: Tooltip(
        message: t.dashRollerHint(widget.maxMonths),
        child: MouseRegion(
          // 保持系统默认箭头（用户要求）：拖动亲和力由滚筒自身的
          // hover 提亮与握纹旋转提示，不改光标样式。
          cursor: SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) => setState(() => _dragging = true),
            onHorizontalDragUpdate: (d) => _updateFromX(d.localPosition.dx),
            onHorizontalDragEnd: (_) => setState(() => _dragging = false),
            onHorizontalDragCancel: () => setState(() => _dragging = false),
            onTapDown: (t) => _updateFromX(t.localPosition.dx),
            child: LayoutBuilder(
              builder: (context, constraints) {
                _width = constraints.maxWidth;
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    // 滑轨：凹槽 + 月刻度 + 已选区段染色。
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RollerTrackPainter(
                          dark: dark,
                          primary: theme.colorScheme.primary,
                          hint: theme.hintColor,
                          months: widget.months,
                          maxMonths: widget.maxMonths,
                          active: active,
                        ),
                      ),
                    ),
                    // 滚筒旋钮：握纹随取值旋转（转轴手感）。
                    AnimatedPositioned(
                      duration: tweenDuration,
                      curve: Curves.easeOut,
                      left: knobX,
                      width: knobSize,
                      height: knobSize,
                      top: (36 - knobSize) / 2 + 1,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: dark
                                ? const [Color(0xFFA5C0DD), Color(0xFF5E86BC)]
                                : const [Color(0xFF3A6392), Color(0xFF1C3A5C)],
                          ),
                          border: Border.all(
                            color: dark
                                ? const Color(0x66E7ECF2)
                                : const Color(0x40FFFFFF),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: active ? 0.55 : 0.25,
                              ),
                              blurRadius: active ? 14 : 6,
                              spreadRadius: active ? 1 : 0,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.30),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AnimatedRotation(
                          turns: (widget.months - 1) / widget.maxMonths * 1.5,
                          duration: tweenDuration,
                          curve: Curves.easeOut,
                          child: const CustomPaint(
                            painter: _DrumNotchesPainter(),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 滑轨绘制：凹槽、月份刻度（每 12 月加长）、1/12/24/36 标记、
/// 旋钮左侧的已选区段。
class _RollerTrackPainter extends CustomPainter {
  const _RollerTrackPainter({
    required this.dark,
    required this.primary,
    required this.hint,
    required this.months,
    required this.maxMonths,
    required this.active,
  });

  final bool dark;
  final Color primary;
  final Color hint;
  final int months;
  final int maxMonths;
  final bool active;

  static const grooveTop = 15.0;
  static const grooveH = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final groove = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, grooveTop, w, grooveH),
      const Radius.circular(2.5),
    );
    // 凹槽底 + 内高光（机械导轨感）。
    canvas.drawRRect(
      groove,
      Paint()..color = dark ? const Color(0xFF0A0F16) : const Color(0xFFDDE4EC),
    );
    canvas.drawRRect(
      groove,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = dark ? const Color(0x2EE7ECF2) : const Color(0x331E2A38),
    );
    // 已选区段：旋钮左侧染色。
    final selW =
        (months - 1) / (maxMonths - 1) * (w - _TimeRollerState.knobSize) +
        _TimeRollerState.knobSize / 2;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, selW, size.height));
    canvas.drawRRect(
      groove,
      Paint()..color = primary.withValues(alpha: active ? 0.65 : 0.45),
    );
    canvas.restore();
    // 月份刻度：每月一粒，每 12 月加长。
    for (var m = 1; m <= maxMonths; m++) {
      final x =
          (m - 1) / (maxMonths - 1) * (w - _TimeRollerState.knobSize) +
          _TimeRollerState.knobSize / 2;
      final major = m % 12 == 0 || m == 1;
      canvas.drawLine(
        Offset(x, grooveTop + grooveH + 2),
        Offset(x, grooveTop + grooveH + 2 + (major ? 6 : 3)),
        Paint()
          ..strokeWidth = 1
          ..color = (major ? hint : hint).withValues(alpha: major ? 0.7 : 0.3),
      );
      if (major && (m == 1 || m == 12 || m == 24 || m == maxMonths)) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$m${rt('月')}',
            style: TextStyle(fontSize: 9, color: hint.withValues(alpha: 0.8)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(
            (x - tp.width / 2).clamp(0.0, w - tp.width),
            grooveTop + grooveH + 11,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RollerTrackPainter old) =>
      old.months != months ||
      old.maxMonths != maxMonths ||
      old.active != active ||
      old.dark != dark;
}

/// 滚筒握纹：三条径向刻痕（120° 分布），随取值旋转出「转轴」手感。
class _DrumNotchesPainter extends CustomPainter {
  const _DrumNotchesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final paint = Paint()
      ..color = const Color(0xCC0B1524)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final a = i * 2 * math.pi / 3;
      canvas.drawLine(
        c + Offset(math.cos(a) * r * 0.38, math.sin(a) * r * 0.38),
        c + Offset(math.cos(a) * r * 0.72, math.sin(a) * r * 0.72),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DrumNotchesPainter old) => false;
}

class UpcomingCard extends StatelessWidget {
  const UpcomingCard({super.key, required this.d});

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final base = d.nw.baseCurrencyCode;
    return SectionCard(
      title: t.dashUpcomingTitle,
      child: d.upcoming.isEmpty
          ? Text(
              t.dashNoUpcoming,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            )
          : Column(
              children: [
                for (final o in d.upcoming.take(8))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: SizedBox(
                      width: 44,
                      child: Text(
                        dateKey(o.date).substring(5),
                        style: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    title: Text(o.eventName),
                    trailing: Text(
                      fmtMinor(o.amountMinor.abs(), base),
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

/// 资产负债表卡（首页右列首卡）：资产/负债合计 + 账户数 + 估值状态，
/// 整卡点开资产页（容器展开转场）。
class AssetsSheetCard extends StatelessWidget {
  const AssetsSheetCard({super.key, required this.d});

  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final base = d.nw.baseCurrencyCode;
    final accounts = d.nw.items.length;
    final missing = d.nw.missingValuations, stale = d.nw.staleValuations;
    return SectionCard(
      title: t.dashBalanceSheet,
      child: Column(
        children: [
          StatRow(
            label: t.dashAssetsTotal,
            value: fmtMinor(d.nw.totalAssets, base),
            emphasized: true,
          ),
          StatRow(
            label: t.dashLiabilitiesTotal,
            value: fmtMinor(d.nw.totalLiabilities, base),
            valueColor: d.nw.totalLiabilities > BigInt.zero
                ? AppColors.negativeOf(theme.brightness)
                : null,
          ),
          StatRow(label: t.dashIncludedAccounts, value: t.dashAccountCount(accounts)),
          if (missing > 0 || stale > 0)
            StatRow(
              label: t.dashValuationStatus,
              value: [
                if (missing > 0) t.dashMissingCount(missing),
                if (stale > 0) t.dashStaleCount(stale),
              ].join(' · '),
              valueColor: AppColors.warnOf(theme.brightness),
            ),
        ],
      ),
    );
  }
}
