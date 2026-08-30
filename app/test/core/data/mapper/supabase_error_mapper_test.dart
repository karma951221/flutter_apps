import 'package:daylog/core/data/mapper/supabase_error_mapper.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('신고(reports) 제약 변환', () {
    test('reports_once 중복 신고를 안내로 바꾼다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(
          message:
              'duplicate key value violates unique constraint "reports_once"',
          code: '23505',
        ),
      );

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).message, '이미 신고한 항목입니다');
    });

    test('reports_detail_length 제약을 사용자 문구로 옮긴다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(
          message:
              'new row for relation "reports" violates check constraint '
              '"reports_detail_length"',
          code: '23514',
        ),
      );

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).field, 'detail');
      expect(failure.message, contains('500자'));
    });

    test('reports_not_self_user 제약을 안내로 바꾼다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(
          message:
              'new row for relation "reports" violates check constraint '
              '"reports_not_self_user"',
          code: '23514',
        ),
      );

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).message, '자기 자신은 신고할 수 없습니다');
    });
  });

  group('차단(blocks) 제약 변환', () {
    test('blocks_not_self 제약을 안내로 바꾼다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(
          message:
              'new row for relation "blocks" violates check constraint '
              '"blocks_not_self"',
          code: '23514',
        ),
      );

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).message, '자기 자신은 차단할 수 없습니다');
    });

    test('blocks_pkey 중복 차단을 안내로 바꾼다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(
          message:
              'duplicate key value violates unique constraint "blocks_pkey"',
          code: '23505',
        ),
      );

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).message, '이미 차단한 사용자입니다');
    });

    test('enforce_comment_depth() 의 차단 트리거 문구를 그대로 전달한다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(message: '이 게시물에는 댓글을 달 수 없습니다', code: '42501'),
      );

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).message, '이 게시물에는 댓글을 달 수 없습니다');
    });
  });

  group('enforce_report_target() 트리거 문구', () {
    test('대상 없음 문구를 그대로 전달한다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(message: '신고할 대상이 없습니다', code: '23514'),
      );

      expect((failure as ValidationFailure).message, '신고할 대상이 없습니다');
    });

    test('내 게시물 신고 금지 문구를 그대로 전달한다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(message: '내 게시물은 신고할 수 없습니다', code: '23514'),
      );

      expect((failure as ValidationFailure).message, '내 게시물은 신고할 수 없습니다');
    });

    test('내 댓글 신고 금지 문구를 그대로 전달한다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(message: '내 댓글은 신고할 수 없습니다', code: '23514'),
      );

      expect((failure as ValidationFailure).message, '내 댓글은 신고할 수 없습니다');
    });
  });

  group('기존 매핑이 깨지지 않는다', () {
    test('댓글 300자 제약은 여전히 사용자 문구로 번역된다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(
          message:
              'new row for relation "post_comments" violates check constraint '
              '"post_comments_content_length"',
          code: '23514',
        ),
      );

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).message, contains('300자'));
    });

    test('2단 답글 제한 트리거 문구는 여전히 그대로 전달된다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(message: '답글에는 답글을 달 수 없습니다', code: '23514'),
      );

      expect((failure as ValidationFailure).message, '답글에는 답글을 달 수 없습니다');
    });
  });
}
