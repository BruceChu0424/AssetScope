import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';

import '../data/app_database.dart';
import '../security/backup.dart';
import '../security/crypto_suite.dart';
import '../security/dart_crypto_suite.dart';

/// 备份与恢复服务。
///
/// 导出：把加密数据库经 sqlcipher_export 导出为明文临时文件，
/// 再用 AEAD 容器整体加密（DEK 或独立口令）。容器格式见
/// docs/08-备份恢复与迁移.md。
///
/// 恢复：容器解密 → 临时明文库 → 完整性校验 → 以当前 DEK 重新加密落盘，
/// 全程不触碰原库；校验失败原样保留。
class BackupService {
  BackupService(this._db, this._suite);

  final AppDatabase _db;
  final CryptoSuite _suite;

  /// 导出加密备份到 [target]。
  ///
  /// [vaultFingerprint]：账本谱系指纹（MergeService.vaultFingerprint），
  /// 写入容器明文 meta，供多设备合并时校验"同一本账"。
  Future<void> exportTo({
    required File target,
    Uint8List? dek,
    String? passphrase,
    String? vaultFingerprint,
    Map<String, Object> meta = const {},
  }) async {
    final dir = target.parent;
    await dir.create(recursive: true);
    final plainTmp = File(
        '${dir.path}${Platform.pathSeparator}assetscope-export-tmp.db');
    if (await plainTmp.exists()) await plainTmp.delete();
    try {
      await _db.customStatement(
          "ATTACH DATABASE ? AS exp_plain KEY ''", [plainTmp.path]);
      await _db.customStatement("SELECT sqlcipher_export('exp_plain')");
      await _db.customStatement('DETACH DATABASE exp_plain');
      final bytes = await plainTmp.readAsBytes();
      final container = await BackupContainer.create(
        payload: bytes,
        dek: dek,
        passphrase: passphrase,
        suite: _suite,
        meta: {
          'app': 'assetscope',
          'schemaVersion': _db.schemaVersion,
          'vaultId': ?vaultFingerprint,
          ...meta,
        },
      );
      await target.writeAsBytes(container, flush: true);
    } finally {
      if (await plainTmp.exists()) {
        await plainTmp.delete();
      }
    }
  }

  /// 校验备份可解（不落盘、不动原库）。返回元数据。
  static Future<Map<String, Object>> verify(
    Uint8List container, {
    Uint8List? dek,
    String? passphrase,
    CryptoSuite? suite,
  }) async {
    final payload = await BackupContainer.open(container,
        dek: dek, passphrase: passphrase, suite: suite);
    return payload.meta;
  }

  /// 恢复：解密 → 明文临时库 → 完整性检查 → 以 [newDbKeyHex] 重新加密到 [target]。
  /// [target] 存在时先备份为 .bak，校验通过才替换。
  static Future<void> restoreTo({
    required Uint8List container,
    required File target,
    required String newDbKeyHex,
    Uint8List? dek,
    String? passphrase,
    CryptoSuite? suite,
  }) async {
    final s = suite ?? DartCryptoSuite.instance;
    final payload = await BackupContainer.open(container,
        dek: dek, passphrase: passphrase, suite: s);
    final dir = target.parent;
    await dir.create(recursive: true);
    final plainTmp = File(
        '${dir.path}${Platform.pathSeparator}assetscope-restore-tmp.db');
    final encTmp = File(
        '${dir.path}${Platform.pathSeparator}assetscope-restore-enc.db');
    for (final f in [plainTmp, encTmp]) {
      if (await f.exists()) await f.delete();
    }
    try {
      await plainTmp.writeAsBytes(payload.bytes, flush: true);

      // 完整性校验（在临时明文库上执行，失败即中止，不影响原库）。
      final probe = AppDatabase(NativeDatabase(plainTmp));
      try {
        await probe.customStatement('PRAGMA integrity_check');
        await probe.customSelect('SELECT COUNT(*) c FROM transactions').getSingle();
        final meta = payload.meta;
        if (meta['schemaVersion'] != null &&
            (meta['schemaVersion'] as num).toInt() != probe.schemaVersion) {
          throw BackupException(
              '备份 schema 版本 ${meta['schemaVersion']} 与当前 ${probe.schemaVersion} 不一致，需要迁移');
        }
      } finally {
        await probe.close();
      }

      // 以新密钥重新加密：从明文库 sqlcipher_export 到加密目标。
      final encDb = AppDatabase(NativeDatabase(plainTmp));
      try {
        await encDb.customStatement(
            'ATTACH DATABASE ? AS enc KEY ?', [encTmp.path, "x'$newDbKeyHex'"]);
        await encDb.customStatement("SELECT sqlcipher_export('enc')");
        await encDb.customStatement('DETACH DATABASE enc');
      } finally {
        await encDb.close();
      }

      // 目标已存在则先备份，再原子替换。
      if (await target.exists()) {
        final bak = File('${target.path}.bak');
        if (await bak.exists()) await bak.delete();
        await target.rename(bak.path);
      }
      await encTmp.rename(target.path);
    } finally {
      if (await plainTmp.exists()) await plainTmp.delete();
      if (await encTmp.exists()) await encTmp.delete();
    }
  }
}
