# W4 feed — 테스트

> [테스트 가이드](../../../../../docs/testing/README.md) · [pawlog 허브](../../README.md) · [계획](plan.md) · [구현 기록](history.md) · [구현 리뷰](../../audits/2026-10-03-implementation-review.md)

```bash
cd packages/features/walk && flutter test test/presentation/cubit/walk_feed_cubit_test.dart
cd packages/features/walk && flutter test test/presentation/page/walk_feed_page_test.dart test/presentation/widget/route_preview_painter_test.dart
cd packages/features/walk && flutter test test/data/repository/drift_walk_repository_test.dart   # 최신순 · 이름 변경이 watch 에 흐름
```

W4 몫은 cubit 7 · 페이지 10 · `RoutePreviewPainter` 4 = 21건이다(2026-10-03, `d5f95b0` 기준). 같은
커밋의 ⑤ V2 테스트 1건은 [tracking 테스트](../tracking/testing.md) 몫이다. 피드가 읽기만 하는
`watchWalks` 의 정렬 · join · 강아지 이름 변경 반영은 ② 의 `drift_walk_repository_test.dart` 가 덮는다.

## `test/presentation/cubit/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `walk_feed_cubit_test.dart` (7) | `WalkFeedCubit` | 스트림이 2건 → 1건을 내면 `loading` → `loaded([2건], idle)` → `loaded([1건], idle)` · 시작 시 `trackerState` 가 `tracking` 이면 첫 `loaded` 부터 `tracking` · `trackerStates` 가 `finished` 를 내면 `loaded(walks, finished)` 로 갱신 · **목록 전에 온 `tracker` 변화는 `loading` 을 유지하고 첫 `loaded` 에 반영** · 스트림 `Err` → `failure` · `retry()` → `failure` → `loading` → `loaded`, `watchWalks` 2회 · 닫힌 뒤 온 값은 상태를 내지 않고 두 구독 모두 해제(`hasListener == false`) |

## `test/presentation/page/` · `widget/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `page/walk_feed_page_test.dart` (10) | `WalkFeedPage` | 0건 → `AppPlaceholder`("첫 산책을 시작해 보세요") + 시작 버튼 → `onStartWalk`, FAB 없음 · 카드에 `DogAvatars` · 날짜(`2026.10.03 09:00`) · `1.2 km` · `30분` · 메모 · 메모가 없으면 메모 줄 없음 · 카드 탭 → `onOpenWalk('a')` · 사진이 없으면 `Image` 없음, 있으면 `Image` 1개 · `idle` FAB "산책 시작" → `onStartWalk`, 배너 없음 · `tracking` → 배너 + "산책 계속" FAB, 둘 다 `onStartWalk` · `finished` → 저장 안 함 배너 → `onSaveWalk`, FAB 없음, `onStartWalk` 0회 · 앱바 → `onOpenDogs` · 실패 → `walk-feed-retry` → 다시 구독해 카드 |
| `widget/route_preview_painter_test.dart` (4) | `RoutePreviewPainter` | 점 0개 → `paintsNothing` · 여러 점 → 주어진 색의 `path` · 1점 → 예외 없이 `circle` · `shouldRepaint` 는 색 · 점 목록이 다를 때만 `true` |

계획 테스트 표의 13줄은 모두 위 파일에 있다. 단 "사진 있음 / 없음" 은 `Image` 의 유무만 보고
`CustomPaint` 를 직접 찾지 않는다. `WalkCard` · `ActiveWalkBanner` 는 따로 테스트 파일이 없고 페이지
테스트가 지난다.

## 알아둘 것

- 페이지 테스트는 `getIt` 에 `WalkFeedCubit(mock WalkUseCase)` factory 를 등록하고 `tearDown(getIt.reset)`
- `trackerStates` 는 페이지에서 `Stream.empty()`, cubit 에서 `StreamController.broadcast()` 다.
  `trackerState` 는 바꿀 수 있는 `current` 변수를 돌려줘 시작 시점의 추적 상태를 흉내 낸다
- `photoFile` 은 없는 경로 `File('missing.png')` 를 돌려준다 — 디코드는 검증하지 않는다
- 같은 테스트 안에서 스트림을 바꾸려면 `tester.pumpWidget(const SizedBox())` 로 페이지를 내리고
  다시 띄운다(새 cubit 이 새 `watchWalks` 를 부른다)
- cubit 의 `retry()` 는 이전 구독의 `cancel` 을 기다리지 않는다 — 가짜 비동기에서 끝난 스트림의
  `cancel` 을 기다리면 테스트가 멈췄다([구현 기록](history.md))
- `RoutePreviewPainter` 는 `paints` 매처(`flutter_test`)로 `RenderObject` 의 그리기 호출을 본다
- `pumpApp` 은 `Locale('ko')` 를 고정한다

## mock 으로 확인되지 않는 것

- **`errorBuilder` 폴백** — 사진 파일이 깨졌을 때 경로 썸네일로 바뀌는지는 단언하지 않는다
- **빈 피드 + `finished`** — 시작 버튼이 숨는 분기는 테스트가 없다
- **앱 라우터 연결** — 페이지를 라우터 없이 띄우므로 카드 탭 → `/walks/:id` 가 상세를 여는지,
  `/walks` 가 피드로 가는지(⑥ W1 수정)는 모른다. `apps/pawlog/test/app/router/` 에 `createRouter`
  테스트가 아직 없다
- **실제 drift 스트림** — 저장 · 수정 · 삭제 · 강아지 이름 변경이 피드에 흐르는 것은 레포 테스트(메모리 DB)와
  에뮬레이터로만 본다
- **썸네일 디코드 · 다크 모드** — 실제 사진과 테마별 선 색은 기기에서 본다

## 에뮬레이터

계획 완료 조건과 [기획서](../../overview.md) §8 에뮬레이터 검증 시나리오 ①④⑤⑧ 의 W4 몫이다.
**미실행** — 이 환경에 Android SDK 가 없다.

| # | 시나리오 | 결과 |
|---|---|---|
| ① | 빈 피드(`AppPlaceholder` + 시작) → 산책 저장 → 카드가 맨 위에 생긴다 | 미실행 |
| ② | 카드 → 상세(⑥ W1 수정 확인) → 삭제 → 피드에서 새로고침 없이 사라진다 | 미실행 |
| ③ | 강아지 이름 · 사진 변경이 카드에 반영된다 | 미실행 |
| ④ | 추적 중 배너 · "산책 계속" FAB → `/walk`, 종료 후 저장 전이면 "저장하지 않은 산책" 배너 → `/walk/save`, FAB 없음 | 미실행 |
| ⑤ | 사진 있는 카드는 첫 사진, 없는 카드는 경로 썸네일. 다크 모드에서 선이 보인다 | 미실행 |
| ⑥ | `/walks` 로 가면 피드, 앱 완전 종료 후 재실행해도 카드가 남아 있다 | 미실행 |
