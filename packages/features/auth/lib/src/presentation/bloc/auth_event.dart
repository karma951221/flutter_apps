import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entity/app_user.dart';

part 'auth_event.freezed.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  /// 구독 시작. 앱 부팅 시 한 번.
  const factory AuthEvent.started() = AuthStarted;

  /// 저장소에서 흘러온 사용자 변화.
  const factory AuthEvent.userChanged(AppUser? user) = AuthUserChanged;

  /// 세션은 그대로인 채 사용자 정보만 다시 읽는다.
  ///
  /// 프로필을 수정해도 로그인 때 만들어진 [AppUser] 스냅샷은 그대로라서,
  /// 이걸 보내지 않으면 방금 바꾼 닉네임·사진이 화면에 반영되지 않는다.
  const factory AuthEvent.userRefreshRequested() = AuthUserRefreshRequested;

  const factory AuthEvent.signOutRequested() = AuthSignOutRequested;
}
