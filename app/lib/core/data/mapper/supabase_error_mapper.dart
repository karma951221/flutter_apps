import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../error/failure.dart';

/// Supabase 예외를 앱의 Failure 로 변환한다.
///
/// 이 파일이 공용 data 인프라의 경계다. 여기를 지나면 Supabase 타입은 사라진다.
abstract final class SupabaseErrorMapper {
  static Failure map(Object error) {
    if (error is AuthException) return _auth(error);
    if (error is PostgrestException) return _postgrest(error);
    if (error is SocketException || error is TimeoutException) {
      return const Failure.network(message: '네트워크에 연결할 수 없습니다');
    }
    return Failure.unknown(message: error.toString());
  }

  static Failure _auth(AuthException e) {
    final constraint = _constraintFrom(e.message);
    if (constraint != null) return constraint;

    return switch (e.code) {
      'invalid_credentials' || 'invalid_grant' => const Failure.auth(
        message: '이메일 또는 비밀번호가 올바르지 않습니다',
        code: 'invalid_credentials',
      ),
      'user_already_exists' || 'email_exists' => const Failure.validation(
        message: '이미 가입된 이메일입니다',
        field: 'email',
      ),
      'weak_password' => const Failure.validation(
        message: '비밀번호가 너무 단순합니다',
        field: 'password',
      ),
      'same_password' => const Failure.validation(
        message: '이전과 다른 비밀번호를 입력하세요',
        field: 'password',
      ),
      'otp_expired' => const Failure.auth(
        message: '코드가 만료되었습니다. 다시 요청하세요',
        code: 'otp_expired',
      ),
      'over_email_send_rate_limit' => const Failure.auth(
        message: '요청이 너무 잦습니다. 잠시 후 다시 시도하세요',
        code: 'rate_limit',
      ),
      _ => _byStatus(e),
    };
  }

  static Failure _byStatus(AuthException e) => switch (e.statusCode) {
    '401' || '403' => Failure.auth(message: e.message, code: e.code),
    '404' => Failure.notFound(message: e.message),
    '422' => Failure.validation(message: e.message),
    '429' => const Failure.auth(
      message: '요청이 너무 잦습니다. 잠시 후 다시 시도하세요',
      code: 'rate_limit',
    ),
    _ => Failure.server(message: e.message, code: e.code),
  };

  static Failure _postgrest(PostgrestException e) {
    final constraint = _constraintFrom('${e.message} ${e.details ?? ''}');
    if (constraint != null) return constraint;

    return switch (e.code) {
      '23505' => const Failure.validation(message: '이미 사용 중인 값입니다'),
      '23514' => const Failure.validation(message: '입력값이 조건을 만족하지 않습니다'),
      '23503' => const Failure.validation(message: '참조 대상이 존재하지 않습니다'),
      '42501' => const Failure.forbidden(message: '권한이 없습니다'),
      'PGRST116' => const Failure.notFound(message: '대상을 찾을 수 없습니다'),
      _ => Failure.server(message: e.message, code: e.code),
    };
  }

  static Failure? _constraintFrom(String raw) {
    if (raw.contains('profiles_nickname_length')) {
      return const Failure.validation(
        message: '닉네임은 2자 이상 20자 이하여야 합니다',
        field: 'nickname',
      );
    }
    if (raw.contains('profiles_nickname_lower_idx') ||
        raw.contains('profiles_nickname_key')) {
      return const Failure.validation(
        message: '이미 사용 중인 닉네임입니다',
        field: 'nickname',
      );
    }
    if (raw.contains('profiles_bio_length')) {
      return const Failure.validation(
        message: '자기소개는 200자 이하여야 합니다',
        field: 'bio',
      );
    }
    if (raw.contains('feed_posts_content_length')) {
      return const Failure.validation(
        message: '게시물은 1자 이상 500자 이하여야 합니다',
        field: 'content',
      );
    }
    return null;
  }
}
