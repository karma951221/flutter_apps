import 'package:alarm/alarm.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app.dart';
import 'core/background/background_task.dart';
import 'core/di/injection.dart';
import 'domain/alarm/holiday/holiday_calendar.dart';
import 'domain/alarm/usecase/alarm_use_case.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 시작 sync 가 거는 알림 문구(기기 언어 시각)가 로컬라이제이션 로드를 기다리지 않게.
  await initializeDateFormatting();
  // 이전 세션의 예약을 다시 걸고 알림 스누즈 기록을 반영한다. DI 의 스케줄러가 쓰기 전에 끝나야 한다.
  await Alarm.init();
  await configureDependencies();
  runApp(const WalkApp());
}

/// 헤드리스 엔진 준비. 새 엔진이라 `Alarm.init` 의 checkAlarm 이 저장된 예약(오프셋 없는 벽시계)을
/// 지금 시간대로 다시 걸고, 알림 스누즈 기록을 Dart 저장소에 반영한다 — 빠뜨리면 sync 가 스누즈된
/// 회차를 지난 예약으로 보고 지울 수 있다. 날짜 기호도 올린다 — `MaterialApp` 이 없어, 빠뜨리면 이
/// 엔진이 거는 알람 · 미리 알림 문구가 기기 언어 시각(`오전 7:00`) 대신 `07:00` 으로 저장된다.
Future<void> _initHeadless() async {
  await initializeDateFormatting();
  await Alarm.init();
  await configureDependencies();
}

/// 앱이 떠 있지 않을 때 네이티브 `BackgroundDispatcher` 가 헤드리스 엔진에서 부른다 — 시간대가
/// 바뀌었을 때와 하루 한 번 작업(`DailyAlarmSyncWorker`). 공휴일 캐시를 갱신하고(하루 한 번, 엔진에
/// 붙은 `walk/holidays`), 예약을 지금 시간대의 벽시계로 다시 채우고 `done` 을 보낸다(성공 · 실패 모두).
@pragma('vm:entry-point')
Future<void> alarmResyncMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await runBackgroundTask(
    init: _initHeadless,
    task: resyncTask(
      refreshHolidays: () => getIt<HolidayRefresher>().refresh(),
      sync: () => getIt<AlarmUseCase>().sync(),
    ),
    done: (ok) => backgroundChannel.invokeMethod<void>('done', ok),
  );
}

/// 앱이 떠 있지 않을 때 미리 알림의 [이번만 끄기] · [다음 알람 건너뛰기] 를 누르면 네이티브
/// `ReminderActionReceiver` 가 헤드리스 엔진에서 부른다. [args] 는 `["skip", "<packageId>"]`
/// (엔진이 커스텀 진입점에도 `List<String>` 인자를 넘긴다 — `DartExecutor.executeDartEntrypoint`).
/// 공휴일 캐시를 갱신하고(권한이 회수됐으면 내장 표로 — 미리 알림 계산이 앱과 같은 출처를 보게) 그 회차를
/// 건너뛰고 `done`(성공 여부)을 보낸다. 실패면 네이티브가 알림을 남긴다.
@pragma('vm:entry-point')
Future<void> alarmReminderActionMain(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await runBackgroundTask(
    init: _initHeadless,
    task: resyncTask(
      refreshHolidays: () => getIt<HolidayRefresher>().refresh(),
      sync: () =>
          getIt<AlarmUseCase>().skipOccurrence(reminderActionPackageId(args)),
    ),
    done: (ok) => backgroundChannel.invokeMethod<void>('done', ok),
  );
}
