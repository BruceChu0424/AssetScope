import 'dart:convert';

import 'package:assetscope/ui/globe/globe_page.dart';
import 'package:assetscope/ui/globe/globe_painter.dart';
import 'package:assetscope/ui/globe/immersive_globe_host.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_host.dart';

/// 沉浸式地球宿主与滚轮缩放回归。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 地球大陆点阵资产 mock（widget 测试资产通道默认不通）。
  void mockLandDots() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          if (key == 'assets/globe/land_dots.json') {
            const dots = '[[116.4, 39.9], [151.2, -33.9], [-74.0, 40.7]]';
            return ByteData.view(Uint8List.fromList(utf8.encode(dots)).buffer);
          }
          return null;
        });
  }

  void unmockLandDots() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  }

  testWidgets('沉浸宿主：交互时地球自槽位扩张为全屏，空闲后收回槽位', (tester) async {
    late void Function(bool) immerse;
    final globe = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImmersiveGlobeHost(
            globeBuilder: (cb) {
              immerse = cb;
              return SizedBox(key: globe);
            },
            builder: (context, anim, slot) => Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 120, height: 100, key: slot),
            ),
          ),
        ),
      ),
    );
    await tester.pump(); // 首帧后测量槽位
    expect(
      tester.getRect(find.byKey(globe)),
      const Rect.fromLTWH(0, 0, 120, 100),
    );

    immerse(true); // 交互进行中：扩张为整页
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(globe)),
      const Rect.fromLTWH(0, 0, 800, 600),
    );

    immerse(false); // 空闲恢复：收回槽位
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(globe)),
      const Rect.fromLTWH(0, 0, 120, 100),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('鼠标滚轮缩放地球：上滚放大、下滚缩小', (tester) async {
    mockLandDots();
    final db = widgetDb();
    try {
      await db.customSelect('SELECT 1').getSingle();
    } catch (_) {
      await db.close();
      unmockLandDots();
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    final session = await buildWidgetSession(db);
    try {
      await tester.pumpWidget(widgetHost(const GlobePage(), session));
      await tester.pump(const Duration(milliseconds: 50));
      final canvas = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is GlobePainter,
      );
      expect(canvas, findsOneWidget);
      final center = tester.getCenter(canvas);
      double zoomOf() =>
          ((tester.widget(canvas) as CustomPaint).painter as GlobePainter)
              .view
              .zoom;

      final before = zoomOf();
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: center,
          scrollDelta: const Offset(0, -120),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      final zoomedIn = zoomOf();
      expect(zoomedIn, greaterThan(before));

      await tester.sendEventToBinding(
        PointerScrollEvent(position: center, scrollDelta: const Offset(0, 200)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(zoomOf(), lessThan(zoomedIn));
      expect(tester.takeException(), isNull);
    } finally {
      await db.close();
      unmockLandDots();
    }
  });
}
