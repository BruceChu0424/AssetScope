import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 沉浸式图表引擎 · 其二：瀑布图 / 矩形树图 / 月历热力 / 资产负债天平。

// ─────────────────────────────────────────────────────────────────────────
// 瀑布图（净资产归因）
// ─────────────────────────────────────────────────────────────────────────

class OvWaterfallStep {
  const OvWaterfallStep({
    required this.label,
    required this.delta,
    required this.color,
    this.isTotal = false,
    this.hint,
  });

  final String label;

  /// 本步增量（含合计步的绝对水平）。
  final BigInt delta;

  /// 只有非合计步着色（正钢蓝/负朱砂/其他香槟，页面决定）。
  final Color color;
  final bool isTotal;
  final String? hint;
}

/// 归因瀑布：期初 → 各因子增减 → 期末。柱体自基线逐根生长（每根
/// 220ms easeOutCubic，依次错落），虚线连结前后柱位。
class OvWaterfallChart extends StatefulWidget {
  const OvWaterfallChart({
    super.key,
    required this.steps,
    this.valueFormatter,
    this.onStepTap,
  });

  /// steps[0] 与最后一步应为 isTotal（期初/期末水平柱）。
  final List<OvWaterfallStep> steps;
  final String Function(BigInt v)? valueFormatter;
  final void Function(int i)? onStepTap;

  @override
  State<OvWaterfallChart> createState() => _OvWaterfallChartState();
}

class _OvWaterfallChartState extends State<OvWaterfallChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: 260 + 220 * widget.steps.length,
    ),
  );

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
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _WaterfallPainter(
          steps: widget.steps,
          progress: _c.value,
          textStyle: DefaultTextStyle.of(context).style,
          valueFormatter: widget.valueFormatter,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: widget.onStepTap == null
              ? null
              : (d) {
                  final n = widget.steps.length;
                  if (n == 0) return;
                  final w = 1 / n;
                  widget.onStepTap!((d.localPosition.dx / w).floor().clamp(0, n - 1));
                },
        ),
      ),
    );
  }
}

class _WaterfallPainter extends CustomPainter {
  const _WaterfallPainter({
    required this.steps,
    required this.progress,
    required this.textStyle,
    this.valueFormatter,
  });

  final List<OvWaterfallStep> steps;
  final double progress;
  final TextStyle textStyle;
  final String Function(BigInt v)? valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    if (steps.isEmpty || size.isEmpty) return;
    final n = steps.length;
    var level = steps[0].delta.toDouble();
    var min = level, max = level;
    final levels = <double>[level];
    for (var i = 1; i < n; i++) {
      level = steps[i].isTotal
          ? steps[i].delta.toDouble()
          : level + steps[i].delta.toDouble();
      levels.add(level);
      min = math.min(min, level);
      max = math.max(max, level);
    }
    if (max - min < 1) {
      max = min + 1;
    }
    final pad = (max - min) * 0.18 + 1;
    min -= pad;
    max += pad;
    final h = size.height - 34; // 底部标签区
    final w = size.width;
    final colW = w / n;
    final barW = colW * 0.52;
    double y(double v) => h - (v - min) / (max - min) * h;

    var prevCenter = 0.0;
    for (var i = 0; i < n; i++) {
      final s = steps[i];
      // 阶梯进度：每根柱在其时间窗（60%）内自基线生长。
      final local = ((progress * n - i * 0.72) / 0.6).clamp(0.0, 1.0);
      final grow = Curves.easeOutCubic.transform(local);
      final center = colW * i + colW / 2;
      Rect rect;
      if (s.isTotal) {
        final v = steps[0].delta.toDouble();
        final shown = v * grow + steps[0].delta.toDouble() * (1 - grow);
        final top = y(shown);
        rect = Rect.fromLTWH(center - barW / 2, top, barW, (h - top).clamp(0.0, h));
      } else {
        final v0 = levels[i - 1];
        final v1 = levels[i];
        final lo = math.min(v0, v1);
        final hi = math.max(v0, v1);
        final curLo = v0 + (lo - v0) * grow;
        final curHi = v0 + (hi - v0) * grow;
        rect = Rect.fromLTWH(
          center - barW / 2,
          y(curHi),
          barW,
          (y(curLo) - y(curHi)).clamp(0.0, h),
        );
      }
      if (rect.height > 0.5 && rect.width > 0) {
        final paint = Paint()
          ..color = s.isTotal
              ? const Color(0xCC1C3A5C)
              : s.color.withValues(alpha: 0.88);
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
        canvas.drawRRect(rrect, paint);
        if (s.isTotal) {
          canvas.drawRRect(
            rrect,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = const Color(0x66BFD9F2),
          );
        }
      }
      // 连结虚线：沿 carry 水平（levels[i]）从上一柱右缘接到本柱左缘。
      if (i > 0 && local > 0) {
        final linkY = y(levels[i - 1] + (levels[i] - levels[i - 1]) * grow);
        canvas.drawLine(
          Offset(prevCenter + barW / 2, linkY),
          Offset(center - barW / 2, linkY),
          Paint()
            ..strokeWidth = 1
            ..color = const Color(0x5E71859D),
        );
      }
      prevCenter = center;

      // 标签：名 + 值。
      final tp = TextPainter(
        text: TextSpan(
          text: s.label,
          style: textStyle.copyWith(fontSize: 10.5, color: const Color(0xFFA5B5C7)),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: colW - 4);
      tp.paint(
        canvas,
        Offset(center - tp.width / 2, h + 7),
      );
      if (grow > 0.6) {
        final val = valueFormatter?.call(s.delta) ?? s.delta.toString();
        final vp = TextPainter(
          text: TextSpan(
            text: s.isTotal ? val : (s.delta.toDouble() >= 0 ? '+' : '') + val,
            style: textStyle.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: s.isTotal ? const Color(0xFFE7F0FA) : s.color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        vp.paint(
          canvas,
          Offset(center - vp.width / 2, (rect.top - 16).clamp(2.0, h - 12)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WaterfallPainter old) =>
      old.steps != steps || old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────
// 矩形树图（资产结构）
// ─────────────────────────────────────────────────────────────────────────

class OvTreemapEntry {
  const OvTreemapEntry({
    required this.label,
    required this.value,
    required this.color,
    this.detail,
  });

  final String label;
  final BigInt value;
  final Color color;
  final String? detail;
}

/// 矩形树图：面积 = 金额占比。简约四刀平方分解（squarify 思想的
/// 贪心实现），矩形逐块 60ms 阶梯浮现（面积大者先出场），hover 提亮
/// + 外扩描边。文字只画装得下的块——小类不硬塞。
class OvTreemapChart extends StatefulWidget {
  const OvTreemapChart({super.key, required this.entries, this.onTap});

  final List<OvTreemapEntry> entries;
  final void Function(int i)? onTap;

  @override
  State<OvTreemapChart> createState() => _OvTreemapChartState();
}

class _OvTreemapChartState extends State<OvTreemapChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 240 + 60 * widget.entries.length),
  );
  int? _hover;

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
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final rects = _squarify(
            widget.entries,
            Offset.zero,
            Size(constraints.maxWidth, constraints.maxHeight),
          );
          return MouseRegion(
            onExit: (_) => setState(() => _hover = null),
            child: CustomPaint(
              size: Size.infinite,
              painter: _TreemapPainter(
                entries: widget.entries,
                rects: rects,
                progress: _c.value,
                hover: _hover,
                textStyle: DefaultTextStyle.of(context).style,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanDown: widget.onTap == null
                    ? null
                    : null,
                onTapUp: widget.onTap == null
                    ? null
                    : (d) {
                        for (var i = 0; i < rects.length; i++) {
                          if (rects[i].contains(d.localPosition)) {
                            widget.onTap!(i);
                            return;
                          }
                        }
                      },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 贪心 squarify：按值降序逐块切最短边。
List<Rect> _squarify(List<OvTreemapEntry> entries, Offset at, Size area) {
  final out = <Rect>[];
  if (entries.isEmpty || area.isEmpty || area.width <= 0 || area.height <= 0) {
    return out;
  }
  var total = 0.0;
  for (final e in entries) {
    total += e.value.toDouble();
  }
  if (total <= 0) return out;
  final sorted = [...entries]..sort((a, b) => b.value.compareTo(a.value));
  var remaining = Rect.fromLTWH(at.dx, at.dy, area.width, area.height);
  for (final e in sorted) {
    final frac = e.value.toDouble() / total;
    final isWide = remaining.width >= remaining.height;
    final full = isWide ? remaining.width : remaining.height;
    final len = remaining.isEmpty ? 0.0 : (full * frac).clamp(0.0, full);
    late Rect r;
    if (isWide) {
      r = Rect.fromLTWH(remaining.left, remaining.top, len, remaining.height);
      remaining = Rect.fromLTWH(
        remaining.left + len,
        remaining.top,
        math.max(0, remaining.width - len),
        remaining.height,
      );
    } else {
      r = Rect.fromLTWH(remaining.left, remaining.top, remaining.width, len);
      remaining = Rect.fromLTWH(
        remaining.left,
        remaining.top + len,
        remaining.width,
        math.max(0, remaining.height - len),
      );
    }
    out.add(r);
    total -= e.value.toDouble(); // 防浮点漂移：逐块从总量扣减
  }
  return out;
}

class _TreemapPainter extends CustomPainter {
  const _TreemapPainter({
    required this.entries,
    required this.rects,
    required this.progress,
    required this.hover,
    required this.textStyle,
  });

  final List<OvTreemapEntry> entries;
  final List<Rect> rects;
  final double progress;
  final int? hover;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    // rects 与 entries 顺序一一对应（_squarify 保持输入序）。
    for (var i = 0; i < rects.length && i < entries.length; i++) {
      final r = rects[i];
      if (r.isEmpty) continue;
      final local = ((progress * 1.2 - i * 0.09) / 0.5).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final ease = Curves.easeOutCubic.transform(local);
      final hovered = hover == i;
      final dimmed = hover != null && !hovered;
      final rr = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: r.center,
          width: r.width * (0.7 + 0.3 * ease),
          height: r.height * (0.7 + 0.3 * ease),
        ),
        const Radius.circular(6),
      );
      final paint = Paint()
        ..color = entries[i]
              .color
              .withValues(alpha: (dimmed ? 0.30 : hovered ? 0.55 : 0.42) * ease);
      canvas.drawRRect(rr, paint);
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = hovered ? 1.6 : 1
          ..color = (hovered
              ? entries[i].color.withValues(alpha: 0.9)
              : const Color(0x33E7ECF2)),
      );
      final fs = 11.0;
      if (r.width > 64 && r.height > 34 && ease > 0.55) {
        final tp = TextPainter(
          text: TextSpan(
            text: entries[i].label,
            style: textStyle.copyWith(
              fontSize: fs,
              fontWeight: FontWeight.w600,
              color: Color.lerp(
                const Color(0xFF71859D),
                const Color(0xFFF0F5FB),
                dimmed ? 0 : 1,
              ),
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: r.width - 12);
        tp.paint(canvas, Offset(r.left + 7, r.top + 6));
        if (r.height > 52 && entries[i].detail != null && r.width > 92) {
          final dp = TextPainter(
            text: TextSpan(
              text: entries[i].detail,
              style: textStyle.copyWith(
                fontSize: 10,
                color: const Color(0xFFA5B5C7),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: '…',
          )..layout(maxWidth: r.width - 12);
          dp.paint(canvas, Offset(r.left + 7, r.top + 6 + fs + 4));
        }
      }
    }
  }

  @override
  bool shouldRepaint(_TreemapPainter old) =>
      old.progress != progress ||
      old.hover != hover ||
      old.rects != rects ||
      old.entries != entries;
}

// ─────────────────────────────────────────────────────────────────────────
// 月历热力（收支强度）
// ─────────────────────────────────────────────────────────────────────────

class OvHeatCell {
  const OvHeatCell({
    required this.date,
    required this.intensity01,
    required this.tooltip,
    this.income = false,
    this.marks = const {},
  });

  final DateTime date;

  /// 0..1 强度（当日支出强度）。
  final double intensity01;
  final String tooltip;

  /// 当日净流入（蓝色调）还是净流出（红色调）。
  final bool income;

  /// 标记：类别→颜色（同日多事件小圆点，最多 3）。
  final Map<String, Color> marks;
}

/// 月历热力：周一行首的月历网格。单元底色按收支强度着色（净流入钢
/// 蓝 / 净流出朱砂），今日钢蓝描边，格子逐日 18ms 阶梯浮现；点击某天
/// 回调（联动筛选交易）。
class OvMonthHeatmap extends StatefulWidget {
  const OvMonthHeatmap({
    super.key,
    required this.year,
    required this.month,
    required this.cells,
    this.onDayTap,
    this.cellSize = 34,
  });

  final int year;
  final int month;
  final List<OvHeatCell> cells;
  final void Function(DateTime day)? onDayTap;
  final double cellSize;

  @override
  State<OvMonthHeatmap> createState() => _OvMonthHeatmapState();
}

class _OvMonthHeatmapState extends State<OvMonthHeatmap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );
  int? _hover;

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
    final theme = Theme.of(context);
    final first = DateTime(widget.year, widget.month);
    final daysInMonth = DateTime(widget.year, widget.month + 1, 0).day;
    // 周一为首：offset = (weekday-1)。
    final offset = first.weekday - 1;
    final byDay = {for (final c in widget.cells) c.date.day: c};
    final today = DateTime.now();
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var w = 0; w < 7; w++)
                SizedBox(
                  width: widget.cellSize + 6,
                  child: Text(
                    weekdays[w],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: const Color(0xFF71859D),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var row = 0; row * 7 < offset + daysInMonth; row++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  _cell(offset, daysInMonth, byDay, today, row, col),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(
    int offset,
    int daysInMonth,
    Map<int, OvHeatCell> byDay,
    DateTime today,
    int row,
    int col,
  ) {
    final day = row * 7 + col - offset + 1;
    final isDay = day >= 1 && day <= daysInMonth;
    final cell = byDay[day];
    final theme = Theme.of(context);
    final isToday =
        isDay &&
        today.year == widget.year &&
        today.month == widget.month &&
        today.day == day;
    final idx = row * 7 + col;
    final local = ((_c.value * 1.25 - idx * 0.028) / 0.4).clamp(0.0, 1.0);
    final ease = Curves.easeOutCubic.transform(local);
    final base = cell == null
        ? Colors.white.withValues(alpha: 0.03)
        : (cell.income ? const Color(0xFF7EA6D9) : const Color(0xFFF0907C))
              .withValues(alpha: 0.08 + 0.55 * cell.intensity01);
    final hovered = _hover == idx;
    final size = widget.cellSize;
    return SizedBox(
      width: size + 6,
      height: size + 6,
      child: isDay
          ? Opacity(
              opacity: ease,
              child: Transform.scale(
                scale: 0.8 + 0.2 * ease,
                child: Tooltip(
                  message: cell?.tooltip ?? '$day',
                  waitDuration: const Duration(milliseconds: 260),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hover = idx),
                    onExit: (_) => setState(() => _hover = null),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onDayTap?.call(
                        DateTime(widget.year, widget.month, day),
                      ),
                      child: Container(
                        width: size,
                        height: size,
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          color: hovered
                              ? Color.lerp(base, Colors.white, 0.10)
                              : base,
                          border: isToday
                              ? Border.all(
                                  color: const Color(0xFF7EA6D9),
                                  width: 1.4,
                                )
                              : (hovered
                                    ? Border.all(
                                        color: const Color(0x66E7ECF2),
                                      )
                                    : null),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '$day',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10.5,
                                color: cell != null && cell.intensity01 > 0.55
                                    ? const Color(0xFFF0F5FB)
                                    : const Color(0xFFA5B5C7),
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            if (cell != null && cell.marks.isNotEmpty)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (final c in cell.marks.values.take(3))
                                      Container(
                                        width: 4,
                                        height: 4,
                                        margin: const EdgeInsets.only(left: 2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: c,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 资产负债天平
// ─────────────────────────────────────────────────────────────────────────

/// 资产负债天平：横梁倾角随负债率落位（50% 水平；easeOutBack 带一丝
/// 科砣回摆后停稳——不持续晃动）。左盘钢蓝辉光（资产），右盘琥珀
/// （负债），支柱与底座发丝线勾线。底座中央留给 [center]（净资产）。
class OvBalanceScale extends StatefulWidget {
  const OvBalanceScale({
    super.key,
    required this.debtToAsset,
    required this.center,
    this.width = 300,
    this.height = 200,
  });

  /// 0..1（null/0 = 无负债，横梁水平）。
  final double debtToAsset;
  final Widget center;
  final double width;
  final double height;

  @override
  State<OvBalanceScale> createState() => _OvBalanceScaleState();
}

class _OvBalanceScaleState extends State<OvBalanceScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final CurvedAnimation _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutBack,
  );

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
  void didUpdateWidget(OvBalanceScale old) {
    super.didUpdateWidget(old);
    if (old.debtToAsset != widget.debtToAsset &&
        _c.isCompleted &&
        !MediaQuery.disableAnimationsOf(context)) {
      _c.forward(from: 0.4);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AnimatedBuilder(
            animation: _t,
            builder: (context, _) => CustomPaint(
              size: Size(widget.width, widget.height),
              painter: _ScalePainter(
                tilt: _tiltAt(widget.debtToAsset) * _t.value,
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.only(bottom: 6), child: widget.center),
        ],
      ),
    );
  }

  /// 目标倾角：负债率 50% 水平；每偏离 10pp 倾 1.2°，封顶 ±7°。
  /// 负债越重右盘（琥珀）越沉。
  static double _tiltAt(double dta) {
    const rad = math.pi / 180;
    return ((dta - 0.5) * 12).clamp(-7.0, 7.0) * rad;
  }
}

class _ScalePainter extends CustomPainter {
  const _ScalePainter({required this.tilt});

  final double tilt;

  static const _hair = Color(0x3DE7ECF2);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final pivot = Offset(cx, size.height * 0.34);
    final armHalf = size.width * 0.38;

    // 支柱与底座。
    final struct = Paint()
      ..strokeWidth = 2
      ..color = _hair
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      pivot,
      Offset(cx, size.height - 14),
      struct,
    );
    canvas.drawLine(
      Offset(cx - 26, size.height - 12),
      Offset(cx + 26, size.height - 12),
      struct..strokeWidth = 3,
    );
    // 顶饰铆钉。
    canvas.drawCircle(
      pivot,
      4,
      Paint()..color = const Color(0xFFBFD9F2).withValues(alpha: 0.8),
    );

    // 横梁 + 双盘。
    final armEnd = Offset(
      pivot.dx + math.cos(tilt) * armHalf,
      pivot.dy + math.sin(tilt) * armHalf,
    );
    final armEndL = Offset(
      pivot.dx - math.cos(tilt) * armHalf,
      pivot.dy - math.sin(tilt) * armHalf,
    );
    canvas.drawLine(
      armEndL,
      armEnd,
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0xFF7EA6D9), Color(0xFFD8BE85)],
        ).createShader(Rect.fromPoints(armEndL, armEnd)),
    );

    _pan(canvas, armEndL, const Color(0xFF7EA6D9), const Color(0xFFBFD9F2));
    _pan(canvas, armEnd, const Color(0xFFB3924F), const Color(0xFFE5C078));
  }

  void _pan(Canvas canvas, Offset anchor, Color deep, Color lite) {
    // 吊索。
    final hang = 26.0;
    final panC = anchor + Offset(0, hang);
    final line = Paint()
      ..strokeWidth = 1
      ..color = _hair;
    canvas.drawLine(anchor + Offset(-16, 0), panC, line);
    canvas.drawLine(anchor + Offset(16, 0), panC, line);
    // 盘体：浅碗弧。
    canvas.drawArc(
      Rect.fromCircle(center: panC, radius: 20),
      0,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = lite.withValues(alpha: 0.85),
    );
    canvas.drawArc(
      Rect.fromCircle(center: panC, radius: 20),
      0,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.fill
        ..color = deep.withValues(alpha: 0.18),
    );
    // 盘下柔光。
    canvas.drawCircle(
      panC + const Offset(0, 12),
      16,
      Paint()
        ..color = deep.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  @override
  bool shouldRepaint(_ScalePainter old) => old.tilt != tilt;
}
