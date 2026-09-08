import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../error/failure.dart';
import '../../error/failure_code.dart';

/// Supabase 예외를 앱의 Failure 로 변환한다.
///
/// 이 파일이 공용 data 인프라의 경계다. 여기를 지나면 Supabase 타입은 사라진다.
abstract final class SupabaseErrorMapper {
  static Failure map(Object error) {
    if (error is AuthException) return _auth(error);
    if (error is PostgrestException) return _postgrest(error);
    if (error is FormatException) {
      return Failure.unknown(
        message: error.message.toString(),
        failureCode: FailureCode.invalidData,
      );
    }
    if (error is SocketException || error is TimeoutException) {
      return const Failure.network(
        message: '네트워크에 연결할 수 없습니다',
        failureCode: FailureCode.networkUnavailable,
      );
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
        failureCode: FailureCode.invalidCredentials,
      ),
      'user_already_exists' || 'email_exists' => const Failure.validation(
        message: '이미 가입된 이메일입니다',
        field: 'email',
        failureCode: FailureCode.emailAlreadyRegistered,
      ),
      'weak_password' => const Failure.validation(
        message: '비밀번호가 너무 단순합니다',
        field: 'password',
        failureCode: FailureCode.weakPassword,
      ),
      'same_password' => const Failure.validation(
        message: '이전과 다른 비밀번호를 입력하세요',
        field: 'password',
        failureCode: FailureCode.samePassword,
      ),
      'otp_expired' => const Failure.auth(
        message: '코드가 만료되었습니다. 다시 요청하세요',
        code: 'otp_expired',
        failureCode: FailureCode.otpExpired,
      ),
      'over_email_send_rate_limit' => const Failure.auth(
        message: '요청이 너무 잦습니다. 잠시 후 다시 시도하세요',
        code: 'rate_limit',
        failureCode: FailureCode.rateLimited,
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
      failureCode: FailureCode.rateLimited,
    ),
    _ => Failure.server(message: e.message, code: e.code),
  };

  static Failure _postgrest(PostgrestException e) {
    final constraint = _constraintFrom('${e.message} ${e.details ?? ''}');
    if (constraint != null) return constraint;

    return switch (e.code) {
      '23505' => const Failure.validation(
        message: '이미 사용 중인 값입니다',
        failureCode: FailureCode.duplicateValue,
      ),
      '23514' => const Failure.validation(
        message: '입력값이 조건을 만족하지 않습니다',
        failureCode: FailureCode.constraintViolation,
      ),
      '23503' => const Failure.validation(
        message: '참조 대상이 존재하지 않습니다',
        failureCode: FailureCode.referencedTargetMissing,
      ),
      // 삭제된 게시물에 댓글·반응을 남기려 할 때도 여기로 온다. RLS 가 거부한
      // 것이라 원인을 세분화할 방법이 없어 한 문장으로 안내한다.
      '42501' => const Failure.forbidden(
        message: '권한이 없거나 삭제된 대상입니다',
        failureCode: FailureCode.forbiddenOrDeleted,
      ),
      'PGRST116' => const Failure.notFound(
        message: '대상을 찾을 수 없습니다',
        failureCode: FailureCode.targetNotFound,
      ),
      _ => Failure.server(message: e.message, code: e.code),
    };
  }

  /// `enforce_comment_depth()` 가 던지는 문구들. 트리거의 raise 문과 같아야 한다.
  static const _commentDepthMessages = {
    '답글에는 답글을 달 수 없습니다': FailureCode.nestedReplyNotAllowed,
    '삭제된 댓글에는 답글을 달 수 없습니다': FailureCode.replyToDeletedCommentNotAllowed,
    '부모 댓글이 다른 게시물의 댓글입니다': FailureCode.replyParentPostMismatch,
    '부모 댓글이 없습니다': FailureCode.replyParentMissing,
  };

  /// `enforce_report_target()` 이 던지는 문구들. 트리거의 raise 문과 같아야 한다.
  static const _reportTargetMessages = {
    '신고할 대상이 없습니다': FailureCode.reportTargetMissing,
    '내 게시물은 신고할 수 없습니다': FailureCode.reportOwnPostNotAllowed,
    '내 댓글은 신고할 수 없습니다': FailureCode.reportOwnCommentNotAllowed,
    '내 메시지는 신고할 수 없습니다': FailureCode.reportOwnMessageNotAllowed,
  };

  /// `follows_guard_block()` 이 던지는 문구.
  ///
  /// 방향 중립이어야 한다 — 이 거부를 보는 쪽이 차단을 건 쪽이라고 가정할 수
  /// 없다. 데이터 원본이 42501 을 코드로 바꾸는 경로와 같은 결과를 낸다
  /// (`supabase_follow_data_source.followUser`).
  static const _followGuardMessages = {
    '지금은 팔로우할 수 없습니다': FailureCode.followBlocked,
  };

  /// trade RPC(`start_trade_session` 등)가 던지는 문구. 함수의 raise 문과
  /// 같아야 한다.
  static const _tradeMessages = {
    '진행 중인 판이 있습니다': FailureCode.tradeSessionAlreadyActive,
    '판을 찾을 수 없습니다': FailureCode.tradeSessionNotFound,
    '이미 끝난 판입니다': FailureCode.tradeSessionFinished,
    '잔고가 부족합니다': FailureCode.tradeInsufficientCash,
    '보유 수량이 부족합니다': FailureCode.tradeInsufficientQuantity,
    '수량은 0보다 커야 합니다': FailureCode.tradeQuantityInvalid,
    '끝난 판만 공유할 수 있습니다': FailureCode.tradeSessionNotShareable,
  };

  /// `enforce_room_capacity()` 가 던지는 문구들. 트리거의 raise 문과 같아야 한다.
  ///
  /// 없으면 23514 · 23503 의 기본 문구로 덮여 "입력값이 조건을 만족하지
  /// 않습니다" 가 뜬다 — 방이 꽉 찼다는 사실이 사라져 사용자가 같은 버튼을
  /// 계속 누르게 된다.
  static const _roomCapacityMessages = {
    '정원이 가득 찬 방입니다': FailureCode.roomFull,
    '대화를 시작할 수 없습니다': FailureCode.directChatNotAllowed,
    '자기 자신과는 대화할 수 없습니다': FailureCode.directChatSelfNotAllowed,
    '메시지를 보낼 수 없습니다': FailureCode.chatSendNotAllowed,
    '없는 방입니다': FailureCode.roomNotFound,
  };

  /// `enforce_comment_depth()` 가 차단 때 던지는 문구.
  ///
  /// 방향 중립이어야 한다 — 이 예외는 차단"한" 쪽이 아니라 차단"당한" 쪽이
  /// 본다(B가 A의 게시물 화면을 이미 열어 둔 상태에서 A가 차단하고, B가 댓글을
  /// 등록하는 시점). "차단한 사용자"라는 문구는 B에게는 거짓이고, 동시에 차단
  /// 사실과 방향을 드러낸다 — 계획서의 "차단 사실 노출: 알리지 않는다"를
  /// 정면으로 어긴다. `20260825130000_neutral_block_message.sql` 이 트리거
  /// 문구를 이걸로 바꿨다.
  static const _blockMessages = {
    '이 게시물에는 댓글을 달 수 없습니다': FailureCode.commentNotAllowed,
  };

  static Failure? _constraintFrom(String raw) {
    if (raw.contains('profiles_nickname_length')) {
      return const Failure.validation(
        message: '닉네임은 2자 이상 20자 이하여야 합니다',
        field: 'nickname',
        failureCode: FailureCode.nicknameLength,
      );
    }
    if (raw.contains('profiles_nickname_lower_idx') ||
        raw.contains('profiles_nickname_key')) {
      return const Failure.validation(
        message: '이미 사용 중인 닉네임입니다',
        field: 'nickname',
        failureCode: FailureCode.nicknameTaken,
      );
    }
    if (raw.contains('profiles_bio_length')) {
      return const Failure.validation(
        message: '자기소개는 200자 이하여야 합니다',
        field: 'bio',
        failureCode: FailureCode.bioTooLong,
      );
    }
    if (raw.contains('posts_content_length')) {
      return const Failure.validation(
        message: '게시물은 1자 이상 500자 이하여야 합니다',
        field: 'content',
        failureCode: FailureCode.postContentLength,
      );
    }
    if (raw.contains('post_comments_content_length')) {
      return const Failure.validation(
        message: '댓글은 1자 이상 300자 이하여야 합니다',
        field: 'content',
        failureCode: FailureCode.commentContentLength,
      );
    }
    if (raw.contains('post_reactions_type_valid') ||
        raw.contains('comment_reactions_type_valid')) {
      return const Failure.validation(
        message: '지원하지 않는 감정입니다',
        failureCode: FailureCode.unsupportedReaction,
      );
    }
    if (raw.contains('reports_once')) {
      return const Failure.validation(
        message: '이미 신고한 항목입니다',
        failureCode: FailureCode.reportAlreadySubmitted,
      );
    }
    if (raw.contains('reports_detail_length')) {
      return const Failure.validation(
        message: '상세 설명은 500자 이하여야 합니다',
        field: 'detail',
        failureCode: FailureCode.reportDetailTooLong,
      );
    }
    if (raw.contains('reports_not_self_user')) {
      return const Failure.validation(
        message: '자기 자신은 신고할 수 없습니다',
        failureCode: FailureCode.reportSelfNotAllowed,
      );
    }
    if (raw.contains('blocks_not_self')) {
      return const Failure.validation(
        message: '자기 자신은 차단할 수 없습니다',
        failureCode: FailureCode.blockSelfNotAllowed,
      );
    }
    // 이미 차단한 사용자를 다시 차단하려 할 때 복합 PK(blocker_id, blocked_id)
    // 위반으로 온다. 이 문구가 사용자에게 보일 일은 거의 없다 — UI 가 이미
    // '차단 해제' 메뉴를 그리고 있을 것이기 때문이다. 그래도 등록해 둔다.
    if (raw.contains('blocks_pkey')) {
      return const Failure.validation(
        message: '이미 차단한 사용자입니다',
        failureCode: FailureCode.blockAlreadyExists,
      );
    }
    // enforce_comment_depth() 와 enforce_report_target() 은 사용자에게 그대로
    // 보여줄 수 있는 한국어 문구로 예외를 던진다. 23514 의 기본 문구("입력값이
    // 조건을 만족하지 않습니다")로 덮으면 무엇이 잘못됐는지가 사라진다.
    for (final entry in <String, FailureCode>{
      ..._commentDepthMessages,
      ..._reportTargetMessages,
      ..._blockMessages,
      ..._roomCapacityMessages,
      ..._followGuardMessages,
      ..._tradeMessages,
    }.entries) {
      if (raw.contains(entry.key)) {
        return Failure.validation(message: entry.key, failureCode: entry.value);
      }
    }
    return null;
  }
}
