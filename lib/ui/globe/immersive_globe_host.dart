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
/// - 「减少动画」时降为 60ms 直达（功能保留，动效取消）；
/// - [globeChrome] 是槽位左上角的小标签，随沉浸淡出。
class ImmersiveGlobeHost extends StatefulWidget {
  const ImmersiveGlobeHost({
    super.key,
    required this.builder,
    required this.globeBuilder,
    this.globeChrome,
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

  void _onImmersed(bool active) {
    if (!mounted) return;
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
                // 每帧重测槽位（窗口尺寸/布局可能变化）；测不到时
                // 补一帧 postFrameCallback 触发重量。
                final measured = _measureSlot() ?? _slotRect;
                if (measured == null) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _slotRect == null) setState(() {});
                  });
                  return const SizedBox.shrink(); // 槽位未就绪：暂不显示
                }
                if (measured != _slotRect) {
                  _slotRect = measured;
                  // build 期测量发生在布局之前——窗口尺寸刚变化时拿到
                  // 的是上一帧的槽位（旧位置），且此后无人再触发重建，
                  // 地球会停在偏位直到下一次交互。这里在布局完成后复
                  // 测一次，仍有偏差就再排一帧，直至完全跟住槽位。
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    final next = _measureSlot();
                    if (mounted && next != null && next != _slotRect) {
                      setState(() {});
                    }
                  });
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
