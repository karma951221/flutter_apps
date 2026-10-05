# W1 dog — 테스트

> [테스트 가이드](../../../../../docs/testing/README.md) · [pawlog 허브](../../README.md) · [계획](plan.md) · [구현 기록](history.md) · [구현 리뷰](../../audits/2026-10-03-implementation-review.md)

```bash
cd apps/pawlog && flutter test test/presentation/dog/cubit
cd apps/pawlog && flutter test test/presentation/dog/page
cd apps/pawlog && flutter test test/data/dog/drift_dog_repository_test.dart
cd apps/pawlog && flutter test test/core test/convention   # 첫 실행 리다이렉트 · 패키지 경계
```

백엔드가 없어 모두 로컬에서 돈다. W1 몫은 cubit 14 · 페이지 9 · 레포 5 · 앱 4건이다
(2026-10-03, `93d722b` 기준). 도메인 규칙(이름 trim · 사진 교체 시 옛 파일 삭제 · 없는 강아지)은
① 의 `save_dog_scenario_test.dart` 가 이미 덮는다.

## `apps/pawlog/test/presentation/dog/cubit/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `dog_list_cubit_test.dart` (3) | `DogListCubit` | 스트림이 2마리를 내면 `loading` → `loaded` · `Err` 면 `failure` · 닫힌 뒤 온 스트림 값은 상태를 내지 않는다 |
| `dog_edit_cubit_test.dart` (11) | `DogEditCubit` | `load(null)` → 빈 폼 `editing` · `load(id)` → `loading` → 값이 찬 `editing` · 없는 강아지 → `loadFailure` · 빈 이름 저장 → `isSaving` 거쳐 `editing(failure)` · 정상 저장은 `DogDraft` 를 넘기고 `saved` · 삭제 → `deleteDog` · `deleted` · 사진을 고르면 `storePhoto` 후 경로를 폼에 · 두 번 고르면 첫 새 파일 삭제 · 저장 없이 닫으면 새 사진 삭제 · 저장했으면 닫아도 유지 · **저장 중 늦게 도착한 사진은 파일을 지우고 상태를 바꾸지 않는다**(T1) |

## `apps/pawlog/test/presentation/dog/page/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `dog_list_page_test.dart` (3) | `DogListPage` | 빈 목록 → `AppPlaceholder` + 추가 버튼 → `onAddDog` · 2마리 → 행 2개 · 품종 subtitle · 행 탭 → `onOpenDog(id)` · 스트림 실패 → `AppPlaceholder` + 다시 시도 |
| `dog_edit_page_test.dart` (6 → 12) | `DogEditPage` | 신규는 메뉴 없이 "반려견 등록" · 이름 입력 후 저장 → `onDone` 한 번 · 저장 실패 → 스낵바(이름 누락은 입력칸 `errorText`, 디자인 P3) · **사진 변경(2026-10-05) — 출처 시트에 앨범 · 카메라, 카메라 → `captureImage` → `storePhoto`, 앨범 → `pickImage`(카메라 없음), 시트를 닫으면 아무것도 안 부름, 카메라로 찍고 저장 없이 나가면 `removePhoto(새 파일)`** · **불러오는 동안에도 "반려견 수정"**(T2) · 수정: 메뉴 → 삭제 → 확인이면 `deleteDog` · `onDone`, 취소면 `deleteDog` 없음 |

## 데이터 · 앱 셸

| 파일 | 대상 | 확인 |
|---|---|---|
| `test/data/dog/drift_dog_repository_test.dart` (5) | `DriftDogRepository` (메모리 drift) | 저장 후 이름순 watch · 수정이 스트림에 반영 · 삭제하면 사라짐 · `findById` 없으면 null · 생일이 깨진 행도 스트림을 끊지 않는다(D1) |
| `test/core/router/app_router_test.dart` (+2, 2026-10-04) | `createRouter` | 첫 등록(0마리)을 마치면 목록이 아니라 피드(`/`) · 목록에서 추가를 마치면 목록으로 돌아간다 |
| `test/core/router/dogs_redirect_test.dart` (4) | `DogsRedirect` | 0마리면 `/dogs` 밖 경로 → `/dogs/new` · `/dogs` 아래는 통과 · 있으면 통과 · `markHasDogs()` 뒤 통과 |
| `test/convention/package_boundary_test.dart` (1) | `apps/pawlog` pubspec | `feature_*` · `supabase_flutter` 의존이 없다 (2026-10-04 `feature_walk` 를 앱으로 옮기며 대상이 앱 pubspec 으로 바뀌었다) |

계획 테스트 표의 17줄은 모두 위 파일에 있다. 리뷰 ④ I2 가 짚은 공백은 [구현 기록](history.md)의
"고치지 않았지만 적어 둘 것" 에 남겼다.

## 알아둘 것

- 페이지 테스트는 `getIt` 에 mock `WalkUseCase` 로 만든 cubit factory 를 등록하고
  `tearDown(getIt.reset)` 한다. 페이지가 `BlocProvider` 안에서 `getIt<...Cubit>()` 을 부르기 때문이다
- `test/support/pump_app.dart` 가 `locale: Locale('ko')` · `AppTheme.light()` 로 감싼다. `ko` 가 ARB
  템플릿이라 원문이 곧 기대값이다
- "불러오는 동안" 테스트는 스피너가 끝나지 않아 `pumpAndSettle` 을 쓸 수 없다 — `pumpWidget` 뒤
  `pump()` 한 번만 한다
- 사진 파일은 `photoFile` 을 stub 해 없는 경로의 `File` 을 준다. 디코드는 검증하지 않는다

## 에뮬레이터

계획의 완료 조건 중 화면 확인 몫이다. **2026-10-04 실행** — Android 17 에뮬레이터(`Medium_Phone`), 위치는 `adb emu geo fix` 로 경로를 흘렸다. 고친 것은 [구현 기록](history.md)의 "2026-10-04 — 에뮬레이터 QA" 에 있다.

| # | 시나리오 | 결과 |
|---|---|---|
| ① | 첫 실행(0마리) → `/dogs/new` → 저장 → 피드 | **PASS**(수정 뒤) — 처음엔 저장 뒤 반려견 목록에 떨어져 피드로 갈 길이 없었다(`fce4e77`) |
| ② | 등록 → 목록에 이름순 → 수정 → 삭제 | 일부 — 목록과 수정 폼은 확인, 삭제는 실행하지 않았다 |
| ③ | 사진 교체 시 옛 파일 삭제, 저장 없이 나가면 새 파일 삭제(`adb shell run-as com.karma.pawlog ls app_flutter/pawlog_photos`) | 미실행 |
| ④ | 강아지 삭제 후에도 산책 기록이 남는다 | 미실행 |

사진 폴더는 `getApplicationDocumentsDirectory()` 아래라 Android 에서는 `files/` 가 아니라
`app_flutter/pawlog_photos` 다.
