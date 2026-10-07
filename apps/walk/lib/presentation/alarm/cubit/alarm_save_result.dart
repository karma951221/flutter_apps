import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../../../domain/alarm/entity/alarm_pause.dart';
import '../../../domain/alarm/upcoming_triggers.dart';

part 'alarm_save_result.freezed.dart';

/// 알람을 켠 채 저장하거나 스위치로 켠 뒤 목록이 띄울 스낵바의 근거.
@freezed
sealed class AlarmSaveResult with _$AlarmSaveResult {
  /// 다음 울림까지 남은 시간(쉬는 기간의 회차는 빼고 센다).
  const factory AlarmSaveResult.ringsIn(Duration untilRing) = AlarmRingsIn;

  /// 쉬는 기간 때문에 울릴 회차가 없다(쉬는 중에 만든 그 기간 안의 한 번 알람).
  const factory AlarmSaveResult.pausedOut() = AlarmPausedOut;

  /// [alarm] 의 [now] 뒤 첫 회차로 정한다. 쉬는 기간을 빼면 회차가 없지만 빼지 않으면 있으면
  /// [AlarmPausedOut], 둘 다 없으면(꺼짐 · 지난 한 번 알람) null.
  static AlarmSaveResult? of(Alarm alarm, DateTime now, AlarmPause? pause) {
    if (upcomingTriggers(alarm, now, pause: pause).firstOrNull case final at?) {
      return AlarmSaveResult.ringsIn(at.difference(now));
    }
    if (pause != null && upcomingTriggers(alarm, now).isNotEmpty) {
      return const AlarmSaveResult.pausedOut();
    }
    return null;
  }
}
