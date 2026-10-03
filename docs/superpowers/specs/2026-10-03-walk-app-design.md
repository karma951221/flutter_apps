# 산책 앱(pawlog) 설계 — 셋째 앱으로 로컬 DB와 지도를 얹어 본다

> 2026-10-03 작성 · 브랜치 `claude/dog-walk-log-app-8zyycw` · 기획서는
> [pawlog 기획서](../../../apps/pawlog/docs/overview.md) · 선례는
> [통근 앱 설계](2026-09-13-commute-app-design.md) · 계층 규칙은 [아키텍처](../../architecture.md)

## 0. 왜 만드는가

통근 앱은 `core` · `design_system` · `l10n` 만으로 섰다. 하지만 백엔드도, 영속 데이터도
`shared_preferences` 두 키뿐이었다. 셋째 앱은 같은 경계 위에 **로컬 DB(drift) · 지도
(flutter_map) · 백그라운드 GPS · 로컬 사진 파일**을 더해도 경계가 유지되는지 본다.

- 의존은 통근 앱과 같다: `feature_walk` → `core` · `design_system` · `l10n`. `feature_*` ·
  `supabase_flutter` · `go_router` 없음
- 페이지는 콜백만 받고 경로는 앱이 정한다(통근 앱에서 시험한 방식을 그대로)
- drift 는 [트레이더 기획 §4.2](../../../apps/trader/docs/overview.md#42-로컬-db는-drift-하나만)가
  정해 두고 미뤄 둔 것이다. 이 앱이 첫 사용처다

이 문서는 [기획서](../../../apps/pawlog/docs/overview.md) §5~§7 의 엔지니어링 상세다.
기획서와 어긋나면 기획서가 기준이고, 바뀐 판단은 기획서 해당 절을 함께 고친다.
§7 은 이 앱을 만들며 쌓을 리팩터링 후보 목록이다.

## 1. 범위와 화면

범위는 기획서 §3 그대로다(v1 = 혼자 쓰는 로컬 기록 앱). 화면과 경로:

| 경로 | 페이지 | Feature | 내용 |
|---|---|---|---|
| `/` | `WalkFeedPage` | W4 | 기록 카드(최신순), 추적 중 배너, FAB 시작/계속, AppBar → 강아지 |
| `/walk` | `ActiveWalkPage` | W2 | 강아지 선택 → 추적(지도 · 경과 시간 · 거리) → 종료 확인 |
| `/walk/save` | `WalkEditPage.create` | W3 | 방금 끝난 세션 저장 폼 |
| `/walks/:id` | `WalkDetailPage` | W3 | 전체 경로 지도 · 통계 · 사진 · 메모, 수정 · 삭제 |
| `/walks/:id/edit` | `WalkEditPage.edit` | W3 | 강아지 · 메모 · 사진 수정 |
| `/dogs` | `DogListPage` | W1 | 강아지 목록, FAB 추가 |
| `/dogs/new` | `DogEditPage` | W1 | 신규 등록. 0마리면 부팅 시 여기로 |
| `/dogs/:id` | `DogEditPage` | W1 | 수정 · 삭제 |

### 의도적으로 없는 것

기획서 §3 "제외" 와 같다. 설계상 특히 신경 쓴 것: **일시정지/재개 · 강제종료 복구 ·
페이지네이션은 만들지 않지만 막지도 않는다** — 점 테이블이 append 가능하고(§3),
`watchWalks` 를 커서 쿼리로 바꿀 자리가 레포 인터페이스에 있다.

## 2. 도메인

### 엔티티 (`domain/entity/`, Freezed 단일 모델 — Primary Constructor)

| 이름 | 필드 |
|---|---|
| `Dog` | `id`, `name`, `breed?`, `birthday?: DateTime`(날짜만), `photoPath?`(상대 경로), `createdAt`, `updatedAt` |
| `DogDraft` | `id?`(null = 신규), `name`, `breed?`, `birthday?`, `photoPath?`(상대 경로) |
| `GeoPoint` | `lat`, `lng` |
| `WalkTrackPoint` | `point: GeoPoint`, `recordedAt`, `accuracy?`(m) |
| `WalkSession` | `dogIds`, `startedAt`, `endedAt?`, `points: List<WalkTrackPoint>`, `distanceMeters` · `Duration elapsedAt(DateTime now)` |
| `TrackerState` | **sealed** · `idle()` / `tracking(WalkSession)` / `finished(WalkSession)` |
| `TrackingNotice` | `title`, `text` — Android 포그라운드 알림 문구(l10n 을 페이지가 넘긴다) |
| `Walk` | `id`, `startedAt`, `endedAt`, `duration`, `distanceMeters`, `memo?`, `dogs: List<Dog>`, `photos: List<WalkPhoto>`, `previewPoints: List<GeoPoint>`, `createdAt`, `updatedAt` |
| `WalkPhoto` | `id`, `path`(상대 경로), `position` |
| `WalkDraft` | `startedAt`, `endedAt`, `distanceMeters`, `points: List<WalkTrackPoint>`, `dogIds`, `memo?`, `photoPaths: List<String>` |
| `WalkUpdate` | `id`, `dogIds`, `memo?`, `photoPaths: List<String>` |

- `Walk` 는 **전체 경로를 들지 않는다.** 피드가 수천 점을 읽지 않게 `previewPoints`(≤ 64점)만
  들고, 전체는 `getWalkTrack(id)` 로 따로 읽는다
- 사진은 강아지 · 산책 모두 **선택 즉시 파일로 쓰고** 드래프트에는 상대 경로만 든다(기획서
  W3). 10장을 바이트로 들고 있으면 메모리가 무겁고, 두 폼의 흐름을 하나로 맞추는 쪽이
  단순하다. 폼을 버리면 그 폼에서 새로 쓴 파일을 지운다(`DiscardWalk`, 강아지 폼도 같은
  규칙)
- `TrackerState` 를 sealed 로 두는 이유: 피드(배너 · FAB 문구), 진행 화면(바로 `tracking`
  진입), 저장 폼(`finished` 에서 세션 꺼냄)이 모두 분기한다

### 정책 (`domain/policy/`, 순수 Dart)

| 이름 | 규칙 |
|---|---|
| `WalkTrackingPolicy.accept({previous, next, stepMeters})` | `next.accuracy ≤ 50`(null 이면 통과) **그리고** `stepMeters ≥ 2`(`previous` 가 null 인 첫 점은 통과). 상수 `maxAccuracyMeters = 50`, `minStepMeters = 2` |
| `RoutePreview.downsample(List<GeoPoint>, {int max = 64})` | 첫 점 · 끝 점을 유지하고 사이를 균등 인덱스로 뽑는다. `length ≤ max` 면 그대로 |
| `RoutePreview.encode` / `decode` | `[[lat,lng],…]` JSON, 소수 5자리(≈1 m). `decode` 는 깨진 값이면 빈 목록 |

거리 계산(`distanceBetween`)은 정책 밖, tracker 가 한다. 정책이 플랫폼을 모르게.

### 인터페이스 (`domain/repository/`)

```dart
abstract interface class DogRepository {
  Stream<Result<List<Dog>>> watchDogs();            // 이름순
  Future<Result<List<Dog>>> getDogs();
  Future<Result<Dog>> getDog(String id);            // 없으면 notFound
  Future<Result<void>> upsert(Dog dog);
  Future<Result<void>> delete(String id);
}

abstract interface class WalkRepository {
  Stream<Result<List<Walk>>> watchWalks();          // started_at 내림차순
  Future<Result<Walk>> getWalk(String id);          // 없으면 walkNotFound
  Future<Result<List<WalkTrackPoint>>> getWalkTrack(String id);  // seq 순
  Future<Result<void>> insert(Walk walk, List<WalkTrackPoint> track);
  Future<Result<void>> update(Walk walk);           // 강아지 · 메모 · 사진 교체
  Future<Result<void>> delete(String id);
}

abstract interface class WalkTracker {
  TrackerState get state;
  Stream<TrackerState> get states;                  // 구독 즉시 현재 상태부터
  Future<Result<void>> start({required List<String> dogIds, required TrackingNotice notice});
  Future<Result<WalkSession>> stop();               // tracking 아니면 walkNotFound
  void clear();                                     // finished → idle
}

abstract interface class PhotoStorage {
  Future<Result<String>> save(PreparedImage image);  // 상대 경로 반환
  String resolve(String relativePath);               // 절대 경로
  Future<void> delete(String relativePath);          // best-effort, 실패 무시
}
```

`WalkTracker` 는 저장소가 아니지만 "나중에 갈아끼우는 자리" 라는 같은 이유로 여기에 둔다.
구현은 `data/tracker/`. `PreparedImage` 는 `core` 의 것이다(도메인 → `core` 의존은 허용).

### Usecase facade + 시나리오 (`domain/usecase/`)

`WalkUseCase` 가 유일한 facade 다. cubit 은 이것만 본다([아키텍처 규칙 ③](../../architecture.md#-presentation은-feature별-usecase-facade-하나만-주입받는다)).

| 메서드 | 시나리오 / 위임 | 핵심 |
|---|---|---|
| `watchDogs()` · `getDogs()` · `getDog(id)` | 레포 위임 | — |
| `saveDog(DogDraft)` → `Result<Dog>` | `SaveDogScenario` | 이름 trim 이 비면 `dogNameRequired`. `newPhoto` 가 있으면 저장 → 성공 후 옛 파일 삭제. 신규면 `IdGenerator` · `createdAt` |
| `deleteDog(id)` | `DeleteDogScenario` | 행 삭제(`walk_dogs` cascade, **산책은 남는다**) → 사진 파일 best-effort |
| `trackerStates` · `trackerState` | tracker 위임 | — |
| `startWalk(dogIds, notice)` | `StartWalkScenario` | 강아지 0 → `walkDogRequired`. 그 외 실패는 tracker 가 정한다 |
| `stopWalk()` → `Result<WalkSession>` | tracker 위임 | — |
| `saveWalk(WalkDraft)` → `Result<String>` | `SaveWalkScenario` | 강아지 0 → `walkDogRequired`. uuid · 시각 · `RoutePreview.downsample` → 트랜잭션 insert → `tracker.clear()` |
| `discardWalk(photoPaths)` | `DiscardWalkScenario` | 파일 삭제 → `tracker.clear()` |
| `watchWalks()` · `getWalk(id)` · `getWalkTrack(id)` | 레포 위임 | — |
| `updateWalk(WalkUpdate)` | `UpdateWalkScenario` | 강아지 0 → `walkDogRequired`. 기존과 비교해 **빠진 사진 파일만** 삭제 |
| `deleteWalk(id)` | `DeleteWalkScenario` | `getWalk` 로 사진 경로 확보 → 행 삭제 → 파일 best-effort |
| `storePhoto(PreparedImage)` → `Result<String>` | `StorePhotoScenario` | 실패를 `walkPhotoSaveFailed` 로 |
| `photoPath(relative)` → `String` | storage 위임 | 페이지가 `Image.file` · `AppAvatar.imageFile` 에 쓴다 |

시나리오는 `DateTime Function() now` 를 생성자로 받는다(기본 `DateTime.now`). 테스트가
`createdAt` · `endedAt` 을 단언하려면 시계가 필요한데 `core` 에 시계 추상이 없다(→ §7 후보 4).
파일 삭제는 **DB 가 성공한 뒤** 한다 — 순서가 반대면 실패 시 행이 없는 파일을 가리킨다.

### 실패 코드

`core` 의 `FailureCode` 에 5개 추가, `l10n` 의 exhaustive switch 와 ARB 3개(ko · en · ja)를
같이 고친다.

| 코드 | Failure 종류 | 언제 |
|---|---|---|
| `walkDogRequired` | `validation` | 강아지 0마리로 시작 · 저장 · 수정 |
| `walkTrackingAlreadyActive` | `validation` | 추적 중에 `start` |
| `walkNotFound` | `notFound` | 없는 산책 id, 추적 중이 아닌데 `stop`, `finished` 없이 `/walk/save` |
| `walkPhotoSaveFailed` | `unknown` | 파일 쓰기 실패 |
| `dogNameRequired` | `validation` | 이름 공백 |

위치 실패는 기존 `locationPermissionDenied` · `locationServiceDisabled` 를 재사용한다.

## 3. 데이터 구현 (`data/`)

| 인터페이스 | 구현 | 비고 |
|---|---|---|
| `DogRepository` | `DriftDogRepository(WalkDatabase)` | — |
| `WalkRepository` | `DriftWalkRepository(WalkDatabase)` | 조인 watch + 그룹핑 |
| `WalkTracker` | `GeolocatorWalkTracker(LocationGateway)` | 앱 수명 lazySingleton |
| `PhotoStorage` | `FilePhotoStorage(@Named('walkPhotosRoot') Directory, IdGenerator)` | — |

### WalkDatabase — drift 스키마 v1 (`data/database/`)

| 테이블 | 컬럼 | 키 · 인덱스 |
|---|---|---|
| `dogs` | `id TEXT`, `name TEXT`, `breed TEXT?`, `birthday TEXT?`(`yyyy-MM-dd`, `DateOnlyConverter`), `photo_path TEXT?`, `created_at`, `updated_at` | pk `id` |
| `walks` | `id TEXT`, `started_at`, `ended_at`, `duration_seconds INT`, `distance_meters REAL`, `memo TEXT?`, `route_preview TEXT?`, `created_at`, `updated_at` | pk `id`, idx `started_at` |
| `walk_dogs` | `walk_id` → walks **cascade**, `dog_id` → dogs **cascade** | pk `(walk_id, dog_id)` |
| `walk_points` | `walk_id` → walks **cascade**, `seq INT`, `lat REAL`, `lng REAL`, `recorded_at`, `accuracy REAL?` | pk `(walk_id, seq)` |
| `walk_photos` | `id TEXT`, `walk_id` → walks **cascade**, `path TEXT`, `position INT`, `created_at` | pk `id`, idx `walk_id` |

- 시각은 ISO-8601 텍스트: `build.yaml` 의 drift 옵션 `store_date_time_values_as_text: true`
- `MigrationStrategy(beforeOpen: …)` 에서 `PRAGMA foreign_keys = ON`. 없으면 cascade 가 조용히 안 돈다
- `schemaVersion = 1`. 바꿀 때는 `drift_dev schema dump` 로 스냅숏을 남긴다
- 생성자는 `WalkDatabase(QueryExecutor)`. 앱은 `driftDatabase(name: 'pawlog')`(`drift_flutter`),
  테스트는 `NativeDatabase.memory()`

**점을 별도 테이블로 두는 이유**: 피드 쿼리가 점을 읽지 않는다(`route_preview` 로 썸네일).
저장은 트랜잭션 `batch` 일괄 삽입, 읽기는 `ORDER BY seq`. 강제종료 복구를 만들 때 추적 중
점을 바로 append 하면 되고, v2 에서 Postgres(PostGIS) 로 그대로 옮겨진다.
**`route_preview` 를 컬럼으로 두는 이유**: 썸네일 하나 그리려고 점 테이블을 조인하지 않는다.

### DriftDogRepository · DriftWalkRepository

- `watchWalks`: `walks LEFT JOIN walk_dogs LEFT JOIN dogs LEFT JOIN walk_photos` 를
  `ORDER BY walks.started_at DESC, walk_photos.position` 으로 `.watch()`. 행을 `walk.id` 로
  묶어 순서를 지키고 강아지 · 사진은 id 로 중복 제거한다. **조인해야 `dogs` 변경(이름 ·
  사진)에도 스트림이 다시 흐른다** — `walks` 만 watch 하면 강아지 이름 변경이 카드에 안 온다.
  강아지 × 사진 곱만큼 행이 늘지만 v1 규모(최대 10장 × 몇 마리)에서는 문제 삼지 않는다
- `insert`: `transaction` 안에서 walks → walk_dogs → walk_points(`batch`, seq = 인덱스) → walk_photos
- `update`: `transaction` 안에서 walks 행 갱신, walk_dogs · walk_photos 는 지우고 다시 넣는다
- `getWalk` 미존재 → `Failure.notFound(failureCode: walkNotFound)`
- **오류 변환**: 모든 메서드를 `try/catch` → `Err(Failure.unknown(message: error.toString()))`.
  `SupabaseErrorMapper` 는 쓰지 않는다(Supabase 가 없다). watch 스트림은 오류를
  `StreamTransformer` 로 `Err` 값으로 바꿔 흘린다 — 예외로 흐르면 cubit 구독이 끊긴다

### FilePhotoStorage

- 루트: `<documents>/pawlog_photos/` — DI 가 `@preResolve` 로 만들어 준다(§5)
- `save`: `<uuid>.<image.extension>` 로 쓰고 **파일명(상대 경로)만** 돌려준다. iOS 는 설치 ·
  업데이트마다 컨테이너 절대 경로가 바뀌므로 DB 에 절대 경로를 쓰지 않는다
- `resolve`: `root.path + '/' + relative`. `delete`: 없으면 무시, 예외 삼킴

### LocationGateway — 통근 앱에서 복사

`packages/features/commute/lib/src/data/location/location_gateway.dart` 를
`data/location/location_gateway.dart` 로 복사하고 두 메서드를 더한다.
[아키텍처 규칙 ⑥](../../architecture.md#-feature-간-참조는-최소로)이 data 계층 feature 간
import 를 막고, `core` 로 올리면 `core` 에 geolocator 가 붙는다(→ §7 후보 1).

```dart
Stream<Position> positionStream(LocationSettings settings);
double distanceBetween(double startLat, double startLng, double endLat, double endLng);
```

### GeolocatorWalkTracker (`data/tracker/`)

```
start(dogIds, notice)
 ├─ state is tracking            → Err(walkTrackingAlreadyActive)
 ├─ 서비스 꺼짐                   → Err(validation, locationServiceDisabled)
 ├─ 권한 denied & !_requestDeclined → requestPermission, 거부면 _requestDeclined = true
 ├─ 권한 denied/deniedForever    → Err(forbidden, locationPermissionDenied)
 └─ positionStream(settings).listen(_onPosition) → emit tracking(빈 세션) → Ok
_onPosition(p)
 ├─ meters = distanceBetween(직전 점, p)   (첫 점이면 null)
 ├─ WalkTrackingPolicy.accept(accuracy: p.accuracy, metersFromPrevious: meters) 거짓 → 버림
 └─ points += p, distance += meters → emit tracking(session)
stop()  → 구독 취소, endedAt = now → emit finished(session) → Ok(session)
clear() → emit idle
```

| 플랫폼 | `LocationSettings` |
|---|---|
| Android | `AndroidSettings(accuracy: high, distanceFilter: 3, foregroundNotificationConfig: ForegroundNotificationConfig(notificationTitle: notice.title, notificationText: notice.text, enableWakeLock: true))` |
| iOS | `AppleSettings(accuracy: best, distanceFilter: 3, activityType: fitness, allowBackgroundLocationUpdates: true, pauseLocationUpdatesAutomatically: false, showBackgroundLocationIndicator: true)` |

- 권한 흐름은 통근 앱 `GeolocatorLocationRepository` 의 `_requestDeclined` 를 그대로 쓴다
  (Android 는 첫 거부 뒤에도 `denied` 를 돌려줘 재시도마다 다이얼로그가 뜬다)
- 스트림 오류(서비스를 도중에 끔 등)는 **세션을 버리지 않는다.** 점만 안 쌓이고 `tracking` 유지
- 상태 스트림은 `StreamController.broadcast` + 현재값. `states` 는 현재값을 먼저 내보낸다
- 위치 점은 메모리에만 있다. 앱이 죽으면 진행 중 산책은 사라진다(기획서 §3 제외 항목)

## 4. Presentation

> **구현 뒤 안내(2026-10-03).** 이 절의 상태 표 · 페이지 콜백 · 문자열 키 이름은 착수 전 초안이다.
> 구현은 feature 별 계획 — [W1 dog](../../../apps/pawlog/docs/features/dog/plan.md) ·
> [W2 tracking](../../../apps/pawlog/docs/features/tracking/plan.md) ·
> [W3 record](../../../apps/pawlog/docs/features/record/plan.md) ·
> [W4 feed](../../../apps/pawlog/docs/features/feed/plan.md) — 을 따랐고, 둘이 다르면 **계획이 우선한다**.
> 예: 피드 상태는 `loaded(walks, isTracking)` 이 아니라 `loaded(walks, tracker)`, 피드 콜백에
> `onSaveWalk` 가 더해졌고, `walkFeedStartAction` 같은 키 대신 계획의 `walkStart` · `walkContinue` 등을 쓴다.
> 왜 바꿨는지는 각 폴더의 `history.md` 에 있다. 이 절은 다시 쓰지 않는다.

### 상태를 어디에 두는가

**추적 상태는 DI 싱글턴 `WalkTracker` 에, cubit 은 페이지마다.** 화면 이동이 추적을 끊으면
안 되고, 앱 루트 `MultiBlocProvider` 는 [아키텍처 §4](../../architecture.md#4-bloc-사용-지침)와
어긋난다. 피드 · 진행 · 저장 폼 cubit 은 각자 `trackerStates` 를 구독해 같은 진실을 본다.
모든 `await` 뒤 `isClosed` 검사, 구독 · 타이머는 `close()` 에서 끊는다.

### Cubit

| Cubit | State (sealed) | 동작 |
|---|---|---|
| `DogListCubit` | `loading` / `loaded(dogs)` / `failure(failure)` | `start()` — `watchDogs` 구독 |
| `DogEditCubit` | `loading` / `editing(form, isSaving, failure?)` / `saved(dog)` / `deleted` | `load(id?)`, `setName` · `setBreed` · `setBirthday` · `setPhoto(PreparedImage)`, `save()`, `delete()` |
| `ActiveWalkCubit` | `selectingDogs(dogs, selectedIds)` / `starting` / `tracking(session, elapsed)` / `stopped(session)` / `failure(failure, dogs, selectedIds)` | `init()`(추적 중이면 바로 `tracking`), `toggleDog(id)`, `start(notice)`, `stop()`, `retry()` |
| `WalkEditCubit` | `loading` / `editing(form, isSaving, failure?)` / `saved(id)` / `discarded` | `loadNew()`, `loadExisting(id)`, `toggleDog`, `setMemo`, `addPhotos(List<PreparedImage>)`, `removePhoto(i)`, `save()`, `discard()` |
| `WalkDetailCubit` | `loading` / `loaded(walk, track)` / `deleting` / `deleted` / `failure(failure)` | `load(id)`, `delete()` |
| `WalkFeedCubit` | `loading` / `loaded(walks, isTracking)` / `failure(failure)` | `start()` — `watchWalks` + `trackerStates` 구독, `retry()` |

- `elapsed` 는 1초 `Timer.periodic` 마다 `session.elapsedAt(now)` 로 **다시 계산한다**(틱을
  누적하지 않는다 — 백그라운드에서 틱이 밀려도 맞다)
- `failure` 에 `dogs` · `selectedIds` 를 두는 이유: 권한 거부 뒤 재시도할 때 선택이 남아야 한다
- `WalkEditCubit.loadNew()` 는 `trackerState` 가 `finished` 가 아니면 `walkNotFound`.
  `addPhotos` 는 10장을 넘는 몫을 버린다(UI 도 비활성). `discard()` 는 신규면 모든 사진,
  수정이면 **이번 편집에서 추가한 사진만** 지운다
- 폼 모델 `DogForm` · `WalkForm` 은 presentation 의 Freezed 단일 모델

### 페이지 — feature 는 go_router 를 모른다

| 페이지 | 생성자 콜백 | 공통 위젯 |
|---|---|---|
| `WalkFeedPage` | `onStartWalk`, `onOpenWalk(id)`, `onOpenDogs` | `AppPlaceholder`(빈 · 실패), `AppButton.primary`, `AppAvatar` |
| `ActiveWalkPage` | `onStopped`, `onAddDog` | `AppButton.primary`, `AppConfirmDialog(isDestructive: false)`, `AppPlaceholder` |
| `WalkEditPage.create` / `.edit(walkId)` | `onSaved(id)`, `onDiscarded` | `AppButton`, `AppConfirmDialog`(버리기, 파괴적), `AppSnackBar`, `AppAvatar` |
| `WalkDetailPage(walkId)` | `onEdit`, `onDeleted` | `AppOverflowMenu` + `AppOverflowMenuItem`, `AppConfirmDialog`, `AppPlaceholder` |
| `DogListPage` | `onAddDog`, `onOpenDog(id)` | `AppListTile`, `AppAvatar(imageFile)`, `AppPlaceholder` |
| `DogEditPage({dogId})` | `onDone` | `AppAvatar(imageBytes / imageFile)`, `AppButton`, `AppOverflowMenu`, `AppConfirmDialog` |

- 사진 선택은 페이지가 `getIt<ImagePickerService>()` 를 직접 부른다(트레이더 `post_editor_page`
  선례). 앨범 `pickImages(limit: 10 - n)`, 카메라 `captureImage()`(§5)
- 생일은 `showDatePicker`. 공통 위젯이 없고 한 곳뿐이라 승격하지 않는다
- 토큰은 `AppColors` · `AppSpacing` · `AppRadius` · `Theme.of(context)`([CLAUDE.md](../../../CLAUDE.md))

### 위젯 (`presentation/widget/`)

| 위젯 | 역할 |
|---|---|
| `RouteMap(points, {followLast})` | `FlutterMap` + `TileLayer` + `PolylineLayer` + OSM 출처 표기. 점이 없으면 `walkNoTrack` 안내 |
| `RoutePreviewPainter(points)` | 타일 없는 `CustomPaint` 썸네일. 경계 상자를 정규화해 폴리라인만 그린다 |
| `WalkCard` | `DogAvatars` · 날짜 · `WalkStatsRow` · 첫 사진 또는 `RoutePreviewPainter` · 메모 2줄 |
| `DogAvatars` | 겹친 `AppAvatar`(최대 3 + "+n") |
| `WalkStatsRow` | 거리 · 시간 |
| `ActiveWalkBanner` | 피드 상단 추적 중 배너(탭 → `onStartWalk`) |
| `DogChips` | `FilterChip` 다중 선택 |
| `PhotoStrip` · `PhotoSourceSheet` · `WalkPhotoGrid` | 사진 띠 · 앨범/카메라 시트 · 상세 그리드 |

`RouteMap` 의 `TileLayer`:

- `urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'`
- `userAgentPackageName: 'com.karma.pawlog'` — OSM 타일 사용 정책이 요구한다
- `tileProvider: getIt<TileProvider>()` — 운영은 `NetworkTileProvider`, **위젯 테스트는 투명
  이미지를 주는 stub 을 등록**해 네트워크를 타지 않는다

`WalkFormat`: 거리(`< 1000 m` → `"850 m"`, 그 외 `"1.2 km"`), 시간(`"1시간 5분"` · `"23분"`),
경과 시계(`"12:34"` · `"1:02:03"`, 로케일 무관). 날짜는 `core` 의 `displayDateTime`.

### 문자열

공유 `l10n` ARB 3개에 `walk` 접두로 약 60개, 실패 문자열은 `failureWalk…` · `failureDog…`.
모든 키에 `@key.description`. 이름만 적는다.

| 묶음 | 키 |
|---|---|
| 피드 | `walkAppTitle` `walkFeedTitle` `walkFeedEmptyTitle` `walkFeedEmptyMessage` `walkFeedStartAction` `walkFeedContinueAction` `walkFeedDogsAction` `walkActiveBannerTitle` |
| 강아지 | `walkDogListTitle` `walkDogListEmptyTitle` `walkDogListEmptyMessage` `walkDogAddAction` `walkDogNewTitle` `walkDogEditTitle` `walkDogNameLabel` `walkDogBreedLabel` `walkDogBirthdayLabel` `walkDogBirthdayUnset` `walkDogPhotoChange` `walkDogSaveAction` `walkDogDeleteAction` `walkDogDeleteConfirmTitle` `walkDogDeleteConfirmMessage` |
| 추적 | `walkActiveTitle` `walkSelectDogsLabel` `walkNoDogsMessage` `walkStartAction` `walkStopAction` `walkStopConfirmTitle` `walkStopConfirmMessage` `walkElapsedLabel` `walkDistanceLabel` `walkTrackingNoticeTitle` `walkTrackingNoticeText` `walkRetryAction` |
| 저장 · 상세 | `walkSaveTitle` `walkEditTitle` `walkMemoLabel` `walkPhotosLabel` `walkPhotoAdd` `walkPhotoFromGallery` `walkPhotoFromCamera` `walkPhotoLimit` `walkSaveAction` `walkDiscardAction` `walkDiscardConfirmTitle` `walkDiscardConfirmMessage` `walkDetailTitle` `walkEditAction` `walkDeleteAction` `walkDeleteConfirmTitle` `walkDeleteConfirmMessage` `walkNoTrack` |
| 포맷 | `walkDistanceKm` `walkDistanceMeters` `walkDurationHoursMinutes` `walkDurationMinutes` |
| 실패 | `failureWalkDogRequired` `failureWalkTrackingAlreadyActive` `failureWalkNotFound` `failureWalkPhotoSaveFailed` `failureDogNameRequired` |

## 5. DI · 앱 셸

### `feature_walk` 파일 구조

```
packages/features/walk/
├── pubspec.yaml   # core, design_system, l10n + drift, drift_flutter, geolocator, flutter_map, latlong2, path_provider, flutter_bloc, freezed_annotation, injectable
├── build.yaml     # drift: store_date_time_values_as_text
└── lib/
    ├── feature_walk.dart            # 페이지 6개 · WalkUseCase · FeatureWalkPackageModule export
    └── src/
        ├── di/  feature_walk.dart (microPackage) · walk_register_module.dart
        ├── domain/
        │   ├── entity/      dog · dog_draft · geo_point · walk_track_point · walk_session · tracker_state
        │   │                tracking_notice · walk · walk_photo · walk_draft · walk_update
        │   ├── policy/      walk_tracking_policy · route_preview
        │   ├── repository/  dog_repository · walk_repository · walk_tracker · photo_storage
        │   └── usecase/     walk_use_case
        │       └── scenario/  save_dog · delete_dog · start_walk · save_walk · discard_walk
        │                      update_walk · delete_walk · store_photo
        ├── data/
        │   ├── database/    walk_database · tables · date_only_converter
        │   ├── repository/  drift_dog_repository · drift_walk_repository · file_photo_storage
        │   ├── location/    location_gateway
        │   └── tracker/     geolocator_walk_tracker
        └── presentation/
            ├── cubit/       dog_list · dog_edit · active_walk · walk_edit · walk_detail · walk_feed (+ _state)
            ├── form/        dog_form · walk_form
            ├── page/        walk_feed · active_walk · walk_edit · walk_detail · dog_list · dog_edit
            ├── widget/      route_map · route_preview_painter · walk_card · dog_avatars · walk_stats_row
            │                active_walk_banner · dog_chips · photo_strip · photo_source_sheet · walk_photo_grid
            └── format/      walk_format
```

### micro module 과 `WalkRegisterModule`

`lib/src/di/feature_walk.dart`(`@InjectableInit.microPackage`) → `FeatureWalkPackageModule`.
레포 3개 · `GeolocatorWalkTracker` · `GeolocatorGateway` · `FilePhotoStorage` · `WalkUseCase` 는
lazySingleton, cubit 6개는 factory. 생성자로 못 만드는 것은 모듈이 준다.

```dart
@module
abstract class WalkRegisterModule {
  @lazySingleton
  @disposeMethod  // close()
  WalkDatabase database() => WalkDatabase(driftDatabase(name: 'pawlog'));

  @preResolve
  @Named('walkPhotosRoot')
  Future<Directory> photosRoot() async {
    final documents = await getApplicationDocumentsDirectory();
    return Directory('${documents.path}/pawlog_photos').create(recursive: true);
  }

  @lazySingleton
  TileProvider tileProvider() => NetworkTileProvider();
}
```

`Directory` 는 흔한 타입이라 `@Named` 로 구분한다. `IdGenerator` 는 `CorePackageModule` 이 준다.

### `apps/pawlog`

```
apps/pawlog/
├── pubspec.yaml         # core, design_system, l10n, feature_walk + flutter_bloc, go_router, injectable, get_it, flutter_localizations
├── lib/
│   ├── main.dart
│   ├── bootstrap.dart   # ensureInitialized → configureDependencies → getDogs() 1회 → runApp(PawlogApp(hasDogs))
│   ├── app/
│   │   ├── app.dart     # PawlogApp: MaterialApp.router, AppTheme.light/dark, themeMode: system, AppLocalizations
│   │   └── router/
│   │       ├── app_router.dart     # createRouter({required bool hasDogs}) — 8경로
│   │       └── dogs_redirect.dart  # PawlogPaths + DogsRedirect
│   └── di/injection.dart           # externalPackageModulesBefore: [Core, FeatureWalk]
├── android/ ios/        # flutter create --org com.karma. 권한 선언
└── test/
    ├── app/router/dogs_redirect_test.dart
    └── convention/package_boundary_test.dart
```

- `PawlogPaths`: `home '/'`, `walk '/walk'`, `walkSave '/walk/save'`, `walk(id) '/walks/$id'`,
  `walkEdit(id)`, `dogs '/dogs'`, `dogNew '/dogs/new'`, `dog(id)`. `/dogs` 아래에서 **`new` 를
  `:id` 보다 먼저** 선언한다
- `DogsRedirect(hasDogs)`: 통근 앱 `SettingsRedirect` 와 같은 모양. 0마리면 `/dogs/new`
  외의 모든 경로를 그리로 보낸다. `DogEditPage.onDone` 에서 `markHasDogs()` → `go('/')`.
  라우터는 cubit 을 구독하지 않는다 — **부팅 시 1회 판단**(마지막 강아지 삭제는 §8)
- 이동: 진행 `onStopped` → `pushReplacement('/walk/save')`, 저장 `onSaved` → `go('/')`,
  상세 `onDeleted` → `pop()`. 피드 · 목록은 drift `watch()` 로 갱신되므로 "돌아오면 새로고침"
  콜백이 없다(통근 §7 후보 9 의 또 다른 답)

### 플랫폼 권한

| 플랫폼 | 선언 |
|---|---|
| Android `AndroidManifest.xml` | `INTERNET`(OSM 타일), `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`. `CAMERA` 는 선언하지 않는다 — image_picker 는 카메라 권한 선언 없이 동작하고, 선언하면 런타임 요청 의무가 생긴다 |
| iOS `Info.plist` | `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `UIBackgroundModes: [location]` |

Android 13+ 알림 권한은 따로 요청하지 않는다(`permission_handler` 제외). 거부돼도 포그라운드
서비스는 돌고 알림만 안 보인다.

### `core` · `design_system` 의 추가 변경 (모두 additive)

| 대상 | 변경 | 이유 |
|---|---|---|
| `core` `ImagePickerService` | `Future<PreparedImage?> captureImage()` — `ImageSource.camera` → `prepare` | 같은 압축 정책으로 카메라 촬영 |
| `core` `FailureCode` | +5 (§2) | — |
| `design_system` `AppAvatar` | `File? imageFile` 인자. 우선순위 `imageBytes > imageFile > imageUrl` | 로컬 사진 파일 아바타. 지금은 URL · 바이트만 받는다 |
| `l10n` | ARB 3개 + `FailureLocalizations` switch | — |

## 6. 테스트

구조는 구현을 그대로 반영한다(`packages/features/walk/lib/src/**` ↔ `test/**`). 테스트 이름은
한국어 문장.

### feature_walk

| 대상 | 방법 | 확인할 것 |
|---|---|---|
| `WalkTrackingPolicy` · `RoutePreview` | 순수 Dart | 50 m 경계 · 2 m 경계 · 첫 점 · null 정확도, 64점 이하 · 첫/끝 유지 · encode↔decode 왕복 · 깨진 JSON |
| 시나리오 8개 | `mocktail` + 고정 `now` | 이름 공백 → `dogNameRequired`, 사진 교체 시 옛 파일 삭제, 강아지 0 → `walkDogRequired`, 저장 후 `clear`, 빠진 사진만 삭제, DB 실패 시 파일 안 지움 |
| `DriftDogRepository` · `DriftWalkRepository` | `NativeDatabase.memory()` | 왕복, 피드 최신순, 강아지 이름 변경이 `watchWalks` 에 흐름, 산책 삭제 → 점 · 사진 · 연결 cascade, 강아지 삭제 → 산책 남음, `getWalkTrack` seq 순 |
| `FilePhotoStorage` | `Directory.systemTemp.createTemp` | 상대 경로 반환, `resolve`, 없는 파일 `delete` 무시 |
| `GeolocatorWalkTracker` | mock `LocationGateway` + `StreamController<Position>` | 서비스 꺼짐 · 권한 거부(재요청 안 함) · 이미 추적 중, 정책 탈락 점 버림, 거리 합산, `stop` → `finished`, 스트림 오류에도 `tracking` 유지 |
| cubit 6개 | `bloc_test` · `fakeAsync` | `elapsed` 1초 갱신, 추적 중 진입 시 바로 `tracking`, 사진 10장 상한, 신규/수정 `discard` 차이 |
| 페이지 | `getIt` 에 mock usecase · stub `TileProvider` 등록 | 피드 빈/카드/배너, 진행 화면 칩 · 종료 확인, 상세 지도 · 메뉴, 강아지 목록 · 폼 |

### apps/pawlog

- `dogs_redirect_test.dart`: 0마리 → 모든 경로가 `/dogs/new`, `/dogs/new` 는 그대로,
  `markHasDogs` 뒤 통과, 강아지가 있으면 리다이렉트 없음
- `package_boundary_test.dart`: 통근 앱 것을 복사해 `packages/features/walk/pubspec.yaml` 에
  `feature_` 접두 · `supabase_flutter` · `go_router` 가 없음을 검사

### 에뮬레이터 검증 (기획서 §8)

1. 첫 실행 → `/dogs/new` → 강아지 저장 → 빈 피드
2. FAB → 강아지 선택 → 시작 → 위치 권한 허용 → GPX 재생 → 폴리라인 · 거리 · 시간이 자란다
3. 홈 버튼으로 30초 백그라운드 → 알림 → 돌아오면 점이 계속 쌓여 있다
4. 종료 → 확인 → 사진 2장 + 메모 → 저장 → 피드 카드에 사진 썸네일
5. 카드 → 상세 → 메모 수정 → 피드가 새로고침 없이 바뀐다
6. 산책 삭제 → `adb shell run-as com.karma.pawlog ls files/pawlog_photos` 에서 사진이 사라진다
7. 위치 거부 → `AppPlaceholder` + 재시도
8. 앱 완전 종료 후 재실행 → 기록이 남아 있다. 다크 모드

## 7. 리팩터링 후보 — 이 앱을 만들며 확인된 것

여기 적힌 것은 **지금 고치지 않는다.** [통근 설계 §7](2026-09-13-commute-app-design.md#7-리팩터링-후보--이-앱을-만들며-확인된-것)과
같은 방식으로 쌓고, 작업 중 새로 발견한 항목은 이 목록 끝에 추가한다.

| # | 발견 | 근거 |
|---|---|---|
| 1 | `LocationGateway` 가 `feature_commute` 와 `feature_walk` 에 두 벌 있다 | 규칙 ⑥ 때문에 복사했다. `location` 패키지(geolocator 래퍼 + 권한 흐름 `_requestDeclined`)로 빼면 둘 다 거기를 본다 |
| 2 | 앱이 늘 때마다 `core` 의 `FailureCode` 와 `l10n` 의 ARB · exhaustive switch 가 함께 자란다 | 통근 후보 3 · 4 의 반복. 셋째 앱에서 +5 코드 · 약 60 키. feature 별 실패 코드 · ARB 분리가 필요하다는 근거가 하나 더 |
| 3 | `AppAvatar` 의 필수 인자가 `nickname` 이다 | 강아지 이름을 `nickname` 으로 넘긴다. 사용자 아바타 전용 이름이 공용 위젯에 남았다 → `label` 등 |
| 4 | 시나리오가 각자 `DateTime Function() now` 를 받는다 | `core` 에 시계 추상(`Clock`)이 없다. 셋째 앱부터 시각 단언이 필요해졌다 |
| 5 | [CLAUDE.md](../../../CLAUDE.md) 의 경로가 `app/lib/design_system/…` · `cd app` 등 모노레포 이전 모습이다 | 실제는 `packages/design_system/lib/src/widget/` · `apps/<app>`. 새 앱을 만드는 에이전트가 처음 읽는 문서라 혼란이 크다 |

## 8. 남은 판단 (착수 시 결정)

기획서 §9 "남은 판단" 과 같다.

- 위치 점 필터 수치(`distanceFilter` 3 m · 최소 이동 2 m · 정확도 50 m) — 실기기에서 조정
- 마지막 강아지를 삭제했을 때 — 부팅 시 1회 판단이라 재실행 전까지는 강아지 없이 진행
  화면에 들어간다(시작 버튼 비활성). 그걸로 충분한지, 삭제를 막을지
- OSM 타일 캐시 여부(`flutter_map` 캐시 플러그인 · 오프라인)
- 리팩터링 후보의 처리 시점 — §7
