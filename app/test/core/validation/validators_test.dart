import 'package:daylog/core/validation/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('email', () {
    test('빈 값은 거부한다', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('   '), isNotNull);
    });

    test('형식이 틀리면 거부한다', () {
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('abc@'), isNotNull);
      expect(Validators.email('abc@def'), isNotNull);
      expect(Validators.email('@def.com'), isNotNull);
    });

    test('올바른 형식은 통과한다', () {
      expect(Validators.email('a@b.com'), isNull);
      expect(Validators.email('first.last+tag@sub.example.co.kr'), isNull);
      expect(Validators.email('  spaced@example.com  '), isNull);
    });
  });

  group('password', () {
    test('8자 미만은 거부한다', () {
      expect(Validators.password('1234567'), isNotNull);
    });

    test('8자 이상은 통과한다', () {
      expect(Validators.password('12345678'), isNull);
    });
  });

  group('passwordConfirm', () {
    test('불일치는 거부한다', () {
      expect(Validators.passwordConfirm('abcd1234', 'abcd9999'), isNotNull);
    });

    test('일치하면 통과한다', () {
      expect(Validators.passwordConfirm('abcd1234', 'abcd1234'), isNull);
    });
  });

  group('nickname', () {
    // DB 제약(profiles_nickname_length)과 값이 일치해야 한다.
    test('2자 미만은 거부한다', () {
      expect(Validators.nickname('가'), isNotNull);
    });

    test('20자 초과는 거부한다', () {
      expect(Validators.nickname('a' * 21), isNotNull);
    });

    test('경계값 2자와 20자는 통과한다', () {
      expect(Validators.nickname('ab'), isNull);
      expect(Validators.nickname('a' * 20), isNull);
    });

    test('앞뒤 공백은 무시하고 판단한다', () {
      expect(Validators.nickname('  ab  '), isNull);
      expect(Validators.nickname('  가  '), isNotNull);
    });
  });

  group('otpCode', () {
    test('6자리 숫자가 아니면 거부한다', () {
      expect(Validators.otpCode('12345'), isNotNull);
      expect(Validators.otpCode('1234567'), isNotNull);
      expect(Validators.otpCode('abcdef'), isNotNull);
    });

    test('6자리 숫자는 통과한다', () {
      expect(Validators.otpCode('123456'), isNull);
      expect(Validators.otpCode('000000'), isNull);
    });
  });
}
