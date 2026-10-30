import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 容器展开转场（container transform）：首页卡片 → 对应页面。
///
/// 频率档：偶发（页面级导航，非键盘高频）。目的：**空间连续**——页面
/// 从被点卡片的矩形「生长」出来、返回时收缩回卡片，而不是凭空弹出一
/// 个新页面。仅动 clip 与 opacity（GPU 友好）；曲线 M3 强调
/// easeInOutCubicEmphasized，去程 420ms / 回程 320ms。「减少动画」时
/// 退回普通淡入转场。
///
/// 用法：卡片侧 `HeroLaunch.go(context, '/reports', cardKey)`；路由侧
/// `HeroLaunch.takeFor(path)` 取来源矩形，交给 [HeroGrow]。
class HeroLaunch {
  HeroLaunch._();

  static _HeroSource? _last;

  /// 从 [key] 指向的卡片发起导航：记录其全局矩形后跳转。
  /// 卡片不可测量（已卸载）时退化为普通跳转。
  static void go(BuildContext context, String path, GlobalKey key) {
    final ro = key.currentContext?.findRenderObject();
    if (ro is RenderBox && ro.attached && ro.hasSize) {
      _last = _HeroSource(
        path: path,
        rect: ro.localToGlobal(Offset.zero) & ro.size,
        at: DateTime.now(),
      );
    } else {
      _last = null;
    }
    context.go(path);
  }

  /// 路由 pageBuilder 调用：有新鲜（<1.5s）的同路径来源才返回。
  /// 陈旧来源（期间发生过别的导航）不再套用，避免从错误位置展开。
  static Rect? takeFor(String path) {
    final s = _last;
    if (s == null) return null;
    if (s.path != path ||
        DateTime.now().difference(s.at) > const Duration(milliseconds: 1500)) {
      _last = null;
      return null;
    }
    return s.rect;
  }
}

class _HeroSource {
  const _HeroSource({
    required this.path,
    required this.rect,
    required this.at,
  });
  final String path;
  final Rect rect;
  final DateTime at;
}

/// 页面从 [from] 矩形生长为全屏（或反向收缩回去）。
///
/// 组合：外层 ClipRRect 从卡片圆角 16 平到 0，裁剪矩形从来源卡片插值到
/// 全屏；内层内容在展开的后 60% 淡入（先见「容器」再见「内容」，
/// 与 Material container transform 的分层一致）。背景侧由上一页自身
/// 的淡出转场负责，无需额外遮罩。
class HeroGrow extends StatelessWidget {
  const HeroGrow({super.key, required this.animation, required this.from, required this.child});

  final Animation<double> animation;
  final Rect from;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubicEmphasized,
      reverseCurve: Curves.easeInOutCubicEmphasized.flipped,
    );
    // Navigator 铺满无边框窗口，全局坐标即转场坐标。
    final screen = MediaQuery.sizeOf(context);
    final fromRel = RelativeRect.fromSize(from, screen);
    // 内容淡入：展开前 40% 只见容器生长，后 60% 内容浮现。
    final contentIn = CurvedAnimation(
      parent: curved,
      curve: const Interval(0.4, 1, curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, page) {
        final t = curved.value;
        final rect = RelativeRect.lerp(fromRel, RelativeRect.fill, t)!;
        return Stack(
          children: [
            Positioned.fromRelativeRect(
              rect: rect,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16 * (1 - t)),
                child: Opacity(opacity: contentIn.value, child: page),
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}
