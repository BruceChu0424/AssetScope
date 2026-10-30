import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/ui/widgets/common.dart';

/// runBusy 粒子舞台生命周期回归：
/// - 任务正常完成：舞台上屏 → hold 后自动收场，结果透传；
/// - 任务抛错且 showError=false：立即收场并重新抛出；
/// - 任务瞬时完成（弹窗挂监听前）：hold 定时器不丢失，弹窗不卡死；
/// - BusyHost 根 Overlay 舞台：router 式整树替换不销毁舞台，
///   syncReveal 揭幕钟持幕/揭幕时序正确。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAway(WidgetTester tester) async {
    // 冲完整条离场链：60ms 轮询触发 → postFrame pop → 路由 150ms
    // 反向过渡 → 销毁卸树（每段 pump 推进若干假时钟帧）。
    for (final ms in const [80, 80, 80, 80, 80, 200]) {
      await tester.pump(Duration(milliseconds: ms));
    }
  }

  testWidgets('成功：舞台上屏并自动收场，结果透传', (tester) async {
    String? got;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  got = await runBusy<String>(
                    context,
                    message: '正在测试…',
                    successMessage: '搞定',
                    showError: false,
                    task: () async => 'ok',
                  );
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump(); // 弹窗路由入栈
    expect(find.byKey(const ValueKey('as-busy-scene')), findsOneWidget);

    await tester.pump(const Duration(seconds: 2)); // hold 800ms + 出场
    await pumpAway(tester);
    expect(find.byKey(const ValueKey('as-busy-scene')), findsNothing);
    expect(got, 'ok');
  });

  testWidgets('失败（showError=false）：立即收场并重新抛出', (tester) async {
    Object? thrown;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  try {
                    await runBusy<void>(
                      context,
                      message: '正在测试…',
                      showError: false,
                      task: () async {
                        throw StateError('boom');
                      },
                    );
                  } catch (e) {
                    thrown = e;
                  }
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await pumpAway(tester);
    expect(find.byKey(const ValueKey('as-busy-scene')), findsNothing);
    expect(thrown, isStateError);
  });

  testWidgets('任务在挂监听前瞬完：hold 定时器补课，弹窗不卡死', (tester) async {
    int? got;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  got = await runBusy<int>(
                    context,
                    message: '瞬完…',
                    showError: false,
                    // 同步返回：client._succeed 在弹窗 build 之前触发。
                    task: () => Future.value(42),
                  );
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.byKey(const ValueKey('as-busy-scene')), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await pumpAway(tester);
    expect(find.byKey(const ValueKey('as-busy-scene')), findsNothing);
    expect(got, 42);
  });

  testWidgets('BusyHost：舞台挂根 Overlay，整树替换（换 router）不死 + 揭幕钟', (tester) async {
    addTearDown(BusyReveal.instance.reveal); // 兜底复位全局揭幕钟
    String? got;
    final gate = Completer<void>();
    Widget appOf(Widget home) => MaterialApp(
          builder: (_, c) => BusyHost(child: c ?? const SizedBox.shrink()),
          home: home,
        );
    await tester.pumpWidget(
      appOf(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  got = await runBusy<String>(
                    context,
                    message: '正在测试…',
                    successMessage: '搞定',
                    showError: false,
                    syncReveal: true,
                    task: () async {
                      await gate.future;
                      return 'ok';
                    },
                  );
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.byKey(const ValueKey('as-busy-scene')), findsOneWidget);
    expect(BusyReveal.instance.revealed, isFalse, reason: 'syncReveal 舞台持幕中');

    // 任务进行中整树替换（解锁/上锁会换整个 router——home 整个换掉）：
    // 舞台挂在 BusyHost 根 Overlay，不随旧树销毁。
    await tester.pumpWidget(appOf(const Scaffold(body: Text('新页面'))));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('as-busy-scene')), findsOneWidget,
        reason: '舞台跨 router 换树存活');
    expect(find.text('新页面'), findsOneWidget);

    gate.complete();
    await tester.pump(const Duration(seconds: 2)); // hold 800ms + 渐隐
    expect(BusyReveal.instance.revealed, isTrue, reason: '散场开始即揭幕');
    await pumpAway(tester);
    expect(find.byKey(const ValueKey('as-busy-scene')), findsNothing);
    expect(got, 'ok');
  });
}
