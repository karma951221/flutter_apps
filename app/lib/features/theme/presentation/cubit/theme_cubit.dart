import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/app_theme_mode.dart';
import '../../domain/usecase/theme_use_case.dart';

/// 앱 전체의 화면 테마를 소유한다. `DaylogApp` 에서 만들어 앱 수명 전체를 산다.
///
/// 상태는 [AppThemeMode] 값 하나다 — Freezed 를 씌울 필드가 없으므로 상태
/// 클래스를 두지 않는다. `BuildContext` 를 알지 못한다.
@injectable
class ThemeCubit extends Cubit<AppThemeMode> {
  ThemeCubit(this._useCase) : super(_useCase.loadThemeMode());

  final ThemeUseCase _useCase;

  /// 고른 테마를 즉시 적용하고 기기에 남긴다.
  ///
  /// 저장 실패는 삼킨다 — 화면은 이미 바뀌었고, 실패하면 다음 실행에 이전 값으로
  /// 뜰 뿐이다. 그것을 오류로 알리는 편이 더 성가시다(계획서).
  Future<void> setMode(AppThemeMode mode) async {
    if (state == mode) return;
    emit(mode);
    await _useCase.saveThemeMode(mode);
  }
}

/// domain 의 [AppThemeMode] 를 material 의 [ThemeMode] 로 옮긴다.
///
/// material 타입을 아는 곳은 presentation 뿐이다.
extension AppThemeModeX on AppThemeMode {
  ThemeMode get themeMode => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}
