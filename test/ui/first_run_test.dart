import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:assetscope/app/providers.dart';
import 'package:assetscope/security/crypto_suite.dart';
import 'package:assetscope/security/key_manager.dart';
import 'package:assetscope/ui/lock/lock_page.dart';
import 'package:assetscope/ui/widgets/common.dart';
import 'package:assetscope/l10n/app_localizations.dart';

/// 首启动回归（v0.15 修复）：干净机器（无 vault.key）上必须显示
/// "创建加密账本"表单——此前 _init 会把状态误置为 Locked，新用户
/// 面对永远解不开的解锁死锁（v0.2 引入，真机首启动发现）。
///
/// 工艺：_init 走 dart:io 文件 I/O，在 widget 测试的 FakeAsync 区里
/// 永远不会完成——必须在 tester.runAsync 的真实异步区里预热 provider
/// （建容器 + read 触发 build），完成后再挂到 widget 树上。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('as-first-run-');
    PathProviderPlatform.instance = _FakePathProvider(tmp);
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  /// 真实区预热 provider，返回可挂到树上的容器。
  Future<ProviderContainer> prewarm(WidgetTester tester) async {
    final container = ProviderContainer();
    await tester.runAsync(() async {
      container.read(vaultProvider); // 触发 build + _init（真实 I/O）
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pump();
    return container;
  }

  testWidgets('干净首启动：显示创建表单（不是解锁死锁）', (tester) async {
    final container = await prewarm(tester);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),home: LockPage()),
      ),
    );
    await tester.pump();

    // 粒子 logo + 两枚胶囊输入框（提示语承载语境，无标题），圆钮 check。
    expect(find.byType(ParticleBrandMark), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('创建加密账本'), findsNothing, reason: '标题已并入输入框提示');
    expect(find.text('解锁'), findsNothing);
    expect(find.text('忘记主口令？使用恢复码'), findsNothing);
  });

  testWidgets('已有金库：显示解锁表单', (tester) async {
    // 预放一个可解码的密钥头（_init 只判断存在与可解码，不解密；
    // 直接构造避免测试里跑 60 万轮 PBKDF2）。
    final header = VaultHeader(
      version: 1,
      kdfAlgo: 'pbkdf2-hmac-sha512',
      kdfParams: const {'iterations': 1000, 'bits': 256},
      salt: Uint8List(16),
      wrapAlgo: 'xchacha20-poly1305',
      wrappedDek: SealedBox(
        nonce: Uint8List(24),
        ciphertext: Uint8List(48),
        algoId: 'xchacha20-poly1305',
      ),
    );
    final appDir = Directory('${tmp.path}/assetscope')
      ..createSync(recursive: true);
    File('${appDir.path}/vault.key').writeAsStringSync(header.encode());

    final container = await prewarm(tester);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),home: LockPage()),
      ),
    );
    await tester.pump();

    expect(find.byType(ParticleBrandMark), findsOneWidget);
    expect(find.text('资观 AssetScope'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    expect(find.text('创建加密账本'), findsNothing);

    // 空口令直接点圆钮：不再内联错误文字，而是顶部通知条。
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('请输入主口令或恢复码'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4)); // 通知自动收场

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.root);

  final Directory root;

  @override
  Future<String?> getApplicationSupportPath() async => root.path;
}
