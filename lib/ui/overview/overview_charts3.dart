import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/runtime_l10n.dart';
import 'overview_providers.dart';

/// 自绘日现金流图：每日收入/消费并立双柱（自基线生长，逐日阶梯）+
/// 累计净现金流折线（随进度扫掠）。悬停出现竖向十字线与玻璃提示片。
/// 纵轴自动取整（1-2-5 美数刻度），浅网格三道。
class OvDailyFlowChart extends StatefulWidget {
  const OvDailyFlowChart({
    super.key,
    required this.daily,
    required this.format,
    required this.dayLabel,
    this.height = 260,
  });

  final List<OvDailyCell> daily;

  /// 金额格式化（含币种符号）。
  final String Function(BigInt minor) format;

  /// 提示片里的日期文案（如「10 月 8 日 周三」）。
  final String Function(DateTime day) dayLabel;

  final double height;

  @override
  State<OvDailyFlowChart> createState() => _OvDailyFlowChartState();
}

class _OvDailyFlowChartState extends State<OvDailyFlowChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  );
  int? _hoverDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return MouseRegion(
          cursor: SystemMouseCursors.basic,
          onHover: (e) => setState(
            () => _hoverDay = _dayAt(e.localPosition.dx),
          ),
          onExit: (_) => setState(() => _hoverDay = null),
          child: CustomPaint(
            size: Size(double.infinity, widget.height),
            painter: _DailyFlowPainter(
              daily: widget.daily,
              progress: _c.value,
              hover: _hoverDay,
              dark: dark,
            ),
            child: Builder(
              builder: (context) {
                if (_hoverDay == null ||
                    _hoverDay! >= widget.daily.length) {
                  return const SizedBox.expand();
                }
                final cell = widget.daily[_hoverDay!];
                return Align(
                  alignment: Alignment(_hoverX!, -0.55),
                  child: _FlowTooltip(
                    title: widget.dayLabel(cell.date),
                    income: widget.format(cell.income),
                    expense: widget.format(cell.expense),
                    net: widget.format(cell.net),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  double? _hoverX;
  static const _padL = 8.0;
  static const _padR = 8.0;

  int? _dayAt(double dx) {
    final w = context.size?.width;
    if (w == null || widget.daily.isEmpty) return null;
    final inner = w - _padL - _padR;
    final f = ((dx - _padL) / inner).clamp(0.0, 0.9999);
    _hoverX = (f * 2 - 1).clamp(-1.0, 1.0);
    return (f * widget.daily.length).floor();
  }
}

class _FlowTooltip extends StatelessWidget {
  const _FlowTooltip({
    required this.title,
    required this.income,
    required this.expense,
    required this.net,
  });

  final String title;
  final String income;
  final String expense;
  final String net;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodySmall?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ) ??
        const TextStyle();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xF0101929),
        border: Border.all(color: const Color(0x4DE7ECF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: mono.copyWith(
              color: const Color(0xFFA5B5C7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          _r('↑', income, const Color(0xFF8FBCE8), mono),
          _r('↓', expense, const Color(0xFFF0907C), mono),
          _r('Σ', net, const Color(0xFFBFD9F2), mono),
        ],
      ),
    );
  }

  Widget _r(String sym, String v, Color c, TextStyle base) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            child: Text(sym, style: base.copyWith(color: c, fontSize: 11)),
          ),
          Text(v, style: base.copyWith(color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DailyFlowPainter extends CustomPainter {
  const _DailyFlowPainter({
    required this.daily,
    required this.progress,
    required this.hover,
    required this.dark,
  });

  final List<OvDailyCell> daily;
  final double progress;
  final int? hover;
  final bool dark;

  static const _padT = 14.0;
  static const _padB = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (daily.isEmpty || size.width < 40) return;
    final w = size.width - 16;
    final h = size.height - _padT - _padB;
    final base = _padT + h;
    var peak = 1.0;
    for (final c in daily) {
      peak = math.max(
        peak,
        math.max(c.income.toDouble(), c.expense.toDouble()),
      );
    }
    double y(double v) => base - v / peak * h;

    // 网格：三道横线 + 数值（1-2-5 美数）。
    final nicePeak = _nice(peak);
    final grid = Paint()
      ..strokeWidth = 1
      ..color = const Color(0x1EE7ECF2);
    final tp = TextPainter(
      text: const TextSpan(
        text: '',
        style: TextStyle(fontSize: 10, color: Color(0xFF71859D)),
      ),
      textDirection: TextDirection.ltr,
    );
    for (var g = 1; g <= 3; g++) {
      final gy = _padT + h - h * g / 3;
      canvas.drawLine(Offset(8, gy), Offset(8 + w, gy), grid);
      tp.text = TextSpan(
        text: _short(nicePeak * g / 3),
        style: const TextStyle(fontSize: 9.5, color: Color(0xFF71859D)),
      );
      tp.layout();
      tp.paint(canvas, Offset(10, gy - 12));
    }

    // 双柱。
    final n = daily.length;
    final slot = w / n;
    final barW = math.max(1.5, slot * 0.26);
    final incomeC = dark ? const Color(0xFF8FBCE8) : const Color(0xFF2B6CB0);
    final expenseC = dark ? const Color(0xFFF0907C) : const Color(0xFFC13A2B);
    for (var i = 0; i < n; i++) {
      final local = ((progress * 1.35 - i / n * 0.5) / 0.85).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final grow = Curves.easeOutCubic.transform(local);
      final cx = 8 + slot * i + slot / 2;
      final hovered = hover == i;
      var inc = daily[i].income.toDouble() * grow;
      var exp = daily[i].expense.toDouble() * grow;
      if (inc > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(
              cx - barW - 1,
              y(inc),
              barW,
              (base - y(inc)).clamp(0.0, h),
            ),
            topLeft: const Radius.circular(2),
            topRight: const Radius.circular(2),
          ),
          Paint()
            ..color = incomeC.withValues(
              alpha: hovered ? 1 : (dark ? 0.85 : 0.9),
            ),
        );
      }
      if (exp > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(
              cx + 1,
              y(exp),
              barW,
              (base - y(exp)).clamp(0.0, h),
            ),
            topLeft: const Radius.circular(2),
            topRight: const Radius.circular(2),
          ),
          Paint()
            ..color = expenseC.withValues(
              alpha: hovered ? 1 : (dark ? 0.85 : 0.9),
            ),
        );
      }
    }

    // 累计净额线（随进度扫掠；数值域取整）。
    var cum = BigInt.zero;
    final pts = <Offset>[];
    var minCum = 0.0, maxCum = 0.0;
    final cums = <double>[];
    for (final c in daily) {
      cum += c.net;
      cums.add(cum.toDouble());
      minCum = math.min(minCum, cum.toDouble());
      maxCum = math.max(maxCum, cum.toDouble());
    }
    final span = math.max(1.0, maxCum - minCum);
    for (var i = 0; i < n; i++) {
      final cx = 8 + slot * i + slot / 2;
      final ly = _padT + h - (cums[i] - minCum) / span * h * 0.92 - h * 0.04;
      pts.add(Offset(cx, ly));
    }
    final lineProgress = (progress * 1.2).clamp(0.0, 1.0);
    final shown = (pts.length * lineProgress).ceil();
    if (shown >= 2) {
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (var i = 1; i < shown; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFFBFD9F2).withValues(alpha: 0.95),
      );
      // 前缘辉点。
      final tip = pts[shown - 1];
      canvas.drawCircle(
        tip,
        3.2,
        Paint()..color = Colors.white.withValues(alpha: 0.95),
      );
      canvas.drawCircle(
        tip,
        8,
        Paint()
          ..color = const Color(0xFFBFD9F2).withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // 基线。
    canvas.drawLine(
      Offset(8, base),
      Offset(8 + w, base),
      Paint()
        ..strokeWidth = 1
        ..color = const Color(0x3DE7ECF2),
    );

    // 悬停十字线。
    if (hover != null && hover! < n) {
      final cx = 8 + slot * hover! + slot / 2;
      canvas.drawLine(
        Offset(cx, _padT - 6),
        Offset(cx, base),
        Paint()
          ..strokeWidth = 1
          ..color = const Color(0x66BFD9F2),
      );
    }

    // 今日刻度。
    final today = DateTime.now();
    for (var i = 0; i < n; i++) {
      if (daily[i].date.day == today.day &&
          daily[i].date.month == today.month &&
          daily[i].date.year == today.year) {
        final cx = 8 + slot * i + slot / 2;
        final tp2 = TextPainter(
          text: TextSpan(
            text: rt('今天'),
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF8FBCE8)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp2.paint(canvas, Offset(cx - tp2.width / 2, base + 6));
      }
    }
  }

  /// 1-2-5 美数取整（刻度上界）。
  static double _nice(double v) {
    if (v <= 0) return 1;
    final exp = (math.log(v) / math.ln10).floor();
    final base = math.pow(10, exp).toDouble();
    for (final m in [1, 2, 5, 10]) {
      if (v <= m * base) return m * base;
    }
    return 10 * base;
  }

  static String _short(double v) {
    final en = RuntimeL10n.english;
    if (en) {
      if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
      if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
      if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}k';
      return v.round().toString();
    }
    if (v >= 1e8) return '${(v / 1e8).toStringAsFixed(1)}亿';
    if (v >= 1e4) return '${(v / 1e4).toStringAsFixed(0)}万';
    return v.round().toString();
  }

  @override
  bool shouldRepaint(_DailyFlowPainter old) =>
      old.daily != daily ||
      old.progress != progress ||
      old.hover != hover ||
      old.dark != dark;
}
