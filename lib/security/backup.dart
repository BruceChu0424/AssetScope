import 'dart:convert';
import 'dart:typed_data';

import 'crypto_suite.dart';
import 'dart_crypto_suite.dart';
import 'key_manager.dart';

class BackupException implements Exception {
  BackupException(this.message);
  final String message;

  @override
  String toString() => 'BackupException: $message';
}

/// 加密备份容器 v1：
///
/// ┌────────────┬─────────┬────────────┬──────────────────────────┐
/// │ magic 4B   │ ver 1B  │ headLen 4B │ header JSON（明文元数据）│
/// ├────────────┴─────────┴────────────┼──────────────────────────┤
/// │ payload: AEAD(nonce ‖ ct ‖ mac)    │  ← 密钥为 DEK 或口令派生 │
/// └───────────────────────────────────┴──────────────────────────┘
///
/// - 完整性：AEAD 认证覆盖全部密文，篡改/口令错误/损坏一律拒绝；
/// - 打开方式：DEK 直开（本机已解锁）或 主口令（换机恢复）；
/// - header 与金库密钥头同构（KDF 参数内嵌）。
class BackupContainer {
  static const magic = [0x41, 0x53, 0x42, 0x4B]; // 'ASBK'
  static const version = 1;

  BackupContainer._();

  static Future<Uint8List> create({
    required Uint8List payload,
    Map<String, Object> meta = const {},
    Uint8List? dek,
    String? passphrase,
    CryptoSuite? suite,
  }) async {
    if (dek == null && passphrase == null) {
      throw ArgumentError('必须提供 dek 或 passphrase 之一');
    }
    final s = suite ?? DartCryptoSuite.instance;
    final Uint8List key;
    final VaultHeader? header;
    if (dek != null) {
      key = dek;
      header = null;
    } else {
      final salt = s.randomBytes(16);
      final kek = await s.kdf.derive(passphrase: passphrase!, salt: salt);
      // 口令模式：随机载荷密钥加密数据，口令 KEK 只包裹载荷密钥。
      final payloadKey = s.randomBytes(32);
      final wrappedPayloadKey =
          await s.seal(key: kek, plaintext: payloadKey, aad: _aadBackup());
      header = VaultHeader(
        version: version,
        kdfAlgo: s.kdf.algoId,
        kdfParams: s.kdf.params,
        salt: salt,
        wrapAlgo: s.aead.algoId,
        wrappedDek: wrappedPayloadKey,
        createdAt: DateTime.now(),
      );
      key = payloadKey;
    }
    final metaJson = jsonEncode({
      ...meta,
      'payloadLen': payload.length,
      'createdAt': DateTime.now().toIso8601String(),
    });
    final sealed = await s.seal(key: key, plaintext: payload, aad: _aadBackup());
    final headerBytes =
        header == null ? Uint8List(0) : Uint8List.fromList(utf8.encode(header.encode()));
    final out = BytesBuilder();
    out.add(magic);
    out.addByte(version);
    out.add(_u32(metaJson.length));
    out.add(utf8.encode(metaJson));
    out.add(_u32(headerBytes.length));
    if (headerBytes.isNotEmpty) out.add(headerBytes);
    out.add(sealed.nonce);
    out.add(sealed.ciphertext);
    return out.toBytes();
  }

  /// 解开备份。错误口令/损坏数据抛 [BackupException]，不返回部分数据。
  static Future<BackupPayload> open(
    Uint8List container, {
    Uint8List? dek,
    String? passphrase,
    CryptoSuite? suite,
  }) async {
    final s = suite ?? DartCryptoSuite.instance;
    if (container.length < 10) throw BackupException('备份文件过短');
    for (var i = 0; i < 4; i++) {
      if (container[i] != magic[i]) throw BackupException('不是合法的备份文件');
    }
    if (container[4] != version) {
      throw BackupException('不支持的备份版本 ${container[4]}');
    }
    var p = 5;
    int metaLen = _readU32(container, p);
    p += 4;
    if (metaLen < 0 || p + metaLen > container.length) {
      throw BackupException('备份头部损坏');
    }
    final meta = Map<String, Object>.from(
        jsonDecode(utf8.decode(container.sublist(p, p + metaLen))) as Map);
    p += metaLen;
    int headerLen = _readU32(container, p);
    p += 4;
    VaultHeader? header;
    if (headerLen > 0) {
      if (p + headerLen > container.length) throw BackupException('备份头部损坏');
      header = VaultHeader.decode(
          utf8.decode(container.sublist(p, p + headerLen)));
      p += headerLen;
    }
    if (dek == null && passphrase == null) {
      throw ArgumentError('必须提供 dek 或 passphrase 之一');
    }
    final Uint8List key;
    if (dek != null) {
      key = dek;
    } else {
      if (header == null) {
        throw BackupException('该备份创建时未绑定口令，请使用原设备数据密钥');
      }
      final kek = await s.kdf.derive(passphrase: passphrase!, salt: header.salt);
      try {
        key = await s.open(key: kek, box: header.wrappedDek, aad: _aadBackup());
      } on CryptoException {
        throw BackupException('口令不正确或备份已损坏');
      }
    }
    if (p + s.aead.nonceLength >= container.length) {
      throw BackupException('备份数据段缺失');
    }
    final nonce = container.sublist(p, p + s.aead.nonceLength);
    final ct = container.sublist(p + s.aead.nonceLength);
    try {
      final payload = await s.aead.decrypt(
          key: key, nonce: nonce, ciphertext: ct, aad: _aadBackup());
      if (payload.length != (meta['payloadLen'] as num?)?.toInt()) {
        throw BackupException('备份长度校验不一致');
      }
      return BackupPayload(bytes: payload, meta: meta);
    } on CryptoException {
      throw BackupException('解密失败：密钥不匹配或数据被篡改');
    }
  }

  static Uint8List _aadBackup() =>
      Uint8List.fromList(utf8.encode('assetscope-backup-v1'));

  static Uint8List _u32(int v) =>
      Uint8List.fromList([(v >> 24) & 0xff, (v >> 16) & 0xff, (v >> 8) & 0xff, v & 0xff]);

  static int _readU32(Uint8List b, int off) =>
      (b[off] << 24) | (b[off + 1] << 16) | (b[off + 2] << 8) | b[off + 3];
}

class BackupPayload {
  const BackupPayload({required this.bytes, required this.meta});
  final Uint8List bytes;
  final Map<String, Object> meta;
}
