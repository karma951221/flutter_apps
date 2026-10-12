import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/lock/secret_hasher.dart';

void main() {
  test('salt 는 16바이트 base64 이고 매번 다르다', () {
    final a = SecretHasher.newSalt();
    final b = SecretHasher.newSalt();

    expect(base64.decode(a), hasLength(16));
    expect(a, isNot(b));
  });

  test('sha256 를 salt + 원문부터 10,000번 반복한다', () {
    // python: h = sha256((salt + '1234').encode()); 9,999번 더 sha256(h); base64.
    expect(
      SecretHasher.hash('c2FsdHNhbHRzYWx0c2FsdA==', '1234'),
      'zTcFOxqC7XKL6T7VzTE/ulL94pPzH512qAiFFTJYpXk=',
    );
  });

  test('salt 가 다르면 해시가 다르다', () {
    expect(
      SecretHasher.hash('c2FsdHNhbHRzYWx0c2FsdA==', '1234'),
      isNot(SecretHasher.hash('b3RoZXJzYWx0b3RoZXJzYQ==', '1234')),
    );
  });

  test('상수 시간 비교', () {
    expect(SecretHasher.matches('abcd', 'abcd'), isTrue);
    expect(SecretHasher.matches('abcd', 'abce'), isFalse);
    expect(SecretHasher.matches('abcd', 'abc'), isFalse);
    expect(SecretHasher.matches('', ''), isTrue);
  });
}
