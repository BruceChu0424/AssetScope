import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/ui/lock/lock_page.dart';
import 'package:assetscope/ui/theme/app_theme.dart';
import 'widget_host.dart';

// 错误态回归：空口令点解锁 → 顶部通知 + 输入框红框 + 圆钮转朱砂并
// 自摇（v0.22 两段式解锁：核验失败即时交还，不再躲在全屏舞台后面）。
void main() {
  testWidgets('解锁错误：圆钮变红 + 横摇，重新输入即恢复', (tester) async {
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

      // 空口令直接点圆钮：校验即时失败（不触慢哈希）。
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await tester.pump(const Duration(milliseconds: 80));

      // 顶部通知出现。
      expect(find.text('请输入主口令或恢复码'), findsOneWidget);

      // 圆钮转朱砂（错误持续态，直到重新输入）。
      Material buttonMaterial() => tester.widget<Material>(
        find
            .ancestor(
              of: find.byIcon(Icons.arrow_forward_rounded),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(
        buttonMaterial().color,
        AppColors.negative,
        reason: '错误态圆钮应转朱砂',
      );

      // 钮自身横摇：70ms 迟发起摇后，中途某帧存在非零水平位移。
      var shook = false;
      for (var t = 0; t < 400; t += 40) {
        await tester.pump(const Duration(milliseconds: 40));
        for (final t in tester.widgetList<Transform>(
          find.byType(Transform),
        )) {
          final m = t.transform;
          final dx = m.getTranslation().x;
          if (dx != 0 && dx.abs() < 7) shook = true; // 表单 ±6 / 钮 ±3.2
        }
      }
      expect(shook, isTrue, reason: '错误时应播放表单/圆钮横摇');

      // 重新输入 → 错误清除，圆钮回主色。
      await tester.enterText(find.byType(TextField).first, 'abc12345');
      await tester.pump();
      expect(
        buttonMaterial().color,
        Theme.of(
          tester.element(find.byType(LockPage)),
        ).colorScheme.primary,
        reason: '重新输入后圆钮应恢复主色',
      );

      // 排干顶部通知的自动退场计时器（错误条 3.2s TTL + 出场动画）。
      // 注意不能用 pumpAndSettle：锁屏 ParticleBrandMark 的行波时钟
      // 无 FLUTTER_TEST 静态帧保护（存量），常驻排帧永不收敛。
      await tester.pump(const Duration(seconds: 4));
    } finally {
      await db.close();
    }
  });
}
