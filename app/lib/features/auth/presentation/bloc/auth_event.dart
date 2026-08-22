import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entity/app_user.dart';

part 'auth_event.freezed.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  /// 구독 시작. 앱 부팅 시 한 번.
  const factory AuthEvent.started() = AuthStarted;

  /// 저장소에서 흘러온 사용자 변화.
  const factory AuthEvent.userChanged(AppUser? user) = AuthUserChanged;

  const factory AuthEvent.signOutRequested() = AuthSignOutRequested;
}
