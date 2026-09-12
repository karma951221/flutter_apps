import 'package:freezed_annotation/freezed_annotation.dart';

import 'failure_code.dart';

part 'failure.freezed.dart';

/// 앱 전체가 공유하는 실패 타입.
///
/// Supabase 예외는 여기까지 올라오지 않는다. data 계층의 mapper 가
/// 이 타입으로 변환한 뒤에야 domain / presentation 으로 넘어간다.
@freezed
sealed class Failure with _$Failure {
  /// 네트워크 연결 자체가 실패
  const factory Failure.network({String? message, FailureCode? failureCode}) =
      NetworkFailure;

  /// 인증 실패 (자격 오류, 세션 만료)
  const factory Failure.auth({
    String? message,
    String? code,
    FailureCode? failureCode,
  }) = AuthFailure;

  /// 권한 없음 (RLS 거부 포함)
  const factory Failure.forbidden({String? message, FailureCode? failureCode}) =
      ForbiddenFailure;

  /// 대상 없음
  const factory Failure.notFound({String? message, FailureCode? failureCode}) =
      NotFoundFailure;

  /// 입력값 문제 (중복 닉네임, 제약 위반)
  const factory Failure.validation({
    String? message,
    String? field,
    FailureCode? failureCode,
  }) = ValidationFailure;

  /// 서버 오류
  const factory Failure.server({
    String? message,
    String? code,
    FailureCode? failureCode,
  }) = ServerFailure;

  /// 분류되지 않은 오류
  const factory Failure.unknown({String? message, FailureCode? failureCode}) =
      UnknownFailure;
}
