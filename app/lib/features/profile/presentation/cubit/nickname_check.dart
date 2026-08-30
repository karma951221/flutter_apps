import 'package:freezed_annotation/freezed_annotation.dart';

part 'nickname_check.freezed.dart';

/// 닉네임 사전 중복 확인의 상태.
///
/// 최종 판정은 `profiles_nickname_key` 유니크 제약이 한다. 이 값은 저장 버튼을
/// 누르기 전에 결과를 미리 보여주기 위한 것이고, 확인에 실패하면 [idle] 로
/// 되돌아가 아무 말도 하지 않는다 — 틀린 안내보다 침묵이 낫다.
@freezed
sealed class NicknameCheck with _$NicknameCheck {
  /// 확인할 것이 없다 (형식 미달·현재 닉네임 그대로·확인 실패).
  const factory NicknameCheck.idle() = NicknameCheckIdle;
  const factory NicknameCheck.checking() = NicknameCheckChecking;
  const factory NicknameCheck.available() = NicknameCheckAvailable;
  const factory NicknameCheck.taken() = NicknameCheckTaken;
}
