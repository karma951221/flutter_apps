# W2 tracking — 테스트

> [테스트 가이드](../../../../../docs/testing/README.md) · [pawlog 허브](../../README.md) · [계획](plan.md) · [구현 기록](history.md) · [구현 리뷰](../../audits/2026-10-03-implementation-review.md)

```bash
cd packages/features/walk && flutter test test/data/tracker
cd packages/features/walk && flutter test test/presentation/cubit/active_walk_cubit_test.dart test/presentation/format
cd packages/features/walk && flutter test test/presentation/page/active_walk_page_test.dart
```

W2 몫은 추적기 12 · cubit 11 · 포맷 7 · 페이지 9 = 39건이다(2026-10-03, `93d722b` 기준). 추적
도메인(정책 4 · `StartWalkScenario` 3 · `DiscardWalkScenario` 1)은 ① 의 `test/domain/` 이 덮는다.
GPS · 지도 타일은 실제로 부르지 않는다 — `LocationGateway` mock 과 stub `TileProvider` 를 쓴다.

## `test/data/tracker/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `geolocator_walk_tracker_test.dart` (12) | `GeolocatorWalkTracker` (`LocationGateway` mock) | 서비스 꺼짐 → `locationServiceDisabled` · 권한 거부 → `locationPermissionDenied` 이고 **같은 세션에 다시 묻지 않는다**(요청 1회) · 영구 거부는 요청 없음 · 시작하면 빈 `tracking` · 플랫폼별 설정(`debugDefaultTargetPlatformOverride` 로 Android 알림 문구 · `distanceFilter`, iOS `fitness` · 자동 일시정지 끔) · 위치가 들어오면 점 · 거리 누적 · 정책이 버린 점은 쌓이지 않음 · 추적 중 `start` 거부 · `stop` 은 `endedAt` 을 채운 `finished` 와 구독 해제 · 비추적 `stop` → `walkNotFound` · `clear` 는 `finished` 에서만 `idle` · 스트림 오류에도 `tracking` 유지 |

## `test/presentation/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `cubit/active_walk_cubit_test.dart` (11) | `ActiveWalkCubit` | 반려견 목록 → 전부 선택된 `selectingDogs` · 0마리 → 빈 `selectingDogs` 이고 시작하지 않음 · 추적 중 재진입 → `getDogs` 없이 `tracking` · `finished` 재진입 → `stopped` · `toggleDog` 넣고 빼기 · 시작 성공 → 선택한 반려견으로 `startWalk`, `starting` 뒤 `tracking` · 권한 거부 → 선택 유지 `failure`, 재시도는 같은 알림 문구 · 반려견 조회 실패의 재시도는 다시 읽기 · `stop` 성공은 `stopped` 한 번(구독이 먼저 `finished` 를 줘도) · `stop` 실패 → `failure`, 재시도는 추적 상태를 다시 읽기 · **`fakeAsync` 로 1 · 2 · 3초 `elapsed` 재계산, `close` 뒤 정지** |
| `format/walk_format_test.dart` (7) | `WalkFormat` | `999 m` · `850 m` · `1.0 km` · `1.3 km` · 999.6 m → `1.0 km` 경계, `59분` · `1시간 5분`, `07:05` · `1:02:03` |
| `page/active_walk_page_test.dart` (9) | `ActiveWalkPage` | 칩을 모두 해제하면 시작 버튼 비활성 · 시작하면 선택한 반려견과 알림 문구로 `startWalk` · 추적 중 지도 · 경과 시간 · 거리 · 점이 없으면 "위치를 찾는 중…" · 종료 확인 → `stopWalk` 후 `onStopped` 한 번 · 취소면 둘 다 없음 · 저장 안 된 종료 세션으로 들어오면 곧바로 `onStopped` · 권한 거부 → 안내 + 재시도 → `startWalk` 다시 · 0마리 → 등록 안내 → `onOpenDogs` |

계획 테스트 표의 14줄은 모두 위 파일에 있다. `RouteMap` · `WalkStatsRow` · `DogChips` 는 따로
테스트 파일이 없고 페이지 테스트가 지난다.

## 알아둘 것

- 페이지 테스트는 `getIt` 에 `ActiveWalkCubit.withClock(useCase, () => now)` factory 와
  `StubTileProvider`(1×1 투명 PNG 를 메모리에서 준다)를 등록하고, `tearDown` 에서 스트림을 닫은 뒤
  `getIt.reset()` 한다. `RouteMap` 이 `tileProvider ?? getIt<TileProvider>()` 라 네트워크를 타지 않는다
- 추적 화면은 1초 주기 타이머가 남는다. 테스트 끝에서 `tester.pumpWidget(const SizedBox())` 로
  페이지를 내려 cubit 을 닫아야 "타이머가 남았다" 실패가 나지 않는다
- 타이머 테스트는 `fake_async`(dev 의존)의 `fakeAsync` + `async.getClock(t0)` 로 시계와 타이머를
  함께 돌린다. "틱을 누적하지 않는다" 를 실제로 검증하는 유일한 곳이다
- `trackerStates` 는 테스트가 만든 `StreamController.broadcast()` 이고, `trackerState` 는 바꿀 수 있는
  `current` 변수를 돌려준다 — 재진입은 `current` 만 바꿔 흉내 낸다
- `pumpApp` 은 `Locale('ko')` 를 고정한다. `ko` 가 ARB 템플릿이라 원문이 곧 기대값이다
- 위 표는 `93d722b` 기준이다. `d5f95b0` 의 V2 수정으로 stub 이 `getDogs` 에서 `watchDogs`(`Stream.value`)로
  바뀌었고, cubit 에 "반려견을 등록하고 돌아오면 목록이 갱신된다" 1건이 더해져 cubit 은 12건이다

## mock 으로 확인되지 않는 것

- **포그라운드 서비스와 백그라운드 수신** — `AndroidSettings` 객체가 맞게 만들어지는지만 본다.
  화면이 꺼지거나 앱이 백그라운드일 때 점이 실제로 들어오는지는 기기에서만 드러난다
- **실제 정확도 · 간격** — `best` + 2초가 배터리 · 경로 품질에서 맞는지는 GPX 재생으로 고른다
- **OSM 타일 · 카메라 추종** — stub 타일이라 줌 · 이동 · 출처 표기는 보이지 않는다

## 에뮬레이터

계획 완료 조건과 [기획서](../../overview.md) §8 에뮬레이터 검증 시나리오 ②③⑦ 의
W2 몫이다. **미실행** — 이 환경에 Android SDK 가 없다.

| # | 시나리오 | 결과 |
|---|---|---|
| ① | Extended Controls 로 GPX 재생 → 폴리라인 · 거리 · 경과 시간이 자란다 | 미실행 |
| ② | 추적 중 뒤로 가기 → 다시 `/walk` → 같은 세션이 이어진다 | 미실행 |
| ③ | 홈 버튼으로 30초 백그라운드 → 돌아오면 그동안의 점이 쌓여 있다(Android 13+ 는 알림이 안 보일 수 있다) | 미실행 |
| ④ | 위치 권한 거부 · 서비스 꺼짐 → `AppPlaceholder` + 재시도, 같은 세션엔 다시 묻지 않는다 | 미실행 |
| ⑤ | 종료 확인 → `onStopped` → `/walk/save`, 저장 폼에서 뒤로 가기가 앱을 닫지 않는다(V1) | 미실행 |
| ⑥ | Android `accuracy` · 간격, OSM 출처 표기, 추종 · 줌 | 미실행 |
