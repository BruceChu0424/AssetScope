import 'dart:convert';
import 'dart:math' as math;

import 'package:assetscope/ui/globe/globe_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_host.dart';

/// 首页「清屏地球」钉住沉浸回归：右上角按钮原地切换（不跳 /globe），
/// 清屏期间跨 2.5s 空闲自转不回弹，再点恢复页面。
/// 单独成文件：首页地球测试同文件顺序执行有跨用例状态残留怪癖
/// （地球挂加载圈），文件级 isolate 隔离。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('清屏地球：卡片清场钉住跨空闲不回弹，再点恢复', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          if (key == 'assets/globe/land_dots.json') {
            const dots = '[[116.4, 39.9], [151.2, -33.9], [-74.0, 40.7]]';
            return ByteData.view(Uint8List.fromList(utf8.encode(dots)).buffer);
          }
          return null;
        });
    final db = widgetDb();
    try {
      await db.customSelect('SELECT 1').getSingle();
    } catch (_) {
      await db.close();
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    final session = await buildWidgetSession(db);
    await seedWidgetData(session);
    try {
      await tester.pumpWidget(widgetHost(const GlobeHomePage(), session));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      double cardOpacity() {
        final fades = find
            .ancestor(
              of: find.text('净资产'),
              matching: find.byType(FadeTransition),
            )
            .evaluate();
        var min = 1.0;
        for (final el in fades) {
          final w = el.widget as FadeTransition;
          min = math.min(min, w.opacity.value);
        }
        return min;
      }

      expect(cardOpacity(), greaterThan(0.99));
      final clearBtn = find.byTooltip('清屏地球：只留中央地球');
      expect(clearBtn, findsOneWidget);

      // 点按：原地清屏（卡片退场、地球扩张），不发生路由跳转。
      await tester.tap(clearBtn, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      expect(cardOpacity(), lessThan(0.35));
      await tester.pump(const Duration(milliseconds: 400));
      expect(cardOpacity(), lessThan(0.05));

      // 钉住语义：跨过 2.5s 空闲（地球侧会报退出沉浸）页面不得回弹。
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(
        cardOpacity(),
        lessThan(0.05),
        reason: '清屏是钉住的，空闲自转恢复不应把卡片带回来',
      );

      // 再点（钮已变「恢复页面」）：页面复原。
      final restoreBtn = find.byTooltip('恢复页面');
      expect(restoreBtn, findsOneWidget);
      await tester.tap(restoreBtn, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 700));
      expect(cardOpacity(), greaterThan(0.99));
      expect(tester.takeException(), isNull);
    } finally {
      await db.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    }
  });
}
