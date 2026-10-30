import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/ai/assistant_page.dart';
import '../ui/budget/budgets_page.dart';
import '../ui/debts/debts_page.dart';
import '../ui/goals/goals_page.dart';
import '../ui/globe/globe_home_page.dart';
import '../ui/globe/globe_page.dart';
import '../ui/home_shell.dart';
import '../ui/lock/lock_page.dart';
import '../ui/planning/plans_page.dart';
import '../ui/reports/report_page.dart';
import '../ui/settings/settings_page.dart';
import '../ui/theme/app_theme.dart';
import '../ui/transactions/transactions_page.dart';
import '../ui/widgets/common.dart';
import '../ui/widgets/window_chrome.dart';
import 'providers.dart';class AssetScopeApp extends ConsumerWidget {
  AssetScopeApp({super.key});

  final Map<bool, GoRouter> _routers = {};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(vaultProvider);
    final locked = vault is! VaultUnlocked;
    final router = _routers.putIfAbsent(locked, () => _buildRouter(locked));
    return MaterialApp.router(
      title: '资观 AssetScope',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
      routerConfig: router,
      builder: (context, child) {
        // 无边框窗口框体（拖拽条 + 红绿灯）置于最外层：锁屏与正常页面
        // 顶部都不再有原生标题条。触摸观察走全局 PointerRoute（无渲染
        // 对象）——用 Listener 会给整棵树盖上 RenderPointerListener，让
        // WindowChrome 拖拽条在任何位置都误判「下方有交互」而失效。
        // BusyHost 在 Navigator 之上收留粒子舞台：解锁换 router（整树
        // 替换）时舞台不随旧 navigator 销毁，散场编排得以跨树完成。
        return WindowChrome(
          child: BusyHost(
            child: _TouchObserver(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }

  GoRouter _buildRouter(bool locked) {
    return GoRouter(
      initialLocation: locked ? '/lock' : '/',
      redirect: (context, state) {
        final loc = state.matchedLocation;
        if (locked && loc != '/lock') return '/lock';
        if (!locked && loc == '/lock') return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/lock', builder: (_, _) => const LockPage()),
        GoRoute(path: '/globe', builder: (_, _) => const GlobePage()),
        ShellRoute(
          builder: (_, _, child) => HomeShell(body: child),
          routes: [
            _fadeThrough('/', (_, _) => const GlobeHomePage()),
            _page('/transactions', (_, _) => const TransactionsPage()),
            _page('/budgets', (_, _) => const BudgetsPage()),
            _page('/plans', (_, _) => const PlansPage()),
            _page('/goals', (_, _) => const GoalsPage()),
            _page('/debts', (_, _) => const DebtsPage()),
            _page('/reports', (_, _) => const ReportPage()),
            _page('/ai', (_, _) => const AssistantPage()),
            _page('/settings', (_, _) => const SettingsPage()),
          ],
        ),
      ],
    );
  }

  /// Shell 内页面：默认 240ms 淡入 + 6px 上浮；若导航来自首页卡片的
  /// 容器展开（HeroLaunch），先播 420ms/320ms 的「从卡片生长」转场。
  /// 「减少动画」时一律退回淡入。
  GoRoute _page(
    String path,
    Widget Function(BuildContext, GoRouterState) builder,
  ) {
    return GoRoute(
      path: path,
      pageBuilder: (context, state) {
        final from = HeroLaunch.takeFor(path);
        if (from != null && !MediaQuery.disableAnimationsOf(context)) {
          return CustomTransitionPage(
            key: state.pageKey,
            transitionDuration: const Duration(milliseconds: 420),
            reverseTransitionDuration: const Duration(milliseconds: 320),
            transitionsBuilder: (context, animation, _, child) =>
                HeroGrow(animation: animation, from: from, child: child),
            child: builder(context, state),
          );
        }
        return _fadePage(state.pageKey, builder(context, state));
      },
    );
  }

  GoRoute _fadeThrough(
    String path,
    Widget Function(BuildContext, GoRouterState) builder,
  ) =>
      GoRoute(
        path: path,
        pageBuilder: (context, state) =>
            _fadePage(state.pageKey, builder(context, state)),
      );

  static CustomTransitionPage<void> _fadePage(LocalKey key, Widget child) {
    return CustomTransitionPage<void>(
      key: key,
      transitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (context, animation, _, child) {
        final t = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: t,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.99, end: 1).animate(t),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 6 / 400),
                end: Offset.zero,
              ).animate(t),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// 全局触摸观察：解锁状态下任何指针按下即重置自动锁定计时。
/// 用 [GestureBinding.pointerRouter] 而非 Listener——后者会在整棵树的
/// 命中链上留下 RenderPointerListener，污染命中测试（保持链干净）。
class _TouchObserver extends ConsumerStatefulWidget {
  const _TouchObserver({required this.child});

  final Widget child;

  @override
  ConsumerState<_TouchObserver> createState() => _TouchObserverState();
}

class _TouchObserverState extends ConsumerState<_TouchObserver> {
  void _onPointerEvent(PointerEvent event) {
    if (event is PointerDownEvent && ref.read(vaultProvider) is VaultUnlocked) {
      ref.read(vaultProvider.notifier).touch();
    }
  }

  @override
  void initState() {
    super.initState();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointerEvent);
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointerEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
