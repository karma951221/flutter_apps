import 'dart:io';
import 'package:daylog/core/data/mapper/supabase_error_mapper.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/error/failure_code.dart';
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
      expect(failure.failureCode, FailureCode.reportAlreadySubmitted);
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
      expect(failure.failureCode, FailureCode.commentNotAllowed);
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

    // 20260822120000 마이그레이션이 feed_posts → posts 로 rename 하면서 제약
    // 이름도 posts_content_length 로 바뀌었다. 매퍼가 옛 이름을 보고 있으면
    // 500자 초과 저장에서 사용자 문구 대신 DB 원문이 그대로 올라간다.
    test('게시물 길이 제약을 사용자 문구로 옮긴다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(
          message:
              'new row for relation "posts" violates check constraint '
              '"posts_content_length"',
          code: '23514',
        ),
      );
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).field, 'content');
      expect(failure.message, contains('500자'));
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

  group('댓글·감정 제약', () {
    test('300자 제약 위반이 사용자 문구로 번역된다', () {
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

    test('2단 제한 트리거의 문구를 그대로 전달한다', () {
      // 트리거가 이미 사용자에게 보여줄 수 있는 한국어로 던진다. 기본 문구로
      // 덮으면 무엇이 잘못됐는지가 사라진다.
      final failure = SupabaseErrorMapper.map(
        PostgrestException(message: '답글에는 답글을 달 수 없습니다', code: '23514'),
      );

      expect((failure as ValidationFailure).message, '답글에는 답글을 달 수 없습니다');
    });

    test('삭제된 대상에 쓰기를 막은 42501 을 안내로 바꾼다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(
          message: 'new row violates row-level security policy',
          code: '42501',
        ),
      );

      expect(failure, isA<ForbiddenFailure>());
      expect((failure as ForbiddenFailure).message, contains('삭제된 대상'));
    });

    test('정의되지 않은 감정 코드를 안내로 바꾼다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(
          message: 'violates check constraint "post_reactions_type_valid"',
          code: '23514',
        ),
      );

      expect((failure as ValidationFailure).message, contains('감정'));
    });
  });

  group('채팅(chat) 트리거 변환', () {
    // F9 chat 이 더한 raise 문구 3개가 mapper 에 없어서, 정원이 찬 방에
    // 들어가면 "입력값이 조건을 만족하지 않습니다" 라는 엉뚱한 안내가 떴다
    // (2026-08-30 리뷰). 문구를 못 알아보면 코드가 없어 번역도 되지 않는다.
    test('정원이 찬 방은 그 사실을 그대로 알린다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(message: '정원이 가득 찬 방입니다', code: '23514'),
      );

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).failureCode, FailureCode.roomFull);
    });

    test('없는 방 입장은 참조 오류로 뭉개지 않는다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(message: '없는 방입니다', code: '23503'),
      );

      expect(
        (failure as ValidationFailure).failureCode,
        FailureCode.roomNotFound,
      );
    });

    test('내 메시지 신고 거부는 원문 한국어로 새지 않는다', () {
      // using errcode 가 없어 P0001 로 올라온다. 코드를 못 붙이면
      // Failure.server 의 raw message 가 그대로 화면에 나간다.
      final failure = SupabaseErrorMapper.map(
        PostgrestException(message: '내 메시지는 신고할 수 없습니다', code: 'P0001'),
      );

      expect(
        (failure as ValidationFailure).failureCode,
        FailureCode.reportOwnMessageNotAllowed,
      );
    });
  });

  group('trade RPC 문구 변환', () {
    // F10 마이그레이션이 아직 없어도 mapper 는 미리 문구를 알아야 한다 —
    // trigger_message_mapping_test.dart 가 마이그레이션 착지 즉시 이 문구들을
    // 요구한다.
    test('진행 중인 판이 있으면 그 사실을 그대로 알린다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(message: '진행 중인 판이 있습니다', code: 'P0001'),
      );

      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).failureCode,
        FailureCode.tradeSessionAlreadyActive,
      );
    });

    test('판을 찾을 수 없으면 남의 판인지 없는 id 인지 구분하지 않는다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(message: '판을 찾을 수 없습니다', code: 'P0001'),
      );

      expect(
        (failure as ValidationFailure).failureCode,
        FailureCode.tradeSessionNotFound,
      );
    });

    test('이미 끝난 판에 매매를 시도하면 그 사실을 알린다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(message: '이미 끝난 판입니다', code: 'P0001'),
      );

      expect(
        (failure as ValidationFailure).failureCode,
        FailureCode.tradeSessionFinished,
      );
    });

    test('잔고 부족 매수를 안내로 바꾼다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(message: '잔고가 부족합니다', code: 'P0001'),
      );

      expect(
        (failure as ValidationFailure).failureCode,
        FailureCode.tradeInsufficientCash,
      );
    });

    test('보유 수량 초과 매도를 안내로 바꾼다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(message: '보유 수량이 부족합니다', code: 'P0001'),
      );

      expect(
        (failure as ValidationFailure).failureCode,
        FailureCode.tradeInsufficientQuantity,
      );
    });

    test('0 이하 수량 주문을 안내로 바꾼다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(message: '수량은 0보다 커야 합니다', code: 'P0001'),
      );

      expect(
        (failure as ValidationFailure).failureCode,
        FailureCode.tradeQuantityInvalid,
      );
    });

    test('진행 중인 판 공유 시도를 안내로 바꾼다', () {
      final failure = SupabaseErrorMapper.map(
        PostgrestException(message: '끝난 판만 공유할 수 있습니다', code: 'P0001'),
      );

      expect(
        (failure as ValidationFailure).failureCode,
        FailureCode.tradeSessionNotShareable,
      );
    });
  });
}
