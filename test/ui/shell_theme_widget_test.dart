import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:assetscope/app/providers.dart';
import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/ui/globe/globe_home_page.dart';
import 'package:assetscope/ui/settings/settings_page.dart';
import 'package:assetscope/ui/overview/inbox_page.dart';
import 'package:assetscope/ui/widgets/common.dart' show PageBackButton;

import 'widget_host.dart';
import 'package:assetscope/l10n/app_localizations.dart';

/// 首页即枢纽（2026-10-30 导航体系删除）：右上集群承载目的地入口
/// （待办 / AI / 设置），其余页面一律返回键回上层；外观模式持久化。
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
          GoRoute(path: '/', builder: (_, _) => const GlobeHomePage()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
          GoRoute(path: '/inbox', builder: (_, _) => const InboxPage()),
        ],
      );

  Widget shellHost() => ProviderScope(
        overrides: [vaultProvider.overrideWith(() => FixedVault(session))],
        child: MaterialApp.router(
          routerConfig: router(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
        ),
      );

  /// 首页地球常驻动画（自转/呼吸/粒子标）不会"settle"，改定时泵帧。
  Future<void> pumpMs(WidgetTester tester, int ms) async {
    var left = ms;
    while (left > 0) {
      final step = left > 200 ? 200 : left;
      await tester.pump(Duration(milliseconds: step));
      left -= step;
    }
  }

  testWidgets('首页枢纽：右上集群直达设置/待办，返回键回首页', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    await tester.pumpWidget(shellHost());
    await pumpMs(tester, 1000);

    // 左上角是品牌粒子标（不再是导航入口）；右上集群六钮齐全。
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
    expect(find.byIcon(Icons.checklist), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);

    // 设置直达。
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await pumpMs(tester, 600);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);

    // 返回键回上层（栈空回总览）。
    await tester.tap(find.byType(PageBackButton));
    await pumpMs(tester, 800);
    expect(find.byType(GlobeHomePage), findsOneWidget);

    // 待办直达（原右列「待处理卡」已删，入口收敛到这枚钮）。
    await tester.tap(find.byIcon(Icons.checklist));
    await pumpMs(tester, 600);
    await tester.pumpAndSettle();
    expect(find.byType(InboxPage), findsOneWidget);
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
      child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),home: const SettingsPage()),
    ));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.system);

    // 深空控制舱改版：小屏为「横向分类胶囊 + 当前分类内容」。主题模式
    // 行在「偏好」分类里——先切分类，再进主题模式项。
    await tester.tap(find.text('偏好'));
    await tester.pumpAndSettle();
    // （非懒加载 ListView 的所有子树都参与 finder，scrollUntilVisible
    // 会误判"已可见"，用 ensureVisible 真正滚动。）
    await tester.ensureVisible(find.text('主题模式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('主题模式'));
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
