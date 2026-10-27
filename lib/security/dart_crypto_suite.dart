import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as c;

import 'crypto_suite.dart';

/// 纯 Dart 密码学套件（默认实现，测试与任意平台可用）：
/// - AEAD：XChaCha20-Poly1305（随机 24 字节 nonce）
/// - KDF：PBKDF2-HMAC-SHA512（600,000 轮，OWASP 2023 对 SHA-512 的建议量级）
///
/// 说明：内存困难性弱于 Argon2id；设备端验证 [SodiumCryptoSuite] 可用后
/// 自动优先使用 Argon2id。KDF 算法与参数写入密文头，向后兼容。
class DartCryptoSuite extends CryptoSuite {
  /// 迭代次数可注入以便测试提速；生产默认 600,000。
  DartCryptoSuite({int pbKdf2Iterations = 600000})
      // ignore: prefer_initializing_formals
      : _pbKdf2Iterations = pbKdf2Iterations;

  // ignore: unused_field
  final int _pbKdf2Iterations;

  static final DartCryptoSuite instance = DartCryptoSuite();

  @override
  String get name => 'dart';

  @override
  AeadCipher get aead => _XchachaAead();

  @override
  PassphraseKdf get kdf => _Pbkdf2Kdf(_pbKdf2Iterations);
}

class _XchachaAead extends AeadCipher {
  final c.Xchacha20 _algo = c.Xchacha20.poly1305Aead();

  @override
  String get algoId => 'xchacha20-poly1305';

  @override
  int get nonceLength => 24;

  @override
  Future<Uint8List> encrypt({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List plaintext,
    Uint8List? aad,
  }) async {
    final box = await _algo.encrypt(
      plaintext,
      secretKey: c.SecretKeyData(key),
      nonce: nonce,
      aad: aad ?? const [],
    );
    return _concat(box.cipherText, box.mac.bytes);
  }

  @override
  Future<Uint8List> decrypt({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List ciphertext,
    Uint8List? aad,
  }) async {
    if (ciphertext.length < 16) {
      throw CryptoException('密文长度不足（损坏的数据）');
    }
    final ctPart = ciphertext.sublist(0, ciphertext.length - 16);
    final mac = ciphertext.sublist(ciphertext.length - 16);
    try {
      return Uint8List.fromList(await _algo.decrypt(
        c.SecretBox(ctPart, nonce: nonce, mac: c.Mac(mac)),
        secretKey: c.SecretKeyData(key),
        aad: aad ?? const [],
      ));
    } on c.SecretBoxAuthenticationError {
      throw CryptoException('认证失败：密钥错误或数据被篡改');
    }
  }
}

class _Pbkdf2Kdf extends PassphraseKdf {
  _Pbkdf2Kdf(this.iterations);

  final int iterations;

  @override
  String get algoId => 'pbkdf2-hmac-sha512';

  @override
  Map<String, Object> get params => {'iterations': iterations, 'bits': 256};

  @override
  Future<Uint8List> derive({
    required String passphrase,
    required Uint8List salt,
  }) async {
    final kdf = c.Pbkdf2(
      macAlgorithm: c.Hmac.sha512(),
      iterations: iterations,
      bits: 256,
    );
    final key = await kdf.deriveKey(
      secretKey: c.SecretKeyData(utf8.encode(passphrase)),
      nonce: salt,
    );
    return Uint8List.fromList(await key.extractBytes());
  }
}

Uint8List _concat(List<int> a, List<int> b) {
  final out = Uint8List(a.length + b.length);
  out.setRange(0, a.length, a);
  out.setRange(a.length, out.length, b);
  return out;
}
