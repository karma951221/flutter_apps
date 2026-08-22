import 'dart:io';

import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/data/mapper/supabase_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthException 변환', () {
    test('invalid_credentials 는 계정 존재 여부를 노출하지 않는다', () {
      final failure = SupabaseErrorMapper.map(
        const AuthException(
          'Invalid login credentials',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
      );
      expect(failure, isA<AuthFailure>());
      final message = (failure as AuthFailure).message!;
      // "없는 계정" / "비밀번호 틀림" 을 구분해 알려주면 계정 열거가 가능해진다.
      expect(message, contains('이메일 또는 비밀번호'));
    });

    test('user_already_exists 는 이메일 검증 실패로 옮긴다', () {
      final failure = SupabaseErrorMapper.map(
        const AuthException(
          'exists',
          statusCode: '422',
          code: 'user_already_exists',
        ),
      );
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).field, 'email');
    });

    test('otp_expired 는 재요청을 안내한다', () {
      final failure = SupabaseErrorMapper.map(
        const AuthException('expired', statusCode: '403', code: 'otp_expired'),
      );
      expect(failure, isA<AuthFailure>());
      expect((failure as AuthFailure).code, 'otp_expired');
    });

    test('알 수 없는 코드는 상태 코드로 분류한다', () {
      expect(
        SupabaseErrorMapper.map(const AuthException('nope', statusCode: '429')),
        isA<AuthFailure>(),
      );
      expect(
        SupabaseErrorMapper.map(const AuthException('boom', statusCode: '500')),
        isA<ServerFailure>(),
      );
    });
  });

  group('DB 제약 위반 변환', () {
    // 회원가입 트리거가 실패하면 GoTrue 가 DB 오류 원문을 그대로 실어 보낸다.
    // 사용자에게 원문을 보여줄 수 없으므로 매퍼가 번역해야 한다.
    test('닉네임 길이 제약을 사용자 문구로 옮긴다', () {
      final failure = SupabaseErrorMapper.map(
        const AuthException(
          'violates check constraint "profiles_nickname_length"',
          statusCode: '500',
        ),
      );
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).field, 'nickname');
      expect(failure.message, contains('2자'));
    });

    test('닉네임 중복을 사용자 문구로 옮긴다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(
          message:
              'duplicate key value violates unique constraint '
              '"profiles_nickname_lower_idx"',
          code: '23505',
        ),
      );
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).message, contains('이미 사용'));
    });
  });

  group('PostgrestException 변환', () {
    test('42501 은 권한 없음이다', () {
      expect(
        SupabaseErrorMapper.map(
          PostgrestException(message: 'permission denied', code: '42501'),
        ),
        isA<ForbiddenFailure>(),
      );
    });
  });

  test('네트워크 예외는 network 로 분류한다', () {
    expect(
      SupabaseErrorMapper.map(const SocketException('no route')),
      isA<NetworkFailure>(),
    );
  });
}
