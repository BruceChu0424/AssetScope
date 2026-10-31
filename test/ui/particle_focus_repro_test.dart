import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assetscope/ui/widgets/particle_interactive.dart';
import 'package:assetscope/l10n/app_localizations.dart';

// 复现：粒子包装后输入框能否点击聚焦、按钮能否点击。
void main() {
  testWidgets('点击 ParticleTextField 应能聚焦并输入', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
        home: Scaffold(
          body: Center(
            child: ParticleTextField(controller: c, decoration: const InputDecoration(hintText: 'h')),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isNotNull);
    expect(FocusScope.of(tester.element(find.byType(TextField))).hasFocus, isTrue);
    await tester.enterText(find.byType(TextField), 'ok');
    expect(c.text, 'ok');
  });

  testWidgets('点击 ParticleFilledButton 应触发 onPressed', (tester) async {
    var fired = 0;
    await tester.pumpWidget(
      MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
        home: Scaffold(
          body: Center(
            child: ParticleFilledButton(onPressed: () => fired++, child: const Text('GO')),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(fired, 1);
  });
}
