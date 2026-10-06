import 'package:alarm/alarm.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';

import 'core/app.dart';
import 'core/background/alarm_resync.dart';
import 'core/di/injection.dart';
import 'domain/alarm/holiday/holiday_calendar.dart';
import 'domain/alarm/usecase/alarm_use_case.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 이전 세션의 예약을 다시 걸고 알림 스누즈 기록을 반영한다. DI 의 스케줄러가 쓰기 전에 끝나야 한다.
  await Alarm.init();
  await configureDependencies();
  runApp(const WalkApp());
}

/// 앱이 떠 있지 않을 때 네이티브 `AlarmResync` 가 헤드리스 엔진에서 부른다 — 시간대가 바뀌었을 때와
/// 하루 한 번 작업(`DailyAlarmSyncWorker`). 공휴일 캐시를 갱신하고(하루 한 번, 엔진에 붙은
/// `walk/holidays`), 예약을 지금 시간대의 벽시계로 다시 채우고 `done` 을 보낸다(성공 · 실패 모두).
@pragma('vm:entry-point')
Future<void> alarmResyncMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await runAlarmResync(
    init: () async {
      // 새 엔진이라 init 의 checkAlarm 이 저장된 예약(오프셋 없는 벽시계)을 지금 시간대로
      // 다시 건다 — 메인 isolate 의 `timeZoneChanged` 가 하는 일과 같아 sync 만 남는다.
      await Alarm.init();
      await configureDependencies();
    },
    refreshHolidays: () => getIt<HolidayRefresher>().refresh(),
    sync: () => getIt<AlarmUseCase>().sync(),
    done: () => backgroundChannel.invokeMethod<void>('done'),
  );
}
