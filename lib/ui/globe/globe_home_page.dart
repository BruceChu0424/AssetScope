import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../accounts/account_edit_dialog.dart';
import '../dashboard/dashboard_cards.dart';
import '../dashboard/dashboard_providers.dart';
import '../dashboard/dashboard_secondary_cards.dart';
import '../transactions/add_transaction_dialog.dart';
import '../widgets/common.dart';
import 'asset_globe.dart';
import 'glass_card.dart';
import 'immersive_globe_host.dart';
import 'space_backdrop.dart';

/// 首页 · 财富指挥舱：整页深空（星野/星云/流星铺满窗口四缘）上的资产
/// 地球 + 悬浮财务卡。全出血布局，所有界面元素悬浮于背景之上。
/// 总览兼作账户页——「添加资产」入口在本页右上角（新建即点亮地球）。
///
/// - 左上角：分类菜单入口（属 HomeShell 纯浮层，展开覆盖卡片）；
/// - 右上角：添加资产（实心强调胶囊）→ 定位 → 全屏 → 刷新，与菜单入口
///   同一水平线；刷新加载中旋转且防重复触发；
/// - 特大屏（≥1120）：左列核心卡贴窗口左缘 · 中央地球（相对整窗居中）
///   · 右列次级卡贴右缘，两侧留协调边距，三区各自滚动；
/// - 大屏（≥900）：地球居左 + 单列卡片贴右缘；
/// - 小屏：地球固定高度在上（避开顶部操作区），卡片纵列在下滚动；
/// - 卡片为深色玻璃面板（局部背景模糊 + 发丝边 + 悬浮阴影），
///   hover 上浮 + 投影加深；入场编排：地球 450ms 淡入轻放大，卡片
///   40ms 阶梯浮现（仅首次）；
/// - 沉浸模式：地球交互（拖动/缩放）时卡片淡出收缩、地球自槽位扩张
///   为全屏（[ImmersiveGlobeHost]）；右上操作钮恒定不动。
class GlobeHomePage extends ConsumerStatefulWidget {
  const GlobeHomePage({super.key});

  @override
  ConsumerState<GlobeHomePage> createState() => _GlobeHomePageState();
}

class _GlobeHomePageState extends ConsumerState<GlobeHomePage> {
  /// 地球实例钥匙：右上角「定位」按钮经此复位视角（同一实例，视角连续）。
  final GlobalKey<AssetGlobeState> _globeKey = GlobalKey<AssetGlobeState>(
    debugLabel: 'home-globe',
  );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dashboardProvider);
    final topPad = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFF050A12),
      body: Stack(
        children: [
          // 整窗深空底幕：铺满窗口四缘，一切元素悬浮其上。
          const Positioned.fill(child: SpaceBackdrop()),
          Positioned.fill(
            child: async.when(
              loading: () => const Center(
                child: OrbitSpinner(size: 44, color: Color(0xFF7EA6D9)),
              ),
              error: (e, _) => Center(
                child: Text(
                  '加载失败：$e',
                  style: const TextStyle(color: Color(0xFFF0907C)),
                ),
              ),
              data: (_) => Column(
                children: [
                  _AutoPostNotice(),
                  const _AiValuationNotice(),
                  Expanded(child: _RefreshableHomeBody(globeKey: _globeKey)),
                ],
              ),
            ),
          ),
          // 右上操作集群：定位 → 全屏 → 刷新（与左上 48px 菜单入口垂直居中）。
          Positioned(
            right: 20,
            top: topPad + 18,
            child: _TopActionCluster(globeKey: _globeKey),
          ),
          // 右下角悬浮添加（果冻菜单）：自带整页磨砂暗纱层。
          _QuickAddFab(globeKey: _globeKey),
        ],
      ),
    );
  }
}

/// 右上操作集群：与菜单入口同一水平线。定位/全屏为玻璃圆钮，刷新为
/// 钢蓝强调圆钮（加载中旋转、防重复触发）。新建入口在右下角
/// [_QuickAddFab]（添加资产 / 记一笔）。
class _TopActionCluster extends ConsumerWidget {
  const _TopActionCluster({required this.globeKey});

  final GlobalKey<AssetGlobeState> globeKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _GlassIconButton(
          tooltip: '定位：复位地球视角',
          icon: Icons.my_location,
          onTap: () => globeKey.currentState?.resetView(),
        ),
        const SizedBox(width: 10),
        _GlassIconButton(
          tooltip: '全屏地球',
          icon: Icons.open_in_full,
          onTap: () => context.go('/globe'),
        ),
        const SizedBox(width: 10),
        _RefreshButton(),
      ],
    );
  }
}

/// 右下角悬浮添加按钮（果冻菜单）：点按后整页蒙上一层磨砂暗纱，
/// 两枚操作胶囊「添加资产 / 记一笔」从按钮里**果冻式弹性分离**——
/// elasticOut 过冲回弹 + 自按钮方向的位移生长，依次错落弹出；再点按
/// （或点磨砂空白处）原路收回。
///
/// - 胶囊动作：添加资产 → [AccountEditDialog]（保存后地球重载标记，
///   视角连续）；记一笔 → [AddTransactionDialog]（保存后刷新仪表盘）；
/// - 打开时主按钮 + 旋转 45° 变「×」，按压有 120ms 回缩；
/// - 「减少动画」时直达终态（无弹性）。
class _QuickAddFab extends ConsumerStatefulWidget {
  const _QuickAddFab({required this.globeKey});

  final GlobalKey<AssetGlobeState> globeKey;

  @override
  ConsumerState<_QuickAddFab> createState() => _QuickAddFabState();
}

class _QuickAddFabState extends ConsumerState<_QuickAddFab>
    with TickerProviderStateMixin {
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
    reverseDuration: const Duration(milliseconds: 240),
    value: 0,
  );

  /// 菜单氛围粒子时钟（仅展开期间运转；减少动画时不启）。
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  final Stopwatch _ambientClock = Stopwatch();

  bool _hover = false;
  bool _pressed = false;
  bool _reduce = false;

  @override
  void initState() {
    super.initState();
    _open.addStatusListener(_onOpenStatus);
  }

  void _onOpenStatus(AnimationStatus status) {
    if (_reduce) return;
    if (status == AnimationStatus.completed) {
      _ambientClock.start();
      _ambient.repeat();
    } else if (status == AnimationStatus.dismissed) {
      _ambient.stop();
      _ambientClock.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _open.dispose();
    _ambient.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_reduce) {
      _open.value = _open.value > 0.5 ? 0 : 1;
    } else {
      _open.value > 0.5 ? _open.reverse() : _open.forward();
    }
  }

  Future<void> _addAction(
    Widget dialog, {
    bool reloadGlobe = false,
    DissolveController? dissolve,
  }) async {
    _toggle(); // 先收起菜单再开弹窗
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, animation, _) =>
            _DialogShell(animation: animation, child: dialog),
      ),
    );
    if (!mounted) return;
    unawaited(ref.refresh(dashboardProvider.future));
    // 粒子化保存的标记重载推迟到光束到达（onArrive），此处即时重载
    // 会在光束落点前剧透新光点。
    if (reloadGlobe && dissolve?.played != true) {
      widget.globeKey.currentState?.reloadMarkers();
    }
  }

  /// 添加资产 · 粒子化保存编排：弹窗碎裂成粒子光束，地球同步飞往
  /// 资产位置，光束到达时点亮标记（时间轴见 dissolve_stage.dart）。
  Future<void> _addAsset() async {
    final dissolve = DissolveController(
      targetOf: (lat, lon) =>
          widget.globeKey.currentState?.locationScreenPos(lat, lon),
      onLaunch: (lat, lon) =>
          widget.globeKey.currentState?.flyToLocation(lat, lon),
      onArrive: (lat, lon) {
        widget.globeKey.currentState?.reloadMarkers();
        unawaited(ref.refresh(dashboardProvider.future));
      },
    );
    await _addAction(
      DissolveCapture(
        controller: dissolve,
        child: AccountEditDialog(dissolve: dissolve),
      ),
      reloadGlobe: true,
      dissolve: dissolve,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 整棵子树随 _open 逐帧重建：暗纱的 IgnorePointer/提示语必须与
    // 动画值同步求值——否则收起完成后命中态滞留在「可点」，一层无形
    // 暗纱挡住整页交互（曾需再点一次才恢复）。
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _open,
        builder: (context, _) => Stack(
          children: [
            // 整页磨砂暗纱：打开时对背后全部内容做背景模糊，点击空白收回。
            IgnorePointer(
              ignoring: _open.value < 0.02,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _open,
                  curve: const Interval(0, 0.6, curve: Curves.easeOut),
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggle,
                  child: BackdropFilter(
                    // 轻纱：模糊保留（聚焦菜单），暗度减半——观感是「空气感
                    // 轻纱」而非灰蒙版。
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(color: const Color(0x2E061020)),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 28,
              bottom: 28,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 氛围粒子：胶囊/主钮四周缓升微光的钢蓝/香槟尘埃，
                  // 仅展开期间运转（z 序在胶囊之下，不参与命中）。
                  Positioned(
                    left: -84,
                    top: -96,
                    right: -14,
                    bottom: -8,
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _ambient,
                        builder: (context, _) => CustomPaint(
                          painter: _FabMotesPainter(
                            t: _reduce
                                ? 0.6
                                : _ambientClock.elapsedMilliseconds / 1000,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _pill(
                        index: 0,
                        icon: Icons.add_location_alt_outlined,
                        label: '添加资产',
                        tooltip: '新建资产/负债账户，为资产选位置即点亮地球',
                        onTap: _addAsset,
                      ),
                      const SizedBox(height: 12),
                      _pill(
                        index: 1,
                        icon: Icons.receipt_long_outlined,
                        label: '记一笔',
                        tooltip: '上报消费 / 收入 / 转账等日常流水',
                        onTap: () => _addAction(const AddTransactionDialog()),
                      ),
                      const SizedBox(height: 16),
                      _fabButton(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 主按钮：钢蓝渐变圆钮，+ 号随开合旋转 45°。
  Widget _fabButton() {
    return Tooltip(
      message: _open.value > 0.5 ? '收起' : '记一笔 / 添加资产',
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
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF9DC0EA), Color(0xFF5E86BC)],
                ),
                border: Border.all(
                  color: const Color(0xFFCFE2F6).withValues(alpha: 0.55),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF7EA6D9,
                    ).withValues(alpha: _hover ? 0.55 : 0.38),
                    blurRadius: _hover ? 26 : 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: Semantics(
                  button: true,
                  label: _open.value > 0.5 ? '收起快捷菜单' : '添加：记一笔或添加资产',
                  onTap: _toggle,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _toggle,
                    child: Center(
                      child: AnimatedRotation(
                        turns: _open.value * 0.125, // 45° = 1/8 圈
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        child: const Icon(
                          Icons.add,
                          size: 28,
                          color: Color(0xFF0B1524),
                        ),
                      ),
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

  /// 果冻胶囊：elasticOut 过冲回弹 + 从按钮方向（右下）升起，随开合
  /// 原路收回；标签稍晚淡入，保证弹出时不糊成一片。
  Widget _pill({
    required int index,
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    // 每枚错开 14%：先弹「添加资产」，再弹「记一笔」。
    final begin = 0.10 + 0.14 * index;
    final pop = CurvedAnimation(
      parent: _open,
      curve: Interval(
        begin,
        (begin + 0.6).clamp(0.0, 1.0),
        curve: Curves.elasticOut,
      ),
      reverseCurve: const Interval(0, 0.7, curve: Curves.easeInCubic),
    );
    final labelIn = CurvedAnimation(
      parent: _open,
      curve: Interval((begin + 0.25).clamp(0.0, 1.0), 1, curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: _open,
      builder: (context, child) {
        final t = pop.value;
        // elasticOut 的 t 可能瞬时 >1（过冲），scale 直接用即可（放大再回弹）。
        return Transform.translate(
          offset: Offset(6 * (1 - t), 10 * (1 - t)),
          child: Transform.scale(
            scale: t.clamp(0.0, 1.6),
            alignment: Alignment.bottomRight,
            child: Opacity(
              opacity: labelIn.value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: Tooltip(
        message: tooltip,
        child: _FabPill(icon: icon, label: label, onTap: onTap),
      ),
    );
  }
}

/// 菜单胶囊本体：深色玻璃胶囊 + 圆形图标位 + 标签，hover 提亮。
class _FabPill extends StatefulWidget {
  const _FabPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_FabPill> createState() => _FabPillState();
}

class _FabPillState extends State<_FabPill> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 46,
            // 左缘给图标留出呼吸间距，不贴边框。
            padding: const EdgeInsets.fromLTRB(6, 6, 18, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              color: _hover ? const Color(0xFF22344A) : const Color(0xE6162433),
              border: Border.all(
                color: _hover
                    ? const Color(0x66BFD9F2)
                    : const Color(0x3DE7ECF2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(23),
              ),
              child: Semantics(
                button: true,
                label: widget.label,
                onTap: widget.onTap,
                child: InkWell(
                  borderRadius: BorderRadius.circular(23),
                  onTap: widget.onTap,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFF7EA6D9,
                            ).withValues(alpha: _hover ? 0.30 : 0.20),
                          ),
                          child: Icon(
                            widget.icon,
                            size: 18,
                            color: const Color(0xFFBFD9F2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Color(0xFFE7F0FA),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
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

/// 弹窗外壳：居中、宽度收束到 ≤480（桌面默认弹窗过宽），入场 260ms
/// 淡入 + 96%→100% 轻放大 + 10px 上浮（easeOutCubic），离场反向；
/// 深色主题下给 Dialog 补玻璃质感（深底 + 发丝边 + 20px 圆角）。
/// 快捷菜单氛围粒子：右下角集群四周的钢蓝/香槟微尘——缓慢上升 +
/// 左右摇曳 + 明暗呼吸，主钮身后一抹钢蓝辉光。固定种子（位置稳定
/// 不闪跳），hitTest 恒 false 不挡交互。
class _FabMotesPainter extends CustomPainter {
  const _FabMotesPainter({required this.t});

  final double t; // 秒

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // 只做微尘粒子：光晕只留在按钮边缘（主钮自身的 boxShadow），
    // 不再整片区域铺底光（用户要求）。
    final rnd = _Seeded(23);
    for (var i = 0; i < 18; i++) {
      final speed = 6 + rnd.next() * 14; // 上升 px/s
      final baseX = rnd.next() * size.width;
      final phase = rnd.next() * 2 * math.pi;
      // 行程序：0 刚在底缘下现身 → 1 顶缘上消失（活动窗 = 高度+30）。
      final progress = ((t * speed + phase * 20) % (size.height + 30)) /
          (size.height + 30);
      final y = size.height - progress * (size.height + 30);
      final x = baseX + math.sin(t * (0.4 + rnd.next() * 0.5) + phase) * 8;
      final twinkle =
          0.5 + 0.5 * math.sin(t * (0.6 + speed * 0.12) + phase * 2);
      // 出入边缘 15% 钟形淡入淡出：粒子在底缘现身/顶缘消失都不"啪"。
      final edge = math.sin(
        (progress.clamp(0.0, 1.0) * math.pi / 0.85).clamp(0.0, math.pi),
      );
      final alpha = (0.08 + 0.26 * twinkle) * edge;
      canvas.drawCircle(
        Offset(x, y),
        0.9 + rnd.next() * 1.1,
        Paint()
          ..color =
              (i % 4 == 0
                      ? const Color(0xFFE5C078) // 香槟点缀
                      : const Color(0xFFBFD9F2)) // 钢蓝微尘
                  .withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_FabMotesPainter old) => old.t != t;

  @override
  bool hitTest(Offset position) => false;
}

/// 固定种子伪随机（0..1）：粒子布局跨帧稳定（同 floating_nav_rail）。
class _Seeded {
  _Seeded(int seed) : _state = seed;

  int _state;

  double next() {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state / 0x7fffffff;
  }
}

class _DialogShell extends StatelessWidget {
  const _DialogShell({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 10 * (1 - curved.value)),
        child: Transform.scale(scale: 0.96 + 0.04 * curved.value, child: child),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Theme(
            data: Theme.of(context).copyWith(
              dialogTheme: DialogThemeData(
                backgroundColor: dark ? const Color(0xF2141B24) : Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: dark
                        ? const Color(0x33E7ECF2)
                        : const Color(0x14273A4D),
                  ),
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 刷新按钮：强调材质；刷新进行中图标旋转且忽略点击（防重复触发）。
class _RefreshButton extends ConsumerStatefulWidget {
  const _RefreshButton();

  @override
  ConsumerState<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends ConsumerState<_RefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(dashboardProvider).isLoading;
    if (loading && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!loading && _spin.isAnimating) {
      _spin
        ..stop()
        ..value = 0;
    }
    return _GlassIconButton(
      tooltip: loading ? '刷新中…' : '刷新数据',
      accent: true,
      onTap: loading
          ? null
          : () => unawaited(ref.refresh(dashboardProvider.future)),
      iconBuilder: (color) => RotationTransition(
        turns: _spin,
        child: Icon(Icons.refresh, size: 18, color: color),
      ),
    );
  }
}

/// 统一材质的玻璃圆钮：局部磨砂 + 发丝边 + hover 提亮 + 按压回缩。
/// [accent] 为强调款（钢蓝底 + 钢蓝边，用于刷新）。
class _GlassIconButton extends StatefulWidget {
  const _GlassIconButton({
    required this.tooltip,
    this.icon,
    this.iconBuilder,
    this.accent = false,
    this.onTap,
  });

  final String tooltip;
  final IconData? icon;
  final Widget Function(Color color)? iconBuilder;
  final bool accent;
  final VoidCallback? onTap; // null = 禁用（不响应但仍可聚焦读提示）

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final base = accent
        ? const Color(0xFF7EA6D9).withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.07);
    final hovered = accent
        ? const Color(0xFF7EA6D9).withValues(alpha: 0.30)
        : Colors.white.withValues(alpha: 0.14);
    final iconColor = accent
        ? const Color(0xFFBFD9F2)
        : const Color(0xFF7EA6D9).withValues(alpha: 0.9);
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
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hover ? hovered : base,
                border: Border.fromBorderSide(
                  BorderSide(
                    color: accent
                        ? const Color(0xFF7EA6D9).withValues(alpha: 0.45)
                        : const Color(0x2EE7ECF2),
                    width: 1,
                  ),
                ),
                boxShadow: [
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

/// 刷新包装（下拉或右上角刷新）：仅包卡片滚动区，地球手势不触发。
class _RefreshableHomeBody extends ConsumerWidget {
  const _RefreshableHomeBody({required this.globeKey});

  /// 透传给地球实例的钥匙（页面右上角「定位」按钮复位视角用）。
  final GlobalKey<AssetGlobeState> globeKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dashboardProvider).requireValue;
    return RefreshIndicator.adaptive(
      onRefresh: () => ref.refresh(dashboardProvider.future),
      edgeOffset: 8,
      child: _HomeBody(d: d, globeKey: globeKey),
    );
  }
}

/// 响应式三区/两区/纵向布局 + 一次性入场编排。
class _HomeBody extends StatefulWidget {
  const _HomeBody({required this.d, required this.globeKey});

  final DashboardData d;
  final GlobalKey<AssetGlobeState> globeKey;

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _started = false;
  bool _reduce = false;

  // 容器展开导航源：各卡的矩形钥匙（点击后页面从卡片位置生长）。
  final _nwKey = GlobalKey(debugLabel: 'hero-nw');
  final _flowKey = GlobalKey(debugLabel: 'hero-flow');
  final _healthKey = GlobalKey(debugLabel: 'hero-health');
  final _spendKey = GlobalKey(debugLabel: 'hero-spend');
  final _trendKey = GlobalKey(debugLabel: 'hero-trend');
  final _upcomingKey = GlobalKey(debugLabel: 'hero-upcoming');

  @override
  void initState() {
    super.initState();
    // 解锁粒子揭幕：舞台持幕期间（BusyReveal.hold）入场静候，散场开始
    // （reveal，即幕布渐薄那一刻）才启幕——地球/卡片与烟雾消散同步
    // 浮现。常态（无舞台）revealed 恒为 true，挂载即刻入场不受影响。
    BusyReveal.instance.addListener(_maybeStart);
  }

  @override
  void dispose() {
    BusyReveal.instance.removeListener(_maybeStart);
    _enter.dispose();
    super.dispose();
  }

  void _maybeStart() {
    if (_started || !BusyReveal.instance.revealed) return;
    _started = true;
    if (_reduce) {
      _enter.value = 1;
    } else {
      _enter.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
    _maybeStart();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    final width = MediaQuery.sizeOf(context).width;
    // 卡片列顶部：窗口栏（WindowChrome 顶衬垫）+ 菜单入口行（48px）+
    // 呼吸间距——与左上入口/右上操作集群落在同一条节奏线上。
    final cardsTop = MediaQuery.paddingOf(context).top + 78;
    return ImmersiveGlobeHost(
      globeBuilder: (onImmerse) => FadeTransition(
        opacity: _viewportAnim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(_viewportAnim),
          child: AssetGlobe(
            key: widget.globeKey,
            backdrop: false,
            showActions: false,
            onImmersionChanged: onImmerse,
          ),
        ),
      ),
      builder: (context, immersion, slotKey) {
        // 左列：核心卡（净资产/收支/体检）——整卡可点，容器展开进对应页。
        final leftCards = [
          _CardLauncher(
            heroKey: _nwKey,
            path: '/reports',
            hint: '月报 · 净资产变化分解',
            child: NetWorthHeroCard(d: d, animateNumber: true),
          ),
          _CardLauncher(
            heroKey: _flowKey,
            path: '/transactions',
            hint: '流水 · 本月全部收支',
            child: MonthFlowCard(d: d),
          ),
          _CardLauncher(
            heroKey: _healthKey,
            path: '/reports',
            hint: '月报 · 体检与构成明细',
            child: HealthCard(d: d),
          ),
        ];
        // 右列：次级卡（可支配/洞察/走势/未来/待处理）。会自缩为空的卡
        // 在此按数据条件剔除——避免给空壳包玻璃面板。
        final rightCards = [
          _CardLauncher(
            heroKey: _spendKey,
            path: '/budgets',
            hint: '预算 · 额度与配速',
            child: SpendableCard(d: d),
          ),
          if (d.insights.insights.isNotEmpty)
            InsightsCard(insights: d.insights.insights),
          if (d.series.isNotEmpty)
            _CardLauncher(
              heroKey: _trendKey,
              path: '/reports',
              hint: '月报 · 历史走势与归因',
              child: TrendCard(d: d),
            ),
          _CardLauncher(
            heroKey: _upcomingKey,
            path: '/plans',
            hint: '计划 · 固定开销与预定支出',
            child: UpcomingCard(d: d),
          ),
          if (d.pendingDueCount > 0 ||
              d.nw.missingValuations > 0 ||
              d.nw.staleValuations > 0 ||
              d.report.attribution.hasResidual)
            IssuesCard(d: d),
        ];
        if (width >= 1120) {
          // 对称双翼：卡片贴窗口两缘（20px 协调边距），地球槽位占据中央
          // 全高——地球相对整窗居中，卡片不挤压中间区域。
          final cardW = width >= 1700 ? 356.0 : (width >= 1400 ? 344.0 : 328.0);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: cardW,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, cardsTop, 0, 0),
                  child: _recede(immersion, _cardScroll(leftCards)),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(child: SizedBox.expand(key: slotKey)),
              const SizedBox(width: 18),
              SizedBox(
                width: cardW,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, cardsTop, 20, 0),
                  child: _recede(immersion, _cardScroll(rightCards)),
                ),
              ),
            ],
          );
        }
        if (width >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: SizedBox.expand(key: slotKey)),
              const SizedBox(width: 12),
              SizedBox(
                width: 344,
                child: Padding(
                  padding: EdgeInsets.only(top: cardsTop, right: 16),
                  child: _recede(
                    immersion,
                    _cardScroll([...leftCards, ...rightCards]),
                  ),
                ),
              ),
            ],
          );
        }
        // 小屏：取景框固定高度在上（避开顶部操作区），卡片列表在下
        // （各自手势互不抢）。
        return LayoutBuilder(
          builder: (context, constraints) {
            final globeHeight = math.min(
              400.0,
              (constraints.maxHeight * 0.46).clamp(240.0, 420.0),
            );
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.paddingOf(context).top + 60,
                    16,
                    4,
                  ),
                  child: SizedBox(
                    height: globeHeight,
                    width: double.infinity,
                    key: slotKey,
                  ),
                ),
                Expanded(
                  child: _recede(
                    immersion,
                    _cardScroll([
                      ...leftCards,
                      ...rightCards,
                    ], extraBottomPadding: true),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 卡片让位：淡出跑在沉浸扩张的**前半程**（Interval 0~0.55）——滚轮
  /// /拖动一触发卡片先声夺人地退场，地球随后到位。若跟着 M3 强调曲线
  /// 走全程，慢起步会让前 ~400ms 的淡出几乎不可见（感知上"没消失"）。
  Widget _recede(Animation<double> immersion, Widget child) {
    final fade = CurvedAnimation(
      parent: immersion,
      curve: const Interval(0, 0.55, curve: Curves.easeInOutCubic),
    );
    return FadeTransition(
      opacity: ReverseAnimation(fade),
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 0.96).animate(fade),
        child: child,
      ),
    );
  }

  /// 取景框入场区间：前 450ms（占 900ms 总程的一半）。
  Animation<double> get _viewportAnim => CurvedAnimation(
    parent: _enter,
    curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
  );

  /// 卡片列：玻璃面板 + 首次入场 40ms 阶梯淡入上浮；hover 抬升。
  Widget _cardScroll(List<Widget> cards, {bool extraBottomPadding = false}) {
    return SingleChildScrollView(
      padding: extraBottomPadding
          ? const EdgeInsets.fromLTRB(16, 4, 16, 24)
          : const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _StaggerIn(
              index: i,
              enter: _enter,
              child: _HoverLift(child: GlassCard(child: cards[i])),
            ),
          ],
        ],
      ),
    );
  }
}

/// 整卡导航启动器：首页卡片整卡可点，点击后经容器展开转场进入
/// [path]（页面从卡片矩形生长）。hover 时右上角浮现角标箭头并悬停
/// 显示目的地说明（提示语规范）；按压 120ms 轻回缩（反馈档）。
/// 内部仍有手势的卡（如走势卡的时间滚筒）不受影响——手势竞技场
/// 中内层识别器优先。
class _CardLauncher extends StatefulWidget {
  const _CardLauncher({
    required this.heroKey,
    required this.path,
    required this.hint,
    required this.child,
  });

  final GlobalKey heroKey;
  final String path;
  final String hint;
  final Widget child;

  @override
  State<_CardLauncher> createState() => _CardLauncherState();
}

class _CardLauncherState extends State<_CardLauncher> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Semantics(
            button: true,
            label: widget.hint,
            child: GestureDetector(
              key: widget.heroKey,
              behavior: HitTestBehavior.opaque,
              onTap: () => HeroLaunch.go(context, widget.path, widget.heroKey),
              child: Stack(
                children: [
                  widget.child,
                  Positioned(
                    right: 10,
                    top: 10,
                    child: IgnorePointer(
                      ignoring: !_hover,
                      child: AnimatedOpacity(
                        opacity: _hover ? 1 : 0,
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOut,
                        child: Tooltip(
                          message: widget.hint,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF7EA6D9).withValues(
                                alpha: 0.22,
                              ),
                              border: Border.all(
                                color: const Color(0x66BFD9F2),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_outward,
                              size: 15,
                              color: Color(0xFFBFD9F2),
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

/// 桌面 hover 抬升：上浮 3px + 投影加深 + 0.6% 放大（180ms easeOut）。
/// MouseRegion 只在鼠标环境触发，触屏设备自然无效。
class _HoverLift extends StatefulWidget {
  const _HoverLift({required this.child});

  final Widget child;

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: theme.brightness == Brightness.light
                        ? const Color(0x14000000)
                        : Colors.black.withValues(alpha: 0.45),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: AnimatedScale(
          scale: _hover ? 1.006 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 单卡入场：区间 [0.06·i 截止 0.45, +0.45] 淡入 + 12px 上浮，easeOutCubic。
class _StaggerIn extends StatelessWidget {
  const _StaggerIn({
    required this.index,
    required this.enter,
    required this.child,
  });

  final int index;
  final Animation<double> enter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final begin = (0.06 * index).clamp(0.0, 0.45);
    final curved = CurvedAnimation(
      parent: enter,
      curve: Interval(begin, (begin + 0.45).clamp(0.0, 1.0)),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final t = curved.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

/// 解锁时自动落地了计划交易的透明提示（只提示一次）。
class _AutoPostNotice extends ConsumerStatefulWidget {
  const _AutoPostNotice();

  @override
  ConsumerState<_AutoPostNotice> createState() => _AutoPostNoticeState();
}

/// AI 每日估值后台完成通知：轮询 [VaultUnlocked.aiValuationNotice]
/// （负值=有失败项），提示一次并刷新首页统计。估值一般几十秒内
/// 完成，轮询 4 分钟后自停。
class _AiValuationNotice extends ConsumerStatefulWidget {
  const _AiValuationNotice();

  @override
  ConsumerState<_AiValuationNotice> createState() =>
      _AiValuationNoticeState();
}

class _AiValuationNoticeState extends ConsumerState<_AiValuationNotice> {
  Timer? _poll;
  Timer? _stopgap;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted) return;
      final s = sessionOf(ref.read(vaultProvider));
      final n = s?.aiValuationNotice ?? 0;
      if (n == 0) return;
      s!.aiValuationNotice = 0;
      _poll?.cancel();
      unawaited(ref.refresh(dashboardProvider.future));
      if (!mounted) return;
      final failed = n < 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failed
                ? 'AI 已更新 ${-n} 项资产估值（部分失败，可在账户详情查看）'
                : 'AI 已更新 $n 项资产估值（来源可审计，可在账户详情纠正）',
          ),
        ),
      );
    });
    // 4 分钟兜底自停（估值偶尔慢网）。存句柄：dispose 一并取消，
    // 否则页面卸载后残留 Pending timer（widget 测试会失败）。
    _stopgap = Timer(const Duration(minutes: 4), () => _poll?.cancel());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _stopgap?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _AutoPostNoticeState extends ConsumerState<_AutoPostNotice> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = sessionOf(ref.read(vaultProvider));
      if (s == null || s.autoPostedCount <= 0) return;
      final n = s.autoPostedCount;
      s.autoPostedCount = 0;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已按计划自动记入 $n 笔交易，可在流水中查看（来源：计划）')));
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
