# walk — 기상 알람 · 설정 탭 설계

> 작성 2026-09-27 · 상태: **구현 중** · 앱 문서 [walk 허브](../../../apps/walk/docs/README.md) ·
> 선행 설계 [walk 만보기](2026-09-27-walk-app-design.md)

## 1. 목적

만보기만 있는 `apps/walk` 에 **기상용 알람**과 **설정**을 더해 하단 탭 세 개
(알람 · 걷기 · 설정) 앱으로 만든다. 알람은 걸음과 관계없는 일반 기상 알람이다.
안드로이드만, 백엔드 없음.

사용자 방침(2026-09-27): "일단 다 만들어 보고 완성본을 보며 고친다." 세부 UX 는 이 문서의
기본안으로 만들고 완성본 리뷰에서 바꾼다.

## 2. 결정 기록

| 결정 | 이유 |
|---|---|
| 새 앱이 아니라 `apps/walk` 를 고쳐 쓴다. 폴더 · 패키지명 `walk` 유지, 표시 이름만 "걷기·알람" | 사용자 결정. 이름 변경은 파급이 커서 라벨만 바꾼다 |
| 알람은 걸음과 연동하지 않는다 | 사용자 결정 — "진짜 기상할 때 쓰는 알람" |
| v1 알람 기능: 여러 개 · 시각 · 반복 요일 · 켜기/끄기 · 라벨 · 진동 켜기/끄기 · 스누즈 · 잠금화면 위 울림 · 재부팅 후 유지 | 사용자 선택. 알람음 선택은 제외(기본음 하나) |
| 스누즈 5분 고정 | 설정 탭에 간격 항목을 넣지 않기로 함 |
| 울림은 [`alarm`](https://pub.dev/packages/alarm) 패키지 | 정확한 예약 · 반복 재생 · 진동 · 전체 화면 알림 · 스누즈 버튼 · 잠금화면 Activity 를 제공한다. `flutter_local_notifications` 는 알림 채널 소리라 기상용으로 약하고, 네이티브 직접 구현은 작업량이 크다(패키지로 모자라면 그때) |
| 반복 알람은 **앞으로 14일 안의 회차를 모두 미리 예약**하고 앱이 열릴 때마다 채운다(§5) | 패키지는 1회성만 알고, 앱이 꺼진 채 알림에서 끄면 Dart 코드가 돌지 않아 "울릴 때 다음 회차 예약"이 빠질 수 있다 |
| 알람 정의 저장은 `shared_preferences` JSON | 알람 수십 개 수준. DB 불필요 |
| 탭 셸은 `NavigationBar` + `IndexedStack`, 라우터 없음 | 탭 전환 시 걷기 탭 상태 유지. 푸시 화면은 편집 · 울림 둘뿐 |
| 시각 입력은 화면 안 스크롤 휠(`CupertinoDatePicker` time 모드) | 알람 앱 관례. 공통 위젯에 대응물이 없어 예외로 직접 쓴다 |
| 권한은 알람을 처음 저장/켤 때 요청. 거부해도 저장하고 경고 배너 | 앱 시작 시 권한 폭탄을 피한다 |
| 설정 탭: 권한 상태 모아보기 · 테마(시스템/라이트/다크) · 앱 정보 | 사용자 선택 |
| 기존 walk 코드를 `walk/` 하위 폴더로 옮긴다(이동만 하는 커밋 분리) | 한 앱에 기능이 셋이 되므로 계층 아래 기능 폴더를 둔다 |

## 3. 구조

```
lib/
  main.dart                 Alarm.init → configureDependencies → runApp
  core/
    app.dart                MaterialApp(themeMode ← SettingsCubit, navigatorKey, home: MainShellPage)
    di/injection.dart
    alarm_ring_listener.dart  Alarm.ringing 구독 → AlarmRingingPage push, 울림 뒤 sync
  domain/
    clock.dart              (공유)
    walk/…                  기존 entity · repository · usecase
    alarm/
      entity/alarm.dart           Alarm, Weekday
      entity/alarm_trigger.dart   (packageId, alarmId, at)
      upcoming_triggers.dart      순수 함수
      repository/alarm_repository.dart   Future<List<Alarm>> load(); save(List<Alarm>)
      scheduler/alarm_scheduler.dart     인터페이스(§5)
      usecase/alarm_use_case.dart        list · save · delete · toggle · sync · snooze · stop
    settings/
      entity/app_settings.dart    themeMode
      repository/settings_repository.dart
  data/
    walk/…                  기존 health 파일
    alarm/
      prefs_alarm_repository.dart
      package_alarm_scheduler.dart   alarm 패키지 래퍼
      notification_permission_source.dart
      exact_alarm_permission_source.dart
      full_screen_intent_permission_source.dart
    settings/prefs_settings_repository.dart
    app_info/app_info_source.dart   package_info_plus
  presentation/
    shell/main_shell_page.dart
    walk/…                  기존 page · widget · cubit · format
    alarm/  cubit(alarm_list, alarm_edit, alarm_permission) · page(list, edit, ringing) · widget · format
    settings/ cubit(settings, permission_overview) · page · widget
```

- 새 의존성: `alarm`, `shared_preferences`, `permission_handler`, `package_info_plus`.
- 문자열은 `packages/l10n` arb 에 `walkAlarm*` · `walkSettings*` · `walkShell*` 접두사.

## 4. 도메인

```dart
enum Weekday { mon, tue, wed, thu, fri, sat, sun }   // DateTime.weekday 1..7 과 대응

@freezed
class Alarm with _$Alarm {
  final int id;            // 1..9999, 저장소가 부여(최대+1)
  final int hour;          // 0..23
  final int minute;        // 0..59
  final Set<Weekday> repeat;  // 비면 1회성
  final String label;      // 빈 문자열 = 라벨 없음
  final bool vibrate;
  final bool enabled;
  final DateTime? oneShotAt;  // 1회성일 때 켤 때 정한 울릴 시각. 반복이면 null
}
```

- **1회성의 울릴 시각**은 켜는(저장/토글) 순간 `now` 기준 다음 `hour:minute` 로 정해
  `oneShotAt` 에 저장한다. 그래야 "시각이 지났으면 자동으로 끔"을 판단할 수 있다.
- `upcomingTriggers(Alarm, DateTime now, {Duration window = 14일})` →
  `List<DateTime>` (오름차순, `now` 보다 뒤, `now + window` 이하).
  - 꺼진 알람 → 빈 목록.
  - 1회성 → `oneShotAt` 가 `now` 뒤면 `[oneShotAt]`, 아니면 빈 목록.
  - 반복 → 오늘부터 14일의 각 날짜 중 요일이 맞고 시각이 `now` 뒤인 것.
  - 날짜 산술은 `DateTime(y, m, d + n, hour, minute)` 생성자로(DST · 월말 안전).
- `packageId(alarmId, index) = alarmId * 100 + index` (index 0..99).
- `nextTrigger(alarms, now)` — 켜진 알람 전체의 가장 이른 회차. 목록 머리 "다음 알람까지".

## 5. 예약 동기화

```dart
abstract interface class AlarmScheduler {
  Future<Set<int>> scheduledIds();                    // 패키지에 걸린 id
  Future<void> schedule(int packageId, DateTime at, Alarm alarm);  // 같은 id면 덮어씀
  Future<void> cancel(int packageId);
  Future<void> stop(int packageId);                   // 울리는 중 끄기
}
```

`AlarmUseCase.sync(now)`:

1. 저장된 알람을 읽는다.
2. 1회성인데 켜져 있고 `oneShotAt <= now` 면 `enabled = false` 로 저장한다.
3. 원하는 예약 = 켜진 각 알람의 `upcomingTriggers` → `packageId` 맵.
4. `scheduledIds()` 와 비교해 원하는 것은 `schedule`(시각 · 설정이 바뀌었을 수 있으므로
   원하는 것은 모두 다시 건다 — 패키지가 같은 id 를 덮어쓴다), 원하지 않는 id 는 `cancel`.
   단, **지금 울리는 중인 id 는 건드리지 않는다**(`Alarm.isRinging`).
5. 멱등이다.

호출 시점: 앱 시작 · 백그라운드 복귀(`AppLifecycleListener.resumed`) · 알람 저장/삭제/토글 ·
울림을 끈 직후 · 스누즈 후.

- **한계**: 앱을 14일 넘게 한 번도 열지 않으면 반복 알람이 멈춘다. 설정 탭에 한 줄 안내.
- 스누즈: 울림 화면 [5분 뒤] → 같은 `packageId` 로 `now + 5분` 재예약. 알림의 스누즈 버튼은
  패키지의 `androidSnoozeDuration: 5분` 이 처리한다.
- 끄기: `stop(packageId)` 후 `sync`.

`PackageAlarmScheduler.schedule` 이 만드는 `AlarmSettings`:
`loopAudio: true` · `vibrate: alarm.vibrate` · `assetAudioPath:` 앱 에셋 기본음
(`assets/alarm/default.mp3`, 저작권 문제 없는 음원 — 없으면 짧은 사인파 비프를 생성해 넣는다) ·
`volumeSettings: fade(3초, volume 0.8)` · `androidFullScreenIntent: true` ·
`androidSnoozeDuration: 5분` · `notificationSettings(title: 라벨 또는 "알람", body: 시각, stopButton: "끄기", androidSnoozeButton: "5분 뒤")` ·
`payload: alarm.id`.

## 6. 화면

### 하단 탭 `MainShellPage`
`NavigationBar` 세 항목 — 알람(`Icons.alarm`) · 걷기(`Icons.directions_walk`) · 설정(`Icons.settings`).
첫 탭은 **걷기**(기존 사용 흐름 유지). `IndexedStack`.

### 알람 목록 `AlarmListPage`
- 머리: 켜진 알람이 있으면 "다음 알람까지 7시간 12분", 없으면 숨김.
- 권한 경고 배너: 알림 · 정확한 알람 중 하나라도 거부면 "알람이 울리지 않을 수 있어요" + 설정 탭으로 이동.
- 행(`AppListTile` 기반): 큰 시각(`오전 7:00`) · 라벨 · 반복 요약(매일/평일/주말/`월·수·금`/1회) · 오른쪽 `Switch`. 꺼진 알람은 흐리게.
- 행 탭 → 편집. FAB `+` → 새 알람(기본 07:00, 반복 없음, 진동 켬).
- 비면 `AppPlaceholder`.

### 편집 `AlarmEditPage`
시각 휠 → 요일 칩 7개(월~일) → 라벨 입력 → 진동 스위치 → [저장] (primary). 수정이면
[삭제] (text, 확인 `AppConfirmDialog`). 저장하면 켜진 상태로 저장, 권한 확인(§7), sync,
`AppSnackBar` "N시간 M분 뒤에 울려요", 목록으로.

### 울림 `AlarmRingingPage`
큰 현재 시각 · 라벨 · [5분 뒤] (secondary) · [끄기] (primary). `PopScope(canPop: false)`.
앱이 살아 있을 때 `Alarm.ringing` 으로 뜬다. 앱이 죽어 있거나 잠금 상태면 패키지의 전체 화면
알림 · 알림 버튼이 대신한다.

### 설정 `SettingsPage`
- **권한**: 알림 · 정확한 알람 · 전체 화면 알림 · Health Connect — 행마다 "허용됨" / "허용 필요 ›". 탭 → 해당 설정 열기. `resumed` 때 다시 확인.
- **테마**: 시스템 · 라이트 · 다크 라디오. 즉시 반영, 저장.
- **앱 정보**: 버전 · 오픈소스 라이선스(`showLicensePage`).
- 안내: "앱을 14일 넘게 열지 않으면 반복 알람이 멈출 수 있어요."

### 걷기 탭
기존 `WalkHomePage` 그대로. `Scaffold` 안에 중첩되므로 AppBar 는 탭별로 각자 둔다.

## 7. 권한

| 권한 | 안드로이드 | 확인 · 요청 |
|---|---|---|
| 알림 | 13+ `POST_NOTIFICATIONS` 런타임 | `permission_handler` `Permission.notification` |
| 정확한 알람 | 12+ `SCHEDULE_EXACT_ALARM` | `Permission.scheduleExactAlarm` — 요청하면 시스템 설정 화면 |
| 전체 화면 알림 | 14+ `USE_FULL_SCREEN_INTENT` (거부될 수 있음) | `NotificationManager.canUseFullScreenIntent()` — `permission_handler` 로 안 되면 MethodChannel `walk/full_screen_intent` 에 `canUse` · `openSettings` |
| 부팅 | `RECEIVE_BOOT_COMPLETED` · `WAKE_LOCK` · `FOREGROUND_SERVICE(_MEDIA_PLAYBACK)` 등 | `alarm` 패키지 README 가 요구하는 매니페스트 항목을 그대로 따른다 |

- 각각 `PermissionSource` 구현 → `PermissionRequester`(세션당 한 번). 알람 저장/켜기 때
  알림 `ensure()` → 정확한 알람 `ensure()`. 거부돼도 저장은 한다.

## 8. 테스트

- `upcoming_triggers_test`: 반복 요일 · 오늘 이미 지남 · 자정 직전/직후 · 14일 경계 · 1회성 · 꺼짐 · 월말.
- `alarm_use_case_test`: 가짜 스케줄러 · 저장소로 sync 의 추가/취소, 1회성 자동 끄기, 울리는 중 보존, 새 id 부여, 삭제 시 취소.
- `prefs_alarm_repository_test` · `prefs_settings_repository_test`: `SharedPreferences.setMockInitialValues`.
- cubit: bloc_test. 페이지: 목록 · 편집 · 설정 위젯 테스트, 셸 탭 전환.
- 기존 walk 테스트는 경로만 옮기고 모두 통과해야 한다.

## 9. 기기 확인 (구현 마지막)

실제 폰(또는 에뮬레이터)에서:

1. 알람 1분 뒤로 저장 → 앱 켜 둔 채 울림 화면 · 끄기.
2. 앱을 최근 앱에서 지우고 화면 끈 채 → 잠금화면 위 전체 화면 · 소리 · 진동.
3. 알림 스누즈 → 5분 뒤 재울림.
4. 재부팅 후 예약 유지(안 되면 부팅 수신기에서 sync 를 보완).
5. 반복 알람 끈 뒤 목록 "다음 알람"이 다음 회차.
6. 테마 전환 · 권한 행 → 설정 이동.
