import 'dart:convert';
import 'dart:math' as math;

import 'package:assetscope/ui/globe/globe_home_page.dart';
import 'package:assetscope/ui/globe/globe_painter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_host.dart';

/// 首页沉浸回归（稳态变体）：页面进入空闲自转稳态（>2.5s，
/// velocity 已并入 idleOmega）后再滚轮——旧代码下一帧「惯性收敛」
/// 分支会把刚上报的沉浸一帧撤销（真机上滚轮缩放卡片从不消失）。
/// 单独成文件：首页地球测试同文件顺序执行有跨用例状态残留怪癖
/// （地球挂加载圈），文件级 isolate 隔离。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('稳态空闲自转后滚轮：卡片仍让位，且空闲后复原（回归）', (tester) async {
    // 回归场景：页面挂载超 2.5s 已进入空闲自转稳态（_velocity 已并入
    // _idleOmega）再滚轮——旧代码此时下一帧「惯性收敛」分支会把刚
    // 上报的沉浸一帧撤销（真机上滚轮缩放卡片从不消失；上一条测试
    // 960ms 就发事件，未到稳态所以测不出）。
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
      // 泵过 2.5s：空闲计时器已把地球并入稳态自转（velocity==idleOmega）。
      for (var i = 0; i < 30; i++) {
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

      final canvas = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is GlobePainter,
      );
      final center = tester.getCenter(canvas);
      expect(cardOpacity(), greaterThan(0.99)); // 稳态：卡片满血在场

      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: center,
          scrollDelta: const Offset(0, -120),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      expect(cardOpacity(), lessThan(0.35), reason: '稳态自转中滚轮也应进入沉浸');
      await tester.pump(const Duration(milliseconds: 400));
      expect(cardOpacity(), lessThan(0.05));

      // 空闲 2.5s 计时器到期 → 退出沉浸，卡片复原。
      for (var i = 0; i < 13; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(cardOpacity(), greaterThan(0.99), reason: '空闲后页面应复原');
      expect(tester.takeException(), isNull);
    } finally {
      await db.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    }
  });
}
