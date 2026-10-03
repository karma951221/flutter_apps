# pawlog — 기획서 (강아지 산책 기록, 셋째 앱)

> [pawlog 허브](README.md) · [진행 현황](status.md) · [아키텍처](../../../docs/architecture.md) · [의존 그래프](../../../docs/dependencies.md) · [개발환경](../../../docs/setup.md) · [테스트 가이드](../../../docs/testing/README.md)

> 상태: **v0.1 초안** · 작성 2026-10-03
>
> 코드보다 먼저 쓴 기획서다. 화면 · 도메인 · 데이터의 세부는 feature 착수 때 각
> `features/<name>/plan.md` 가 이 문서를 상세화하고, 구현하며 바뀐 판단은 이 문서의
> 해당 절을 갱신한다. 진행 상태는 [진행 현황](status.md)에만 적는다.

---

## 1. 한 줄 정의

**강아지와 산책한 기록을 쌓고, 피드로 돌아보는 모바일 앱.**

산책 시작을 누르면 GPS 로 코스를 그리고, 끝나면 강아지 · 사진 · 메모를 붙여 저장한다.
홈은 그 기록의 타임라인(피드)이다. v1 은 **혼자 쓰는 기록 앱**이고, 로그인과 다른
사람의 피드는 v2 에서 Supabase 위에 얹는다.

## 2. 목표와 성공 기준

이 프로젝트는 **토이 프로젝트**다. 사용자 수나 성장은 목표가 아니다.

**성공 기준**: "산책 시작 → 코스 추적 → 저장 → 피드에서 다시 보기" 흐름이 **기기
하나에서 끝까지 동작하는 상태로 완성한다.** 백엔드 없이, 앱을 껐다 켜도 기록이 남아
있어야 한다.

부차 목표:

1. **셋째 앱으로 `packages/` 경계를 다시 시험한다.** [통근 앱](../../commute/docs/plan.md)이
   `core` · `design_system` · `l10n` 만으로 섰다면, 이 앱은 거기에 **로컬 DB 와 지도**를
   더해도 같은 경계가 유지되는지 본다
2. **로컬 DB(drift) 를 들인다.** [트레이더 기획 §4.2](../../trader/docs/overview.md#42-로컬-db는-drift-하나만)
   가 "로컬 DB 는 drift 하나만" 으로 정해 두고 도입을 미뤘다. 경로 점 수천 개와
   산책↔강아지 조인은 shared_preferences 로는 안 되므로 이 앱이 첫 사용처다
3. **백그라운드 위치 추적**을 겪어 본다 — 권한 · 포그라운드 서비스 · 배터리

**v2(소셜) 를 위해 v1 에서 지키는 것**: 엔티티 id 는 앱이 만드는 UUID(`core` 의
`IdGenerator`), 모든 행에 `created_at` · `updated_at`, 저장소는 인터페이스 뒤에 둬
Supabase 구현을 DI 교체로 넣을 수 있게 한다. 그 외 소셜 관련 코드는 v1 에 넣지 않는다.

## 3. MVP(v1) 범위

### 포함

| 영역 | 내용 |
|------|------|
| 강아지 | 여러 마리 등록 · 수정 · 삭제. 이름(필수) · 사진 · 품종 · 생일(선택). 첫 실행에 0마리면 등록 화면으로 유도 |
| 산책 추적 | 시작/종료 버튼. GPS 로 경로 · 거리 · 소요 시간을 자동 기록. 앱이 뒤로 가도 추적 유지(Android 포그라운드 알림 · iOS 백그라운드 위치). 지도에 실시간 경로 |
| 산책 기록 | 종료 직후 강아지(1마리 이상) · 메모 · 사진(최대 10장, 앨범/카메라)을 붙여 저장. 수정 · 삭제. 상세(지도 · 거리 · 시간 · 사진 · 메모) |
| 피드 | 내 산책 기록의 최신순 타임라인. 카드 = 강아지 아바타 · 날짜 · 거리 · 시간 · 첫 사진(없으면 경로 썸네일) · 메모. 추적 중이면 상단 배너. 탭 → 상세 |
| 환경 | 다국어(한국어 · 영어 · 일본어, 기존 `l10n`), 테마는 시스템 추종 |

### 제외 (v1 범위 밖)

로그인 · Supabase · 다른 사람의 피드 · 좋아요/댓글 · 코스 즐겨찾기/추천 · 수동 코스
입력 · 일시정지/재개 · 앱 강제종료 후 진행 중 산책 복구 · 통계 대시보드 · 알림 권한
안내(`permission_handler`) · 피드 페이지네이션 · 데이터 내보내기 · API 키가 필요한
지도 서비스.

> 복구와 페이지네이션은 v1 스키마가 이미 받아 줄 수 있게 설계한다(§7). 만들지 않을
> 뿐 막아 두지 않는다.

### 범위에 대한 솔직한 평가

핵심 리스크는 **백그라운드 GPS** 다 — 권한 흐름, Android 포그라운드 서비스, 배터리,
에뮬레이터에서의 검증. 그래서 W2 산책 추적을 W1 강아지 바로 다음에 두어 **가장 먼저
기기에서 확인한다.** 추적이 안 되면 그 뒤의 저장 · 피드는 의미가 없다.

iOS 는 개발 기기가 없어 미검증으로 남긴다([개발환경 §2](../../../docs/setup.md)와 같은
사정). 권한 키와 백그라운드 모드는 선언해 두되, 동작 확인은 Android 에뮬레이터 기준이다.

## 4. 기술 스택

### 4.1 확정

| 영역 | 선택 | 비고 |
|------|------|------|
| 앱 · 상태 · DI · 모델 | Flutter · bloc(Cubit) · get_it + injectable · freezed | 모노레포 공통. [아키텍처](../../../docs/architecture.md) 규칙을 그대로 따른다 |
| 로컬 DB | **drift** + `drift_flutter` | §4.2 |
| 위치 | **geolocator** | 통근 앱과 같은 패키지. §4.3 |
| 지도 | **flutter_map** + `latlong2` | §4.4 |
| 사진 | `core` 의 `ImagePickerService`(image_picker + 압축) 재사용, 파일은 앱 문서 디렉터리 | §4.5 |
| 단순 설정 | shared_preferences | 필요할 때만. v1 에는 쓸 곳이 없을 수도 있다 |
| 코드 생성 | build_runner | freezed · injectable · drift 공용 |

### 4.2 로컬 DB 는 drift

[트레이더 기획 §4.2](../../trader/docs/overview.md#42-로컬-db는-drift-하나만) 의 결정을
그대로 쓴다 — Hive · Isar 는 유지보수가 끊겼고, drift 는 build_runner 기반이라 코드
생성 파이프라인이 통일되며, Supabase(Postgres) 와 같은 SQL 모델이다.

이 앱에서 shared_preferences 로 안 되는 이유:

- 산책 하나에 경로 점이 수백~수천 개다. 키-값 저장소에 JSON 으로 넣으면 피드를 열
  때마다 전부 읽는다
- 산책↔강아지가 다대다다. 강아지 이름을 바꾸면 모든 카드에 반영돼야 한다
- drift 의 `watch()` 가 조인 쿼리의 변경을 스트림으로 주므로, 피드와 강아지 목록이
  "돌아오면 새로고침" 콜백 없이 저절로 갱신된다

테스트는 `NativeDatabase.memory()` 로 실제 SQL 을 돌린다. mock 레포지토리로는 조인과
cascade 가 검증되지 않는다.

### 4.3 위치는 geolocator, 백그라운드는 플랫폼 설정으로

`Geolocator.getPositionStream` 에 Android 는 `foregroundNotificationConfig`(포그라운드
서비스 + 알림), iOS 는 `allowBackgroundLocationUpdates` 를 주면 앱이 뒤로 가도 스트림이
끊기지 않는다. 별도의 백그라운드 패키지를 들이지 않는다.

통근 앱의 `LocationGateway`(정적 `Geolocator` 를 감싸 mock 가능하게 한 것)는 **복사해서
쓴다.** [아키텍처 규칙 ⑥](../../../docs/architecture.md)이 data 계층의 feature 간 import 를
막고, `core` 로 올리면 이미 무거운 `core` 에 geolocator 가 하나 더 붙는다. 두 벌이 된
것은 리팩터링 후보로 적어 둔다(§9).

### 4.4 지도는 flutter_map (OpenStreetMap)

API 키 · 네이티브 SDK · 과금이 없고 순수 Dart 라 위젯 테스트가 된다. Google Maps 는
키와 플랫폼 설정이 필요하고 토이 프로젝트에 얻는 것이 없다.

타일은 네트워크를 탄다. **피드 카드의 경로 썸네일은 타일 없이 `CustomPaint` 로
그린다** — 카드마다 지도를 띄우면 OSM 타일 서버에 부담이고 스크롤이 무거워진다.
지도는 진행 화면과 상세 화면 두 곳에만 있다. 위젯 테스트는 `TileProvider` 를 stub 으로
갈아 끼워 네트워크를 타지 않는다.

### 4.5 사진은 압축해서 앱 문서 디렉터리에

`core` 의 `ImagePickerService` 가 긴 변 1080px · 품질 80 으로 압축한 바이트를 준다
(Supabase 없이도 쓸 수 있는 것을 확인했다). 카메라 촬영은 같은 서비스에 `captureImage`
를 더해 쓴다. 파일은 `<documents>/pawlog_photos/<uuid>.<ext>` 에 두고, **DB 에는 상대
경로만** 적는다 — iOS 는 설치 · 업데이트마다 컨테이너의 절대 경로가 바뀐다.

### 4.6 패키지 경계

`feature_walk` 는 `core` · `design_system` · `l10n` 만 의존한다. `feature_*` ·
`supabase_flutter` · `go_router` 는 쓰지 않는다 — 통근 앱의 `package_boundary_test` 를
`apps/pawlog` 에도 둔다. 페이지는 콜백만 받고 경로는 앱의 라우터가 정한다(통근 앱과
같은 선택).

## 5. Feature 분해

v1 은 **패키지 하나(`packages/features/walk`, `feature_walk`)** 에 feature 넷을 둔다.
서로 엔티티를 공유하고(산책↔강아지) 화면이 적어, 패키지를 나누면 비용만 든다. v2 소셜이
들어올 때 쪼갠다. 문서는 트레이더처럼 `apps/pawlog/docs/features/<name>/` 에 feature
별로 `plan.md` · `history.md` · `testing.md` 를 둔다.

| # | Feature | 역할 | 단계 |
|---|---------|------|------|
| W1 | **dog** | 강아지 프로필 등록 · 수정 · 삭제 · 사진, 첫 실행 등록 유도 | 1 |
| W2 | **tracking** | 산책 시작/종료, GPS 경로 · 거리 · 시간, 백그라운드 유지, 진행 화면(지도) | 1 |
| W3 | **record** | 산책 저장(강아지 · 메모 · 사진) · 수정 · 삭제 · 상세 | 2 |
| W4 | **feed** | 내 기록 타임라인 · 카드 · 빈 상태 · 추적 중 배너 · 변경 반영 | 2 |
| W5 | **social** (v2) | Supabase 동기화 · 공개 피드 · 프로필 · 반응/댓글 — 트레이더 feature 재사용 검토 | 3 |

### 교차 관심사 (특정 feature 소유 아님)

| 이름 | 역할 | 위치 |
|------|------|------|
| `WalkDatabase` (drift) | 테이블 5개(§7), 스키마 v1 | `feature_walk/src/data/database/` |
| `PhotoStorage` | 사진 파일 저장 · 경로 해석 · 삭제 | `feature_walk/src/data/repository/` |
| `WalkTracker` | **앱 수명 싱글턴.** 위치 스트림을 구독해 세션(점 · 거리 · 시작 시각)을 누적하고 `idle` / `tracking` / `finished` 상태를 스트림으로 준다. 화면을 떠나도 추적이 끊기지 않는 이유 | `feature_walk/src/data/tracker/` |
| `WalkUseCase` | 유일한 facade. cubit 은 이것만 본다 | `feature_walk/src/domain/usecase/` |
| `FailureCode` +5 | `walkDogRequired` · `walkTrackingAlreadyActive` · `walkNotFound` · `walkPhotoSaveFailed` · `dogNameRequired` | `core` + `l10n` 의 exhaustive switch + ARB 3개 |
| `AppAvatar.imageFile` | 로컬 파일로 아바타를 그리는 인자 (지금은 URL · 바이트만 받는다) | `design_system` (+ 테스트) |
| l10n `walk*` 키 | 약 55개. ko 템플릿 + en · ja, 모든 키에 `@` 설명 | `l10n` |

## 6. Feature 별 개발 항목

각 feature 의 `plan.md` 가 이 절을 상세화한다. 여기에는 화면 · 상태 · 완료 조건의
골격만 둔다.

### 공통 규칙

- cubit 은 페이지마다 `BlocProvider` 로 만든다. 상태는 sealed 이고 `switch` 로 분기한다
- 앱 수명 상태는 DI 싱글턴(`WalkTracker`) 에만 둔다. 앱 루트에 `MultiBlocProvider` 를
  두지 않는다
- 모든 `await` 뒤에 `isClosed` 를 검사한다. 스트림 구독은 `close()` 에서 끊는다
- 공통 위젯은 [UI 공통 위젯 규칙](../../../CLAUDE.md)의 진입점을 쓴다. 테스트 이름은
  한국어 문장

### W1. dog — 강아지

| 화면 | 경로 | 내용 |
|------|------|------|
| 목록 `DogListPage` | `/dogs` | `AppListTile` 행(`AppAvatar(imageFile)` · 이름 · 품종), 빈 상태 `AppPlaceholder`, FAB 추가 |
| 폼 `DogEditPage` | `/dogs/new` · `/dogs/:id` | 사진 변경, 이름 · 품종, 생일(`showDatePicker`), 저장. 기존 강아지는 `AppOverflowMenu` 삭제 → `AppConfirmDialog` |

- 엔티티 `Dog(id, name, breed?, birthday?, photoPath?, createdAt, updatedAt)` · `DogDraft`
- 상태 `DogListState: loading / loaded(dogs) / failure`,
  `DogEditState: loading / editing(form, isSaving, failure?) / saved / deleted`
- 시나리오 `SaveDog`(이름을 trim 해 비면 `dogNameRequired`, 사진 교체 시 옛 파일 삭제) ·
  `DeleteDog`(행 + 사진 파일. `walk_dogs` 는 cascade 로 끊기고 **산책 기록은 남는다**)
- **첫 실행**: 앱 부팅 때 `getDogs()` 를 한 번 읽어 0마리면 `/dogs/new` 로 보낸다
  (`DogsRedirect` — 통근 앱 `SettingsRedirect` 와 같은 모양, 부팅 시 1회 판단)
- 완료 조건: 등록 → 목록 → 수정 → 삭제, 사진 교체. drift in-memory 레포 테스트 ·
  cubit · 페이지 · 리다이렉트 테스트

### W2. tracking — 산책 추적

| 화면 | 경로 | 내용 |
|------|------|------|
| 진행 `ActiveWalkPage` | `/walk` | 시작 전: 강아지 칩 다중 선택(전부 기본 선택, 0마리면 시작 비활성). 추적 중: 지도에 실시간 폴리라인 + 카메라 추종, 경과 시간(1초 갱신), 거리, 종료 버튼 → `AppConfirmDialog(isDestructive: false)` |

- 상태 `ActiveWalkState: selectingDogs(dogs, selectedIds) / starting / tracking(session, elapsed) / stopped(session) / failure(failure, …)`.
  종료 확인 → `stopped` → `onStopped()` 콜백으로 W3 저장 폼으로 간다
- 권한 거부 · 서비스 꺼짐은 기존 `FailureCode.locationPermissionDenied` /
  `locationServiceDisabled` 로 `AppPlaceholder` + 재시도. 통근 앱의 "이번 세션에 거부했으면
  다시 묻지 않는다" 로직을 재사용한다
- **추적 중 뒤로 가기는 허용**한다. 추적은 `WalkTracker` 에 있으므로 피드로 갔다
  돌아와도 이어진다. 피드는 추적 중 배너를 띄운다(W4)
- `WalkTracker.start(dogIds, notice)`: 서비스 · 권한 확인 → 위치 스트림(`distanceFilter: 3`,
  Android 포그라운드 알림 문구는 l10n 으로 페이지가 넘긴다) → `WalkTrackingPolicy.accept`
  (정확도 ≤ 50m, 직전 점에서 ≥ 2m 이동) → 점 누적 + `distanceBetween` 합산 →
  `tracking(session)` 방출. `stop()` → `finished(session)`. 이미 추적 중이면
  `walkTrackingAlreadyActive`
- 엔티티 `WalkSession(dogIds, startedAt, endedAt?, points, distanceMeters)` ·
  `WalkTrackPoint(point, recordedAt, accuracy?)` · sealed `TrackerState`
- 플랫폼: Android `INTERNET` · `ACCESS_FINE_LOCATION` · `ACCESS_COARSE_LOCATION` ·
  `FOREGROUND_SERVICE` · `FOREGROUND_SERVICE_LOCATION` · `POST_NOTIFICATIONS`,
  iOS `NSLocationWhenInUseUsageDescription` · `NSLocationAlwaysAndWhenInUseUsageDescription` ·
  `UIBackgroundModes: location`
- 완료 조건: 에뮬레이터 GPX 재생으로 폴리라인 · 거리 · 시간 확인, 홈 갔다 돌아와도 유지,
  백그라운드 30초 뒤에도 점이 쌓임, 권한 거부 분기. 테스트: 정책(순수 Dart) ·
  tracker(mock gateway + `StreamController<Position>`) · cubit(`fakeAsync`) ·
  페이지(stub `TileProvider`)

### W3. record — 산책 기록

| 화면 | 경로 | 내용 |
|------|------|------|
| 저장/수정 `WalkEditPage` | `/walk/save`(신규) · `/walks/:id/edit` | 요약 헤더(날짜 · 거리 · 시간), 강아지 칩, 메모, 사진 띠(추가 → 시트: 앨범 / 카메라, 최대 10장), 저장, 버리기 → `AppConfirmDialog`(파괴적. 저장해 둔 사진 파일도 지운다) |
| 상세 `WalkDetailPage` | `/walks/:id` | 지도에 전체 경로(점이 없으면 안내), 거리 · 시간 · 강아지, 사진 그리드, 메모, `AppOverflowMenu`(수정 · 삭제 → `AppConfirmDialog`) |

- 엔티티 `Walk(id, startedAt, endedAt, duration, distanceMeters, memo?, dogs, photos, previewPoints, createdAt, updatedAt)`.
  **전체 경로는 분리**해서 `getWalkTrack(id)` 로 따로 읽는다 — 피드가 가벼워야 한다.
  `WalkDraft`(신규) · `WalkUpdate`(수정) · `WalkPhoto(id, path, position)`
- 사진 선택은 페이지가 `getIt<ImagePickerService>()` 를 직접 부른다(트레이더
  `post_editor_page` 선례). 선택 즉시 `storePhoto` 로 파일에 쓰고 경로를 폼에 쌓는다
- 시나리오 `SaveWalk`(강아지 0 → `walkDogRequired`, uuid · 시각 · 64점 이하 프리뷰 생성,
  트랜잭션 저장, 끝나면 `tracker.clear()`) · `UpdateWalk`(목록에서 빠진 사진 파일 삭제) ·
  `DeleteWalk`(행 삭제 → 파일은 best-effort) · `DiscardWalk` · `StorePhoto`
- 상태 `WalkEditState: loading / editing(form, isSaving, failure?) / saved(id) / discarded`,
  `WalkDetailState: loading / loaded(walk, track) / deleting / deleted / failure`
- 완료 조건: 저장 → 상세 → 수정 → 삭제. 사진 파일 생성 · 삭제를 `adb` 로 확인.
  레포 · 시나리오 · cubit · 페이지 테스트

### W4. feed — 피드

| 화면 | 경로 | 내용 |
|------|------|------|
| 피드 `WalkFeedPage` | `/` | 카드 목록(최신순). 추적 중이면 상단 배너(탭 → `/walk`). FAB "산책 시작" / 추적 중이면 "산책 계속". AppBar 액션 → 강아지 목록. 빈 상태 `AppPlaceholder`("첫 산책을 시작해 보세요" + 시작 버튼). 실패 → 재시도 |

- 카드 `WalkCard`: 겹친 `AppAvatar`(강아지들), 날짜, 거리 · 시간, 첫 사진(없으면
  `CustomPaint` 경로 썸네일), 메모 2줄
- `watchWalks()` 스트림을 구독한다. 저장 · 수정 · 삭제 · 강아지 이름 변경이 drift
  `watch()` 로 반영되므로 "돌아오면 새로고침" 콜백이 없다
- 상태 `WalkFeedState: loading / loaded(walks, isTracking) / failure`
- v1 은 전체 로드. v2 에서 `CursorPage` · `AppLoadMoreListener` 로 바꾼다
- 완료 조건: 빈 상태 → 저장 후 카드 → 상세 → 삭제 후 사라짐, 강아지 이름 변경이
  카드에 반영, 다크 모드

### W5. social — 소셜 (v2, 별도 기획)

로그인(`feature_auth`), Supabase 테이블 + RLS, 내 기록 동기화, 공개 피드, 프로필,
반응 · 댓글. 트레이더의 feature 를 얼마나 재사용할지는 그때 정한다. v1 은 §2 의
"v2 를 위해 지키는 것" 만 지킨다.

## 7. 데이터 모델 (drift 스키마 v1)

```
dogs        (id TEXT pk, name, breed?, birthday? [date text], photo_path?,
             created_at, updated_at)
walks       (id TEXT pk, started_at, ended_at, duration_seconds INT,
             distance_meters REAL, memo?, route_preview? [JSON [[lat,lng],…] ≤ 64점],
             created_at, updated_at)                         idx started_at
walk_dogs   (walk_id fk→walks cascade, dog_id fk→dogs cascade, pk(walk_id, dog_id))
walk_points (walk_id fk→walks cascade, seq INT, lat REAL, lng REAL, recorded_at,
             accuracy?, pk(walk_id, seq))
walk_photos (id TEXT pk, walk_id fk→walks cascade, path [상대 경로], position INT,
             created_at)                                     idx walk_id
```

### 설계 원칙

- 시각은 ISO-8601 텍스트(`storeDateTimeAsText`), 외래 키는 `PRAGMA foreign_keys = ON`
- **경로 점은 별도 테이블이다.** 피드 쿼리는 점을 읽지 않고(`route_preview` 로 썸네일을
  그린다), 저장은 트랜잭션 일괄 삽입, 읽기는 `ORDER BY seq`. 나중에 "추적 중 점을 바로
  저장해 강제종료를 복구" 하는 것이 append 로 가능하고, Postgres(PostGIS) 로 그대로
  옮겨진다
- v2 때 `user_id` 와 RLS 만 얹으면 되도록 snake_case · timestamptz 호환 이름을 쓴다.
  [트레이더 명명 규칙](../../trader/docs/overview.md#명명-규칙)과 같다

## 8. 개발 단계

커밋 하나씩. 메시지는 저장소의 한국어 양식(`feat(walk): … 를 구현한다`).

| 단계 | 커밋 | 범위 |
|------|------|------|
| 0 | `docs(pawlog): 산책 앱 기획서와 허브를 추가한다` | 이 문서 · 허브 · 진행 현황 · 공통 문서 행 |
| ① | `feat(walk): 산책 도메인과 패키지 뼈대를 추가한다` | `packages/features/walk` 뼈대 · 엔티티 · 인터페이스 · facade · 시나리오 · 정책, `FailureCode` +5, ARB 3개, workspace 등록 |
| ② | `feat(walk): drift 저장소와 사진 파일 저장소를 구현한다` | `WalkDatabase` · 레포지토리 2개 · `FilePhotoStorage` + in-memory 테스트 |
| ③ | `feat(pawlog): 앱 셸과 라우팅을 추가한다` | `flutter create --org com.karma`, 라우터 · `DogsRedirect` · 권한 선언 · `package_boundary_test` · `AppAvatar.imageFile` |
| ④ | `feat(walk): 반려견 목록·편집 화면을 구현한다` | **W1** |
| ⑤ | `feat(walk): GPS 산책 추적과 진행 화면을 구현한다` | **W2** + 지도 위젯 · 거리/시간 포맷 |
| ⑥ | `feat(walk): 산책 저장·편집 화면과 사진을 구현한다` | **W3** 저장 폼 |
| ⑦ | `feat(walk): 산책 피드와 상세 화면을 구현한다` | **W4** + W3 상세 |
| — | 에뮬레이터 검증 → `fix(walk): …` | 통근 앱 `d1c7d8e` 선례. 고친 것은 `history.md` 에 |
| ⑧ | `docs(pawlog): …` | feature 별 `history` · `testing`, 진행 현황, 아키텍처 · 의존 그래프 · 개발환경 · 테스트 허브 |
| v2 | W5 social | 별도 기획 |

①~③ 은 feature 가 서기 위한 바닥이라 W1 보다 앞선다. ④ 부터 feature 순서(W1 → W2 →
W3 → W4)로 간다. **W2 가 기기에서 돌아가기 전에 ⑥ 으로 넘어가지 않는다.**

### 에뮬레이터 검증 시나리오 (⑦ 뒤)

1. 첫 실행 → `/dogs/new` → 강아지 저장 → 빈 피드
2. FAB → 강아지 선택 → 시작 → 위치 권한 허용 → Extended Controls 로 GPX 재생 →
   폴리라인 · 거리 · 시간이 자란다
3. 홈 버튼으로 30초 백그라운드 → 알림이 보인다 → 돌아오면 점이 계속 쌓여 있다
4. 종료 → 확인 → 저장 폼에 사진 2장 + 메모 → 저장 → 피드 카드에 사진 썸네일
5. 카드 → 상세(지도 · 사진) → 메모 수정 → 피드가 새로고침 없이 바뀐다
6. 산책 삭제 → 사진 파일이 사라진다(`adb shell run-as com.karma.pawlog ls files/pawlog_photos`)
7. 위치 거부 → `AppPlaceholder` + 재시도
8. 앱 완전 종료 후 재실행 → 기록이 남아 있다. 다크 모드

## 9. 확정 사항 · 남은 판단

### 확정

| # | 결정 | 근거 |
|---|------|------|
| 1 | 이름은 앱 `pawlog`(`apps/pawlog`, `com.karma.pawlog`), 패키지 `feature_walk` | 트레이더 제품명 daylog 의 형제. 앱명 ≠ feature 명은 트레이더 선례 |
| 2 | v1 은 패키지 하나 | §5 |
| 3 | 로컬 DB 는 drift | §4.2 |
| 4 | 지도는 flutter_map(OSM), 피드 썸네일은 타일 없이 그린다 | §4.4 |
| 5 | 백그라운드 추적은 geolocator 설정만으로 | §4.3 |
| 6 | 사진은 최대 10장, 상대 경로 저장 | §4.5 |
| 7 | 산책에는 강아지가 1마리 이상 붙는다 | 강아지 없는 산책 기록은 이 앱의 정의에 맞지 않는다 |
| 8 | 경로 점은 별도 테이블 + `walks.route_preview` 64점 | §7 |
| 9 | 추적 상태는 DI 싱글턴(`WalkTracker`), cubit 은 페이지 단위 | 화면 이동이 추적을 끊으면 안 된다. 앱 루트 bloc 은 아키텍처 §4 와 어긋난다 |

### 남은 판단 (착수 시 결정)

- 위치 점 필터 수치(`distanceFilter` 3m · 최소 이동 2m · 정확도 50m) — 실기기에서 조정
- 마지막 강아지를 삭제했을 때 — 부팅 시 1회 판단이라 재실행 전까지는 강아지 없이
  시작 화면에 들어간다. 시작 버튼이 비활성이면 충분한지, 삭제를 막을지
- OSM 타일 캐시 여부
- 리팩터링 후보: `LocationGateway` 가 두 feature 에 복사됨(→ `location` 패키지),
  앱이 늘 때마다 `core` 의 `FailureCode` 와 `l10n` ARB 가 함께 자라는 구조
  ([통근 설계 §7](../../../docs/superpowers/specs/2026-09-13-commute-app-design.md#7-리팩터링-후보--이-앱을-만들며-확인된-것)과
  같은 목록에 쌓는다)
