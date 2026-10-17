# W4 feed — 테스트

> [테스트 가이드](../../../../../docs/testing/README.md) · [pawlog 허브](../../README.md) · [계획](plan.md) · [구현 기록](history.md) · [구현 리뷰](../../audits/2026-10-03-implementation-review.md)

```bash
cd apps/pawlog && flutter test test/presentation/feed/cubit
cd apps/pawlog && flutter test test/presentation/feed/page test/presentation/feed/widget
cd apps/pawlog && flutter test test/data/walk/drift_walk_repository_test.dart   # 최신순 · 이름 변경이 watch 에 흐름
```

W4 몫은 cubit 7 · 페이지 10 · `RoutePreviewPainter` 4 = 21건이다(2026-10-03, `d5f95b0` 기준). 같은
커밋의 ⑤ V2 테스트 1건은 [tracking 테스트](../tracking/testing.md) 몫이다. 피드가 읽기만 하는
`watchWalks` 의 정렬 · join · 강아지 이름 변경 반영은 ② 의 `drift_walk_repository_test.dart` 가 덮는다.

## `test/presentation/feed/cubit/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `walk_feed_cubit_test.dart` (7) | `WalkFeedCubit` | 스트림이 2건 → 1건을 내면 `loading` → `loaded([2건], idle)` → `loaded([1건], idle)` · 시작 시 `trackerState` 가 `tracking` 이면 첫 `loaded` 부터 `tracking` · `trackerStates` 가 `finished` 를 내면 `loaded(walks, finished)` 로 갱신 · **목록 전에 온 `tracker` 변화는 `loading` 을 유지하고 첫 `loaded` 에 반영** · 스트림 `Err` → `failure` · `retry()` → `failure` → `loading` → `loaded`, `watchWalks` 2회 · 닫힌 뒤 온 값은 상태를 내지 않고 두 구독 모두 해제(`hasListener == false`) |

## `test/presentation/feed/page/` · `widget/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `page/walk_feed_page_test.dart` (10 → 12) | `WalkFeedPage` | 0건 → `AppPlaceholder`("첫 산책을 시작해 보세요") + 시작 버튼 → `onStartWalk`, FAB 없음 · 카드에 `DogAvatars` · 날짜(`2026.10.03 09:00`) · `1.2 km` · `30분` · 메모 · 메모가 없으면 메모 줄 없음 · 카드 탭 → `onOpenWalk('a')` · 사진이 없으면 `Image` 없음, 있으면 `Image` 1개 · `idle` FAB "산책 시작" → `onStartWalk`, 배너 없음 · `tracking` → 배너 + "산책 계속" FAB, 둘 다 `onStartWalk` · `finished` → 저장 안 함 배너 → `onSaveWalk`, FAB 없음, `onStartWalk` 0회 · 앱바 → `onOpenDogs` · 실패 → `walk-feed-retry` → 다시 구독해 카드 · (2026-10-04 QA) 0건이라도 `tracking` · `finished` 면 시작 안내 · 버튼 없이 "첫 산책이 곧 여기에 보여요" + 배너 |
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
- **앱 라우터 연결** — 페이지를 라우터 없이 띄우므로 카드 탭 → `/walks/:id` 가 상세를 여는지,
  `/walks` 가 피드로 가는지(⑥ W1 수정)는 모른다. `apps/pawlog/test/core/router/` 에 `createRouter`
  테스트가 아직 없다
- **실제 drift 스트림** — 저장 · 수정 · 삭제 · 강아지 이름 변경이 피드에 흐르는 것은 레포 테스트(메모리 DB)와
  에뮬레이터로만 본다
- **썸네일 디코드 · 다크 모드** — 실제 사진과 테마별 선 색은 기기에서 본다

## 에뮬레이터

계획 완료 조건과 [기획서](../../overview.md) §8 에뮬레이터 검증 시나리오 ①④⑤⑧ 의 W4 몫이다.
**2026-10-04 실행** — Android 17 에뮬레이터(`Medium_Phone`), 위치는 `adb emu geo fix` 로 경로를 흘렸다. 고친 것은 [구현 기록](history.md)의 "2026-10-04 — 에뮬레이터 QA" 에 있다.

| # | 시나리오 | 결과 |
|---|---|---|
| ① | 빈 피드(`AppPlaceholder` + 시작) → 산책 저장 → 카드가 맨 위에 생긴다 | **PASS** — 단 추적 중에도 빈 피드의 시작 안내가 함께 보여 고쳤다(`af4cf22`) |
| ② | 카드 → 상세(⑥ W1 수정 확인) → 삭제 → 피드에서 새로고침 없이 사라진다 | **PASS** |
| ③ | 강아지 이름 · 사진 변경이 카드에 반영된다 | **PASS**(2026-10-17) — 카메라로 찍은 사진 · "Kong" → "Kongi" 가 저장 직후 카드에 보인다 |
| ④ | 추적 중 배너 · "산책 계속" FAB → `/walk`, 종료 후 저장 전이면 "저장하지 않은 산책" 배너 → `/walk/save`, FAB 없음 | **PASS**(2026-10-17) — 산책 1건이 있는 상태에서 추적 중 배너 + "Continue walk" → 진행 화면, 종료 뒤 저장 전(강제 종료 후 재실행)이면 "You have an unsaved walk" 배너 → 저장 폼, 시작 버튼 없음 |
| ⑤ | 사진 있는 카드는 첫 사진, 없는 카드는 경로 썸네일. 다크 모드에서 선이 보인다 | **PASS** — 사진 썸네일 · 다크 모드 확인 |
| ⑥ | `/walks` 로 가면 피드, 앱 완전 종료 후 재실행해도 카드가 남아 있다 | **일부**(2026-10-17) — 강제 종료 뒤 카드가 남는다 PASS. `/walks` 는 화면에서 갈 길이 없어 [라우터 테스트](../../../test/core/router/app_router_test.dart)로만 |

## 2026-10-17 — 다듬기

| 파일 | 추가 | 확인 |
|---|---|---|
| `test/presentation/feed/page/walk_feed_page_test.dart` | 2 | 즐겨찾기 별이 합친 라벨에 "즐겨찾기" 로 읽힌다(`bySemanticsLabel`) · 목록 실패 중 더보기에 `walk-feed-favorites-toggle` 없음(백업 항목은 있음) |

## 2026-10-17 — 페이지네이션

```bash
cd apps/pawlog && flutter test test/data/walk/drift_walk_repository_test.dart test/presentation/feed
```

| 파일 | 추가 | 확인 |
|---|---|---|
| `test/data/walk/drift_walk_repository_test.dart` | 5 | 반려견 2 · 사진 2 인 산책 5개에서 `watchRecent(limit: 3)` 은 정확히 3개를 최신순으로, 반려견 · 사진을 모두 싣고 · `favoritesOnly` 는 즐겨찾기만 limit 까지 · 같은 시각이면 id 내림차순 · 더 최근 산책을 넣으면 그 산책을 맨 앞에 두고 다시 흐름 · `watchStartedSince(from)` 은 from 과 같거나 뒤에 시작한 것만 |
| `test/presentation/feed/cubit/walk_feed_cubit_test.dart` | 12 (14 → 26) | 첫 구독 limit 30, 30개가 오면 `hasMore` · `loadMore` → limit 60 으로 다시 구독, 값이 올 때까지 `isLoadingMore`(읽는 중 두 번째 `loadMore` 는 무시) · limit 보다 적게 오면 `hasMore` false, `loadMore` 는 다시 구독하지 않음 · loaded 전 `loadMore` 무시 · 즐겨찾기 켜면 읽은 목록을 바로 즐겨찾기만 거른 상태(`hasMore` false)를 내고 limit 30 · `favoritesOnly: true` 로 다시 구독(60 까지 읽은 뒤에도), 켠 직후 새 값 전 `loadMore` 무시, 끄면 전체 30 으로 다시 · `loadMore` 뒤 `retry` 는 limit 30 으로 · `loadMore` 뒤 이전 구독이 늦게 낸 값은 무시(컨트롤러 둘, 이전 것 `hasListener` false) · 요약 스트림 `Err` 는 지난 요약 유지 · 이번 주 31개 · 페이지 30개면 요약은 31 · 요약 스트림이 목록 뒤에 와도 요약 갱신 · `refreshWeekSummary` 는 주가 바뀌면 새 주 시작으로 다시 구독, 같은 주면 구독하지 않음 |
| `test/presentation/feed/page/walk_feed_page_test.dart` | 2 | 처음엔 `AppListFooter` 없음 · 30개를 끝까지 내리면 `watchRecentWalks(limit: 60)` 을 부르고 끝에 로딩 스피너, 값이 오면 footer 도 "모두 확인했습니다" 도 없음 · 10개면 끝까지 내려도 다시 구독하지 않고 끝 안내 없음 |
| `test/core/router/app_router_test.dart` | 0 | 피드가 새 유스케이스 호출(`watchRecentWalks` · `watchWalksSince`)을 쓰도록 stub 만 더함 |

- 기존 cubit · 페이지 테스트는 `watchWalks` 대신 `watchRecentWalks` · `watchWalksSince` 를 stub 한다.
  페이지 테스트의 목록 stub 은 저장소처럼 즐겨찾기 · limit 을 적용해, 즐겨찾기 화면 테스트가 그대로 지난다
- mocktail `any()` 로 `DateTime` 을 받으려고 `registerFallbackValue(DateTime(2000))` 을 둔다
- 페이지 테스트의 끝까지 내리기는 마지막 항목 키로 `scrollUntilVisible` 한 뒤 조금 더 끈다 — 큰 `drag` 한 번은
  지연 레이아웃의 예상 길이에 막혀 끝까지 가지 않았다. 없음 단언은 `skipOffstage: false` 로 화면 밖까지 본다
- 실제 drift 의 `isInQuery` 부분 쿼리 · watch 재방출은 레포 테스트(메모리 DB)가 덮는다. 스크롤 체감 ·
  끝 안내의 모양은 에뮬레이터에서 보지 않았다
