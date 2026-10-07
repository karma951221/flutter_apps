# walk — 알람 고도화 웨이브 4 설계 (복제 · 쉬는 기간 · 울림 기록 · 홈 화면 위젯)

> 작성 2026-10-07 · 상태: **설계(기본안으로 진행, 결과 보고 수정)** · 앱 문서 [walk 허브](../../../apps/walk/docs/README.md) ·
> 백로그 [알람 고도화](2026-10-05-walk-alarm-upgrade-backlog-design.md) 웨이브 4 · 선행 [웨이브 3](2026-10-05-walk-alarm-wave3-design.md)

웨이브 0~3 이 끝난 코드 위에서 시작한다. 사용자가 "바로 다음 단계"를 요청해 세부는 기본안으로 정하고
완성본을 보며 고친다.

## 1. 범위

| ID | 항목 |
|---|---|
| B3 | 알람 복제 |
| B4 | 쉬는 기간(휴가 모드) |
| C4 | 울림 기록 |
| C5 | 홈 화면 위젯(다음 알람) |

## 2. 결정 기록

| 결정 | 이유 |
|---|---|
| B3 복제는 알람 행 길게 누르기 시트(웨이브 3 의 건너뛰기 시트를 모든 알람용 "알람 메뉴"로 넓힌다)의 [복제] 와 편집 화면 앱바 메뉴의 [복제]. 누르면 같은 설정의 **저장 전 알람**으로 편집 화면을 연다(제목 그대로, `skippedAt` · 1회성의 지난 `oneShotAt` 은 비움). 저장해야 생긴다 | 바로 목록에 생기면 같은 시각 알람이 두 번 울린다. 열어서 바꾸게 한다 |
| B4 쉬는 기간은 앱 전역 하나: `AppSettings.pause = (from: 날짜, until: 날짜)?`(포함 범위, 날짜 단위). 그 기간의 회차는 **모든 알람**에서 빠진다(1회성 포함). 기간이 지나면 저절로 풀린다(지난 기간은 sync 가 지움) | 휴가 때 알람을 하나씩 끄고 다시 켜는 수고를 없앤다. 스위치 상태는 건드리지 않는다 |
| B4 진입: 알람 탭 앱바의 [쉬기] 아이콘 → 시트(시작 · 끝 날짜, 빠른 버튼 [오늘만] · [내일까지] · [이번 주말], 날짜 고르기는 `showDateRangePicker`). 쉬는 중이면 다음 알람 카드 위에 "10월 12일까지 알람을 쉬어요 · 그만 쉬기" 배너 | 목록 화면에서 상태가 보여야 한다 |
| B4 는 `upcomingTriggers` 가 기간 안 날짜의 회차를 빼는 방식. 미리 알림 · 공휴일 알림도 회차에서 나오므로 함께 빠진다 | 기존 sync 구조를 그대로 쓴다 |
| C4 울림 기록은 **포크 네이티브가 쓴다**: `AlarmService` 가 울림 시작 · 끄기(사용자/알림/자동 멈춤) · 스누즈에서 이벤트를 앱 전용 저장소(SharedPreferences `walk_ring_log`, JSON 줄, 최근 200개)에 덧붙인다. 앱은 채널 `walk/ring_log` 로 읽는다. 건너뛰기(앱 · 헤드리스)는 Dart 가 같은 채널로 덧붙인다 | 앱이 꺼진 채 울리고 알림으로 끈 경우까지 남는다. Dart 만으로는 엔진이 없을 때를 놓친다 |
| C4 이벤트: `{at, packageId, alarmId, kind: rang|stopped|autoStopped|snoozed|skipped}`. 화면은 회차(packageId + 날짜)별로 묶어 "오전 7:00 출근 — 7:00 울림 · 스누즈 2번 · 7:12 끔" 한 줄. 날짜별 머리. 최근 30일 | 사용자가 보고 싶은 것은 "언제 일어났나" |
| C4 진입: 알람 탭 앱바 [기록] 아이콘 → `AlarmHistoryPage`. 비면 `AppPlaceholder` | |
| C5 홈 화면 위젯: 네이티브 `AppWidgetProvider` + `RemoteViews`(2×1 기본, 가로 늘림 가능). 내용 "다음 알람" · "내일 (목) 오전 7:00" · 제목. 알람이 없으면 "예정된 알람 없음". 누르면 앱 알람 탭을 연다. 초록 배경(아이콘 색) · 라이트/다크 | 남은 시간 카운트다운은 매분 갱신이 필요해 넣지 않는다(절대 시각만) |
| C5 갱신: Dart `_sync` 끝(메인 · 헤드리스 모두)에서 채널 `walk/widget` 의 `update({atMillis, title})` 를 부르면 Kotlin 이 SharedPreferences 에 쓰고 `AppWidgetManager.updateAppWidget`. 날짜 문구(오늘/내일)는 위젯이 그릴 때 기기 시각으로 계산하고, 자정에 바뀌게 `ACTION_DATE_CHANGED` · `TIME_SET` · `TIMEZONE_CHANGED` 를 받는다 | home_widget 패키지 없이. 하루 sync 와 앱 사용으로 충분히 자주 갱신된다 |
| 새 pub 의존성 없음 | |

## 3. 도메인 · 데이터

- `Alarm.duplicate()` → `id: unsavedId`, `skippedAt: null`, 1회성이면 `oneShotAt: null`.
- `AlarmPause {DateTime from; DateTime until}`(날짜만) — `contains(DateTime at)`. `AppSettings.pause`(JSON `pauseFrom` · `pauseUntil`, 없으면 null).
- `upcomingTriggers(alarm, now, {AlarmPause? pause})`, `triggersOf` 도. `AlarmUseCase` 가 설정에서 pause 를 읽어 넘긴다. `setPause(AlarmPause?)` 는 저장 뒤 sync.
- `RingLogEntry`(Freezed) · `RingLogSource`(domain 인터페이스: `Future<List<RingLogEntry>> read({required DateTime since})`, `Future<void> append(RingLogEntry)`) · `ChannelRingLogSource`.
- `ringLogGroups(List<RingLogEntry>, List<Alarm>)` 순수 함수 → 회차별 요약.
- `NextAlarmWidget` 인터페이스(`Future<void> show(DateTime? at, String title)`) · `ChannelNextAlarmWidget`. `_sync` 끝에서 실제 예약 중 가장 이른 것으로 부른다(예외는 삼킨다).

## 4. 포크 · 네이티브

- 포크 `AlarmService`: `RingLog.append(context, event)` 호출 지점 — `ringAlarm`(rang), `handleStopAlarmCommand`(stopped / 자동 멈춤 Handler 에서 autoStopped), `SnoozeCoordinator`(snoozed). 기록 형식 함수는 순수 Kotlin(JUnit). 저장소 이름은 앱과 약속한 상수.
- 앱 Kotlin: `RingLogChannel.kt`(read · append), `NextAlarmWidgetProvider.kt` + `res/layout/widget_next_alarm.xml` + `res/xml/next_alarm_widget_info.xml` + 매니페스트 receiver, `WidgetChannel.kt`. 메인 · 헤드리스 엔진 모두 채널 attach.

## 5. 화면 · l10n

- 알람 메뉴 시트: [복제] · (반복이면) [다음 알람 건너뛰기]/[건너뛰기 취소] · [삭제] — 확인 다이얼로그를 거친다.
- 알람 탭 앱바: [쉬기] · [기록] 아이콘(툴팁). 쉬기 시트 · 쉬는 중 배너. 기록 화면.
- l10n(ko · en · ja, `walkAlarm*`): 복제 · 쉬기 시트 문구 · 배너 · 기록 화면 · 이벤트 문구 · 위젯 문구(위젯은 Kotlin 리소스 `values/strings.xml` · `values-en` · `values-ja`).

## 6. 테스트

| 대상 | 내용 |
|---|---|
| `alarm_test` | duplicate 규칙 |
| `alarm_pause_test` · `app_settings` | contains 경계 · JSON 왕복 · 없으면 null |
| `upcoming_triggers_test` | 쉬는 기간 회차 제외(경계 포함) · 1회성도 제외 |
| `alarm_use_case_test` | setPause 뒤 sync 가 기간 회차 · 미리 알림 취소 · 지난 기간 정리 · 위젯 갱신 호출 · 위젯 실패 삼킴 |
| `ring_log_test` | 회차 묶기 · 스누즈 횟수 · 자동 멈춤 · 건너뜀 · 지운 알람 |
| 채널 소스 테스트 | ring log · widget 인자/응답 |
| cubit · 페이지 | 메뉴 시트 · 복제 → 편집 · 쉬기 시트 · 배너 · 그만 쉬기 · 기록 화면 · 빈 상태 |
| Kotlin JUnit | 기록 형식 · 위젯 날짜 문구 계산 |
| 에뮬레이터 | 복제 · 쉬기(오늘만) 후 오늘 회차 없음 · 앱 종료 상태 울림 → 알림으로 끄기 → 기록에 남음 · 위젯 추가 · 저장 뒤 위젯 갱신 · 자정 문구 |

## 7. 문서

완료 시 [status](../../../apps/walk/docs/status.md) · `testing.md` · `plan.md`(화면 표 · 범위 밖) 갱신.
