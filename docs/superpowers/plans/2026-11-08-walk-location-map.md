# walk 위치 기록 · 지도 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** walk 에 끄지 않으면 계속 도는 위치 기록(평소 · 촘촘)과, 그 동선 위에 장소가 태그된 일기를 핀으로 보여 주는 지도(도구 › 지도)를 더한다.

**Architecture:** 기록은 Flutter 없이 도는 Kotlin 포그라운드 서비스가 맡아 앱 전용 SQLite inbox 에 점을 쌓는다. Dart 는 MethodChannel 로 켜고 끄며, 앱이 앞에 올 때 inbox 를 drift `LocationDatabase` 로 옮긴다(수거). 머문 곳 · 선 · 자주 간 곳은 저장하지 않고 도메인 순수 함수로 계산하고, 지도는 `flutter_map` 위에 동선과 일기 핀을 그린다.

**Tech Stack:** Flutter · flutter_bloc · freezed 3 · injectable/get_it · drift · flutter_map 8 + latlong2 · Kotlin(FusedLocationProviderClient, play-services-location) · JUnit4

**Spec:** [2026-11-08-walk-location-map-design.md](../specs/2026-11-08-walk-location-map-design.md)

경로는 따로 적지 않으면 `apps/walk/` 기준이다.

## Global Constraints

- 안드로이드만. `minSdk = 26` 유지.
- 지도는 **도구 탭의 셋째 상단 탭** [알람 · 걷기 · 지도]. 하단 탭은 늘리지 않는다.
- 지도 콘텐츠 · 지도 설정은 **일기 잠금 아래**(`DiaryLockGate` · `pushDiaryRoute`).
- 위치 기록은 이 폰에만. 서버 전송 없음.
- 평소: `PRIORITY_BALANCED_POWER_ACCURACY` · 간격 180초 · 최소 이동 50m · 최대 지연 600초. 촘촘: `PRIORITY_HIGH_ACCURACY` · 간격 5초 · 최소 이동 10m.
- 정지 감지(평소 모드만): Activity Transition `STILL` 진입 → `stillStart = true` 점 하나 남기고 위치 요청 멈춤, 이탈 → 요청 재개 + 즉시 한 점. `ACTIVITY_RECOGNITION` 없으면 정지 감지 없이 3분 간격.
- 머문 곳: 반경 100m 안 10분 이상. 점 사이 30분 넘게 비면 선을 끊는다 — 단 앞 점이 `stillStart` 이고 뒤 점이 100m 안이면 그 사이 전체가 머문 곳. 격자 키 = 위도 · 경도 소수 3자리. 자주 간 곳 상위 10.
- 보관 기간: 3개월 · 1년 · 지우지 않음(기본).
- MethodChannel 이름 `com.karma.walk/location_record`.
- 하루 경계 = 기기 현지 자정. 점 시각은 UTC 로 저장.
- UI 는 CLAUDE.md 의 공통 위젯 · 토큰 규칙(`AppPlaceholder` · `AppConfirmDialog` · `AppListTile` · `AppSnackBar` · `AppColors`/`AppSpacing`/`AppRadius`, 하드코딩 금지).
- Freezed 는 Primary Constructor(단일) · sealed union(변형) 두 패턴만. 분기는 `switch`.
- 문구는 `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` 셋 모두에 넣는다. 키 접두사 `walkMap`. 템플릿 ARB 의 새 키는 모두 `@key.description` 을 단다(`arb_description_convention_test`).
- 테스트 위치는 구현 구조 그대로: `lib/<layer>/<feature>/` ↔ `test/<layer>/<feature>/`. feature 이름은 `location`(도메인 · 데이터) · `map`(화면).
- 생성 파일(`.freezed.dart` · `.g.dart` · `injection.config.dart`)은 `dart run build_runner build --delete-conflicting-outputs` 로만 갱신.

## Review Focus

1. **앱을 밀어 닫거나 재부팅한 뒤** — 기록이 켜져 있었으면 서비스가 다시 떠 있어야 한다. Task 3 의 `LocationRecordRules.shouldRestartOnBoot` 테스트 + 기기 QA L-QA2 · L-QA3.
2. **켜 둔 사이 "항상 허용"을 시스템에서 뺏겼을 때** — 서비스는 조용히 죽지 않고 상태가 `blocked` 가 되며, 지도 칩이 "기록 꺼짐 · 권한 필요"로 보인다. Task 5 `MapRecordCubit` 테스트 `load reports blocked when always permission revoked`.
3. **수거 도중 앱이 죽어 같은 점이 두 번 들어올 때** — 점이 중복되지 않는다. Task 2 `insertAll ignores duplicates` · Task 4 `sync is idempotent when ack fails`.
4. **자정을 걸친 머문 곳 · 날짜 넘김** — 오늘 보기는 현지 자정 기준으로 자른다. Task 1 `stay spanning midnight is clipped to day bounds` · `MapPeriod.day bounds use local midnight`.
5. **정지 감지로 몇 시간 동안 점이 없을 때**(회사에 8시간) — 기록 공백이 아니라 머문 곳 하나로 보인다. Task 1 `still gap within radius is one stay` · `still gap then far point ends stay without line`.
6. **촘촘 기록으로 한 달이 쌓였을 때(수만 점)** — 한 달 보기가 버벅이지 않는다. Task 1 `simplify keeps endpoints and drops points within tolerance` · Task 6 한 달 보기는 `simplify(toleranceM: 30)` 을 거친 점만 그린다는 테스트.

---

### Task 1: 위치 도메인 — 엔티티와 계산

**Files:**
- Create: `lib/domain/location/entity/location_point.dart` · `record_mode.dart` · `stay.dart` · `track_segment.dart` · `day_track.dart` · `frequent_place.dart` · `map_period.dart`
- Create: `lib/domain/location/geo/geo_math.dart` · `lib/domain/location/usecase/track_analyzer.dart` · `frequent_places.dart` · `track_simplifier.dart`
- Modify: `docs/plan.md`(위치 기록 · 지도 착수 — 스펙 링크와 화면 표 행 추가: 지도 `MapTab`, 지도 설정 `MapSettingsPage`)
- Test: `test/domain/location/geo/geo_math_test.dart` · `test/domain/location/usecase/track_analyzer_test.dart` · `frequent_places_test.dart` · `track_simplifier_test.dart` · `test/domain/location/entity/map_period_test.dart`

**Interfaces:**
- Produces:
  - `enum RecordMode { normal, dense }`
  - `LocationPoint({required DateTime recordedAt, required double lat, required double lng, double? accuracyM, required RecordMode mode, bool stillStart = false})` (Freezed primary)
  - `Stay({required DateTime start, required DateTime end, required double lat, required double lng, required int pointCount})` + `Duration get duration`
  - `TrackSegment({required List<LocationPoint> points, required RecordMode mode})`
  - `DayTrack({required List<TrackSegment> segments, required List<Stay> stays})` + `bool get isEmpty`
  - `FrequentPlace({required String gridKey, required double lat, required double lng, required int visits, required Duration total})`
  - `sealed class MapPeriod`: `MapPeriod.day(DateTime date)` = `DayPeriod` · `MapPeriod.month(int year, int month)` = `MonthPeriod` · `MapPeriod.story(Story story)` = `StoryPeriod`, 확장 `({DateTime from, DateTime to}) bounds(DateTime now)` — 현지 시각, 양 끝 포함. 스토리 `endedAt == null` 이면 `to = now`.
  - `double haversineMeters(double lat1, double lng1, double lat2, double lng2)` · `String gridKey(double lat, double lng)` (예: `37.56612, 126.97803` → `'37.566,126.978'`)
  - `class TrackAnalyzer { static const stayRadiusM = 100.0; static const stayMinDuration = Duration(minutes: 10); static const gap = Duration(minutes: 30); DayTrack analyze(List<LocationPoint> points, {DateTime? clipFrom, DateTime? clipTo}); }`
  - `List<FrequentPlace> frequentPlaces(List<Stay> stays, {int limit = 10})`
  - `List<LocationPoint> simplify(List<LocationPoint> points, {required double toleranceM})`

- [ ] **Step 1: 실패하는 테스트 작성**

  - `geo_math_test`: 서울시청(37.5663, 126.9779) ↔ 광화문(37.5759, 126.9768) ≈ 1,070m(±20). `gridKey(37.56612, 126.97803) == '37.566,126.978'`, 음수 경도도 소수 3자리.
  - `track_analyzer_test`:
    - `points within 100m for 10 minutes form one stay` — 1분 간격 11점, 반경 30m → `stays.length == 1`, `duration == 10분`.
    - `9 minutes is not a stay` → `stays` 비었음.
    - `gap over 30 minutes splits segments` — 31분 빈 두 무리 → `segments.length == 2`.
    - `mode change splits segments` — normal 3점 + dense 3점 → 두 구간, 각 `mode` 맞음.
    - `stay spanning midnight is clipped to day bounds` — 23:50~00:20 머묾, `clipFrom/clipTo` = 그날 → `stay.end == 23:59:59.999`.
    - `empty input gives empty track` → `isEmpty`.
    - `still gap within radius is one stay` — 09:00 `stillStart` 점, 다음 점 17:00 같은 자리(30m) → 구간이 끊기지 않고 `stays.single` 이 09:00~17:00.
    - `still gap then far point ends stay without line` — 09:00 `stillStart`, 다음 점 17:00 2km 밖 → 머문 곳 09:00~16:59:59.999(뒤 점 1ms 전), 두 점 사이 선 없음(구간 2개).
    - `gap without stillStart still splits` — 일반 점 뒤 31분 공백 → 머문 곳 아님, 구간 2개.
  - `frequent_places_test`: 같은 격자 3번 · 다른 격자 2번 → 순서 · `visits` 맞음. 방문 횟수 같으면 `total` 큰 쪽이 먼저. 15곳이면 10개만.
  - `track_simplifier_test`: `simplify keeps endpoints and drops points within tolerance` — 직선 위 100점 → 결과 2점(처음 · 끝). 꺾인 점(직선에서 200m) 은 남음. 2점 이하 입력은 그대로.
  - `map_period_test`: `MapPeriod.day bounds use local midnight` — `day(2026-11-08 15:00)` → from `2026-11-08 00:00`, to `2026-11-08 23:59:59.999`. `month(2026, 2)` → 2/1 ~ 2/28 끝. 열린 스토리 → `to == now`.

- [ ] **Step 2: 실패 확인** — `cd apps/walk && flutter test test/domain/location` → FAIL(정의 없음)
- [ ] **Step 3: 엔티티 · 함수 구현.** `simplify` 는 Douglas–Peucker(거리는 위도 기준 등장방형 근사 미터). `analyze` 는 점을 시간순 정렬 → 30분 간격 · 모드 변화로 구간 분리(앞 점이 `stillStart` 면 Global Constraints 의 예외 규칙: 100m 안이면 이어 붙여 머문 곳, 밖이면 머문 곳을 뒤 점 1ms 전까지로 닫고 구간 분리) → 각 구간에서 앞 점부터 반경 100m 안에 머무는 최장 연속을 찾아 10분 이상이면 `Stay`(중심 = 평균). 이어서 `dart run build_runner build --delete-conflicting-outputs`.
- [ ] **Step 4: 통과 확인** — `flutter test test/domain/location` → PASS
- [ ] **Step 5: `docs/plan.md` 착수 반영 후 커밋**

```bash
git add apps/walk/lib/domain/location apps/walk/test/domain/location apps/walk/docs/plan.md
git commit -m "feat(walk): 위치 도메인 — 머문 곳 · 구간 · 자주 간 곳 · 단순화"
```

---

### Task 2: 위치 저장소 — drift `LocationDatabase`

**Files:**
- Create: `lib/data/location/database/location_database.dart` · `tables.dart` · `lib/data/location/drift_location_repository.dart` · `lib/data/location/prefs_location_preferences.dart`
- Create: `lib/domain/location/repository/location_repository.dart` · `location_preferences.dart` · `lib/domain/location/entity/record_retention.dart`
- Modify: `lib/core/di/register_module.dart`(`LocationDatabase(driftDatabase(name: 'location'))` + dispose, 일기 DB 와 같은 방식)
- Test: `test/data/location/drift_location_repository_test.dart` · `prefs_location_preferences_test.dart`

**Interfaces:**
- Consumes: Task 1 `LocationPoint` · `RecordMode`
- Produces:
  - `abstract interface class LocationRepository { Future<int> insertAll(List<LocationPoint> points); Future<List<LocationPoint>> pointsBetween(DateTime from, DateTime to); Future<bool> hasAnyPoint(); Future<int> purgeBefore(DateTime cutoff); Future<void> deleteAll(); Future<String?> placeName(String gridKey); Future<void> savePlaceName(String gridKey, String name); }` — `insertAll` 은 새로 들어간 개수.
  - `enum RecordRetention { threeMonths, oneYear, never }` + `DateTime? cutoff(DateTime now)`(never → null)
  - `abstract interface class LocationPreferences { RecordRetention get retention; Future<void> setRetention(RecordRetention value); }` 기본 `never`
  - 테이블: `location_points(id autoinc, recorded_at, lat, lng, accuracy_m nullable, mode, still_start bool default false)` + **UNIQUE(recorded_at, lat, lng)** + 인덱스 `recorded_at` · `place_names(grid_key PK, name, updated_at)`. schemaVersion 1, `storeDateTimeAsText: true`.

- [ ] **Step 1: 실패하는 테스트** (`NativeDatabase.memory()`)
  - `insertAll ignores duplicates` — 같은 3점 두 번 → 둘째 반환 0, 총 3.
  - `stillStart round trip` — true 로 넣은 점이 true 로 돌아온다.
  - `pointsBetween is inclusive and ordered` — 경계 시각 점 포함, 오름차순.
  - `purgeBefore deletes older points only` · `deleteAll clears points and place names`.
  - `placeName round trip` · `hasAnyPoint`.
  - prefs: 기본 `never`, 저장 뒤 다시 읽음. `RecordRetention.threeMonths.cutoff(2026-11-08)` == `2026-08-08`.
- [ ] **Step 2: FAIL 확인** — `flutter test test/data/location`
- [ ] **Step 3: 구현** — `insertAll` 은 `InsertMode.insertOrIgnore` 배치, 시각은 UTC 로 저장해 현지로 돌려준다. build_runner.
- [ ] **Step 4: PASS 확인** — `flutter test test/data/location`
- [ ] **Step 5: 커밋** — `feat(walk): 위치 점 저장소(LocationDatabase) · 보관 기간 설정`

---

### Task 3: 네이티브 기록 서비스(Kotlin)

**Files:**
- Create: `android/app/src/main/kotlin/com/karma/walk/location/LocationRecordService.kt` · `LocationInbox.kt` · `LocationRecordPrefs.kt` · `LocationRecordRules.kt` · `LocationBootReceiver.kt` · `LocationRecordChannel.kt` · `ActivityTransitionReceiver.kt`
- Modify: `android/app/src/main/kotlin/com/karma/walk/MainActivity.kt`(채널 등록) · `android/app/src/main/AndroidManifest.xml` · `android/app/build.gradle.kts`(`com.google.android.gms:play-services-location:21.3.0` — Activity Recognition 도 이 라이브러리)
- Test: `android/app/src/test/kotlin/com/karma/walk/LocationRecordRulesTest.kt`

**Interfaces:**
- Produces (채널 `com.karma.walk/location_record`):
  - `start({mode: "normal"|"dense"})` → null · `stop()` → null · `setMode({mode})` → null
  - `status()` → `{"state": "off"|"running"|"blocked", "mode": "normal"|"dense", "stillDetection": Boolean}` — `blocked` = 켜짐으로 저장됐지만 `ACCESS_BACKGROUND_LOCATION` 없음 또는 위치 서비스 꺼짐. `stillDetection` = 활동 인식 권한이 있어 정지 감지가 도는지
  - `drain({limit: Int})` → `List<Map>`: `{"id": Long, "t": epochMillisUtc, "lat", "lng", "acc": Double?, "mode", "still": Boolean}` (id 오름차순)
  - `ack({upToId: Long})` → null (그 id 이하 삭제)
- `object LocationRecordRules { data class Request(val priority: Int, val intervalMs: Long, val minDistanceM: Float, val maxDelayMs: Long); fun requestFor(mode: String): Request; fun shouldRestartOnBoot(enabled: Boolean, hasBackgroundPermission: Boolean): Boolean; fun stateOf(enabled: Boolean, hasBackgroundPermission: Boolean, locationOn: Boolean): String; enum class Phase { MOVING, STILL }; sealed interface Action { object Pause; object ResumeAndFix; object None }; fun onTransition(mode: String, phase: Phase, enteredStill: Boolean, stillDetection: Boolean): Pair<Phase, Action> }`

- [ ] **Step 1: 실패하는 JVM 테스트** `LocationRecordRulesTest`
  - `normal request` → priority `Priority.PRIORITY_BALANCED_POWER_ACCURACY`(102), 180_000ms, 50f, 600_000ms. `dense` → `PRIORITY_HIGH_ACCURACY`(100), 5_000ms, 10f, 0. 모르는 값 → normal.
  - `shouldRestartOnBoot`: (true,true) → true, (true,false) → false, (false,*) → false.
  - `stateOf`: 꺼짐 → "off", 켜짐 + 권한 + 위치 on → "running", 켜짐 + 권한 없음 또는 위치 off → "blocked".
  - `onTransition`: normal + MOVING + 정지 진입 → (STILL, Pause). normal + STILL + 정지 이탈 → (MOVING, ResumeAndFix). 같은 상태로 다시 들어오면 None(중복 이벤트). dense 면 항상 (MOVING, None). `stillDetection == false` 면 항상 (MOVING, None).
  (상수는 Play Services 에 의존하지 않게 숫자로 둔다 — JVM 테스트에서 클래스 로딩을 피한다.)
- [ ] **Step 2: FAIL 확인** — `cd apps/walk/android && ./gradlew :app:testDebugUnitTest --tests '*LocationRecordRulesTest*'`
- [ ] **Step 3: 구현**
  - 정지 감지: 서비스가 normal 모드로 시작하면 `ActivityRecognition.getClient(...).requestActivityTransitionUpdates`(`STILL` ENTER · EXIT) 를 `ActivityTransitionReceiver` 행 `PendingIntent`(FLAG_MUTABLE)로 건다. 리시버는 서비스에 `ACTION_TRANSITION` 인텐트(진입/이탈)를 보내고, 서비스는 `onTransition` 결과대로 Pause = `getCurrentLocation` 한 점을 `still = 1` 로 inbox 에 쓰고 `removeLocationUpdates` · ResumeAndFix = `requestLocationUpdates` 다시 + `getCurrentLocation` 한 점. dense 로 바뀌거나 stop 이면 전환 구독 해제. 현재 Phase 는 prefs 에 둬서 서비스 재시작 뒤에도 이어 간다.
  - Manifest: `ACCESS_BACKGROUND_LOCATION` · `FOREGROUND_SERVICE_LOCATION` · `ACTIVITY_RECOGNITION` · `com.google.android.gms.permission.ACTIVITY_RECOGNITION`(API 26~28) 권한, `<receiver android:name=".location.ActivityTransitionReceiver" android:exported="false"/>`, `<service android:name=".location.LocationRecordService" android:foregroundServiceType="location" android:exported="false"/>`, `<receiver android:name=".location.LocationBootReceiver" android:exported="false">` + `BOOT_COMPLETED` · `MY_PACKAGE_REPLACED`.
  - 서비스: `START_STICKY`. 시작 시 알림 채널 `location_record`(중요도 LOW), 알림 문구 "위치 기록 중 · 평소/촘촘" + [끄기] 액션(서비스에 stop 인텐트). `requestLocationUpdates(LocationRequest(rules), callback, looper)` → 받은 점을 `LocationInbox.insert`. 권한이 사라지면 업데이트를 멈추고 `stopSelf()`(prefs 의 enabled 는 유지 → `status` 가 `blocked`).
  - `LocationInbox`: `SQLiteOpenHelper("location_inbox.db")`, 테이블 `points(id INTEGER PK AUTOINCREMENT, t INTEGER, lat REAL, lng REAL, acc REAL, mode TEXT, still INTEGER DEFAULT 0)`.
  - `LocationRecordPrefs`: SharedPreferences `location_record` 의 `enabled` · `mode`.
  - 부트 리시버: `shouldRestartOnBoot` 이면 `startForegroundService`.
  - 채널: 위 메서드를 서비스 · inbox · prefs 로 잇는다. `start` 는 prefs 저장 후 서비스 시작, `stop` 은 prefs 끄고 서비스 종료, `setMode` 는 prefs 저장 후 실행 중이면 서비스에 모드 인텐트.
- [ ] **Step 4: PASS 확인** — 같은 gradle 명령 → PASS, 그리고 `cd apps/walk && flutter build apk --debug` 성공
- [ ] **Step 5: 커밋** — `feat(walk): 위치 기록 포그라운드 서비스 · inbox · 부트 복구`

---

### Task 4: Dart 브리지 · 수거

**Files:**
- Create: `lib/domain/location/recorder/location_recorder.dart` · `recorder_status.dart` · `lib/data/location/channel_location_recorder.dart` · `lib/domain/location/usecase/location_sync.dart`
- Test: `test/data/location/channel_location_recorder_test.dart` · `test/domain/location/usecase/location_sync_test.dart`

**Interfaces:**
- Consumes: Task 2 `LocationRepository` · `LocationPreferences` · `RecordRetention.cutoff`; Task 3 채널 계약
- Produces:
  - `sealed class RecorderStatus`: `RecorderStatus.off()` = `RecorderOff` · `.running(RecordMode mode, {required bool stillDetection})` = `RecorderRunning` · `.blocked(RecordMode mode)` = `RecorderBlocked`
  - `abstract interface class LocationRecorder { Future<RecorderStatus> status(); Future<void> start(RecordMode mode); Future<void> stop(); Future<void> setMode(RecordMode mode); Future<List<({int id, LocationPoint point})>> drain({int limit = 2000}); Future<void> ack(int upToId); }`
  - `@injectable class LocationSync { Future<int> run(); }` — 반환은 새로 넣은 점 개수. 동시에 두 번 불리면 둘째는 첫째의 Future 를 기다린다.

- [ ] **Step 1: 실패하는 테스트**
  - 채널: `TestDefaultBinaryMessengerBinding` 으로 가짜 응답 → `status` 매핑 3종, `drain` 이 epochMillis 를 UTC `DateTime` 으로, `acc` null 허용, `still: true` → `stillStart: true`, `stillDetection` 매핑, `start(RecordMode.dense)` 가 `{"mode": "dense"}` 를 보냄.
  - `location_sync_test`(가짜 recorder · 메모리 repo):
    - `drains until empty and acks last id` — 2000 + 500 점 → `insertAll` 두 번, `ack(마지막 id)` 두 번, 반환 2500.
    - `sync is idempotent when ack fails` — 첫 ack 에서 throw → 다시 `run()` 하면 같은 점이 또 오지만 총 개수 그대로.
    - `purges by retention after drain` — `oneYear` 면 `purgeBefore(now - 1년)` 호출, `never` 면 호출 없음.
    - `concurrent run shares one pass` — 동시에 두 번 → drain 한 바퀴.
- [ ] **Step 2: FAIL 확인** — `flutter test test/data/location/channel_location_recorder_test.dart test/domain/location/usecase/location_sync_test.dart`
- [ ] **Step 3: 구현** + DI 등록(`@LazySingleton(as: LocationRecorder)`) + build_runner
- [ ] **Step 4: PASS 확인** — 같은 명령
- [ ] **Step 5: 커밋** — `feat(walk): 위치 기록 채널 브리지 · inbox 수거(LocationSync)`

---

### Task 5: 기록 켜기 흐름 · 지도 설정

**Files:**
- Create: `lib/data/location/background_location_access.dart` · `lib/presentation/map/cubit/map_record_cubit.dart` · `map_record_state.dart` · `lib/presentation/settings/page/map_settings_page.dart`
- Modify: `lib/presentation/settings/open_settings.dart`(`SettingsTarget.map` 추가 — 잠금 아래로 연다) · `lib/presentation/settings/page/app_settings_page.dart`(기능별 설정 바로가기에 "지도 설정") · l10n arb 3종
- Test: `test/presentation/map/cubit/map_record_cubit_test.dart` · `test/presentation/settings/page/map_settings_page_test.dart`

**Interfaces:**
- Consumes: Task 4 `LocationRecorder` · `RecorderStatus`; Task 2 `LocationPreferences` · `LocationRepository.deleteAll`
- Produces:
  - `enum AlwaysAccess { granted, needsSettings, denied }` · `abstract interface class BackgroundLocationAccess { Future<AlwaysAccess> check(); Future<AlwaysAccess> request(); Future<void> openAppSettings(); Future<void> openBatterySettings(); }` (permission_handler 의 `locationWhenInUse` → `locationAlways` → `activityRecognition` → `notification`. 안드로이드 11+ 에서 always 를 대화상자로 못 받으면 `needsSettings`. 활동 인식 거부는 결과에 영향 없음 — 기록은 켜고 정지 감지만 꺼진다)
  - `MapRecordState({required RecorderStatus status, required bool busy, AlwaysAccess? access})` (Freezed primary)
  - `MapRecordCubit { Future<void> load(); Future<void> enable(); Future<void> disable(); Future<void> setDense(bool dense); Future<void> setRetention(RecordRetention value); Future<void> deleteAll(); }`

- [ ] **Step 1: 실패하는 테스트**
  - cubit: `enable starts normal when always granted` → `start(normal)`, 상태 running(normal). `enable does not start when needsSettings` → start 없음, `access == needsSettings`. `setDense(true)` → `setMode(dense)`. `disable` → `stop()`, off. `load reports blocked when always permission revoked` — recorder 가 `blocked` 를 주면 상태 그대로 blocked. `deleteAll` → repository `deleteAll`. `enable starts even when activity recognition denied` → running(normal, stillDetection: false).
  - 설정 화면: 행 — 위치 기록 스위치 · 촘촘 스위치(기록 꺼짐이면 비활성) · 보관 기간(시트 3택, 기본 "지우지 않음") · 배터리 최적화 안내 · 권한 상태(위치 항상 허용 · 신체 활동 — 없으면 "정지 감지 꺼짐" + 설정 열기 · 알림) · 모두 지우기(누르면 `AppConfirmDialog`, 확인해야 `deleteAll`).
- [ ] **Step 2: FAIL 확인** — `flutter test test/presentation/map/cubit test/presentation/settings/page/map_settings_page_test.dart`
- [ ] **Step 3: 구현** — 화면은 기존 `WalkSettingsPage` 구성을 따른다. 문구 키 `walkMapSettings*`.
- [ ] **Step 4: PASS 확인** — 같은 명령
- [ ] **Step 5: 커밋** — `feat(walk): 위치 기록 켜기 흐름 · 지도 설정`

---

### Task 6: 지도 데이터 cubit

**Files:**
- Create: `lib/presentation/map/cubit/map_view_cubit.dart` · `map_view_state.dart` · `lib/domain/location/usecase/stay_namer.dart`
- Test: `test/presentation/map/cubit/map_view_cubit_test.dart` · `test/domain/location/usecase/stay_namer_test.dart`

**Interfaces:**
- Consumes: Task 1 전부 · Task 2 `LocationRepository` · Task 4 `LocationSync` · 기존 `DiaryRepository.searchEntries(from:, to:, limit:)` · `PlaceNamer.nameFor`
- Produces:
  - `StayNamer { Future<String?> nameFor(double lat, double lng); }` — 격자 캐시(`placeName`/`savePlaceName`) 먼저, 없으면 `PlaceNamer`; `offline` · `noName` 이면 null(캐시 안 함)
  - `sealed class MapViewState`: `.loading(MapPeriod period)` · `.ready(MapViewData data)` · `.empty(MapPeriod period)`
  - `MapViewData({required MapPeriod period, required DayTrack track, required List<FrequentPlace> frequent, required List<DiaryEntry> entries, required Map<String, String> stayNames})` — `stayNames` 키는 `gridKey`
  - `MapViewCubit { Future<void> show(MapPeriod period); Future<void> refresh(); }` — `refresh` = `LocationSync.run()` 뒤 현재 기간 다시 읽기

- [ ] **Step 1: 실패하는 테스트**
  - `show day loads points, stays and entries with coordinates` — 좌표 없는 일기는 빠짐, 휴지통은 repository 가 이미 뺌.
  - `month view simplifies points` — 같은 직선 위 1,000점 → `track.segments` 점 합이 10 미만 (`simplify(toleranceM: 30)`), `frequent` 는 단순화 전 점으로 계산.
  - `day view does not simplify`.
  - `empty when no points and no entries` → `.empty`.
  - `entries limit is 300 per period` — `searchEntries(limit: 300)` 로 부른다.
  - `refresh runs sync before reload`.
  - stay_namer: 캐시 적중 시 PlaceNamer 호출 없음, offline 이면 null 이고 저장 없음.
- [ ] **Step 2: FAIL 확인** — `flutter test test/presentation/map/cubit/map_view_cubit_test.dart test/domain/location/usecase/stay_namer_test.dart`
- [ ] **Step 3: 구현** — 오늘 · 스토리는 `analyze(clipFrom/clipTo = bounds)`, 한 달은 `analyze` 로 stays/frequent 를 얻고 그리기용 구간 점은 `simplify(toleranceM: 30)`. 머문 곳 이름은 오늘 보기에서만 구한다.
- [ ] **Step 4: PASS 확인**
- [ ] **Step 5: 커밋** — `feat(walk): 지도 보기 데이터(MapViewCubit) · 머문 곳 이름`

---

### Task 7: 지도 화면 `MapTab` + 도구 셋째 탭

**Files:**
- Create: `lib/presentation/map/page/map_tab.dart` · `lib/presentation/map/widget/track_map.dart` · `record_chip.dart` · `entry_pin.dart` · `timeline_sheet.dart` · `frequent_sheet.dart` · `story_picker_sheet.dart` · `period_header.dart`
- Modify: `pubspec.yaml`(`flutter_map: ^8.3.2` · `latlong2: ^0.10.1` — pawlog 과 같은 버전) · `lib/presentation/shell/page/tools_tab.dart`(`enum ToolsSection { alarm, walk, map }`, 탭 · ⋮ `FeatureMenu(settings: SettingsTarget.map)`, 잠긴 동안 `showFeatureSettings: false`) · `lib/presentation/shell/page/main_shell_page.dart`(cubit 제공 · 앱이 앞에 올 때 `MapViewCubit.refresh`) · l10n arb 3종
- Test: `test/presentation/map/page/map_tab_test.dart` · `test/presentation/shell/page/tools_tab_test.dart`(기존 파일에 지도 탭 케이스 추가)

**Interfaces:**
- Consumes: Task 5 `MapRecordCubit` · Task 6 `MapViewCubit` · `DiaryLockGate` · `openStoryViewer(context, ViewerSource.entries(ids, title), entryId:)`
- Produces: `class MapTab extends StatelessWidget { const MapTab({required bool active}); }` · `ToolsSection.map`

- [ ] **Step 1: 실패하는 위젯 테스트** (`TrackMap` 은 타일 없이 그리도록 `tileLayerBuilder` 주입 가능하게 — 테스트는 빈 레이어)
  - `locked shows lock input, not map` — `DiaryLockCubit` 잠김 → 지도 · 칩 없음.
  - `relocking closes open timeline sheet` — 시트 연 상태에서 잠김 → 시트 닫힘.
  - `first run shows placeholder with enable button` — 점 없음 + 기록 off → `AppPlaceholder` + [위치 기록 켜기] → `MapRecordCubit.enable` 호출.
  - `segment switches period` — [오늘 · 한 달 · 스토리] 누르면 `show(DayPeriod/MonthPeriod)`, 스토리는 피커 시트(진행 중 먼저, `daily` 제외).
  - `period header cannot go to future` — 오늘이면 › 비활성.
  - `record chip toggles dense` · `blocked shows record-off chip` — blocked 상태면 "기록 꺼짐" 칩, 누르면 `enable`.
  - `entry pin opens viewer` — 사진 있는 일기 핀 탭 → `openStoryViewer` 가 그 entryId 로.
  - `empty period shows placeholder over map`.
  - tools_tab: 상단 탭이 3개이고 지도 탭에서 ⋮ 에 "지도 설정".
- [ ] **Step 2: FAIL 확인** — `flutter test test/presentation/map test/presentation/shell`
- [ ] **Step 3: 구현** — 선: 촘촘 구간은 굵게(불투명), 평소는 얇고 옅게(같은 `AppColors` 색). 머문 곳은 원 마커. 같은 자리 핀은 화면 거리 기준으로 묶어 숫자 표시(알고리즘은 빌더 판단). 타일은 `https://tile.openstreetmap.org/{z}/{x}/{y}.png` + `userAgentPackageName: 'com.karma.walk'`. 시트는 `DraggableScrollableSheet`, 행은 `AppListTile`.
- [ ] **Step 4: PASS 확인** — 같은 명령 + `flutter analyze` 0
- [ ] **Step 5: 커밋** — `feat(walk): 도구 › 지도 — 오늘 · 한 달 · 스토리 동선과 일기 핀`

---

### Task 8: 스토리 뷰어 "지도로 보기"

**Files:**
- Modify: `lib/presentation/diary/viewer/story_viewer_page.dart`(⋮ 에 "지도로 보기", 스토리 소스이고 기본 스토리가 아닐 때만) · `lib/presentation/shell/page/main_shell_page.dart`(도구 탭 + `ToolsSection.map` 으로 바꾸고 `MapViewCubit.show(MapPeriod.story(story))`) · l10n arb 3종
- Test: `test/presentation/diary/viewer/story_viewer_page_test.dart`(케이스 추가)

**Interfaces:**
- Consumes: Task 7 `ToolsSection.map` · Task 6 `MapViewCubit.show`
- Produces: 셸 콜백 `void openMapForStory(Story story)` — 뷰어는 이를 상위에서 받는다(전역 상태 없이 기존 셸 콜백 방식대로).

- [ ] **Step 1: 실패하는 테스트** — `menu shows map entry for story source` · `hidden for daily story and filter source` · `tapping pops viewer and calls openMapForStory with that story`.
- [ ] **Step 2: FAIL 확인** — `flutter test test/presentation/diary/viewer/story_viewer_page_test.dart`
- [ ] **Step 3: 구현**
- [ ] **Step 4: PASS 확인**
- [ ] **Step 5: 커밋** — `feat(walk): 스토리 뷰어에서 지도로 보기`

---

### Task 9: 마무리 — 문서 · 전체 검증

**Files:**
- Modify: `docs/plan.md`(화면 표 · 결정 · 권한 반영) · `docs/status.md`(위치 기록 · 지도 행, 코드 완료 · 기기 QA 대기) · `docs/history.md` · `docs/testing.md`(기기 QA 시나리오 L-QA1~7) · 스펙 상태줄 "구현됨"

- [ ] **Step 1: `testing.md` 에 기기 QA 시나리오 작성**
  - L-QA1 켜기 흐름: 앱 사용 중 → 항상 허용(설정 화면 이동) → 알림, 상시 알림이 뜬다.
  - L-QA2 앱을 최근 앱에서 밀어 닫고 30분 걸은 뒤 다시 열면 그 동선이 보인다.
  - L-QA3 재부팅 뒤 앱을 열지 않고 이동 → 나중에 열면 기록돼 있다.
  - L-QA4 평소 모드 하루 배터리 사용량(설정 › 배터리)에서 Life Tool 비율 기록.
  - L-QA5 촘촘 칩 켜고 걷기 → 선이 길을 따라간다. 끄면 성긴 점으로 돌아간다.
  - L-QA7 정지 감지: 책상에 폰을 두고 1시간 → 그 사이 inbox 점이 늘지 않고(디버그 로그), 지도에는 머문 곳 하나로 보인다. 들고 걸으면 몇 분 안에 다시 점이 찍힌다.
  - L-QA6 장소 태그된 사진 일기가 핀으로 보이고 누르면 뷰어가 열린다. 잠그면 지도가 가려진다.
- [ ] **Step 2: 전체 검증** — `cd apps/walk && flutter analyze` → 0 issues · `flutter test` → 전부 통과 · `cd ../trader && flutter test test/convention` → 문서 링크 통과 · `cd ../walk/android && ./gradlew :app:testDebugUnitTest` → 통과
- [ ] **Step 3: 커밋** — `docs(walk): 위치 기록 · 지도 반영 · 기기 QA 시나리오`
