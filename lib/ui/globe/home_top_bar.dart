import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../services/current_location.dart';
import '../dashboard/dashboard_providers.dart';
import '../widgets/common.dart';
import '../widgets/particle_orbit.dart';
import 'asset_globe.dart';

/// 首页右上操作集群（2026-10-30 导航体系删除后的功能枢纽）：
///
/// [待办] [AI 助手] [设置] ‖ [定位当前位置] [清屏地球] [刷新]
///
/// - 前三枚是目的地入口（容器展开转场：页面自按钮矩形生长）：
///   待办在有待处理事项时转香槟色调、呼吸起伏、外圈粒子环绕——
///   醒目但不喧哗；无待办时是常规钢蓝玻璃钮。
/// - 后三枚是地球视角/数据操作：定位当前位置（Windows 定位服务优先，
///   不可用时按本地时区估计并如实标注；定位中钮内粒子轨道）；
///   清屏地球钉住沉浸；刷新为强调钮，点击即起转（最少一整圈），
///   加载期间持续旋转、防重复触发。
class HomeTopBar extends ConsumerStatefulWidget {
  const HomeTopBar({
    super.key,
    required this.globeKey,
    required this.pinned,
    required this.onTogglePinned,
  });

  final GlobalKey<AssetGlobeState> globeKey;
  final bool pinned;
  final VoidCallback onTogglePinned;

  @override
  ConsumerState<HomeTopBar> createState() => _HomeTopBarState();
}

class _HomeTopBarState extends ConsumerState<HomeTopBar> {
  // 容器展开导航源：各钮矩形钥匙（页面自按钮位置生长）。
  final _todoKey = GlobalKey(debugLabel: 'hero-todo');
  final _aiKey = GlobalKey(debugLabel: 'hero-ai');
  final _settingsKey = GlobalKey(debugLabel: 'hero-settings');

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final d = ref.watch(dashboardProvider).value;
    // 与原右列「待处理卡」同一判定：到期计划/估值缺口/对账差额任一存在。
    final pendingCount = d == null
        ? 0
        : (d.pendingDueCount > 0 ? 1 : 0) +
              (d.nw.missingValuations > 0 ? 1 : 0) +
              (d.nw.staleValuations > 0 ? 1 : 0) +
              (d.report.attribution.hasResidual ? 1 : 0);
    return Row(
      children: [
        _TodoButton(pendingCount: pendingCount, heroKey: _todoKey),
        const SizedBox(width: 10),
        _GlassIconButton(
          tooltip: t.homeAiTooltip,
          icon: Icons.auto_awesome_outlined,
          onTap: () => HeroLaunch.go(context, '/ai', _aiKey),
          heroKey: _aiKey,
        ),
        const SizedBox(width: 10),
        _GlassIconButton(
          tooltip: t.homeSettingsTooltip,
          icon: Icons.settings_outlined,
          onTap: () => HeroLaunch.go(context, '/settings', _settingsKey),
          heroKey: _settingsKey,
        ),
        // 目的地组与视角/数据组之间的呼吸间距。
        const SizedBox(width: 18),
        _LocateButton(globeKey: widget.globeKey),
        const SizedBox(width: 10),
        _GlassIconButton(
          tooltip: widget.pinned ? t.globeRestorePage : t.globeClearScreen,
          icon: widget.pinned ? Icons.close_fullscreen : Icons.open_in_full,
          onTap: widget.onTogglePinned,
        ),
        const SizedBox(width: 10),
        const _RefreshButton(),
      ],
    );
  }
}

/// 待办钮：无待办=常规玻璃钮；有待办=香槟色调 + 2.4s 呼吸（微缩放 +
/// 辉光起伏，与全站呼吸光环同一周期）+ 外圈缓转香槟粒子。点击经容器
/// 展开进入待处理页。widget 测试与「减少动画」都定格呼吸中帧（粒子环
/// 仍在，明暗冻结）。
class _TodoButton extends StatefulWidget {
  const _TodoButton({required this.pendingCount, required this.heroKey});

  final int pendingCount;
  final GlobalKey heroKey;

  @override
  State<_TodoButton> createState() => _TodoButtonState();
}

class _TodoButtonState extends State<_TodoButton>
    with SingleTickerProviderStateMixin {
  /// 呼吸时钟：2.4s 余弦一圈（与导航时代入口光环、FAB 微尘同族节奏）。
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  /// widget 测试环境：常驻 Ticker 会卡死 pumpAndSettle，定格静止帧。
  static final bool _testEnv =
      Platform.environment['FLUTTER_TEST'] == 'true';
  bool _reduce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = _testEnv || MediaQuery.disableAnimationsOf(context);
    if (_reduce) {
      _breath.stop();
      _breath.value = 0.25; // 呼吸中帧：粒子环可见、明暗冻结
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final pending = widget.pendingCount > 0;
    if (pending && !_reduce && !_breath.isAnimating) _breath.repeat();
    if (!pending && _breath.isAnimating) _breath.stop();
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        // 余弦呼吸：0→1→0，峰谷都圆润（无 ease 起步感）。
        final b = 0.5 - 0.5 * math.cos(_breath.value * 2 * math.pi);
        return Transform.scale(
          scale: pending ? 1 + 0.05 * b : 1,
          child: child,
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 呼吸粒子环：12 颗香槟火花绕钮缓转，仅待办态可见。
          if (pending)
            Positioned(
              left: -16,
              top: -16,
              width: 72,
              height: 72,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _breath,
                  builder: (context, _) => CustomPaint(
                    painter: _TodoSparkPainter(
                      t: _breath.value * 2.4,
                    ),
                  ),
                ),
              ),
            ),
          _GlassIconButton(
            tooltip: pending ? t.homeTodoPending(widget.pendingCount) : t.homeTodoTooltip,
            icon: Icons.checklist,
            brass: pending,
            onTap: () => HeroLaunch.go(context, '/inbox', widget.heroKey),
            heroKey: widget.heroKey,
          ),
        ],
      ),
    );
  }
}

/// 待办粒子环：香槟火花沿钮缘缓公转（~7s 一圈）+ 轻径向摆动 + 明暗
/// 闪烁，固定种子（位置跨帧稳定）。hitTest 恒 false。
class _TodoSparkPainter extends CustomPainter {
  const _TodoSparkPainter({required this.t});

  final double t; // 秒

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final c = size.center(Offset.zero);
    final rnd = _Seeded(31);
    for (var i = 0; i < 12; i++) {
      final phase = rnd.next() * 2 * math.pi;
      final angle = t * 0.9 + phase; // 0.9 rad/s ≈ 7s 一圈
      final wob = math.sin(t * 0.7 + i * 1.3) * 2.5;
      final r = size.shortestSide / 2 - 10 + wob;
      final x = c.dx + math.cos(angle) * r;
      final y = c.dy + math.sin(angle) * r;
      final twinkle = 0.5 + 0.5 * math.sin(t * (0.8 + rnd.next() * 0.6) + phase * 2);
      canvas.drawCircle(
        Offset(x, y),
        0.9 + rnd.next() * 0.8,
        Paint()
          ..color = (i % 5 == 0 ? const Color(0xFFF5E7C4) : const Color(0xFFE5C078))
              .withValues(alpha: (0.18 + 0.5 * twinkle).clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(_TodoSparkPainter old) => old.t != t;

  @override
  bool hitTest(Offset position) => false;
}

/// 定位当前位置钮：点击先起钮内粒子轨道（定位中），拿到坐标后地球
/// 飞往该地上空，落地 toast 如实标注来源（系统定位 / 时区估计）。
class _LocateButton extends StatefulWidget {
  const _LocateButton({required this.globeKey});

  final GlobalKey<AssetGlobeState> globeKey;

  @override
  State<_LocateButton> createState() => _LocateButtonState();
}

class _LocateButtonState extends State<_LocateButton>
    with SingleTickerProviderStateMixin {
  bool _locating = false;

  Future<void> _locate() async {
    if (_locating) return;
    setState(() => _locating = true);
    final loc = await locateCurrent();
    if (!mounted) return;
    setState(() => _locating = false);
    final t = AppLocalizations.of(context);
    await widget.globeKey.currentState?.flyToLocation(loc.lat, loc.lon);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          loc.exact
              ? t.homeLocatedExact(loc.placeName)
              : t.homeLocatedEstimate(loc.placeName),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return _GlassIconButton(
      tooltip: _locating ? t.homeLocating : t.homeLocateCurrentTooltip,
      icon: Icons.my_location,
      onTap: _locating ? null : _locate,
      iconBuilder: (color) => _locating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: Center(
                child: ParticleOrbit(size: 20, color: Color(0xFF7EA6D9)),
              ),
            )
          : Icon(Icons.my_location, size: 18, color: color),
    );
  }
}

/// 刷新按钮：强调材质。点击即起转（840ms easeOutCubic 整圈半——缓存
/// 命中时加载几十毫秒就完，没有保底转程的话用户永远看不见旋转）；
/// 加载期间持续线性旋转且忽略点击（防重复触发）。两段旋转叠加。
class _RefreshButton extends ConsumerStatefulWidget {
  const _RefreshButton();

  @override
  ConsumerState<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends ConsumerState<_RefreshButton>
    with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// 点击保底转程：840ms 内匀减速转 1.25 圈。
  late final AnimationController _kick = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 840),
  );

  @override
  void dispose() {
    _spin.dispose();
    _kick.dispose();
    super.dispose();
  }

  void _refresh() {
    if (MediaQuery.disableAnimationsOf(context)) {
      unawaited(ref.refresh(dashboardProvider.future));
      return;
    }
    _kick.forward(from: 0);
    unawaited(ref.refresh(dashboardProvider.future));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final loading = ref.watch(dashboardProvider).isLoading;
    if (loading && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!loading && _spin.isAnimating) {
      _spin
        ..stop()
        ..value = 0;
    }
    return _GlassIconButton(
      tooltip: loading ? t.homeRefreshing : t.homeRefreshData,
      accent: true,
      onTap: loading ? null : _refresh,
      iconBuilder: (color) => RotationTransition(
        turns: _spin,
        child: RotationTransition(
          turns: CurvedAnimation(parent: _kick, curve: Curves.easeOutCubic),
          child: Icon(Icons.refresh, size: 18, color: color),
        ),
      ),
    );
  }
}

/// 统一材质的玻璃圆钮：局部磨砂 + 发丝边 + hover 提亮 + 按压回缩。
/// [accent] 为强调款（钢蓝底，用于刷新）；[brass] 为待办警示款（香槟
/// 底，有待办事项时）。[heroKey] 供容器展开导航测量来源矩形。
class _GlassIconButton extends StatefulWidget {
  const _GlassIconButton({
    required this.tooltip,
    this.icon,
    this.iconBuilder,
    this.accent = false,
    this.brass = false,
    this.onTap,
    this.heroKey,
  });

  final String tooltip;
  final IconData? icon;
  final Widget Function(Color color)? iconBuilder;
  final bool accent;
  final bool brass;

  final VoidCallback? onTap; // null = 禁用（不响应但仍可聚焦读提示）

  /// 可选：钮体矩形钥匙（HeroLaunch.go 用）。
  final GlobalKey? heroKey;

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final brass = widget.brass;
    final base = accent
        ? const Color(0xFF7EA6D9).withValues(alpha: 0.18)
        : brass
        ? const Color(0xFFE5C078).withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.07);
    final hovered = accent
        ? const Color(0xFF7EA6D9).withValues(alpha: 0.30)
        : brass
        ? const Color(0xFFE5C078).withValues(alpha: 0.30)
        : Colors.white.withValues(alpha: 0.14);
    final iconColor = accent
        ? const Color(0xFFBFD9F2)
        : brass
        ? const Color(0xFFF2DCA8)
        : const Color(0xFF7EA6D9).withValues(alpha: 0.9);
    final borderColor = accent
        ? const Color(0xFF7EA6D9).withValues(alpha: 0.45)
        : brass
        ? const Color(0xFFE5C078).withValues(alpha: 0.55)
        : const Color(0x2EE7ECF2);
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Listener(
          onPointerDown: (_) => setState(() => _pressed = true),
          onPointerUp: (_) => setState(() => _pressed = false),
          onPointerCancel: (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              key: widget.heroKey,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hover ? hovered : base,
                border: Border.fromBorderSide(
                  BorderSide(color: borderColor, width: 1),
                ),
                boxShadow: [
                  if (brass)
                    BoxShadow(
                      // 待办辉光：警示但温和（呼吸起伏由外层缩放呈现）。
                      color: const Color(0xFFE5C078).withValues(
                        alpha: _hover ? 0.4 : 0.24,
                      ),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: Semantics(
                  button: true,
                  label: widget.tooltip,
                  onTap: widget.onTap,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.onTap,
                    child: Center(
                      child:
                          widget.iconBuilder?.call(iconColor) ??
                          Icon(widget.icon, size: 18, color: iconColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 固定种子伪随机（0..1）：粒子布局跨帧稳定。
class _Seeded {
  _Seeded(int seed) : _state = seed;

  int _state;

  double next() {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state / 0x7fffffff;
  }
}
