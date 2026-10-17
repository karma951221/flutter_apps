# W4 feed — 구현 기록

> [pawlog 허브](../../README.md) · [계획](plan.md) · [테스트](testing.md) · [구현 리뷰](../../audits/2026-10-03-implementation-review.md)

설계 판단 · 리뷰에서 고친 것 · 검증 결과를 남긴다. 진행 상태는 [진행 현황](../../status.md)에만 적는다.
구현 커밋은 `d5f95b0`(단계 ⑦)이고, 같은 커밋에 리뷰 ⑥ W1(`/walks` 리다이렉트)과 ⑤ V2(진행 화면의
반려견 갱신) 수정이 함께 들어 있다. 소견 번호는 [W3 기록](../record/history.md)처럼 "⑥ W1" 로 단계를 붙여 쓴다.

## 2026-10-03 — 설계 판단

### 상태는 `loaded(walks, tracker)` — bool 이 아니다

설계 §4 의 `loaded(walks, isTracking)` 로는 "추적 중" 과 "끝났지만 저장 안 함(`finished`)" 을
가를 수 없다. 둘은 배너 문구도, 가는 곳도 다르다. 그래서 `TrackerState` 를 그대로 든다
(`WalkFeedState.loaded({walks, tracker})`). 페이지는 `switch (tracker)` 로 배너를 고른다.

### 구독을 먼저 걸고 현재값은 그다음

`start()` 는 `trackerStates` 구독을 먼저 걸고 `trackerState` 를 읽은 뒤 `watchWalks()` 를
구독한다. 계획은 "현재값을 먼저 읽는다" 였지만 W2 `ActiveWalkCubit` 과 같은 이유로 순서를 바꿨다 —
`trackerStates` 는 브로드캐스트라 현재값을 내지 않아, 읽는 사이에 온 변화를 놓치지 않으려면
구독이 먼저다([tracking 기록](../tracking/history.md)).

목록이 오기 전에 온 `tracker` 변화는 보관만 하고 `loading` 을 유지한다. 첫 `walks` 가 오면 그때의
`tracker` 로 `loaded` 를 낸다. `failure` 중에 온 `tracker` 도 보관만 한다.

### `finished` 는 저장 안 함 배너 + FAB 없음

| `tracker` | 배너 | FAB |
|---|---|---|
| `idle` | 없음 | `walkStart` → `onStartWalk` |
| `tracking` | `walkInProgressBanner` + `WalkStatsRow` → `onStartWalk` | `walkContinue` → `onStartWalk` |
| `finished` | `walkUnsavedBanner` → `onSaveWalk` | **없음** |

저장 · 버리기 전에 새 산책을 시작하면 `finished` 세션이 덮인다(리뷰 열린 질문 1). W2 는 `/walk`
진입에서 `finished` 를 저장 폼으로 돌리고, 피드는 시작 버튼 자체를 없애 같은 규칙을 화면 수준에서
지킨다 — 추적기는 바꾸지 않았다. 배너는 `onStartWalk` 를 거치지 않고 `onSaveWalk` 로 바로 간다.
진행 화면이 잠깐 비쳤다 사라지지 않게 하려는 것이다(계획에서 더한 콜백).

### 빈 피드에서도 `finished` 면 시작 버튼을 숨긴다

0건이면 FAB 대신 `AppPlaceholder` 의 행동 버튼이 시작 버튼이다. `finished` 일 때는 이 버튼도
`onAction: null` 로 감춰 안내 문구만 남긴다 — 첫 산책을 끝내고 저장하지 않은 채 피드로 온 경우다.
위의 배너가 저장 폼으로 데려간다.

### 카드의 통계는 `Text` 한 줄 — `WalkStatsRow` 가 아니다

계획은 "`WalkStatsRow` 압축형" 이었지만 `WalkStatsRow` 는 진행 화면용이라 시간을 `clock`(`30:00`)
으로 보이고 라벨 · 값 두 줄이다. 카드에는 `WalkFormat.distance` · `WalkFormat.duration` 을 이은
`Text`(`1.2 km · 30분`) 하나를 둔다. W2 계획이 `duration` 을 "W3 · W4 카드용" 으로 만든 의도대로다.
배너의 추적 중 통계만 `WalkStatsRow` 를 쓴다.

### 썸네일 — 첫 사진, 없거나 깨지면 경로

`photos` 가 있으면 `Image.file(photoFile(first), cacheWidth: 88 × devicePixelRatio)`, 파일을 못
읽으면 `errorBuilder` 가 경로 썸네일로 바꾼다. 사진이 없으면 처음부터 경로 썸네일이다. 경로는
`previewPoints` 가 2점 미만이면 `Icons.pets_outlined` 만, 그 이상이면 `RoutePreviewPainter` 다.
⑥ W4 가 지적한 `cacheWidth` 고정값 문제를 피드에서는 기기 배율로 풀었다.

`RoutePreviewPainter` 는 타일 없이 점들의 경계 상자를 비율을 유지한 채 `AppSpacing.sm` 안쪽에
맞추고 폴리라인만 그린다. 한 점 · 한 직선이어도 0 으로 나누지 않고, 1점이면 원 하나를 그린다
(카드는 2점 미만에서 아이콘을 쓰므로 방어용이다). 색은 `colorScheme.primary` 라 다크 모드에서도
테마를 따른다.

### 카드 바탕은 Material `Card` + `InkWell`

`design_system` 에 썸네일 큰 카드 위젯이 없고 `AppListTile` 은 이 모양을 담지 못한다. 쓰는 곳이
피드 하나라 승격하지 않았다(계획대로). 모서리 `AppRadius.lgAll` · 썸네일 `AppRadius.smAll`, 여백은
`AppSpacing`. FAB 도 공통 위젯이 없어 W1 목록과 같이 `FloatingActionButton.extended` 를 쓴다.

### 재시도는 끝난 구독의 `cancel` 을 기다리지 않는다

`retry()` 는 산책 구독만 끊고 다시 건다(추적 구독은 그대로). 이때 이전 구독의 `cancel()` 을
`unawaited` 로 둔다 — 위젯 테스트의 가짜 비동기에서 이미 끝난 스트림의 `cancel` 을 기다리면
멈췄다. `close()` 는 두 구독을 모두 기다려 끊는다.

### 배너의 경과 시간은 타이머 없이

배너는 `session.elapsedAt(DateTime.now())` 를 빌드 때 계산한다. 피드에는 1초 타이머가 없어,
새 점이 와서 `trackerStates` 가 상태를 바꿀 때 거리와 함께 바뀐다(계획대로). 시계 주입은 하지
않았다 — 진행 화면과 달리 시각 단언이 필요 없다.

### 라우터 — `/` 가 실제 피드, `/walks` 리다이렉트 수정

`/` 의 `_Placeholder` 와 임시 "dogs" 버튼을 지우고 `WalkFeedPage` 를 연결했다. 이제 8 경로가 모두
실제 페이지다. `onStartWalk` · `onSaveWalk` · `onOpenWalk` · `onOpenDogs` 는 모두 `push` 라 뒤로 가면 피드다.

`/walks` 부모의 route-level `redirect` 는 ⑥ 에서 `state.matchedLocation` 을 비교해 자식
(`/walks/:id` · `/walks/:id/edit`)까지 피드로 돌렸다(⑥ W1). 부모 redirect 안에서 `matchedLocation`
은 자식으로 가는 중에도 부모 자신의 위치이기 때문이다. 실제 요청 경로인 `state.uri.path` 가
정확히 `/walks` 일 때만 돌리도록 고쳤다.

### ⑤ V2 — 진행 화면은 반려견을 구독한다

`ActiveWalkCubit` 이 `getDogs()` 한 번 대신 `watchDogs()` 를 구독한다. 0마리 안내에서 반려견을
등록하고 돌아오면 목록이 저절로 바뀐다. 새로 생긴 반려견은 선택된 채로 들어오고, 사용자가 해제한
반려견은 해제된 채 남는다. 시작 · `tracking` 진입 · `stopped` · `close()` 에서 구독을 끊는다.
W4 와 같은 커밋이지만 W2 몫이다([tracking 기록](../tracking/history.md)).

## 리뷰에서 고친 것

| id | 내용 | 커밋 |
|---|---|---|
| ⑥ W1 | `/walks` redirect 를 `state.uri.path == /walks` 비교로 — 상세 · 수정이 다시 열린다 | `d5f95b0` |
| ⑤ V2 | `ActiveWalkCubit` 이 `watchDogs()` 를 구독해 반려견 등록 뒤 돌아오면 갱신 | `d5f95b0` |
| 열린 질문 1 | 피드 FAB · 빈 상태 시작 버튼을 `finished` 에서 숨기고 배너로 저장 폼에 보낸다(⑤ "다음 단계" 표) | `d5f95b0` |
| ⑥ W4 (피드 몫) | 썸네일 `cacheWidth` 를 기기 배율로 | `d5f95b0` |

## 고치지 않았지만 적어 둘 것

- **⑥ W1 수정의 라우터 테스트는 `b4abf9c` 에서 추가했다** — `createRouter` 를 실제로 띄워
  `/walks/:id` 상세 · `/walks/:id/edit` 수정 · `/walks` → 피드 · 첫 실행 `/dogs/new` 4건.
  경로 썸네일의 동서 늘어남(⑦ F1)은 `a6fc098` 에서 cos(위도) 보정으로 고쳤다.
  `createRouter` 로 `/walks/w1` 이 상세를, `/walks` 가 피드를 그리는지 보는 테스트가 필요하다. 고친
  방식은 리뷰어가 ⑥ 에서 제안한 그대로지만 이 저장소 안에서 실행으로 확인한 것은 아니다
- **`errorBuilder` 폴백은 테스트하지 않았다** — 페이지 테스트의 `photoFile` 은 없는 파일을 돌려주지만
  `Image` 위젯이 있는지만 보고, 디코드 실패 뒤 경로 썸네일로 바뀌는지는 단언하지 않는다. 계획의
  "임시 디렉터리의 작은 PNG" 도 쓰지 않았다
- **빈 피드 + `finished` 의 시작 버튼 숨김**도 테스트가 없다(배너 · FAB 없음은 1건 이상일 때만 본다)
- `WalkFormat.duration` 의 경계(⑤ I2) — 정확히 60분이면 `1시간 0분`, 1분 미만이면 `0분`. 카드에
  그대로 보인다
- 썸네일 크기 `88.0` · 목록 아래 여백 `AppSpacing.xl * 3` · 선 굵기 `3.0` 은 크기 수치다(④ T3 · ⑥ W4 와 같은 결)
- 다크 모드에서 경로 선이 보이는지는 `colorScheme.primary` 를 쓴다는 것까지만 — 화면 확인은 에뮬레이터 몫
- **범위 밖**: 페이지네이션(v1 전체 로드, `Walk` 에 전체 경로가 없어 가볍다), 날짜별 묶음 머리글,
  강아지별 필터 · 검색, 통계 대시보드, 당겨서 새로고침(스트림이라 필요 없음) — [계획 — 범위 밖](plan.md#범위-밖)

## 2026-10-04 — 에뮬레이터 QA

Android 17 에뮬레이터(`Medium_Phone`)에서 [테스트](testing.md#에뮬레이터)의 시나리오를 돌리며 찾은 것을 고쳤다.

### 산책 중 빈 피드의 시작 안내 (`af4cf22`)

"빈 피드에서도 `finished` 면 시작 버튼을 숨긴다" 는 `tracking` 을 빠뜨렸다. 저장된 산책이 없을 때
추적 중이면 배너 아래에 "첫 산책을 시작해 보세요 / 산책 시작" 이 함께 보였다. 눌러도 두 번째 세션이
생기지는 않는다 — 진행 화면이 추적기 상태를 보고 진행 중 산책으로 들어가고 `StartWalkScenario` 도
거부한다. 그래도 문구가 상황과 맞지 않아, 추적기가 `idle` 이 아니면 시작 버튼 없이 "첫 산책이 곧
여기에 보여요 / 위 배너에서 산책을 마치고 저장해 주세요"(ARB 3개에 2키)만 둔다. 페이지 테스트 2건.

## 검증

- `d5f95b0` 스냅숏에서 `feature_walk` `flutter analyze` 0건 · `flutter test` `+172`(⑦ 몫 22건 —
  피드 cubit 7 · 피드 페이지 10 · `RoutePreviewPainter` 4 · `ActiveWalkCubit` V2 1), `apps/pawlog` `+5`,
  `l10n` `+10`, `design_system` `+42`, 모두 analyze 0건
- **에뮬레이터 확인은 아직 하지 않았다 (이 환경에 Android SDK 없음).** 빈 피드 → 저장 → 카드,
  카드 → 상세 → 삭제, 배너 두 종류, 다크 모드 썸네일은 [테스트](testing.md#에뮬레이터)에 미실행으로
  남겼다. iOS 도 빌드하지 않았다

## 2026-10-17 — 다듬기

W10 최종 리뷰에서 넘긴 것([favorites](../favorites/history.md#넘기는-것-최종-리뷰-minor))을 닫았다.

- 피드 항목의 즐겨찾기 별에 스크린리더 라벨 `walkFavoriteLabel`("즐겨찾기" · Favorite · お気に入り)을 단다.
  항목 전체가 `InkWell` 하나로 합쳐 읽히므로 합친 라벨 안에 들어간다
- 목록을 못 불러온 동안(`WalkFeedFailure`)에는 더보기 메뉴에 즐겨찾기 토글을 두지 않는다 — 거를 목록이
  없고, 필터가 켜져 있어도 문구가 "즐겨찾기만 보기" 로 돌아가 틀린 말을 했다. `WalkFeedLoaded` 에서만 보인다
- 페이지 테스트 2건(별 라벨 · 실패 중 메뉴)

## 2026-10-17 — 페이지네이션

피드가 `watchWalks()` 로 모든 산책을 반려견 · 사진과 조인해 읽던 것을 최근 30개씩 나눠 읽는다.
통계 · 백업 · 진행 중 산책은 그대로 `watchWalks()`(전체)를 쓴다.

### 저장소 — 산책 수로 자른 뒤 조인

- `WalkRepository.watchRecent({limit, favoritesOnly})` — 조인하면 산책 하나가 (반려견 × 사진) 행으로
  늘어나 `LIMIT` 이 행을 센다. 그래서 같은 순서(`started_at` 내림차순, 같으면 `id` 내림차순)로 산책 id 만
  `LIMIT` 으로 고르는 부분 쿼리를 만들고 `walks.id.isInQuery(...)` 로 그 id 들만 조인한다. 쿼리 하나라
  drift `watch()` 가 walks · walk_dogs · dogs · walk_photos 변경에 다시 흐른다
- `favoritesOnly` 는 부분 쿼리에 `is_favorite = 1` 을 건다 — 즐겨찾기만 세어 자른다. 화면은 더 이상
  목록을 걸러 그리지 않는다
- `WalkRepository.watchStartedSince(from)` — `started_at >= from` 인 산책을 조인해 낸다. 한 주 분량이라
  조인 비용은 작고, 요약 계산은 그대로 `WalkStatsPolicy` 한 곳에 둔다(저장소에 합계 SQL 을 두지 않았다)
- 유스케이스는 `watchRecentWalks` · `watchWalksSince` 로 그대로 넘긴다(시나리오 없음)

### cubit — 커서가 아니라 늘어나는 `limit`

- `WalkFeedCubit.pageSize = 30`. `limit` 은 30 에서 시작하고 `loadMore()` 가 한 페이지씩 올려 다시
  구독한다. 로컬 drift 라 커서(`CursorPage`)보다 "최근 N개 watch" 가 단순하고, 이미 읽은 페이지에 생긴
  수정 · 삭제 · 새 산책도 같은 스트림으로 흐른다
- `hasMore = 받은 수 == limit`. 딱 limit 개만 있으면 한 번 더 읽어 끝을 안다
- `loaded` 에 `hasMore` · `isLoadingMore`(둘 다 `@Default(false)`). `loadMore()` 는 loaded 가 아니거나
  읽는 중이거나 `hasMore` 가 false 면 아무것도 하지 않는다 — `AppLoadMoreListener` 가 스크롤마다 불러도 된다
- 즐겨찾기 토글은 `limit` 을 한 페이지로 되돌리고 `favoritesOnly` 로 다시 구독한다. `loading` 을 내지
  않고 새 목록이 올 때까지 지금 목록을 둔다 — 스피너가 깜빡이고 더보기 메뉴의 토글이 잠깐 사라지는 것보다
  낫다고 봤다
- 이번 주 요약은 페이지와 무관하게 `watchWalksSince(이번 주 월요일 0시)` 스트림으로 센다(이번 주에 31번
  걸어도 31). 요약 스트림이 목록보다 먼저 오면 보관만 하고, 나중에 오면 loaded 의 요약만 바꾼다.
  요약 스트림의 `Err` 는 무시하고 지난 요약을 둔다 — 요약 줄 때문에 피드를 실패로 돌리지 않는다
- `refreshWeekSummary()`(앱 복귀)는 주가 바뀌었을 때만 들고 있던 목록으로 바로 다시 세고 새 주 시작으로
  다시 구독한다. 새 주는 옛 주 시작 이후의 부분이라 들고 있던 목록으로 세도 맞다
- `retry()` 는 요약 · 목록을 첫 페이지부터 다시 구독한다

### 페이지

- 타임라인을 `AppLoadMoreListener(onLoadMore: cubit.loadMore)` 로 감싸고 마지막 항목으로
  `AppListFooter(isLoadingMore:, canLoadMore: hasMore)` 를 붙인다. 끝까지 읽으면 공통 끝 안내
  (`feedEndOfList` "모두 확인했습니다")가 보인다 — 공통 위젯의 문구다
- 날짜 열 · 달 머리는 이어 붙인 전체 목록으로 계산하므로 페이지 경계에서도 이어진다
- 목록이 이제 걸러져 오므로 "즐겨찾기만 보기인데 0건" 이면 즐겨찾기 안내, 필터가 꺼진 0건이면 첫 산책
  안내다. 요약 줄 · 추적 중 시작 버튼은 `목록이 있거나 즐겨찾기만 보기` 일 때 보인다(예전에는 거르기 전
  전체 목록으로 판단했다). 산책이 아예 없는데 즐겨찾기만 보기를 켜면 0건 요약 줄과 즐겨찾기 안내가 보이는
  것은 받아들였다

### 검증

- `apps/pawlog` `flutter analyze` 0건 · `flutter test` `+558` · `flutter build apk --debug` 성공
- `apps/trader` `flutter test test/convention` 통과
- 에뮬레이터 확인은 하지 않았다
