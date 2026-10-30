import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' as ui show Image, RSTransform;

import 'package:flutter/material.dart';

import 'soft_sprite.dart';

/// 轨道粒子加载：按钮内联「进行中」指示——一圈软粒子绕心公转的彗星环，
/// 头粒最亮、尾粒渐隐，香槟金火花领衔。与粒子舞台/底缘光尘同一视觉
/// 语言（软贴图 drawAtlas + 单调时钟纯函数运动）；widget 测试环境与
/// 「减少动画」都定格静止帧（环仍在，明暗冻结）。
///
/// 用在锁屏圆钮内部替代 CircularProgressIndicator：解锁核验的慢哈希
/// 期间只有这圈粒子在转，全屏舞台留到核验成功之后。
class ParticleOrbit extends StatefulWidget {
  const ParticleOrbit({
    super.key,
    this.size = 24,
    this.color,
    this.spark,
  });

  /// 环的外接尺寸（正方形）。
  final double size;

  /// 尾粒颜色（默认 onPrimary：钮底是主色）。
  final Color? color;

  /// 头粒火花色（默认香槟金，同粒子舞台配色）。
  final Color? spark;

  @override
  State<ParticleOrbit> createState() => _ParticleOrbitState();
}

class _ParticleOrbitState extends State<ParticleOrbit>
    with SingleTickerProviderStateMixin {
  /// 单调时钟：永不满、无回绕，painter 挂 repaint 监听。
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(days: 1),
  );
  ui.Image? _sprite;
  bool _reduce = false;

  /// widget 测试环境只画静态帧（常驻 Ticker 会卡死 pumpAndSettle）。
  static final bool _testEnv = Platform.environment['FLUTTER_TEST'] == 'true';

  @override
  void initState() {
    super.initState();
    bakeSoftSprite().then((img) {
      if (mounted) setState(() => _sprite = img);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
    if (!_testEnv && !_reduce && !_clock.isAnimating && _clock.value == 0) {
      _clock.forward();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      size: Size.square(widget.size),
      painter: _OrbitPainter(
        clock: _clock,
        sprite: _sprite,
        color: widget.color ?? cs.onPrimary,
        spark: widget.spark ?? const Color(0xFFE5C078),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({
    required this.clock,
    required this.sprite,
    required this.color,
    required this.spark,
  }) : super(repaint: clock);

  final AnimationController clock;
  final ui.Image? sprite;
  final Color color;
  final Color spark;

  /// 粒子数：46px 钮内 ~28px 环，12 颗足够密又不糊成环带。
  static const int _count = 12;

  /// 公转角速度（rad/s）：约 2.6s 一圈——加载中的从容节奏，不焦躁。
  static const double _omega = 2.4;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    if (s <= 0) return;
    final elapsed = clock.lastElapsedDuration;
    final t = elapsed == null ? 0.0 : elapsed.inMicroseconds / 1e6;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final orbit = s * 0.36;
    final baseR = s * 0.075;

    final xf = <ui.RSTransform>[];
    final cols = <Color>[];
    void put(double x, double y, double r, Color c) {
      if (sprite == null) {
        canvas.drawCircle(Offset(x, y), r * 0.55, Paint()..color = c);
        return;
      }
      final sc = r * 2 / kSoftSpriteSize;
      xf.add(
        ui.RSTransform(
          sc,
          0,
          x - sc * kSoftSpriteSize / 2,
          y - sc * kSoftSpriteSize / 2,
        ),
      );
      cols.add(c);
    }

    for (var i = 0; i < _count; i++) {
      // i=0 是彗头：相位落后量越大越暗越小（(1-u)^1.6 的彗尾包络）。
      final u = i / _count;
      final fade = math.pow(1 - u, 1.6).toDouble();
      final angle = t * _omega - u * 2 * math.pi;
      // 轻微径向摆动，避免机械正圆。
      final wob = math.sin(t * 3.1 + i * 1.7) * s * 0.02;
      final x = cx + math.cos(angle) * (orbit + wob);
      final y = cy + math.sin(angle) * (orbit + wob);
      final head = i == 0 || i == 1;
      put(
        x,
        y,
        baseR * (0.62 + 0.5 * fade) * (head ? 1.25 : 1),
        (head ? spark : color).withValues(
          alpha: (head ? 0.95 : 0.16 + 0.72 * fade).clamp(0, 1),
        ),
      );
    }

    if (sprite != null && xf.isNotEmpty) {
      canvas.drawAtlas(
        sprite!,
        xf,
        List.filled(
          xf.length,
          const Rect.fromLTWH(0, 0, kSoftSpriteSize, kSoftSpriteSize),
        ),
        cols,
        BlendMode.modulate,
        Offset.zero & size,
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.medium,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) =>
      oldDelegate.sprite != sprite ||
      oldDelegate.color != color ||
      oldDelegate.spark != spark;
}
