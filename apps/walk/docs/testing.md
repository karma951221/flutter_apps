# walk 테스트

> [테스트 가이드](../../../docs/testing/README.md) · [계획](plan.md) · [기록](history.md) · [진행 현황](status.md)

```bash
cd apps/walk && flutter test   # 도메인 · 데이터 · cubit · 위젯 · 경계 (2026-10-03 기준 344건 통과 · 1건 skip)
```

백엔드가 없어 로컬 Supabase 없이 돈다. Health Connect 는 `HealthGateway` 를 mock 해서 본다
— `HealthPluginGateway`(플러그인 호출 자체)는 단위 테스트하지 않고 기기에서 확인한다. 알람은
`AlarmScheduler` 를 가짜(`_FakeScheduler`)로, 시간은 `Clock` 을 주입해서 본다 — `alarm` 패키지 호출과
Kotlin 수신기는 에뮬레이터로 확인한다.

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
| `convention/package_boundary_test.dart` | `pubspec.yaml` | `feature_*` · `supabase_flutter` 의존 없음 |

걷기 표의 굵은 항목은 최종 리뷰에서 고친 것의 회귀 테스트다([기록](history.md#2026-09-27--최종-리뷰에서-고친-것)).

### 알람 — 도메인 · 데이터

| 파일 | 대상 | 확인 |
|---|---|---|
| `domain/alarm/entity/alarm_test.dart` | `Alarm` · `Weekday` | JSON 왕복(1회성 `oneShotAt` 은 로컬 시각 그대로) · `fromJson` 기본값 · 깨진 값은 던짐(저장소가 건너뜀) · `draft` |
| `domain/alarm/entity/alarm_trigger_test.dart` | `packageId` · `triggerIndex` | `alarmId * 100 + index` 왕복 · 날짜 index 는 14일 안에서 겹치지 않음 |
| `domain/alarm/upcoming_triggers_test.dart` | `upcomingTriggers` · `nextOccurrence` · `triggersOf` | 꺼짐 · 반복 요일만 오름차순 · 오늘 지남/아직 · `now` 와 같은 시각 제외 · 자정 · 14일 경계 포함/제외 · 월말 · 연말 · 윤년 · 1회성 · 서머타임(skip 조건부) |
| `domain/alarm/permission/alarm_permissions_test.dart` | `AlarmPermissions` | 알림 → 정확한 알람 순서 · `canRing` 은 둘 다 허용일 때만 |
| `domain/alarm/usecase/alarm_use_case_test.dart` | `DefaultAlarmUseCase` | **save**(새 id · 최대 id/9999 가득 · 1회성 `oneShotAt` · 14일 예약 · 수정 시 예전 회차(5분 안 · 스누즈 포함) 정리) · **toggle** · **delete** · **sync**(빠진 회차 걸기 · 남은 것 취소 · 멱등(스누즈 · 울림 있어도) · 1회성 만료 · **스누즈 중 1회성 유지** · **막 된 1회성 유지** · **꺼진 알람의 5분 안 예약 취소** · 울리는 회차 보존 · 스누즈 보존 창 경계 · 자정 넘은 스누즈 · 시간대 변경 재설정) · **snooze/stop**(5분 뒤 · **꺼진/지운 알람은 멈춤** · **stop 도중 읽어도 꺼진 1회성**) · **nextRings**(알람별 최솟값 · 스누즈 포함 · 지난 것 · 꺼짐 · 예약 없음) · `timeZoneChanged` · 직렬 줄이 실패 뒤에도 풀림 |
| `data/alarm/package_alarm_scheduler_test.dart` | `PackageAlarmScheduler.settingsFor` | 스펙 §5 설정(반복 재생 · 전체 화면 · 스와이프해도 계속 · 5분 스누즈) · 기본 제목 · 본문은 기기 언어 시각 · 버튼 문구(ko/en/ja) |
| `data/alarm/prefs_alarm_repository_test.dart` | `PrefsAlarmRepository` | 없음 · 왕복 · 비우기 · **깨진 JSON/배열 아님/항목 하나 깨짐/문자열 아님 → 던지지 않고 읽을 수 있는 것만, 원본은 `walk.alarms.corrupt`** · 백업 덮어쓰기 · 정상 저장 복구 |
| `data/alarm/full_screen_intent_permission_source_test.dart` | 전체 화면 알림 채널 | `canUse` true/false · 요청은 설정을 열고 다시 읽음 · 채널 없으면 허용 |
| `data/alarm/permission_handler_source_test.dart` | `permission_handler` 래퍼 | 상태 매핑 |
| `data/settings/prefs_settings_repository_test.dart` | `PrefsSettingsRepository` | 없음/저장/모르는 값 → 시스템 · **문자열 아닌 값 → 시스템** · 목표 · 축하일 왕복 · 깨진 값 기본/clamp · 축하일 null 은 키 삭제 · **저장 도중 읽어 다시 저장해도 앞선 목표 유지** |
| `data/app_info/app_info_source_test.dart` | `PackageInfoAppInfoSource` | `이름 (빌드번호)` |

### 알람 · 설정 · 셸 — 화면

| 파일 | 대상 | 확인 |
|---|---|---|
| `presentation/alarm/format/alarm_format_test.dart` | `AlarmFormat` | 분 올림 · 시간/일 · `N 후` 표(스펙 §4.3) · 단위 경계 · 음수 → 1분 · **1초 미만 자투리 올림** · 오늘/내일/월일 · 자정 · 달/해 넘김 · `earliest` 동률은 작은 id · 반복 요약 · 기기 언어 시각 |
| `presentation/alarm/cubit/alarm_list_cubit_test.dart` | `AlarmListCubit` | load(목록 · `nextAt` · `now` · 권한) · **읽기 실패 → failure(던지지 않음)** · 권한/다음 울림 실패에도 목록 · 다시 load · `tick` 은 저장소를 안 읽음 · 회차 지나면 다시 읽음 · 토글(낙관적 반영 · 권한 · 남은 시간 · **권한 예외여도 성공** · 실패 시 되돌림 · **저장+재읽기 실패 → failure**) |
| `presentation/alarm/cubit/alarm_edit_cubit_test.dart` | `AlarmEditCubit` | isNew · 값 바꾸기 · 저장 → 권한(거부돼도 계속) → 남은 시간 · **권한 예외여도 저장 성공** · 저장 실패면 권한 안 물음 |
| `presentation/alarm/cubit/alarm_ringing_cubit_test.dart` | `AlarmRingingCubit` | 회차의 알람 찾기 · snooze · stop |
| `presentation/alarm/page/alarm_list_page_test.dart` | `AlarmListPage` | 빈 상태(카드 숨김) · 요약 카드(가장 이른 알람 · 동률 · 모두 꺼짐 · **켜졌는데 예약 없음 → 예약 없음 · 권한 안내, 배너가 위**) · 행(켜진 것만 남은 시간 · 꺼진 행 흐림) · 스위치 켜기/끄기 → 카드 · 행 갱신 · 실패 되돌림 + 스낵바 · 자정 tick · 행 탭 → 편집 → 스낵바 · 카드 누를 수 없음 · 분 경계 타이머(0초 · 가려지면 건너뜀) · 읽기 실패 → 다시 시도 · 권한 배너 → 설정 탭 · FAB |
| `presentation/alarm/page/alarm_edit_page_test.dart` | `AlarmEditPage` | 저장 흐름 · 실패 스낵바 · **권한 실패여도 닫히고 중복 저장 없음** · 저장 중 잠금 · 휠 값 저장 · 기존 알람 id · 라벨 유지 · 삭제 확인 · 320dp 요일 한 줄 |
| `presentation/alarm/page/alarm_ringing_page_test.dart` | `AlarmRingingPage` | 시각 · 라벨 · 뒤로가기 막힘 · 기본 제목 · 끄기/5분 뒤 후 닫힘 · 리스너가 먼저 걷어도 아래 화면 유지 · 320dp 버튼 문구(ko/en/ja) |
| `presentation/settings/cubit/*_test.dart` | 테마 · 권한 · 앱 정보 cubit | 저장된 테마로 동기 시작 · 선택 즉시 반영/저장 · 네 권한 읽기 · 알림 다시 묻기/설정 · 정확한 알람 · 전체 화면 · Health Connect 요청/설정/스토어 · 버전 |
| `presentation/theme/walk_theme_test.dart` | `WalkTheme` · `WalkMotion` | 초록 시드 · 애니메이션 끄기 읽기 |
| `presentation/alarm/widget/alarm_summary_card_test.dart` | `AlarmSummaryCard` | 초록 컨테이너 색 · 남은 시간 색 · 시간이 바뀌면 `AnimatedSwitcher` |
| `presentation/alarm/widget/alarm_tile_test.dart` | `AlarmTile` | 꺼진 알람 글자색 · 꺼져도 행 탭 동작 · 스위치 햅틱 후 `onToggle` |
| `presentation/alarm/widget/ringing_ripple_test.dart` | `RingingRipple` | 켜면 위상이 변함 · 애니메이션 제거면 정지 |
| `presentation/settings/widget/step_goal_sheet_test.dart` | `StepGoalSheet` | 슬라이더 2,000~30,000 · 1,000 단위 · 저장하면 값 반환 |
| `presentation/settings/page/settings_page_test.dart` | `SettingsPage` | 걷기 섹션 · 하루 목표 시트 → 저장 · 권한 상태 · 버전 · 안내 · 행 탭별 동작 · 확인 중이면 빈 문구 · 테마 선택 · 라이선스 페이지 |
| `presentation/shell/page/main_shell_page_test.dart` | `MainShellPage` | 첫 탭 걷기 · 초록 컨테이너 · 선택 탭 채움 아이콘 · 탭 전환 · 시작/복귀 때 sync 뒤 목록 · 복귀 때 권한 행 · **울림 화면이 걷히면 sync** · **sync 실패해도 목록** · 네이티브 `resync` → 재설정 · 목록 · 응답(실패해도) · 사라지면 핸들러 해제 · **설정 탭에서 목표를 낮춰 달성해도 걷기 탭을 열 때 한 번 축하** |
| `core/alarm_ring_listener_test.dart` | `AlarmRingListener` | 한 번만 띄움 · 밖에서 끄면 걷음 · 화면이 먼저 닫힘 · 스누즈 뒤 다시 띄움 · 가려진 화면만 걷음 · 내비게이터 전 값 · 첫 프레임 전 시작→끝이면 안 띄움 · 중복 start · dispose |
| `core/app_test.dart` | `WalkApp` · `themeModeOf` | 테마 매핑 · 저장된 다크로 첫 프레임 |
| `core/background/alarm_resync_test.dart` | `runAlarmResync` | init → sync → done · init 실패면 sync 건너뛰고 done · sync/done 실패도 삼킴 · done 한 번 |

굵은 항목은 확인하며 고친 버그의 회귀 테스트다([기록](history.md#알람--확인하며-고친-것)).

## 테스트가 없는 것

걷기: 당겨서 새로고침 · 이전 기간 넘기기(페이지 수준) · 업데이트 필요 화면 · 기간 읽기 실패 ·
월간 차트의 기간 전환. 코드 검토로는 맞지만 테스트는 없다.

알람: `PackageAlarmScheduler` 의 실제 패키지 호출(`set` · `stop` · `getAlarms` · `checkAlarm`) ·
`MainActivity` 채널 · `TimeZoneChangedReceiver`(Kotlin) · 헤드리스 진입점 `alarmResyncMain` 은 단위
테스트하지 않고 아래 에뮬레이터 시나리오로 확인했다. 편집 화면 시각 휠 테스트는 드래그 대신
`onDateTimeChanged` 를 직접 불러 연결만 본다. 볼륨 패널을 끄는 `showSystemUI: false` 는 설정값만
`package_alarm_scheduler_test` 에서 고정하고, 실제로 패널이 뜨지 않는지는 A11 로 본다.

시각 강화(2026-10-03): `walk_theme` 다크 변형 · `WalkMotion.off` 의 거짓 경로, `WalkSkeleton` · `GoalCelebration` 의 애니메이션 켜진 경로와 햅틱 호출, 링 아래 줄 위젯 단독(`today_goal_footer`), 울림 파동의 런타임 `disableAnimations` 전환은 직접 테스트가 없다. 실제 폰에서 목표 달성 · 축하 · 파동을 확인한다.

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
