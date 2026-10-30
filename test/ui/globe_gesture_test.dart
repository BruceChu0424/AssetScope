import 'dart:convert';

import 'package:assetscope/ui/globe/globe_page.dart';
import 'package:assetscope/ui/globe/globe_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_host.dart';

/// 地球页手势层回归：资产加载完成后 GestureDetector 才真正构建。
/// widget 测试里资产通道默认不通（body 停在加载圈），旧冒烟测试只验
/// AppBar 标题，pan+scale 并存的框架断言因此漏网、真机红屏。
/// 这里 mock 资产通道强制走到手势层。
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
      return null;
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  testWidgets('地球页手势层构建与拖拽无异常（pan+scale 断言回归）', (tester) async {
    final db = widgetDb();
    try {
      await db.customSelect('SELECT 1').getSingle();
    } catch (_) {
      await db.close();
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    final session = await buildWidgetSession(db);
    try {
      await tester.pumpWidget(widgetHost(const GlobePage(), session));
      // 资产 mock 加载完成 → body 进入手势层；断言即在此抛出（曾红屏）。
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      // MaterialApp 外层自带一个 GestureDetector；页面手势层是更深处的。
      // 直接以地球画布（CustomPaint）为中心取点——画布之上还叠有
      // Tooltip/InkWell 悬浮操作（自带 GestureDetector），用「最后一个
      // GestureDetector」定位会点到悬浮按钮上去。
      final gestures = find.byType(GestureDetector);
      expect(gestures, findsWidgets);
      final canvas = find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is GlobePainter);
      expect(canvas, findsOneWidget);
      final center = tester.getCenter(canvas);

      // 单指拖拽（scale 识别器路径）：旋转 + 惯性收尾不抛异常。
      await tester.dragFrom(center, const Offset(80, 0));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);

      // 纵向拖拽（曾因投影镜像方向颠倒）与快速点按（tap 识别器共存）。
      await tester.dragFrom(center, const Offset(0, -60));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    } finally {
      await db.close();
    }
  });
}
