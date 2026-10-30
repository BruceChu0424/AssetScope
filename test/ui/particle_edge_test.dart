import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assetscope/ui/widgets/particle_interactive.dart';

/// ParticleEdge 底缘光尘：触发接线与「测试环境静态帧」工艺回归。
///
/// 关键守护：FLUTTER_TEST 环境下组件不得启动常驻 Ticker——悬停/聚焦
/// 状态中 pumpAndSettle 必须能收尾（否则全部页面的既有测试会被卡死）。
void main() {
  Finder dustCanvas() => find.descendant(
    of: find.byType(ParticleEdge),
    matching: find.byWidgetPredicate(
      (w) => w is CustomPaint && w.foregroundPainter != null,
    ),
  );

  testWidgets('hover 激活光尘画布，pumpAndSettle 仍能收尾', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ParticleEdge(
              band: 18,
              child: SizedBox(width: 220, height: 64, child: Text('卡')),
            ),
          ),
        ),
      ),
    );
    expect(dustCanvas(), findsOneWidget);

    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(ParticleEdge)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    // 静态帧模式：无常驻 Ticker，settle 可收尾（去掉测试门控即超时）。
    await tester.pumpAndSettle();

    await gesture.moveTo(const Offset(5, 5));
    await tester.pumpAndSettle();
  });

  testWidgets('聚焦 + 输入中不抛异常（ParticleTextField）', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ParticleTextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: '主口令'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ParticleTextField),
        matching: find.byWidgetPredicate(
          (w) => w is CustomPaint && w.foregroundPainter != null,
        ),
      ),
      findsAtLeastNWidgets(1), // 自身画布 + 输入框光标画布
    );

    await tester.enterText(find.byType(TextField), 'passphrase-1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle(); // 输入迸发在测试环境同样不起时钟
  });

  testWidgets('「减少动画」时整带禁用（不激活）', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: ParticleEdge(
                child: SizedBox(width: 220, height: 64, child: Text('卡')),
              ),
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(ParticleEdge)));
    await tester.pump();
    await tester.pumpAndSettle(); // 不激活、不抛异常、可收尾
  });

  testWidgets('active 外部驱动模式随布尔切换', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ParticleEdge.active(
              active: true,
              child: SizedBox(width: 120, height: 40, child: Text('钮')),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(dustCanvas(), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
