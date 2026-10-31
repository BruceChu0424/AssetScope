import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/app/providers.dart';
import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/ui/settings/settings_page.dart';
import 'package:assetscope/ui/theme/app_theme.dart';
import 'package:assetscope/l10n/app_localizations.dart';

import 'widget_host.dart';

/// 设置页专属 golden：只出 settings_wide / settings_small 两张（与
/// redesign_walkthrough 同路径同工艺），供设置页改版独立走查——其他
/// 页面的 golden 由各自任务维护。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late VaultUnlocked session;
  bool dbAvailable = true;

  setUp(() async {
    try {
      db = AppDatabase(NativeDatabase.memory());
      await db.customSelect('SELECT 1').getSingle();
    } catch (_) {
      dbAvailable = false;
      return;
    }
    session = await buildWidgetSession(db);
    await seedWidgetData(session);
  });

  tearDown(() async {
    if (dbAvailable) await db.close();
  });

  testWidgets('设置页两档尺寸 golden', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    for (final (w, h, tag) in const [
      (1600.0, 1000.0, 'wide'),
      (480.0, 900.0, 'small'),
    ]) {
      await tester.binding.setSurfaceSize(Size(w, h));
      tester.view.physicalSize = Size(w, h);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [vaultProvider.overrideWith(() => FixedVault(session))],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            theme: buildAppTheme(Brightness.dark),
            home: const SettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('redesign/settings_$tag.png'),
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }
  });
}
