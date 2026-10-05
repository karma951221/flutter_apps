# walk 알람 고도화 (웨이브 0~3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development (Workflow 로 태스크마다 새 서브에이전트 + 리뷰). 태스크마다 해당 스펙 절을 함께 읽는다. 체크박스(`- [ ]`)로 진행을 표시한다.

**Goal:** walk(Life Tool) 알람에 알람음 선택 · 새 알람 추가 흐름 · 무음 모드 진동 · 하루 백그라운드 sync · 앱 아이콘/스플래시 · 볼륨/스누즈/자동 멈춤 · 건너뛰기 · 미리 알림 · 공휴일 알림을 더한다.

**Architecture:** `alarm` 5.14.0 을 `apps/walk/third_party/alarm` 으로 포크해 울리는 순간의 네이티브 판단을 넣고, 앱은 기존 계층(domain/data/presentation)과 `AlarmUseCase._sync` 14일 선예약 구조를 유지한다. 패키지 예약에 설정 지문을 실어 설정 변경이 이미 걸린 회차에도 반영된다. 백그라운드 일(하루 sync · 미리 알림 액션)은 네이티브 Kotlin 이 메인 엔진 우선 · 헤드리스 대체로 Dart 를 부른다.

**Tech Stack:** Flutter 3.41 / Dart 3.11, flutter_bloc, freezed 3, injectable/get_it, shared_preferences, alarm(포크), Kotlin(AGP 8.11, minSdk 26), androidx.work, pigeon(포크 재생성).

**Spec:**
- 웨이브 0: [알람음 선택](../specs/2026-10-05-walk-alarm-sound-design.md) (§10 추가 결정 우선)
- 웨이브 1: [웨이브 1](../specs/2026-10-05-walk-alarm-wave1-design.md)
- 웨이브 2: [앱 아이콘 · 스플래시](../specs/2026-10-05-walk-app-face-design.md)
- 웨이브 3: [웨이브 3](../specs/2026-10-05-walk-alarm-wave3-design.md)
- 배경: [백로그](../specs/2026-10-05-walk-alarm-upgrade-backlog-design.md)

## Global Constraints

- 안드로이드만. Dart 명령은 `apps/walk` 에서: `flutter test` · `flutter analyze` · 코드 생성 `dart run build_runner build --delete-conflicting-outputs`.
- l10n: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` 에 키 추가, `cd packages/l10n && flutter gen-l10n`, 생성물도 커밋. ko 에는 `@key.description` 필수. 키 추가 전 `grep '"walkXxx"' app_ko.arb` 로 pawlog 의 `walk*` 키와 겹치지 않는지 확인. ARB 를 바꾸면 `cd apps/trader && flutter test test/convention` 통과.
- CLAUDE.md: UI 공통 위젯(`AppButton` · `AppListTile` · `AppPlaceholder` · `AppConfirmDialog` · `AppSnackBar`) 우선, 색 · 여백 · 모서리는 `Theme.of(context)` · `AppSpacing` · `AppRadius`(하드코딩 금지), Freezed 2 패턴(primary constructor · sealed union), 분기는 `switch` 패턴 매칭, 생성 파일 직접 수정 금지, 테스트는 `lib/…` ↔ `test/…` 1:1.
- 한 앱 전용 코드는 앱 안에. walk 의존 패키지는 `core` · `design_system` · `l10n` · `permission` + 외부 pub/포크(`test/convention/package_boundary_test.dart`).
- 날짜 산술은 `DateTime(y, m, d + n, h, mi)` 생성자. 시간 의존 코드는 `Clock` 주입.
- TDD: 먼저 실패하는 테스트를 쓰고 실패를 확인한 뒤 구현한다. 바로 통과한 테스트는 구현을 잠시 되돌려(뮤테이션) 실패하는지 확인한다. Kotlin 은 순수 규칙 함수를 JUnit 으로, 나머지는 에뮬레이터 시나리오로.
- 커밋: 경로 지정 `git add <경로…> && git commit -m "…"`. 메시지 `feat(walk): …`/`fix(walk): …`/`refactor(walk): …`/`docs(walk): …` 한국어 + 빈 줄 + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. `.idea/` · `apps/pawlog/**` 는 절대 add 하지 않는다(다른 작업 중).
- 각 태스크 끝: `flutter analyze` 0 이슈 · `flutter test` 전부 통과(기준선 349 통과 · 1 skip). 네이티브를 건드린 태스크는 `flutter build apk --debug` 성공.
- 포크 재생성(필드 추가 시): `cd apps/walk/third_party/alarm && flutter pub get && dart run pigeon --input pigeons/alarm_api.dart && dart run build_runner build --delete-conflicting-outputs`. 포크 Kotlin 테스트: `cd apps/walk/android && ./gradlew :alarm:testDebugUnitTest`. 정확한 절차는 W0-T1 이 `FORK.md` 에 확정해 적는다.

---

## 웨이브 0 — 포크 · 설정 지문 · 알람음

### W0-T1: alarm 포크 도입

**Files:** Create `apps/walk/third_party/alarm/**`(pub cache `alarm-5.14.0` 복사, `example/` 제외), `apps/walk/third_party/alarm/FORK.md`. Modify `apps/walk/pubspec.yaml`(`alarm: path: third_party/alarm`), `apps/walk/analysis_options.yaml`(`analyzer: exclude: [third_party/**]`), 루트 `pubspec.lock`(pub get 결과).

**Interfaces:** Produces — 포크 패키지 이름은 그대로 `alarm`(import 변경 없음).

- [ ] 복사(`cp -R ~/.pub-cache/hosted/pub.dev/alarm-5.14.0 apps/walk/third_party/alarm`, `example/` 삭제, `LICENSE` 유지).
- [ ] path 의존성으로 바꾸고 루트에서 `flutter pub get`. 포크는 workspace 멤버로 넣지 않는다.
- [ ] 포크 디렉터리에서 pigeon · build_runner 재생성이 **아무 변경 없이** 도는지 확인(생성물 diff 0). 안 되면 원인과 우회 절차를 `FORK.md` 에 적는다.
- [ ] `./gradlew :alarm:testDebugUnitTest` 가 도는지 확인.
- [ ] `FORK.md`: 기준 버전 · 복사 날짜 · 재생성 명령 · 테스트 명령 · 변경 목록(빈 표).
- [ ] `flutter analyze` · `flutter test` · `flutter build apk --debug`.
- [ ] 커밋 `chore(walk): alarm 5.14.0 을 third_party 로 포크한다`.

### W0-T2: 포크 — 소리 대체 경로

**Files:** 포크 `pigeons/alarm_api.dart`, 생성물, `lib/model/alarm_settings.dart`(+ `.g.dart`), `android/.../models/AlarmSettings.kt`, `android/.../services/AudioService.kt`, `android/src/test/.../AudioFallbackTest.kt`(신규), `FORK.md`.

**Interfaces:** Produces — Dart `AlarmSettings.androidFallbackAudioPath: String?`(기본 null, json 왕복). Kotlin `internal fun audioCandidates(primary: String?, fallback: String?): List<String?>` — 재생 시도 순서(`[primary, fallback]`, fallback 이 null 이거나 primary 와 같으면 하나).

- [ ] 실패 테스트: `audioCandidates` 4 조합(Kotlin JUnit) · Dart `AlarmSettings` json 왕복(포크 `test/` 에 두거나 앱 테스트에서 `toJson/fromJson`).
- [ ] pigeon 필드 끝에 추가 → 재생성 → Dart/Kotlin 모델(기본값 있는 필드, 레거시 json 은 null).
- [ ] `AudioService.playAudio`: 후보를 차례로 `prepare/start`, 실패 시 다음. 모두 실패면 기존 실패 경로.
- [ ] `FORK.md` 표에 추가. 검증 · 커밋 `feat(walk): 포크 알람이 소리 재생에 실패하면 대체음으로 울린다`.

### W0-T3: 도메인 — `AlarmSound` · 내장음

**Files:** Create `lib/domain/alarm/entity/alarm_sound.dart`(+freezed), `tool/generate_alarm_sounds.py`, `assets/alarm/chime.wav`, `assets/alarm/rising.wav`. Modify `lib/domain/alarm/entity/alarm.dart`. Test `test/domain/alarm/entity/alarm_sound_test.dart`, `alarm_test.dart`.

**Interfaces:** Produces —
```dart
@freezed sealed class AlarmSound with _$AlarmSound {
  const factory AlarmSound.system() = SystemAlarmSound;
  const factory AlarmSound.bundled(String asset) = BundledAlarmSound;
  const factory AlarmSound.device({required String title, required String path}) = DeviceAlarmSound;
  Map<String, Object?> toJson(); static AlarmSound fromJson(Object? json); // 모르면 system
}
abstract final class BundledAlarmSounds { static const beep = 'assets/alarm/default.wav'; static const chime = 'assets/alarm/chime.wav'; static const rising = 'assets/alarm/rising.wav'; static const all = [beep, chime, rising]; }
// Alarm: final AlarmSound sound (기본 AlarmSound.system()), JSON 'sound'
```
- [ ] 실패 테스트: sound 3종 왕복 · 키 없음/모르는 type/깨진 값 → system · Alarm JSON 에 sound 포함.
- [ ] 구현, `default.wav` 는 이름 그대로(스펙 §10). 스크립트(표준 라이브러리만)로 chime · rising 생성(22.05kHz mono 16bit, 3초), 생성물 커밋.
- [ ] 커밋 `feat(walk): 알람마다 소리를 저장한다`.

### W0-T4: 데이터 — 소리 매핑 · 설정 지문 다시 걸기

**Files:** Modify `lib/data/alarm/package_alarm_scheduler.dart`, `lib/domain/alarm/scheduler/alarm_scheduler.dart`, `lib/domain/alarm/usecase/alarm_use_case.dart`. Test `test/data/alarm/package_alarm_scheduler_test.dart`, `test/domain/alarm/usecase/alarm_use_case_test.dart`(`_FakeScheduler` 갱신).

**Interfaces:**
```dart
// domain
typedef ScheduledRing = ({DateTime at, String signature});
abstract interface class AlarmScheduler {
  Future<Map<int, ScheduledRing>> scheduled(); // 기존 Map<int, DateTime> 대체
  String signatureOf(Alarm alarm);              // 이 알람으로 지금 걸면 붙을 지문
  ... // 나머지 그대로
}
// data
static pkg.AlarmSettings settingsFor(int packageId, DateTime at, Alarm alarm, AlarmNotificationTexts texts,
    {bool Function(String path) fileExists = _exists});
static String signatureFor(Alarm alarm); // fnv1a32 hex, 울림 영향 값만(sound 경로 · vibrate · 제목)
// payload = '${alarm.id}|${signatureFor(alarm)}'; 옛 payload('<id>') 의 signature 는 ''.
```
- [ ] 실패 테스트(data): system → `assetAudioPath` null · bundled → asset · device 파일 있음/없음(→ null) · 항상 `androidFallbackAudioPath == BundledAlarmSounds.beep` · payload 형식 · 같은 입력 같은 지문 · sound/label 바뀌면 지문 바뀜 · 로캘 문구는 지문에 영향 없음.
- [ ] 실패 테스트(usecase): 시각 같고 지문 같으면 다시 걸지 않음 · 지문 다르면 다시 건다 · 옛 payload(지문 '')는 다시 건다 · 울리는 중 회차는 건드리지 않음(기존 규칙 유지).
- [ ] 구현(`nextRings` 등 `scheduled()` 를 쓰는 곳 모두 `.at` 으로). 커밋 `feat(walk): 설정이 바뀐 회차는 다시 건다`.

### W0-T5: 네이티브 알람음 소스

**Files:** Create `lib/domain/alarm/sound/alarm_sound_source.dart`, `lib/data/alarm/channel_alarm_sound_source.dart`, `android/app/src/main/kotlin/com/karma/walk/AlarmSoundsChannel.kt`. Modify `MainActivity.kt`. Test `test/data/alarm/channel_alarm_sound_source_test.dart`.

**Interfaces:** 스펙 §4.2 그대로(`DeviceRingtone`, `AlarmSoundSource.deviceRingtones/preview/stopPreview/import`). 채널 `walk/alarm_sounds`, 메서드 `list` · `preview{kind,value}` · `stopPreview` · `import{uri}`. `import` 는 복사 후 `MediaPlayer.prepare()` 검증, 실패 시 파일 삭제 + `result.error`.
- [ ] 실패 테스트: mock MethodChannel 로 각 메서드 인자 · 응답 매핑 · 오류 → 예외 · `import` 결과가 `AlarmSound.device(title, path)`.
- [ ] Dart 구현 + DI(`@LazySingleton(as: AlarmSoundSource)`, 인자 없는 생성자) + Kotlin(스펙 §4.3, `cleanUpFlutterEngine` 에서 미리 듣기 해제).
- [ ] `flutter build apk --debug`. 커밋 `feat(walk): 기기 알람음을 읽고 미리 듣고 복사한다`.

### W0-T6: 알람음 선택 화면 · 편집 줄

**Files:** Create `lib/presentation/alarm/cubit/alarm_sound_cubit.dart`(+state), `lib/presentation/alarm/page/alarm_sound_page.dart`, `lib/presentation/alarm/format/alarm_sound_format.dart`(이름). Modify `alarm_edit_cubit.dart`(`setSound`), `alarm_edit_page.dart`(진동 줄 위 알람음 줄), ARB 3개. Test 대응 테스트 파일들.

- [ ] 스펙 §5 · §7 · §8 의 테스트를 먼저: cubit(초기 선택 · 탭 → preview · 내장/시스템 선택 · 기기 import 성공/실패 · close → stopPreview) · 페이지(세 구역 · 목록 실패 placeholder · 선택 결과 pop · import 중 로딩) · 편집(알람음 줄 이름 · 선택 반영).
- [ ] 구현 · l10n(스펙 §7 키, "비프" 이름) · gen-l10n · trader convention.
- [ ] 커밋 `feat(walk): 알람음을 고르는 화면을 더한다`.

### W0-R: 웨이브 0 리뷰 · 문서

- [ ] 리뷰 워크플로(정확성 · 스펙 준수 · 테스트 품질 · 네이티브) → 판정 → 수정.
- [ ] `apps/walk/docs/{plan,status,history,testing}.md` 갱신(진행 상태는 status 에만).
- [ ] 에뮬레이터: 내장음 · 기기 알람음으로 1분 뒤 알람이 그 소리로 울림 · 앱 업데이트 직후 기존 알람이 지문 불일치로 다시 걸림.

---

## 웨이브 1 — 알람 추가 흐름 · 무음 모드 · 하루 sync · 설정 정리

### W1-T1: 포크 — 무음 · 진동 모드면 진동만

**Files:** 포크 pigeon/생성물, `alarm_settings.dart`, `AlarmSettings.kt`, `AlarmService.kt`, `AudioService.kt`, `VibrationService.kt`, `android/src/test/.../RingerMuteTest.kt`, `FORK.md`.

**Interfaces:** Dart `AlarmSettings.androidSilentWhenRingerMuted: bool`(기본 false). Kotlin `internal fun shouldMuteForRinger(optIn: Boolean, ringerMode: Int): Boolean`.
- [ ] 실패 테스트: `shouldMuteForRinger` 6 조합(NORMAL/VIBRATE/SILENT × optIn) · Dart json 왕복(없으면 false).
- [ ] 구현: 스파이크 N5 §4.2(무음이면 볼륨 · 포커스 생략, `MediaPlayer` 볼륨 0 으로 재생 유지, 진동 켬) + 진동 `USAGE_ALARM` 속성(API 33+ `VibrationAttributes`, 26~32 `AudioAttributes`).
- [ ] 커밋 `feat(walk): 포크 알람이 무음 모드에서 진동만 울릴 수 있다`.

### W1-T2: 도메인 · 데이터 — 체크 필드 · 반복 묶음 · 한 번 초안 · save 규칙

**Files:** Modify `alarm.dart`, `alarm_use_case.dart`, `package_alarm_scheduler.dart`, `alarm_format.dart`(묶음 판정 재사용). Create `lib/domain/alarm/entity/repeat_preset.dart`, `lib/domain/alarm/one_shot_draft.dart`(+freezed). Tests 대응.

**Interfaces:** 스펙 §3.1 ~ §3.4 그대로(`Alarm.silentWhenRingerMuted`, `RepeatPreset{everyday,weekdays,weekend}.days/of`, `OneShotDraft{offset,fixedAt}.add/reset/fixAt/ringAt/remaining/canSave/fromAlarm`, 버튼 상수 `oneShotSteps = [Duration(hours: 1), Duration(minutes: 10), Duration(minutes: 5), Duration(minutes: 1)]`, 상한 `oneShotMaxOffset = Duration(hours: 23, minutes: 59)`).
- [ ] 실패 테스트: 스펙 §7 의 `alarm_test` · `repeat_preset_test` · `one_shot_draft_test` · `alarm_use_case_test`(미래 oneShotAt 유지 · 과거면 nextOccurrence · hour/minute 맞춤) · `package_alarm_scheduler_test`(`vibrate: true` 고정 · 무음 필드 전달 · 지문 반영).
- [ ] 구현. `vibrate` 필드와 쓰는 곳 제거(편집 화면의 진동 줄은 W1-T3 에서 체크 줄로 바뀌므로 이 태스크에서는 컴파일되게만 최소 수정).
- [ ] 커밋 `feat(walk): 한 번 알람 시각과 반복 묶음을 도메인에 둔다`.

### W1-T3: 화면 — 종류 시트 · 편집 화면 개편 · 목록 행

**Files:** Create `lib/presentation/alarm/widget/alarm_kind_sheet.dart`, `lib/presentation/alarm/widget/one_shot_section.dart`, `lib/presentation/alarm/widget/repeat_section.dart`, `lib/presentation/alarm/widget/weekday_dots.dart`. Modify `alarm_edit_cubit.dart`/`state`, `alarm_edit_page.dart`, `alarm_tile.dart`, `alarm_list_page.dart`, ARB. Tests 대응 + `alarm_kind_sheet_test.dart`.

**Interfaces:** `enum AlarmKind { oneShot, repeating }`; `AlarmKindSheet.show(BuildContext) → Future<AlarmKind?>`; `AlarmEditState{alarm, draft: OneShotDraft, busy}`; cubit `addOffset(Duration)` · `resetOffset()` · `fixOneShotAt(int h, int m)` · `applyPreset(RepeatPreset)` · `setSilentWhenRingerMuted(bool)` · `bool canSave(DateTime now)`.
- [ ] 실패 테스트: 스펙 §7 의 cubit · 편집 페이지 · 시트 · 목록/타일 항목. 320dp 에서 넘침 없음(ko · en · ja).
- [ ] 구현: 스펙 §5 와 승인된 시안(둥근 카드 행 · 요일 점 · 큰 남은 시간 · 칩 버튼). 토큰만 사용.
- [ ] 커밋 여러 개 가능: 시트 · 편집 / 목록.

### W1-T4: 설정 정리

**Files:** Delete `lib/presentation/settings/cubit/app_info_cubit.dart`, `lib/domain/app_info/`, `lib/data/app_info/`, 해당 테스트 2개. Modify `settings_page.dart`(StatelessWidget, 앱 정보 · 14일 안내 삭제), `pubspec.yaml`(`package_info_plus` 삭제), `settings_page_test.dart` · `main_shell_page_test.dart` · `app_test.dart`(AppInfo mock 제거), ARB(키 4개 삭제), DI 재생성.
- [ ] 실패 테스트 먼저: 설정 화면에 버전 · 라이선스 · 14일 안내 문구가 **없다**.
- [ ] 삭제 · 재생성 · gen-l10n. 커밋 `refactor(walk): 설정에서 앱 정보와 14일 안내를 뺀다`.

### W1-T5: 하루 한 번 백그라운드 sync (C1)

**Files:** Create `android/app/src/main/kotlin/com/karma/walk/AlarmResync.kt`, `DailyAlarmSyncWorker.kt`, `android/app/src/debug/kotlin/com/karma/walk/DebugDailySyncReceiver.kt`. Modify `TimeZoneChangedReceiver.kt`, `MainActivity.kt`, `android/app/build.gradle.kts`, `android/app/src/debug/AndroidManifest.xml`, Dart 주석(`main.dart`, `alarm_resync.dart`, `main_shell_page.dart`).

**Interfaces:** 스펙 §4.1 (`AlarmResync.run(context, timeoutMs, onEnd): Handle`, 직렬화 · 재요청 1회).
- [ ] 순수 규칙(직렬화 큐 상태 머신)을 Kotlin 클래스로 떼어 JUnit 테스트(`app/src/test`): 실행 중 요청 → 끝난 뒤 1회 더 · 여러 번 와도 1회.
- [ ] 구현 · `flutter build apk --debug`.
- [ ] 커밋 `feat(walk): 하루 한 번 백그라운드에서 알람 예약을 채운다`.

### W1-R: 웨이브 1 리뷰 · 문서 · 에뮬레이터

- [ ] 리뷰 워크플로 → 수정. 문서 갱신(plan 화면 표 · 범위 밖, status, history, testing, README).
- [ ] 에뮬레이터: 시트 → 한 번(+10분 ×2 → 저장 → 남은 시간) · 반복(평일) · 무음/진동/소리 모드 × 체크 · 디버그 방송으로 하루 sync(앱 종료 → 헤드리스, 실행 중 → 메인) · 스크린샷.

---

## 웨이브 2 — 앱 아이콘 · 스플래시

### W2-T1: 적응형 아이콘 · 단색 · 알림 아이콘

**Files:** 스펙 §3 의 `assets/icon/*.svg`, `res/mipmap-anydpi-v26/*`, `res/drawable/ic_launcher_foreground.xml` · `ic_launcher_monochrome.xml` · `ic_stat_alarm.xml`, `res/values/colors.xml`, 매니페스트 `roundIcon`, 기존 `mipmap-*/ic_launcher.png` 삭제. Modify `package_alarm_scheduler.dart`(`NotificationSettings.icon: 'ic_stat_alarm'`) + 테스트.
- [ ] 실패 테스트: `settingsFor` 의 알림 아이콘 이름.
- [ ] 좌표는 스펙 §4. 모든 요소가 안전 원(반지름 33) 안인지 계산해 확인.
- [ ] `flutter build apk --debug`. 커밋 `feat(walk): 알람시계 아이콘을 단다`.

### W2-T2: 스플래시

**Files:** `res/drawable/splash_icon.xml`, `launch_background.xml`(drawable · drawable-v21 · drawable-night), `values-v31/styles.xml`, `values-night-v31/styles.xml`, `values/colors.xml`.
- [ ] 빌드 · 에뮬레이터 라이트/다크 시작 스크린샷 · 런처(원형/둥근 사각) · 테마 아이콘 · 알림 상태바 아이콘 스크린샷.
- [ ] 커밋 `feat(walk): 시작 화면을 초록 스플래시로 바꾼다`. 문서 갱신.

---

## 웨이브 3 — 울림 세부 · 건너뛰기 · 미리 알림 · 공휴일

### W3-T1: 포크 — 스누즈 횟수 · 자동 멈춤

**Files:** 포크 pigeon/생성물, `alarm_settings.dart`, `lib/alarm.dart`(`_applyMove`), `AlarmSettings.kt`, `SnoozeCoordinator.kt`, `AlarmService.kt`, `android/src/test/.../SnoozeRuleTest.kt` · `AutoStopTest.kt`, `FORK.md`.

**Interfaces:** Dart `AlarmSettings.snoozeCount: int`(0) · `androidSnoozeLimit: int?` · `androidAutoStopAfter: Duration?`, Dart `AlarmSettings nextAfterSnooze(DateTime next)`(count+1, 한도면 `androidSnoozeDuration: null` · 스누즈 버튼 null). Kotlin 같은 이름 규칙 함수.
- [ ] 실패 테스트(Kotlin · Dart 둘 다): 한도 null → 계속 스누즈 · 한도 3 → 3번째 스누즈 뒤 설정에 스누즈 없음 · `_applyMove` 가 count 를 올림 · 자동 멈춤 지연 계산.
- [ ] 구현(자동 멈춤 Handler 는 끄기 · 스누즈 · 서비스 종료 때 취소). 커밋 `feat(walk): 포크 알람이 스누즈 횟수를 세고 스스로 멈출 수 있다`.

### W3-T2: 도메인 · 데이터 — 울림 세부 설정 · 건너뛰기

**Files:** Create `lib/domain/alarm/entity/alarm_options.dart`. Modify `alarm.dart`, `upcoming_triggers.dart`, `alarm_scheduler.dart`(`snoozeCountOf`, `schedule(..., {int snoozeCount})`), `alarm_use_case.dart`(snooze 간격 · count · `canSnooze` · `skipNext` · `unskip` · `skipOccurrence` · 보존 창 · 지난 skippedAt 정리), `package_alarm_scheduler.dart`(볼륨 · 페이드 · 스누즈 · 한도 · 자동 멈춤 · 지문). Tests 대응.
- [ ] 실패 테스트: 스펙 §7 의 alarm · upcoming · use case · scheduler 항목.
- [ ] 구현. 커밋 여러 개 가능.

### W3-T3: 공휴일 표

**Files:** Create `lib/domain/alarm/holiday/holiday_calendar.dart`, `lib/domain/alarm/holiday/korean_holidays.dart`. Test `test/domain/alarm/holiday/korean_holidays_test.dart`.
- [ ] 2026 · 2027 대한민국 법정 공휴일 · 대체공휴일을 공식 출처(관보 · 인사혁신처 · 우주항공청 월력요항, 2025~2026 의 법 개정 반영: 제헌절 · 노동절 등 공휴일 지정 여부와 2026 지방선거일)로 확인해 표로. 출처 URL 과 확인 날짜를 파일 머리 주석에. 불확실한 항목은 주석에 표시.
- [ ] 실패 테스트 → 구현. 커밋 `feat(walk): 2026 · 2027 공휴일 표를 둔다`.

### W3-T4: 미리 알림 도메인 · Dart 데이터 · 설정

**Files:** Create `lib/domain/alarm/entity/alarm_reminder.dart`, `lib/domain/alarm/reminders.dart`, `lib/domain/alarm/scheduler/reminder_scheduler.dart`, `lib/data/alarm/channel_reminder_scheduler.dart`. Modify `alarm_use_case.dart`(생성자 · `_syncReminders`), `app_settings.dart` · `prefs_settings_repository.dart`(`holidayReminder`), DI. Tests 대응.
- [ ] 실패 테스트: 스펙 §7 의 reminders · use case 미리 알림 diff · channel scheduler · settings 왕복.
- [ ] 구현. 커밋 `feat(walk): 알람 미리 알림을 계산해 네이티브에 넘긴다`.

### W3-T5: 미리 알림 네이티브 · 액션 디스패치

**Files:** 스펙 §4.1 · §4.2 의 Kotlin 파일 · 매니페스트 · `core/background/background_task.dart`(runAlarmResync 일반화) · `main.dart`(`alarmReminderActionMain`) · `main_shell_page.dart`(`reminderAction`). Tests: `background_task_test.dart`, `main_shell_page_test.dart`, Kotlin 저장소 · 재부팅 판정 순수 함수 JUnit.
- [ ] 첫 확인: Dart 커스텀 진입점이 `List<String>` 인자를 받는지(안 되면 채널로 인자 받기).
- [ ] 실패 테스트 → 구현 → `flutter build apk --debug`. 커밋 `feat(walk): 미리 알림을 띄우고 알림에서 건너뛴다`.

### W3-T6: 화면 — 울림 설정 · 건너뛰기 · 칩 · 울림 화면 · 설정 스위치

**Files:** Create `lib/presentation/alarm/widget/ring_settings_section.dart`, `lib/presentation/alarm/widget/alarm_skip_sheet.dart`. Modify 편집 · 목록 · 타일 · 울림 페이지/cubit · 설정 페이지 · ARB. Tests 대응.
- [ ] 실패 테스트: 스펙 §5 · §7 화면 항목.
- [ ] 구현. 커밋 여러 개 가능.

### W3-R: 웨이브 3 리뷰 · 문서 · 에뮬레이터

- [ ] 리뷰 워크플로 → 수정. 문서 갱신.
- [ ] 에뮬레이터: 스파이크 R1~R8(리드 시간을 `--dart-define` 으로 줄여) · 자동 멈춤(앱 종료) · 알림 스누즈 3회 후 버튼 없음 · 스크린샷.
