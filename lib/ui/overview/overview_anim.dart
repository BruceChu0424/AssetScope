import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';

/// 沉浸式详情页动效工具（v0.26 Orbital Finance 套件）。
///
/// 三条纪律：
/// 1. **拉满但有序**——用户明确要求动画细腻不减配；所有编排给完整曲线
///    与阶梯，但同一时刻只有一个视觉焦点在动。
/// 2. **测试静态帧**——FLUTTER_TEST 环境下常驻循环（自转/呼吸）冻结为
///    静止帧（同 SpaceBackdrop 的教训），否则 golden 走查永不 settle。
/// 3. **减少动画直达**——MediaQuery.disableAnimations 时一切入场直达
///    终态，循环动画停摆。

/// 测试环境：常驻循环动画冻结（golden 可 settle）。
final bool kOvTestEnv = Platform.environment['FLUTTER_TEST'] == 'true';

/// 单段入场（90→300ms 可调）：淡入 + 上浮 + 0.5% 放大，easeOutCubic。
/// 与首页 _StaggerIn 同手感，供详情页区块/弹层内容复用。
class OvRiseIn extends StatefulWidget {
  const OvRiseIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
    this.offset = 14,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  State<OvRiseIn> createState() => _OvRiseInState();
}

class _OvRiseInState extends State<OvRiseIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final CurvedAnimation _anim = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  /// 阶梯延迟用可取消 Timer：dispose 时清掉（widget 测试收尾的
  /// 「无挂起 Timer」断言不接受幸存的 Future.delayed）。
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    // initState 里不能查 MediaQuery（inherit 依赖未挂载）：帧后校验。
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  /// 入口：先过「减少动画」，再决定立即起跳还是延迟一拍。
  void _begin() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _delayTimer = Timer(widget.delay, _start);
    }
  }

  /// 延迟到点：真正起跳（只执行一次，不再自排——曾因此无限排程，
  /// 第 2 项起永远停在透明度 0，被 golden 像素走查逮住）。
  void _start() {
    if (mounted) _c.forward();
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _c.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final t = _anim.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - t)),
            child: Transform.scale(scale: 0.995 + 0.005 * t, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// 阶梯入场列：children 依次错落浮现（默认 45ms 一阶）。
/// 滚动容器里同样成立（每块各自持控制器，滚出视口即停帧不销毁）。
class OvStaggerColumn extends StatelessWidget {
  const OvStaggerColumn({
    super.key,
    required this.children,
    this.step = const Duration(milliseconds: 45),
    this.gap = 14,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final Duration step;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          OvRiseIn(delay: step * i, child: children[i]),
        ],
      ],
    );
  }
}

/// 呼吸辉光：围绕 child 的一圈柔光缓慢明暗（周期 3.2s）。
/// 用于状态点/轨道节点/空状态柔光；hitTest 不挡交互。
class OvBreathing extends StatefulWidget {
  const OvBreathing({
    super.key,
    required this.color,
    required this.child,
    this.radius = 18,
    this.maxAlpha = 0.38,
  });

  final Color color;
  final Widget child;
  final double radius;
  final double maxAlpha;

  @override
  State<OvBreathing> createState() => _OvBreathingState();
}

class _OvBreathingState extends State<OvBreathing>
    with SingleTickerProviderStateMixin {
  // 注意：initState 即刻构造（惰性构造在 dispose 阶段查 TickerMode 祖先
  // 会炸——同 space_backdrop / home_shell 的教训）。
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void initState() {
    super.initState();
    if (!kOvTestEnv) _c.repeat(reverse: true);
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
      builder: (context, child) {
        final t = Curves.easeInOut
            .transform(kOvTestEnv ? 0.5 : _c.value);
        return Container(
          foregroundDecoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(
                  alpha: widget.maxAlpha * (0.35 + 0.65 * t),
                ),
                blurRadius: widget.radius,
                spreadRadius: widget.radius * 0.25,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 图表扫描入场：child（图表）从左向右 720ms 揭开（ClipRect 扫掠 +
/// 前缘一道 1px 亮线）。数据不动、只有取景在走——「图表绘制中」的
/// 高级读法。减少动画时直通。
class OvChartSweep extends StatefulWidget {
  const OvChartSweep({super.key, required this.child, this.duration = 720});

  final Widget child;
  final int duration;

  @override
  State<OvChartSweep> createState() => _OvChartSweepState();
}

class _OvChartSweepState extends State<OvChartSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.duration),
  );
  late final CurvedAnimation _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    // 同上：帧后校验「减少动画」再启幕。
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
      builder: (context, child) {
        final w = _t.value;
        if (w >= 1) return child!;
        return ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: w.clamp(0.001, 1.0),
            child: Stack(
              children: [
                child!,
                // 前缘亮线：随扫掠推进。
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1.2,
                    color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: 0.75,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// 数值生长（0→值，BigInt 整数域缩放，全程精确）：与首页
/// _CountUpMoney 同工艺；详情页 KPI 大数默认走它（配 Odometer roll）。
class OvCountUp extends StatelessWidget {
  const OvCountUp({
    super.key,
    required this.minor,
    required this.builder,
    this.duration = const Duration(milliseconds: 1100),
  });

  final BigInt minor;
  final Widget Function(BigInt value) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) =>
          builder(minor * BigInt.from((t * 10000).round()) ~/
              BigInt.from(10000)),
    );
  }
}
