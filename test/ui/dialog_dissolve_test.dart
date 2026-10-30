import 'dart:convert';

import 'package:assetscope/app/providers.dart';
import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/ui/accounts/account_edit_dialog.dart';
import 'package:assetscope/ui/globe/globe_home_page.dart';
import 'package:assetscope/ui/home_shell.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'widget_host.dart';

/// 新建资产 · 粒子化保存回归：
/// ① 位置必填——不选位置点创建：顶部通知弹出、弹窗保留；
/// ② 选城市后创建：弹窗碎裂为粒子舞台（as-dissolve-stage 出现，
///    约 2.9s 后自动收场消失），账户带坐标落库；
/// ③ 无粒子化条件的路径（记一笔弹窗）不受影响（home_fab_test 已覆盖）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (key == 'assets/globe/land_dots.json') {
        const dots = '[[116.4, 39.9], [151.2, -33.9], [-74.0, 40.7]]';
        return ByteData.view(Uint8List.fromList(utf8.encode(dots)).buffer);
      }
      if (key == 'AssetManifest.bin') {
        return const StandardMessageCodec().encodeMessage(
          <String, Object>{
            'assets/logo/mark_light.png': <Object>[],
            'assets/logo/mark_dark.png': <Object>[],
            'assets/logo/lockup_light.png': <Object>[],
            'assets/logo/lockup_dark.png': <Object>[],
          },
        );
      }
      if (key.endsWith('.png')) {
        const png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
            'AAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
        return ByteData.view(Uint8List.fromList(base64Decode(png)).buffer);
      }
      return null;
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

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
              GoRoute(path: '/', builder: (_, _) => const GlobeHomePage()),
            ],
          ),
        ],
      );

  Widget shellHost() => ProviderScope(
        overrides: [vaultProvider.overrideWith(() => FixedVault(session))],
        child: MaterialApp.router(routerConfig: router()),
      );

  /// 首页常驻动画不 settle，一律定时泵帧。
  Future<void> pumpMs(WidgetTester tester, int ms) async {
    var left = ms;
    while (left > 0) {
      final step = left > 200 ? 200 : left;
      await tester.pump(Duration(milliseconds: step));
      left -= step;
    }
  }

  /// 打开快捷菜单并点「添加资产」，返回弹窗已就绪的测试器状态。
  Future<void> openAccountDialog(WidgetTester tester) async {
    await tester.tap(find.byTooltip('记一笔 / 添加资产'));
    await pumpMs(tester, 700);
    await tester.tap(find.text('添加资产'));
    await pumpMs(tester, 400);
    expect(find.byType(AccountEditDialog), findsOneWidget);
  }

  testWidgets('位置必填：未选位置 → 顶部通知 + 弹窗保留', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(shellHost());
    await pumpMs(tester, 1200); // 仪表盘数据 + 入场动画

    await openAccountDialog(tester);
    await tester.enterText(find.byType(TextField).first, '测试房');
    await tester.tap(find.text('创建资产'));
    await pumpMs(tester, 300);

    expect(
      find.text('请选择资产位置——保存后将在地球首页点亮对应坐标'),
      findsOneWidget,
      reason: '未选位置提交应弹顶部通知（表单错误规范：通知+红框+横摇）',
    );
    expect(
      find.byType(AccountEditDialog),
      findsOneWidget,
      reason: '校验未过弹窗不得关闭',
    );
    // 未落库。
    final accounts = await session.accounts.all();
    expect(accounts.any((a) => a.name == '测试房'), isFalse);

    // 收尾：消化弹窗与通知后卸载。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('选城市创建：粒子舞台接管 → 自动收场 → 账户带坐标落库', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(shellHost());
    await pumpMs(tester, 1200);

    await openAccountDialog(tester);
    await tester.enterText(find.byType(TextField).first, '测试房');
    // 地址自动适配：输入城市名即定位（无需点选候选）。
    await tester.enterText(find.widgetWithText(TextField, '位置'), '北京');
    await pumpMs(tester, 150);
    // 截图走 toImage/toByteData（dart:ui 原生 Future），须在真实事件
    // 循环（runAsync 区）里等它完成；回到泵帧区驱动舞台动画。
    await tester.runAsync(() async {
      await tester.tap(find.text('创建资产'));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    // 粒子舞台接管：全屏场景出现，弹窗内容已隐藏。
    expect(
      find.byKey(const ValueKey('as-dissolve-stage')),
      findsOneWidget,
      reason: '保存瞬间弹窗应碎裂为粒子舞台',
    );

    // 剧场时长 ~2.9s：泵完应自动收场消失。
    await pumpMs(tester, 3200);
    expect(
      find.byKey(const ValueKey('as-dissolve-stage')),
      findsNothing,
      reason: '粒子舞台应在闪耀收场后自动摘除',
    );
    expect(find.byType(AccountEditDialog), findsNothing);

    // 账户已带北京坐标落库。
    final accounts = await session.accounts.all();
    final created = accounts.firstWhere((a) => a.name == '测试房');
    expect(created.locationLat, 39.9);
    expect(created.locationLon, 116.4);
    expect(created.locationName, '北京');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
