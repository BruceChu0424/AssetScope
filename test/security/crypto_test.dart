import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:assetscope/security/backup.dart';
import 'package:assetscope/security/crypto_suite.dart';
import 'package:assetscope/security/dart_crypto_suite.dart';
import 'package:assetscope/security/key_manager.dart';

import 'package:flutter/foundation.dart' show listEquals;

void main() {
  // 降低 KDF 迭代以加速测试（容器/密钥管理逻辑与迭代次数无关）。
  final suite = DartCryptoSuite(pbKdf2Iterations: 1000);

  test('AEAD roundtrip + 篡改拒绝', () async {
    final key = suite.randomBytes(32);
    final plain = Uint8List.fromList(List.generate(1000, (i) => i % 251));
    final box = await suite.seal(key: key, plaintext: plain);
    final back = await suite.open(key: key, box: box);
    expect(back, plain);

    // 篡改 1 字节 → 认证失败
    final tampered = Uint8List.fromList(box.ciphertext);
    tampered[0] ^= 1;
    await expectLater(
      suite.open(key: key, box: SealedBox(nonce: box.nonce, ciphertext: tampered, algoId: box.algoId)),
      throwsA(isA<CryptoException>()),
    );

    // 错误密钥 → 认证失败
    await expectLater(
      suite.open(key: suite.randomBytes(32), box: box),
      throwsA(isA<CryptoException>()),
    );
  });

  test('nonce 不重复（随机 24B，无生日碰撞风险量级）', () {
    final seen = <String>{};
    for (var i = 0; i < 1000; i++) {
      final n = suite.randomBytes(24);
      final hex = n.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(seen.contains(hex), isFalse);
      seen.add(hex);
    }
  });

  test('KeyManager：完整生命周期', () async {
    final km = KeyManager(suite: suite);
    final boot = await km.createVault('correct horse battery staple');
    final dek1 = Uint8List.fromList(km.dek!);

    // 恢复码也能解锁
    km.lock();
    await km.unlock(boot.recoveryCode, boot.recoveryHeader);
    expect(km.dek, dek1);

    // 错误口令 → 明确异常
    km.lock();
    await expectLater(
        km.unlock('nope', boot.header), throwsA(isA<WrongPassphraseException>()));

    // 改口令：DEK 不变（数据库无需重加密）
    await km.unlock('correct horse battery staple', boot.header);
    final newHeader =
        await km.changePassphrase('correct horse battery staple', 'new stronger passphrase 42', boot.header);
    expect(km.dek, dek1);
    km.lock();
    await km.unlock('new stronger passphrase 42', newHeader);
    expect(km.dek, dek1);

    // 头部为明文 JSON，不含 DEK 明文
    final json = newHeader.encode();
    expect(json.contains('wrappedDek'), isTrue);
    final dekHex = dek1.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    expect(json.contains(dekHex), isFalse);
  });

  test('备份容器：口令模式 roundtrip / 错口令 / 损坏全部拒绝', () async {
    final payload = Uint8List.fromList(List.generate(4096, (i) => i % 7));
    final container = await BackupContainer.create(
      payload: payload,
      passphrase: 'backup-passphrase-2026',
      suite: suite,
      meta: {'schemaVersion': 1},
    );
    final opened = await BackupContainer.open(container,
        passphrase: 'backup-passphrase-2026', suite: suite);
    expect(opened.bytes, payload);
    expect(opened.meta['schemaVersion'], 1);

    await expectLater(
      BackupContainer.open(container, passphrase: 'wrong', suite: suite),
      throwsA(isA<BackupException>()),
    );

    // 截断
    await expectLater(
      BackupContainer.open(
          Uint8List.sublistView(container, 0, container.length - 5),
          passphrase: 'backup-passphrase-2026',
          suite: suite),
      throwsA(isA<BackupException>()),
    );

    // 魔数破坏
    final badMagic = Uint8List.fromList(container);
    badMagic[0] = 0x00;
    await expectLater(
      BackupContainer.open(badMagic, passphrase: 'backup-passphrase-2026', suite: suite),
      throwsA(isA<BackupException>()),
    );
  });

  test('备份容器：DEK 模式（本机已解锁直开）', () async {
    final dek = suite.randomBytes(32);
    final payload = Uint8List.fromList([1, 2, 3, 4, 5]);
    final container =
        await BackupContainer.create(payload: payload, dek: dek, suite: suite);
    final opened = await BackupContainer.open(container, dek: dek, suite: suite);
    expect(opened.bytes, payload);
    // 错误 DEK 拒绝
    await expectLater(
      BackupContainer.open(container, dek: suite.randomBytes(32), suite: suite),
      throwsA(isA<BackupException>()),
    );
  });

  test('KDF 输出确定性（同口令同盐同参数）', () async {
    final salt = suite.randomBytes(16);
    final a = await suite.kdf.derive(passphrase: 'p', salt: salt);
    final b = await suite.kdf.derive(passphrase: 'p', salt: salt);
    expect(a, b);
    final c = await suite.kdf.derive(passphrase: 'q', salt: salt);
    expect(a.length == 32 && c.length == 32 && !listEquals(a, c), isTrue);
  });

  // 恢复码形态门控（providers.unlockCheck 快排依赖）：不符形态的输入
  // 不可能等于任何恢复码，主口令失败后跳过第二轮慢哈希。
  test('looksLikeRecoveryCode：8 组 4 位 hex、大小写、连字符', () {
    expect(
      looksLikeRecoveryCode('A1B2-C3D4-E5F6-0718-9ABC-DEF0-1234-5678'),
      isTrue,
    );
    expect(
      looksLikeRecoveryCode('a1b2-c3d4-e5f6-0718-9abc-def0-1234-5678'),
      isTrue,
      reason: '用户可能粘贴小写',
    );
    // 非形态：普通口令、位数不足、非 hex、错误分隔。
    expect(looksLikeRecoveryCode('correct horse'), isFalse);
    expect(looksLikeRecoveryCode('A1B2-C3D4'), isFalse);
    expect(looksLikeRecoveryCode('G1B2-C3D4-E5F6-0718-9ABC-DEF0-1234-5678'),
        isFalse);
    expect(looksLikeRecoveryCode('A1B2 C3D4 E5F6 0718 9ABC DEF0 1234 5678'),
        isFalse);
  });
}
