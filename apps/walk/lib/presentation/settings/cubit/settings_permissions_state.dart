import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:permission/permission.dart';

import '../../../domain/walk/entity/health_access.dart';

part 'settings_permissions_state.freezed.dart';

/// 설정 탭 권한 행들의 상태. null = 아직 확인 중.
@freezed
class SettingsPermissionsState with _$SettingsPermissionsState {
  @override
  final PermissionStatus? notification;
  @override
  final PermissionStatus? exactAlarm;
  @override
  final PermissionStatus? fullScreenIntent;
  @override
  final HealthAccess? health;

  const SettingsPermissionsState({
    this.notification,
    this.exactAlarm,
    this.fullScreenIntent,
    this.health,
  });
}
