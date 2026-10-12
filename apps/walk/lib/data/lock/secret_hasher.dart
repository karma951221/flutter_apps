import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// 잠금 비밀 해시. 원문을 남기지 않으려고 salt + SHA-256 반복을 쓴다(스펙 §7).
abstract final class SecretHasher {
  static const saltBytes = 16;
  static const iterations = 10000;

  /// 16바이트 랜덤 salt(base64).
  static String newSalt() {
    final random = Random.secure();
    return base64.encode(
      List<int>.generate(saltBytes, (_) => random.nextInt(256)),
    );
  }

  /// sha256(salt + secret) 에서 시작해 sha256 를 모두 [iterations] 번 적용한 값(base64).
  static String hash(String salt, String secret) {
    var digest = sha256.convert(utf8.encode(salt + secret)).bytes;
    for (var i = 1; i < iterations; i++) {
      digest = sha256.convert(digest).bytes;
    }
    return base64.encode(digest);
  }

  /// 앞에서 다른 글자를 만나도 끝까지 비교한다(상수 시간).
  static bool matches(String a, String b) {
    var diff = a.length ^ b.length;
    final length = min(a.length, b.length);
    for (var i = 0; i < length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
