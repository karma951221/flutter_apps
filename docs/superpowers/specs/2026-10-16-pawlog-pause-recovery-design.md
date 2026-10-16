# pawlog 일시정지 · 복구 설계 — 산책을 멈췄다 잇고, 앱이 죽어도 잃지 않는다

> 2026-10-16 작성 · 기획서는 [pawlog 기획서](../../../apps/pawlog/docs/overview.md) · 화면 · 상태 ·
> 문자열 · 완료 조건은 [W7 session 계획](../../../apps/pawlog/docs/features/session/plan.md) ·
> 추적기는 [W2 tracking 계획](../../../apps/pawlog/docs/features/tracking/plan.md)

## 0. 왜 만드는가

기획서 §3 이 v1 밖으로 뺀 것 중 둘을 W7 session 으로 얹는다.

- **일시정지 · 재개**: 편의점에 들르거나 신호를 기다리는 동안 시간을 세지 않는다. 지금은 끝내거나 그대로 두는 수밖에 없다
- **강제 종료 뒤 복구**: 추적 중 세션은 메모리(`GeolocatorWalkTracker`)에만 있다. 앱이 죽으면 그 산책이 통째로 사라진다

기획서 §3 은 "복구는 v1 스키마가 받아 줄 수 있게 설계한다" 고 해 두었다. 이번에 그 약속을 지킨다.
사용자는 이 작업을 직접 고르지 않았다. "묻지 말고 알아서 진행" 지시에 따라 앞서 추천한 다음
후보(2026-10-16 대화의 B 안)를 골랐다.

## 1. 결정

| # | 결정 | 근거 |
|---|---|---|
| 1 | 일시정지 중에도 **위치 스트림은 끊지 않고, 들어오는 점을 버린다** | 스트림을 끊으면 Android 포그라운드 서비스가 내려가 백그라운드에서 앱이 죽기 쉽다. 알림이 "산책 중" 으로 남는 편이 낫다 |
| 2 | 재개 뒤 첫 점은 **거리를 더하지 않는다**(구간 0 m). 경로 선은 이어 그린다 | 멈춘 동안 걸어간 거리가 직선으로 더해지지 않게. 선을 끊는 것은 `walk_points` 에 구간 표시가 필요해 이번에 하지 않는다 |
| 3 | 산책 시간 = 시작부터 끝까지 − **멈춘 시간 합** | `walks.duration_seconds` 의 뜻을 "걸은 시간" 으로 둔다. 스키마는 그대로 |
| 4 | 진행 중 세션을 drift 의 **별도 두 테이블**(`active_walks` 한 줄 · `active_walk_points`)에 그때그때 쓴다 | `walks` 는 반려견 · 사진이 붙은 저장된 기록이다. 진행 중 세션을 같은 테이블에 두면 피드 · 통계 쿼리가 모두 걸러야 한다 |
| 5 | 앱 시작 때 `bootstrap` 이 추적기 `restore()` 를 한 번 부른다. 끝나지 않은 세션은 `tracking` 으로, 끝났지만 저장 전이면 `finished` 로 되살린다 | 피드 배너 · 진행 화면 · 저장 폼이 이미 추적기 상태만 보므로 화면 코드를 따로 고치지 않아도 이어진다 |
| 6 | 앱이 죽어 있던 동안은 **걸은 시간으로 센다**. 멈춤 상태로 죽었으면 멈춤 시간으로 센다 | 사용자는 앱이 죽은 줄 모르고 계속 걸었을 가능성이 크다. 멈춤 상태는 `paused_at` 으로 남는다 |
| 7 | 저장소 쓰기는 **순서를 지키는 직렬 큐**로, 실패는 로그만 남기고 산책을 끊지 않는다 | 위치 콜백은 동기다. 쓰기 실패로 산책 기록이 멈추면 복구 기능이 오히려 산책을 망친다 |
| 8 | 일시정지 버튼은 시트 안의 **보조 버튼**, 끝내기가 주 버튼으로 남는다 | design.md "화면마다 주 버튼은 하나" |
| 9 | 멈춤 중에는 연두 점멸을 멈춘다. 배너 문구는 "산책을 잠시 멈췄어요" | 연두는 '진행 중' 에만 쓴다(design.md Colors) |

## 2. 도메인

`WalkSession` 에 두 필드를 더한다.

| 필드 | 뜻 |
|---|---|
| `Duration pausedDuration` (기본 `Duration.zero`) | 지난 멈춤들의 합 |
| `DateTime? pausedAt` | 지금 멈춰 있으면 멈춘 시각, 아니면 null |

- `bool get isPaused => pausedAt != null`
- `Duration elapsedAt(DateTime now)` = `(endedAt ?? now) − startedAt − pausedDuration − (pausedAt != null ? (endedAt ?? now) − pausedAt : 0)`, 음수면 0
- `WalkDraft` 에 `Duration duration` 을 더한다. 저장 폼은 `session.elapsedAt(endedAt)` 을 넣고,
  `SaveWalkScenario` 는 `endedAt − startedAt` 대신 이 값을 저장한다

`WalkTracker` 에 둘을 더한다: `Future<Result<void>> pause()` · `Future<Result<void>> unpause()`.
`tracking` 이 아니면 `walkNotFound`, 이미 그 상태면 아무것도 하지 않고 `Ok`. `stop()` 이 멈춤 중에
불리면 멈춤을 닫고(`pausedDuration += endedAt − pausedAt`, `pausedAt = null`) 끝낸다.
`WalkUseCase` 에 `pauseWalk()` · `unpauseWalk()` 를 더해 그대로 넘긴다.

복구 저장소 인터페이스 `ActiveWalkStore`(`lib/domain/tracking/repository/active_walk_store.dart`):

| 메서드 | 뜻 |
|---|---|
| `Future<ActiveWalkSnapshot?> load()` | 남은 세션. 없으면 null |
| `Future<void> begin(WalkSession session, TrackingNotice notice)` | 이전 것을 지우고 새 세션 머리를 쓴다 |
| `Future<void> appendPoint(int seq, WalkTrackPoint point, double distanceMeters)` | 점 하나 + 누적 거리 |
| `Future<void> updateTiming(WalkSession session)` | `pausedDuration` · `pausedAt` · `endedAt` 을 덮어쓴다 |
| `Future<void> clear()` | 모두 지운다 |

`ActiveWalkSnapshot(session, notice)` 은 Freezed 단일 모델. `notice` 를 남기는 이유는 복구 때
포그라운드 알림을 같은 문구로 다시 띄우기 위해서다.

## 3. 데이터 — drift 스키마 v2

```
active_walks        (id INT pk (언제나 1), dog_ids TEXT [JSON 배열], started_at, ended_at?,
                     paused_ms INT, paused_at?, distance_meters REAL,
                     notice_title TEXT, notice_text TEXT)
active_walk_points  (seq INT pk, lat REAL, lng REAL, recorded_at, accuracy?)
```

- `schemaVersion` 1 → 2. `onUpgrade`: `from < 2` 이면 두 테이블을 만든다. 기존 다섯 테이블은 그대로
- 외래 키 없음 — 진행 중 세션은 반려견이 지워져도 남고, 저장할 때 W3 가 존재하는 반려견만 붙인다
- `DriftActiveWalkStore` 가 `@LazySingleton(as: ActiveWalkStore)`
- 시각은 기존처럼 ISO 텍스트(`storeDateTimeAsText`)

## 4. 추적기

`GeolocatorWalkTracker(gateway, clock, store)`.

| 시점 | 상태 | 저장소 |
|---|---|---|
| `start` 성공 | `tracking(새 세션)` | `begin` |
| 점 수락 | 점 추가 · 거리 누적 | `appendPoint(seq, point, distance)` |
| 멈춤 중 점 | 버린다(위치 오류만 지움) | — |
| 재개 뒤 첫 점 | 점 추가, 거리 그대로 | `appendPoint` |
| `pause` · `unpause` | `pausedAt` · `pausedDuration` 갱신 | `updateTiming` |
| `stop` | `finished` | `updateTiming`(endedAt) |
| `clear`(저장 · 버리기 뒤) | `idle` | `clear` |
| `restore()` | 스냅샷 없음 → 그대로 · `endedAt` 있음 → `finished` · 없음 → `tracking` + 구독(실패는 `locationError`) | `load` |

- 쓰기는 `_writes = _writes.then((_) => op()).catchError(log)` 같은 직렬 큐. 테스트는 큐를 기다릴 수
  있게 `@visibleForTesting Future<void> get pendingWrites` 를 연다
- `restore()` 는 `idle` 일 때만 한다. 저장소 `load` 가 던지면 로그만 남기고 `idle`
- 재개 뒤 첫 점 표시는 메모리 플래그. 그 사이 앱이 죽으면 복구 뒤 첫 점은 평소처럼 거리를 더한다(짧은 직선 하나 — 받아들인다)

## 5. 화면

- **진행 화면 시트**: 숫자 위에 멈춤 중이면 `walkPausedLabel`(label, muted). 끝내기 주 버튼 위에 보조 버튼
  (`AppButton.secondary`, 키 `walk-active-pause-button`) — 진행 중 "일시정지", 멈춤 중 "계속 걷기"
- **시계**: `ActiveWalkCubit` 은 멈춤 중에도 1초 타이머를 두되 `elapsedAt` 이 멈춘 값을 돌려주므로 숫자가 서 있다
- **피드 배너**: `session.isPaused` 면 `walkPausedBanner` 문구, 연두 점 없음. 경과 시간은 멈춘 값
- 복구는 화면이 따로 없다. 앱을 다시 열면 피드에 배너가 보인다

## 6. 테스트

| 층 | 대상 | 확인 |
|---|---|---|
| 단위 | `WalkSession.elapsedAt` | 멈춤 없음 · 지난 멈춤 합 · 지금 멈춤 중 · 끝난 세션 · 음수 방지 |
| 단위 | `SaveWalkScenario` · `WalkEditForm.toDraft` | 저장 시간이 멈춤을 뺀 값 |
| 단위 | `GeolocatorWalkTracker` | pause/unpause 상태 · 멈춤 중 점 버림 · 재개 뒤 첫 점 0 m · 멈춤 중 stop · 저장소 호출 순서 · restore 세 갈래 · 저장소 실패에도 추적 계속 |
| 단위 | `DriftActiveWalkStore` (in-memory) | begin · append · updateTiming · load 왕복 · clear · begin 이 이전 것을 지움 |
| 단위 | 마이그레이션 | v1 DB(기존 다섯 테이블 + 행) → v2 열기 → 새 테이블 생김 · 기존 행 유지 |
| 단위 | `ActiveWalkCubit` | pause/unpause 호출 · 멈춤 중 경과 시간 고정 |
| 위젯 | 진행 화면 · 피드 배너 | 버튼 문구 전환 · 멈춤 표시 · 배너 문구 · 점 없음 |
| 에뮬레이터 | [W7 계획 완료 조건](../../../apps/pawlog/docs/features/session/plan.md#완료-조건) | 멈춤 · 재개 · 강제 종료 후 복구 |
