import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;

/// 沉浸状态回调：true = 交互进行中（整页让位），false = 空闲恢复。
typedef GlobeImmersiveListener = void Function(bool immersed);

/// 沉浸式地球宿主：地球平时住在布局的「槽位」（[slotKey] 标记的
/// SizedBox）里；地球交互进行中（[globeBuilder] 返回的 AssetGlobe 通过
/// onImmersionChanged 上报），地球从槽位矩形平滑扩张到整页全屏，
/// [builder] 产出的其余页面（卡片、标题等）同步淡出并轻微收缩让位；
/// 交互结束回到空闲后，再缓慢收回槽位、页面复原。
///
/// - 扩张 760ms / 收回 1100ms，M3 强调曲线 easeInOutCubicEmphasized
///   （起步缓、中段快、收势长而柔——「有去有回、去快回慢」更细腻）；
/// - 地球用同一个实例整体平移缩放，视角/缩放状态全程连续，无跳变；
/// - [pinned]：外部钉住的沉浸（右上角「清屏地球」钮）——true 时前进
///   到全屏，且**忽略地球侧的空闲退出上报**（钉住的清屏不因空闲自转
///   恢复而消退）；翻回 false 时立即收回；
/// - 「减少动画」时降为 60ms 直达（功能保留，动效取消）；
/// - [globeChrome] 是槽位左上角的小标签，随沉浸淡出。
class ImmersiveGlobeHost extends StatefulWidget {
  const ImmersiveGlobeHost({
    super.key,
    required this.builder,
    required this.globeBuilder,
    this.globeChrome,
    this.pinned = false,
  });

  /// 页面主体。接收沉浸进度动画（0=常态 1=全沉浸，已含曲线）与槽位 key；
  /// 卡片列等元素建议包 FadeTransition(ReverseAnimation(immersion)) 让位。
  final Widget Function(
    BuildContext,
    Animation<double> immersion,
    GlobalKey slotKey,
  )
  builder;

  /// 构造地球（宿主负责把沉浸回调接进来）。
  final Widget Function(GlobeImmersiveListener onImmersion) globeBuilder;

  /// 外部钉住的沉浸：true = 卡片清场、地球占满整窗，忽略空闲退出；
  /// false = 交还地球自管（见类注释）。
  final bool pinned;

  final Widget? globeChrome;

  @override
  State<ImmersiveGlobeHost> createState() => _ImmersiveGlobeHostState();
}

class _ImmersiveGlobeHostState extends State<ImmersiveGlobeHost>
    with SingleTickerProviderStateMixin {
  final GlobalKey _slotKey = GlobalKey(debugLabel: 'globe-slot');

  late final AnimationController _immersion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
    reverseDuration: const Duration(milliseconds: 1100),
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _immersion,
    curve: Curves.easeInOutCubicEmphasized,
    reverseCurve: Curves.easeInOutCubicEmphasized.flipped,
  );

  Rect? _slotRect;
  bool _reduce = false;
  bool _remeasureQueued = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce != _reduce) {
      _reduce = reduce;
      _immersion.duration = Duration(milliseconds: reduce ? 60 : 760);
      _immersion.reverseDuration = Duration(milliseconds: reduce ? 60 : 1100);
    }
  }

  @override
  void dispose() {
    _immersion.dispose();
    _curve.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ImmersiveGlobeHost old) {
    super.didUpdateWidget(old);
    // 钉住/解除由按钮直接驱动（与地球侧上报互补，controller 可从当前
    // 值平滑续走）。
    if (old.pinned != widget.pinned) {
      widget.pinned ? _immersion.forward() : _immersion.reverse();
    }
  }

  void _onImmersed(bool active) {
    if (!mounted) return;
    // 钉住的清屏不因地球空闲自转恢复而消退。
    if (!active && widget.pinned) return;
    active ? _immersion.forward() : _immersion.reverse();
  }

  /// 槽位矩形（宿主坐标系）。布局未就绪时返回 null。
  Rect? _measureSlot() {
    final slotRo = _slotKey.currentContext?.findRenderObject();
    final hostRo = context.findRenderObject();
    if (slotRo is RenderBox &&
        slotRo.hasSize &&
        hostRo is RenderBox &&
        hostRo.hasSize) {
      final tl = slotRo.localToGlobal(Offset.zero, ancestor: hostRo);
      return tl & slotRo.size;
    }
    return null;
  }

  /// 布局完成后补测槽位（去重排队）。窗口缩放/断点切换时，build 期
  /// 测到的是**上一帧**的布局：若与 [_slotRect] 恰好相同则不会再有
  /// 任何东西触发重测，地球会冻结在旧槽位（只在新一轮交互才恢复）。
  /// 因此每次 build 无条件排一帧补测：测得的最新槽位若有出入就
  /// setState 更新并再排，直至完全跟住。
  void _scheduleRemeasure() {
    if (_remeasureQueued) return;
    _remeasureQueued = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _remeasureQueued = false;
      if (!mounted) return;
      final next = _measureSlot();
      if (next != null && next != _slotRect) {
        setState(() => _slotRect = next);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chrome = widget.builder(context, _curve, _slotKey);
        final full = Offset.zero & constraints.biggest;
        return Stack(
          fit: StackFit.expand,
          children: [
            chrome,
            AnimatedBuilder(
              animation: _immersion,
              child: Stack(
                children: [
                  Positioned.fill(child: widget.globeBuilder(_onImmersed)),
                  if (widget.globeChrome != null)
                    Positioned(
                      top: 14,
                      left: 16,
                      child: FadeTransition(
                        opacity: ReverseAnimation(_curve),
                        child: widget.globeChrome,
                      ),
                    ),
                ],
              ),
              builder: (context, child) {
                // 先吃 build 期测量（常态下已足够），再无条件排一帧
                // 布局后补测兜住窗口缩放的一帧滞后（见方法注释）。
                final measured = _measureSlot();
                if (measured != null && measured != _slotRect) {
                  _slotRect = measured;
                }
                _scheduleRemeasure();
                if (_slotRect == null) {
                  return const SizedBox.shrink(); // 槽位未就绪：暂不显示
                }
                final rect = Rect.lerp(_slotRect!, full, _curve.value)!;
                return Positioned.fromRect(rect: rect, child: child!);
              },
            ),
          ],
        );
      },
    );
  }
}
