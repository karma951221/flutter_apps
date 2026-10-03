# W3 record — 구현 기록

> [pawlog 허브](../../README.md) · [계획](plan.md) · [테스트](testing.md) · [구현 리뷰](../../audits/2026-10-03-implementation-review.md)

설계 판단 · 리뷰에서 고친 것 · 검증 결과를 남긴다. 진행 상태는 [진행 현황](../../status.md)에만 적는다.
구현 커밋은 `93d722b`(단계 ⑥ 저장 폼 + 상세를 ⑦ 에서 당겨 함께)다. 리뷰 ⑥ 의 판정은 **보류**다 —
상세 · 수정 화면이 앱 라우터에서 열리지 않는다(⑥ W1, 아래). 리뷰 ⑥ 의 소견 번호 W1~W6 은
feature 이름 W1 dog 등과 겹치므로 이 문서에서는 "⑥ W1" 처럼 단계를 붙여 쓴다.

## 2026-10-03 — 설계 판단

### 사진은 고르는 즉시 한 장씩 파일로 쓴다

W1 과 같은 원칙이다. `addPhotos` 가 `storePhoto` 를 한 장씩 부르고 성공한 경로를 `photoPaths`
끝에 붙인다. 넘치는 몫(`maxPhotos = 10`)은 버리고, 실패한 장은 `walkPhotoSaveFailed` 를 싣고
나머지를 계속한다. 시작할 때 남아 있던 `failure` 를 먼저 비운다 — 같은 실패가 연달아 나도
스낵바 리스너(`listenWhen` 은 "새 실패"만)가 다시 듣게 하려는 것이다.

매 `await` 뒤에 닫힘 · 저장 시작 · 10장 도달을 다시 보고, 받을 수 없으면 방금 쓴 파일을 지우고
멈춘다. W1 의 T1 수정과 같은 가드다(리뷰 ④ 다음 단계 표).

### 지우는 것은 "이번 폼에서 쓴 파일"뿐이다

`WalkEditForm.addedPhotoPaths` = `photoPaths` 중 `existing.photos` 에 없던 것(신규는 전부).
썸네일의 x 는 추가분이면 파일을 바로 지우고, 기존 사진은 목록에서만 뺀다. 기존 파일은 저장이
성공한 뒤 `UpdateWalkScenario` 가 DB 성공 다음에 지운다 — 수정을 취소하면 그대로 남아야 하기 때문이다.

### 수정 모드는 `discardWalk` 를 부르지 않는다

`discardWalk` 안의 `tracker.clear()` 는 `finished` 에서 `idle` 로 간다. 저장 대기 중인 다른 세션이
있을 때 수정 폼을 버리면 그 세션이 지워진다(리뷰 ① B2 의 남은 몫). 그래서 `discard()` 는 신규에서만
동작하고, 수정 모드의 정리는 `close()` 의 `removePhoto` 만 쓴다. 수정 화면에는 버리기 버튼도 없다.

### 신규 모드의 뒤로 가기는 버리기와 같은 확인을 거친다

`PopScope(canPop: false)` 를 `editing` 동안만 건다. 그냥 나가면 `finished` 세션이 남아 W2 가 새
산책 대신 저장 폼으로 돌려보낸다. 확인하면 `discardWalk(photoPaths: 추가분)` → `discarded` →
`onDiscarded`(앱: `go('/')`). 수정 모드는 막지 않는다.

`close()` 는 신규 모드라도 `tracker.clear()` 를 하지 않는다 — 앱이 다른 길로 폼을 내리면 세션은
남고 피드 배너(W4)로 다시 온다.

### 저장 중에 닫히면 파일을 지우지 않는다

`close()` 는 `saved` · `discarded` 가 아니면 추가분을 지우지만, `isSaving` 중이면 건너뛴다.
`saveWalk` 가 이미 그 경로로 행을 썼을 수 있어, 결과를 모른 채 지우면 저장된 산책의 사진이
깨진다. 저장이 실패했다면 고아 파일이 남는다 — 계획의 규칙 3 에서 벗어난 의도한 예외다.

### 상세는 수정에서 돌아오면 조용히 다시 읽는다

상세는 스트림이 아니다. `onEdit(id)` 가 `push` 의 Future 를 돌려주고, 페이지는 그것을 기다린 뒤
`load(id)` 를 다시 부른다(통근 앱 `OpenSettingsCallback` 과 같은 방식). `load` 는 이미
`loaded` · `deleting` 이면 `loading` 을 내지 않아 화면이 깜빡이지 않는다. 산책과 경로는
레코드 `.wait` 로 함께 읽고, `Ok(null)` 은 `walkNotFound` 다. 수정 폼의 `loadExisting` 도
`getWalk` 와 `getDogs` 를 함께 읽는다.

### 삭제 실패는 내용을 지우지 않는다

`deleting(walk, track)` · `loaded(walk, track, failure?)` 로 데이터를 들고 다닌다. 삭제가 실패하면
`loaded(failure)` 로 돌아와 스낵바만 띄운다(설계 §4 에 데이터를 더했다).

### 저장 뒤 스택은 피드 → 상세

`onSaved(id)` 에서 앱이 `go('/')` 후 `push('/walks/:id')` 한다. 상세에서 뒤로 가면 피드다. 수정
모드는 `onSaved` · `onDiscarded` 모두 `pop()`. 저장 폼으로는 W2 가 `pushReplacement` 로 들어온다(V1).
리뷰어가 go_router 로 스택 `[/, /walks/w1]` 을 확인했다 — 단 지금은 ⑥ W1 때문에 상세가 피드로 튕긴다.

### 페이지는 생성자 하나

계획의 `WalkEditPage.create()` · `.edit(walkId)` 대신 `WalkEditPage({walkId})` 하나다. `walkId` 가
null 이면 신규. `DogEditPage({dogId})` 와 같은 모양이다.

## 리뷰에서 고친 것

| id | 내용 | 커밋 |
|---|---|---|
| B2 (잔여) | 수정 폼은 `discardWalk` 대신 `removePhoto` 로 정리 | `93d722b` |
| S2 | 스펙에 없던 `/walks` 목록 화면을 `redirect` 로 피드에 돌린다 — **자식까지 막는 ⑥ W1 을 새로 만들었다** | `93d722b` (△) |
| V1 | 저장 폼에 `pushReplacement` 로 들어와 뒤로 가기가 앱을 닫지 않는다([tracking 기록](../tracking/history.md)) | `93d722b` |
| T1 류 | `addPhotos` 의 await 뒤 가드 — 늦게 온 파일은 지운다 | `93d722b` |

## 고치지 않았지만 적어 둘 것

- **⑥ W1 (버그, 미해결)** — `/walks` 부모의 route-level `redirect` 는 자식으로 갈 때도
  `matchedLocation == '/walks'` 를 받는다. 리뷰어가 같은 구성의 go_router 로 `go('/walks/w1')` ·
  `go('/walks/w1/edit')` 가 모두 `/` 로 가는 것을 재현했다. 저장 뒤 `push(walk(id))` 는 피드로 튕기고
  상세 · 수정은 앱에서 열리지 않는다. S2 를 고치며 생긴 결함이고, 페이지 테스트는 라우터 없이 페이지를
  띄워 못 잡았다. 제안: `state.fullPath` / `state.uri.path` 비교 또는 `/walks/:id` 최상위화 + 앱 라우터 테스트
- **⑥ W2** — 저장 중 닫히면 추가 사진을 지우지 않는 위 판단의 대가로, 저장이 **실패**하면 고아가 남는다.
  `save()` 가 `isClosed` 면 결과를 버리기 때문이다. 신규는 `PopScope` 가 막아 수정 모드만 해당
- **⑥ W3** — 사진 빼기 버튼이 `InkResponse` + `CircleAvatar` 라 터치 영역이 작고 의미 라벨이 없다
- **⑥ W4** — `cacheWidth: 400` · `tileSize * 2`(기기 배율 무시) · scrim `alpha: 0.6` · 지도 높이
  `AppSpacing.xl * 8` 등 크기 수치(④ T3 · ⑤ V3 와 같은 결)
- 저장 직전에 고른 사진은 조용히 빠진다 — ④ T1 수정과 같은 대가이고 리뷰는 받아들일 만하다고 봤다
- 신규 모드에서 `getDogs` 가 실패해도 "저장할 산책이 없습니다" + "피드로 돌아가기" 가 보인다
  (계획 표대로지만 실패 원인을 가린다). 세션은 남는다
- 상세 · 저장 폼의 통계는 `WalkStatsRow` 라 시간이 `clock`(`30:00`)으로 보인다. W2 계획은 `duration`
  (`30분`)을 "W3 · W4 카드용" 이라 했다. 값 키도 `walk-active-elapsed` · `walk-active-distance` 를 같이 쓴다
- 저장 중 닫힘 · 프로세스 종료로 남는 고아 사진 파일은 감수한다(계획 범위 밖)
- `discardWalk` 결과를 보지 않는다(`Future<void>`) — 파일 삭제는 best-effort
- `RouteMap` 이 `getIt<TileProvider>()` 를 푸는 곳이 진행 · 상세 둘이 됐다(V4)
- **테스트 공백**: **앱 라우터 연결(⑥ W1 — `createRouter` 로 `/walks/w1` 이 상세를 그리는지)**,
  저장 중 닫힘(⑥ W2), 카메라 경로(`captureImage`), 10장 도달 시 추가 칸 대신 캡션(UI), 시트 취소,
  `prepare` 예외 스낵바, 상세 실패 화면의 재시도, `WalkPhotoGrid` 의 깨진 파일 표시, `DogAvatars` 의 `+n`,
  삭제된 강아지만 있던 산책의 수정

## 검증

- `93d722b` 스냅숏에서 `feature_walk` `flutter analyze` 0건 · `flutter test` `+150`(W3 몫 44건 —
  cubit 26 · 페이지 18), `apps/pawlog` `+5`. 리뷰어도 `93d722b` worktree 에서 같은 수와
  `design_system` `+42` 를 확인했다. **테스트가 모두 통과해도 ⑥ W1 은 남아 있다** — 라우터 테스트가 없다
- **에뮬레이터 확인은 아직 하지 않았다 (이 환경에 Android SDK 없음).** 저장 → 상세 → 수정 → 삭제와
  사진 파일 확인은 [테스트](testing.md#에뮬레이터)에 미실행으로 남겼다. iOS 도 빌드하지 않았다
