# pawlog W7 session (일시정지 · 복구) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 산책을 일시정지 · 재개할 수 있고, 앱이 강제 종료돼도 진행 중(또는 저장 전) 산책이 다음 실행에 되살아난다.

**Architecture:** `WalkSession` 이 멈춤 시간을 들고 `elapsedAt` 이 그것을 뺀다. `GeolocatorWalkTracker` 가
`pause` · `unpause` 를 하고, 새 `ActiveWalkStore`(drift 스키마 v2 의 두 테이블)에 세션을 직렬 큐로 써 두었다가
`restore()` 로 읽는다. `bootstrap` 이 DI 직후 `restore()` 를 부른다. 화면은 추적기 상태만 보므로 버튼 · 문구만 더한다.

**Tech Stack:** Flutter · drift 2.34 · freezed 3 · injectable/get_it · flutter_bloc · geolocator(`packages/location`) · gen-l10n · bloc_test · mocktail

**Spec:** [docs/superpowers/specs/2026-10-16-pawlog-pause-recovery-design.md](../specs/2026-10-16-pawlog-pause-recovery-design.md) ·
화면 · 문자열 · 완료 조건 [apps/pawlog/docs/features/session/plan.md](../../../apps/pawlog/docs/features/session/plan.md)

## Global Constraints

- 멈춤 중에도 위치 스트림은 끊지 않고 점을 버린다. 재개 뒤 첫 수락 점은 거리 0 m 를 더한다
- `elapsedAt(now)` = `(endedAt ?? now) − startedAt − pausedDuration − 진행 중 멈춤`, 0 미만이면 0. 저장 시간(`walks.duration_seconds`)은 이 값
- 앱이 죽어 있던 동안은 걸은 시간으로 센다. 멈춤 상태로 죽었으면 멈춤으로 센다
- 저장소 쓰기는 순서 보존 직렬 큐. 실패는 `debugPrint` 만, 추적은 계속
- drift `schemaVersion` 2, `onUpgrade` `from < 2` 에서 `active_walks` · `active_walk_points` 를 만든다. 기존 테이블 · 행은 그대로. 새 테이블에 외래 키 없음
- 연두(`accent`)는 진행 중에만 — 멈춤 중 배너에 연두 점 없음. 화면당 주 버튼 하나(끝내기), 일시정지는 `AppButton.secondary`
- 화면에 `Colors.*` · 숫자 여백 · `BorderRadius.circular(n)` 금지 — `Pawlog*` 토큰 · `Theme.of(context)`
- Freezed 단일 모델은 primary constructor, 상태는 sealed union. 분기는 `switch` 패턴
- 생성 파일은 `dart run build_runner build --delete-conflicting-outputs`(apps/pawlog), l10n 은 `flutter gen-l10n`(packages/l10n). 손으로 고치지 않는다
- 테스트는 `lib/` 와 1:1 경로. 문자열 키 · 값은 feature plan 의 표 그대로(ko 에만 `@` 설명)
- 커밋 메시지 끝 `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

## Review Focus

1. **멈춤 중 강제 종료 → 복구** — `paused_at` 이 남아 복구 뒤에도 멈춤 중이고, 그동안의 시간이 걸은 시간에 들어가지 않아야 한다 → Task 5 테스트
2. **v1 사용자의 업그레이드** — 기존 기록이 있는 DB 가 v2 로 열릴 때 행이 사라지거나 열기가 실패하면 안 된다 → Task 4 마이그레이션 테스트
3. **저장소 쓰기 실패 · 느린 쓰기** — 쓰기가 던져도 점은 계속 쌓이고, 쓰기 순서가 뒤바뀌지 않는다(점 seq 가 begin 보다 먼저 쓰이지 않음) → Task 5 테스트
4. **저장 · 버리기 뒤 남은 스냅샷** — `clear()` 가 저장소를 비우지 않으면 다음 실행에 유령 배너가 뜬다 → Task 5 테스트
5. **멈춤 중 끝내기** — 저장되는 시간이 멈춘 시간을 뺀 값이고 `pausedAt` 이 닫힌다 → Task 1 · Task 2 테스트

---

## File Structure

| 파일 | 책임 |
|---|---|
| Modify `lib/domain/tracking/entity/walk_session.dart` | `pausedDuration` · `pausedAt` · `isPaused` · `elapsedAt` |
| Modify `lib/domain/walk/entity/walk_draft.dart` · `usecase/scenario/save_walk_scenario.dart` · `presentation/walk/cubit/walk_edit_form.dart` | 저장 시간 = 걸은 시간 |
| Modify `lib/domain/tracking/repository/walk_tracker.dart` · `lib/data/tracking/geolocator_walk_tracker.dart` · `lib/domain/walk/usecase/walk_use_case.dart` | pause · unpause · restore |
| Create `lib/domain/tracking/entity/active_walk_snapshot.dart` · `repository/active_walk_store.dart` | 복구 저장소 경계 |
| Modify `lib/data/database/tables.dart` · `walk_database.dart` | v2 테이블 · 마이그레이션 |
| Create `lib/data/tracking/drift_active_walk_store.dart` | drift 구현 |
| Modify `lib/core/bootstrap.dart` | 시작 때 `restore()` |
| Modify `lib/presentation/tracking/cubit/active_walk_cubit.dart` · `page/active_walk_page.dart` · `widget/active_walk_banner.dart` | 버튼 · 표시 |
| Modify `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` | 문자열 4 |
| Tests | 각 `lib/` 경로에 맞춰 `test/` |

---

### Task 1: 세션 멈춤 시간과 저장 시간

**Files:**
- Modify: `apps/pawlog/lib/domain/tracking/entity/walk_session.dart`
- Modify: `apps/pawlog/lib/domain/walk/entity/walk_draft.dart`, `apps/pawlog/lib/domain/walk/usecase/scenario/save_walk_scenario.dart`, `apps/pawlog/lib/presentation/walk/cubit/walk_edit_form.dart`
- Test: `apps/pawlog/test/domain/tracking/entity/walk_session_test.dart` (새 파일), 기존 `save_walk_scenario` · `walk_edit_cubit` 테스트(있으면 그 파일에 추가)

**Interfaces:**
- Produces:
  - `WalkSession({required List<String> dogIds, required DateTime startedAt, DateTime? endedAt, required List<WalkTrackPoint> points, required double distanceMeters, Duration pausedDuration = Duration.zero, DateTime? pausedAt})`
  - `bool get isPaused`, `Duration elapsedAt(DateTime now)`
  - `WalkDraft({…기존…, required Duration duration})`
- 기존 `WalkSession(...)` 호출부는 새 필드가 기본값이라 그대로 컴파일된다

- [ ] **Step 1: 실패하는 테스트** — `walk_session_test.dart`:
  - 멈춤 없음: `startedAt` 9:00, `now` 9:30 → 30분
  - 지난 멈춤 합 5분 → 25분
  - 지금 멈춤 중(`pausedAt` 9:20, 합 5분), `now` 9:30 → 15분이고 `now` 9:40 이어도 15분
  - 끝난 세션(`endedAt` 9:30, 합 5분): `now` 와 무관하게 25분
  - 끝났는데 `pausedAt` 이 남은 세션(`endedAt` 9:30, `pausedAt` 9:25, 합 0): 25분
  - 음수 방지: 합이 전체보다 크면 `Duration.zero`
  - `isPaused` 는 `pausedAt != null`
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/pawlog && flutter test test/domain/tracking/entity/walk_session_test.dart`
- [ ] **Step 3: 구현** — 필드 두 개를 primary constructor 에 더한다(`@override final …`). `elapsedAt`:

```dart
  Duration elapsedAt(DateTime now) {
    final end = endedAt ?? now;
    final pausedAt = this.pausedAt;
    final current = pausedAt == null || end.isBefore(pausedAt)
        ? Duration.zero
        : end.difference(pausedAt);
    final value = end.difference(startedAt) - pausedDuration - current;
    return value.isNegative ? Duration.zero : value;
  }
```

- [ ] **Step 4: 저장 시간** — `WalkDraft` 에 `required Duration duration`. `WalkEditForm.toDraft()` 는
  `duration: session.elapsedAt(session.endedAt ?? session.startedAt)`. `SaveWalkScenario` 는 `duration: draft.duration`.
  `WalkDraft(` 를 만드는 테스트 · 코드는 모두 `duration:` 을 넘기게 고친다(`grep -rn "WalkDraft(" apps/pawlog`).
  테스트 추가: 멈춤 10분이 있는 세션의 `toDraft().duration` 이 전체 − 10분, `SaveWalkScenario` 가 그 값을 `Walk.duration` 으로 저장.
- [ ] **Step 5: 생성 · 전체 테스트 · 분석** — `dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test`
- [ ] **Step 6: 커밋** — `feat(pawlog): 산책 세션이 멈춘 시간을 빼고 시간을 센다`

---

### Task 2: 추적기 일시정지 · 재개

**Files:**
- Modify: `apps/pawlog/lib/domain/tracking/repository/walk_tracker.dart`, `apps/pawlog/lib/data/tracking/geolocator_walk_tracker.dart`, `apps/pawlog/lib/domain/walk/usecase/walk_use_case.dart`
- Test: `apps/pawlog/test/data/tracking/geolocator_walk_tracker_test.dart`, 유스케이스 테스트(있으면)

**Interfaces:**
- Consumes: Task 1 의 `WalkSession.pausedDuration` · `pausedAt`
- Produces: `WalkTracker.pause() → Future<Result<void>>`, `WalkTracker.unpause() → Future<Result<void>>`; `WalkUseCase.pauseWalk()` · `unpauseWalk()`(같은 반환형)

- [ ] **Step 1: 실패하는 테스트** (기존 `geolocator_walk_tracker_test.dart` 의 `started()` · `_pos` · `clock` 도우미 사용):
  - `pause()` → `current` 가 `tracking`, `session.pausedAt == clock`, `states` 로도 나온다
  - 멈춤 중 들어온 점은 `points` 에 안 들어간다(거리 그대로)
  - `unpause()` → `pausedAt == null`, `pausedDuration` 이 멈춘 길이(시계를 5분 옮겨 확인)
  - 재개 뒤 첫 점은 `points` 에 들어가지만 `distanceMeters` 가 늘지 않는다. 두 번째 점부터는 `distanceBetween`(10) 만큼 는다
  - 멈춤 중 `stop()` → `finished` 세션의 `pausedAt == null`, `pausedDuration` 에 마지막 멈춤이 더해져 있다
  - `idle` 에서 `pause()` · `unpause()` → `Err(walkNotFound)`. 이미 멈춤 중 `pause()` · 진행 중 `unpause()` → `Ok`, 상태 변화 없음
  - 멈춤 중 위치 오류가 있던 상태에서 점이 오면 `locationError` 는 지운다(점은 버림)
- [ ] **Step 2: 실패 확인**
- [ ] **Step 3: 구현** — `_onPosition` 첫머리에 멈춤이면 오류만 지우고 return. 재개 플래그 `_skipNextStep` 을
  `unpause` 에서 켜고 다음 수락 점에서 `step` 을 0 으로 쓰고 끈다(정책 판정의 `stepMeters` 는 실제 값으로 — 2 m 미만 점을 받지 않는 규칙은 유지).
  세션을 새로 만드는 모든 곳(`_onPosition`, `stop`, `resume`, 오류)에서 `pausedDuration` · `pausedAt` 을 잃지 않게
  `session.copyWith(...)` 를 쓴다. `WalkUseCase` 인터페이스 · 구현에 두 메서드를 더해 추적기로 넘긴다.
  테스트의 `MockWalkUseCase` 는 mocktail 이라 수정이 필요 없다.
- [ ] **Step 4: 테스트 · 분석 · 커밋** — `feat(pawlog): 산책 추적을 일시정지하고 이어 갈 수 있다`

---

### Task 3: 일시정지 버튼 · 표시 · 문자열

**Files:**
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` (+ 생성 파일)
- Modify: `apps/pawlog/lib/presentation/tracking/cubit/active_walk_cubit.dart`, `page/active_walk_page.dart`, `widget/active_walk_banner.dart`
- Test: `apps/pawlog/test/presentation/tracking/cubit/active_walk_cubit_test.dart`, `page/active_walk_page_test.dart`, 배너가 쓰이는 `test/presentation/feed/page/walk_feed_page_test.dart`

**Interfaces:**
- Consumes: Task 2 의 `WalkUseCase.pauseWalk()` · `unpauseWalk()`, `WalkSession.isPaused`
- Produces: `ActiveWalkCubit.pause()` · `unpause()`(진행 중이 아니면 아무것도 안 함), 키 `walk-active-pause-button` · `walk-active-paused-label` · 배너 `walk-feed-banner-paused`

- [ ] **Step 1: 문자열** — feature plan 표의 4키를 세 ARB 끝에 더하고 `cd packages/l10n && flutter gen-l10n && flutter test`
- [ ] **Step 2: 실패하는 테스트**
  - cubit: `pause()` 가 `useCase.pauseWalk()` 를 한 번 부른다 · `unpause()` 도 · 추적 중이 아니면 부르지 않는다 · 멈춘 세션이 오면 1초 뒤에도 `elapsed` 가 그대로(`FakeClock` 으로 시계를 옮겨 tick)
  - 페이지: 추적 중 보조 버튼 "일시정지" → `pause` 호출(`MockWalkUseCase` 의 `pauseWalk` verify) · 멈춘 세션이면 "계속 걷기" · `walk-active-paused-label` "일시정지 중" 보임 · 끝내기 버튼은 그대로 하나
  - 피드 배너: 멈춘 세션이면 "산책을 잠시 멈췄어요" 와 `walk-feed-banner-paused`, 연두 점(`PulseDot`) 없음
- [ ] **Step 3: 구현**
  - cubit: 두 메서드는 `state is ActiveWalkTracking` 일 때만 유스케이스를 부른다(결과는 추적기 스트림으로 돌아온다)
  - 시트: `PawlogBottomAction` 안 주 버튼 위에 `AppButton.secondary(key: …pause-button, label: isPaused ? walkUnpause : walkPause)` 와 사이 `PawlogSpacing.sm`. 멈춤이면 `WalkStatsRow` 위에 `walkPausedLabel`(`labelMedium`, `textMuted`)
  - 배너: `tracking` 생성자에서 `session.isPaused` 면 점을 그리지 않고 문구를 바꾼다
- [ ] **Step 4: 테스트 · 분석 · 토큰 grep(`grep -rnE "\bColors\.|BorderRadius\.circular" lib/presentation/tracking` 결과 없음) · 커밋** —
  `feat(pawlog): 진행 화면에서 산책을 일시정지 · 재개한다` (l10n 은 같은 커밋이어도 된다)

---

### Task 4: 복구 저장소 — drift 스키마 v2

**Files:**
- Create: `apps/pawlog/lib/domain/tracking/entity/active_walk_snapshot.dart`, `apps/pawlog/lib/domain/tracking/repository/active_walk_store.dart`
- Modify: `apps/pawlog/lib/data/database/tables.dart`, `apps/pawlog/lib/data/database/walk_database.dart`
- Create: `apps/pawlog/lib/data/tracking/drift_active_walk_store.dart`
- Test: `apps/pawlog/test/data/tracking/drift_active_walk_store_test.dart`, `apps/pawlog/test/data/database/walk_database_migration_test.dart`

**Interfaces:**
- Produces:
  - `ActiveWalkSnapshot({required WalkSession session, required TrackingNotice notice})` (Freezed)
  - `abstract interface class ActiveWalkStore { Future<ActiveWalkSnapshot?> load(); Future<void> begin(WalkSession session, TrackingNotice notice); Future<void> appendPoint(int seq, WalkTrackPoint point, double distanceMeters); Future<void> updateTiming(WalkSession session); Future<void> clear(); }`
  - `@LazySingleton(as: ActiveWalkStore) class DriftActiveWalkStore implements ActiveWalkStore { DriftActiveWalkStore(WalkDatabase db); }`

- [ ] **Step 1: 테이블** — `tables.dart` 에 설계 §3 대로 `ActiveWalks`(`@DataClassName('ActiveWalkRow')`, `id` 정수 pk, `dogIds` 텍스트 JSON, `startedAt`, `endedAt?`, `pausedMs` 정수, `pausedAt?`, `distanceMeters` 실수, `noticeTitle` · `noticeText`) · `ActiveWalkPoints`(`@DataClassName('ActiveWalkPointRow')`, `seq` pk, `lat` · `lng` · `recordedAt` · `accuracy?`). `WalkDatabase` 의 `tables:` 에 더하고 `schemaVersion => 2`, `MigrationStrategy` 에 `onUpgrade: (m, from, to) async { if (from < 2) { await m.createTable(activeWalks); await m.createTable(activeWalkPoints); } }` (기존 `beforeOpen` 유지)
- [ ] **Step 2: 실패하는 저장소 테스트** (`WalkDatabase(NativeDatabase.memory())`, 기존 `drift_walk_repository_test.dart` 의 생성 · 해제 방식 그대로):
  - 비어 있으면 `load()` null
  - `begin` → `load()` 가 같은 `dogIds` · `startedAt` · 빈 점 · 거리 0 · 같은 notice
  - `appendPoint` 세 번(seq 0,1,2, 누적 거리 0 · 10 · 20) → `load()` 의 점 순서 · 좌표 · accuracy · 거리 20
  - `updateTiming` (멈춤 합 5분 · `pausedAt` · `endedAt`) → `load()` 에 그대로
  - 두 번째 `begin` 은 이전 점까지 지운다
  - `clear()` → null
- [ ] **Step 3: 실패하는 마이그레이션 테스트** — `NativeDatabase.memory(setup: (raw) { … })` 의 `setup` 에서 v1 의 다섯 `CREATE TABLE`(지금 `walk_database.g.dart` 가 만드는 SQL 과 같은 컬럼 · 키; 실제 SQL 은 v1 DB 를 한 번 열어 `sqlite_master.sql` 로 뽑아 테스트에 상수로 박는다) 과 `dogs` 한 행 · `walks` 한 행 INSERT, `PRAGMA user_version = 1` 을 실행한다. 그 DB 로 `WalkDatabase` 를 열고: `select(dogs)` · `select(walks)` 행 유지, `active_walks` · `active_walk_points` 가 `sqlite_master` 에 있음, `DriftActiveWalkStore.begin` 이 동작
- [ ] **Step 4: 구현** — `dogIds` 는 `jsonEncode` · `jsonDecode`. `begin` 은 트랜잭션 안에서 두 테이블을 비우고 `id: 1` 한 줄을 넣는다. `appendPoint` 는 트랜잭션으로 점 insert + `distanceMeters` update. `load` 는 점을 `seq` 순으로 읽어 `WalkSession` 을 만든다(`pausedDuration: Duration(milliseconds: pausedMs)`)
- [ ] **Step 5: 생성 · 테스트 · 분석 · 커밋** — `feat(pawlog): 진행 중 산책을 drift 에 써 두는 저장소를 추가한다`

---

### Task 5: 추적기가 세션을 써 두고 시작할 때 되살린다

**Files:**
- Modify: `apps/pawlog/lib/data/tracking/geolocator_walk_tracker.dart`, `apps/pawlog/lib/domain/tracking/repository/walk_tracker.dart`, `apps/pawlog/lib/core/bootstrap.dart`
- Test: `apps/pawlog/test/data/tracking/geolocator_walk_tracker_test.dart`, `apps/pawlog/test/core/di/injection_test.dart`(등록 확인이 있으면)

**Interfaces:**
- Consumes: Task 4 의 `ActiveWalkStore`, Task 2 의 pause 로직
- Produces: `GeolocatorWalkTracker(LocationGateway gateway, Clock clock, ActiveWalkStore store)`, `WalkTracker.restore() → Future<void>`, `@visibleForTesting Future<void> get pendingWrites`

- [ ] **Step 1: 실패하는 테스트** — 기존 추적기 테스트의 `setUp` 에 `MockActiveWalkStore`(mocktail, 모든 메서드 `thenAnswer((_) async {})`, `load` 는 기본 null) 를 넣고 생성자를 바꾼다. 추가:
  - `start` → `store.begin(session, notice)` 한 번
  - 점 두 개 수락 → `appendPoint(0, …, 0)` · `appendPoint(1, …, 10)` 순서(`verifyInOrder`) — `await tracker.pendingWrites` 뒤 확인
  - 버린 점은 쓰지 않는다
  - `pause` · `unpause` · `stop` → 각각 `updateTiming` 에 그 시점 세션
  - `clear()`(finished 에서) → `store.clear()`
  - `begin` 이 던져도 `start` 는 `Ok`, 뒤 점은 계속 쌓인다(그리고 `appendPoint` 는 여전히 불린다)
  - `restore()`:
    - `load` null → `idle` 그대로, 구독 없음
    - `endedAt` 있는 스냅샷 → `finished(그 세션)`, 구독 없음
    - 진행 중 스냅샷(점 2개 · 멈춤 없음) → `tracking(그 세션)`, `positionStream` 구독, 새 점이 오면 `appendPoint(2, …)` 로 이어진다
    - 멈춘 채 저장된 스냅샷 → `tracking` 이고 `isPaused`, 점이 와도 버린다
    - 위치 서비스 꺼짐 → `tracking(session, locationError: locationServiceDisabled)`
    - `load` 가 던지면 `idle`
    - `idle` 이 아니면(이미 start 한 뒤) 아무것도 안 한다
- [ ] **Step 2: 실패 확인**
- [ ] **Step 3: 구현**
  - `Future<void> _writes = Future.value();` 와 `void _enqueue(Future<void> Function() op) { _writes = _writes.then((_) => op()).catchError((Object e) => debugPrint('active walk store: $e')); }`, `pendingWrites => _writes`
  - 점 `seq` 는 `session.points.length - 1`(추가 뒤)
  - `restore()` 는 `_notice` 를 스냅샷 notice 로 두고, 진행 중이면 `_checkAccess` → 실패면 `locationError` 로 `tracking`, 성공이면 `_subscribe` 후 `tracking`
  - `bootstrap()`: `await configureDependencies();` 다음에 `await getIt<WalkTracker>().restore();` (getIt 은 `core` 에서 — `dogs_redirect` 처럼 기존 import 방식을 따른다)
  - `injection.config.dart` 재생성. `test/core/di/injection_test.dart` 가 실제 DI 를 만든다면 `ActiveWalkStore` 해석이 되는지 확인
- [ ] **Step 4: 생성 · 테스트 · 분석 · APK 빌드 · 커밋** — `feat(pawlog): 앱이 죽어도 진행 중 산책을 다음 실행에 되살린다`

---

### Task 6: 검증 · 문서

**Files:**
- Create: `apps/pawlog/docs/features/session/history.md`, `testing.md`
- Modify: `apps/pawlog/docs/features/session/plan.md`(상태 줄), `apps/pawlog/docs/status.md`, `apps/pawlog/docs/README.md`(W7 행), `apps/pawlog/docs/overview.md`(§3 제외 목록 · §5 표 · §7 스키마 v2 두 테이블), `docs/status.md` pawlog 행
- [ ] 전체 검증: `apps/pawlog` analyze · test · `flutter build apk --debug`, `packages/l10n` test, `apps/trader` `flutter test test/convention`
- [ ] 에뮬레이터: feature plan 완료 조건 ①~⑤. GPS 가 앱에 안 들어오는 AVD 라도 ①②④⑤ 와 ③의 "배너 · 진행 화면 복귀" 는 볼 수 있다
- [ ] history(단계 커밋 · 설계와 다르게 간 것 · 리뷰 수정) · testing(파일별 건수 · 에뮬레이터 표) · 진행 현황
- [ ] 커밋 — `docs(pawlog): W7 session 구현 기록과 테스트를 남긴다`
