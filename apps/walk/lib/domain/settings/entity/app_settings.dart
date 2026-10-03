import 'package:freezed_annotation/freezed_annotation.dart';

import '../../walk/entity/step_goal.dart';

part 'app_settings.freezed.dart';

/// 화면 테마 선택. Flutter `ThemeMode` 와 같은 뜻이지만 domain 이 Flutter 에 기대지 않게 따로 둔다.
enum AppThemeMode { system, light, dark }

@freezed
class AppSettings with _$AppSettings {
  @override
  final AppThemeMode themeMode;

  /// 하루 걸음 목표.
  @override
  final int stepGoal;

  /// 목표 달성 축하를 마지막으로 보인 날(날짜만, 로컬 자정).
  @override
  final DateTime? goalCelebratedOn;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.stepGoal = StepGoal.defaultSteps,
    this.goalCelebratedOn,
  });
}
