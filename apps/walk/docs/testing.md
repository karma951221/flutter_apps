# walk 테스트

> [테스트 가이드](../../../docs/testing/README.md) · [계획](plan.md) · [기록](history.md) · [진행 현황](status.md)

```bash
cd apps/walk && flutter test   # 도메인 · 데이터 · cubit · 위젯 · 경계 (2026-10-22 기준 1794건 통과 · 1건 skip)
```

백엔드가 없어 로컬 Supabase 없이 돈다. Health Connect 는 `HealthGateway` 를 mock 해서 본다
— `HealthPluginGateway`(플러그인 호출 자체)는 단위 테스트하지 않고 기기에서 확인한다. 알람은
`AlarmScheduler` 를 가짜(`_FakeScheduler`)로, 시간은 `Clock` 을 주입해서 본다 — `alarm` 패키지의 실제
호출(`set` · `getAlarms` 등)과 Kotlin 채널 · 수신기는 에뮬레이터로 확인한다.

`alarm` 은 `third_party/alarm` 포크다([FORK.md](../third_party/alarm/FORK.md)). 포크 자체의 `test/` 는 돌리지
않는다. 포크의 Dart 모델은 앱의 `test/third_party/alarm/…`(포크 경로와 1:1)에서, 포크 Kotlin 의 순수 규칙
(`audioCandidates` · `shouldMuteForRinger` · `EngineRegistry` · `smallIconResId` · 설정 저장)은 포크 JUnit 으로 본다. 앱 Kotlin 의 순수
규칙(`replaceVerified` · `BackgroundQueue` · `ReminderRules` · `HolidayCalendarRules`)은 앱 JUnit 이다. `AudioService.playAudio` 가 실제로 대체음으로 다시 트는지,
무음 · 진동 모드에서 진동만 하는지, 하루 sync 가 헤드리스로 도는지는 에뮬레이터로 본다.

```bash
cd apps/walk/android
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
./gradlew :alarm:testDebugUnitTest   # 포크 — AudioFallbackTest · RingerMuteTest · EngineRegistryTest · SnoozeRuleTest · AutoStopTest · HostAlarmEventTest · RingLogTest · AlarmApiImplTest 등
./gradlew :app:testDebugUnitTest     # 앱 — VerifiedReplaceTest · BackgroundQueueTest · HeadlessIdleGateTest · ReminderRulesTest · HolidayCalendarRulesTest · CalendarPermissionRulesTest · NextAlarmWidgetRulesTest
```

skip 1건은 서머타임 테스트다. 기기 시간대에 3월 서머타임 전환이 없으면(KST) 스스로 건너뛴다 —
`TZ=America/New_York flutter test test/domain/alarm/upcoming_triggers_test.dart` 로 돌린다.

## `apps/walk/test/` — `lib/` 와 1:1

### 걷기

| 파일 | 대상 | 확인 |
|---|---|---|
| `domain/walk/entity/period_range_test.dart` | `periodRange` · `daysBetween` | 주는 월요일 시작 · 일요일에 연 이번 주 · 지난 주가 달을 넘음 · 윤년 2월 · 지난 달이 연도를 넘음 · 양 끝 포함 |
| `domain/walk/entity/activity_period_test.dart` | `ActivityPeriod` | 합계 · 일평균은 오늘까지 지난 날로 나눔 · 거리/칼로리는 값 있는 날만, 없으면 null · `isCurrent` · 지난 기간은 전체 일수 |
| `domain/walk/usecase/walk_use_case_test.dart` | `DefaultWalkUseCase` | 오늘 하루만 읽기 · 이번 주는 오늘까지 읽고 나머지 0보 · 지난 달 전체 · 실패 전파 |
| `data/walk/health/health_permission_source_test.dart` | `HealthPermissionSource` | 걸음 권한 기준 granted/denied(permanentlyDenied 없음) · 세 타입 요청 · 걸음을 거부하면 기록 이력은 묻지 않음 · 설정 열기 |
| `data/walk/repository/health_connect_activity_repository_test.dart` | `HealthConnectActivityRepository` | SDK 없음/모름/업데이트 필요 매핑 · 걸음 권한만으로 granted · **이번 세션에 한 번만 묻기** · 거부 후 다시 요청 · **동시 확인은 요청 한 번** · 모든 날 채우기 · 권한 없는 타입은 묻지 않음 · 예외 → `Err` |
| `presentation/walk/format/walk_format_test.dart` | `WalkFormat` | `6,240` · `4.3 km` · `183 kcal` · 없으면 `–` · 주/월/요일/일 라벨 |
| `presentation/walk/cubit/health_access_cubit_test.dart` | `HealthAccessCubit` | 확인 중(null) · 확인 결과와 `canOpenSettings` · 요청 · 설치/설정은 화면만 연다 |
| `presentation/walk/cubit/today_activity_cubit_test.dart` | `TodayActivityCubit` | loading → loaded · failure · 새로고침은 로딩 없이 |
| `presentation/walk/cubit/period_activity_cubit_test.dart` | `PeriodActivityCubit` | 현재 기간 · 이전 · 현재에서 다음 불가 · 새로고침은 같은 offset · 늦은 응답 버림 · 실패해도 offset 유지 |
| `presentation/walk/widget/activity_bar_chart_test.dart` | `ActivityBarChart` | 요일 7개 · 최댓값 막대가 가장 높음 · 미래 날은 막대 없음 · 탭하면 그날 걸음 · **새로고침 뒤 선택 값 갱신** · 목표선 · 높이 기준 `max(최댓값, 목표)` · 달성일/미달일 색 · 오늘 테두리(**달성하면 `onPrimaryContainer`**) · 선택 줄의 목표 % · 막대 성장 · **마지막 막대와 라벨 겹침 없음(주간 · 월간) · 목표 높이의 마지막 막대 선택** |
| `presentation/walk/page/walk_home_page_test.dart` | `WalkHomePage` | 오늘 걸음 · km · `–` · 현재 기간 다음 버튼 꺼짐 · 월간 탭 · 권한 요청 · 설정 열기 유무 · 설치 안내 · 오늘 실패 재시도 · **복귀 시 재확인 · 새로고침** · **복귀 중 허용되면 한 번만 읽기** · 값 읽는 동안 스켈레톤(오늘 · 기간, 높이 비슷) · 주간/월간 세그먼트 · **축하 날짜 1회**(처음 달성하면 저장 · 같은 날 재진입 무연출 · 미달이면 저장 안 함 · 목표 변경 · 실패 뒤 재시도 · 날이 바뀐 뒤 · 어제 값에서 오늘 값) · **숨은 탭이면 판정 · 저장 안 함, 보이게 되면 한 번**(달성 값 · 목표 낮춤) |
| `domain/walk/entity/goal_progress_test.dart` | `GoalProgress` | 범위 밖 목표는 끝값 · 1,000 단위 반올림 · 0보 · 정확히 목표면 달성 · 초과 비율 · 남은 거리(오늘 보폭) · 축하 여부(기록 없음 / 어제 / 오늘 이미) |
| `presentation/walk/cubit/step_goal_cubit_test.dart` | `StepGoalCubit` | 처음 값은 저장된 목표 · `select` 는 1,000 단위로 맞춰 반영 · 저장 · 다른 필드 유지 · 같은 값이면 무시 · **실제 SharedPreferences 에서 목표 변경 직후 축하일 저장해도 새 목표 유지** |
| `presentation/walk/widget/step_goal_ring_test.dart` | `StepGoalRing` | 진입 시 0 → 비율, 바뀌면 직전 → 새 값 · 넘침은 1 에서 멈춤 · 애니메이션 끄기면 끝 값 · 트랙 · 진행 색 |
| `presentation/walk/widget/today_goal_card_test.dart` | `TodayGoalCard` | 걸음 · 목표 문구 · 링 접근성 비율 · 거리/칼로리 지표 · 링 탭 → 남은 걸음 · 다시 탭 → 지표 · **탭해도 카드 높이 그대로** · 거리 없으면 남은 걸음만 · 달성 배지 · 3초 뒤 복귀 |
| `presentation/walk/widget/period_summary_test.dart` | `PeriodSummary` | 달성 n/m일(오늘 이후 제외, 지난 기간은 전부) · 네 지표 타일 |
| `convention/package_boundary_test.dart` | `pubspec.yaml` | `feature_*` · `supabase_flutter` 의존 없음 · `alarm` 은 `third_party/alarm` path 의존(FORK.md · LICENSE 있음) · 포크는 루트 workspace 멤버 아님 · walk 는 일기 위치에 workspace `location` 을 의존 |
| `convention/android_icon_resources_test.dart` | `android/app/src/main/res` 알림 아이콘 | **`PackageAlarmScheduler.notificationIcon` 이름의 `drawable/<이름>.xml` 이 있고 `raw/keep.xml` 의 `tools:keep` 이 `@drawable/<이름>` 을 남긴다**(포크는 못 찾으면 조용히 대체 아이콘으로 넘어간다) |
| `convention/android_splash_resources_test.dart` | `android/app/src/main/res` 시작 화면 리소스 | 배경 색 라이트 #1D9E75 · 다크 #0F6E56 · **`splash_icon` 은 레이어 리스트가 아닌 288 뷰포트 벡터 하나 · 전경 경로 그대로 · 중심 (54,54)→(144,144) · 안전 원이 지름 192 원 안**(QA: 12+ 스플래시 확대 · 잘림) · `values(-night)-v31` `LaunchTheme` 의 스플래시 배경 · 아이콘(아이콘 배경 없음) · 12 미만 `launch_background`(drawable · v21 · night) 초록 바탕 가운데 아이콘 · `NormalTheme` 은 `?android:colorBackground` 유지 |

걷기 표의 굵은 항목은 최종 리뷰에서 고친 것의 회귀 테스트다([기록](history.md#2026-09-27--최종-리뷰에서-고친-것)).

### 알람 — 도메인 · 데이터

| 파일 | 대상 | 확인 |
|---|---|---|
| `domain/alarm/entity/alarm_test.dart` | `Alarm` · `Weekday` | JSON 왕복(1회성 `oneShotAt` 은 로컬 시각 그대로) · `fromJson` 기본값 · 깨진 값은 던짐(저장소가 건너뜀) · `draft` · `sound`(기본 시스템 · 3종 왕복) · `silentWhenRingerMuted`(옛 `vibrate` 키는 읽고 버림) · **울림 세부 · 건너뛰기**(기본 볼륨 80 · 점점 커지기 끔 · 스누즈 5분 무제한 · 자동 멈춤 없음 · 미리 알림 끔 · 건너뛰기 없음 · 기본값은 선택지 안 · 새 필드 왕복(`skippedAt` 은 로컬 ISO) · null 왕복 · 키 없는 옛 알람은 기본값 · 선택지 밖/타입 다름은 기본값 · 볼륨 10 단위) · **복제**(`duplicate(now)` — id · `skippedAt` 비움 · 1회성의 지난 `oneShotAt` 은 비우고 **아직 오지 않은 것은 그대로**) |
| `domain/alarm/entity/alarm_sound_test.dart` | `AlarmSound` · `BundledAlarmSounds` | 시스템 · 내장 · 기기 JSON 왕복 · 값 없음/모르는 type/맵 아님/필드 빠짐 → 시스템(던지지 않음) · 비프는 `default.wav` 이름 그대로 · 내장음은 22.05kHz 모노 16bit 3초 WAV |
| `domain/alarm/entity/alarm_trigger_test.dart` | `packageId` · `triggerIndex` | `alarmId * 100 + index` 왕복 · 날짜 index 는 14일 안에서 겹치지 않음 |
| `domain/alarm/entity/repeat_preset_test.dart` | `RepeatPreset` | 매일 · 평일 · 주말의 요일 · 요일 집합이 묶음과 같으면 그 묶음(순서 무관) · 빈 집합 · 일부 · 넘침은 null |
| `domain/alarm/one_shot_draft_test.dart` | `OneShotDraft` | 버튼 상수 · 상한 23시간 59분 · 상대 모드는 offset 에 쌓기 · 고정 모드는 fixedAt 에 더하기(자정 넘김) · reset · `fixAt`(오늘/내일, 초 0) · `ringAt`(**상대 모드는 지금이 든 분 초 0 + offset — 같은 분이면 몇 초든 같은 시각 · 내림으로 1분 미만이면 한 분 미룸 · 자정 넘김**) · `remaining`(지난 시각은 0) · `canSave` 1분 경계(두 모드) · `fromAlarm`(미래면 고정, 지났거나 없으면 상대 0) |
| `domain/alarm/upcoming_triggers_test.dart` | `upcomingTriggers` · `nextOccurrence` · `triggersOf` | 꺼짐 · 반복 요일만 오름차순 · 오늘 지남/아직 · `now` 와 같은 시각 제외 · 자정 · 14일 경계 포함/제외 · 월말 · 연말 · 윤년 · 1회성 · 서머타임(skip 조건부) · `skippedAt` 과 같은 순간의 회차만 뺌(다른 시각이면 그대로 · UTC 로 와도 같은 순간이면 뺌) · **쉬는 기간**(기간 안 날짜의 회차 제외 · 시작 · 끝 날 포함 · 끝 날 23:59 는 빠지고 다음 날 0시는 남음 · 1회성도 · `triggersOf` 도) |
| `domain/alarm/reminders_test.dart` | `remindersOf` · `reminderId` · 리드 시간 | 기본 리드 30분 · 24시간 · id 는 `1_000_000 + packageId * 2 + 종류`(패키지 id · 포크 자리표시 알림 973422 와 겹치지 않음) · **soon**(remindBefore 꺼짐이면 없음 · 회차마다 30분 전 · 1회성도 · 30분 안이면 안 만듦(경계 포함) · 리드 바꾸기) · **holiday**(반복 알람의 공휴일 회차는 24시간 전 이름과 함께 · 24시간 전이 지났으면 지금 · 1회성 없음 · 설정 끄면 없음 · 지난 회차 없음 · soon 과 둘 다) |
| `domain/alarm/holiday/korean_holidays_test.dart` | `KoreanHolidays`(내장 표) | 출처는 내장 표 2026–2027 · 2026(정규 · 대체 · 선거일 · 주말과 겹친 공휴일 · 22일) · 2027(설 연휴와 대체 · 노동절 · 제헌절 대체 · 부처님 오신 날 5/13 · 24일) · 평일 · 기념일은 null · 시각이 있어도 날짜로 · 표 밖의 해는 null |
| `domain/alarm/holiday/holiday_calendar_access_test.dart` | `HolidayCalendarAccess`(캘린더 권한) | ensure 로 새로 허용되면 바로 다시 읽음(force) · 이미 허용/거부면 안 읽음 · check 는 상태 그대로 · `requestAgain` 은 세션 기억과 상관없이 묻고 허용되면 다시 읽음 · `ensureIfReminding` 은 공휴일 미리 알림이 켜졌을 때만 묻기 |
| `domain/alarm/permission/alarm_permissions_test.dart` | `AlarmPermissions` | 알림 → 정확한 알람 순서 · `canRing` 은 둘 다 허용일 때만 |
| `domain/alarm/usecase/alarm_use_case_test.dart` | `DefaultAlarmUseCase` | **save**(새 id · 최대 id/9999 가득 · 1회성 `oneShotAt` · 14일 예약 · 수정 시 예전 회차(5분 안 · 스누즈 포함) 정리) · **toggle** · **delete** · **sync**(빠진 회차 걸기 · 남은 것 취소 · 멱등(스누즈 · 울림 있어도) · 1회성 만료 · **스누즈 중 1회성 유지** · **막 된 1회성 유지** · **꺼진 알람의 5분 안 예약 취소** · 울리는 회차 보존 · 스누즈 보존 창 경계 · 자정 넘은 스누즈 · 시간대 변경 재설정) · **지문**(시각 · 지문이 같으면 그대로 · 지문이 다르면 다시 걸기 · 옛 payload 는 한 번 다시 걸기 · 울리는 회차는 건드리지 않음) · **snooze/stop**(5분 뒤 · **꺼진/지운 알람은 멈춤** · **stop 도중 읽어도 꺼진 1회성**) · **스누즈 세부**(알람의 간격 · 센 횟수 + 1 · 한도를 다 쓰면 멈춤 · `canSnooze`(무제한 · 한도 전 · 한도 · 지움/꺼짐) · 보존 창은 알람의 간격 · sync 가 거는 회차는 0회) · **건너뛰기**(skipNext 는 다음 회차를 `skippedAt` 으로 · 보존 창 안 회차도 지움 · 두 번 불러도 하나 · 1회성/꺼짐/없는 id · unskip · skipOccurrence(반복 · 다음이 아닌 공휴일 회차 · 1회성은 끄기 · 지운 알람은 예약만) · 지난 `skippedAt` 정리 · **시각 · 요일을 바꿔 저장하면 남지 않는 건너뛰기를 지움(되돌려도 안 살아남) · 라벨만 바꾸면 둠**) · **미리 알림 diff**(30분 전 걸기 · 꺼짐 · 멱등 · 끄면 지움 · 시각 바꾸면 다시 걸기 · 정의에 없으면 지움 · 떠 있는 것 유지 · 떠 있어도 울릴 시각이 바뀌면 다시 걸거나 리드 안이면 지움 · 건너뛰거나 remindBefore 를 끄면 지움 · 공휴일 24시간 전 · 설정 끄면 지움 · 지났으면 지금 띄우고 다시 안 띄움 · 1회성 없음 · 실패해도 알람 예약은 끝남) · **nextRings**(알람별 최솟값 · 스누즈 포함 · 지난 것 · 꺼짐 · 예약 없음) · `timeZoneChanged` · 직렬 줄이 실패 뒤에도 풀림 · **쉬는 기간**(`setPause` 뒤 sync 가 기간 회차 · 미리 알림을 거두고 지난 기간은 지움) · **건너뛰기 기록**(반복은 회차가 지난 sync 에서 한 번 · **취소(unskip) · 시각 변경으로 지워진 건너뛰기는 기록하지 않음** · 1회성 skipOccurrence 는 바로 · 기록 실패해도 건너뛰기 · 정리는 됨) · **새 id 는 울림 기록에 남은 지운 알람 id 를 피함** · **홈 화면 위젯**(sync 끝에 켜진 알람의 걸린 예약을 이른 순 (시각, 라벨) · **두 알람이 섞인 가장 이른 20개(자른 뒤 정렬하면 실패)** · 바꾸는 동작도 갱신 · 실패 삼킴) |
| `domain/alarm/entity/alarm_pause_test.dart` | `AlarmPause` | `contains` 경계(시작 날 0시 · 끝 날 23:59 포함, 앞뒤 날 제외 · 시각 붙은 값도 날짜로) · `isOver`(끝 날이 오늘이면 아직) · 빠른 기간(오늘만 · 내일까지 · 이번 주말 — 평일 · 토 · 일 · 달 넘김) |
| `domain/alarm/ring_log_test.dart` | `ringLogGroups` | 한 회차의 울림 · 스누즈 · 다시 울림 · 끔을 한 묶음 · 자동 멈춤 · 끔 없음 · 건너뜀 · 건너뛰었다가 울리면 울림 · 지운 알람 · 회차마다 나누고 최근 먼저 · 100일 뒤 같은 packageId 는 다른 회차 · **자정을 넘긴 스누즈 · 끔도 한 회차** |
| `data/alarm/channel_ring_log_source_test.dart` | `ChannelRingLogSource`(`walk/ring_log`) | JSON 줄 → 기록 · since 이전 뺌 · 깨진 줄 · 모르는 종류 건너뜀 · append 인자 · 채널 없으면 빈 목록/무시 · 네이티브 오류는 던짐 |
| `data/alarm/channel_next_alarm_widget_test.dart` | `ChannelNextAlarmWidget`(`walk/widget`) | update 에 `{atMillis, title}` 목록(빈 목록도) · `takeLaunch` 응답 · 채널 없으면 무시/false · 네이티브 오류는 던짐 |
| `data/alarm/package_alarm_scheduler_test.dart` | `PackageAlarmScheduler.settingsFor` · 지문 | 스펙 §5 설정(반복 재생 · 전체 화면 · 스와이프해도 계속) · 진동 항상 · 무음 모드 체크 전달 · 기본 제목 · 본문은 기기 언어 시각 · 버튼 문구(ko/en/ja) · 알림 작은 아이콘 `ic_stat_alarm`(`notificationIcon`) · **울림 세부**(점점 커지기 끔이면 고정 볼륨 · 켜면 그 시간 동안 그 볼륨까지 · 스누즈 간격과 버튼 문구의 분 · 한도와 센 횟수 전달 · 한도에 닿으면 스누즈 간격 · 버튼 없음 · 무제한 · 자동 멈춤 Duration/null · 포크 `nextAfterSnooze` 와 같은 결과) · **소리**(시스템은 경로 없음 · 내장은 에셋 · 기기는 복사본이 있으면 그 경로, 없으면 시스템 · 대체음은 항상 비프) · **지문**(결정적 8자리 hex · 소리/무음 모드 체크/라벨 · 볼륨 · 점점 커지기 · 스누즈 간격 · 한도 · 자동 멈춤이 바뀌면 바뀜 · 미리 알림 · 건너뛰기는 무관 · **웨이브 1 전(vibrate 자리) · 알림 아이콘 전 · 웨이브 3 전 지문과 겹치지 않음(한 번 다시 건다)** · 켜짐/시각/로캘 문구는 무관 · payload `'<id>\|<지문>'` 읽기, 옛 payload 는 빈 지문) |
| `data/alarm/channel_alarm_sound_source_test.dart` | `ChannelAlarmSoundSource`(`walk/alarm_sounds`) | `list` → 제목 · uri, null 은 빈 목록 · `preview` 의 kind(system · asset · uri, 복사본은 `file://`) · `stopPreview`(채널 없으면 조용히) · `import` 경로 → `AlarmSound.device`, 빈 경로 · 오류 · 채널 없음 → `AlarmSoundException` |
| `data/alarm/channel_reminder_scheduler_test.dart` | `ChannelReminderScheduler`(`walk/reminders`) | 채널 이름 · `argumentsFor`(soon: epoch millis · 문구 · [이번만 끄기] · 라벨 없으면 기본 제목 / holiday: 날짜 · 이름 · 시각 · [다음 알람 건너뛰기] · [울리기] · 이름 없으면 날짜만 · 영어는 이름 없이) · `scheduled` 맵 · `schedule` 은 기기 언어 문구 · `cancel` id · 채널 없으면 빈 맵/무시 |
| `data/alarm/channel_reminder_scheduler_symbols_test.dart` | `ChannelReminderScheduler.prepareArguments` | **날짜 기호를 아무도 올리지 않은 상태(헤드리스)에서도 `오전 7:00` · `10월 9일` 로 만든다(대체 문구 `07:00` · `10/9` 아님)** — 다른 테스트의 `initializeDateFormatting` 에 가리지 않게 파일을 나눴다 |
| `data/alarm/channel_device_holiday_source_test.dart` | `ChannelDeviceHolidaySource`(`walk/holidays`) | 채널 이름 · `read` 는 범위를 날짜 문자열로 넘기고 날짜 · 이름으로 옮김 · 깨진 행 건너뜀 · 권한 없음/캘린더 없음(null) · 오류 · 채널 없음은 null · `calendarName` 그대로 · 오류/채널 없음 null · **`canRead`(읽기 권한) 그대로, 모르면(null · 오류 · 채널 없음) true** |
| `data/alarm/cached_holiday_calendar_test.dart` | `CachedHolidayCalendar` | 캐시 없으면 내장 표 · refresh 는 오늘부터 400일을 캐시하고 폰 캘린더로 답함 · 새 인스턴스(헤드리스)도 캐시를 읽음 · 하루 한 번(같은 날 건너뜀 · 다음 날 · force) · 폰 캘린더 없음(null)이면 내장 표, 그날은 다시 안 읽음 · 이름 없어도 폰 캘린더 출처 · 읽기가 던져도 끝나고 캐시 유지 · 오래된 캐시(maxAge) · 범위 밖 날짜 · 깨진 캐시는 내장 표 · **캐시를 새로 쓰면 `refreshed` 로 알림(같은 날 건너뜀 · 읽기 실패는 안 알림, force 는 알림)** · **권한 회수: 오늘 읽은 폰 캘린더 캐시가 있어도 권한이 없으면 다시 읽어 내장 표(새 인스턴스도) · 그때 `refreshed` 알림 · 권한이 그대로면 같은 날 안 읽음 · 캐시가 내장 표면 권한을 묻지 않음 · 권한 확인이 던지면 지난 캐시** |
| `data/alarm/prefs_alarm_repository_test.dart` | `PrefsAlarmRepository` | 없음 · 왕복 · 비우기 · **다른 isolate(헤드리스 엔진)가 쓴 값을 읽음(읽을 때마다 `reload`)** · **깨진 JSON/배열 아님/항목 하나 깨짐/문자열 아님 → 던지지 않고 읽을 수 있는 것만, 원본은 `walk.alarms.corrupt`** · 백업 덮어쓰기 · 정상 저장 복구 |
| `data/alarm/calendar_permission_source_test.dart` | 캘린더 읽기 권한 채널(`walk/calendar_permission`) | `granted` · `denied` · `permanentlyDenied` 매핑 · 모르는 값 · null 은 거부 · request 는 네이티브 요청 · openSettings · 채널 없으면 거부(던지지 않음) · `HolidayCalendarAccess` 와 엮어 거부 → 다시 묻기 → 허용이면 캐시를 force 로 다시 읽음 |
| `data/alarm/full_screen_intent_permission_source_test.dart` | 전체 화면 알림 채널 | `canUse` true/false · 요청은 설정을 열고 다시 읽음 · 채널 없으면 허용 |
| `data/alarm/permission_handler_source_test.dart` | `permission_handler` 래퍼 | 상태 매핑 |
| `data/settings/prefs_settings_repository_test.dart` | `PrefsSettingsRepository` | 없음/저장/모르는 값 → 시스템 · **문자열 아닌 값 → 시스템** · 목표 · 축하일 왕복 · 깨진 값 기본/clamp · 축하일 null 은 키 삭제 · **저장 도중 읽어 다시 저장해도 앞선 목표 유지** · **쉬는 기간**(`pauseFrom` · `pauseUntil` 날짜만 왕복 · 없으면/한쪽만/날짜 아님 null · null 로 지움 · 다른 설정을 바꿔도 유지) |

### 알람 · 설정 · 셸 — 화면

| 파일 | 대상 | 확인 |
|---|---|---|
| `presentation/alarm/format/alarm_format_test.dart` | `AlarmFormat` | 분 올림 · 시간/일 · `N 뒤` 표(스펙 §4.3, ko 는 '뒤'로 통일) · 단위 경계 · 음수 → 1분 · **1초 미만 자투리 올림** · 오늘/내일/월일 · 자정 · 달/해 넘김 · `earliest` 동률은 작은 id · 반복 요약 · 기기 언어 시각 |
| `presentation/alarm/cubit/alarm_list_cubit_test.dart` | `AlarmListCubit` | load(목록 · `nextAt` · `now` · 권한) · **읽기 실패 → failure(던지지 않음)** · 권한/다음 울림 실패에도 목록 · 다시 load · `tick` 은 저장소를 안 읽음 · 회차 지나면 다시 읽음 · 토글(낙관적 반영 · 권한 · 남은 시간 · **권한 예외여도 성공** · 실패 시 되돌림 · **저장+재읽기 실패 → failure**) · **공휴일 칩**(규칙의 다음 회차가 24시간 안 공휴일인 반복 알람 · 멀면 tick 에서 · **스누즈된 울림이 아니라 건너뛰기가 고를 회차로** · 건너뛴 공휴일 회차에도 · 1회성 없음) · 건너뛰기(skipNext · unskip 뒤 다시 읽기 · 실패하면 읽고 던짐) · **쉬는 기간**(load 가 담음 · 기간 안 공휴일 칩 없음 — **tick 도 같음** · 쉬는 중 켜면 남은 시간은 기간 뒤 · 읽기 실패는 쉬지 않음 · setPause · delete · **tick 이 끝난 쉬는 기간을 보면(앱을 띄운 채 자정) sync 뒤 다시 읽음 · sync 실패해도 읽음 · 끝 날 안에서는 sync 없음** · **기간 때문에 예약이 없는 켜진 알람은 `pausedOut`**) |
| `presentation/alarm/cubit/alarm_edit_cubit_test.dart` | `AlarmEditCubit` | isNew · 값 바꾸기(시각 · 요일 · 라벨 · 무음 모드 체크 · 알람음) · 저장 → 권한(거부돼도 계속) → 남은 시간 · **권한 예외여도 저장 성공** · 저장 실패면 권한 안 물음 · 삭제 · **한 번**(새 알람은 상대 0 · 저장 불가, 미래 `oneShotAt` 은 고정으로 열기, 더하기 · 초기화 · 시각 고정, 상대 모드 저장은 지금 + offset, **고정 모드 저장은 그 시각 · id 그대로**, 저장 불가면 던짐) · **반복**(묶음 · 요일 없으면 저장 불가 · 던짐) · 울림 설정(볼륨 · 점점 커지기 · 스누즈 간격 · 횟수 · 자동 멈춤 · 30분 전 알림) 저장 · 캘린더 권한(반복만 · 예외여도 저장 성공) · **쉬는 기간 안의 한 번 알람을 저장하면 `pausedOut`** |
| `presentation/alarm/cubit/alarm_save_result_test.dart` | `AlarmSaveResult.of` | 쉬지 않으면 남은 시간 · 기간 안의 한 번 알람은 `pausedOut` · 반복은 기간 뒤 첫 회차까지 · 꺼짐 · 지난 한 번 알람은 null |
| `presentation/alarm/cubit/alarm_sound_cubit_test.dart` | `AlarmSoundCubit` | 처음 선택(시스템 · 내장 · 기기) · 목록을 읽으면 같은 제목 줄로 표시 이동, 없으면 현재 값 · **목록을 읽는 동안 고른 선택 유지**(Completer) · 목록 실패 · 탭하면 미리 듣기(기기는 uri) · 미리 듣기 실패 무시 · confirm(시스템 · 내장 그대로 · 기기는 import, 그동안 importing · 실패면 던짐 · 복사 중 선택 무시) · **현재 기기 소리 줄을 그대로(또는 돌아와) 고르면 import 없이 원래 값** · `pausePreview` · 닫으면 미리 듣기 멈춤 |
| `presentation/alarm/format/alarm_sound_format_test.dart` | `AlarmSoundFormat` | 시스템 기본 · 내장음은 에셋 경로로 이름(`default.wav` 는 "비프") · 모르는 에셋은 파일 이름 · 기기는 제목 |
| `presentation/alarm/cubit/alarm_ringing_cubit_test.dart` | `AlarmRingingCubit` | 회차의 알람 찾기 · `canSnooze`(한도를 다 쓰면 false · 읽기 실패면 남김 · 처리 중에도 그대로) · snooze · stop |
| `presentation/alarm/page/alarm_list_page_test.dart` | `AlarmListPage` | 빈 상태(카드 숨김) · 요약 카드(가장 이른 알람 · 동률 · 모두 꺼짐 · **켜졌는데 예약 없음 → 예약 없음 · 권한 안내, 배너가 위**) · 행(켜진 것만 남은 시간 · 꺼진 행 흐림) · 스위치 켜기/끄기 → 카드 · 행 갱신 · 실패 되돌림 + 스낵바 · 자정 tick · 행 탭 → 편집 → 스낵바 · 카드 누를 수 없음 · 분 경계 타이머(0초 · 가려지면 건너뜀) · 읽기 실패 → 다시 시도 · 권한 배너 → 설정 탭 · FAB · 길게 누르기 → 건너뛰기 시트 → 건너뜀 칩 · 건너뛴 알람은 취소 · 한 번/꺼진 반복은 길게 누르기 없음(남은 값은 취소 가능) · 시트 그냥 닫기 · 실패 스낵바 · 공휴일 칩 → 시트 · **알람 메뉴**(모든 행 길게 누름 · [복제] → 저장 전 편집 · 한 번 알람의 지난 시각은 0분 뒤 · **아직 오지 않은 한 번 알람은 같은 날짜 · 시각** · [삭제] 확인 · 취소 · 실패) · **쉬는 기간**(앱바 [알람 쉬기] → 시트 → 배너가 카드 위 · 시작 · 끝 문구 · 알람이 없어도 배너 · [그만 쉬기] · **기간이 회차를 덮으면 카드에 권한 안내 없음** · **기간 때문에 예약이 없는 행에 `쉬는 중`(한 번은 `한 번 · 쉬는 중`) · 쉬는 중에 기간 안의 한 번 알람을 저장하면 `쉬는 기간이라 울리지 않아요` 스낵바**) · 앱바 [울림 기록] |
| `presentation/alarm/page/alarm_edit_page_test.dart` | `AlarmEditPage` | **한 번**: 0분 뒤 · 저장 잠금 + 안내 · 더하기 · 초기화 · 시각 칩 → 휠 시트 고정 · 상대 모드는 분이 지나도 N 뒤 그대로 · 기존 알람은 그 시각으로 열고 저장 · 칩으로 고정한 시각으로 저장 · **연 초와 상관없이 다음 분 0초에 맞춰 갱신 · 그 뒤 매분** · **고정 모드 남은 시간이 줄고 1분 밑으로 내려가는 순간 잠금 · 안내** · **기준 시각이 늦어도 저장 때 다시 보고 오류 대신 잠금 · 안내** · **칩으로 고정하면 기준 시각을 새로 읽음** · **분 중간에 저장해도 칩에 보인 분(초 0)으로 저장** · **오늘이 아니면 칩에 날짜(`내일 (월) 오전 12:08에 울림`)** / **반복**: 휠 · 빠른 버튼 ↔ 요일 · 요일 없으면 잠금 + 안내(**요약 줄 자리 유지 — 제목 칸이 뛰지 않음**) · 저장 흐름 · 기존 알람 id · 라벨 유지 / 공통: 제목 · 알람음 · 무음 모드 체크 줄 순서(진동 토글 없음) · 체크 값 저장 · 실패 스낵바 · **권한 실패여도 닫히고 중복 저장 없음** · 저장 중 잠금 · 알람음 선택 반영 · **제목 입력 중 알람음 줄을 누르면 포커스를 풀고 돌아와도(뒤로 · 선택) 다시 잡지 않음** · 삭제 확인 · 320dp(요일 한 줄 · ko/en/ja) / **울림 설정**: 체크 줄 아래 · 저장 위에 접힘 · 요약 · 펼쳐 고른 값으로 저장 · 한 번 알람도 있고 캘린더 권한은 안 물음 · **앱바 [복제]**(새 알람엔 메뉴 없음 · 복제 편집을 위에 열고 저장하면 두 화면이 닫힘 · 그냥 닫으면 돌아옴) |
| `presentation/alarm/cubit/alarm_history_cubit_test.dart` | `AlarmHistoryCubit` | 최근 30일을 회차로 묶음(앞날 회차는 뺌) · **회차가 지났지만 아직 sync 전인 `skippedAt` 도 건너뜀** · 실패 → 다시 읽기 |
| `presentation/alarm/page/alarm_history_page_test.dart` | `AlarmHistoryPage` | 날짜 머리 · 회차 한 줄(울림 · 스누즈 · 끔) · 건너뜀 · 지운 알람 · 빈 상태 · 오류와 다시 시도 |
| `presentation/alarm/widget/alarm_menu_sheet_test.dart` | `AlarmMenuSheet` | 켜진 반복은 [복제 · 다음 알람 건너뛰기 · 삭제] · 쉬는 중이면 기간 뒤 회차 · 한 번 · 꺼진 반복은 건너뛰기 없음 · 건너뛴 알람은 [건너뛰기 취소] · 각 동작 · 삭제는 오류 색 · 320dp(ko · en · ja) |
| `presentation/alarm/widget/alarm_pause_sheet_test.dart` | `AlarmPauseSheet` | 빠른 기간 셋과 문구 · 고르면 그 기간 · [날짜 고르기] 달력 · 취소 · 그냥 닫으면 null |
| `presentation/alarm/widget/alarm_pause_banner_test.dart` | `AlarmPauseBanner` | 쉬는 중이면 끝 날만 · 시작이 뒤면 시작 · 끝 · [그만 쉬기] |
| `presentation/alarm/page/alarm_sound_page_test.dart` | `AlarmSoundPage` | 세 구역(시스템 · 앱 소리 3줄 · 기기 목록) · 복사해 둔 소리는 같은 제목 줄에 표시 · 목록 실패/빈 목록은 그 구역만 안내 · 탭 → 표시 이동 · 미리 듣기 → 선택하면 그 소리로 닫힘 · 복사 중 버튼 로딩 · 복사 실패 스낵바 · 뒤로 가면 null · 미리 듣기 멈춤 · **앱이 가려지면(홈 · 잠금) 미리 듣기 멈춤** |
| `presentation/alarm/page/alarm_ringing_page_test.dart` | `AlarmRingingPage` | 시각 · 라벨 · 뒤로가기 막힘 · 기본 제목 · 끄기 · N분 뒤(알람의 스누즈 간격) 후 닫힘 · **스누즈 한도를 다 쓰면 스누즈 버튼 없이 끄기만 전체 폭** · 리스너가 먼저 걷어도 아래 화면 유지 · 320dp 버튼 문구(ko/en/ja) |
| `presentation/settings/cubit/*_test.dart` | 테마 · 권한 · 공휴일 cubit | 저장된 테마로 동기 시작 · 선택 즉시 반영/저장 · 네 권한 읽기 · 알림 다시 묻기/설정 · 정확한 알람 · 전체 화면 · Health Connect 요청/설정/스토어 · **공휴일**(`HolidaySettingsCubit`: 저장된 설정 · 출처 · 캘린더 권한 읽기 · 권한 실패여도 출처 · 시스템 설정에서 허용하고 돌아오면 다시 읽고 알람 맞추기(처음 확인은 안 읽음) · 끄면 저장 · 맞추기 · 안 물음 · 켜면 저장 → 권한 → 맞추기 → 출처 · 실패해도 설정은 바뀜 · 거부면 다시 묻고 영구 거부 · 허용이면 앱 설정 · **캐시 갱신(`refreshed`)이면 확인 없이 출처를 다시 읽음 · 닫으면 구독 해제**) |
| `presentation/theme/walk_theme_test.dart` | `WalkTheme` · `WalkMotion` | 초록 시드 · 애니메이션 끄기 읽기 |
| `presentation/alarm/widget/alarm_summary_card_test.dart` | `AlarmSummaryCard` | 초록 컨테이너 색 · 남은 시간 색 · 시간이 바뀌면 `AnimatedSwitcher` |
| `presentation/alarm/widget/alarm_tile_test.dart` | `AlarmTile` | 둥근 카드 행 · 반복(시각 · 제목 · 요약 · 요일 점) · 한 번(모래시계 · N 뒤) · 꺼진 알람 흐림 · 꺼져도 행 탭 동작 · 스위치 햅틱 후 `onToggle` · 320dp 긴 제목 · 건너뛴 반복 알람은 "건너뜀" 칩(꺼지면 없음) · 공휴일 칩 → `onHolidayTap` · 길게 누르기 → `onLongPress` · 320dp 칩 둘 · **쉬는 기간 때문에 예약이 없으면 한 번은 `한 번 · 쉬는 중`, 반복은 "쉬는 중" 칩(꺼지면 없음)** |
| `presentation/alarm/widget/alarm_kind_sheet_test.dart` | `AlarmKindSheet` | 손잡이 · 제목 · 두 행 · 한 번/반복을 고르면 그 종류로 닫힘 · 그냥 닫으면 null · 320dp(ko/en/ja) |
| `presentation/alarm/widget/alarm_skip_sheet_test.dart` | `AlarmSkipSheet` | 손잡이 · 알람 · [다음 알람 건너뛰기 · 다음 회차] → skip · 건너뛴 알람은 [건너뛰기 취소 · 건너뛴 회차] → unskip · 라벨 없으면 시각만 · 그냥 닫으면 null · 320dp(ko/en/ja) |
| `presentation/alarm/widget/alarm_time_wheel_test.dart` | `AlarmTimeWheel` | 시 열 화면 읽기 라벨에 '정각' 없음(`12시` · `12 hours` · `12時`, QA: 분 43 인데 `12시 정각`) · 휠 전체 라벨은 고른 시각(`오전 12:43`)이고 바꾸면 따라감 · `onChanged` · `maximum` 뒤 시각은 고를 수 없음(일기 미래 시각 금지) |
| `presentation/alarm/widget/ring_settings_section_test.dart` | `RingSettingsSection` | 접힌 상태는 제목 · 요약 한 줄(알람 값) · 펼치면 볼륨 · 점점 커지기 · 스누즈 간격 · 횟수 · 자동 멈춤 · 30분 전 알림 · 고르면 그 값(무제한 · 안 함은 null) · 볼륨 10 단위 · **볼륨 슬라이더는 이름표 `볼륨` · 값 `80%`(±10%) 한 번만 읽음** · 저장 중 잠금 · 320dp 펼쳐도 안 넘침(ko/en/ja) |
| `presentation/alarm/widget/weekday_dots_test.dart` | `WeekdayDots` | 월~일 7개 · 켜진 요일 primary, 나머지 outlineVariant · 흐리게면 onSurfaceVariant |
| `presentation/alarm/widget/ringing_ripple_test.dart` | `RingingRipple` | 켜면 위상이 변함 · 애니메이션 제거면 정지 |
| `presentation/settings/widget/step_goal_sheet_test.dart` | `StepGoalSheet` | 슬라이더 2,000~30,000 · 1,000 단위 · 저장하면 값 반환 |
| `presentation/settings/page/settings_page_test.dart` | `SettingsPage` | 걷기 섹션 · 하루 목표 시트 → 저장 · 권한 상태 · 앱 정보(버전 · 라이선스)와 14일 안내 없음 · 행 탭별 동작 · 확인 중이면 빈 문구 · 테마 선택 · **공휴일**(걷기와 권한 사이 스위치 · 출처(내장 표 · 캘린더 이름 · 이름 모름) · 캘린더 권한 · 확인 중 빈 문구 · 끄면 저장 · 맞추기 · 출처 행 → 권한 다시 묻기 · 320dp) · **일기 섹션**(알람과 권한 사이 · 잠금 꺼짐/PIN/패턴 표시 · 용량 문구(크기 · 사진 · 영상 수 · 휴지통 몫, B · KB) · 탭이 다시 보이면 용량 다시 읽기 · 휴지통 기간 4개 · 다시 잠기는 시간 4개 → 최신 설정에 저장하고 잠금에 알림 · 잠금 꺼짐이면 다시 잠기는 시간 행 막힘 · **일기가 잠긴 동안 두 행 막힘 · 시트가 열린 사이 잠기면 저장 안 함** · 잠금 행 → `LockSetupPage` · PIN → 패턴 · 끄면 풀림 · 그냥 닫으면 그대로) |
| `presentation/shell/page/main_shell_page_test.dart` | `MainShellPage` | 첫 탭 걷기 · 초록 컨테이너 · 선택 탭 채움 아이콘 · 탭 전환 · 시작/복귀 때 sync 뒤 목록 · 복귀 때 권한 행 · **울림 화면이 걷히면 sync** · **sync 실패해도 목록** · 네이티브 `resync` → 재설정 · 목록 · 응답(실패해도) · 사라지면 핸들러 해제 · **설정 탭에서 목표를 낮춰 달성해도 걷기 탭을 열 때 한 번 축하** · 설정 탭 공휴일 출처 · 권한 읽기(허용하고 돌아오면 다시) · 시작 · resync 때 공휴일 캐시 갱신 → 예약(갱신 실패해도 예약) · 네이티브 `reminderAction` → 건너뛰고 목록 · true(실패면 false, 알림 남김) · **헤드리스 기다리기: 시작 · 복귀 sync 는 네이티브 `awaitIdle` 응답 뒤(그 전엔 공휴일 갱신 · sync 없음) · 응답이 없으면 10초 뒤 그냥 sync · 네이티브 `resync` 는 `awaitIdle` 을 묻지 않음** · **일기**: 탭 순서 알람 · 걷기 · 일기 · 설정 · 시작 때 고아 청소 한 번(실패해도 화면) · 잠긴 채 시작, 풀었다 백그라운드에 오래 있으면 다시 잠김 · 일기가 잠겨 있어도 알람 울림 화면 |
| `core/alarm_ring_listener_test.dart` | `AlarmRingListener` | 한 번만 띄움 · 밖에서 끄면 걷음 · 화면이 먼저 닫힘 · 스누즈 뒤 다시 띄움 · 가려진 화면만 걷음 · 내비게이터 전 값 · 첫 프레임 전 시작→끝이면 안 띄움 · 중복 start · dispose · **앱 복귀 안전망: 플랫폼이 안 울린다는 화면을 걷음 · 아직 울리면 둠 · 걷은 뒤 늦은 같은 울림 값으로 다시 띄우지 않음(끝 값 뒤 다시 울리면 띄움)** |
| `core/app_test.dart` | `WalkApp` · `themeModeOf` | 테마 매핑 · 저장된 다크로 첫 프레임 · 일기 의존을 등록한 앱 시작 |
| `core/background/background_task_test.dart` | `runBackgroundTask` · `resyncTask` · `reminderActionPackageId` | init → task → done(true) · init 실패면 task 건너뛰고 done(false) · task 실패면 done(false) · done 실패도 삼킴 · done 한 번 · 공휴일 갱신 → sync(갱신 실패해도 sync) · 진입점 인자 `["skip", id]` · **`awaitBackgroundIdle`: `awaitIdle` 을 부르고 응답까지 기다림 · 시간 한도(10초) 뒤 그냥 끝남 · 채널 없음/오류면 바로 끝남** |

### 일기 — 도메인 · 데이터

DB 는 `NativeDatabase.memory()`(진짜 SQLite — 제약 · 트랜잭션 · FK 연쇄), 파일은 임시 디렉터리, 압축은
`FakeMediaProcessor`(`test/support/`), 위치 · 역지오코딩은 가짜 함수, 시간은 `Clock` 주입. 픽스처는 `test/support/diary_fixtures.dart`.
저장소 테스트는 `DriftDiaryRepository` 하나를 관심사별 파일로 나눴다(설계 §9.3). 괄호 안은 2026-10-13 기준 건수.

| 파일 | 대상 | 확인 |
|---|---|---|
| `domain/diary/entity/tag_name_test.dart` (9) | `TagName` | 앞뒤 공백 · `#`(여러 개) · 안쪽 공백 제거 · 소문자 · `#` 뿐이거나 빈 값은 null · 30자 되고 31자 null · 이모지 그대로 · `searchKey` 는 30자를 넘어도 다듬은 값(어떤 태그와도 안 맞음) |
| `domain/diary/entity/entry_time_test.dart` (12) | `EntryDraft.validate` · `DiaryEntry` | now 와 같은 시각 OK · +1초 `futureTime` · 빈 글/공백 글 + 미디어 0 은 `emptyEntry` · 미디어만 OK · 11개 `tooManyMedia` · 30,001ms `videoTooLong` · 검사 순서 · `timeEdited` · `isTrashed` |
| `domain/diary/entity/media_limits_test.dart` (3) | `MediaLimits` | 합 10 이하만 추가 · 영상 30초까지 · 상수 |
| `domain/diary/entity/story_test.dart` (9) | `Story` | 닫으면 `endedAt` · 기본 스토리 거절 · 시작 전 시각 거절 · 시작과 같은 시각 허용 · 다시 열기 · `covers` 경계 포함 · `endedAt` 없으면 미래 전부 |
| `domain/diary/entity/trash_retention_test.dart` (4) | `TrashRetention` | 7일: 6일 23:59:59 아직 · 정확히 7일 만료 · 안 함은 1000일도 아님 · 모르는 값은 7일 |
| `domain/diary/usecase/story_suggestion_test.dart` (11) | `StorySuggestion` | 작성 기본: 열린 것 중 `lastPostedAt` 최신 · 닫힌 것 제외 · 없으면 일상 · 같으면 최근 생성 · 시각 제안: 기간 안 열린 것 · 여럿이면 최신 · `endedAt` 없음은 시작 이후 전부 · 양 끝 포함 · 닫힌 것 제외 · 없으면 일상 |
| `domain/diary/usecase/story_order_test.dart` (3) | `StoryOrder` | 열린 것 `lastPostedAt` 내림차순(없으면 `createdAt`) · 같으면 최근 생성 · 닫힌 것은 보관함 `endedAt` 내림차순 |
| `domain/diary/usecase/story_cover_test.dart` (8) | `StoryCoverRule` | 지정 표지 · 없으면 최신 기록의 첫 사진 · **지정 표지의 기록이 휴지통이면 자동 표지** · 휴지통 미디어 안 씀 · 영상만이면 썸네일 · 사진 먼저 · 미디어 없으면 이니셜 · **유일한 사진이 휴지통이면 이니셜** |
| `domain/diary/usecase/diary_use_case_test.dart` (22) | `DiaryUseCase` | 저장: 새 미디어 tmp → media 이동 · **DB 실패면 옮긴 파일을 되돌림** · 규칙 위반이면 안 옮김 · 수정에서 뺀 파일은 성공 뒤에만 지움 · 취소는 tmp 정리 · 휴지통: 파일 그대로 · 복원하면 같은 경로가 열림 · **사진 2 + 영상 1 영구 삭제 → 썸네일까지 파일 0, 다른 기록 파일 유지** · 비우기 · 파일 삭제가 던져도 Ok(고아 청소가 회수) · 스토리 삭제 · 정리: 휴지통 기한 · 장소 이름 채우기(오프라인이면 멈춤 · `noName` 은 건너뜀 · 한 번에 20곳 · 겹쳐 부르면 한 번) · 고아 청소(저장 중인 파일 남김) |
| `data/diary/database/diary_database_test.dart` (8) | `DiaryDatabase` | 첫 실행 "일상" 한 행 · 다시 열어도 하나 · 지워도 되살아남 · `foreign_keys` · `tags.name` · `places.name` UNIQUE · 기록 삭제 시 `media` · `entry_tags` 연쇄 · 없는 스토리 FK |
| `data/diary/drift_diary_repository_entry_test.dart` (38) | 기록 CRUD · `watchEntries` | 미디어 순서 · 태그 · 장소 기존 행 재사용 · 표기만 다른 태그 하나 · 좌표만 있는 위치 · `lastPostedAt` · 닫힌 스토리에 새 기록 `storyClosed` · 이모지 · 1만 자 왕복 · 수정은 `updatedAt` 만 · 위치 끄면 장소 · 좌표 null · 정렬 · **닫힌 스토리로 옮기기(R23)** · 휴지통 기록은 고칠 수 없음 · `moveEntries` · **트랜잭션 중간 실패면 아무 행도 안 남음** · 태그 · 미디어 · 장소만 바뀌어도 다시 내보냄 · 필터 5종 |
| `data/diary/drift_diary_repository_story_test.dart` (15) | 스토리 | 만들기(open/closed · `endBeforeStart`) · 닫기 · 다시 열기 · 이름 · 표지 · 기본 스토리 닫기 거절 · 스토리 바 순서 · `entriesBetween` · **스토리 삭제 = 기록 전부 휴지통 + 행 삭제** · 처음 `deletedAt` 유지 · 기본 스토리 삭제 거절 |
| `data/diary/drift_diary_repository_trash_test.dart` (16) | 휴지통 · 연쇄 삭제 | `deletedAt` 만 채움 · 모든 목록 · 검색에서 빠짐 · **영구 삭제 → 기록 · 미디어 · 태그 연결 행 삭제, 원본 · 썸네일 경로 반환** · 다른 기록의 미디어 · 공유 태그 · 장소 유지 · 휴지통 기록이 쓰는 태그 · 장소 유지 · 지운 표지 → `coverMediaId` null · 살아 있는 기록은 안 지움 · 트랜잭션 실패 · 닫힌 DB → `Err` · 비우기 · 기한(같은 시각 포함) · `allMediaPaths` |
| `data/diary/drift_diary_repository_trash_restore_test.dart` (9) | 휴지통 → 복원(설계 §9.3.1) | 삭제해도 미디어 행 · 경로 그대로 · 복원 뒤 스토리 · 전체 · 검색 · 태그 · 장소에 다시 · 지정 표지 되돌아옴 · 닫힌 스토리로 복원(보관함) · 지워진 스토리면 일상으로 · 영구 삭제 뒤 `notFound` · `updatedAt` 불변 |
| `data/diary/drift_diary_repository_tag_sync_test.dart` (8) | 해시태그 반영(§9.3.2) | 추가 +1 · 스토리를 넘나드는 모아보기 · 휴지통 -1 · 마지막도 휴지통이면 숨김(행은 남음) · 복원은 같은 `tags.id` · `#제주` → `#부산` · 영구 삭제 정리 · 휴지통 기록만 가진 태그 검색 0 |
| `data/diary/drift_diary_repository_place_sync_test.dart` (7) | 장소 반영(§9.3.3) | 같은 장소 행 하나 · 휴지통 → 복원 같은 `places.id` · 모두 휴지통이면 숨김 · 수정으로 바꾸기 · 빼기 · 영구 삭제 정리 · 오프라인 기록 이름이 나중에 채워지면 합쳐짐 · 휴지통 오프라인 기록 제외 |
| `data/diary/drift_diary_repository_search_test.dart` (13) | 검색 | 부분 일치 · ASCII 대소문자 무시 · **`%` · `_` · `\` 글자 그대로** · 휴지통 제외 · 최신순 · 스토리를 넘나듦 · **한글 · 이모지 · 1만 자** · 태그 · 장소 모아보기 · 스토리 제목(일상 · 바꾼 기본 이름 · 순서 · 개수 갱신) |
| `data/diary/drift_diary_repository_suggest_test.dart` (12) | 추천 | 포함 일치 · 개수 → 최근 사용 순 · `lastUsedAt` 은 휴지통 아닌 기록 기준 · 빈 입력이면 상위 N · **`#Jeju` · `jeju` · ` 제 주 ` 는 하나** · 휴지통 제외 개수 · 0개 숨김 · 30자 초과 입력 · `%` · `_` 글자 그대로 · 장소 앞뒤 공백 |
| `data/diary/drift_diary_repository_place_fill_test.dart` (8) | 장소 지연 채우기 | 좌표만 있는 기록만(스토리 무관 · 휴지통 제외, 복원하면 다시) · 채우면 좌표 · `updatedAt` 그대로 · 같은 이름과 합침 · 빈 이름 무시 · 이미 장소가 있으면 안 덮음 |
| `data/diary/drift_diary_repository_usage_test.dart` (4) | 용량 | 0 · 사진 · 영상 개수와 바이트 · 휴지통 몫 따로(합계 포함) · 영구 삭제하면 빠짐 |
| `data/diary/media/file_media_store_test.dart` (20) | `FileMediaStore` | 원본 그대로 `tmp/<id>` 사본 · 겹치지 않는 경로 · 처리 실패면 `Err` + tmp 정리 · 영상 30초 받고 31초 `videoTooLong` · 길이 못 읽음 · **폴더를 못 만들면 던지지 않고 `Err`** · promote · demote · discard · deleteFiles · 고아 청소(keep · **24시간 안 바뀐 `media/` 남김** · tmp 는 24시간 지난 것만) |
| `data/diary/media/plugin_media_processor_test.dart` (19) | `PluginMediaProcessor`(플랫폼 인스턴스 가짜) | 긴 변 1600 목표 표 · 키우지 않음 · JPEG 85 · EXIF 제거 · 회전 보정 · 가로/세로 짧은 변 목표 · 영상 길이 ms 반올림 · 720p 압축 뒤 결과 · 썸네일 이동과 캐시 비우기 · **동시 호출은 차례로** · 앞 실패 뒤 다음 처리 · 실패해도 캐시 비움 |
| `data/diary/location/current_place_source_test.dart` (7) | `CurrentPlaceSource` | 좌표 + 이름 · 위치 서비스 꺼짐 · 권한 거부 · 예외 · 타임아웃 → null(오류 아님) · 이름 못 얻으면 좌표만 |
| `data/diary/location/geocoding_place_namer_test.dart` (9) | `composePlaceName` · `GeocodingPlaceNamer` | 앞의 두 필드 · 빈 값 건너뜀 · 호출마다 `locale` · 다음 결과로 넘어감 · 빈 목록 · 조합 불가 → `noName` · 예외 · 타임아웃 → `offline` |
| `data/diary/prefs_diary_preferences_test.dart` (4) | `PrefsDiaryPreferences` | 기본 7일 · 새 인스턴스로 왕복 · 타입이 다르거나 모르는 값은 기본값(보기 모드 저장은 화면 재기획으로 없어짐) |

### 일기 — 화면

| 파일 | 대상 | 확인 |
|---|---|---|
| `presentation/diary/cubit/diary_timeline_cubit_test.dart` (6) | `DiaryTimelineCubit` | 열린 스토리와 보관함을 나눠 둠 · 항상 모든 스토리의 기록을 최신순으로 · 저장 · 삭제 · 복원 즉시 반영 · 전체 필터 하나만 구독 · 기록 · 스토리 스트림 실패 |
| `presentation/diary/cubit/entry_editor_cubit_test.dart` (24) | `EntryEditorCubit` | 기본 스토리 · 지금 위치 · 위치 실패면 직접 입력 · **같은 분이면 안 바뀐 것** · 과거면 위치 빼기 · 미래 무시 · 스토리 제안 · 되돌리기 · 늦게 온 위치 버림 · 칩 · 위치 빼기 · 11개째 `tooManyMedia` · **한 번에 하나씩 가져오기** · 31초 거절 · **가져오기가 던져도 표시가 풀림** · 순서 바꾸기 · 빈 기록 · 중복 탭 · 취소 정리 · 뺀 미디어는 저장 뒤에만 |
| `presentation/diary/cubit/diary_search_cubit_test.dart` (13) | `DiarySearchCubit` | 탭 4개 · 299ms 조회 없음 / 300ms 한 번 · 마지막 입력만 · 빈 입력(글 · 스토리 조회 없음, 태그 · 장소 상위 추천) · 늦은 응답 버림(입력 · 탭) · 실패 · **메모리 DB 에서 휴지통 · 복원하면 추천 개수 · 결과 갱신** |
| `presentation/diary/cubit/filtered_entries_cubit_test.dart` (4) | `FilteredEntriesCubit`(태그 · 장소) | 열린 채 추가 +1 · 휴지통 -1 · 복원 +1 · 마지막이 사라지면 빈 상태 · 스토리를 넘나듦 |
| `presentation/diary/cubit/story_manage_cubit_test.dart` (18) | `StoryManageCubit` | 만들기(열림 · 닫힘 · 종료일 오류) · 지난 기간의 일상 기록만 제안 · 고른 것만 옮김 · 닫기(지금 · 고른 날 · 시작 전 거절) · 다시 열기 · 기본 스토리 닫기 거절 · 이름(기본 스토리 비우면 기본 이름) · 표지 · 후보는 살아 있는 기록 미디어 · 삭제 |
| `presentation/diary/cubit/story_covers_cubit_test.dart` (3) | `StoryCoversCubit` | 이니셜 → 사진 · 고른 표지와 휴지통이면 자동 · 스토리마다 자기 기록 |
| `presentation/diary/cubit/trash_cubit_test.dart` (12) | `TrashCubit` | 최신순 · 살아 있는 기록 안 보임 · 남은 일수(올림 · 0 아래 없음 · 안 함 null · 30일) · 복원 · 영구 삭제 · 비우기 · 실패 표시 |
| `presentation/diary/format/diary_format_test.dart` (10) | `DiaryFormat` | 오늘 · 어제 · 올해 · 지난해 날짜 머리 · 1월 1일의 어제 · 규칙 위반 문구 · 같은 날 · 1분 안이면 지금 · 스토리 기간 |
| `presentation/diary/media_picker_test.dart` (2) | `MediaPicker` | 앨범 · 카메라 고르기가 잠금 예외(`MediaPickGuard`) 안에서 · 남은 칸만큼 · 취소면 빈 목록 |
| `presentation/diary/page/diary_tab_test.dart` (28) | `DiaryTab` | **잠긴 동안 타임라인 · ＋ 가 트리에 없고 풀면 동그라미 줄 · 새 스토리 시트가 닫힘 · 가려진 탭은 다른 탭 팝업을 안 닫음** · 앱바 · 동그라미 줄 · 모든 스토리 피드(보기 모드 토글 없음) · 빈 상태 · 동그라미 탭 → 뷰어(진행 중은 마지막 날) · 순번 시작 · 기록 없는 스토리 → 스토리 페이지 · 길게 누르기 · 모두 보기 · ＋ 새 스토리 · 카드 탭 → 뷰어 그 기록 · 카드 머리 → 스토리 페이지 · 피드 영상 자동재생 안 함 · ＋ 시트 4항목(앨범 · 글만 쓰기) · 앱바 ⋮ 모든 스토리 · 휴지통 · 🔍 · 오류 · 보일 때 정리 한 번 · 잠긴 동안 정리 안 함 |
| `presentation/diary/page/entry_editor_page_test.dart` (26) | `EntryEditorPage` | 시각 행 · 스토리 시트(열린 것만) · 칩 · 추천 · 위치 ✕ → 직접 입력 · 올리기 · **칩으로 안 만든 태그 글자도 넣음** · 규칙 위반 안내 · 닫기 전 확인 · 앨범에서 남은 칸만큼 · 고치기 · **다시 잠기면 트리에서 빠지고 풀면 쓰던 글 그대로 · 잠금 화면 뒤로 가기 무시 · 스토리 시트 닫힘** · 화면이 사라져도 임시 사본 정리 |
| `presentation/diary/page/entry_actions_test.dart` (8) | `entry_actions` | 휴지통(확인 → 되돌리기 스낵바 · 실패 · `confirm: false` 면 바로 · 취소) · 스토리 옮기기(스낵바 · 되돌리기 · 같은 스토리 · 실패) · 고치기 화면 |
| `presentation/diary/page/story_page_test.dart` (15) | `StoryPage` | 머리 통계 · 처음부터 보기 → 뷰어 · 칸 탭 → 그 기록 · 기록 없는 스토리 · ⋮ 메뉴(일상 · 열린 · 닫힌) · 이름 · 닫기 · 다시 열기 · 삭제 확인 · 규칙 위반 스낵바 · 표지 시트(그 스토리 사진만) · **다시 잠기면 표지 시트 · 삭제 다이얼로그가 닫히고 지우지 않음** |
| `presentation/diary/page/all_stories_page_test.dart` (4) | `AllStoriesPage` | 진행 중 · 지난 구역 카드 → 스토리 페이지 · 지난 스토리 없으면 구역 없음 · ＋ 만들기 · 지난 기간이면 일상 옮기기 제안 · 오늘 시작이면 제안 없음 |
| `presentation/diary/page/story_form_sheet_test.dart` (8) | `StoryFormSheet` | 시작일 기본 오늘 · 제목 필수 · 종료일은 그날 끝 · 지우면 진행 중 · 시작일을 종료일 뒤로 · 이름 바꾸기(기본 스토리만 비우기 허용) |
| `presentation/diary/page/diary_search_page_test.dart` (9) | `DiarySearchPage` | 탭 4개 · 입력 안내 · 태그 · 장소 입력 전 추천과 개수 · 본문 강조 · 결과 없음 · 글 결과 → 그 기록부터 뷰어 · 스토리 결과 → 스토리 페이지 · 태그 · 장소 → 모아보기 · 오류 |
| `presentation/diary/page/filtered_entries_page_test.dart` (6) | `FilteredEntriesPage` | 태그 · 장소 제목과 개수 · 3열 그리드 · 열린 채 늘고 줄어듦 · ▶ 보기 → 모아보기 소스 뷰어 · 칸 탭 → 그 기록부터 · 오류 |
| `presentation/diary/page/trash_page_test.dart` (10) | `TrashPage` | 남은 일수 · 안 함이면 없음 · 오늘 삭제 · 복원 · 영구 삭제 · 비우기 확인 · 복원 · 삭제 실패 문구 따로 · 빈 상태 |
| `presentation/diary/viewer/viewer_model_test.dart` (7) | `buildViewerGroup` · `startPos` · `nextPos` · `prevPos` · `dayNumber` | 날짜별 묶음 · 기록 안 미디어마다 조각 · 휴지통 기록 제외 · 진행 중은 마지막 날 · 닫힘은 첫날 · entryId 시작 · 날 · 그룹 넘김 · 끝에서 null · 빈 그룹 건너뜀 · n일차 |
| `presentation/diary/viewer/story_viewer_page_test.dart` (23) | `StoryViewerPage` | 머리(이름 · n일차 · 날짜) · 5초 자동 넘김(글 6초 · 영상은 끝에서) · 마지막이면 닫힘 · 영상 실패 · 길이 0 · 탭 이전 · 다음 · 길게 눌러 멈춤 · 가로 스와이프로 다음 스토리 · 아래로 끌어 닫기 · ✕ · ⋮ 휴지통(확인 없이 되돌리기 스낵바) · 위에 화면이 얹히면 멈춤 · **다시 잠겼다 풀리면 이어 감** · 일상 · 모아보기 소스 · 머리 이름 → 스토리 페이지 · 기록이 모두 사라지면 닫힘 · 수정으로 날이 바뀌면 새 날에서 찾음 · 읽기 실패 안내 · 처음 영상에서 이전이면 다시 틂 |
| `presentation/diary/widget/story_ring_row_test.dart` (5) | `StoryRingRow` · `ringOrder` | 진행 중은 최신 기록순 · 빈 것은 뒤 · 닫힘은 종료일 최신순 10개 · ＋ 와 모두 보기 · 탭 · 길게 누르기 · 링 색 · 선택 체크 |
| `presentation/diary/widget/entry_grid_test.dart` (2) | `EntryGrid` | 최신 위 3열 · 영상 ▶ · 여러 장 아이콘 · 글 타일 · 탭 · 슬리버로도 사용 |
| `presentation/diary/widget/feed_view_test.dart` (10) | `FeedView` | 머리(표지 원 · 스토리 · 장소) · 4:5 미디어 · 1/n · 영상은 자동재생 없이 ▶ · 몸통 · 머리 · 태그 탭 · ⋮ · 6줄 대신 3줄 접기 · 더 보기 · 모르는 스토리 |
| `presentation/diary/widget/media_preview_pager_test.dart` (4) | `MediaPreviewPager` | 비어 있으면 ＋ 칸 · 고르기 시트 · 길게 누르거나 ✕ 로 뺌 · 가져오는 중 진행 표시 · 10개면 ＋ 없음 |
| `presentation/diary/widget/tag_chip_input_test.dart` (5) | `TagChipInput` | 완료 · 띄어쓰기로 칩 · 같은 태그 무시 · ✕ · 추천 |
| `presentation/diary/widget/highlighted_text_test.dart` (7) | `matchRanges` · `matchSnippet` | 대소문자 무시 · 한글 · 이모지 · `%` · `_` · `\` · 겹치지 않게 · 긴 본문 자르기 · 이모지를 깨지 않음 · 굵게 |
| `presentation/settings/cubit/diary_settings_cubit_test.dart` (5) | `DiarySettingsCubit` | 잠금 설정 · 보관 기간 · 저장 공간 읽기 · 용량을 못 읽어도 나머지 · 다시 잠기는 시간은 방금 읽은 설정에 얹어 저장 · 보관 기간 |

굵은 항목은 Review Focus(저장 도중 실패 · 같은 태그 · 이모지와 1만 자 · 휴지통 표지 · 잠금 우회)나 리뷰에서 고친 것의 회귀 테스트다
([기록](history.md#2026-10-13--일기)).

### 잠금

| 파일 | 대상 | 확인 |
|---|---|---|
| `domain/lock/lock_policy_test.dart` (14) | `LockPolicy` · `PatternRule` | 4회까지 차단 없음 · 5회째 30초 + 횟수 0 · 30초 뒤 풀림 · 폰 인증 실패 24시간(24시간 - 1초까지) · 성공하면 초기화 · **시계가 거꾸로 가면 남은 시간을 전체로** · 건너뛴 가운데 점(가로 · 세로 · 대각선 · 이미 쓴 점) |
| `domain/lock/relock_timer_test.dart` (8) | `RelockTimer` | 기본 꺼짐 · PIN · 1분 · 즉시 · 30초 · 1분 · 5분 경계 · 미디어 고르는 동안 10분도 안 잠금 · 백그라운드 없으면 안 잠금 · **시계 역행이면 잠금** |
| `data/lock/secret_hasher_test.dart` (4) | `SecretHasher` | salt 16바이트 · 매번 다름 · SHA-256 10,000번 · 상수 시간 비교 |
| `data/lock/prefs_lock_repository_test.dart` (17) | `PrefsLockRepository` | **원문 PIN 이 prefs 어디에도 없음** · 같은 PIN 도 해시 다름 · 검증 · 패턴 순서 · 재시작 뒤 검증 · **실패 횟수 · 차단 해제 시각 재시작 뒤 유지** · **깨진 prefs(해시만 · salt 만 · 타입 다름)는 켜진 채 검증 거절** · 모르는 값은 기본값 |
| `data/lock/local_auth_device_auth_test.dart` (10) | `LocalAuthDeviceAuth` | 화면 잠금 유무 · 기기 PIN 허용 · true 성공 · false 실패 · 사용자 · 시스템 닫힘 · 시간 초과는 취소 · 잠금 없음 → unavailable · 폰 잠김 → lockedOut · 채널 오류 |
| `presentation/lock/cubit/diary_lock_cubit_test.dart` (32) | `DiaryLockCubit` | 시작 상태 · 해제 · 5회째 30초 · 차단 중 맞는 비밀 무시 · 24시간 차단을 30초로 덮지 않음 · **재시작 뒤 차단 유지(30초 · 24시간)** · tick · 폰 인증 성공 → 재설정 · 실패 · lockedOut → 24시간 · 취소 · 쓸 수 없음 · 다시 잠그기(70초 잠김 / 50초 열림 · 미디어 고르는 동안 3분 · 시계 역행 · 꺼짐) · `configChanged` |
| `presentation/lock/cubit/lock_setup_cubit_test.dart` (17) | `LockSetupCubit` | 화면 잠금 없음 · PIN 두 번 · 불일치 · 패턴 3점 · PIN 길이 · 켜져 있으면 현재 비밀 먼저 · 틀린 횟수를 잠금 화면과 같이 · 30초 · 24시간 차단 · 끄기 · 방식 변경 · 재설정은 onSave 로 |
| `presentation/lock/media_pick_guard_test.dart` (3) | `MediaPickGuard` | run 동안만 active · 겹침 · 던져도 풀림 |
| `presentation/lock/widget/diary_lock_gate_test.dart` (9) | `DiaryLockGate` | 꺼짐이면 기록 · **잠기면 기록 위젯이 트리에 없음** · 패턴 · 맞는 PIN · 틀림 · 30초 남은 초 · 24시간 시간 · 분 · 잊어버렸어요 → 폰 인증 → 새 PIN · 쓸 수 없으면 안내 |
| `presentation/lock/widget/pin_pad_test.dart` (5) | `PinPad` | 점 4개 · 4번째에 완료 · 지우기 · 막힘 · 오류 색 |
| `presentation/lock/widget/pattern_lock_test.dart` (6) | `PatternLock` | 연결 · 건너뛴 점 넣기 · 재방문 무시 · 3점 오류 · 막힘 |
| `presentation/lock/widget/lock_secret_input_test.dart` (4) | `lockBlockedMessage` · 패턴 입력 | 차단 아님 null · 30초 올림 · 24시간 시간 · 분 · 패턴은 `-` 로 이어 넘김 |
| `presentation/lock/page/lock_setup_page_test.dart` (6) | `LockSetupPage` | 화면 잠금 없음 안내 · PIN 두 번 → true · 불일치 문구 · **PIN 길이는 PIN 문구** · 패턴 입력 · 현재 PIN 확인 뒤 끄기 |

설정 · 셸 · 앱 시작의 일기 · 잠금 연결은 위 "알람 · 설정 · 셸 — 화면" 표의 `settings_page_test` · `main_shell_page_test` ·
`app_test` 행에, `location` 의존은 걷기 표의 `package_boundary_test` 행에 있다.

### 포크 · 네이티브(JUnit)

| 파일 | 대상 | 확인 |
|---|---|---|
| `test/third_party/alarm/model/alarm_settings_test.dart` | 포크 `AlarmSettings.androidFallbackAudioPath` · `androidSilentWhenRingerMuted` | 기본 null/false · json 왕복 · 키 없는 옛 json 은 null/false · 값이 다르면 다른 설정 · 네이티브로 넘김 · `copyWith` |
| `test/third_party/alarm/alarm_set_test.dart` | 포크 `Alarm.set` | 울리는 알람을 같은 id 로 다시 걸면 `stopAlarm` 없이 네이티브 교체 · 울리지 않으면 먼저 멈춤 |
| `test/third_party/alarm/alarm_stopped_test.dart` | 포크 호스트 울림 · 끔 콜백과 Dart 대체 타이머(`PlatformTimers`) | **백그라운드에서 울리고 알림으로 끈 알람이 앱 복귀 뒤 다시 `ringing` 에 들지 않음 · 울림 소식 없이 끔만 받아도 같음** · 끄기 전에 돌아오면 울림은 한 번 |
| `third_party/alarm/android/src/test/…/services/RingLogTest.kt` | 포크 `RingLog`(울림 기록 저장 형식) | 한 줄 JSON(at · packageId · kind) · 모든 종류의 wire 이름 · 덧붙이기 순서 · 최근 200줄만 · 빈 줄 버림 · 끔은 울리는 알람에만 |
| `third_party/alarm/android/src/test/…/api/AlarmApiImplTest.kt` | 포크 같은 id 다시 걸기 | 이 프로세스가 건 알람 · 예전 프로세스가 건 울리는 알람은 지움 · 새 id 는 그대로 |
| `android/app/src/test/…/NextAlarmWidgetRulesTest.kt` | 앱 `NextAlarmWidgetRules`(홈 화면 위젯) | `pick` 은 지금 뒤 가장 이른 회차(지금과 같으면 뺌) · `dayOf` 오늘 · 내일 · 그 뒤(시간대 따름) · `nextRefreshAt` 은 보이는 회차와 다음 자정 중 이른 것 |
| `test/third_party/alarm/model/alarm_event_test.dart` | 포크 `AlarmMoved.applyTo` | 스누즈는 시각을 옮기고 횟수를 올림 · 한도에 닿으면 다음 울림의 스누즈를 끔 · 플랫폼 거부로 옮긴 것은 시각만 · **호스트가 센 횟수**(wire 값 그대로 · 표식 하나가 여러 번을 대신하면 호스트 값 · 한도 전이면 스누즈 남김 · 같은 표식 두 번 세지 않음 · 횟수 없는 옛 표식은 Dart 가 하나) |
| `third_party/alarm/android/src/test/…/AudioFallbackTest.kt` | 포크 `audioCandidates` · 설정 저장 | 대체음 없음/있음 × 기본음/파일 · 1차와 같은 대체음은 한 번 · 저장 왕복 · 옛 저장값 · 명시적 null · 전달 |
| `third_party/alarm/android/src/test/…/alarm/RingerMuteTest.kt` | 포크 `shouldMuteForRinger` · 설정 저장 | 켰을 때 일반 모드는 소리, 진동 · 무음 모드는 음소거 · 껐으면 모드와 상관없이 소리 · 저장 왕복 · 옛 저장값은 무시 · 전달 |
| `third_party/alarm/android/src/test/…/services/NotificationIconTest.kt` | 포크 `smallIconResId`(알림 작은 아이콘) | 찾은 이름은 그 drawable · **이름 없음 · 못 찾은 이름은 앱(적응형) 아이콘 대신 플랫폼 단색 `ic_lock_idle_alarm`** |
| `third_party/alarm/android/src/test/…/alarm/EngineRegistryTest.kt` | 포크 `EngineRegistry`(`AlarmPlugin.alarmTriggerApi`) | 가장 나중에 붙은 엔진이 현재 · **먼저 붙은 헤드리스 엔진을 내려도 앱 엔진 유지** · 현재 엔진을 내리면 남은 엔진으로 · 마지막을 내리면 없음 · 같은 엔진 다시 붙기 · 모르는 엔진 무시 |
| `third_party/alarm/android/src/test/…/models/SnoozeRuleTest.kt` | 포크 스누즈 횟수 · 한도(`nextAfterSnooze`) | 스누즈는 옮기고 셈 · 한도 없으면 계속 · 한도 3 이면 두 번째까지 스누즈 남고 세 번째 뒤 없음 · 저장 왕복 · 세기 전 옛 저장값은 횟수 · 한도 없음 · wire 전달 · 스누즈 표식이 호스트가 센 횟수를 실음 |
| `third_party/alarm/android/src/test/…/alarm/AutoStopTest.kt` | 포크 자동 멈춤 | 기본 없음 · 10분이면 울림 시작 10분 뒤 · 0/음수는 멈추지 않음 · 저장 왕복 · 옛 저장값은 멈추지 않음 |
| `third_party/alarm/android/src/test/…/models/HostAlarmEventTest.kt` | 포크 호스트 표식(`HostAlarmEvent`) | `toWire` 모든 필드 · 동사 · 원인 매핑 · 저장 형식 왕복 · 디스크의 기존 형식 · **호스트가 센 스누즈 횟수**(wire · 옛 표식은 없음 · 저장 왕복) |
| `android/app/src/test/…/BackgroundQueueTest.kt` | 앱 `BackgroundQueue`(`BackgroundDispatcher`) | 첫 요청은 실행 · 도는 중 같은 일 요청은 끝난 뒤 한 번 더(여러 개는 하나로) · 그 실행 중 요청은 또 한 번 · 쉬면 새 실행 · 취소한 대기자는 받지 않지만 실행은 함 · 지금 실행의 대기자 · 다른 일은 들어온 순서대로 하나씩 · 기다리는 같은 일은 하나로 묶음 |
| `android/app/src/test/…/HeadlessIdleGateTest.kt` | 앱 `HeadlessIdleGate`(`BackgroundDispatcher` 의 `awaitIdle`) | 도는 일이 없으면 바로 답함 · 헤드리스 일이 도는 동안은 기다리고 끝나면(`stopped`) 풀어 줌 · 다음 실행이 메인 엔진이면 풀어 줌 · 다음도 헤드리스면 계속 기다림 · 대기자는 한 번만 풀림 |
| `android/app/src/test/…/ReminderRulesTest.kt` | 앱 `ReminderBook` · `ReminderRules` | `scheduled` 는 울릴 시각 전 걸린 것 · 띄운 것 · 덮어쓰면 shown 해제 · 닫은(shown) 항목은 울릴 시각까지 남고 `remove` · 경과만 지움 · 지난 띄울 시각은 바로 띄움 · **알림 버튼(`onAction`)**: `dismiss` 버튼([울리기])은 알림만 닫고 항목 · shown 유지 · skip 은 Dart 로(항목 그대로) · **울릴 시각이 지난 · 취소된 · 모르는 버튼은 STALE(Dart 에 안 보냄, 지난 항목 지움)** · 띄운 알림은 울릴 시각에 저절로 닫힘(`timeoutAfter`) · 재부팅: 지난 것 버림 · 띄운 것 유지 · 미래는 다시 걺 · 놓친 것은 1분보다 남았을 때만 바로 띄움 |
| `android/app/src/test/…/HolidayCalendarRulesTest.kt` | 앱 `HolidayCalendarRules`(폰 캘린더 휴일) | 구글 한국 휴일 캘린더를 `OWNER_ACCOUNT` · `CAL_SYNC1` · `_SYNC_ID` 로 고름 · official · 영어 피드 · 다른 나라 · 구글 아닌 계정 · 동기화 꺼짐은 id 로 안 고름 · 구글 것이 있으면 이름 규칙 안 씀 · 없으면 이름(대한민국의 휴일 · 공휴일 · Holidays in South Korea) · **이름 규칙은 한국 휴일만(United States holidays · 미국의 휴일 · Holidays in Japan 은 안 고름)** · 이름으로 찾은 캘린더의 설명 없는 일정은 쉬는 날, 기념일은 뺌 · 설명 첫 줄 판정 · 모르는 설명은 official 만 · 종일 공휴일만 날짜 → 이름 · 여러 날 · 같은 날은 먼저 온 이름 · 없으면 null |
| `android/app/src/test/…/CalendarPermissionRulesTest.kt` | 앱 `CalendarPermissionRules`(`READ_CALENDAR` 만 묻는 채널) | 허용이 먼저 · rationale 을 본 적 없으면 거부(대화상자 띄움) · rationale 이 보이면 거부 · 본 뒤 사라지면 영구 거부 · rationale 본 기록은 남음 |
| `android/app/src/test/…/VerifiedReplaceTest.kt` | 앱 `replaceVerified`(기기 알람음 복사) | 임시 파일에 쓰고 검증한 뒤 바꿈 · 기존 복사본 덮어쓰기 · **쓰기 · 검증이 실패하면 기존 복사본은 그대로, 임시 파일만 지움** · 임시 파일은 확장자가 끝 |

굵은 항목은 확인하며 고친 버그의 회귀 테스트다([기록](history.md#알람--확인하며-고친-것)).

### 통근 — 도메인 · 데이터

픽스처(`test/fixtures/commute/*.json`)는 키가 없어 **문서 기준으로 손으로 만든 것**이다. 실제 응답 확인 때 교체하고 파서 · 매핑 테스트를 맞춘다([진행 현황](status.md#통근)).

| 파일 | 확인 |
|---|---|
| `domain/commute/entity/transit_route_test` | 경로 · 구간(지하철/도보) 값, 첫 승차 구간 |
| `domain/commute/commute_policy_test` | 탈 수 있나(걷는 시간 기준: 걸어가면 이번 열차 / 다음 열차 기준 / 두 열차 모두 어려움) · 탈 열차 고르기 · 도착 예상 계산 |
| `domain/commute/subway_line_codes_test` | 노선 → 서울 지하철 ID, 역 이름 정규화 |
| `domain/commute/usecase/commute_use_case_test` | 조회 · 경로 선택(같은 승차역은 재조회 없이 판단만) · 장소 저장 |
| `data/commute/seoul_subway_arrival_source_test` | 서울 실시간 응답 파싱 · 키 오류 · 데이터 없음 · 정렬 · 서버 시각이 앞서도 분이 늘지 않음 · 네트워크(소켓 · TLS)/타임아웃 · 비 2xx → `HTTP <code>` |
| `data/commute/odsay_route_finder_test` | ODsay 경로 파싱 · 키 오류 · 근처 없음 · 오류 분류 · TLS → 네트워크 · 비 2xx → `HTTP <code>` · 모든 경로 해석 실패 → `parse` |
| `data/commute/prefs_place_repository_test` · `prefs_route_preference_repository_test` | 장소 · 경로 선호 저장/복원 |
| `data/commute/geocoding_address_search_test` | 주소 검색 후보 · 실패 |
| `core/config/commute_api_keys_test` · `convention/commute_network_config_test` | 키 주입(`fromEnvironment`) · http/인터넷 권한 설정 |

### 통근 — 화면

| 파일 | 확인 |
|---|---|
| `presentation/commute/cubit/commute_cubit_test` | 방향 전환 시 옛 요청 버림 · 위치 예외 · 조회 · 경로 선택 · 알 수 없는 예외는 타입 이름 · 장소 저장 시 결과 비움(진행 중 요청도 버림) · close |
| `presentation/commute/page/commute_tab_test` | 상태별 화면(미설정 · 키 없음 · 오류 · 경로 없음 · 실시간 없음) · 장소 시트 · 위치 실패가 시트 안에 보임 |
| `presentation/commute/widget/{arrival_card,verdict_banner,route_options_sheet,place_setup_sheet}_test` | 도착 카드 · 판단 배너 · 경로 고르기 · 장소 설정(검색 상태 정리) · 영어 복수형 |

통근 테스트 중 네트워크 · 위치 · 키는 모두 가짜(`RouteFinder` · `SubwayArrivalSource` · `AddressSearch` · `Clock`)다. 실제 API 호출은 아래 시나리오로 본다.

## 테스트가 없는 것

걷기: 당겨서 새로고침 · 이전 기간 넘기기(페이지 수준) · 업데이트 필요 화면 · 기간 읽기 실패 ·
월간 차트의 기간 전환. 코드 검토로는 맞지만 테스트는 없다.

알람: `PackageAlarmScheduler` 의 실제 패키지 호출(`set` · `stop` · `getAlarms` · `checkAlarm`) ·
`MainActivity` 채널 · `AlarmSoundsChannel`(목록 · 미리 듣기 · 복사와 `MediaPlayer` 검증 — 파일 바꾸기 규칙만 JUnit) · `TimeZoneChangedReceiver` ·
`DailyAlarmSyncWorker` · `BackgroundDispatcher`(Kotlin, 대기 규칙만 JUnit) · 포크 `AlarmService` 의 무음 판단 적용(규칙만 JUnit) · 헤드리스 진입점 `alarmResyncMain` 은 단위
테스트하지 않고 아래 에뮬레이터 시나리오로 확인했다. 편집 화면 시각 휠 테스트는 드래그 대신
`onDateTimeChanged` 를 직접 불러 연결만 본다. 볼륨 패널을 끄는 `showSystemUI: false` 는 설정값만
`package_alarm_scheduler_test` 에서 고정하고, 실제로 패널이 뜨지 않는지는 A11 로 본다.
미리 알림 네이티브(`ReminderChannel` · `ReminderAlarms` · `ReminderStore` · 수신기 셋)와 헤드리스 진입점
`alarmReminderActionMain` 도 규칙(`ReminderRules`)만 JUnit 이고 나머지는 에뮬레이터 시나리오(스파이크 R1~R8) 몫이다.
웨이브 4 네이티브도 규칙만 JUnit 이다: 포크 `AlarmService` 의 울림 기록 호출 지점(울림 · 끔 · 자동 멈춤 · 스누즈 — 형식은
`RingLogTest`) · `RingLogChannel` · `WidgetChannel` · `NextAlarmWidgetProvider`(그리기 · 날짜 변경 수신 · 다시 그리기 알람이
`setWindow` 10분 창으로 걸리는지 — `AlarmManager` 호출이라 JUnit 으로 지킬 수 없다) · 위젯 미리보기 레이아웃 · 위젯을
눌러 연 뒤 재개 시 `takeLaunch` 로 알람 탭 열기는 에뮬레이터 시나리오로 본다. 앱이 꺼진 채 알림에서 누른 스누즈는 다음
sync 까지 위젯에 없다(알고 둔 한계, 웨이브 4 스펙 C5).

시각 강화(2026-10-03): `walk_theme` 다크 변형 · `WalkMotion.off` 의 거짓 경로, `WalkSkeleton` · `GoalCelebration` 의 애니메이션 켜진 경로와 햅틱 호출, 링 아래 줄 위젯 단독(`today_goal_footer`), 울림 파동의 런타임 `disableAnimations` 전환은 직접 테스트가 없다. 실제 폰에서 목표 달성 · 축하 · 파동을 확인한다.

일기(2026-10-13): 실제 플러그인 호출 — `flutter_image_compress` · `video_compress`(처리기는 플랫폼 인스턴스를 가짜로) · `geolocator`
(`location` 패키지) · `geocoding` · `local_auth`(채널 결과 매핑만) · `image_picker` · `video_player`(`videoSurface`, 테스트는 가짜 영상 면) —
는 단위 테스트하지 않고 아래 [일기 기기 시나리오](#일기-기기-시나리오--대기)로 본다. drift 의 파일 DB · 실제 앱 문서 폴더도 기기 몫이다.
상태 · 매퍼 · 표 정의처럼 테스트 파일이 따로 없는 `lib/` 파일은 쓰는 쪽(저장소 · cubit · 페이지) 테스트가 덮는다.

## 걷기 기기 시나리오 — 대기

실제 폰(Health Connect 에 헬스 앱 기록이 있는)에서 볼 것. 에뮬레이터는 기록이 없어 ② · ⑥ · ⑦ 만 의미가 있다.

| # | 시나리오 | 기대 | 결과 |
|---|---|---|---|
| ⓪ | 걸음 · 거리 · 활동 칼로리가 Health Connect 에 있는가 | 헬스 앱 숫자와 같음. 활동 칼로리가 없고 총 칼로리만 있으면 칼로리 타입을 다시 정한다 | 대기 |
| ① | 첫 실행 → 권한 허용 | 오늘 걸음이 헬스 앱과 같은 숫자, 권한 창은 한 번만 | 대기 |
| ② | 권한 거부 | 안내 + 권한 허용 + 설정 열기 → 풀림 | 대기 |
| ③ | 주간 · 월간 탭, ‹ 로 지난 기간 | 막대 · 합계 · 일평균이 맞고 날짜가 밀리지 않음, 현재 기간에서 › 꺼짐 | 대기 |
| ④ | 막대 선택 → 홈 → 조금 걷기 → 복귀 | 오늘 걸음 · 선택 줄 갱신 | 대기 |
| ⑤ | 거리 · 칼로리 없는 날 | `–` | 대기 |
| ⑥ | 다크 모드 | 대비 정상 | 대기 |
| ⑦ | 권한 창의 개인정보/사용 내역 링크 | 앱이 두 번 뜨거나 권한 창이 겹치지 않음 | 대기 |

## 알람 기기 시나리오

에뮬레이터 Medium_Phone(Android 17). 실제 폰은 대기.

| # | 시나리오 | 기대 | 결과 |
|---|---|---|---|
| A1 | 알람을 1~3분 뒤로 저장 → 화면 끄고 잠금 | 화면이 켜지고 전체 화면 울림 · 소리 · 진동, [알람 끄기] 로 멈춤 | 통과(09-27 · 09-30) |
| A2 | 재부팅 | 부팅 뒤 패키지 BootReceiver 가 예약 복원, 그 시각에 울림 | 통과(09-27) |
| A3 | 홈 화면(다른 앱 사용 중)에서 울림 | 헤드업 알림에 [알람 끄기] · [5분 뒤 다시 울림], 본문 `오전 12:29` | 통과(09-30) |
| A4 | 헤드업에서 5분 뒤 | 1회성 스위치 켜진 채 · 카드 `5분 후 · 오전 12:34` · 5분 뒤 전체 화면 재울림 | 통과(09-30) |
| A5 | 앱을 띄운 채 울림 → [알람 끄기] | 1회성 스위치가 바로 꺼지고 카드 갱신 | 통과(09-30, 경합 수정 뒤) |
| A6 | 스위치 켜기 · 분 경계 | 카드 · 행 남은 시간 즉시 표시, 매분 0초에 1분 줄어듦 | 통과(09-30) |
| A7 | 앱 종료 상태에서 시간대 서울 → 파리 | 수신기 → 헤드리스 엔진 → 예약이 파리 07:00 으로 이동 | 통과(09-30) |
| A8 | 앱을 띄운 채 시간대 변경 | 헤드리스 없이 메인 엔진 `resync`, 카드 즉시 갱신 | 통과(09-30) |
| A9 | PIN 잠금 위 울림 | 잠금을 풀지 않고 울림 화면이 위에 뜸 | 대기(실제 폰) |
| A10 | 설정: 테마 전환 · 권한 행 → 설정 이동 | 즉시 반영 · 해당 설정 화면 | 테마 통과, 권한 행 대기 |
| A11 | 릴리스 APK 로 앱을 띄운 채 울림 → [알람 끄기] | 울림 화면 · 소리, 시스템 볼륨 패널이 뜨지 않음(울릴 때 · 끌 때) | 통과(10-05, 에뮬레이터 — 울림 8초 · 끈 뒤 `VolumeDialog` 창 없음. 헤드업은 함께 뜸) |
| A12 | 벨소리 모드(소리 · 진동 · 무음) × 무음 모드 체크(켬 · 끔)로 울림 | 체크를 켜고 진동 · 무음 모드면 소리 없이 진동만, 나머지는 소리 + 진동 | 대기 |
| A13 | 앱을 내린 채 `adb shell am broadcast -a com.karma.walk.DEBUG_DAILY_SYNC -p com.karma.walk`(디버그) | 헤드리스 엔진으로 sync 뒤 `finish: headless done`, 14일 창 끝 회차가 채워짐 | 대기 |
| A14 | A13 직후 1~2초 안에 앱을 열고 1분 뒤 알람 → 울림 → 알림의 [알람 끄기] | 헤드리스 엔진을 내린 뒤에도 앱의 울림 화면이 뜨고 끄면 닫힘(포크 `EngineRegistry`) | 대기 |
| A15 | `pm revoke … READ_CALENDAR` 뒤 새 APK → 설정 탭 "공휴일 출처 · 캘린더 허용 필요" 행 → 허용 | 읽기 권한 대화상자가 뜸(쓰기 권한 없이), 허용하면 캐시를 다시 읽고 "캘린더 허용됨" · 휴일 캘린더가 있으면 "폰 캘린더: …" · 콜드 스타트 첫 화면도 최신 출처 | 통과(10-07, 에뮬레이터 — 휴일 캘린더를 지운 상태라 내장 표 · 로컬 "대한민국의 휴일" 캘린더를 넣고 캐시를 지운 콜드 스타트는 첫 화면부터 폰 캘린더) |
| A16 | 오늘 "폰 캘린더: …" 캐시가 있는 채 `pm revoke com.karma.walk android.permission.READ_CALENDAR` → 앱 실행 → 설정 탭 | 다음 날까지 기다리지 않고 바로 "내장 표 2026–2027 · 캘린더 허용 필요"(시작 refresh 가 권한 회수를 보고 캐시를 내장 표 기록으로 바꿈) | 통과(10-07, 에뮬레이터 — 로컬 "대한민국의 휴일" 캘린더) |
| A17 | 앱 프로세스를 내린 채(force-stop 아님) 반복 알람의 30분 전 미리 알림 [이번만 끄기] → 0.2초 안에 앱 실행 | 로그 `awaitIdle: waiting for headless run` → `finish: headless done`, 그 회차는 `skippedAt` 으로 남고 예약 · 다음 알람 카드는 다음 회차 | 통과(10-07, 에뮬레이터 — 오늘 22:45 회차 건너뜀, 카드 "내일 (목) 오후 10:45") |
| A18 | 앱 프로세스가 살아 있는 채 홈 화면 → 1분 뒤 한 번 알람 → 헤드업 [알람 끄기] → 런처로 앱 열기 | 꺼진 알람의 울림 화면이 다시 뜨지 않고 알람 탭이 보임(포크 콜백이 Dart 대체 타이머를 지움) | 통과(10-08, 에뮬레이터 — 고치기 전엔 복귀 ~1초 뒤 `ringing` 에 다시 들어 울림 화면이 떴음) |
| A19 | [알람 쉬기] 오늘만 → 한 번 알람 +5분 저장 | 스낵바 `쉬는 기간이라 울리지 않아요`, 행 `한 번 · 쉬는 중` | 통과(10-08, 에뮬레이터) |

## 일기 기기 시나리오 — 대기

설계 §9.7 의 9개(D1~D9)에, 단위 테스트 · 에뮬레이터 스파이크로 확인하지 못한 것(D10~D15)을 더했고, 2026-10-21 화면 재기획의 기기 확인(D16~D18)을 더했다([설계](../../../docs/superpowers/specs/2026-10-21-walk-diary-story-redesign-design.md)). 재기획으로 D2 · D8 · D13 · D15 의 기대 화면이 바뀌어 재확인 대기다. 에뮬레이터에서는
`geocoding` 이 응답하지 않을 수 있어 장소 이름(D3 · D10)은 실제 폰에서도 본다.

| # | 시나리오 | 기대 | 결과 |
|---|---|---|---|
| D1 | 갤러리 사진 3장 첨부 → 저장 | 사본 긴 변 ≤ 1600px · EXIF GPS 없음 · 갤러리 원본 그대로 | **통과**(에뮬레이터, 2026-10-13): 4000×3000 → 1600×1200 · 3000×4000 → 1200×1600 · 1000×800 그대로, 사본 EXIF 0개, 원본 md5 불변. **발견**: `image_picker` 가 고른 원본을 앱 `cache/<uuid>/` 에 GPS 포함 그대로 복사해 두고 지우지 않음 → **고침**(`1c57f67`): 가져오기가 끝나면 앱 캐시 안의 복사본만 지운다 · **재확인(에뮬레이터, 2026-10-13, `f13bee2`)**: 다시 고른 뒤 `cache/` 에 새 복사본이 남지 않음, 작성 취소 시 `diary/tmp` 도 비워짐 |
| D2 | 40초 영상 첨부 / 25초 영상 첨부 | 거절 안내 / 720p 압축 · 뷰어에서 재생 | **재확인 대기(화면 재기획)** — 기대를 뷰어 기준으로 바꿈. 이전 결과: **통과**(에뮬레이터, 2026-10-13): 40.01초 → "30초 이하 영상만 넣을 수 있어요" 스낵바 · 0/10 그대로. 24.99초 1080×2400(6.83MB) → 576×1280 · 25.0초 · 2.4MB, 압축 약 24초 · 썸네일 생성, 릴스에서 재생(프레임 변화 확인). **발견(경미)**: 압축 중 `사진·영상 추가` 버튼 안의 진행 표시가 잘려 보임 → **고침**(`d5956c6`) |
| D3 | 비행기 모드에서 기록 → 연결 후 일기 탭 | 장소 이름 없음 → 채워짐 | **에뮬레이터 판정 불가**(2026-10-13): 온라인에서도 역지오코딩 이름이 오지 않아 "이름 없는 위치"(좌표만 저장)로 남음 → 실제 폰에서 D10 과 함께 |
| D4 | 잠금(1분) → 홈 → 50초 / 70초 뒤 복귀 | 열림 / 잠김 | **통과**(에뮬레이터, 2026-10-14): 일기 잠금 PIN · 1분 설정 → 홈 50초 뒤 복귀 열림 / 70초 뒤 복귀 잠김. 잠긴 동안 ＋ 숨김 |
| D5 | 즉시 설정에서 사진 고르는 중 3분 | 잠기지 않음 | **통과**(에뮬레이터, 2026-10-14): "바로" 설정에서 작성 화면 → 앨범 고르기 화면에 3분 머문 뒤 돌아와도 열림. 대조: 홈 갔다 오면 즉시 잠김(작성 화면 위에도 잠금) |
| D6 | 폰 인증 실패 → 앱 재시작 | 24시간 차단 유지 | **부분 통과**(에뮬레이터, 2026-10-14): 틀린 PIN 5회 → "29초 뒤에 다시 시도할 수 있어요" · 키패드 · 잊어버렸어요 비활성. 잊어버렸어요 → 폰 인증 **성공** → 잠금 방식 다시 고르기 → 새 PIN 등록 → 열림(2회). 폰 인증 **실패 → 24시간 차단 · 재시작 유지**는 두 번 모두 인증이 성공해 기기에서 미확인(규칙은 `diary_lock_cubit_test` · `lock_policy_test` 가 확인) |
| D7 | 삭제 → 휴지통 1일 → 시계 다음 날 → 일기 탭 | 행 · 파일 모두 사라짐 | **통과**(에뮬레이터, 2026-10-13): 설정 보관 기간 1일 → 기록 삭제 → 시스템 시계 대신 앱 DB 의 `deleted_at` 을 이틀 전으로 바꿔 넣음 → 일기 탭 진입 → `entries` · `media` 행과 사진 파일 모두 삭제, 다른 기록 파일 유지 |
| D8 | 삭제 → 복원 | 사진 · 영상이 피드 · 뷰어에서 그대로 보이고 재생 | **재확인 대기(화면 재기획)** — 이전 결과(릴스 · 상세 기준): **통과**(에뮬레이터, 2026-10-13): 영상 기록 상세 ⋮ → 삭제 → 확인 → 피드에서 사라짐 · 파일 유지 · 휴지통 "7일 남음" → 복원 → 원래 시각 자리로 돌아옴, 미디어 5개 파일 md5 삭제 전과 동일, 피드 · 릴스 재생 확인. **발견(경미)**: 스낵바가 + 버튼을 가림 · 휴지통 행에 썸네일 없음 → **고침**(`346cef4` ＋ 를 셸 Scaffold 로 · `06e19b9` 썸네일) |
| D9 | 일기 잠금 중 알람 울림 | 울림 화면 정상 | **통과**(에뮬레이터, 2026-10-14): 일기 잠긴 채 한 번 알람 → 전체 화면 울림 화면 정상 표시 · 알람 끄기 뒤 일기는 계속 잠김 |
| D10 | 위치를 켜고 새 기록(실제 폰, 도시 · 동네 몇 곳) | `Placemark` 의 `locality` · `subLocality` · `thoroughfare` 중 무엇이 채워지는지 기록, 장소 이름이 "시 동"처럼 읽힘 | 대기 |
| D11 | EXIF 회전 값이 있는 세로 JPEG(폰으로 세로 촬영) 첨부 | 사본이 바로 선 방향 · **긴 변**(세로)이 1600 이하 | **통과**(에뮬레이터, 합성 JPEG 4000×3000 + Orientation=6, 2026-10-13): 사본 1200×1600 · 표식이 오른쪽 위(바로 선 방향) · 회전 태그 제거, 상세 화면도 바로 섬. 실제 폰 촬영본은 미확인 |
| D12 | HEIC 원본 첨부 | 오류 없이 JPEG 사본, 갤러리 원본 그대로 | 대기 |
| D13 | 세로로 찍은 영상 첨부 | 압축본이 세로 비율 그대로(눕지 않음) · 뷰어에서 비율 맞게 재생 | **부분 통과**(에뮬레이터, 2026-10-13): 화면 녹화 1080×2400 → 576×1280, 에뮬레이터 카메라 5초 → 720×1280 · 변환 행렬 단위(세로 그대로). 회전 메타데이터가 붙는 실제 폰 세로 영상은 미확인 |
| D14 | `image_picker` 앨범 여러 장 고르기 · 카메라 사진 · 카메라 영상 | 고르기 화면이 뜨고 남은 칸만큼 들어옴, 카메라에 다녀와도 잠기지 않음 | **부분 통과**(에뮬레이터, 2026-10-13): 앨범 3장 다중 선택 · 카메라 사진 · 카메라 영상(5초) 모두 들어옴. 잠금 예외는 기기 화면 잠금이 없어 미확인(D4~D6 과 함께) |
| D15 | 태그 · 장소 모아보기를 릴스로 보기 | 모아보기 화면 안에서 릴스가 화면을 채우고 넘기기 · 영상 재생 · 위 화면이 얹히면 멈춤 | **부분 통과**(에뮬레이터, 2026-10-13): 검색 해시태그 탭 `#jeju 기록 2개` → 모아보기 → 릴스, 세로 넘기기 동작. 머리줄 아래에 그려져 꽉 채우지는 않음 · 카메라 영상이 정지 장면이라 재생 여부는 화면 비교로 판정 못 함. **발견(경미)**: 밝은 영상 위 릴스 하단 시각 글자 대비 낮음 → **고침**(`a887c15`): 글 뒤 전체에 그늘 |

## 통근 기기 시나리오 — 대기

키(`config/commute_keys.json`)가 있어야 한다. 실행: `flutter run --dart-define-from-file=config/commute_keys.json`.

| # | 시나리오 | 기대 | 결과 |
|---|---|---|---|
| C1 | curl 로 장승배기 실시간 · ODsay 장승배기 → 강남역 녹화 | `barvlDt`(7호선 · 신분당선) · `ordkey` · `updnLine`↔`wayCode` · `subwayCode` 109 · `way` · https 확인, 픽스처 교체 | 대기 |
| C2 | 에뮬레이터에서 조회(Android 키) | ODsay 가 앱 키로 응답. 막히면 서버/웹 키 → 카카오 `publictraffic` | 대기 |
| C3 | 장소 미설정 → 현재 위치/주소로 집 · 회사 설정 | 안내 → 설정 시트 → 저장 | 대기 |
| C4 | 출근 조회 → 다른 경로 고르기 → 탭 재진입 | 판단 · 예상 표시, 같은 경로가 기본 | 대기 |
| C5 | 퇴근 조회 | 방향이 바뀐 경로 · 도착 | 대기 |
| C6 | 비행기 모드에서 조회 | 네트워크 오류 안내 | 대기 |
| C7 | 조회 2분 뒤 | 낡음 표시 | 대기 |
| C8 | 실제 폰으로 출근길 비교 | 도착 예상이 실제와 맞음 | 대기 |
| D15 | 태그 · 장소 모아보기 그리드 → ▶ 보기 | 그리드에서 칸 탭 · ▶ 보기로 뷰어가 열리고 넘기기 · 영상 재생 · 위 화면이 얹히면 멈춤 | **부분 통과**(에뮬레이터, 2026-10-22): 피드 `#jeju` 칩 → 모아보기 `기록 2개` · ▶ 보기 · 3열 그리드 → ▶ 보기로 `#jeju` 머리 뷰어가 열림. 칸 탭 · 위 화면 얹힘 멈춤은 단위 테스트로만 확인. 이전(릴스 기준) 결과는 역사로: 2026-10-13 부분 통과 |
| D16 | 일기 탭 동그라미 → 스토리 뷰어 | 진행 중 스토리는 마지막 날 첫 조각부터, 5초(글 6초 · 영상은 끝)마다 자동 넘김 · 오른쪽 탭 다음 · 왼쪽 탭 이전 · 길게 누르면 멈춤 · 가로 스와이프로 다음 스토리 · 아래로 끌기 · ✕ 로 닫힘 · 머리 이름 → 스토리 페이지 | **통과**(에뮬레이터, 2026-10-22): 진행 중 '일상'이 마지막 날(10/22)부터 · 사진 5초 뒤 영상으로 자동 넘김 · 오른쪽/왼쪽 탭 · 길게 누르면 머리 · 글이 숨고 멈춤 · 아래로 끌어 닫힘 · 이름 → 스토리 페이지 → 뒤로 뷰어. 새 스토리를 만들어 링 순서(방금 올린 스토리가 맨 앞) · '1일차' 머리 · 가로 스와이프로 다음 스토리(일상, 마지막 날부터)도 확인. ▶ 대비 수정 뒤 피드 ▶ 가 잘 보임. **발견**: 피드 · 그리드의 영상 ▶ 표시가 작고 어두워 안 보임 → **고침**(`52211e94`) |
| D17 | ＋ → 시트(앨범 · 카메라 · 글만 쓰기) → 작성 → 스토리 동그라미 고르기 → 올리기 | 사진부터 고르고 어느 스토리에 올릴지 동그라미로 정함, 올린 기록이 피드 맨 위와 그 스토리 뷰어에 나옴 · 카메라에 다녀와도 잠기지 않음 | **통과**(에뮬레이터, 2026-10-22): ＋ → 시트 4항목 → 앨범에서 고르기 → 작성 화면(큰 미리보기 · 다음 칸 `사진·영상 추가 1/10` · '어디에 올릴까요?' 일상 체크) → 올리기 → 스낵바 '일상에 올렸어요' · 피드 맨 위 '지금' · 동그라미 표지 갱신 · 뷰어 첫 조각. ＋ → 사진 찍기 → 카메라 촬영 → 돌아와도 잠기지 않음(다시 잠김 '바로' 설정), 시각에 맞는 진행 중 스토리가 자동 선택 → 'Busan trip에 올렸어요'. **발견(경미)**: 올린 직후 동그라미를 누르면 그 스낵바가 뷰어 위에도 남음 |
| D18 | 스토리 페이지 · 모든 스토리 · 휴지통 | 동그라미 길게 누르기 · 모두 보기 · ⋮ 모든 스토리로 열림 · 스토리 페이지 ⋮ 이름 · 표지 · 닫기 · 다시 열기 · 삭제 · 뷰어 ⋮ 휴지통 → 되돌리기 스낵바로 복원 | **부분 통과**(에뮬레이터, 2026-10-22): 모두 보기 → 모든 스토리(진행 중 카드) · 스토리 페이지(표지 · 기간 · 기록 · 사진 수 · 처음부터 보기 · 3열 그리드, 영상 ▶ · 여러 장 아이콘) · 뷰어 ⋮(수정 · 스토리 옮기기 · 휴지통으로) → 확인창 없이 휴지통 + '되돌리기' 스낵바, 그날이 비어 뷰어 닫힘. 동그라미 길게 누르기 → 스토리 페이지 ⋮(이름 · 표지 · 닫기 · 삭제) → 삭제 확인 → 페이지가 닫히고 동그라미 · 피드에서 사라짐. 되돌리기 누르기 · 닫기 · 다시 열기는 단위 테스트로만 확인. **발견(공통 위젯, 범위 밖)**: 스낵바 '되돌리기' 글자 대비가 낮음 |
