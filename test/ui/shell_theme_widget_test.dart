import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:assetscope/app/providers.dart';
import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/ui/budget/budgets_page.dart';
import 'package:assetscope/ui/dashboard/dashboard_page.dart';
import 'package:assetscope/ui/home_shell.dart';
import 'package:assetscope/ui/settings/settings_page.dart';

import 'widget_host.dart';

/// 导航框架与外观模式：底部导航"4 高频 + 更多"、选中态、主题切换持久化。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late VaultUnlocked session;
  bool dbAvailable = true;

  setUp(() async {
    try {
      db = AppDatabase(NativeDatabase.memory());
      await db.customSelect('SELECT 1').getSingle();
    } catch (_) {
      dbAvailable = false;
      return;
    }
    session = await buildWidgetSession(db);
    await seedWidgetData(session);
  });

  tearDown(() async {
    if (dbAvailable) await db.close();
  });

  GoRouter router() => GoRouter(
        initialLocation: '/',
        routes: [
          ShellRoute(
            builder: (_, _, child) => HomeShell(body: child),
            routes: [
              GoRoute(path: '/', builder: (_, _) => const DashboardPage()),
              GoRoute(path: '/budgets', builder: (_, _) => const BudgetsPage()),
              GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
            ],
          ),
        ],
      );

  Widget shellHost() => ProviderScope(
        overrides: [vaultProvider.overrideWith(() => FixedVault(session))],
        child: MaterialApp.router(routerConfig: router()),
      );

  testWidgets('底部导航：高频直达 + 更多弹层进入次要页并保持选中', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    // 默认测试视口 800x600 < 900 → 底部导航分支。
    await tester.pumpWidget(shellHost());
    await tester.pumpAndSettle();

    // 首页：总览选中（此前用 startsWith('/') 导致任何路径都选中总览）。
    var navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 0);

    // 高频直达：流水/月报在底栏；预算走"更多"。
    await tester.tap(find.text('更多'));
    await tester.pumpAndSettle();
    expect(find.text('计划'), findsOneWidget, reason: '次要目的地应出现在弹层');
    await tester.tap(find.text('预算'));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetsPage), findsOneWidget, reason: '应导航到预算页');

    // 次要页保持"更多"选中（修复前任何路径都错亮"总览"）。
    navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 4);

    // 高频页直接点底栏返回。
    await tester.tap(find.text('总览'));
    await tester.pumpAndSettle();
    navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 0);
    expect(find.byType(DashboardPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('设置：外观切换立即生效并写入设置表', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    final container = ProviderContainer(
      overrides: [vaultProvider.overrideWith(() => FixedVault(session))],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: const SettingsPage()),
    ));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.system);

    // 新增入口（如"从备份合并"）可能把外观项挤出视口，先滚动到位。
    await tester.scrollUntilVisible(find.text('外观'), 200);
    await tester.tap(find.text('外观'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('深色').last);
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark,
        reason: '切换后应立即生效');
    expect(await session.meta.settingString('themeMode'), 'dark',
        reason: '偏好应持久化到设置表');

    // 关闭页签提示。
    expect(find.text('外观'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
