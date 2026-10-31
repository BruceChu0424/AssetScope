import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'overview_anim.dart';

/// 沉浸式图表引擎 · 其一：环形图 / 雷达图 / 评分仪表盘。
///
/// 全部自绘（CustomPainter），共享动效语法：
/// - 数据驱动一次入场（扫掠/展开/回弹），此后换数据走平滑重扫；
/// - 「减少动画」直达终态；FLUTTER_TEST 下一次性入场仍可 settle
///   （只冻结常驻循环，不冻结一次性入场）。

// ─────────────────────────────────────────────────────────────────────────
// 环形图
// ─────────────────────────────────────────────────────────────────────────

class OvSlice {
  const OvSlice({
    required this.label,
    required this.value,
    required this.color,
    this.sublabel,
  });

  final String label;
  final BigInt value;
  final Color color;

  /// 右侧图例第二行（如占比或金额），由页面拼好传入。
  final String? sublabel;
}

/// 环形图：扇区按占比自然展开（900ms easeOutCubic 扫掠）；hover 扇区
/// 外扩 3px 且其余退隐；点击扇区回调。中心孔由 [center] 占位（总资产
/// 等大数）。布局自适应：取父约束的短边为直径。
class OvDonutChart extends StatefulWidget {
  const OvDonutChart({
    super.key,
    required this.slices,
    this.center,
    this.onSliceTap,
    this.stroke = 26,
    this.gapDeg = 2.4,
    this.externalHover,
  });

  final List<OvSlice> slices;
  final Widget? center;
  final void Function(int index)? onSliceTap;

  /// 环带厚度。
  final double stroke;

  /// 扇区间隔（度）；单扇区时间隔消失。
  final double gapDeg;

  /// 外部联动 hover（图例行悬停时点亮扇区）；内部直指 hover 优先。
  final int? externalHover;

  @override
  State<OvDonutChart> createState() => _OvDonutChartState();
}

class _OvDonutChartState extends State<OvDonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final CurvedAnimation _t = CurvedAnimation(
    parent: _sweep,
    curve: Curves.easeOutCubic,
  );
  int? _hover;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _sweep.value = 1;
      } else {
        _sweep.forward();
      }
    });
  }

  @override
  void didUpdateWidget(OvDonutChart old) {
    super.didUpdateWidget(old);
    // 换数据：从当前进度平滑重扫（保留已展开的直觉）。
    if (old.slices.length != widget.slices.length) _hover = null;
    if (_sweep.isCompleted && !_sweep.isAnimating) {
      if (!MediaQuery.disableAnimationsOf(context)) _sweep.forward(from: 0.55);
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    _t.dispose();
    super.dispose();
  }

  double get _total => widget.slices
      .fold(0.0, (s, x) => s + x.value.toDouble());

  int? _sliceAt(Offset p, Size size) {
    final c = size.center(Offset.zero);
    final d = (p - c).distance;
    final r = size.shortestSide / 2;
    if (d < r - widget.stroke - 6 || d > r + 6) return null;
    var ang = (math.atan2(p.dy - c.dy, p.dx - c.dx) * 180 / math.pi + 450) %
        360; // 0° = 正上
    var acc = 0.0;
    final total = _total;
    final gap = widget.slices.length > 1 ? widget.gapDeg : 0.0;
    final span = 360 - gap * widget.slices.length;
    for (var i = 0; i < widget.slices.length; i++) {
      final w = total <= 0
          ? 360 / widget.slices.length
          : widget.slices[i].value.toDouble() / total * span;
      if (ang >= acc && ang < acc + w + gap) return i;
      acc += w + gap;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        return MouseRegion(
          cursor: widget.onSliceTap != null
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          onHover: (e) => setState(() => _hover = _sliceAt(e.localPosition, size)),
          onExit: (_) => setState(() => _hover = null),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: widget.onSliceTap == null
                ? null
                : (d) {
                    final i = _sliceAt(d.localPosition, size);
                    if (i != null) widget.onSliceTap!(i);
                  },
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _t,
                  builder: (context, _) => CustomPaint(
                    size: size,
                    painter: _DonutPainter(
                      slices: widget.slices,
                      progress: kOvTestEnv && _t.value == 0 ? 1 : _t.value,
                      hover: _hover ?? widget.externalHover,
                      stroke: widget.stroke,
                      gapDeg: widget.gapDeg,
                    ),
                  ),
                ),
                if (widget.center != null)
                  Padding(padding: EdgeInsets.all(widget.stroke + 10), child: widget.center),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.slices,
    required this.progress,
    required this.hover,
    required this.stroke,
    required this.gapDeg,
  });

  final List<OvSlice> slices;
  final double progress;
  final int? hover;
  final double stroke;
  final double gapDeg;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || slices.isEmpty) return;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - stroke / 2 - 2;
    var total = 0.0;
    for (final s in slices) {
      total += s.value.toDouble();
    }
    final gap = slices.length > 1 ? gapDeg : 0.0;
    final span = (360 - gap * slices.length) * progress;
    var start = -90.0;
    for (var i = 0; i < slices.length; i++) {
      final w = total <= 0
          ? span / slices.length
          : slices[i].value.toDouble() / total * span;
      if (w <= 0.05) {
        start += w + gap * progress;
        continue;
      }
      final hovered = hover == i;
      final dimmed = hover != null && !hovered;
      final radius = r + (hovered ? 3 : 0);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = slices.length == 1 ? StrokeCap.round : StrokeCap.butt
        ..color = slices[i]
              .color
              .withValues(alpha: dimmed ? 0.28 : (hovered ? 1 : 0.92));
      final rect = Rect.fromCircle(center: c, radius: radius);
      // 微隙：起止各让 gap/2，末扇区不留尾隙。
      final lead = slices.length > 1 ? gap / 2 : 0;
      final tail = (slices.length > 1 && i < slices.length - 1) ? gap / 2 : 0;
      canvas.drawArc(
        rect,
        (start + lead) * math.pi / 180,
        (w - lead - tail).clamp(0.0, w) * math.pi / 180,
        false,
        paint,
      );
      start += w + gap * progress;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.slices != slices ||
      old.progress != progress ||
      old.hover != hover ||
      old.stroke != stroke;
}

/// 环形图图例：色点 + 名称 + 数值/占比两行，hover 行与扇区联动。
class OvDonutLegend extends StatelessWidget {
  const OvDonutLegend({
    super.key,
    required this.slices,
    required this.total,
    this.currency,
    this.hover,
    this.onHover,
    this.onTap,
    this.valueFormatter,
  });

  final List<OvSlice> slices;
  final BigInt total;
  final String? currency;

  /// 联动索引（与 OvDonutChart 共享）。
  final int? hover;
  final ValueChanged<int?>? onHover;
  final void Function(int index)? onTap;

  /// 值格式化（默认原样 BigInt.toString()；页面一般传 fmtMinor 包装）。
  final String Function(BigInt value, String? currency)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < slices.length; i++) ...[
          if (i > 0) const SizedBox(height: 2),
          MouseRegion(
            cursor: onTap != null
                ? SystemMouseCursors.click
                : MouseCursor.defer,
            onEnter: (_) => onHover?.call(i),
            onExit: (_) => onHover?.call(null),
            child: GestureDetector(
              onTap: onTap == null ? null : () => onTap!(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: hover == i
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: slices[i].color.withValues(
                          alpha: hover == null || hover == i ? 1 : 0.35,
                        ),
                        boxShadow: hover == i
                            ? [
                                BoxShadow(
                                  color: slices[i]
                                      .color
                                      .withValues(alpha: 0.55),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        slices[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: hover == null || hover == i
                              ? const Color(0xFFE7F0FA)
                              : const Color(0xFF71859D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          slices[i].sublabel ??
                              (valueFormatter?.call(
                                    slices[i].value,
                                    currency,
                                  ) ??
                                  '${(total > BigInt.zero ? slices[i].value.toDouble() / total.toDouble() * 100 : 0).toStringAsFixed(1)}%'),
                          maxLines: 1,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFA5B5C7),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 雷达图
// ─────────────────────────────────────────────────────────────────────────

class OvRadarDim {
  const OvRadarDim({required this.label, required this.value, this.target});

  /// 维度名。
  final String label;

  /// 0..1 当前值（>1 按 1 封顶绘制）。
  final double value;

  /// 0..1 参考目标（琥珀虚线多边形）；null 不画该维目标点。
  final double? target;
}

/// 六维雷达：当前值钢蓝实面 + 目标琥珀虚线，网格低亮度蓝灰。入场时
/// 值多边形自中心展开（620ms easeOutCubic）。
class OvRadarChart extends StatefulWidget {
  const OvRadarChart({super.key, required this.dims, this.labels = true});

  final List<OvRadarDim> dims;
  final bool labels;

  @override
  State<OvRadarChart> createState() => _OvRadarChartState();
}

class _OvRadarChartState extends State<OvRadarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final CurvedAnimation _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
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
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _RadarPainter(
          dims: widget.dims,
          progress: _t.value,
          labels: widget.labels,
          textTheme: DefaultTextStyle.of(context).style,
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({
    required this.dims,
    required this.progress,
    required this.labels,
    required this.textTheme,
  });

  final List<OvRadarDim> dims;
  final double progress;
  final bool labels;
  final TextStyle textTheme;

  static const _gridColor = Color(0x2E71859D);

  Offset _point(Offset c, double r, int i, int n, double v) {
    final a = -math.pi / 2 + 2 * math.pi * i / n;
    return c + Offset(math.cos(a), math.sin(a)) * r * v.clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (dims.length < 3 || size.isEmpty) return;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - (labels ? 26 : 8);
    final n = dims.length;

    // 网格：四环 + 轴线。
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _gridColor;
    for (var ring = 1; ring <= 4; ring++) {
      final path = Path();
      for (var i = 0; i <= n; i++) {
        final p = _point(c, r, i % n, n, ring / 4);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, grid);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(c, _point(c, r, i, n, 1), grid);
    }

    // 目标多边形：琥珀虚线。
    if (dims.any((d) => d.target != null)) {
      final path = Path();
      var started = false;
      for (var i = 0; i <= n; i++) {
        final t = dims[i % n].target;
        if (t == null) {
          started = false;
          continue;
        }
        final p = _point(c, r, i % n, n, t);
        started ? path.lineTo(p.dx, p.dy) : path.moveTo(p.dx, p.dy);
        started = true;
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0xFFD8BE85).withValues(alpha: 0.75),
      );
    }

    // 值多边形：钢蓝实面 + 描边 + 顶点。
    final path = Path();
    for (var i = 0; i <= n; i++) {
      final p = _point(c, r, i % n, n, dims[i % n].value * progress);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF7EA6D9).withValues(alpha: 0.18),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF8FBCE8),
    );
    final dot = Paint()..color = const Color(0xFFBFD9F2);
    for (var i = 0; i < n; i++) {
      final p = _point(c, r, i, n, dims[i].value * progress);
      canvas.drawCircle(p, 2.6, dot);
    }

    // 维度标签。
    if (labels) {
      for (var i = 0; i < n; i++) {
        final p = _point(c, r + 14, i, n, 1);
        final tp = TextPainter(
          text: TextSpan(text: dims[i].label, style: textTheme.copyWith(fontSize: 11, color: const Color(0xFFA5B5C7))),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, p.translate(-tp.width / 2, -tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.dims != dims || old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────
// 评分仪表盘
// ─────────────────────────────────────────────────────────────────────────

/// 环形评分仪表：270° 弧，蓝→香槟渐变扫掠（easeOutBack 轻回弹落位），
/// 弧端呼吸辉光点，圆心分数大数 + 状态语。分数变化重扫。
class OvScoreGauge extends StatefulWidget {
  const OvScoreGauge({
    super.key,
    required this.score,
    required this.center,
    this.size = 220,
  });

  /// 0..1。
  final double score;
  final Widget center;
  final double size;

  @override
  State<OvScoreGauge> createState() => _OvScoreGaugeState();
}

class _OvScoreGaugeState extends State<OvScoreGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
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
  void didUpdateWidget(OvScoreGauge old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score &&
        _c.isCompleted &&
        !MediaQuery.disableAnimationsOf(context)) {
      _c.forward(from: 0.35);
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
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _t,
            builder: (context, _) => CustomPaint(
              size: Size.square(widget.size),
              painter: _GaugePainter(
                score: widget.score,
                // easeOutBack 会瞬时 >1：分数弧随之轻微越位再回弹落位
                // （刻意保留），但整体封顶不超过满弧。
                progress: _t.value.clamp(0.0, 1.06),
                clock: kOvTestEnv
                    ? 0.5
                    : (_c.lastElapsedDuration?.inMilliseconds ?? 0) / 3200,
              ),
            ),
          ),
          widget.center,
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.score,
    required this.progress,
    required this.clock,
  });

  final double score;
  final double progress;
  final double clock;

  static const _startDeg = 135.0;
  static const _sweepDeg = 270.0;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 12;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x26E7ECF2);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      _startDeg * math.pi / 180,
      _sweepDeg * math.pi / 180,
      false,
      track,
    );

    // 刻度：每 10% 一粒微点。
    final tick = Paint()..color = const Color(0x3DA5B5C7);
    for (var i = 0; i <= 10; i++) {
      final a = (_startDeg + _sweepDeg * i / 10) * math.pi / 180;
      final p = c + Offset(math.cos(a), math.sin(a)) * (r + 12);
      canvas.drawCircle(p, i % 5 == 0 ? 1.6 : 1.0, tick);
    }

    final v = (score * progress).clamp(0.0, 1.0);
    if (v > 0.003) {
      final rect = Rect.fromCircle(center: c, radius: r);
      canvas.drawArc(
        rect,
        _startDeg * math.pi / 180,
        _sweepDeg * v * math.pi / 180,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..shader = const SweepGradient(
            startAngle: _startDeg * math.pi / 180,
            endAngle: (_startDeg + _sweepDeg) * math.pi / 180,
            colors: [Color(0xFF5E86BC), Color(0xFF7EA6D9), Color(0xFFD8BE85)],
            transform: GradientRotation(_startDeg * math.pi / 180),
          ).createShader(rect),
      );
      // 弧端辉光点：呼吸。
      final a = (_startDeg + _sweepDeg * v) * math.pi / 180;
      final tip = c + Offset(math.cos(a), math.sin(a)) * r;
      final breathe = 0.55 + 0.45 * math.sin(clock * 2 * math.pi);
      canvas.drawCircle(
        tip,
        5,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2),
      );
      canvas.drawCircle(
        tip,
        10 + 5 * breathe,
        Paint()
          ..color = const Color(0xFFBFD9F2).withValues(
            alpha: 0.16 + 0.22 * breathe,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.score != score || old.progress != progress || old.clock != clock;
}
