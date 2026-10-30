import 'dart:convert';
import 'dart:math' as math;

import 'package:assetscope/ui/globe/globe_home_page.dart';
import 'package:assetscope/ui/globe/globe_painter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_host.dart';

/// 首页沉浸回归：滚轮缩放地球 → 两侧卡片让位淡出。
/// 单独成文件：与其它地球测试同文件顺序执行时，测试绑定的跨用例
/// 状态残留会让首页地球挂起在加载圈（隔离运行即正常，属 harness
/// 怪癖而非产品问题），文件级 isolate 天然隔离。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('首页滚轮缩放：两侧卡片让位淡出（感知性回归）', (tester) async {
    // 宽屏（≥1120 对称双翼布局）与用户桌面场景一致。
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
      // 含常驻动画，定时泵帧等异步数据落定。
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      expect(find.text('净资产'), findsOneWidget);

      // 净资产卡文本向上的全部 FadeTransition，取最小不透明度。
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
      expect(cardOpacity(), greaterThan(0.99));

      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: center,
          scrollDelta: const Offset(0, -120),
        ),
      );
      // 感知性契约：淡出必须跑在沉浸前半程——500ms 已明显退场，
      // 900ms 完全消失（慢起步的全程曲线曾让前 400ms 几乎不可见）。
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      expect(cardOpacity(), lessThan(0.35));
      await tester.pump(const Duration(milliseconds: 400));
      expect(cardOpacity(), lessThan(0.05));
      expect(tester.takeException(), isNull);
    } finally {
      await db.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    }
  });
}
