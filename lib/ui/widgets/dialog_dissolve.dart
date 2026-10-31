import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'dissolve_stage.dart';

/// 目标落点解析：经纬度 → 全局屏幕坐标（地球投影；null = 暂不可见）。
typedef DissolveTargetOf = Offset? Function(double lat, double lon);

/// 经纬度钩子（光束出鞘/到达时刻，地球侧据此飞行与点亮标记）。
typedef DissolveLocationHook = void Function(double lat, double lon);

/// 弹窗粒子化保存（公共组件）。
///
/// 任意弹窗包一层 [DissolveCapture]，保存成功后调用
/// [DissolveController.dissolveAndPop] 取代普通 `Navigator.pop`：
/// 弹窗被实时截图并采样成**数千颗小粒子**（数量随弹窗面积自适应，
/// 以后弹窗改尺寸/改内容都自动跟随）——原图与粒子云无缝交接 → 自
/// 保存按钮碎裂四散 → 汇成一道光束飞向 [targetOf] 给出的落点
/// （地球同时在转）→ 到达汇聚成标志并闪耀。时间轴与视觉见
/// [dissolve_stage.dart]。
///
/// 「减少动画」或截图失败时返回 false，调用方走普通 pop，零降级感。
class DissolveController extends ChangeNotifier {
  DissolveController({this.targetOf, this.onLaunch, this.onArrive});

  /// 落点解析（一般由地球实例提供投影）。null 时光束飞向屏幕中心。
  DissolveTargetOf? targetOf;

  /// 光束出鞘（0.55s）：地球开始飞往落点，与彗头同步到达。
  DissolveLocationHook? onLaunch;

  /// 光束到达（1.70s）：重载标记——新资产的光点在闪耀光效下点亮。
  DissolveLocationHook? onArrive;

  _DissolveCaptureState? _shell;
  bool _hidden = false;
  DissolveCaptureData? _prepared;

  /// 本次弹窗是否已走粒子化（外层据此跳过即时的标记重载，避免剧透）。
  bool played = false;

  /// 弹窗内容是否已被粒子云接管（捕获壳消费，隐藏原内容）。
  bool get contentHidden => _hidden;

  void _attach(_DissolveCaptureState shell) => _shell = shell;

  void _detach(_DissolveCaptureState shell) {
    if (_shell == shell) _shell = null;
  }

  /// 预备粒子化：保存按钮按下的**同一帧**调用——截图与采样和落库等
  /// 异步工作并行完成；落库结束的那一帧 [dissolveAndPop] 直接起跳，
  /// 消除「保存后画面先静止一拍再爆开」的卡顿（2026-10 用户指令：
  /// 每个阶段的开始/结束都要流畅对得上）。重复调用/已 played 无效；
  /// 不具备条件（未挂载/减少动画/截图失败）静默跳过。
  Future<void> prepare({Offset? origin}) async {
    if (played || _prepared != null) return;
    final shell = _shell;
    if (shell == null || !shell.mounted || shell.reduceMotion) return;
    _prepared ??= await shell.capture(
      origin ?? shell.boundaryCenter,
    );
  }

  /// 截图 → 采样粒子 → 舞台接管显示 → 隐藏弹窗内容并 pop 路由。
  ///
  /// [origin] 碎裂起点兼光束起点（保存按钮中心，全局坐标；缺省用
  /// 弹窗中心）。返回 false 表示不具备粒子化条件（未挂载 / 截图
  /// 失败 / 系统减少动画），调用方应普通 pop。
  Future<bool> dissolveAndPop({
    Offset? origin,
    required double lat,
    required double lon,
  }) async {
    final shell = _shell;
    if (shell == null || !shell.mounted || shell.reduceMotion) return false;
    var data = _prepared ?? await shell.capture(
      origin ?? shell.boundaryCenter,
    );
    _prepared = null;
    if (data == null) return false;
    played = true;
    // 顺序关键：舞台先入根 Overlay（静止粒子云顶住画面），同帧再
    // 隐藏弹窗内容、pop 路由——视觉上弹窗「原地变成粒子」。
    _hidden = true;
    notifyListeners();
    shell.startStage(data, lat: lat, lon: lon);
    return true;
  }
}

/// 弹窗捕获壳：把任意弹窗内容包进 RepaintBoundary（粒子化取景框）。
/// 内容隐藏由控制器驱动（截图完成后 Opacity 置 0，路由照常离场）。
class DissolveCapture extends StatefulWidget {
  const DissolveCapture({
    super.key,
    required this.controller,
    required this.child,
  });

  final DissolveController controller;
  final Widget child;

  @override
  State<DissolveCapture> createState() => _DissolveCaptureState();
}

class _DissolveCaptureState extends State<DissolveCapture> {
  final GlobalKey _boundaryKey = GlobalKey(debugLabel: 'dissolve-boundary');
  bool _reduce = false;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    super.dispose();
  }

  RenderRepaintBoundary? get boundary =>
      _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

  bool get reduceMotion => _reduce;

  Offset get boundaryCenter {
    final ro = boundary;
    if (ro == null || !ro.hasSize) return Offset.zero;
    return ro.localToGlobal(ro.size.center(Offset.zero));
  }

  /// 截图并采样成粒子云（失败返回 null；调用方自行 dispose data.image）。
  Future<DissolveCaptureData?> capture(Offset launchFrom) async {
    final ro = boundary;
    if (ro == null || !ro.hasSize || ro.size.isEmpty) return null;
    try {
      final image = await ro.toImage(pixelRatio: 1.0);
      final bytes = await image.toByteData();
      if (bytes == null) {
        image.dispose();
        return null;
      }
      return sampleDissolve(
        image: image,
        rgba: bytes.buffer.asUint8List(),
        dialogRect: ro.localToGlobal(Offset.zero) & ro.size,
        launchFrom: launchFrom,
      );
    } catch (_) {
      return null; // 截图/采样异常：静默退回普通关闭
    }
  }

  /// 挂舞台到根 Overlay（覆盖弹窗路由与整页），随后 pop 弹窗路由。
  /// 舞台结束后摘除 OverlayEntry 并释放截图。
  void startStage(
    DissolveCaptureData data, {
    required double lat,
    required double lon,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      data.image.dispose();
      Navigator.of(context).pop();
      return;
    }
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => DissolveStage(
        data: data,
        targetOf: () => widget.controller.targetOf?.call(lat, lon),
        onLaunch: () => widget.controller.onLaunch?.call(lat, lon),
        onArrive: () => widget.controller.onArrive?.call(lat, lon),
        onDone: () {
          if (entry.mounted) entry.remove();
          data.image.dispose();
        },
      ),
    );
    overlay.insert(entry);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _boundaryKey,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) => Opacity(
          opacity: widget.controller.contentHidden ? 0 : 1,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
