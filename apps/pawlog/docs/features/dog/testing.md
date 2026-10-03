# W1 dog — 테스트

> [테스트 가이드](../../../../../docs/testing/README.md) · [pawlog 허브](../../README.md) · [계획](plan.md) · [구현 기록](history.md) · [구현 리뷰](../../audits/2026-10-03-implementation-review.md)

```bash
cd packages/features/walk && flutter test test/presentation/cubit/dog_list_cubit_test.dart test/presentation/cubit/dog_edit_cubit_test.dart
cd packages/features/walk && flutter test test/presentation/page/dog_list_page_test.dart test/presentation/page/dog_edit_page_test.dart
cd packages/features/walk && flutter test test/data/repository/drift_dog_repository_test.dart
cd apps/pawlog && flutter test   # 첫 실행 리다이렉트 · 패키지 경계
```

백엔드가 없어 모두 로컬에서 돈다. W1 몫은 cubit 14 · 페이지 9 · 레포 5 · 앱 4건이다
(2026-10-03, `93d722b` 기준). 도메인 규칙(이름 trim · 사진 교체 시 옛 파일 삭제 · 없는 강아지)은
① 의 `save_dog_scenario_test.dart` 가 이미 덮는다.

## `packages/features/walk/test/presentation/cubit/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `dog_list_cubit_test.dart` (3) | `DogListCubit` | 스트림이 2마리를 내면 `loading` → `loaded` · `Err` 면 `failure` · 닫힌 뒤 온 스트림 값은 상태를 내지 않는다 |
| `dog_edit_cubit_test.dart` (11) | `DogEditCubit` | `load(null)` → 빈 폼 `editing` · `load(id)` → `loading` → 값이 찬 `editing` · 없는 강아지 → `loadFailure` · 빈 이름 저장 → `isSaving` 거쳐 `editing(failure)` · 정상 저장은 `DogDraft` 를 넘기고 `saved` · 삭제 → `deleteDog` · `deleted` · 사진을 고르면 `storePhoto` 후 경로를 폼에 · 두 번 고르면 첫 새 파일 삭제 · 저장 없이 닫으면 새 사진 삭제 · 저장했으면 닫아도 유지 · **저장 중 늦게 도착한 사진은 파일을 지우고 상태를 바꾸지 않는다**(T1) |

## `packages/features/walk/test/presentation/page/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `dog_list_page_test.dart` (3) | `DogListPage` | 빈 목록 → `AppPlaceholder` + 추가 버튼 → `onAddDog` · 2마리 → 행 2개 · 품종 subtitle · 행 탭 → `onOpenDog(id)` · 스트림 실패 → `AppPlaceholder` + 다시 시도 |
| `dog_edit_page_test.dart` (6) | `DogEditPage` | 신규는 메뉴 없이 "반려견 등록" · 이름 입력 후 저장 → `onDone` 한 번 · 저장 실패 → 스낵바 · **불러오는 동안에도 "반려견 수정"**(T2) · 수정: 메뉴 → 삭제 → 확인이면 `deleteDog` · `onDone`, 취소면 `deleteDog` 없음 |

## 데이터 · 앱 셸

| 파일 | 대상 | 확인 |
|---|---|---|
| `test/data/repository/drift_dog_repository_test.dart` (5) | `DriftDogRepository` (메모리 drift) | 저장 후 이름순 watch · 수정이 스트림에 반영 · 삭제하면 사라짐 · `findById` 없으면 null · 생일이 깨진 행도 스트림을 끊지 않는다(D1) |
| `apps/pawlog/test/app/router/dogs_redirect_test.dart` (4) | `DogsRedirect` | 0마리면 `/dogs` 밖 경로 → `/dogs/new` · `/dogs` 아래는 통과 · 있으면 통과 · `markHasDogs()` 뒤 통과 |
| `apps/pawlog/test/convention/package_boundary_test.dart` (1) | `feature_walk` pubspec | 다른 feature · `supabase_flutter` · `go_router` 의존이 없다 |

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

계획의 완료 조건 중 화면 확인 몫이다. **미실행** — 이 환경에 Android SDK 가 없다.

| # | 시나리오 | 결과 |
|---|---|---|
| ① | 첫 실행(0마리) → `/dogs/new` → 저장 → 피드 | 미실행 |
| ② | 등록 → 목록에 이름순 → 수정 → 삭제 | 미실행 |
| ③ | 사진 교체 시 옛 파일 삭제, 저장 없이 나가면 새 파일 삭제(`adb shell run-as com.karma.pawlog ls files/pawlog_photos`) | 미실행 |
| ④ | 강아지 삭제 후에도 산책 기록이 남는다 | 미실행 |
