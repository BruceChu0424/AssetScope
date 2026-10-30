import 'dart:convert';

import 'package:assetscope/app/providers.dart';
import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/ui/globe/globe_home_page.dart';
import 'package:assetscope/ui/home_shell.dart';
import 'package:assetscope/ui/transactions/add_transaction_dialog.dart';
import 'package:assetscope/ui/widgets/floating_nav_rail.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'widget_host.dart';

/// 首页右下角快捷添加（果冻菜单）回归：
/// ① 点击胶囊后弹窗（记一笔/添加资产）必须真正弹出；
/// ② 点空白收起后，磨砂暗纱不得继续拦截整页指针事件。
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
        // 空清单（标准消息编码的 map），满足 AssetImage 解析流程。
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
        // 品牌 PNG 兜底 1×1 透明图，避免图片解码异常噪声。
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

  /// 果冻菜单暗纱的 IgnorePointer（收起后必须回到 ignoring=true）。
  Finder scrimIgnorePointer() => find.byWidgetPredicate(
        (w) =>
            w is IgnorePointer &&
            w.child is FadeTransition &&
            (w.child as FadeTransition).child is GestureDetector,
      );

  testWidgets('快捷菜单：胶囊弹出记一笔弹窗 + 空白收起后不挡事件', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(shellHost());
    await pumpMs(tester, 1200); // 等仪表盘数据 + 入场动画

    // 初始：暗纱不拦截。
    expect(
      tester.widget<IgnorePointer>(scrimIgnorePointer()).ignoring,
      isTrue,
      reason: '菜单未打开时暗纱应忽略指针',
    );

    // 打开果冻菜单。
    await tester.tap(find.byTooltip('记一笔 / 添加资产'));
    await pumpMs(tester, 700);
    expect(
      tester.widget<IgnorePointer>(scrimIgnorePointer()).ignoring,
      isFalse,
      reason: '菜单打开时暗纱应可点（点空白收起）——状态必须随动画同步',
    );

    // 点「记一笔」胶囊 → 弹窗必须出现。
    await tester.tap(find.text('记一笔'));
    await pumpMs(tester, 400);
    expect(find.byType(AddTransactionDialog), findsOneWidget,
        reason: '点击胶囊后记一笔弹窗应弹出');

    // 收尾：消化弹窗（输入框光标 Timer）后卸载。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('快捷菜单：点空白收起后暗纱恢复忽略指针（整页可交互）', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(shellHost());
    await pumpMs(tester, 1200);

    await tester.tap(find.byTooltip('记一笔 / 添加资产'));
    await pumpMs(tester, 700);

    // 点菜单外的空白处收起。
    await tester.tapAt(const Offset(720, 450));
    await pumpMs(tester, 400); // 收起动画 240ms 结束后应恢复 ignoring
    expect(
      tester.widget<IgnorePointer>(scrimIgnorePointer()).ignoring,
      isTrue,
      reason: '收起动画结束后暗纱必须恢复忽略指针，否则整页被透明层挡住',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('导航展开时点击外部：只收起导航，不误触添加按钮', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(shellHost());
    await pumpMs(tester, 1200);

    // 展开分类菜单（桌面浮层导航）。
    final rail = find.byType(FloatingNavRail);
    expect(rail, findsOneWidget);
    await tester.tap(find.byTooltip('展开分类菜单'));
    await pumpMs(tester, 500);
    expect(tester.widget<FloatingNavRail>(rail).expanded, isTrue);

    // 在添加按钮（右下角）上点击：导航应收起，添加菜单不得被这一击
    // 顺势打开（旧版透明 Listener 会放行穿透）。胶囊文本常驻树中，
    // 开合状态用暗纱命中态判定。
    await tester.tap(find.byTooltip('记一笔 / 添加资产'), warnIfMissed: false);
    await pumpMs(tester, 400);
    expect(tester.widget<FloatingNavRail>(rail).expanded, isFalse,
        reason: '点外部应收起导航');
    expect(
      tester.widget<IgnorePointer>(scrimIgnorePointer()).ignoring,
      isTrue,
      reason: '首击被收起屏障吸收：快捷菜单未打开，暗纱保持忽略指针',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('快捷菜单：快速连点/中途反向后必须停在开或合的终态', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(shellHost());
    await pumpMs(tester, 1200);
    final fab = find.byTooltip('记一笔 / 添加资产');

    // 时序 A：展开途中再点（<0.5 时 forward 幂等）→ 停在「开」。
    await tester.tap(fab);
    await pumpMs(tester, 220); // ~0.35：正是截图蒙版可疑区间
    await tester.tap(fab);
    await pumpMs(tester, 700);
    expect(
      tester.widget<IgnorePointer>(scrimIgnorePointer()).ignoring,
      isFalse,
      reason: '中途连点后菜单应完全打开',
    );

    // 时序 B：收起途中点暗纱再点按钮（>0.5 反向、<0.5 再正向）→ 停终态。
    await tester.tapAt(const Offset(720, 450)); // 收起
    await pumpMs(tester, 90); // ~0.6：仍在反向
    await tester.tapAt(const Offset(720, 450)); // 再次收起（幂等）
    await pumpMs(tester, 400);
    var ignoring = tester.widget<IgnorePointer>(scrimIgnorePointer()).ignoring;
    expect(ignoring, isTrue, reason: '收起必须彻底完成');

    // 时序 C：展开途中点暗纱（<0.5 → forward 继续完成）→ 停在「开」。
    await tester.tap(fab);
    await pumpMs(tester, 150);
    await tester.tapAt(const Offset(720, 450));
    await pumpMs(tester, 700);
    expect(
      tester.widget<IgnorePointer>(scrimIgnorePointer()).ignoring,
      isFalse,
      reason: '低进度时点暗纱不得吞掉正向动画',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('走势卡时间转轴：拖动滚筒拉长/收短区间，标题联动', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    // 高视口让右列卡片全部可见，免滚动定位。
    tester.view.physicalSize = const Size(1500, 1700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(shellHost());
    await pumpMs(tester, 1500);

    // 默认 12 个月。
    expect(find.text('净资产走势（近 12 个月）'), findsOneWidget);

    final roller = find.byKey(const Key('trend-roller'));
    expect(roller, findsOneWidget);

    // 小步连续拖（真实手势节奏，单次大跳变竞技场不裁决）。
    Future<void> dragRoller(Offset delta) async {
      final g = await tester.startGesture(tester.getCenter(roller));
      const steps = 20;
      for (var i = 0; i < steps; i++) {
        await g.moveBy(Offset(delta.dx / steps, delta.dy / steps));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await pumpMs(tester, 250);
    }

    // 向右拖到底：拉长到 36 个月。
    await dragRoller(const Offset(600, 0));
    expect(find.text('净资产走势（近 36 个月）'), findsOneWidget,
        reason: '右拖应拉长时间区间到 36 个月');

    // 向左拖到底：收短到 1 个月（用户要求一个月起步）。
    await dragRoller(const Offset(-600, 0));
    expect(find.text('净资产走势（近 1 个月）'), findsOneWidget,
        reason: '左拖应收短时间区间到 1 个月');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
