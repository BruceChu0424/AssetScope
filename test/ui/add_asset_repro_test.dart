import 'dart:convert';

import 'package:assetscope/app/providers.dart';
import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/ui/accounts/account_edit_dialog.dart';
import 'package:assetscope/ui/globe/globe_home_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'widget_host.dart';
import 'package:assetscope/l10n/app_localizations.dart';

/// 「添加资产」弹窗复现：用户真机点击后无弹窗 + release 闪退；
/// errors.log 定位到 AlertDialog 布局断言（child!.hasSize）。
/// 本测试在测试环境全链路复现点击，观察是否抛布局异常。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (key == 'assets/globe/land_dots.json') {
        const dots = '[[116.4, 39.9], [151.2, -33.9], [-74.0, 40.7]]';
        return ByteData.view(
            Uint8List.fromList(utf8.encode(dots)).buffer);
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
        return ByteData.view(
            Uint8List.fromList(base64Decode(png)).buffer);
      }
      return null;
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  testWidgets('点击添加资产：AccountEditDialog 应完整弹出无布局异常', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    try {
      await db.customSelect('SELECT 1').getSingle();
    } catch (_) {
      await db.close();
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    final session = await buildWidgetSession(db);
    try {
      tester.view.physicalSize = const Size(1920, 1040); // 用户真机为最大化
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      GoRouter router() => GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                  path: '/', builder: (_, _) => const GlobeHomePage()),
      ],
          );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          vaultProvider.overrideWith(() => FixedVault(session)),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          routerConfig: router()),
      ));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // 打开果冻菜单 → 点「添加资产」。
      await tester.tap(find.byTooltip('记一笔 / 添加资产'));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.tap(find.text('添加资产'));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(tester.takeException(), isNull,
          reason: '弹出过程中不得有布局/构建异常');
      expect(find.byType(AccountEditDialog), findsOneWidget,
          reason: '添加资产弹窗必须出现');
      expect(find.text('新建资产'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    } finally {
      await db.close();
    }
  });
}
