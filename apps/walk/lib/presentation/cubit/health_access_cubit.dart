import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entity/health_access.dart';
import '../../domain/usecase/walk_use_case.dart';
import 'health_access_state.dart';

class HealthAccessCubit extends Cubit<HealthAccessState> {
  HealthAccessCubit(this._useCase) : super(const HealthAccessState());

  final WalkUseCase _useCase;

  /// 시작 · 복귀 때. 권한이 없으면 이번 세션에 한 번만 요청 화면이 뜬다.
  Future<void> check() async => _emit(await _useCase.access());

  /// "권한 허용" 버튼. 이미 거부했어도 다시 묻는다.
  Future<void> request() async => _emit(await _useCase.requestAccess());

  /// 플레이스토어로 나간다. 돌아오면 페이지의 resumed 가 [check] 를 부른다.
  Future<void> openInstall() => _useCase.openInstall();

  /// Health Connect 권한 설정으로 나간다. 돌아오면 역시 resumed 가 [check] 를 부른다.
  Future<void> openSettings() => _useCase.openPermissionSettings();

  void _emit(HealthAccess access) {
    if (isClosed) return;
    emit(HealthAccessState(
      access: access,
      canOpenSettings: _useCase.permissionDeclinedThisSession,
    ));
  }
}
