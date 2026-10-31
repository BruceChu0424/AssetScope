import 'dart:convert';
import 'dart:typed_data';

import 'package:sodium/sodium_sumo.dart' as sumo;

import '../l10n/runtime_l10n.dart';
import 'crypto_suite.dart';

/// libsodium 密码学套件（设备端首选：Argon2id + XSalsa20-Poly1305）。
///
/// 通过 [tryInit] 创建；原生库不可用时返回 null，应用回退到
/// [DartCryptoSuite]。两个套件写入头部的算法参数互相兼容：
/// 解包始终按头部声明的 kdfAlgo/params 派生密钥。
class SodiumCryptoSuite extends CryptoSuite {
  SodiumCryptoSuite._(this._sumo);

  final sumo.SodiumSumo _sumo;

  /// 初始化失败（原生库缺失/平台不支持）返回 null。
  static Future<SodiumCryptoSuite?> tryInit() async {
    try {
      final s = await sumo.SodiumSumoInit.init();
      return SodiumCryptoSuite._(s);
    } catch (_) {
      return null;
    }
  }

  @override
  String get name => 'sodium';

  @override
  AeadCipher get aead => _SecretBoxAead(_sumo);

  @override
  PassphraseKdf get kdf => _Argon2idKdf(_sumo);
}

class _SecretBoxAead extends AeadCipher {
  _SecretBoxAead(this._sumo);

  final sumo.SodiumSumo _sumo;

  @override
  String get algoId => 'xsalsa20-poly1305';

  @override
  int get nonceLength => _sumo.crypto.secretBox.nonceBytes;

  @override
  Future<Uint8List> encrypt({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List plaintext,
    Uint8List? aad,
  }) async {
    if (aad != null && aad.isNotEmpty) {
      throw CryptoException(rt('secretBox 不支持 AAD'));
    }
    final sk = sumo.SecureKey.fromList(_sumo, key);
    try {
      return _sumo.crypto.secretBox.easy(
        message: plaintext,
        nonce: nonce,
        key: sk,
      );
    } on sumo.SodiumException catch (e) {
      throw CryptoException('${rt('加密失败: ')}$e');
    } finally {
      sk.dispose();
    }
  }

  @override
  Future<Uint8List> decrypt({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List ciphertext,
    Uint8List? aad,
  }) async {
    if (aad != null && aad.isNotEmpty) {
      throw CryptoException(rt('secretBox 不支持 AAD'));
    }
    final sk = sumo.SecureKey.fromList(_sumo, key);
    try {
      return _sumo.crypto.secretBox.openEasy(
        cipherText: ciphertext,
        nonce: nonce,
        key: sk,
      );
    } on sumo.SodiumException {
      throw CryptoException(rt('认证失败：密钥错误或数据被篡改'));
    } finally {
      sk.dispose();
    }
  }
}

class _Argon2idKdf extends PassphraseKdf {
  _Argon2idKdf(this._sumo);

  final sumo.SodiumSumo _sumo;

  @override
  String get algoId => 'argon2id';

  @override
  Map<String, Object> get params => {
    'ops': _sumo.crypto.pwhash.opsLimitModerate,
    'mem': _sumo.crypto.pwhash.memLimitModerate,
  };

  @override
  Future<Uint8List> derive({
    required String passphrase,
    required Uint8List salt,
  }) async {
    final pwBytes = utf8.encode(passphrase);
    final padded = salt.length == _sumo.crypto.pwhash.saltBytes
        ? salt
        : _padSalt(salt, _sumo.crypto.pwhash.saltBytes);
    final out = _sumo.crypto.pwhash(
      outLen: 32,
      password: Int8List.fromList(pwBytes),
      salt: padded,
      opsLimit: _sumo.crypto.pwhash.opsLimitModerate,
      memLimit: _sumo.crypto.pwhash.memLimitModerate,
      alg: sumo.CryptoPwhashAlgorithm.argon2id13,
    );
    return out.extractBytes();
  }

  Uint8List _padSalt(Uint8List salt, int len) {
    final out = Uint8List(len);
    out.setRange(0, salt.length > len ? len : salt.length, salt);
    return out;
  }
}
