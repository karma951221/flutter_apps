# W3 record — 테스트

> [테스트 가이드](../../../../../docs/testing/README.md) · [pawlog 허브](../../README.md) · [계획](plan.md) · [구현 기록](history.md) · [구현 리뷰](../../audits/2026-10-03-implementation-review.md)

```bash
cd packages/features/walk && flutter test test/presentation/cubit/walk_edit_cubit_test.dart test/presentation/cubit/walk_detail_cubit_test.dart
cd packages/features/walk && flutter test test/presentation/page/walk_edit_page_test.dart test/presentation/page/walk_detail_page_test.dart
cd packages/features/walk && flutter test test/domain/usecase/scenario   # 저장 · 수정 · 삭제 · 버리기 시나리오
```

W3 몫은 cubit 26 · 페이지 18 = 44건이다(2026-10-03, `93d722b` 기준). 파일 정리 순서 · 사진 id 보존 ·
0마리 거부는 ① ② 의 시나리오(`save_walk` 4 · `update_walk` 3 · `delete_walk` 3 · `discard_walk` 1)와
`drift_walk_repository_test.dart`(8)가 덮는다.

## `test/presentation/cubit/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `walk_edit_cubit_test.dart` (20) | `WalkEditCubit` | `finished` 세션으로 폼(세션 강아지 선택) · 세션 없음 / 추적 중 → `loadFailure` · 기존 산책 불러오기 · 없는 산책 → `walkNotFound` · 강아지 토글 · 메모 · `addPhotos` 가 `storePhoto` 후 경로를 쌓는다 · **9장에 3장 → 1장만 저장, 10장** · 한 장 실패 → `failure` 싣고 나머지 계속 · `removePhoto` 는 추가분만 파일 삭제 · 신규 저장 → `saveWalk(WalkDraft)` → `saved` · 저장 실패 → `editing.failure` · 수정 → `updateWalk` · **저장 중 늦게 끝난 `addPhotos` 는 파일 삭제** · 버리기 → `discardWalk(추가분)` → `discarded` · **수정 모드 `discard` 는 `discardWalk` 를 부르지 않는다** · 저장 없이 닫으면 새 사진 삭제 · 수정 중 추가분만 닫을 때 삭제하고 `discardWalk` 없음 · 저장했으면 닫아도 유지 · `addPhotos` 도중 닫히면 방금 쓴 파일 삭제 |
| `walk_detail_cubit_test.dart` (6) | `WalkDetailCubit` | `load` 가 walk · track 을 함께 읽는다 · `Ok(null)` → `failure(walkNotFound)` · 읽기 실패 → `failure` · **다시 읽을 때 `loading` 을 내지 않는다** · 삭제 → `deleting` → `deleted` · 삭제 실패 → `loaded(failure)` |

## `test/presentation/page/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `walk_edit_page_test.dart` (10) | `WalkEditPage` | 신규: 강아지 없이 저장 → `walkDogRequired` 스낵바 · 저장 → `onSaved(id)` 한 번 · 앨범에서 고르면(`pickImages(limit: 10)`) 썸네일 · 빼기 버튼이 생기고, 저장 없이 페이지를 내리면 그 파일을 지운다(테스트 이름은 "저장에 실린다" 지만 저장은 확인하지 않는다) · **뒤로 가기 → 버리기 확인, 취소면 아무 일 없음 · 확인하면 `discardWalk` 후 `onDiscarded`** · 버리기 버튼도 같은 확인 · 세션 없음 → 안내 + "피드로 돌아가기" → `onDiscarded`. 수정: 버리기 버튼 없이 기존 메모 · 사진 · 저장 → `updateWalk` 후 `onSaved` · 기존 사진을 빼도 파일은 지우지 않는다 |
| `walk_detail_page_test.dart` (8) | `WalkDetailPage` | 지도 · 날짜 · 거리 · 시간 · 반려견 이름 · 사진 · 메모 · 점 0개 → "기록된 경로가 없습니다" · 메모 · 사진이 없으면 절 생략 · 불러오기 실패 → 안내 + 다시 시도 · 더보기 → 삭제 → 확인 → `deleteWalk` 후 `onDeleted` · 취소면 `deleteWalk` 없음 · 삭제 실패 → 내용 유지 + 스낵바 · **수정에서 돌아오면 다시 읽는다**(`onEdit` 의 Future 완료 뒤 `getWalk` 2회) |

계획 테스트 표의 18줄은 모두 위 파일에 있다. `PhotoStrip` · `PhotoSourceSheet` · `WalkPhotoGrid` ·
`DogAvatars` 는 따로 테스트 파일이 없고 페이지 테스트가 지난다.

## 알아둘 것

- 페이지 테스트는 `getIt` 에 mock `WalkUseCase` 로 만든 cubit factory, `StubTileProvider`(상세),
  `MockImagePickerService`(저장 폼)를 등록하고 `tearDown(getIt.reset)` 한다
- 저장 폼 테스트는 저장 · 버리기 버튼까지 한 화면에 들어오게 `tester.view.physicalSize` 를
  800×2400 으로 키운다(`useTallScreen`, `addTearDown(tester.view.reset)`)
- 닫힐 때 파일을 지우는지 보려면 `tester.pumpWidget(const SizedBox())` 로 페이지를 내려
  `close()` 를 태운다. 상세는 지도 애니메이션이 남지 않게 같은 방식으로 내린다
- `photoFile` 은 없는 경로의 `File` 을 돌려주도록 stub 한다 — 디코드는 검증하지 않는다
- 늦게 도착하는 사진은 `Completer<Result<String>>` 로 `storePhoto` 를 멈춰 두고 그 사이에
  `save()` · `close()` 를 부른다
- `pumpApp` 은 `Locale('ko')` 를 고정한다. 날짜는 `displayDateTime('ko')` 형식(`2026.10.03 09:00`)

## mock 으로 확인되지 않는 것

- **실제 사진 파일** — cubit · 페이지는 `storePhoto` · `removePhoto` 호출만 본다. 파일이 실제로
  생기고 지워지는지는 `file_photo_storage_test.dart`(임시 폴더)와 에뮬레이터의 `run-as ls` 로 확인한다
- **image_picker · 카메라 인텐트** — `MockImagePickerService` 라 권한 · 압축 · 취소 동작은 기기에서만
- **앱 라우터 연결** — 페이지를 라우터 없이 직접 띄우므로 `/walks/:id` 가 열리는지 모른다. 리뷰 ⑥ W1
  (부모 `/walks` redirect 가 상세 · 수정까지 피드로 돌린다, `d5f95b0` 에서 수정)이 이 틈으로 빠졌다 — `apps/pawlog/test/app/router/`
  에 `createRouter` 테스트가 필요하다([구현 기록](history.md))
- **사진 디코드 · 지도 타일** — 없는 경로의 `File` 과 stub 타일이라 실제 썸네일 · 경로 그림은 안 보인다

## 에뮬레이터

계획 완료 조건과 [기획서](../../overview.md) §8 에뮬레이터 검증 시나리오 ④⑤⑥ 의 W3 몫이다.
**미실행** — 이 환경에 Android SDK 가 없다.

| # | 시나리오 | 결과 |
|---|---|---|
| ① | 종료 → `/walk/save` → 사진 2장 + 메모 → 저장 → 상세 → 뒤로 → 피드 | 미실행 |
| ② | 상세 → 수정(메모 · 사진 하나 빼기) → 돌아오면 상세가 다시 읽힌다 | 미실행 |
| ③ | 상세 → 삭제 → 피드. `adb shell run-as com.karma.pawlog ls files/pawlog_photos` 에서 파일이 사라진다 | 미실행 |
| ④ | 저장 폼에서 버리기 · 뒤로 → 확인 → 사진 파일 삭제, 추적기 `idle` | 미실행 |
| ⑤ | `trackerState` 가 `finished` 가 아닐 때 `/walk/save` → 안내 + 피드로 | 미실행 |
| ⑥ | 카메라로 찍기(`CAMERA` 미선언 → 카메라 앱 인텐트) | 미실행 |
