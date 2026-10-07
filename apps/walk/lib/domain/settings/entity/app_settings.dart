import 'package:freezed_annotation/freezed_annotation.dart';

import '../../alarm/entity/alarm_pause.dart';
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

  /// 반복 알람이 공휴일에 울리면 24시간 전에 알려 준다(앱 전역, 기본 켬).
  @override
  final bool holidayReminder;

  /// 모든 알람을 쉬는 기간(앱 전역 하나). 없으면 null. 지나면 알람 sync 가 지운다.
  @override
  final AlarmPause? pause;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.stepGoal = StepGoal.defaultSteps,
    this.goalCelebratedOn,
    this.holidayReminder = true,
    this.pause,
  });
}
