# walk — 알람 고도화 웨이브 1 설계 (알람 추가 흐름 · 무음 모드 · 하루 sync · 설정 정리)

> 작성 2026-10-05 · 상태: **설계 승인** · 앱 문서 [walk 허브](../../../apps/walk/docs/README.md) ·
> 백로그 [알람 고도화](2026-10-05-walk-alarm-upgrade-backlog-design.md) · 선행 [기상 알람](2026-09-27-walk-alarm-design.md) ·
> [알람음 선택(웨이브 0)](2026-10-05-walk-alarm-sound-design.md) · [시간대 변경](2026-09-30-walk-alarm-timezone-design.md)

웨이브 0(알람음 · 포크 · 설정 지문)이 끝난 코드 위에서 시작한다.

## 1. 범위

| ID | 항목 |
|---|---|
| N1 | `+` → 종류 시트([한 번] · [반복]) → 종류별 편집 화면 |
| N2 | 한 번 알람: "얼마 뒤"를 버튼으로 쌓기 · 초기화 · 울릴 시각 표시 · 시각 직접 지정 |
| N3 | 반복 알람: 시각 휠 + [매일 · 평일 · 주말] 빠른 버튼 + 요일 토글 |
| N4 | 라벨 → 화면 이름 "제목"(저장 키 `label` 유지) |
| N5 | "무음 · 진동 모드에선 진동만" 체크박스(포크 네이티브), 진동 토글 삭제 |
| N6 | 알람 목록 · 종류 시트 · 편집 화면 디자인 개선(승인된 시안) |
| N7 | 설정 탭의 버전 · 오픈소스 라이선스 삭제 |
| C1 | 하루 한 번 백그라운드 sync(WorkManager) — 14일 한계 해소 |

범위 밖: 편집 화면 안에서 종류 바꾸기(한 번 ↔ 반복은 지우고 새로 만든다), 볼륨 · 스누즈 · 자동 멈춤(웨이브 3).

## 2. 결정 기록

| 결정 | 이유 |
|---|---|
| 종류는 저장값으로 따로 두지 않는다. 지금처럼 `repeat` 가 비면 한 번 알람이다 | 저장 형식이 바뀌지 않는다 |
| 종류는 시트에서 고르고 편집 화면에서는 바꾸지 않는다. 기존 알람을 열면 그 종류의 편집 화면이 열린다 | 사용자 요청(시트로 선택). 두 화면의 시각 정하는 방식이 달라 섞으면 복잡하다 |
| 한 번 알람의 울릴 시각은 화면이 정해 `oneShotAt` 으로 넘긴다. `save` 는 넘어온 `oneShotAt` 이 미래면 그대로 쓰고, 없거나 지났으면 지금처럼 `nextOccurrence(hour, minute)` 로 정한다 | "얼마 뒤"는 초 단위 정확한 시각이 필요하다. 목록에서 다시 켤 때는 기존 규칙이 맞다 |
| 한 번 화면의 상태: 상대 모드(`offset`, 0 에서 시작) 와 고정 모드(`fixedAt`, 시각 휠로 정함). 버튼은 상대 모드면 `offset` 에, 고정 모드면 `fixedAt` 에 더한다. 초기화는 상대 모드 0 으로 | 사용자 결정("얼마 뒤 + 시각 보조"). 시간이 흘러도 상대 모드의 "N 뒤"는 그대로, 울릴 시각만 매분 갱신된다 |
| 저장 순간 울릴 시각 = `fixedAt ?? now + offset`. 1분 미만이면 저장 버튼을 비활성으로 두고 "시간을 더해 주세요" 안내를 보인다 | 0분 알람을 막는다 |
| 기존 한 번 알람을 열면 `oneShotAt` 이 미래면 고정 모드(`fixedAt = oneShotAt`), 아니면 상대 모드 0 | 다시 열어도 울릴 시각이 흔들리지 않는다 |
| 반복 화면은 요일이 하나도 없으면 저장 버튼을 비활성으로 두고 "요일을 골라 주세요" 안내 | 요일을 다 끄면 한 번 알람으로 바뀌던 동작을 막는다 |
| 빠른 버튼은 현재 요일 집합이 그 묶음과 같을 때 선택 표시. 누르면 요일 집합을 그 묶음으로 바꾼다 | 토글과 버튼이 서로 맞는다 |
| `Alarm.vibrate` 필드를 없애고 `silentWhenRingerMuted`(JSON `silentWhenRingerMuted`, 기본 false)를 더한다. 옛 `vibrate` 키는 읽고 버린다. 패키지에는 항상 `vibrate: true` | 사용자 결정 — 진동은 항상, 체크박스는 "무음 · 진동 모드에선 진동만" 하나 |
| 포크 `AlarmSettings.androidSilentWhenRingerMuted`. `AlarmService.ringAlarm` 이 울리는 순간 `AudioManager.ringerMode != NORMAL` 이면 스트림 볼륨 · 오디오 포커스를 건드리지 않고 `MediaPlayer` 를 볼륨 0 으로 재생(재생은 유지)하고 진동한다 | 앱이 꺼져 있어도 정확하다. 재생을 멈추면 패키지가 "안 울림"으로 보고 30초 뒤 알람을 지운다(스파이크 N5) |
| 진동에 `USAGE_ALARM` 속성을 준다(포크 `VibrationService`) | 무음 모드에서 진동이 막히지 않게 한다. 실기기로 확인 |
| 울리는 중 모드 변경 반영 · 방해 금지(DND) 별도 판단은 하지 않는다 | 백로그 문구는 "울리는 순간". 필요해지면 따로 |
| C1 은 네이티브 androidx.work `PeriodicWorkRequest`(24시간, unique `walk.alarm.dailySync`, `KEEP`). 실행은 시간대 수신기와 같은 공용 실행기 `AlarmResync`(메인 엔진 있으면 `resync`, 없으면 헤드리스 `alarmResyncMain`). 프로세스 안에서 한 번에 하나만 돌고, 실행 중 들어온 요청은 끝난 뒤 한 번 더 돈다 | 스파이크 C1. workmanager · android_alarm_manager_plus 는 엔진을 하나 더 띄워 alarm 플러그인 정적 필드를 덮는다 |
| `MainActivity.onCreate` 에서 enqueue(멱등). 타임아웃(60초)이면 `Result.success`(다음 날 다시 돈다) | 13일 여유가 있어 재시도가 필요 없다 |
| 설정 탭의 "14일 넘게 안 열면 멈출 수 있어요" 안내(`walkSettingsInactiveNotice`)를 지운다 | C1 이 해소한다 |
| 버전 · 라이선스 삭제와 함께 `AppInfoSource` · `AppInfoCubit` · `package_info_plus` 의존성을 지운다. `SettingsPage` 는 `StatelessWidget` 으로 | 쓰는 곳이 없어진다 |

## 3. 도메인

### 3.1 `Alarm`

- 삭제: `vibrate`. 추가: `final bool silentWhenRingerMuted;`(기본 false).
- `toJson`: `vibrate` 키 대신 `silentWhenRingerMuted`. `fromJson`: 키가 없으면 false, `vibrate` 키는 무시.
- 웨이브 0 의 `sound` 는 그대로.

### 3.2 `AlarmUseCase.save`

```dart
// 1회성: 넘어온 oneShotAt 이 미래면 그대로, 아니면 nextOccurrence(hour, minute, now).
// hour · minute 는 결정된 oneShotAt 의 값으로 맞춘다(목록 표시용).
```

`toggle(enabled: true)` 는 지금과 같다(`nextOccurrence`).

### 3.3 반복 묶음 — `domain/alarm/entity/repeat_preset.dart`

```dart
enum RepeatPreset {
  everyday({mon..sun}), weekdays({mon..fri}), weekend({sat, sun});
  final Set<Weekday> days;
  static RepeatPreset? of(Set<Weekday> repeat); // 같으면 그 묶음, 아니면 null
}
```

`AlarmFormat.repeat` 의 매일 · 평일 · 주말 판정도 이것을 쓴다.

### 3.4 한 번 알람 시각 계산 — `domain/alarm/one_shot_draft.dart`

순수 값 객체(Freezed primary constructor):

```dart
@freezed
class OneShotDraft with _$OneShotDraft {
  final Duration offset;     // 상대 모드
  final DateTime? fixedAt;   // 고정 모드(초 0)
  const OneShotDraft({this.offset = Duration.zero, this.fixedAt});

  OneShotDraft add(Duration d);                 // 모드에 맞게 더한다
  OneShotDraft reset();                          // offset 0, fixedAt null
  OneShotDraft fixAt(int hour, int minute, DateTime now); // fixedAt = nextOccurrence
  DateTime ringAt(DateTime now);                 // fixedAt ?? now + offset
  Duration remaining(DateTime now);              // ringAt - now (음수면 zero)
  bool canSave(DateTime now);                    // remaining >= 1분
  static OneShotDraft fromAlarm(Alarm a, DateTime now); // §2 규칙
}
```

더하기 버튼 상수: `[1시간, 10분, 5분, 1분]`. 상대 모드 상한 23시간 59분(넘으면 그 값에 멈춘다).

## 4. 데이터 · 포크

- `PackageAlarmScheduler.settingsFor`: `vibrate: true`, `androidSilentWhenRingerMuted: alarm.silentWhenRingerMuted`. 지문에 `silentWhenRingerMuted` 를 넣는다(웨이브 0 지문 장치).
- 포크(`third_party/alarm`): 스파이크 N5 §4.2 그대로 — pigeon `AlarmSettingsWire` 끝에 필드, Dart 모델 · `toWire` · `copyWith` · props · json, Kotlin `AlarmSettings`(기본 false, `fromWire` · 레거시 `fromJson`), `AlarmService.ringAlarm` 판단(`internal fun shouldMuteForRinger(optIn, ringerMode)`), `AudioService.playAudio(muted)`, `VibrationService` 속성. Kotlin 단위 테스트 `shouldMuteForRinger` (`./gradlew :alarm:testDebugUnitTest`, `apps/walk/android` 에서). `FORK.md` 에 변경 기록.

### 4.1 C1 Kotlin (`apps/walk/android/app/src/main/kotlin/com/karma/walk/`)

| 파일 | 내용 |
|---|---|
| `AlarmResync.kt` (신규) | `TimeZoneChangedReceiver` 의 디스패치를 옮긴 공용 실행기. `@MainThread fun run(context, timeoutMs, onEnd: (reason) -> Unit): Handle`. 메인 엔진(`MainActivity.engine`) 있으면 `walk/background` 의 `resync`, 없으면 헤드리스 `alarmResyncMain`. 한 번에 하나, 실행 중 요청은 끝난 뒤 한 번 더 |
| `TimeZoneChangedReceiver.kt` | `goAsync` → 메인 Looper 에서 `AlarmResync.run(ctx, 9_000)` → `pending.finish()` 만 |
| `DailyAlarmSyncWorker.kt` (신규) | `CoroutineWorker`, `Dispatchers.Main.immediate` 에서 `AlarmResync.run(…, 60_000)` 을 기다린다. `enqueue(context)` = 24시간 주기 · 초기 지연 1일 · `KEEP` |
| `MainActivity.kt` | `onCreate` 에서 `DailyAlarmSyncWorker.enqueue(applicationContext)` |
| `app/build.gradle.kts` | `dependencies { implementation("androidx.work:work-runtime-ktx:2.10.x") }`(빌드되는 최신 안정판) |
| `src/debug/…/DebugDailySyncReceiver.kt` + 디버그 매니페스트 | `com.karma.walk.DEBUG_DAILY_SYNC` 방송을 받으면 1회성 작업을 enqueue(에뮬레이터 확인용) |

Dart 변경 없음(주석만). Kotlin 은 기존 방침대로 에뮬레이터로 확인한다.

## 5. 화면

시안: 목록(둥근 카드 행 · 요일 점 · 다음 알람 카드) · 종류 시트 · 한 번 · 반복. 모든 색 · 여백 · 모서리는
`Theme.of(context)` · `AppSpacing` · `AppRadius` 토큰으로(CLAUDE.md UI 규칙). 앱 전용 모양은 앱 안 위젯으로 둔다.

### 5.1 목록 `AlarmListPage`

- 다음 알람 카드(`AlarmSummaryCard`): 지금 구조 유지, 모서리 `AppRadius.lg`.
- 알람 행(`AlarmTile` 재작성): `Material(surfaceContainerLow, AppRadius.lgAll)` 안의 `InkWell` 행.
  왼쪽: 큰 시각(오전/오후 작게) · 둘째 줄 `제목 · 반복 요약` · 반복 알람은 요일 점 7개(켜진 요일 primary,
  나머지 outlineVariant), 한 번 알람은 모래시계 아이콘 + "한 번 · N 뒤". 오른쪽: 스위치(햅틱 유지).
  꺼진 알람은 글자 흐림(지금 규칙). 행 사이 `AppSpacing.sm`.
- FAB: `FloatingActionButton`(테마 모양, 아이콘 `Icons.add`) → `AlarmKindSheet.show` → 결과 종류로
  `Alarm.draft()`(한 번) 또는 `Alarm.draft().copyWith(repeat: weekdays)`(반복) 를 편집 화면으로 연다.

### 5.2 종류 시트 `AlarmKindSheet`

`showModalBottomSheet` + 손잡이 + 제목 "어떤 알람을 만들까요" + 두 행(아이콘 · 제목 · 한 줄 설명):
[한 번 — 지금부터 얼마 뒤에 울려요] · [반복 — 정한 요일마다 울려요]. 결과 `Future<AlarmKind?>`
(`enum AlarmKind { oneShot, repeating }`, presentation).

### 5.3 편집 `AlarmEditPage(initial)`

종류는 `initial.isOneShot` 으로 정한다. 공통 아래쪽: 제목(30자, 라벨 "제목", 힌트 "예: 출근") · 알람음 줄(웨이브 0) ·
체크 줄(`Checkbox` + "무음 · 진동 모드에선 진동만", 보조 "폰이 무음이나 진동 모드면 소리 없이 진동으로 울려요") ·
저장 · 삭제(기존 알람). 앱바 제목: 새 알람 "한 번 알람"/"반복 알람", 수정 "알람 수정".

- **한 번 영역** `_OneShotSection`: 큰 글자 "1시간 25분 뒤"(0 이면 "0분 뒤") · 그 아래 칩 "오후 4:50에 울림"
  (누르면 시각 휠 시트 → `fixAt`) · 2×2 버튼 [+1시간][+10분][+5분][+1분] · [초기화]. 매분 0초에 다시 그린다.
  저장 불가면 버튼 비활성 + 안내.
- **반복 영역** `_RepeatSection`: 시각 휠(지금 것) · 빠른 버튼 3개 · 요일 원 7개 · 반복 요약 줄.
- `AlarmEditCubit` 추가 메서드: `addOffset(Duration)` · `resetOffset()` · `fixOneShotAt(h, m)` · `applyPreset(RepeatPreset)` ·
  `setSilentWhenRingerMuted(bool)`(삭제: `setVibrate`). 상태에 `OneShotDraft draft` 를 더한다.
  `save()` 는 한 번이면 `alarm.copyWith(oneShotAt: draft.ringAt(now), hour/minute 맞춤)` 을 넘긴다.
  돌려주는 남은 시간은 지금처럼.

### 5.4 설정

버전 · 라이선스 섹션 삭제, 14일 안내 삭제. 나머지(걷기 · 권한 · 테마) 그대로.

## 6. l10n (ko · en · ja, `walkAlarm*`)

추가: `walkAlarmKindTitle`(어떤 알람을 만들까요) · `walkAlarmKindOneShot`(한 번) · `walkAlarmKindOneShotHint` ·
`walkAlarmKindRepeat`(반복) · `walkAlarmKindRepeatHint` · `walkAlarmNewOneShot`(한 번 알람) · `walkAlarmNewRepeat`(반복 알람) ·
`walkAlarmAfter`({duration} 뒤) · `walkAlarmRingsAtChip`({time}에 울림) · `walkAlarmAddHour`(+1시간) · `walkAlarmAddMinutes`(+{minutes}분) ·
`walkAlarmReset`(초기화) · `walkAlarmNeedTime`(시간을 더해 주세요) · `walkAlarmNeedDays`(요일을 골라 주세요) ·
`walkAlarmPresetEveryday` · `walkAlarmPresetWeekdays` · `walkAlarmPresetWeekend` · `walkAlarmTitle`(제목) · `walkAlarmTitleHint`(예: 출근) ·
`walkAlarmSilentWhenMuted`(무음 · 진동 모드에선 진동만) · `walkAlarmSilentWhenMutedHint` · `walkAlarmOneShotRow`(한 번 · {remaining}).
삭제: `walkAlarmVibrate` · `walkAlarmLabel` · `walkAlarmLabelHint`(쓰는 곳이 없어지면) · `walkSettingsAbout` · `walkSettingsVersion` ·
`walkSettingsLicenses` · `walkSettingsInactiveNotice`. 키는 추가 전에 pawlog 의 `walk*` 키와 겹치지 않는지 grep 한다.
ko 에는 `@key.description` 필수(`apps/trader` 의 `test/convention` 이 검사).

## 7. 테스트

| 대상 | 내용 |
|---|---|
| `alarm_test.dart` | `silentWhenRingerMuted` 왕복 · 없으면 false · 옛 `vibrate` 키 무시 |
| `repeat_preset_test.dart` | `of` 판정 3종 · 그 밖 null |
| `one_shot_draft_test.dart` | 상대/고정 더하기 · 초기화 · `fixAt` 오늘/내일 · `ringAt` · `canSave` 1분 경계 · 상한 · `fromAlarm` 미래/과거/null |
| `alarm_use_case_test.dart` | 1회성 save 가 미래 `oneShotAt` 을 유지 · 과거면 `nextOccurrence` · hour/minute 맞춤 |
| `package_alarm_scheduler_test.dart` | `vibrate: true` 고정 · `androidSilentWhenRingerMuted` 전달 · 지문에 반영 |
| `alarm_edit_cubit_test.dart` | 오프셋 · 초기화 · 고정 · 묶음 · 체크 · 한 번 save 가 `oneShotAt` 을 넘김 · 반복 요일 0 이면 저장 불가 |
| `alarm_edit_page_test.dart` | 종류별 영역 · 버튼 → 표시 갱신 · 시각 칩 → 시트 · 비활성 안내 · 빠른 버튼 ↔ 토글 · 체크 줄 · 320dp 넘침 없음 |
| `alarm_kind_sheet_test.dart` | 두 행 · 선택 결과 pop |
| `alarm_list_page_test.dart` · `alarm_tile_test.dart` | FAB → 시트 → 종류별 편집 · 요일 점 · 한 번 행 문구 · 꺼진 행 흐림 |
| `settings_page_test.dart` 등 | 버전 · 라이선스 · 14일 안내 없음, AppInfo mock 제거 |
| 포크 Kotlin | `shouldMuteForRinger` 6 조합 |
| 에뮬레이터 | 무음 모드 · 진동 모드 · 소리 모드 × 체크 켬/끔(앱 종료 · 잠금) · 하루 sync 디버그 방송(앱 종료 → 헤드리스, 앱 실행 → 메인) |

## 8. 문서

완료 시 [walk plan](../../../apps/walk/docs/plan.md) 화면 표 · 알람 절 · 범위 밖, [status](../../../apps/walk/docs/status.md),
`history.md` · `testing.md` · `README.md` 를 갱신한다.
