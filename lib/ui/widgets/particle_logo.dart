import 'dart:math' as math;
import 'dart:ui' as ui show Gradient;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'logo_points.dart';

/// 品牌图形标 · 粒子形态：A mark 以 300 颗钢蓝/雾白/香槟金粒子呈现。
///
/// 与 runBusy 粒子舞台同一视觉语言（同目标点表、同行波涟漪），但这是
/// 常驻内联版：入场自四周散点汇聚（~1.2s，easeInOutCubic），随后持续
/// 行波 + 闪烁 + 呼吸光晕。深浅色各用一套粒子配色（浅色=墨蓝系，深色=
/// 钢蓝系），光晕随主题主色。锁屏等品牌时刻替代静态 [BrandMark]；
/// 「减少动画」时直接呈现汇聚完成的静止帧。
class ParticleBrandMark extends StatefulWidget {
  const ParticleBrandMark({super.key, this.size = 168});

  /// 图形边长（正方形，含光晕余量请在外部留白）。
  final double size;

  @override
  State<ParticleBrandMark> createState() => _ParticleBrandMarkState();
}

class _ParticleBrandMarkState extends State<ParticleBrandMark>
    with SingleTickerProviderStateMixin {
  /// 一天时长的单调时钟：入场只播一次（clamp 保持），行波连续不循环。
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(days: 1),
  );
  late final List<_Spec> _specs = () {
    final rnd = math.Random(7);
    return [
      for (var i = 0; i < kLogoParticlePoints.length ~/ 2; i++) _Spec(rnd),
    ];
  }();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery 不能在 initState 读；「减少动画」定格在汇聚完成帧。
    if (!_t.isAnimating && _t.value == 0) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _t.value = 2 / 86400; // t ≈ 2s 静止帧
      } else {
        _t.forward();
      }
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(widget.size),
      painter: _ParticleMarkPainter(
        clock: _t,
        specs: _specs,
        dark: Theme.of(context).brightness == Brightness.dark,
        size: widget.size,
      ),
    );
  }
}

class _Spec {
  _Spec(math.Random rnd) {
    entryDelay = rnd.nextDouble() * 0.35;
    entryDur = 0.55 + rnd.nextDouble() * 0.3;
    scatterAngle = rnd.nextDouble() * math.pi * 2;
    scatterDist = 0.3 + rnd.nextDouble() * 0.5; // size 倍数
    wavePhase = rnd.nextDouble() * math.pi * 2;
    radius = 1.2 + rnd.nextDouble() * 1.0; // 随 size 缩放，见 painter
    colorSlot = rnd.nextDouble();
  }

  late final double entryDelay;
  late final double entryDur;
  late final double scatterAngle;
  late final double scatterDist;
  late final double wavePhase;
  late final double radius;
  late final double colorSlot;
}

class _ParticleMarkPainter extends CustomPainter {
  _ParticleMarkPainter({
    required this.clock,
    required this.specs,
    required this.dark,
    required this.size,
  }) : super(repaint: clock);

  final Animation<double> clock;
  final List<_Spec> specs;
  final bool dark;
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final t = clock.value * 86400;
    final center = canvasSize.center(Offset.zero);

    _paintHalo(canvas, center, t);
    for (var i = 0; i < specs.length; i++) {
      final target = Offset(
        center.dx + kLogoParticlePoints[i * 2] * size,
        center.dy + kLogoParticlePoints[i * 2 + 1] * size,
      );
      _paintParticle(canvas, center, target, specs[i], t);
    }
  }

  /// 呼吸光晕：径向渐变自带柔边（2s 余弦呼吸，与舞台 2.4s 略错拍）。
  void _paintHalo(Canvas canvas, Offset center, double t) {
    final breath = 0.5 - 0.5 * math.cos(t * math.pi); // 2s 周期
    final color = dark ? AppColors.darkPrimary : AppColors.navy;
    final alpha = (dark ? 0.09 : 0.06) + 0.09 * breath;
    final radius = size * (0.6 + 0.05 * breath);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
          [0.0, 1.0],
        ),
    );
  }

  void _paintParticle(
    Canvas canvas,
    Offset center,
    Offset target,
    _Spec s,
    double t,
  ) {
    final u = ((t - s.entryDelay) / s.entryDur).clamp(0.0, 1.0);
    final eased = Curves.easeInOutCubic.transform(u);
    final scatter =
        Offset(math.cos(s.scatterAngle), math.sin(s.scatterAngle)) *
        (s.scatterDist * size);
    var pos = target + scatter * (1 - eased);

    var alpha = Curves.easeOutCubic.transform(u);
    if (u >= 1) {
      // 到位后：行波涟漪 + 闪烁（幅度随尺寸缩放）。
      final n = _norm(target - center);
      final wave = math.sin(t * 2 * math.pi * 0.55 + s.wavePhase) * size * 0.02;
      pos += n * wave;
      alpha = 0.72 + 0.28 * math.sin(t * 2 * math.pi * 1.1 + s.wavePhase * 7);
    }
    if (alpha <= 0) return;

    canvas.drawCircle(
      pos,
      s.radius * size / 168,
      Paint()..color = _color(s.colorSlot).withValues(alpha: alpha),
    );
  }

  /// 配色：深色=钢蓝系（雾白 12% / 香槟金 18% / 钢蓝 70%），
  /// 浅色=墨蓝系（香槟金 20% / 雾蓝 25% / 墨蓝 55%）。
  Color _color(double slot) {
    if (dark) {
      return slot < 0.12
          ? AppColors.darkInk
          : slot < 0.30
          ? AppColors.darkBrass
          : AppColors.darkPrimary;
    }
    return slot < 0.20
        ? AppColors.brass
        : slot < 0.45
        ? const Color(0xFF7C9CC0) // 雾蓝
        : AppColors.navy;
  }

  static Offset _norm(Offset o) {
    final l = o.distance;
    return l < 0.001 ? const Offset(0, -1) : o / l;
  }

  @override
  bool shouldRepaint(_ParticleMarkPainter old) =>
      old.dark != dark || old.size != size;
}
