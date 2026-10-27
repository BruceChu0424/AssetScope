import 'dart:math';
import 'dart:typed_data';

/// 认证加密（AEAD）接口：加解密均验证完整性，
/// 密钥错误或数据被篡改时抛出 [CryptoException]。
abstract class AeadCipher {
  String get algoId;

  int get nonceLength;

  Future<Uint8List> encrypt({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List plaintext,
    Uint8List? aad,
  });

  Future<Uint8List> decrypt({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List ciphertext,
    Uint8List? aad,
  });
}

/// 口令派生函数（KDF）：慢哈希抗暴力破解。
/// 参数会随密文头持久化，保证算法升级后旧数据仍可解。
abstract class PassphraseKdf {
  String get algoId;

  /// 可序列化参数（写入头部的 JSON）。
  Map<String, Object> get params;

  Future<Uint8List> derive({
    required String passphrase,
    required Uint8List salt,
  });
}

class CryptoException implements Exception {
  CryptoException(this.message);
  final String message;

  @override
  String toString() => 'CryptoException: $message';
}

/// 密码学套件：AEAD + KDF + 安全随机。
/// 默认实现 [DartCryptoSuite]（纯 Dart，任何平台/测试环境可用）；
/// [SodiumCryptoSuite] 在设备上提供 Argon2id 与原生实现（可用时自动启用）。
abstract class CryptoSuite {
  String get name;
  AeadCipher get aead;
  PassphraseKdf get kdf;

  /// 安全随机字节（平台 CSPRNG）。
  Uint8List randomBytes(int length) {
    final r = Random.secure();
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = r.nextInt(256);
    }
    return out;
  }

  /// 包装：随机 nonce + AEAD。
  Future<SealedBox> seal({
    required Uint8List key,
    required Uint8List plaintext,
    Uint8List? aad,
  }) async {
    final nonce = randomBytes(aead.nonceLength);
    final ct = await aead.encrypt(
        key: key, nonce: nonce, plaintext: plaintext, aad: aad);
    return SealedBox(nonce: nonce, ciphertext: ct, algoId: aead.algoId);
  }

  Future<Uint8List> open({
    required Uint8List key,
    required SealedBox box,
    Uint8List? aad,
  }) =>
      aead.decrypt(
          key: key, nonce: box.nonce, ciphertext: box.ciphertext, aad: aad);
}

class SealedBox {
  const SealedBox({
    required this.nonce,
    required this.ciphertext,
    required this.algoId,
  });

  final Uint8List nonce;
  final Uint8List ciphertext;
  final String algoId;
}
