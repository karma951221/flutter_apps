import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission/permission.dart';

import '../../../domain/alarm/permission/alarm_permissions.dart';
import '../../../domain/walk/entity/health_access.dart';
import '../../../domain/walk/usecase/walk_use_case.dart';
import 'settings_permissions_state.dart';

/// 설정 탭 "권한" 모아보기. 시스템 설정으로 나갔다 오면 셸의 resumed 가 [check] 를 부른다.
class SettingsPermissionsCubit extends Cubit<SettingsPermissionsState> {
  SettingsPermissionsCubit(this._permissions, this._walk)
    : super(const SettingsPermissionsState());

  final AlarmPermissions _permissions;
  final WalkUseCase _walk;

  Future<void> check() async {
    final results = await Future.wait([
      _permissions.notification.check(),
      _permissions.exactAlarm.check(),
      _permissions.fullScreenIntent.check(),
    ]);
    final health = await _walk.access();
    if (isClosed) return;
    emit(SettingsPermissionsState(
      notification: results[0],
      exactAlarm: results[1],
      fullScreenIntent: results[2],
      health: health,
    ));
  }

  /// 아직 다이얼로그를 띄울 수 있으면(denied) 바로 묻고, 아니면 앱 설정을 연다.
  Future<void> openNotification() async {
    final requester = _permissions.notification;
    if (await requester.check() == PermissionStatus.denied) {
      await requester.requestAgain();
    } else {
      await requester.openSettings();
    }
    await check();
  }

  /// 런타임 다이얼로그가 없는 권한 — 해당 설정 화면이 열리고, 결과는 복귀 때 읽는다.
  Future<void> openExactAlarm() => _permissions.exactAlarm.openSettings();

  Future<void> openFullScreenIntent() => _permissions.fullScreenIntent.openSettings();

  /// 설치 · 업데이트가 필요하면 스토어, 거부면 권한 요청(두 번 거부해 다이얼로그가
  /// 생략되면 Health Connect 설정), 허용이면 철회할 수 있게 Health Connect 설정.
  Future<void> openHealth() async {
    switch (state.health ?? await _walk.access()) {
      case HealthAccess.notInstalled || HealthAccess.updateRequired:
        await _walk.openInstall();
      case HealthAccess.permissionDenied when !_walk.permissionDeclinedThisSession:
        await _walk.requestAccess();
        await check();
      case HealthAccess.permissionDenied || HealthAccess.granted:
        await _walk.openPermissionSettings();
    }
  }
}
