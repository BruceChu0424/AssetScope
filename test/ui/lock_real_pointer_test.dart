import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assetscope/ui/lock/lock_page.dart';
import 'widget_host.dart';

// 真实指针路径复现：锁屏输入框 hover + 点击 + 输入。
void main() {
  testWidgets('锁屏：鼠标点击输入框应聚焦可输入', (tester) async {
    final db = widgetDb();
    try {
      await db.customSelect('SELECT 1').getSingle();
    } catch (_) {
      await db.close();
      markTestSkipped('无 sqlite3');
      return;
    }
    final session = await buildWidgetSession(db);
    try {
      await tester.pumpWidget(widgetHost(const LockPage(), session));
      await tester.pump(const Duration(milliseconds: 100));

      final field = find.byType(TextField).first;
      final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await g.addPointer(location: Offset.zero);
      addTearDown(g.removePointer);
      await g.moveTo(tester.getCenter(field));
      await tester.pump(const Duration(milliseconds: 50));
      await g.down(tester.getCenter(field));
      await tester.pump(const Duration(milliseconds: 50));
      await g.up();
      await tester.pump(const Duration(milliseconds: 50));

      // 点击必须真正聚焦到字段（enterText 会强制聚焦，测不出点击路径）。
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).focusNode
            .hasPrimaryFocus,
        isTrue,
        reason: '点击胶囊输入框后字段应获得主焦点',
      );
      expect(find.byType(EditableText), findsOneWidget);
      expect(
        tester.widget<EditableText>(
          find.byType(EditableText),
        ).controller.text,
        '',
      );
      await tester.enterText(field, 'abc12345');
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'abc12345',
      );
      debugPrint('锁屏输入 OK');
    } finally {
      await db.close();
    }
  });

  // 回归锁（v0.21 存量 bug）：action 后缀（Align(centerRight)）无
  // maxWidth 时贪占全宽，可编辑区被挤成 0 宽——圆点/光标/悬停 I-beam/
  // 点击命中全部失效，仅键盘盲打可用（autofocus 仍在）。
  testWidgets('回归：action 后缀不得挤占可编辑区（0 宽 bug）', (tester) async {
    final db = widgetDb();
    try {
      await db.customSelect('SELECT 1').getSingle();
    } catch (_) {
      await db.close();
      markTestSkipped('无 sqlite3');
      return;
    }
    final session = await buildWidgetSession(db);
    try {
      await tester.pumpWidget(widgetHost(const LockPage(), session));
      await tester.pump(const Duration(milliseconds: 100));

      final editable = tester.renderObject(
        find.descendant(
          of: find.byType(TextField),
          matching: find.byType(EditableText),
        ),
      ) as RenderBox;
      expect(
        editable.size.width,
        greaterThan(100),
        reason: '可编辑区被 suffix Align 挤成 ${editable.size.width} 宽——'
            '圆点/光标/I-beam/点击命中将全部失效（v0.21 0 宽 bug 复发）',
      );
    } finally {
      await db.close();
    }
  });
}
