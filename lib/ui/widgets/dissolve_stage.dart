import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'dissolve_particles.dart';
import 'dissolve_painter.dart';
import 'soft_sprite.dart';

export 'dissolve_particles.dart'
    show
        DissolveClock,
        DissolveCaptureData,
        DissolveParticle,
        sampleDissolve,
        kConvergeAt,
        kLaunchAt;

/// 弹窗溶解粒子舞台：全屏 Overlay 场景，把 [DissolveCaptureData]
/// （弹窗截图采样出的粒子云）编排成四幕连台动画——
///
/// 1. **无缝接管**（0~0.14s）：弹窗原图与静态粒子云交叉淡入淡出，
///    画面上毫无「换层」痕迹；
/// 2. **碎裂**（0.10~0.88s）：碎裂波自保存按钮位置扫过整个弹窗，
///    粒子带着采样色四散飞溅（外抛 + 涡旋 + 湍流摆动）；
/// 3. **光束**（0.55~1.70s）：粒子汇入一条贝塞尔光束，彗头拖着长尾
///    飞向 [targetOf] 给出的落点——目标点每帧重询，地球边转边缩放
///    光束都实时追踪；
/// 4. **汇聚闪耀**（1.70~2.85s）：粒子收束到落点凝成标志——双扩散环
///    + 中心绽放 + 向上光柱 + 径向迸散火花，随后全场淡出。
///
/// 光束出鞘/到达分别回调 [onLaunch]/[onArrive]（调用方借此驱动地球
/// 飞行与标记重载）。粒子经软贴图 drawAtlas 单批绘制；本舞台铺满
/// 全屏并吸收指针——约 2.9s 的「保存确认剧场」，结束后 [onDone]
/// 摘除自己。
class DissolveStage extends StatefulWidget {
  const DissolveStage({
    super.key,
    required this.data,
    required this.targetOf,
    this.onLaunch,
    this.onArrive,
    required this.onDone,
  });

  final DissolveCaptureData data;

  /// 落点（全局坐标；null = 目标暂不可见，舞台沿用上一帧位置）。
  final Offset? Function() targetOf;
  final VoidCallback? onLaunch;
  final VoidCallback? onArrive;
  final VoidCallback onDone;

  @override
  State<DissolveStage> createState() => _DissolveStageState();
}

class _DissolveStageState extends State<DissolveStage>
    with SingleTickerProviderStateMixin {
  final DissolveClock _clock = DissolveClock();
  late final Ticker _ticker = createTicker(_onTick);
  ui.Image? _sprite;
  Offset? _target;
  bool _launched = false;
  bool _arrived = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    bakeSoftSprite().then((img) {
      if (mounted) setState(() => _sprite = img);
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    _target = widget.targetOf() ?? _target;
    // 相位回调先于重绘发出：地球侧的动作与光束同帧起跑。
    if (!_launched && t >= kLaunchAt) {
      _launched = true;
      widget.onLaunch?.call();
    }
    if (!_arrived && t >= kConvergeAt) {
      _arrived = true;
      widget.onArrive?.call();
    }
    if (!_done && t >= kDissolveTotal) {
      _done = true;
      // 帧末再摘除：本次重绘仍是完整淡出末帧，不留一帧空洞。
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      return;
    }
    _clock.advance(t);
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      // 确认剧场期间吸收整页指针：地球正被程序驱动，不容中途抓取。
      child: AnimatedBuilder(
        animation: _clock,
        builder: (context, _) {
          final t = _clock.t;
          final fade = t <= kFadeAt
              ? 1.0
              : 1 -
                    Curves.easeOutCubic.transform(
                      ((t - kFadeAt) / kFadeDur).clamp(0.0, 1.0),
                    );
          return Opacity(
            opacity: fade,
            child: SizedBox.expand(
              key: const ValueKey('as-dissolve-stage'),
              child: CustomPaint(
                painter: DissolveStagePainter(
                  clock: _clock,
                  data: widget.data,
                  sprite: _sprite,
                  target: _target,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
