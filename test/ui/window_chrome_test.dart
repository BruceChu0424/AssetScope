import 'package:assetscope/ui/widgets/window_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 无边框窗口框体冒烟：enabled 时渲染红绿灯；无插件环境下（widget
/// 测试）点按三钮被安全吞掉不崩；enabled=false 时直通子树零痕迹。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WindowChrome：enabled 时渲染红绿灯，点按无插件不崩', (tester) async {
    WindowChrome.enabled = true;
    addTearDown(() => WindowChrome.enabled = false);

    await tester.pumpWidget(const MaterialApp(
      home: WindowChrome(child: Scaffold(body: SizedBox.expand())),
    ));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(TrafficLights), findsOneWidget);
    // initState 里的 isFocused/isMaximized 查询在测试里拿不到插件通道，
    // 必须被吞掉而非抛异常。
    expect(tester.takeException(), isNull);

    // 点中间（最大化钮命中区，Windows 顺序中居中）：插件缺失 → 动作静默失败，不崩。
    await tester.tap(find.byType(TrafficLights));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('WindowChrome：未启用时直通子树（无控件渲染）', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: WindowChrome(child: Text('内容')),
    ));
    expect(find.text('内容'), findsOneWidget);
    expect(find.byType(TrafficLights), findsNothing);
  });
}
