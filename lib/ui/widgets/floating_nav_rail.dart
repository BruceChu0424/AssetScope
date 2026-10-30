import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'common.dart';

/// 悬浮分类菜单（桌面端）：真正覆盖在内容上方的浮层，不参与页面宽度分配。
///
/// 动画沿用旧版「入口原地展宽」形态：收起态是左上一枚 48px 圆形品牌
/// 按钮（呼吸微光），点按后**按钮原地展宽成面板**（48→212px，M3 强调
/// 曲线 360ms，收起 240ms；条目按 5% 阶梯浮现，条目区自头部向下生长）
/// ——controller 驱动，快速连点平滑反向衔接。
///
/// 浮层质感：面板是半透明深色磨砂玻璃——外围先有**两层羽化模糊环**
/// （-22/-10px 阶梯 BackdropFilter，由外向内逐级加深）再接面板自身
/// 的局部背景模糊 + 钢蓝辉光 + 悬浮阴影，整体像悬停在一团柔光上；
/// 顶缘内侧一道渐隐高光；面板四周有低密度蓝白粒子与散射微光
/// （[MenuAmbiencePainter]，仅可见时驱动 Ticker，随展开进度显现）。
///
/// 图钉固定 = 面板保持展开，仍属覆盖浮层；未固定时导航跳转后由
/// [HomeShell] 自动收起、点击外部屏障或 Escape 关闭（首击被屏障吸
/// 收），关闭后焦点回到入口。
class FloatingNavRail extends StatefulWidget {
  const FloatingNavRail({
    super.key,
    required this.expanded,
    required this.pinned,
    required this.onToggleExpanded,
    required this.onTogglePinned,
    required this.onNavigate,
    required this.entryFocusNode,
  });

  final bool expanded;
  final bool pinned;
  final VoidCallback onToggleExpanded;
  final VoidCallback onTogglePinned;
  final ValueChanged<String> onNavigate;
  final FocusNode entryFocusNode;

  @override
  State<FloatingNavRail> createState() => _FloatingNavRailState();
}

class _FloatingNavRailState extends State<FloatingNavRail>
    with TickerProviderStateMixin {
  /// 展开进度（0=收起 1=展开）。controller 可中断反向，快速连点平滑衔接。
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
    reverseDuration: const Duration(milliseconds: 240),
    value: widget.expanded ? 1 : 0,
  );

  static const _curve = Curves.easeInOutCubicEmphasized;

  late final CurvedAnimation _grow = CurvedAnimation(
    parent: _anim,
    curve: _curve,
    reverseCurve: _curve.flipped,
  );

  /// 收起态入口的呼吸光环（2.4s 余弦循环；仅收起时可见）。
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  /// 菜单粒子时钟（仅面板可见时运转；减少动画时不启）。
  /// duration 必须显式给：repeat() 无周期会在展开完成回调里抛断言。
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  final Stopwatch _ambientClock = Stopwatch();
  bool _ready = false;
  bool _reduce = false;

  @override
  void initState() {
    super.initState();
    _anim.addStatusListener(_onAnimStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery 不能在 initState 读；首次依赖就绪后定档光环/粒子模式。
    if (!_ready) {
      _ready = true;
      _reduce = MediaQuery.disableAnimationsOf(context);
      if (_reduce) {
        _glow.stop();
        _glow.value = 0.25;
        _anim.value = widget.expanded ? 1 : 0;
      }
      _syncAmbient();
    }
  }

  @override
  void didUpdateWidget(FloatingNavRail old) {
    super.didUpdateWidget(old);
    if (old.expanded != widget.expanded) {
      if (_reduce || MediaQuery.disableAnimationsOf(context)) {
        _anim.value = widget.expanded ? 1 : 0;
        _syncAmbient();
      } else if (widget.expanded) {
        _anim.forward();
      } else {
        _anim.reverse();
      }
    }
  }

  void _onAnimStatus(AnimationStatus status) {
    // 动画到站后同步粒子时钟：展开完毕持续运转，收起完毕停表。
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      _syncAmbient();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _grow.dispose();
    _glow.dispose();
    _ambient.dispose();
    super.dispose();
  }

  void _syncAmbient() {
    final visible = _anim.value > 0 || _anim.isAnimating;
    if (visible && !_reduce) {
      if (!_ambient.isAnimating) {
        _ambientClock.start();
        _ambient.repeat();
      }
    } else {
      _ambient.stop();
      _ambientClock.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final location = GoRouterState.of(context).matchedLocation;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 粒子与散射光：z 序在面板之下，允许溢出面板边缘，不参与命中。
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ambient,
              builder: (context, _) => CustomPaint(
                painter: MenuAmbiencePainter(
                  t: _reduce ? 0.8 : _ambientClock.elapsedMilliseconds / 1000,
                  progress: _grow.value,
                ),
              ),
            ),
          ),
        ),
        // 羽化模糊环：两层阶梯 BackdropFilter 环绕面板四周（-22/-10px），
        // 与面板自身磨砂构成「由外向内逐级加深」的悬浮光晕——展开的导
        // 航列像悬停在一团柔光上，且与背后内容拉开层次（更清楚）。
        Positioned(
          left: -22,
          top: -22,
          right: -22,
          bottom: -22,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _grow,
              builder: (context, _) => _grow.value < 0.02
                  ? const SizedBox.shrink()
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(
                        24 + 22 * _grow.value,
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 8 * _grow.value,
                          sigmaY: 8 * _grow.value,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
            ),
          ),
        ),
        Positioned(
          left: -10,
          top: -10,
          right: -10,
          bottom: -10,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _grow,
              builder: (context, _) => _grow.value < 0.02
                  ? const SizedBox.shrink()
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(
                        24 + 14 * _grow.value,
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 16 * _grow.value,
                          sigmaY: 16 * _grow.value,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: Listenable.merge([_anim, _glow]),
          builder: (context, _) {
            final t = _grow.value;
            final width = 48.0 + 164.0 * t;
            final radius = BorderRadius.lerp(
              BorderRadius.circular(24),
              BorderRadius.circular(18),
              t,
            )!;
            final dark = theme.brightness == Brightness.dark;
            // 余弦呼吸：0→1→0 平滑往返（缓亮→缓灭→缓亮循环，无折返
            // 跳变——线性三角波会在周期末突然全亮）。
            final breath = 0.5 - 0.5 * math.cos(_glow.value * 2 * math.pi);
            return Container(
              width: width,
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  // 收起态呼吸光环：品牌色细环微光，随余弦缓慢涨落。
                  BoxShadow(
                    color: scheme.primary.withValues(
                      alpha: (0.06 + 0.24 * breath) * (1 - t),
                    ),
                    blurRadius: 8 + 12 * breath,
                    spreadRadius: 1 + 2 * breath,
                  ),
                  if (t > 0.02) ...[
                    // 展开态悬浮阴影 + 钢蓝辉光：面板像悬停在一团柔光上。
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: (dark ? 0.45 : 0.18) * t,
                      ),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color:
                          (dark
                                  ? const Color(0xFF7EA6D9)
                                  : const Color(0xFF3A6392))
                              .withValues(alpha: (dark ? 0.20 : 0.13) * t),
                      blurRadius: 44,
                      spreadRadius: 7,
                    ),
                  ],
                ],
              ),
              // 展宽过渡经过窄区，裁剪防内容画出圆角面板外；磨砂对
              // 身后真实内容做局部模糊。
              child: ClipRRect(
                borderRadius: radius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 18 + 12 * t,
                    sigmaY: 18 + 12 * t,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      // 深色磨砂玻璃：展开时更实（对比更高、文字更清
                      // 楚），外圈已由羽化模糊环负责「透」。
                      color: dark
                          ? const Color(
                              0xFF10161D,
                            ).withValues(alpha: 0.58 + 0.16 * t)
                          : Colors.white.withValues(alpha: 0.62 + 0.13 * t),
                      border: Border.all(
                        color: dark
                            ? const Color(0x33E7ECF2)
                            : const Color(0x33324A5E),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // 顶缘内侧高光：一道渐隐细亮线，帮助面板与背景分离。
                        Positioned(
                          top: 0,
                          left: 14,
                          right: 14,
                          height: 1,
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: t,
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0x00FFFFFF),
                                      Color(0x66FFFFFF),
                                      Color(0x00FFFFFF),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _header(t, theme, scheme),
                            // 面板主体自头部向下生长（顶端对齐）。
                            // 条目区固定按展开宽度（212）布局，收起时从
                            // 右侧渐隐裁掉——避免窄约束挤压行内容溢出。
                            Align(
                              alignment: Alignment.topLeft,
                              child: SizedBox(
                                width: 212,
                                child: SizeTransition(
                                  sizeFactor: _grow,
                                  alignment: Alignment.topCenter,
                                  child: FadeTransition(
                                    opacity: _grow,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Divider(
                                          height: 1,
                                          color: dark
                                              ? const Color(0x26E7ECF2)
                                              : const Color(0x1A1E2A38),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            8,
                                            8,
                                            8,
                                            10,
                                          ),
                                          // 矮窗口（<面板自然高度）时条目区
                                          // 可滚动，防溢出条。
                                          child: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                for (
                                                  var i = 0;
                                                  i < NavItems.primary.length;
                                                  i++
                                                )
                                                  _stagger(
                                                    i,
                                                    _RailTile(
                                                      icon:
                                                          navMatches(
                                                            location,
                                                            NavItems
                                                                .primary[i]
                                                                .path,
                                                          )
                                                          ? NavItems
                                                                .primary[i]
                                                                .selected
                                                          : NavItems
                                                                .primary[i]
                                                                .icon,
                                                      label: NavItems
                                                          .primary[i]
                                                          .label,
                                                      active: navMatches(
                                                        location,
                                                        NavItems
                                                            .primary[i]
                                                            .path,
                                                      ),
                                                      onTap: () =>
                                                          widget.onNavigate(
                                                            NavItems
                                                                .primary[i]
                                                                .path,
                                                          ),
                                                    ),
                                                  ),
                                                const SizedBox(height: 6),
                                                Divider(
                                                  height: 1,
                                                  indent: 12,
                                                  endIndent: 12,
                                                  color:
                                                      theme.dividerTheme.color,
                                                ),
                                                const SizedBox(height: 6),
                                                for (
                                                  var i = 0;
                                                  i < NavItems.secondary.length;
                                                  i++
                                                )
                                                  _stagger(
                                                    NavItems.primary.length + i,
                                                    _RailTile(
                                                      icon: NavItems
                                                          .secondary[i]
                                                          .icon,
                                                      label: NavItems
                                                          .secondary[i]
                                                          .label,
                                                      active: navMatches(
                                                        location,
                                                        NavItems
                                                            .secondary[i]
                                                            .path,
                                                      ),
                                                      onTap: () =>
                                                          widget.onNavigate(
                                                            NavItems
                                                                .secondary[i]
                                                                .path,
                                                          ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// 头部按钮：收起态是居中品牌标（圆形按钮观感，右下「展开」小角标），
  /// 展开态是品牌 + 分类字样 + 固定开关 + 收起箭头；随进度交叉淡入。
  /// 整个头部都是展开/收起的点击区。
  Widget _header(double t, ThemeData theme, ColorScheme scheme) {
    final dark = theme.brightness == Brightness.dark;
    return Tooltip(
      message: widget.expanded ? '收起分类菜单' : '展开分类菜单',
      child: Semantics(
        button: true,
        expanded: widget.expanded,
        label: '分类菜单',
        onTap: widget.onToggleExpanded, // 语义/键盘可直接激活（InkWell 不接键盘焦点）
        child: Focus(
          focusNode: widget.entryFocusNode,
          child: InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(18),
              bottom: Radius.circular(24 - 6 * t),
            ),
            onTap: widget.onToggleExpanded,
            child: SizedBox(
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 收起态：品牌标居中 + 右下「展开」小角标。
                  Opacity(
                    opacity: (1 - t).clamp(0.0, 1.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const BrandMark(size: 18),
                        Align(
                          alignment: const Alignment(0.95, 0.8),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.expand_more,
                              size: 10,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 展开态：品牌 + 分类字样 + 固定 + 收起箭头。
                  Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          const BrandMark(size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '分类导航',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: dark
                                  ? const Color(0xCCB9C8DA)
                                  : theme.hintColor,
                              letterSpacing: 2,
                            ),
                          ),
                          const Spacer(),
                          _pinButton(scheme),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: widget.expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            curve: _curve,
                            child: Icon(
                              Icons.expand_more,
                              size: 20,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
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

  Widget _pinButton(ColorScheme scheme) {
    final pinned = widget.pinned;
    return Tooltip(
      message: pinned ? '已固定：菜单保持展开' : '未固定：跳转后自动收起',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTogglePinned,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedRotation(
            turns: pinned ? 0 : 0.25,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Icon(
              pinned ? Icons.push_pin : Icons.push_pin_outlined,
              size: 16,
              color: pinned ? scheme.primary : scheme.outline,
            ),
          ),
        ),
      ),
    );
  }

  /// 条目阶梯：每项错开 5%，半程内完成淡入（展开总程 360ms）。
  Widget _stagger(int i, Widget child) {
    final begin = (0.05 * i).clamp(0.0, 0.5);
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _anim,
        curve: Interval(begin, (begin + 0.5).clamp(0.0, 1.0)),
      ),
      child: child,
    );
  }
}

/// 目的地数据（桌面悬浮菜单与手机底栏共用）。
/// 总览兼作账户页（添加资产入口在总览），独立账户页已撤除。
abstract final class NavItems {
  static const primary = [
    (
      icon: Icons.dashboard_outlined,
      selected: Icons.dashboard,
      label: '总览',
      path: '/',
    ),
    (
      icon: Icons.receipt_long_outlined,
      selected: Icons.receipt_long,
      label: '流水',
      path: '/transactions',
    ),
    (
      icon: Icons.assessment_outlined,
      selected: Icons.assessment,
      label: '月报',
      path: '/reports',
    ),
  ];

  static const secondary = [
    (icon: Icons.auto_awesome_outlined, label: 'AI 助手', path: '/ai'),
    (icon: Icons.savings_outlined, label: '预算', path: '/budgets'),
    (icon: Icons.event_outlined, label: '计划', path: '/plans'),
    (icon: Icons.flag_outlined, label: '目标', path: '/goals'),
    (icon: Icons.credit_card_outlined, label: '负债', path: '/debts'),
    (icon: Icons.settings_outlined, label: '设置', path: '/settings'),
  ];
}

/// 路径匹配：根路由精确匹配，其余允许子路径（/transactions/xx）。
/// 注意不能用裸 startsWith——任何路径都以 '/' 开头会导致总览永远选中。
bool navMatches(String location, String path) =>
    location == path || (path != '/' && location.startsWith('$path/'));

class _RailTile extends StatefulWidget {
  const _RailTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_RailTile> createState() => _RailTileState();
}

class _RailTileState extends State<_RailTile> {
  bool _pressed = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = widget.active ? scheme.primary : theme.hintColor;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: ParticleEdge.active(
            active: _hover,
            band: 7,
            extendBelow: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.chip),
              focusColor: scheme.primary.withValues(alpha: 0.10),
              hoverColor: scheme.primary.withValues(alpha: 0.05),
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                  color: widget.active
                      ? scheme.primary.withValues(alpha: 0.12)
                      : _hover
                      ? scheme.primary.withValues(alpha: 0.05)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    // hover 弹性放大（easeOutBack 轻过冲，触屏无 hover 自然无效）。
                    AnimatedScale(
                      scale: _hover ? 1.15 : 1,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      child: Icon(widget.icon, size: 20, color: color),
                    ),
                    const SizedBox(width: 10),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: color,
                        fontWeight: widget.active
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      child: Text(widget.label),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 菜单氛围：面板边缘附近的低密度蓝白粒子（缓慢漂移 + 明暗呼吸）与
/// 背后一抹散射微光。progress（展开进度）驱动整体显现；绘制允许溢出
/// 面板边界（外层 Stack Clip.none），hitTest 恒 false 不挡任何交互。
class MenuAmbiencePainter extends CustomPainter {
  MenuAmbiencePainter({required this.t, required this.progress});

  final double t; // 秒
  final double progress; // 0..1 展开进度

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || size.isEmpty) return;
    // 散射光：面板左上一抹较明显的冷光 + 四周柔和底光，体现
    // 「面板悬浮于空间中」。
    final halo = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF9FC1E3).withValues(alpha: 0.14 * progress),
              const Color(0xFF9FC1E3).withValues(alpha: 0.05 * progress),
              const Color(0xFF9FC1E3).withValues(alpha: 0),
            ],
            stops: const [0, 0.45, 1],
          ).createShader(
            Rect.fromCircle(
              center: Offset(-size.width * 0.08, size.height * 0.18),
              radius: size.width * 1.4,
            ),
          );
    canvas.drawRect(
      Rect.fromLTWH(-80, -80, size.width + 160, size.height + 160),
      halo,
    );
    // 粒子：固定种子（位置稳定不闪跳），沿面板边缘缓慢游移。
    final rnd = _Seeded(11);
    for (var i = 0; i < 26; i++) {
      final baseX = rnd.next() * (size.width + 96) - 48;
      final baseY = rnd.next() * (size.height + 96) - 48;
      final speed = 0.08 + rnd.next() * 0.16;
      final phase = rnd.next() * math.pi * 2;
      final drift = 6 + rnd.next() * 10;
      final x = baseX + math.sin(t * speed + phase) * drift;
      final y = baseY + math.cos(t * speed * 0.8 + phase) * drift;
      final twinkle = 0.5 + 0.5 * math.sin(t * (0.5 + speed * 3) + phase * 2);
      final alpha = (0.10 + 0.22 * twinkle) * progress;
      canvas.drawCircle(
        Offset(x, y),
        0.8 + rnd.next() * 0.9,
        Paint()..color = const Color(0xFFBFD9F2).withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(MenuAmbiencePainter old) =>
      old.t != t || old.progress != progress;

  @override
  bool hitTest(Offset position) => false;
}

/// 固定种子伪随机（0..1）：粒子布局跨帧稳定。
class _Seeded {
  _Seeded(int seed) : _state = seed;

  int _state;

  double next() {
    // 线性同余，够用且便宜。
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state / 0x7fffffff;
  }
}
