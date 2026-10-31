import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;

import 'dialog_dissolve.dart';
import 'particle_dialog_stage.dart';
import 'soft_sprite.dart';

/// ── 粒子弹窗体系（v0.25，2026-10 用户指令：全平台弹窗统一粒子化）─────
///
/// [showParticleDialog] 是全应用弹窗的**唯一打开入口**（`showAppDialog`
/// 与 `showAppSheet` 大屏形态都汇到这里）：
///
/// - **入场 · 四散汇聚**（0.82s）：数千颗粒子自弹窗四周环带螺旋内旋，
///   汇成弹窗轮廓（尘云烘焙层叠出数万颗密度）；第 0.50s 起表面淡入 +
///   轻放大落位，粒子到位即化作表面微光消隐——「粒子汇聚成弹窗形态，
///   弹窗慢慢显示」。
/// - **退场 · 粒子化**（取消 0.80s / 确认 0.94s）：弹窗实时截图采样成
///   粒子云（原图与粒子云同帧同位交叉淡变——「卡片再粒子化」的无缝
///   衔接，绝不生硬瞬切）。取消 = 温和外散消隐；确认（pop 返回值非
///   null）= 先向核心收束再迸散 + 闪光环（能量释放）。
/// - **保存 · 光束飞向目标**：传 [dissolve]（DissolveController）即接
///   入既有的四幕剧场（碎裂→贝塞尔光束→地球落点闪耀，见
///   dialog_dissolve.dart）——首页「添加资产」的标准链路。
///
/// 降级：系统「减少动画」或 FLUTTER_TEST 环境（金像素走查/测试需要
/// pumpAndSettle）自动退回普通淡入淡出；截图失败静默普通关闭。
/// 弹窗内容照常第一时间可交互（表面显形完成即透明度 1）。
///
/// 组件化：弹窗内部控件按 docs/12 规范组装——容器壳 [AppDialog]、
/// 按钮 [ParticleFilledButton]、输入 [ParticleTextField]、下拉
/// `ParticleDropdownField`（particle_menu.dart）、日期 `AppDateField`。

/// widget 测试环境：粒子舞台一律不开（静态帧惯例同 particle_edge）。
final bool kParticleDialogTestEnv =
    Platform.environment['FLUTTER_TEST'] == 'true';

/// 打开粒子化弹窗（全应用统一入口，详见文件头）。
///
/// [alignment] 弹窗在屏位置（居中弹窗 / 右缘侧滑面板）。[entryFrom]
/// 表面落位方向（如侧滑面板自右侧 `Offset(1, 0)`——以弹窗自身尺寸的
/// 比例计）。[dissolve] 接入光束保存链路（played 后本体系跳过自带退场）。
Future<T?> showParticleDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  AlignmentGeometry alignment = Alignment.center,
  Offset entryFrom = Offset.zero,
  DissolveController? dissolve,
  bool useRootNavigator = true,
  Duration entryDuration = const Duration(milliseconds: 820),
}) {
  final reduce = MediaQuery.disableAnimationsOf(context);
  final theme = Theme.of(context);
  if (reduce || kParticleDialogTestEnv) {
    // 降级：普通淡入 + 轻放大（与旧 showAppDialog 完全一致的手感）。
    final barrier =
        barrierColor ??
        (theme.brightness == Brightness.light
            ? Colors.black.withValues(alpha: 0.28)
            : Colors.black.withValues(alpha: 0.5));
    return showGeneralDialog<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(
        context,
      ).modalBarrierDismissLabel,
      barrierColor: barrier,
      transitionDuration: reduce ? Duration.zero : entryDuration,
      pageBuilder: (context, animation, secondaryAnimation) =>
          Align(alignment: alignment, child: builder(context)),
      transitionBuilder: (context, animation, _, child) {
        if (reduce) return child;
        final t = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: t,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(t),
            child: child,
          ),
        );
      },
    );
  }

  final barrier =
      barrierColor ??
      (theme.brightness == Brightness.light
          ? Colors.black.withValues(alpha: 0.28)
          : Colors.black.withValues(alpha: 0.5));
  final route = _ParticleDialogRoute<T>(
    builder: builder,
    alignment: alignment,
    entryFrom: entryFrom,
    dissolve: dissolve,
    barrierColor: barrier,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    entryDuration: entryDuration,
    // 光束链路退场与入场等长（剧场由 DissolveStage 在根 Overlay 续演）；
    // 自带粒子化退场稍长于 0.94s 舞台，避免路由先散留黑帧。
    exitDuration: Duration(
      milliseconds: dissolve != null ? 820 : 980,
    ),
  );
  return Navigator.of(context, rootNavigator: useRootNavigator).push(route);
}

enum DialogRouteKind { particle, beam }

class _ParticleDialogRoute<T> extends RawDialogRoute<T> {
  _ParticleDialogRoute({
    required WidgetBuilder builder,
    required AlignmentGeometry alignment,
    required Offset entryFrom,
    required DissolveController? dissolve,
    required Color barrierColor,
    required String barrierLabel,
    required this.exitDuration,
    super.barrierDismissible,
    required Duration entryDuration,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             _ParticleDialogHost<T>(
               entry: animation,
               alignment: alignment,
               entryFrom: entryFrom,
               dissolve: dissolve,
               child: Builder(builder: builder),
             ),
         transitionDuration: entryDuration,
         barrierLabel: barrierLabel,
         barrierColor: barrierColor,
         transitionBuilder: (context, animation, _, child) => child,
       );

  final Duration exitDuration;

  /// RawDialogRoute 构造器不收反向时长：路由保持存活到粒子化退场舞台
  /// 播完（遮罩同窗渐隐），内容早已同帧隐藏、不会双重淡出。
  @override
  Duration get reverseTransitionDuration => exitDuration;
}

/// 弹窗宿主：入场舞台（粒子在内容层之下）+ 表面显形编排 + 退场粒子化。
class _ParticleDialogHost<T> extends StatefulWidget {
  const _ParticleDialogHost({
    required this.entry,
    required this.alignment,
    required this.entryFrom,
    required this.dissolve,
    required this.child,
  });

  /// 路由入场动画（0→1 线性，时长 = 入场总程）：驱动舞台时钟与表面
  /// 显形（不必自建 controller——路由动画即唯一时间源，反向时表面
  /// 直接隐藏交由退场舞台接管）。
  final Animation<double> entry;
  final AlignmentGeometry alignment;

  /// 表面落位方向（弹窗自身尺寸比例；侧滑面板传 Offset(1, 0)）。
  final Offset entryFrom;
  final DissolveController? dissolve;
  final Widget child;

  @override
  State<_ParticleDialogHost<T>> createState() =>
      _ParticleDialogHostState<T>();
}

class _ParticleDialogHostState<T> extends State<_ParticleDialogHost<T>> {
  final GlobalKey _boundaryKey = GlobalKey(debugLabel: 'particle-dialog');
  final math.Random _rnd = math.Random();

  List<ConvergeParticle>? _specs;
  List<DustLayer> _layers = const [];
  ui.Image? _sprite;
  ui.Image? _cloud;
  bool _exiting = false;
  bool _allowPop = false;
  bool _hidden = false; // 退场粒子化后：表面让位给舞台

  @override
  void initState() {
    super.initState();
    _layers = bakeDustLayers(_rnd);
    bakeSoftSprite().then((img) {
      if (mounted) setState(() => _sprite = img);
    });
    dustCloudImage()?.then((img) {
      if (mounted) setState(() => _cloud = img);
    });
    // 首帧量出弹窗矩形再起汇聚（表面此刻透明，观众只看到粒子成形）。
    WidgetsBinding.instance.addPostFrameCallback((_) => _armEntry());
  }

  void _armEntry() {
    if (!mounted || _specs != null) return;
    final ro = _boundary;
    if (ro == null || !ro.hasSize || ro.size.isEmpty) {
      // 无边界（异常布局）：跳过舞台，直接显形。
      setState(() => _specs = const []);
      return;
    }
    setState(() {
      _specs = sampleConvergence(
        rect: ro.localToGlobal(Offset.zero) & ro.size,
        seed: _rnd.nextInt(1 << 20),
      );
    });
  }

  RenderRepaintBoundary? get _boundary =>
      _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

  @override
  Widget build(BuildContext context) {
    return PopScope<T>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onPopRequest(result);
      },
      child: AnimatedBuilder(
        animation: widget.entry,
        builder: (context, child) {
          final t = widget.entry.value;
          // 表面显形：0.50s 起 0.30s 淡入 + 0.965→1 放大 + 自 entryFrom
          // 方向 6% 落位；退场（反向/粒子化后）瞬时隐藏——画面交由
          // 退场舞台接管，入场舞台绝不能倒放。
          final surface = _hidden
              ? 0.0
              : Curves.easeOutCubic.transform(
                  ((t - kConvSurfaceAt) / kConvSurfaceDur).clamp(0.0, 1.0),
                );
          return Stack(
            children: [
              // 入场舞台：粒子在内容层之下（汇聚「托举」出弹窗）。
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: ConvergePainter(
                      progress: _exiting ? 2 : t,
                      particles: _specs ?? const [],
                      sprite: _sprite,
                      cloud: _cloud,
                      layers: _layers,
                      rect: _dialogRect ?? const Rect.fromLTWH(0, 0, 1, 1),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: widget.alignment,
                child: IgnorePointer(
                  // 显形过半才可命中：隐形态的弹窗不得吃掉遮罩点击。
                  ignoring: _hidden || surface < 0.6,
                  child: Transform.scale(
                    scale: 0.965 + 0.035 * surface,
                    child: Transform.translate(
                      offset: widget.entryFrom * 24.0 * (1 - surface),
                      child: Opacity(
                        opacity: surface,
                        child: RepaintBoundary(
                          key: _boundaryKey,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }

  Rect? get _dialogRect {
    final ro = _boundary;
    if (ro == null || !ro.hasSize || ro.size.isEmpty) return null;
    return ro.localToGlobal(Offset.zero) & ro.size;
  }

  /// pop 请求（遮罩/ESC/关闭钮/取消/保存……）：走粒子化退场后放行。
  /// 光束链路（dissolve.played）与重复请求直接放行。
  void _onPopRequest(T? result) async {
    if (_allowPop) return;
    if (_exiting) {
      // 已在退场（截图/舞台中）：直接放行，绝不再开第二场。
      _forcePop(result);
      return;
    }
    _exiting = true; // 一次性闭锁：此后入场舞台保持终态（绝不倒放）
    if (widget.dissolve?.played == true) {
      _forcePop(result);
      return;
    }
    final ro = _boundary;
    final rect = _dialogRect;
    if (ro == null || rect == null) return _forcePop(result);
    try {
      final image = await ro.toImage(pixelRatio: 1.0);
      final bytes = await image.toByteData();
      if (bytes == null) {
        image.dispose();
        return _forcePop(result);
      }
      if (!mounted) {
        image.dispose();
        return;
      }
      final kind =
          result != null ? DialogExitKind.burst : DialogExitKind.scatter;
      final data = sampleDissolve(
        image: image,
        rgba: bytes.buffer.asUint8List(),
        dialogRect: rect,
        launchFrom: rect.center,
      );
      final overlay = Overlay.maybeOf(context, rootOverlay: true);
      if (overlay == null) {
        image.dispose();
        return _forcePop(result);
      }
      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => DialogExitStage(
          data: data,
          kind: kind,
          onDone: () {
            if (entry.mounted) entry.remove();
            image.dispose();
          },
        ),
      );
      overlay.insert(entry);
      // 顺序关键：舞台先入根 Overlay（原图顶住画面），同帧隐藏弹窗
      // 表面、放行 pop——视觉上弹窗「原地变成粒子」。
      setState(() => _hidden = true);
      _forcePop(result);
    } catch (_) {
      _forcePop(result); // 截图异常：静默退回普通关闭
    }
  }

  void _forcePop(T? result) {
    if (!mounted || _allowPop) return;
    setState(() => _allowPop = true);
    Navigator.of(context).pop(result);
  }
}
