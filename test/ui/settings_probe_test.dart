import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/app/providers.dart';
import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/ui/settings/settings_page.dart';
import 'package:assetscope/ui/settings/settings_kit.dart';
import 'package:assetscope/ui/settings/settings_security.dart';
import 'package:assetscope/ui/globe/glass_card.dart';
import 'package:assetscope/l10n/app_localizations.dart';

import 'widget_host.dart';

/// 设置页深空控制舱改版 · 结构探针：两档尺寸下验证骨架（导航/概览/
/// 操作卡/面板）真实挂载、无溢出、分类切换可用。无输入注入，纯被动。
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

  Future<void> boot(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [vaultProvider.overrideWith(() => FixedVault(session))],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('宽屏：安全分类骨架完整（导航台+概览+三操作卡+双面板）', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    await boot(tester, const Size(1600, 1000));

    // 玻璃导航台 + 六个分类条目。
    expect(find.byType(GlassCard), findsAtLeast(4), reason: '导航台+概览+面板至少 4 张玻璃卡');
    for (final label in ['安全', '备份与恢复', '偏好', '数据管理', 'AI 与行情', '关于']) {
      expect(find.text(label), findsWidgets, reason: '导航应含分类「$label」');
    }
    // 安全分类内容。
    expect(find.byType(SecuritySection), findsOneWidget);
    expect(find.byType(SettingsActionCard), findsNWidgets(3), reason: '三张核心操作卡');
    for (final label in ['立即锁定', '修改主口令', '重新生成恢复码', '会话与保护', '最近安全操作']) {
      expect(find.text(label), findsOneWidget, reason: '应有「$label」');
    }
    // 状态章（本地加密/主口令/恢复码）。
    expect(find.text('本地加密'), findsOneWidget);
    expect(find.text('主口令'), findsAtLeast(1));
    expect(find.text('已配置'), findsOneWidget, reason: 'FixedVault 直构默认恢复码已配置');

    // 切换到「关于」：品牌卡 + 版本面板（粒子 logo 常驻动画→定时泵帧）。
    await tester.tap(find.text('关于'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(find.byType(SecuritySection), findsNothing, reason: '旧分类应退场');
    expect(find.text('应用版本'), findsOneWidget);
    expect(find.text('v0.25.0'), findsOneWidget, reason: '品牌卡版本胶囊');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('小屏：横向分类胶囊 + 切换偏好可进主题模式', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    await boot(tester, const Size(480, 900));
    // 小屏默认安全分类：三操作卡纵向单列。
    expect(find.byType(SettingsActionCard), findsNWidgets(3));
    await tester.tap(find.text('偏好'));
    await tester.pumpAndSettle();
    expect(find.text('主题模式'), findsOneWidget);
    expect(find.text('本位币'), findsOneWidget);
    expect(find.text('现金预测期'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
