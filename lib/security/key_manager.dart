import 'dart:convert';
import 'dart:typed_data';

import 'crypto_suite.dart';
import 'dart_crypto_suite.dart';

class WrongPassphraseException implements Exception {
  @override
  String toString() => 'WrongPassphraseException: 主口令或恢复码不正确';
}

/// 密钥头（明文 JSON，不含任何机密）：记录 KDF 参数与被包裹的 DEK。
///
/// 结构与 KDBX 类似：拿到头部文件无法得到任何明文；
/// 暴力破解需要逐口令跑慢哈希。
class VaultHeader {
  VaultHeader({
    required this.version,
    required this.kdfAlgo,
    required this.kdfParams,
    required this.salt,
    required this.wrapAlgo,
    required this.wrappedDek,
    this.createdAt,
  });

  final int version;
  final String kdfAlgo;
  final Map<String, Object> kdfParams;
  final Uint8List salt;
  final String wrapAlgo;

  /// AEAD(nonce ‖ ciphertext)，密钥为 KEK = KDF(passphrase, salt)。
  final SealedBox wrappedDek;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => {
        'version': version,
        'kdfAlgo': kdfAlgo,
        'kdfParams': kdfParams,
        'salt': base64Encode(salt),
        'wrapAlgo': wrapAlgo,
        'nonce': base64Encode(wrappedDek.nonce),
        'wrappedDek': base64Encode(wrappedDek.ciphertext),
        'createdAt': createdAt?.toIso8601String(),
      };

  static VaultHeader fromJson(Map<String, dynamic> j) {
    try {
      return VaultHeader(
        version: j['version'] as int,
        kdfAlgo: j['kdfAlgo'] as String,
        kdfParams: Map<String, Object>.from(j['kdfParams'] as Map),
        salt: base64Decode(j['salt'] as String),
        wrapAlgo: j['wrapAlgo'] as String,
        wrappedDek: SealedBox(
          nonce: base64Decode(j['nonce'] as String),
          ciphertext: base64Decode(j['wrappedDek'] as String),
          algoId: j['wrapAlgo'] as String,
        ),
        createdAt: j['createdAt'] == null
            ? null
            : DateTime.parse(j['createdAt'] as String),
      );
    } on TypeError {
      throw const FormatException('密钥头格式不合法');
    } on RangeError {
      throw const FormatException('密钥头格式不合法');
    } catch (e) {
      if (e is FormatException) rethrow;
      throw const FormatException('密钥头格式不合法');
    }
  }

  String encode() => jsonEncode(toJson());

  static VaultHeader decode(String raw) =>
      fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// 密钥管理：创建/解锁/改口令/恢复码。
///
/// 密钥层级：
///   主口令 --KDF(Argon2id/PBKDF2)--> KEK（不落盘）
///   DEK（32 字节随机，真正加密数据库与备份，不落盘明文）
///   存储 = VaultHeader{ KEK 包裹的 DEK }
///
/// DEK 与口令解耦：改口令只重包 DEK，数据库无需重加密。
class KeyManager {
  KeyManager({CryptoSuite? suite}) : _suiteOverride = suite;

  final CryptoSuite? _suiteOverride;
  CryptoSuite get _suite => _suiteOverride ?? DartCryptoSuite.instance;

  Uint8List? _dek;

  /// 当前已解锁的 DEK；锁定后为 null。
  Uint8List? get dek => _dek;
  bool get isUnlocked => _dek != null;

  /// 数据库密钥（PRAGMA key 使用的 64 位 hex = 32 字节 DEK）。
  String databaseKeyHex() {
    final d = _dek;
    if (d == null) throw StateError('尚未解锁');
    return d.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  void lock() => _dek = null;

  /// 创建新金库：生成 DEK，用主口令包裹。
  /// 返回（头部, 生成的恢复码包裹头列表）。
  Future<VaultBootstrap> createVault(String passphrase,
      {Uint8List? importDek}) async {
    final suite = _suite;
    final dek = importDek ?? suite.randomBytes(32);
    final header = await _wrap(dek, passphrase);
    final recoveryCode = _generateRecoveryCode(suite);
    final recoveryHeader = await _wrap(dek, recoveryCode);
    _dek = dek;
    return VaultBootstrap(
        header: header, recoveryCode: recoveryCode, recoveryHeader: recoveryHeader, dek: dek);
  }

  Future<VaultHeader> _wrap(Uint8List dek, String passphrase) async {
    final suite = _suite;
    final salt = suite.randomBytes(16);
    final kek = await suite.kdf.derive(passphrase: passphrase, salt: salt);
    final box = await suite.seal(key: kek, plaintext: dek, aad: _aad());
    return VaultHeader(
      version: 1,
      kdfAlgo: suite.kdf.algoId,
      kdfParams: suite.kdf.params,
      salt: salt,
      wrapAlgo: suite.aead.algoId,
      wrappedDek: box,
      createdAt: DateTime.now(),
    );
  }

  /// 解锁：主口令或恢复码均可。失败抛 [WrongPassphraseException]。
  Future<Uint8List> unlock(String passphrase, VaultHeader header) async {
    final suite = _suite;
    final kek = await suite.kdf.derive(passphrase: passphrase, salt: header.salt);
    try {
      final dek = await suite.open(key: kek, box: header.wrappedDek, aad: _aad());
      if (dek.length != 32) throw CryptoException('DEK 长度异常');
      _dek = dek;
      return dek;
    } on CryptoException {
      throw WrongPassphraseException();
    }
  }

  /// 修改主口令：DEK 不变，重新包裹。返回新头部。
  Future<VaultHeader> changePassphrase(
      String oldPassphrase, String newPassphrase, VaultHeader header) async {
    final dek = await unlock(oldPassphrase, header);
    return _wrap(dek, newPassphrase);
  }

  /// 重新生成恢复码头。
  Future<(String, VaultHeader)> newRecoveryCode() async {
    final d = _dek;
    if (d == null) throw StateError('尚未解锁');
    final code = _generateRecoveryCode(_suite);
    return (code, await _wrap(d, code));
  }

  String _generateRecoveryCode(CryptoSuite suite) {
    final raw = suite.randomBytes(16);
    final hex = raw.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final groups = <String>[];
    for (var i = 0; i < hex.length; i += 4) {
      groups.add(hex.substring(i, i + 4));
    }
    return groups.join('-').toUpperCase();
  }

  /// AAD 绑定用途标识，防止头部件被挪用。
  Uint8List _aad() => Uint8List.fromList(utf8.encode('assetscope-vault-v1'));
}

class VaultBootstrap {
  const VaultBootstrap({
    required this.header,
    required this.recoveryCode,
    required this.recoveryHeader,
    required this.dek,
  });

  final VaultHeader header;
  final String recoveryCode;
  final VaultHeader recoveryHeader;
  final Uint8List dek;
}

/// 密钥材料的持久化抽象（安全存储实现 + 文件镜像实现）。
abstract class KeyStore {
  Future<void> savePrimary(VaultHeader header);
  Future<void> saveRecovery(VaultHeader header);
  Future<VaultHeader?> loadPrimary();
  Future<VaultHeader?> loadRecovery();
  Future<void> clear();
}
