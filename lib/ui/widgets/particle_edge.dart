import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' as ui show Image, RSTransform;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'soft_sprite.dart';

/// 底缘光尘：child 底边一条缓慢流淌的粒子带（墨蓝/钢蓝尘 + 香槟金火花），
/// 激活时整带淡入、去激活柔出——全应用按钮、卡片、
/// 输入框「进行中」粒子动效的默认实现（docs/12 §9）。新界面一律复用
/// 本组件，不要另写粒子。
///
/// 触发方式（构造器决定，[mode]）：
/// - [ParticleEdge] 默认构造：鼠标悬停自检测（按钮/卡片）；
/// - [ParticleEdge.focus]：后代获得输入焦点（输入框；传 [controller]
///   时每次输入沿底缘迸一撮上升火花，即「正在输入」）；
/// - [ParticleEdge.active]：外部布尔驱动（自有 hover 态的组件复用，
///   不重复挂 MouseRegion）。
///
/// 工艺（与 busy 舞台同源）：软贴图 `drawAtlas + BlendMode.modulate`
/// 单批绘制逐粒着色；单调时钟 = 1 天 AnimationController（同时充当
/// painter 的 `repaint` 监听），空闲停表零开销；尘粒运动是 `_t` 的
/// 纯函数（无逐帧积分，宽度变化天然适配）。「减少动画」时整带禁用
/// （纯装饰，直接关闭）。widget 测试环境（FLUTTER_TEST）下只画静态
/// 帧不起时钟——常驻 Ticker 会卡死 pumpAndSettle（docs/12 §9 工艺注）。
class ParticleEdge extends StatefulWidget {
  const ParticleEdge({
    super.key,
    required this.child,
    this.band = 16,
    this.extendBelow = 4,
    this.density = 1,
    this.baseColor,
    this.sparkColor,
  }) : mode = ParticleEdgeMode.hover,
       active = null,
       focusNode = null,
       controller = null;

  const ParticleEdge.focus({
    super.key,
    required this.child,
    this.focusNode,
    this.controller,
    this.band = 14,
    this.extendBelow = 4,
    this.density = 1,
    this.baseColor,
    this.sparkColor,
  }) : mode = ParticleEdgeMode.focus,
       active = null;

  const ParticleEdge.active({
    super.key,
    required this.active,
    required this.child,
    this.band = 12,
    this.extendBelow = 3,
    this.density = 1,
    this.baseColor,
    this.sparkColor,
  }) : mode = ParticleEdgeMode.active,
       focusNode = null,
       controller = null;

  final Widget child;

  /// 粒子带高度（自 child 底边向上）。
  final double band;

  /// 粒子带越过底边向下的绘制余量（裁剪容器会自然截掉）。只影响
  /// 软贴图下半球的可见范围——不画任何全宽色带（会读成横杠）。
  final double extendBelow;

  /// 密度倍率（宽度换算基准 ~34px/粒，钳 6–26）。
  final double density;

  /// 主尘色（默认主题主色：浅色墨蓝/深色钢蓝）。
  final Color? baseColor;

  /// 火花色（默认香槟金）。
  final Color? sparkColor;

  final ParticleEdgeMode mode;
  final bool? active;
  final FocusNode? focusNode;
  final TextEditingController? controller;

  @override
  State<ParticleEdge> createState() => _ParticleEdgeState();
}

/// 触发方式：激活条件来自悬停、后代焦点还是外部布尔。
enum ParticleEdgeMode { hover, focus, active }

class _ParticleEdgeState extends State<ParticleEdge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(days: 1), // 单调时钟：永不循环、无回绕
  );

  /// 时钟之外的杂项重绘信号（测试直跳、配色/参数/贴图变更）。
  late final ValueNotifier<int> _bump = ValueNotifier(0);
  late final _EdgeDustPainter _painter = _EdgeDustPainter(
    repaint: Listenable.merge([_clock, _bump]),
  );
  Duration _lastT = Duration.zero;
  bool _hover = false;
  bool _focused = false;
  bool _reduce = false;

  /// widget 测试环境只画静态帧（不起常驻 Ticker，见类注释）。
  static final bool _testEnv = Platform.environment['FLUTTER_TEST'] == 'true';

  @override
  void initState() {
    super.initState();
    _clock.addListener(_onTick);
    _painter.onIdle = _stopClock;
    widget.controller?.addListener(_onType);
    bakeSoftSprite().then((img) {
      if (mounted) {
        _painter.sprite = img;
        _bump.value++;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    _painter
      ..base = widget.baseColor ?? theme.colorScheme.primary
      ..spark = widget.sparkColor ?? AppColors.brassOf(theme.brightness)
      ..band = widget.band
      ..extendBelow = widget.extendBelow
      ..density = widget.density;
    _reduce = MediaQuery.disableAnimationsOf(context);
    _apply(); // 首帧与 active 模式的初值都在这里落地
    _bump.value++;
  }

  @override
  void didUpdateWidget(ParticleEdge old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onType);
      widget.controller?.addListener(_onType);
    }
    _painter
      ..band = widget.band
      ..extendBelow = widget.extendBelow
      ..density = widget.density;
    // 配色可随状态变化（如错误态转朱砂）：与 didChangeDependencies 同步。
    final theme = Theme.of(context);
    final newBase = widget.baseColor ?? theme.colorScheme.primary;
    final newSpark = widget.sparkColor ?? AppColors.brassOf(theme.brightness);
    if (_painter.base != newBase || _painter.spark != newSpark) {
      _painter
        ..base = newBase
        ..spark = newSpark;
      _bump.value++;
    }
    if (widget.mode != old.mode ||
        (widget.mode == ParticleEdgeMode.active &&
            widget.active != old.active)) {
      _apply();
    }
  }

  @override
  void dispose() {
    _painter.onIdle = null;
    widget.controller?.removeListener(_onType);
    _bump.dispose();
    _clock.dispose();
    super.dispose();
  }

  /// 触发态汇总 → painter；激活即起表，去激活靠 activity 归零回调停表。
  void _apply() {
    final bool on;
    switch (widget.mode) {
      case ParticleEdgeMode.hover:
        on = _hover;
      case ParticleEdgeMode.focus:
        on = _focused;
      case ParticleEdgeMode.active:
        on = widget.active ?? false;
    }
    final target = on && !_reduce;
    if (_testEnv) {
      _painter.jump(target); // 静态帧直跳，无时钟
      _bump.value++;
      return;
    }
    if (target && !_clock.isAnimating) {
      _lastT = _clock.lastElapsedDuration ?? Duration.zero;
      _clock.forward();
    }
    _painter.target = target;
  }

  void _onType() {
    if (_testEnv || _reduce) return;
    if (widget.mode == ParticleEdgeMode.focus && !_focused) return;
    _painter.pulse();
    if (!_clock.isAnimating) {
      _lastT = _clock.lastElapsedDuration ?? Duration.zero;
      _clock.forward();
      _painter.target = true;
    }
  }

  void _onTick() {
    final now = _clock.lastElapsedDuration ?? Duration.zero;
    final dt = (now - _lastT).inMicroseconds / 1e6;
    _lastT = now;
    _painter.advance(dt.clamp(0.0, 0.05));
  }

  void _stopClock() {
    if (mounted && _clock.isAnimating) _clock.stop();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = CustomPaint(
      foregroundPainter: _painter,
      child: widget.child,
    );
    switch (widget.mode) {
      case ParticleEdgeMode.hover:
        return MouseRegion(
          onEnter: (_) {
            _hover = true;
            _apply();
          },
          onExit: (_) {
            _hover = false;
            _apply();
          },
          child: result,
        );
      case ParticleEdgeMode.focus:
        return Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (v) {
            _focused = v;
            _apply();
          },
          child: result,
        );
      case ParticleEdgeMode.active:
        return result;
    }
  }
}

/// 单粒环境尘：参数集，运动是 painter 时间 `_t` 的纯函数
/// （右移回绕 + 上下轻摆 + 明灭；火花粒另有慢周期 pop）。
class _Dust {
  _Dust(double w, double band, math.Random rnd)
    : x0 = rnd.nextDouble() * (w + 20),
      lift = band * math.pow(rnd.nextDouble(), 1.7),
      vx = 8 + rnd.nextDouble() * 26,
      size = 1.3 + rnd.nextDouble() * 1.9,
      alpha = 0.22 + rnd.nextDouble() * 0.38,
      spark = rnd.nextDouble() < 0.24,
      tw = 0.8 + rnd.nextDouble() * 2.2,
      bobF = 1.2 + rnd.nextDouble() * 1.6,
      popF = 0.5 + rnd.nextDouble() * 0.9,
      ph = rnd.nextDouble() * math.pi * 2;

  final double x0, lift, vx, size, alpha, tw, bobF, popF, ph;
  final bool spark;

  /// t 时刻的水平位置（-10 … w+10 回绕）。
  double xAt(double t, double w) => (x0 + vx * t) % (w + 20) - 10;
}

/// 输入迸发火花：自底缘升起、指数减速、钟形淡出（生命 ~0.6s）。
class _Ember {
  _Ember(double w, math.Random rnd)
    : x = w * (0.35 + rnd.nextDouble() * 0.6), // 偏右：输入光标常在的半区
      vy0 = -(34 + rnd.nextDouble() * 40),
      vx = (rnd.nextDouble() - 0.5) * 26,
      life = 0.42 + rnd.nextDouble() * 0.3,
      size = 1.5 + rnd.nextDouble() * 1.1,
      spark = rnd.nextDouble() < 0.7;

  final double x, vy0, vx, life, size;
  final bool spark;
  double age = 0;

  /// 抬升量：vy0·τ(1−e^(−t/τ))，τ=0.28s（先快后缓的减速升）。
  double riseAt() {
    const tau = 0.28;
    return -vy0 * tau * (1 - math.exp(-age / tau));
  }
}

class _EdgeDustPainter extends CustomPainter {
  _EdgeDustPainter({required Listenable repaint}) : super(repaint: repaint);

  ui.Image? sprite;
  bool target = false;
  Color base = const Color(0xFF1C3A5C);
  Color spark = const Color(0xFFB3924F);
  double band = 16;
  double extendBelow = 4;
  double density = 1;
  void Function()? onIdle;

  double _activity = 0;
  double _t = 0;
  double _w = -1;
  final List<_Dust> _dust = [];
  final List<_Ember> _embers = [];
  final math.Random _rnd = math.Random();
  double _dustBand = -1;

  /// 测试环境直跳目标态（单帧静态渲染，无时钟）。
  void jump(bool on) {
    target = on;
    _activity = on ? 1 : 0;
    _embers.clear();
  }

  /// 输入迸发：沿底缘右半区掷 3–5 粒上升火花。
  void pulse() {
    if (_w <= 0) return;
    for (var i = 0; i < 3 + _rnd.nextInt(3); i++) {
      _embers.add(_Ember(_w, _rnd));
    }
  }

  /// 时钟每帧推进（重绘由 repaint 监听自动触发）。
  void advance(double dt) {
    if (dt <= 0) return;
    _t += dt;
    _activity += ((target ? 1.0 : 0.0) - _activity) * math.min(1, dt * 7);
    for (final e in _embers) {
      e.age += dt;
    }
    _embers.removeWhere((e) => e.age >= e.life);
    final idle = !target && _activity < 0.006 && _embers.isEmpty;
    if (idle) _activity = 0;
    if (idle) onIdle?.call();
  }

  void _ensureDust() {
    final n = (_w / 34 * density).round().clamp(6, 26);
    if (_dust.length != n || band != _dustBand) {
      _dust
        ..clear()
        ..addAll(List.generate(n, (_) => _Dust(_w, band, _rnd)));
      _dustBand = band;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _w = size.width;
    if (_w <= 0 || (_activity <= 0.004 && _embers.isEmpty)) return;
    _ensureDust();
    final env = _activity;
    final bottom = size.height;

    // 只画粒子本身：不垫任何全宽色带/辉光矩形——线性渐变带在顶边有
    // 硬切，宽卡上看起来就是一条横杠（用户实测反馈）。
    final xf = <ui.RSTransform>[];
    final cols = <Color>[];
    // RSTransform 锚点在贴图左上角：平移量换算成「贴图中心落在 (x, y)」。
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

    for (final d in _dust) {
      final twinkle = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(_t * d.tw + d.ph));
      var a = d.alpha * twinkle * env;
      var r = d.size;
      if (d.spark) {
        final pop = math
            .pow(math.max(0.0, math.sin(_t * d.popF + d.ph)), 8)
            .toDouble();
        a = math.min(1, a + pop * 0.5 * env);
        r *= 1 + pop * 0.5;
      }
      final y = bottom - d.lift + math.sin(_t * d.bobF + d.ph) * 1.6;
      put(
        d.xAt(_t, _w),
        y,
        r,
        (d.spark ? spark : base).withValues(alpha: a.clamp(0, 1)),
      );
    }

    for (final e in _embers) {
      final u = (e.age / e.life).clamp(0.0, 1.0);
      final fade = math.sin(math.pi * u); // 钟形包络：起收都柔
      put(
        e.x + e.vx * e.age,
        bottom - e.riseAt(),
        e.size * (1 + 0.3 * (1 - u)),
        (e.spark ? spark : base).withValues(alpha: 0.85 * fade * env),
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
        Rect.fromLTRB(
          -24,
          bottom - band - 24,
          _w + 24,
          bottom + extendBelow + 24,
        ),
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.medium,
      );
    }
  }

  @override
  bool shouldRepaint(_EdgeDustPainter oldDelegate) => true;
}
