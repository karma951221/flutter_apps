# walk — 알람 고도화 웨이브 3 설계 (울림 세부 · 건너뛰기 · 미리 알림 · 공휴일)

> 작성 2026-10-05 · 상태: **설계 승인** · 앱 문서 [walk 허브](../../../apps/walk/docs/README.md) ·
> 백로그 [알람 고도화](2026-10-05-walk-alarm-upgrade-backlog-design.md) · 선행 [웨이브 1](2026-10-05-walk-alarm-wave1-design.md) ·
> [알람음 · 포크(웨이브 0)](2026-10-05-walk-alarm-sound-design.md)

웨이브 0 · 1 이 끝난 코드 위에서 시작한다(포크 `third_party/alarm`, 설정 지문, 공용 실행기 `AlarmResync`).

## 1. 범위

| ID | 항목 |
|---|---|
| A2 | 알람별 볼륨 · 점점 커지기 |
| A3 | 알람별 스누즈 간격 · 최대 횟수 |
| A4 | 알람별 자동 멈춤 |
| B1 | 반복 알람 다음 1회 건너뛰기 |
| C2 | 울리기 30분 전 미리 알림 + [이번만 끄기] |
| B5 | 공휴일에 울릴 반복 알람을 24시간 전에 알리고 [다음 알람 건너뛰기] · [울리기] |

## 2. 결정 기록

| 결정 | 이유 |
|---|---|
| 새 설정은 모두 알람별이고 편집 화면 아래 접힌 "울림 설정" 영역에 둔다. 접힌 상태는 한 줄 요약("볼륨 80% · 스누즈 5분 · 자동 멈춤 없음") | 웨이브 1 의 단순한 편집 화면을 지킨다 |
| A2 볼륨 10~100%(10 단위, 기본 80 = 지금 값). 점점 커지기 [끔 · 30초 · 60초], 기본 끔. 끔이면 `VolumeSettings.fixed`, 아니면 `fade` | 패키지 기능 그대로. 0% 는 무음이 되므로 막는다 |
| A3 스누즈 간격 [5 · 10 · 15분] 중 기본 5, 횟수 [무제한 · 3회] 중 기본 무제한. 횟수를 다 쓰면 다음 울림에는 울림 화면 · 알림 모두 스누즈 버튼이 없다 | 백로그 |
| A3 횟수는 포크가 센다: `AlarmSettings.snoozeCount`(기본 0) · `androidSnoozeLimit`(Int?). 알림 스누즈(`SnoozeCoordinator`)와 앱 스누즈(`AlarmUseCase.snooze`) 모두 "다음 설정 = count+1, count+1 ≥ limit 이면 스누즈 끔" 규칙을 같은 방식으로 적용한다. 포크 Dart `_applyMove` 도 같은 규칙으로 Dart 저장소를 맞춘다 | 앱이 꺼져 있어도 알림 스누즈가 정확히 세진다. Dart 저장소가 낡으면 `Alarm.init` 이 옛 count 로 다시 걸어 버린다(스파이크 A3) |
| `_sync` 의 스누즈 회차 보존 창은 알람별 `snoozeMinutes` 를 쓴다 | 고정 5분이면 10 · 15분 스누즈 회차를 지운다 |
| A4 자동 멈춤 [안 함 · 5 · 10 · 15분] 중 기본 안 함. 포크 `AlarmService` 가 울림 시작 때 `Handler.postDelayed` 로 그 id 의 멈춤(`handleStopAlarmCommand`)을 건다. 끄기 · 스누즈 · 서비스 종료 때 취소 | 앱 프로세스가 없어도 울림 서비스와 같은 프로세스라 확실하다. 멈춤 뒤 처리는 수동 끄기와 같다(1회성은 꺼진다) |
| B1 `Alarm.skippedAt`(DateTime?, 건너뛴 회차의 정확한 시각). `upcomingTriggers` 가 그 시각을 뺀다. 지난 값은 다음 save/sync 때 지운다 | 반복 알람의 "다음 1회"만 쉰다. 공휴일 건너뛰기(B5)도 같은 필드를 쓴다 |
| B1 진입: 반복 알람 행 길게 누르기 → 시트 [다음 알람 건너뛰기 · 10월 9일 (금) 오전 7:00] 또는 [건너뛰기 취소]. 건너뛴 행에 "건너뜀" 칩 | 행 탭은 편집, 스위치는 켜기/끄기라 빈 동작이 길게 누르기뿐 |
| 미리 알림(C2 · B5)은 네이티브 Kotlin 이 건다(AlarmManager `setExactAndAllowWhileIdle` + 자체 저장소 + 수신기). 무엇을 언제 띄울지는 Dart `_sync` 가 14일 회차에서 계산해 채널 `walk/reminders` 로 넘긴다. flutter_local_notifications 는 쓰지 않는다 | 스파이크 C2/B5: FLN 은 액션마다 엔진을 하나 더 띄우고 내리지 않아 alarm 플러그인 정적 필드를 가져간다 |
| 액션 [이번만 끄기] · [다음 알람 건너뛰기] 는 수신기(goAsync)가 공용 실행기로 Dart `skipOccurrence(packageId)` 를 부른다(메인 엔진 우선, 없으면 헤드리스 `alarmReminderActionMain`). [울리기] 는 Dart 없이 알림만 닫는다. 실패 · 타임아웃이면 알림을 남겨 다시 누를 수 있게 한다 | 앱이 꺼져 있어도 처리된다 |
| `skipOccurrence`: 반복이면 `skippedAt = 그 회차`, 1회성이면 끈다. 그 회차의 패키지 예약을 명시적으로 지운 뒤 sync | 스누즈 보존 창 때문에 30분 안 회차가 남을 수 있다 |
| C2 는 알람별 스위치 "30분 전에 알려 주기"(기본 끔). 울릴 시각이 지금부터 30분보다 가까우면 만들지 않는다. 알림: "곧 알람이 울려요 · 오전 7:00 출근" + [이번만 끄기] | 모든 알람에 켜면 알림이 많다. 500 개 AlarmManager 한도도 고려 |
| B5 는 앱 전역 설정 "공휴일 미리 알림"(설정 탭 알람 섹션, 기본 켬). 반복 알람의 회차가 공휴일이면 24시간 전에 알림: "10월 9일(한글날) 오전 7:00 알람이 공휴일에 울려요" + [다음 알람 건너뛰기] · [울리기] | 사용자 결정(자동 건너뛰기 대신 묻기) |
| 공휴일 표는 `domain/alarm/holiday/korean_holidays.dart` 상수(2026 · 2027, 대체공휴일 포함, 이름 한국어). 출처(관보 · 우주항공청 월력요항)를 파일 머리 주석에 적는다. 임시공휴일은 앱 업데이트로만 | 사용자 결정(앱 내장). 백엔드 · API 키 없음 |
| **공휴일 출처는 폰 캘린더가 먼저, 없으면 내장 표**(2026-10-06 사용자 결정). 안드로이드 캘린더 제공자(`CalendarContract`)의 모든 캘린더 중 휴일 캘린더를 찾아 일정을 읽는다. 특정 캘린더 앱을 가정하지 않는다: 구글 휴일 캘린더(`OWNER_ACCOUNT` 가 `#holiday@group.v.calendar.google.com` 로 끝남, 한국은 `ko.south_korea#holiday@…`) · 이름에 "휴일" · "공휴일" · "holiday" 가 든 캘린더(삼성 등 다른 앱 포함) 순으로 고른다 | 공휴일은 해마다 바뀌고 임시공휴일은 몇 주 전에 지정된다. 폰 캘린더는 캘린더 앱 제공자가 갱신하므로 인터넷 권한 · API 키 없이 따라간다(Health Connect 와 같은 "폰 데이터 읽기" 방식) |
| 쉬는 날 판정(스파이크 2026-10-06 확인): 휴일 캘린더는 `ACCOUNT_TYPE == "com.google"` 이고 `OWNER_ACCOUNT`(또는 `CAL_SYNC1` · `_SYNC_ID`)가 `^[a-z_-]+\.south_korea(\.official)?#holiday@group\.v\.calendar\.google\.com$` 인 것. `Instances` 의 종일 일정 중 설명 첫 줄이 `공휴일`/`Public holiday` 면 쉬는 날, `기념일`/`Observance` 면 아님, 그 밖의 문구는 `.official` 캘린더일 때만 쉬는 날. 대체공휴일 · 선거일도 `공휴일` 로 들어온다. 표시 이름으로 찾기는 실기기 확인 뒤 보조 규칙으로만 | 구글 "대한민국의 휴일" 피드는 공휴일 205 · 기념일 75(어버이날 등)를 섞어 둔다. 삼성 캘린더 내장 공휴일은 다른 앱이 읽을 수 있는지 확인되지 않았다(앱 내부 데이터일 가능성). 구글 캘린더의 "데이터를 다른 앱과 공유" 토글이 꺼져 있으면 안 보인다 → 내장 표 |
| `READ_CALENDAR` 런타임 권한은 "공휴일 미리 알림"을 처음 켤 때(기본 켬이므로 알람 탭 첫 진입 뒤 알람 저장 때) 묻는다. 거부 · 휴일 캘린더 없음 · 읽기 실패면 내장 표. 설정 탭 공휴일 행에 지금 출처("폰 캘린더: 대한민국의 휴일" / "내장 표 2026–2027")와 권한 상태를 보인다 | 사용자가 갤럭시 폰에서 무엇이 잡히는지 바로 확인할 수 있다 |
| 캘린더 읽기는 sync 마다 하지 않고, 앞으로 400일 범위를 읽어 하루 한 번(앱 시작 · 하루 sync) 캐시(`walk.holidays.cache`, 읽은 시각 · 출처 포함)한다. 캐시가 없으면 내장 표 | 백그라운드 헤드리스 sync 에서도 빠르다 |
| 영어 · 일본어 알림은 공휴일 이름 없이 날짜만 쓴다 | 이름 번역표를 두지 않는다 |
| 재부팅 · 업데이트: 자체 `ReminderBootReceiver`(BOOT_COMPLETED · MY_PACKAGE_REPLACED)가 저장소에서 다시 건다. 꺼져 있던 동안 띄울 시각이 지났지만 울릴 시각이 1분보다 많이 남았으면 바로 띄운다 | 패키지 알람과 같은 수준의 복원 |
| 알림 채널 `walk_alarm_reminder`(중요도 DEFAULT), 작은 아이콘 `ic_stat_alarm`(웨이브 2) | 헤드업까지는 필요 없다 |
| 디버그 확인용으로 미리 알림 리드 시간을 `--dart-define=WALK_REMINDER_LEAD_MINUTES` · `WALK_HOLIDAY_LEAD_MINUTES` 로 줄일 수 있다(릴리스 기본값 30 · 1440) | 에뮬레이터에서 24시간을 기다릴 수 없다 |

## 3. 도메인

### 3.1 `Alarm` 추가 필드 (JSON 키가 없으면 기본값)

| 필드 | 타입 · 기본 | JSON |
|---|---|---|
| `volumePercent` | int 80 (10..100) | `volumePercent` |
| `fadeSeconds` | int 0 (0 · 30 · 60) | `fadeSeconds` |
| `snoozeMinutes` | int 5 (5 · 10 · 15) | `snoozeMinutes` |
| `snoozeLimit` | int? null (null · 3) | `snoozeLimit` |
| `autoStopMinutes` | int? null (null · 5 · 10 · 15) | `autoStopMinutes` |
| `remindBefore` | bool false | `remindBefore` |
| `skippedAt` | DateTime? null | `skippedAt`(ISO, 로컬) |

범위를 벗어난 값은 기본값으로 읽는다. 선택지 상수는 `domain/alarm/entity/alarm_options.dart`.

### 3.2 회차 · 건너뛰기

- `upcomingTriggers` 가 `skippedAt` 과 같은 시각(`isAtSameMomentAs`)을 뺀다.
- `AlarmUseCase` 추가: `skipNext(int alarmId)`(다음 회차를 `skippedAt` 으로) · `unskip(int alarmId)` · `skipOccurrence(int packageId)`(§2).
  `_sync` 시작에서 `skippedAt` 이 지났으면 지워 저장한다.
- 스누즈: `snooze(packageId)` 가 `alarm.snoozeMinutes` 와 현재 `snoozeCount`(스케줄러에서 읽음)로 다시 건다.
  `canSnooze(packageId)`: 울림 화면 버튼 표시용.
- `_sync` 의 보존 창: `at <= now + Duration(minutes: alarm.snoozeMinutes)`.

### 3.3 미리 알림

```dart
enum ReminderKind { soon, holiday }

@freezed
class AlarmReminder with _$AlarmReminder {
  final int id;          // reminderId(packageId, kind) = 1_000_000 + packageId * 2 + kind.index
  final int packageId;
  final int alarmId;
  final ReminderKind kind;
  final DateTime at;     // 띄울 시각
  final DateTime ringAt; // 울릴 시각
  final String? holidayName;
  ...
}

// domain/alarm/reminders.dart
List<AlarmReminder> remindersOf(Alarm alarm, List<AlarmTrigger> triggers, DateTime now,
    {required HolidayCalendar holidays, required bool holidayReminder,
     Duration soonLead = alarmSoonLead, Duration holidayLead = alarmHolidayLead});

// domain/alarm/holiday/holiday_calendar.dart
abstract interface class HolidayCalendar { String? nameOf(DateTime date); }
// KoreanHolidayCalendar implements HolidayCalendar — 내장 표

// domain/alarm/scheduler/reminder_scheduler.dart
abstract interface class ReminderScheduler {
  Future<Map<int, DateTime>> scheduled();          // 걸렸거나 떠 있는(ringAt 전) 것: id → at
  Future<void> schedule(AlarmReminder reminder, Alarm alarm);
  Future<void> cancel(int reminderId);             // 예약과 떠 있는 알림 모두
}
```

규칙: soon 은 `remindBefore` 이고 `ringAt - soonLead > now` 일 때. holiday 는 반복 알람 · `holidayReminder` 켬 ·
`holidays.nameOf(ringAt) != null` · `ringAt > now` 일 때(`at` 이 이미 지났으면 다음 sync 에서 바로 띄우도록 `at = now`).
`DefaultAlarmUseCase` 생성자에 `ReminderScheduler` · `HolidayCalendar` · `SettingsRepository`(공휴일 설정 읽기)를 더하고,
`_sync` 끝에 `_syncReminders` 를 둔다(예외는 삼켜 알람 예약을 막지 않는다).

### 3.4 설정

`AppSettings.holidayReminder`(bool, 기본 true) — 설정 탭 "알람" 섹션 스위치. 바꾸면 sync.

## 4. 데이터

- `PackageAlarmScheduler.settingsFor`: `volumeSettings` 는 §2, `androidSnoozeDuration: snoozeMinutes`,
  `androidSnoozeLimit`, `snoozeCount`(인자), `androidAutoStopAfter`(autoStopMinutes), 스누즈 버튼은
  `count < limit` 일 때만. 지문에 볼륨 · 페이드 · 스누즈 · 자동 멈춤을 넣는다(`snoozeCount` 는 넣지 않는다).
- `AlarmScheduler` 추가: `Future<int> snoozeCountOf(int packageId)`, `schedule(..., {int snoozeCount = 0})`.
- `ChannelReminderScheduler`(`@LazySingleton(as: ReminderScheduler)`, 채널 `walk/reminders`): `scheduled` · `schedule` · `cancel`.
  문구는 `PackageAlarmScheduler._texts()` 처럼 기기 로캘로 Dart 가 만들어 넘긴다. 시각은 epoch millis.
  `MissingPluginException` 은 빈 맵 · 무시.
- 포크(`third_party/alarm`): pigeon `AlarmSettingsWire` 에 `androidAutoStopAfterMillis`(int?) · `androidSnoozeLimit`(int?) ·
  `snoozeCount`(int, 기본 0). Dart 모델 · json · `toWire` · `copyWith` · props, Kotlin `AlarmSettings`(기본값 있는 필드, `fromWire` · 레거시 json),
  `AlarmService`(자동 멈춤 Handler, 서비스 종료 시 취소), `SnoozeCoordinator`(count+1 · 한도면 스누즈 끔),
  Dart `_applyMove`(같은 규칙). Kotlin 단위 테스트로 규칙 함수(`nextAfterSnooze(settings, now)`)를 확인. `FORK.md` 갱신.

### 4.1 Kotlin (앱)

스파이크 C2/B5 §3.5 그대로:
`BackgroundDispatcher`(웨이브 1 `AlarmResync` 를 일반화: method · arguments · entrypoint · entrypointArgs · `onEnd(ok)`, 헤드리스 엔진에
`walk/reminders` 채널도 attach) · `ReminderStore`(SharedPreferences `walk_reminders`, org.json) · `ReminderAlarms` ·
`ReminderChannel` · `ReminderFireReceiver` · `ReminderActionReceiver` · `ReminderBootReceiver` + 매니페스트 수신기 3개.
setAlarmClock 은 쓰지 않는다(상태바 다음 알람 표시를 가져가지 않게).

### 4.2 Dart 진입점 · 셸

- `core/background/background_task.dart`: `runBackgroundTask({init, task, done(bool ok)})` 로 `runAlarmResync` 를 일반화.
- `main.dart`: `@pragma('vm:entry-point') alarmReminderActionMain(List<String> args)` — `Alarm.init()` → DI → `skipOccurrence`.
  커스텀 진입점이 인자를 못 받으면 시작 직후 채널로 인자를 받아 온다(구현 첫 확인 항목).
- `MainShellPage._onBackgroundCall`: `'reminderAction'` → `skipOccurrence` → 목록 reload → `true`.

## 5. 화면

- 편집: "울림 설정" 접이식 영역(`ExpansionTile` 테마 정리 또는 앱 위젯) — 볼륨 슬라이더 · 점점 커지기 세그먼트 ·
  스누즈 간격 세그먼트 · 스누즈 횟수 세그먼트 · 자동 멈춤 세그먼트 · "30분 전에 알려 주기" 스위치.
- 목록: 길게 누르기 시트(B1), "건너뜀" 칩, 다음 회차가 24시간 안 공휴일이면 "공휴일" 칩(누르면 건너뛰기 시트).
- 울림 화면: `canSnooze` 가 false 면 스누즈 버튼을 숨기고 끄기 버튼이 전체 폭. 스누즈 버튼 문구는 "{n}분 뒤 다시 울림".
- 설정: "알람" 섹션 + "공휴일 미리 알림" 스위치.

## 6. l10n

`walkAlarmRingSettings`(울림 설정) · 요약 · `walkAlarmVolume` · `walkAlarmFade`(점점 커지기) · `walkAlarmFadeOff` ·
`walkAlarmSeconds`({seconds}초) · `walkAlarmSnoozeInterval` · `walkAlarmSnoozeLimit` · `walkAlarmSnoozeUnlimited` · `walkAlarmTimes`({count}회) ·
`walkAlarmAutoStop` · `walkAlarmAutoStopNever` · `walkAlarmMinutes`({minutes}분) · `walkAlarmRemindBefore`(30분 전에 알려 주기) ·
`walkAlarmSkipNext`(다음 알람 건너뛰기) · `walkAlarmUnskip`(건너뛰기 취소) · `walkAlarmSkipped`(건너뜀) · `walkAlarmHolidayChip`(공휴일) ·
`walkAlarmSnooze` 를 `{minutes}분 뒤 다시 울림` 자리표시자로 · 미리 알림 제목 · 본문 · 액션(`walkReminderSoonTitle` · `walkReminderSoonBody` ·
`walkReminderTurnOffOnce` · `walkReminderHolidayTitle` · `walkReminderHolidayBody`({date}, {name}, {time}) · `walkReminderHolidayBodyNoName` ·
`walkReminderSkip` · `walkReminderRing`) · `walkSettingsAlarm` · `walkSettingsHolidayReminder` · 설명. ko · en · ja.

## 7. 테스트

| 대상 | 내용 |
|---|---|
| `alarm_test.dart` | 새 필드 왕복 · 없으면 기본 · 범위 밖이면 기본 |
| `upcoming_triggers_test.dart` | `skippedAt` 회차 제외 · 다른 회차 유지 |
| `korean_holidays_test.dart` | 2026 · 2027 주요 날짜 · 대체공휴일 · 평일 null |
| `holiday_calendar_test.dart`(합성) | 캐시 있음 → 캐시, 없음/오래됨 → 내장 표, 둘의 출처 표시 |
| `device_holiday_source_test.dart` | 채널 응답 → 날짜 · 이름 매핑, 권한 없음/채널 없음 → null(내장 표로) |
| Kotlin(JUnit) | 휴일 캘린더 고르기 규칙(구글 id · 이름) · 쉬는 날 판정 규칙 |
| `reminders_test.dart` | soon/holiday 규칙 · 리드 경계 · 1회성 holiday 없음 · 설정 끔 · id 범위(packageId · 973422 와 안 겹침) |
| `alarm_use_case_test.dart` | 스누즈 간격별 보존 창 · snoozeCount 전달 · canSnooze · skipNext/unskip/skipOccurrence(반복 · 1회성 · 30분 안 회차 취소) · 지난 skippedAt 정리 · 미리 알림 diff(추가 · 취소 · 시각 변경 · 예외 삼킴 · 떠 있는 것 유지) |
| `package_alarm_scheduler_test.dart` | 볼륨 · 페이드 · 스누즈 · 한도 · 자동 멈춤 매핑 · 지문 반영 |
| `channel_reminder_scheduler_test.dart` | 인자 · 응답 매핑 · MissingPlugin |
| `background_task_test.dart` | 순서 · 실패 시 done(false) |
| cubit · 페이지 테스트 | 울림 설정 영역 · 건너뛰기 시트 · 칩 · 울림 화면 스누즈 숨김 · 설정 스위치 · 셸 `reminderAction` |
| 포크 Kotlin | `nextAfterSnooze` 규칙 · 자동 멈춤 시간 계산 |
| 실제 갤럭시 폰 | calendars 덤프로 휴일 캘린더 행 값 · 삼성 내장 공휴일이 provider 에 있는지 · 공유 토글 끈 경우(설정 탭 출처 표시로 확인) |
| 에뮬레이터 | 스파이크 R1~R8 + 자동 멈춤(앱 종료 상태) + 알림 스누즈 3회 후 버튼 사라짐 |

## 8. 문서

완료 시 [walk plan](../../../apps/walk/docs/plan.md) · [status](../../../apps/walk/docs/status.md) · `history.md` · `testing.md` 갱신.
