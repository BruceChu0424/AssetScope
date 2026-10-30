import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

/// 深空背景与粒子（用户 2026-10 指令：动效全开，不因性能收敛）。
///
/// - [SpaceBackdrop]：整页/整区深空底幕组件——星野闪烁 + 双色星云漂移
///   + 偶发流星，自带 Ticker 驱动，铺满可用空间（首页整页用；地球组件
///   内嵌用）；
/// - `SpaceBackdropPainter`：上述视觉的绘制器，由时间参数 [t] 驱动
///   （确定性，无逐帧状态）；
/// - `ParticleField` + `ParticlesPainter`：屏幕空间粒子池（标记星尘 /
///   点击爆发），由 AssetGlobe 的帧回调推进，画在地球之上；
///   `hitTest` 恒 false，不挡手势。

/// 深空底幕：整页铺满（首页）或嵌在地球组件里（全屏地球页）。
class SpaceBackdrop extends StatefulWidget {
  const SpaceBackdrop({super.key});

  @override
  State<SpaceBackdrop> createState() => _SpaceBackdropState();
}

class _SpaceBackdropState extends State<SpaceBackdrop>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final List<Star> _stars = buildStarfield();
  final math.Random _rnd = math.Random();
  ShootingStar? _shooting;
  double _elapsed = 0;
  double _nextShootingAt = 2.5;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    _elapsed = elapsed.inMicroseconds / 1e6;
    if (_size.width > 0 && _elapsed >= _nextShootingAt) _scheduleShooting();
    setState(() {}); // 重画星野/流星
  }

  /// 流星：每 6–14 秒一颗，从上半区斜穿（时长 0.8–1.3s）。
  void _scheduleShooting() {
    final w = _size.width, h = _size.height;
    final fromLeft = _rnd.nextBool();
    final from = Offset(
      w *
          (fromLeft
              ? 0.05 + _rnd.nextDouble() * 0.35
              : 0.6 + _rnd.nextDouble() * 0.35),
      h * (0.02 + _rnd.nextDouble() * 0.3),
    );
    final to =
        from +
        Offset(
          (fromLeft ? 1 : -1) * w * (0.3 + _rnd.nextDouble() * 0.3),
          h * (0.12 + _rnd.nextDouble() * 0.18),
        );
    _shooting = ShootingStar(from, to, _elapsed, 0.8 + _rnd.nextDouble() * 0.5);
    _nextShootingAt = _elapsed + 6 + _rnd.nextDouble() * 8;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _size = constraints.biggest;
          return CustomPaint(
            size: _size,
            painter: SpaceBackdropPainter(
              t: _elapsed,
              stars: _stars,
              appear: _elapsed.clamp(0.0, 0.9) / 0.9, // 0.9s 内星野亮起
              shooting: _shooting,
            ),
          );
        },
      ),
    );
  }
}

class Star {
  Star(this.x, this.y, this.r, this.phase, this.speed, this.color);

  final double x; // 0..1 归一化
  final double y;
  final double r;
  final double phase;
  final double speed;
  final Color color;
}

/// 固定种子生成 ~120 颗星（白/钢蓝为主，偶带香槟色），布局稳定不闪跳。
List<Star> buildStarfield([int seed = 7]) {
  final rnd = math.Random(seed);
  final stars = <Star>[];
  for (var i = 0; i < 120; i++) {
    final roll = rnd.nextDouble();
    stars.add(
      Star(
        rnd.nextDouble(),
        rnd.nextDouble(),
        0.4 + rnd.nextDouble() * 1.1,
        rnd.nextDouble() * math.pi * 2,
        0.4 + rnd.nextDouble() * 1.3,
        roll < 0.72
            ? const Color(0xFFDCE9F7)
            : roll < 0.92
            ? const Color(0xFF7EA6D9)
            : const Color(0xFFE5C078),
      ),
    );
  }
  return stars;
}

/// 流星的瞬时状态（from → to 直线滑过）。
class ShootingStar {
  ShootingStar(this.from, this.to, this.start, this.life);

  final Offset from;
  final Offset to;
  final double start; // 出发时刻（秒，t 基准）
  final double life; // 全程时长（秒）
}

class SpaceBackdropPainter extends CustomPainter {
  SpaceBackdropPainter({
    required this.t,
    required this.stars,
    required this.appear,
    this.shooting,
  });

  final double t;
  final List<Star> stars;
  final double appear; // 0..1 整体浮现（星野快速先亮）
  final ShootingStar? shooting;

  static const _nebulaA = Color(0xFF3E6C9E); // 钢蓝星云
  static const _nebulaB = Color(0xFF8A7042); // 香槟星云（更淡）

  @override
  void paint(Canvas canvas, Size size) {
    final starAlpha = appear.clamp(0.0, 1.0);
    _paintNebula(canvas, size);
    _paintStars(canvas, size, starAlpha);
    _paintShootingStar(canvas, size, starAlpha);
  }

  /// 双色星云：两个大径向渐变随 t 缓慢游移，透明度极低（氛围不抢戏）。
  void _paintNebula(Canvas canvas, Size size) {
    final fade = 0.5 + 0.5 * math.sin(t * 0.21); // 星云整体呼吸
    void blob(Color color, Offset center, double radius, double alpha) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    }

    final a = Offset(
      size.width * (0.30 + 0.10 * math.sin(t * 0.11)),
      size.height * (0.32 + 0.08 * math.cos(t * 0.13)),
    );
    final b = Offset(
      size.width * (0.74 + 0.09 * math.cos(t * 0.09)),
      size.height * (0.70 + 0.10 * math.sin(t * 0.12)),
    );
    blob(_nebulaA, a, size.width * 0.42, 0.05 + 0.025 * fade);
    blob(_nebulaB, b, size.width * 0.30, 0.028 + 0.018 * fade);
  }

  void _paintStars(Canvas canvas, Size size, double appear) {
    for (final s in stars) {
      final tw = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * s.speed + s.phase));
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.r,
        Paint()..color = s.color.withValues(alpha: tw * appear * 0.9),
      );
    }
  }

  void _paintShootingStar(Canvas canvas, Size size, double appear) {
    final s = shooting;
    if (s == null) return;
    final p = ((t - s.start) / s.life).clamp(0.0, 1.0);
    if (p <= 0 || p >= 1) return;
    // easeOutCubic：起步快、尾段拖长。
    final e = 1 - math.pow(1 - p, 3).toDouble();
    final head = Offset(
      s.from.dx + (s.to.dx - s.from.dx) * e,
      s.from.dy + (s.to.dy - s.from.dy) * e,
    );
    final trail = 70 * (1 - p * 0.45);
    final dir = (s.to - s.from) / (s.to - s.from).distance;
    final tail = head - dir * trail;
    final alpha = math.sin(p * math.pi) * 0.85 * appear;
    canvas.drawLine(
      tail,
      head,
      Paint()
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: alpha),
          ],
        ).createShader(Rect.fromPoints(tail, head)),
    );
    canvas.drawCircle(
      head,
      1.6,
      Paint()..color = Colors.white.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(SpaceBackdropPainter old) =>
      old.t != t || old.appear != appear || old.shooting != shooting;
}

/// 屏幕空间粒子（星尘 / 爆发火花）。
class Particle {
  Particle({
    required this.pos,
    required this.vel,
    required this.life,
    required this.maxLife,
    required this.size,
    required this.color,
    this.gravity = 0,
  });

  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final double size;
  final Color color;
  final double gravity; // 像素/秒²（星尘微升为负）
}

/// 粒子池：上限 [_cap] 防失控；update 由外层帧回调驱动。
class ParticleField {
  ParticleField({this.cap = 240});

  final int cap;
  final List<Particle> particles = [];
  final math.Random _rnd = math.Random();

  bool get isEmpty => particles.isEmpty;

  void update(double dt) {
    for (final p in particles) {
      p.pos += p.vel * dt;
      p.vel = Offset(p.vel.dx, p.vel.dy + p.gravity * dt) * math.exp(-dt * 1.6);
      p.life -= dt;
    }
    particles.removeWhere((p) => p.life <= 0);
  }

  /// 点击爆发：金色火花径向四散 + 几缕白色高光。
  void burst(Offset center, {int count = 22}) {
    for (var i = 0; i < count && particles.length < cap; i++) {
      final angle = _rnd.nextDouble() * math.pi * 2;
      final speed = 40 + _rnd.nextDouble() * 120;
      particles.add(
        Particle(
          pos: center,
          vel: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
          life: 0.5 + _rnd.nextDouble() * 0.7,
          maxLife: 1.2,
          size: 1.2 + _rnd.nextDouble() * 2.0,
          color: _rnd.nextDouble() < 0.75
              ? const Color(0xFFE5C078)
              : const Color(0xFFFFF3D6),
          gravity: 30,
        ),
      );
    }
  }

  /// 标记星尘：从标记位置缓慢升起的一粒微光。
  void sparkle(Offset at, {Color color = const Color(0xFFE5C078)}) {
    if (particles.length >= cap) return;
    particles.add(
      Particle(
        pos: at + Offset((_rnd.nextDouble() - 0.5) * 8, 0),
        vel: Offset((_rnd.nextDouble() - 0.5) * 8, -6 - _rnd.nextDouble() * 10),
        life: 0.9 + _rnd.nextDouble() * 0.9,
        maxLife: 1.8,
        size: 0.8 + _rnd.nextDouble() * 1.1,
        color: color.withValues(alpha: 1),
        gravity: -4,
      ),
    );
  }
}

/// 粒子渲染层（画在地球之上、HUD 之下）；hitTest 恒 false 不挡手势。
class ParticlesPainter extends CustomPainter {
  ParticlesPainter(this.field);

  final ParticleField field;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in field.particles) {
      final k = (p.life / p.maxLife).clamp(0.0, 1.0);
      final color = p.color.withValues(alpha: k * 0.9);
      // 微光晕 + 核心点。
      canvas.drawCircle(
        p.pos,
        p.size * 2.2,
        Paint()..color = color.withValues(alpha: k * 0.18),
      );
      canvas.drawCircle(
        p.pos,
        p.size * (0.4 + 0.6 * k),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter old) => true; // 每帧推进

  @override
  bool hitTest(Offset position) => false;
}
