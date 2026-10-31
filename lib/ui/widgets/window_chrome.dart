import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../l10n/app_localizations.dart';

/// 桌面窗口框体：无边框窗口的「隐形标题条」+ macOS 风格红绿灯按钮。
///
/// - 顶部 36px 是窗口栏（拖拽条 + 红绿灯）的保留区：以 **MediaQuery
///   顶衬垫**的形式从界面里让出来——AppBar、悬浮操作层等随衬垫下移，
///   不再与红绿灯重叠；栏体本身透明，深空底照常透出；
/// - 拖拽条按**原生标题栏语义**工作：条带内任何按下都归属窗口（拖动
///   /双击最大化）。红绿灯自带不透明命中区且位于条带之上，自行拦截
///   自身的点击——不做「下方有交互组件就让位」的启发式，那种判定在
///   地球手势层铺满整页的首页会让拖拽条永远失效；
/// - 右上角 [TrafficLights]：12px 三色圆点、8px 间距（紧凑如 macOS），
///   组内悬停显符号，窗口失焦整体降灰；按钮顺序按 Windows 习惯
///   最小化 → 最大化 → 关闭（配色保留 macOS 三色圆点），
/// - [enabled] 由 `main()` 在桌面端 `windowManager` 初始化成功后置
///   true；测试/移动端保持 false——本组件直通子树，零开销零插件调用。
class WindowChrome extends StatelessWidget {
  const WindowChrome({super.key, required this.child});

  /// 自绘窗口控件是否生效（main() 桌面初始化成功后置 true）。
  static bool enabled = false;

  /// 窗口栏高度（拖拽条/红绿灯的保留区，px）。
  static const barHeight = _TopDragStripState.stripHeight;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final mq = MediaQuery.of(context);
    return Stack(
      children: [
        MediaQuery(
          data: mq.copyWith(
            padding: mq.padding.copyWith(
              top: math.max(mq.padding.top, barHeight),
            ),
          ),
          child: child,
        ),
        const Positioned(top: 0, left: 0, right: 0, child: _TopDragStrip()),
        const Positioned(top: 0, right: 0, child: TrafficLights()),
      ],
    );
  }
}

/// 顶部拖拽条：原生标题栏语义——条带内任何按下都接管为窗口拖动，
/// 双击最大化/还原。红绿灯（条带之上、不透明命中区）自行拦截自身
/// 的点击，不经过本条。
class _TopDragStrip extends StatefulWidget {
  const _TopDragStrip();

  @override
  State<_TopDragStrip> createState() => _TopDragStripState();
}

class _TopDragStripState extends State<_TopDragStrip> {
  static const stripHeight = 36.0;
  DateTime? _lastDown;

  void _onPointerDown(PointerDownEvent e) {
    if (e.buttons != kPrimaryButton) return;
    if (e.position.dy > stripHeight) return;
    final now = DateTime.now();
    if (_lastDown != null &&
        now.difference(_lastDown!) < const Duration(milliseconds: 400)) {
      _lastDown = null;
      _toggleMaximize();
    } else {
      _lastDown = now;
      _guarded(windowManager.startDragging);
    }
  }

  void _toggleMaximize() async {
    try {
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    } catch (_) {
      /* 插件不可用时忽略 */
    }
  }

  void _guarded(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      /* 插件不可用时忽略 */
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: stripHeight,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onPointerDown,
      ),
    );
  }
}

/// 窗口三色钮（macOS 配色圆点），顺序按 Windows：最小化 #FEBC2E /
/// 最大化 #28C840 / 关闭 #FF5F57。
/// 组内任一悬停 → 三钮同时显现符号；窗口失焦 → 整体降灰（还原聚焦
/// 恢复）。12px 圆点 + 8px 间距，命中区放大到 26px 便于点按。
class TrafficLights extends StatefulWidget {
  const TrafficLights({super.key});

  @override
  State<TrafficLights> createState() => _TrafficLightsState();
}

class _TrafficLightsState extends State<TrafficLights> with WindowListener {
  bool _hoverAny = false;
  bool _focused = true;
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initWindowStates();
  }

  Future<void> _initWindowStates() async {
    try {
      final focused = await windowManager.isFocused();
      final maximized = await windowManager.isMaximized();
      if (mounted) {
        setState(() {
          _focused = focused;
          _maximized = maximized;
        });
      }
    } catch (_) {
      /* 插件不可用（测试）保持默认 */
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowBlur() => setState(() => _focused = false);

  @override
  void onWindowFocus() => setState(() => _focused = true);

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hoverAny = true),
      onExit: (_) => setState(() => _hoverAny = false),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Light(
              color: const Color(0xFFFEBC2E),
              hoverAny: _hoverAny,
              focused: _focused,
              label: t.wdgMinimize,
              glyph: _Glyph.minimize,
              onTap: () => _guarded(windowManager.minimize),
            ),
            const SizedBox(width: 8),
            _Light(
              color: const Color(0xFF28C840),
              hoverAny: _hoverAny,
              focused: _focused,
              label: _maximized ? t.wdgRestoreDown : t.wdgMaximize,
              glyph: _maximized ? _Glyph.restore : _Glyph.zoom,
              onTap: () async {
                try {
                  if (_maximized) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                } catch (_) {
                  /* 插件不可用时忽略 */
                }
              },
            ),
            const SizedBox(width: 8),
            _Light(
              color: const Color(0xFFFF5F57),
              hoverAny: _hoverAny,
              focused: _focused,
              label: t.wdgClose,
              glyph: _Glyph.close,
              onTap: () => _guarded(windowManager.close),
            ),
          ],
        ),
      ),
    );
  }

  void _guarded(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      /* 插件不可用时忽略 */
    }
  }
}

/// 符号类型：× / − / 缩放双三角 / 还原双叠框。
enum _Glyph { close, minimize, zoom, restore }

class _Light extends StatefulWidget {
  const _Light({
    required this.color,
    required this.hoverAny,
    required this.focused,
    required this.label,
    required this.glyph,
    required this.onTap,
  });

  final Color color;
  final bool hoverAny; // 组内悬停：三钮同时显符号（macOS 习惯）
  final bool focused;
  final String label; // 无障碍名 + 自绘悬停标签（不依赖 Overlay：
  // WindowChrome 在 MaterialApp.builder 层，位于 Navigator/Overlay 之外，
  // Tooltip 需要 Overlay，debug 下构建即断言、release 下悬停出错）
  final _Glyph glyph;
  final VoidCallback onTap;

  @override
  State<_Light> createState() => _LightState();
}

class _LightState extends State<_Light> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final shown = widget.focused
        ? widget.color
        : const Color(0xFF454B54); // 失焦降灰（macOS 行为）
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: SizedBox(
              width: 30, // 命中区放大；视觉是 14px 圆点
              height: 24,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hover && widget.focused
                            ? Color.alphaBlend(
                                Colors.black.withValues(alpha: 0.12),
                                shown,
                              )
                            : shown,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        opacity: widget.hoverAny && widget.focused ? 1 : 0,
                        child: CustomPaint(
                          painter: _GlyphPainter(widget.glyph),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                  // 悬停标签：画在自己的层里（下方 22px 小黑条），不入 Overlay。
                  Positioned(
                    top: 26,
                    left: -14,
                    width: 58,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        opacity: _hover ? 1 : 0,
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xE610161D),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFE7ECF2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 圆点内符号：深色细笔（同 macOS），zoom = 对角双三角，restore = 双叠框。
class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph);

  final _Glyph glyph;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x8C000000)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final c = size.center(Offset.zero);
    switch (glyph) {
      case _Glyph.close:
        canvas.drawLine(
          c + const Offset(-2.4, -2.4),
          c + const Offset(2.4, 2.4),
          paint,
        );
        canvas.drawLine(
          c + const Offset(2.4, -2.4),
          c + const Offset(-2.4, 2.4),
          paint,
        );
      case _Glyph.minimize:
        canvas.drawLine(
          c + const Offset(-2.4, 0),
          c + const Offset(2.4, 0),
          paint,
        );
      case _Glyph.zoom:
        // 双三角：左上尖角向内、右下尖角向内（macOS 缩放符号）。
        final fill = Paint()..color = const Color(0x8C000000);
        final tri = Path()
          ..moveTo(c.dx - 3.6, c.dy - 1.0)
          ..lineTo(c.dx - 1.0, c.dy - 1.0)
          ..lineTo(c.dx - 3.6, c.dy - 3.6)
          ..close();
        canvas.drawPath(tri, fill);
        final tri2 = Path()
          ..moveTo(c.dx + 3.6, c.dy + 1.0)
          ..lineTo(c.dx + 1.0, c.dy + 1.0)
          ..lineTo(c.dx + 3.6, c.dy + 3.6)
          ..close();
        canvas.drawPath(tri2, fill);
      case _Glyph.restore:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: c + const Offset(-1.3, -1.3),
              width: 3.9,
              height: 3.9,
            ),
            const Radius.circular(0.7),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: c + const Offset(1.6, 1.6),
              width: 3.9,
              height: 3.9,
            ),
            const Radius.circular(0.7),
          ),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.glyph != glyph;
}
