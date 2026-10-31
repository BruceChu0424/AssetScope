import 'package:assetscope/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';


/// 粒子下拉/菜单弹层（v0.25）：选择生效、ESC 关闭、屏障吸收首击。
/// FLUTTER_TEST 下无粒子（静态直显），本测试锁交互语义与弹层结构。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('下拉：点开弹层 → 点条目选择生效 + 弹层移除', (tester) async {
    int? picked;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 260,
            child: ParticleDropdownField<int>(
              initialValue: 1,
              items: const [
                DropdownMenuItem(value: 1, child: Text('一')),
                DropdownMenuItem(value: 2, child: Text('二')),
                DropdownMenuItem(value: 3, child: Text('三')),
              ],
              onChanged: (v) => setState(() => picked = v),
            ),
          ),
        ),
      ),
    );
    // 初始回显第一项。
    expect(find.text('一'), findsOneWidget);

    await tester.tap(find.text('一'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 弹层出现且三条目都在（测试环境粒子静态直显）。
    expect(find.text('二'), findsWidgets);
    await tester.tap(find.text('二').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 选择生效：字段回显「二」，回调收到 2，弹层移除。
    expect(picked, 2);
    expect(find.text('二'), findsOneWidget);
  });

  testWidgets('下拉：ESC 关闭弹层不改值；点屏障同效', (tester) async {
    int? picked;
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 260,
          child: ParticleDropdownField<int>(
            initialValue: 1,
            items: const [
              DropdownMenuItem(value: 1, child: Text('一')),
              DropdownMenuItem(value: 2, child: Text('二')),
            ],
            onChanged: (v) => picked = v,
          ),
        ),
      ),
    );
    await tester.tap(find.text('一'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // ESC：弹层收起、值不变。
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(picked, isNull);
    expect(find.text('一'), findsOneWidget);

    // 再开一次，点屏障（弹层外空白）关闭。
    await tester.tap(find.text('一'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tapAt(const Offset(40, 40));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(picked, isNull);
  });

  testWidgets('溢出菜单钮：条目选择回调 + destructive 语义位', (tester) async {
    String? action;
    await tester.pumpWidget(
      host(
        ParticleMenuButton<String>(
          tooltip: '操作',
          items: const [
            ParticleMenuEntry(
              value: 'edit',
              label: '编辑',
              icon: Icons.edit_outlined,
            ),
            ParticleMenuEntry(
              value: 'delete',
              label: '删除',
              icon: Icons.delete_outline,
              destructive: true,
            ),
          ],
          onSelected: (a) => action = a,
        ),
      ),
    );
    await tester.tap(find.byTooltip('操作'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('编辑'), findsOneWidget);

    await tester.tap(find.text('删除'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(action, 'delete');
  });
}
