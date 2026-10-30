import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';
import 'widgets/floating_nav_rail.dart';

/// 主框架。
///
/// 桌面（≥900）：**纯浮层导航**——分类菜单（[FloatingNavRail]）悬浮在
/// 内容上方，完全不参与页面宽度分配；收起时只留左上一枚入口按钮。
/// 总览页（'/'，整页深空仪表盘）全出血：背景铺满窗口；其余页面左缘
/// 预留 76px 给收起的入口。菜单未固定时：**点击外部吸收首击**（全屏
/// 透明屏障只负责收起，不再让这一击穿透激活下方按钮——与快捷菜单
/// 暗纱一致），按 Escape 同样关闭，关闭后键盘焦点回到入口。
/// 手机：底部导航不变。
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.body});

  final Widget body;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  bool _railExpanded = false;
  bool _railPinned = false;
  Timer? _autoCollapse;

  final FocusNode _entryFocus = FocusNode(debugLabel: 'nav-entry');
  final FocusNode _shellKeys = FocusNode(debugLabel: 'home-shell-keys');

  @override
  void dispose() {
    _autoCollapse?.cancel();
    _entryFocus.dispose();
    _shellKeys.dispose();
    super.dispose();
  }

  void _toggleRail() {
    setState(() => _railExpanded = !_railExpanded);
    if (_railExpanded) {
      _autoCollapse?.cancel();
    } else {
      _returnFocusToEntry();
    }
  }

  void _closeRail() {
    if (!mounted) return;
    if (!_railExpanded) return;
    setState(() => _railExpanded = false);
    _returnFocusToEntry();
  }

  void _returnFocusToEntry() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_railExpanded) _entryFocus.requestFocus();
    });
  }

  void _togglePinned() {
    setState(() {
      _railPinned = !_railPinned;
      if (_railPinned) _railExpanded = true;
    });
  }

  void _navigate(String path) {
    context.go(path);
    // 瞬态模式（未固定）：跳转完成后轻顿一下再收起，让页面过渡先起势。
    if (!_railPinned) {
      _autoCollapse?.cancel();
      _autoCollapse = Timer(const Duration(milliseconds: 420), () {
        if (mounted && !_railPinned) setState(() => _railExpanded = false);
      });
    }
  }

  // ── 「点击外部关闭」：全屏透明屏障吸收首击 ──
  // 屏障位于内容之上、菜单之下：菜单展开（未固定）时，点外部只收起
  // 菜单，这一击不会穿透激活下方按钮（曾导致收起导航的同时误开添加
  // 菜单）。菜单本身在屏障之上，正常可点。

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent e) {
    if (e is KeyDownEvent &&
        e.logicalKey == LogicalKeyboardKey.escape &&
        _railExpanded &&
        !_railPinned) {
      _closeRail();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    if (wide) {
      final location = GoRouterState.of(context).matchedLocation;
      // 总览页全出血（深空背景铺满窗口）；其余页面左缘给收起的入口留位。
      final bodyPadding = EdgeInsets.only(left: location == '/' ? 0 : 76.0);
      return Scaffold(
        // Focus.onKeyEvent 挂在整棵子树上：任何后代持有焦点时按 Escape
        // 都会冒泡到这里（业务弹窗在根 Navigator，不受影响）。
        body: Focus(
          focusNode: _shellKeys,
          autofocus: true,
          onKeyEvent: _onKeyEvent,
          child: Stack(
            children: [
              Padding(padding: bodyPadding, child: widget.body),
              // 收起屏障：吸收首击（在内容之上、菜单之下）。
              if (_railExpanded && !_railPinned)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _closeRail,
                    child: const SizedBox.expand(),
                  ),
                ),
              Positioned(
                left: 16,
                // 让出顶部窗口栏（WindowChrome 顶衬垫）：红绿灯与拖拽条
                // 的保留区不与导航入口叠压。
                top: MediaQuery.paddingOf(context).top + 14,
                child: FloatingNavRail(
                  expanded: _railExpanded,
                  pinned: _railPinned,
                  onToggleExpanded: _toggleRail,
                  onTogglePinned: _togglePinned,
                  onNavigate: _navigate,
                  entryFocusNode: _entryFocus,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final location = GoRouterState.of(context).matchedLocation;
    final inPrimary = NavItems.primary.any((i) => navMatches(location, i.path));
    final currentIndex = inPrimary
        ? NavItems.primary.indexWhere((i) => navMatches(location, i.path))
        : NavItems.primary.length; // "更多"承载全部次要目的地
    return Scaffold(
      body: widget.body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) {
          if (i < NavItems.primary.length) {
            context.go(NavItems.primary[i].path);
          } else {
            _openMore(context);
          }
        },
        destinations: [
          for (final i in NavItems.primary)
            NavigationDestination(
              icon: Icon(i.icon),
              selectedIcon: Icon(i.selected),
              label: i.label,
            ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: '更多',
          ),
        ],
      ),
    );
  }

  /// 次要目的地弹层：两列图标入口，当前页高亮。
  Future<void> _openMore(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final scheme = Theme.of(context).colorScheme;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  '更多',
                  style: Theme.of(
                    sheetCtx,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < NavItems.secondary.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpace.gap),
                    Expanded(
                      child: _MoreTile(
                        item: NavItems.secondary[i],
                        active: navMatches(
                          location,
                          NavItems.secondary[i].path,
                        ),
                        activeColor: scheme.primary,
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          context.go(NavItems.secondary[i].path);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.item,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final ({IconData icon, String label, String path}) item;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active ? activeColor : theme.hintColor;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.chip),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.chip),
          color: active ? activeColor.withValues(alpha: 0.10) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 26, color: color),
            const SizedBox(height: 6),
            Text(
              item.label,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
