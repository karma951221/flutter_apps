# 구현 리뷰 · 요약 — pawlog

> [pawlog 허브](../README.md) · [기획서](../overview.md) · [진행 현황](../status.md) ·
> [설계 스펙](../../../../docs/superpowers/specs/2026-10-03-walk-app-design.md) ·
> [아키텍처](../../../../docs/architecture.md) · [에이전트 가이드](../../../../CLAUDE.md)

작성 2026-10-03 · 대상 커밋 `077640e` ~ `a6fc098` — 단계 ① `077640e` · ② `bdb60c3` · ③ `87c680d` · ④ `cdc1ac2` · ⑤ `4627805` · ⑥ `93d722b` · ⑦ `d5f95b0`, 소견 반영 `b4abf9c` · `a6fc098`

구현 에이전트와 별개인 리뷰어 에이전트가 [기획서](../overview.md) §8 의 단계 커밋을 하나씩
독립적으로 읽고, 기획서 · 설계 스펙 · [CLAUDE.md](../../../../CLAUDE.md) 규칙에 비추어 쓴 기록이다.
커밋에 들어간 파일만 보고, 작업 트리의 미커밋 변경은 보지 않는다. 위치(`path:line`)는 대상
커밋 시점 기준이다. 뒤 단계에서 고쳐진 소견은 지우지 않고 **반영됨**(고친 커밋)으로 한 줄로 줄인다.
무엇이 끝났고 다음이 무엇인지는 이 문서가 아니라 [진행 현황](../status.md)이 기준이다.

## 요약

| 단계 | 커밋 | 범위 | 판정 |
|---|---|---|---|
| ① | `077640e` | `feature_walk` 뼈대 · 도메인(엔티티 11 · 정책 2 · 인터페이스 4 · facade · 시나리오 15) · `FailureCode` +5 · ARB 3개 | **통과(조건부)** — 버그 확정 0, 스펙과 다른 결정 13건(스펙 문서 반영 필요), 잠재 결함 3건(B1 · B3 → `bdb60c3`, B2 → `cdc1ac2` 반영) |
| ② | `bdb60c3` | drift `WalkDatabase`(5테이블) · 매퍼 · `DriftDogRepository` · `DriftWalkRepository` · `FilePhotoStorage` · `WalkRegisterModule` · ① 소견 B1 · B3 반영 | **통과(조건부)** — 스키마 · cascade · 조인 watch 는 스펙대로이고 테스트가 실제로 단언한다. `WalkTracker` 미등록이라 ⑤ 전에는 `WalkUseCase` 를 resolve 할 수 없음(D3), watch 의 매핑 예외가 `Err` 로 바뀌지 않는 구멍(D1), DB dispose 누락(D2) — 셋 다 `cdc1ac2` 반영 |
| ③ | `87c680d` | `apps/pawlog` 셸(부팅 · DI · 라우터 · `DogsRedirect` · 권한) · `AppAvatar.imageFile` · `captureImage` | **통과(조건부)** — 통근 셸과 같은 모양, 권한 선언 정확. 단 D3 때문에 실제 앱은 부팅 스피너에서 멈추고 오류가 안 보임(S1), 스펙에 없는 `/walks` 경로(S2), 새 템플릿의 AGP 9 · iOS 15 미검증(I1). S1 은 `cdc1ac2` 반영 |
| ④ | `cdc1ac2` | `GeolocatorWalkTracker` · `LocationGateway`(⑤ 데이터 몫을 당김) · W1 반려견 목록 · 편집(cubit 2 · 페이지 2 · `walkDog*` 15키) · ②③ 소견 반영 | **통과(조건부)** — tracker 계약 · W1 계획 · UI 규칙을 대체로 지킨다. 사진 고르기 ↔ 저장 경합으로 파일이 고아가 될 수 있음(T1), 수정 화면이 불러오는 동안 · 불러오기 실패 때 "등록" 제목(T2), `stop` 의 Failure 종류(T4). T1 · T2 · T4 · I1 은 `93d722b` 반영 |
| ⑤ | `4627805` | W2 진행 화면 — `ActiveWalkCubit`(1초 타이머) · `RouteMap` · `WalkStatsRow` · `DogChips` · `WalkFormat` · `walk*` 19키, `/walk` 연결 | **통과(조건부)** — 상태 기계 · 타이머 · 재진입이 계획대로이고 `fakeAsync` 로 검증된다. `go(saveWalk)` 가 뒤로 갈 곳을 지움(V1), 0마리 안내에서 등록하고 돌아와도 갱신 안 됨(V2). V1 은 `93d722b`, V2 는 `d5f95b0` 반영 |
| ⑥ | `93d722b` | W3 저장 · 수정 폼과 상세(cubit 2 · 페이지 2 · 위젯 4), ④⑤ 소견 반영, `AppPlaceholder.actionKey` | **통과(조건부)** — 폼 · 사진 규칙 · 경합 처리가 꼼꼼하고 테스트가 두텁다. 상세 · 수정이 열리지 않던 W1 은 `d5f95b0` 에서 반영(처음 판정은 보류). 저장 중 닫힘 고아(W2) · 빼기 버튼 의미 라벨(W3) · `cacheWidth`(W4)는 `b4abf9c` 반영. 남은 조건은 에뮬레이터 검증 |
| ⑦ | `d5f95b0` | W4 피드(cubit · 페이지 · 카드 · 경로 썸네일 · 배너), ⑤ V2 · ⑥ W1 반영, 8경로 모두 실제 페이지 | **통과(조건부)** — 계획대로이고 두 스트림 합치기 · `finished` 처리 · 키가 정확하다. 경로 썸네일이 동서로 늘어나던 F1 은 `a6fc098` 반영. 크기 수치(F2) · 일부 분기 미검증(F3)이 남고, 남은 조건은 에뮬레이터 검증. 전체는 맨 아래 "전체 요약" |

---

## ① 도메인 · 패키지 뼈대 (077640e)

### 무엇이 들어왔나

경로 접두 `packages/features/walk/lib/src/` 는 `walk/` 로 줄인다.

| 묶음 | 내용 | 위치 |
|---|---|---|
| 패키지 | `feature_walk`(workspace 등록), 의존 `core` · `design_system` · `l10n` + drift · geolocator · flutter_map 등 후속 단계 몫까지 선언 | `packages/features/walk/pubspec.yaml:9-24`, `pubspec.yaml:25` |
| 엔티티 11 | `Dog` · `DogDraft` · `GeoPoint` · `WalkTrackPoint` · `WalkSession` · `TrackerState`(sealed) · `TrackingNotice` · `Walk` · `WalkPhoto` · `WalkDraft` · `WalkUpdate` | `walk/domain/entity/` |
| 정책 2 | `WalkTrackingPolicy`(정확도 ≤ 50 m · 이동 ≥ 2 m), `RoutePreview`(≤ 64점 · JSON) | `walk/domain/policy/` |
| 인터페이스 4 | `DogRepository` · `WalkRepository` · `WalkTracker` · `PhotoStorage` | `walk/domain/repository/` |
| facade | `WalkUseCase` 19개 메서드, `DefaultWalkUseCase`(`@LazySingleton`) + `withClock` 생성자 | `walk/domain/usecase/walk_use_case.dart:36-185` |
| 시나리오 15 | 정책 있는 것 8(SaveDog · DeleteDog · StartWalk · SaveWalk · DiscardWalk · UpdateWalk · DeleteWalk · StorePhoto) + 단순 위임 7(Get/Watch × Dog/Walk, GetWalkTrack, StopWalk) | `walk/domain/usecase/scenario/` |
| DI | micro package 모듈 생성물 — 지금은 `WalkUseCase` 하나만 등록 | `walk/di/feature_walk.module.dart:22-30` |
| core | `FailureCode` +5: `walkDogRequired` · `walkTrackingAlreadyActive` · `walkNotFound` · `walkPhotoSaveFailed` · `dogNameRequired` | `packages/core/lib/src/error/failure_code.dart:88-92` |
| l10n | 실패 문자열 5 + `walkAppTitle`(ko · en · ja), exhaustive switch 5줄 | `app_ko.arb:1838-1861`, `failure_localizations.dart:122-127` |
| 테스트 | `feature_walk` **24개**(정책 8 · 시나리오 16), `l10n` 에 walk 실패 문구 4개 추가(패키지 전체 10개) | `packages/features/walk/test/`, `packages/l10n/test/failure_localizations_test.dart:74-107` |

테스트 수와 정적 분석은 `077640e` 를 깨끗한 worktree 로 꺼내 확인했다: `feature_walk`
`flutter test` → `+24: All tests passed!`, `flutter analyze` → `No issues found!`,
`l10n` `flutter test` → `+10: All tests passed!`.

테스트 파일별: 정책 2파일 8개(50 m · 2 m 경계, 첫 점, null 정확도, 64점 · 첫/끝, 왕복, null), 시나리오 6파일 16개
(SaveDog 4 · SaveWalk 3 · UpdateWalk 2 · DeleteWalk 3 · StartWalk 3 · DiscardWalk 1).

### 설계 대비

기준은 [설계 스펙](../../../../docs/superpowers/specs/2026-10-03-walk-app-design.md) §2 와
[기획서](../overview.md) §6 · §9. "다름" 은 결함이 아니라 **스펙 문서를 고쳐야 하는 결정**이다
(스펙 §0: "바뀐 판단은 해당 절을 함께 고친다").

| 항목 | 스펙 · 기획 | 구현 | 판정 |
|---|---|---|---|
| 엔티티 필드 | 스펙 §2 표 | 11개 모두 필드 · 선택성 일치. `WalkDraft` 7필드, `WalkSession.elapsedAt(now)` 포함 | 일치 |
| `DogDraft` 사진 | 스펙 표는 `photoPath?`, facade 표는 "`newPhoto` 가 있으면 저장" | `photoPath` 만, 바이트 없음(`dog_draft.dart:17`). 선택 즉시 `storePhoto` 로 쓰는 W3 흐름과 같은 모양 | 다름 — 스펙 facade 표의 `newPhoto` 문구가 낡았다 |
| 시각 주입 | "`DateTime Function() now` 를 생성자로(기본 `DateTime.now`)" | 시나리오는 `now` 필수(`save_walk_scenario.dart:25`), 기본값은 facade 가 둔다(`walk_use_case.dart:84-107`, DI 는 이름 없는 생성자) | 다름 — 의도 동일, 더 명시적. 스펙 §7 후보 4 와 연결 |
| `WalkTrackingPolicy.accept` | §2 표 `({previous, next, stepMeters})`, §3 의사코드 `(accuracy:, metersFromPrevious:)` | §2 표를 따랐다(`walk_tracking_policy.dart:12-21`) | 일치 — 단, 스펙 §3 의사코드가 자기모순이라 고칠 것 |
| `RoutePreview.downsample` | `(List<GeoPoint>, {int max = 64})` | `(List<WalkTrackPoint>)`, `max` 인자 없음(`route_preview.dart:13`) | 다름 — 호출부가 `draft.points` 를 그대로 넘겨 편하다. 문제 없음 |
| `RoutePreview.encode` | 소수 5자리(≈1 m) | 전체 정밀도 `jsonEncode`(`route_preview.dart:24-26`) | **다름 — 개선 제안 3** |
| `RoutePreview.decode` | 깨진 값이면 빈 목록 | 예외를 던진다(`route_preview.dart:30-36`) | **다름 — 소견 B1** |
| 레포 메서드 이름 | `watchDogs` · `getDog → Result<Dog>`(없으면 notFound) 등 | `watchAll` · `getAll` · `findById → Result<T?>`(`dog_repository.dart:6-10`, `walk_repository.dart:8-12`) | 다름 — "없음" 판단이 시나리오로 옮겨 갔다. 개별 실패 코드를 시나리오가 고르므로 합리적 |
| `WalkTracker` | `state`, `void clear()` | `current`, `Future<void> clear()`(`walk_tracker.dart:8,21`) | 다름 — 무해 |
| `PhotoStorage` | `save(PreparedImage)`, `String resolve`, `delete` | `store({bytes, extension})`, **`File resolve`**, `remove`(`photo_storage.dart:8-16`) | 다름 — `File` 은 소견 R1 |
| facade 사진 경로 | `photoPath(relative) → String` | `photoFile → File` + `removePhoto` 추가(`walk_use_case.dart:64-66`) | 다름 — `removePhoto` 는 강아지 폼 버리기에 필요해 보인다 |
| `saveWalk` 반환 | `Result<String>`(id) | `Result<Walk>`(`walk_use_case.dart:43`) | 다름 — 정보가 더 많다. ⑥ 에서 `saved(id)` 로 쓰면 된다 |
| `storePhoto` 실패 | 시나리오가 `walkPhotoSaveFailed` 로 바꾼다 | 단순 위임(`store_photo_scenario.dart:12-15`) | **다름 — ② 로 넘김** |
| 시나리오 수 | 8개 | 15개(위임 7개 추가). [아키텍처 ③](../../../../docs/architecture.md) "단순 위임으로 시작해도 이후 확장 위치가 일관된다" 에 맞다 | 다름 — 규칙 쪽에 더 가깝다. 커밋 메시지의 "16개" 는 실제 15개 |
| `StartWalk` 중복 검사 | "그 외 실패는 tracker 가 정한다" | 시나리오도 `TrackerTracking` 을 검사(`start_walk_scenario.dart:21`) | 다름 — 방어적 중복. tracker 도 같은 검사를 해야 한다(②·⑤) |
| `SaveDog` 없는 반려견 | 정하지 않음 | `targetNotFound`(`save_dog_scenario.dart:36-39`), `DeleteDog` 도 같다(`delete_dog_scenario.dart:17-20`) | 일치(공백 보충) — 기존 범용 코드 재사용이라 ARB 를 늘리지 않는다 |
| 파일 삭제 순서 | DB 성공 뒤 | 4곳 모두 DB `Err` 면 조기 반환 후 삭제(아래 "괜찮은 점") | 일치 |
| `DeleteDog` 와 산책 | 산책은 남는다(cascade 는 `walk_dogs` 만) | 행 삭제 → 사진(`delete_dog_scenario.dart:23-27`) | 일치 — cascade 는 ② 의 스키마 몫 |
| ARB 설명 | "모든 키에 `@key.description`" | ko 에만(`app_ko.arb:1839` 등). en · ja 는 `@@locale` 하나뿐인 **기존 관례** 그대로 | 일치 — 스펙 문구를 "ko 에만" 으로 좁히면 정확하다 |
| barrel | 페이지 · `WalkUseCase` · 모듈 | 엔티티 · 정책 · 인터페이스 · 시나리오 · facade · 모듈 전부(`feature_walk.dart:1-34`). 통근 barrel 도 시나리오 · data 까지 내보낸다 | 일치(관례) — 페이지는 ④ 부터 |

### 리뷰 소견

등급: **B** 버그(잠재 포함) · **R** 규칙 · 경계 · **I** 개선 제안 · **G** 괜찮은 점.

#### B — 버그 · 잠재 결함

| # | 소견 | 위치 | 비고 |
|---|---|---|---|
| B1 | `RoutePreview.decode` 가 깨진 JSON 에서 던져 피드 스트림 전체를 끊을 수 있었다 | `route_preview.dart:28-38` | **반영됨**(`bdb60c3`) — 세 예외를 잡아 빈 목록, 깨진 값 4종 테스트 |
| B2 | `DiscardWalkScenario` 가 항상 `tracker.clear()` 를 불러, 추적 중에 수정 폼을 버리면 tracker 를 건드릴 수 있었다 | `discard_walk_scenario.dart:10-15` | **반영됨**(`cdc1ac2`) — `clear()` 가 `finished` 에서만 `idle`(`geolocator_walk_tracker.dart:197-201`, 테스트 `geolocator_walk_tracker_test.dart:207`). 잔여(⑥ 수정 폼이 `discardWalk` 를 쓰면 안 됨)도 `93d722b` 에서 지켜졌다 |
| B3 | `SaveWalk` · `UpdateWalk` 가 못 찾은 강아지 id 를 버려 0마리 산책이 저장될 수 있었다(기획 §9 #7) | `save_walk_scenario.dart:35-38`, `update_walk_scenario.dart:50-53` | **반영됨**(`bdb60c3`) — `selected.isEmpty` → `walkDogRequired`, 테스트 2개 |

#### R — 규칙 · 경계

| # | 소견 | 위치 | 의견 |
|---|---|---|---|
| R1 | domain 이 `dart:io` 의 `File` 을 쓴다. 저장소 전체에서 **처음**이다(`packages/*/lib` · 다른 feature domain 에 없음) | `photo_storage.dart:1,13`, `walk_use_case.dart:1,66` | [아키텍처 ⑤](../../../../docs/architecture.md)가 막는 것은 Flutter · Supabase SDK 이고 `dart:io` 는 Dart 코어라 **글자로는 위반이 아니다.** 앱이 모바일 전용이고 ③ 의 `AppAvatar.imageFile` 도 `File` 을 받으므로 실익도 있다. 다만 web 빌드를 닫고, 테스트가 `File` 을 만들어야 한다. **허용하되 스펙 §2 를 `File` 로 고치고 이유를 남기자** |
| R2 | Freezed 단일 모델은 Primary Constructor + `@override final` 로 통일됐다. 통근 엔티티와 같은 모양(`commute_result.dart:12`) | `dog.dart:6-31` 등 11개 | 위반 없음. `TrackerState` 는 sealed union(`tracker_state.dart:7-12`) |
| R3 | 생성된 `when` / `map` 호출 없음. 분기는 `switch` 패턴(`save_walk_scenario.dart:59-62`)과 `case Err(...)`, 상태 판별은 `is TrackerTracking` | 리포 grep | 위반 없음 |
| R4 | 테스트 위치가 구현 구조를 따른다(`test/domain/policy` ↔ `lib/src/domain/policy`, `test/domain/usecase/scenario`). 공용 mock 은 `test/support/fakes.dart`. 테스트 이름은 모두 한국어 문장 | `test/` | 위반 없음 |
| R5 | `.freezed.dart` · `feature_walk.module.dart` 는 생성 헤더를 가진 산출물. analyze 통과. 재생성 diff 비교는 하지 않았다 | `feature_walk.module.dart:1` | — |

#### I — 개선 제안

1. **테스트 공백.** `DeleteDogScenario`(삭제 후 사진 · DB 실패 시 유지) · `StorePhotoScenario` 테스트가
   없다. `RoutePreview` 는 깨진 값(B1), 65점(경계 바로 위)과 빈 목록이 없다. `SaveDog` 는 사진을
   **지운** 경우(`photoPath: null` → 옛 파일 삭제, `save_dog_scenario.dart:55-58`)와 DB 실패 시
   옛 파일 유지가 없다. `UpdateWalk` 의 id 보존은 테스트됐다(`update_walk_scenario_test.dart:64-67`).
2. **`StartWalk` 가 `finished` 를 막지 않는다**(`start_walk_scenario.dart:21`). 저장 폼을 저장도
   버리기도 하지 않고 떠나면, 다음 시작이 저장 안 된 세션을 덮어쓴다 → 열린 질문 1.
3. **`encode` 정밀도.** 소수 5자리로 반올림하면 64점 JSON 이 대략 절반이 되고 스펙과 맞는다
   (`route_preview.dart:24-26`). 왕복 테스트는 5자리 이하 값이라 그대로 통과한다.
4. **`PhotoStorage.remove` 의 "던지지 않는다" 는 주석 계약뿐이다**(`photo_storage.dart:15`).
   시나리오는 `try` 없이 `await` 하므로(`delete_walk_scenario.dart:24-26`) 구현이 계약을 어기면
   DB 는 지워졌는데 `Err` 대신 예외가 난다. ② 테스트로 계약을 고정하자.
5. `SaveDog` 는 `name` 만 trim 하고 `breed` 는 그대로 둔다 — 공백 품종이 `""` 로 저장된다
   (`save_dog_scenario.dart:46`). trim 후 빈 값이면 `null` 이 일관적이다.
6. pubspec 에 ②~⑦ 몫의 의존(drift · flutter_map · geolocator · path_provider)이 미리 들어 있고
   `build.yaml`(drift `store_date_time_values_as_text`)은 아직 없다. ② 에서 같이 맞추면 된다.

#### G — 괜찮은 점

- 파일 삭제는 **DB 성공 뒤**(네 시나리오, `DeleteWalk` 는 `verifyInOrder`), `SaveWalk` 는 `Ok` 일 때만 `clear()`, `UpdateWalk` 는
  사진 id 보존(`update_walk_scenario.dart:42,57`), `downsample` 은 0 · 1 · 2점과 첫/끝 점을 정확히 다룬다(`route_preview.dart:13-22`),
  `elapsedAt(now)` 로 엔티티가 시계를 안 읽고, 정책은 geolocator 를 모르며, l10n exhaustive switch 가 문구 누락을 컴파일 오류로 만든다.

### 다음 단계에 넘기는 것

단계 칸의 ✓ 는 그 단계 커밋에서 확인된 것, △ 는 일부만 된 것, ✗ 는 그 단계에서 안 된 것.

| 단계 | 할 일 | 근거 |
|---|---|---|
| ② ✓ | `FilePhotoStorage.store` 실패를 `Failure.unknown(failureCode: walkPhotoSaveFailed)` 로 바꾼다(시나리오가 안 하므로 여기서) | `store_photo_scenario.dart:12-15`, 스펙 §2 실패 코드 표 |
| ② ✓ | `findById` 는 없으면 `Ok(null)` — 스펙의 "없으면 `Err`" 가 아니다. 레포 테스트도 이 계약으로 | `dog_repository.dart:10`, `walk_repository.dart:10` |
| ② ✓ | `route_preview` 컬럼 읽기에서 B1 을 막는다(도메인을 고치든 매퍼에서 잡든) | B1 |
| ② △ | `PhotoStorage.remove` 가 없는 파일 · IO 오류에서 던지지 않음을 테스트로 고정 | I4 |
| ② ✓ | 레포 2개 · `FilePhotoStorage` · `WalkRegisterModule` DI 등록. 지금 모듈은 `WalkUseCase` 만 등록해 해석 시 실패한다 | `feature_walk.module.dart:22-30` |
| ③ ✓ | `AppAvatar.imageFile` 을 `File` 로 — facade `photoFile` 과 짝 | R1 |
| ④ ✓ | 강아지 폼 버리기는 새 사진을 `removePhoto`(`dog_edit_cubit.dart:131-139`), `getDog` 의 `Ok(null)` → `loadFailure`(`:34-39`) | 스펙 §2 |
| ④ ✓ | tracker 가 `stepMeters` 를 먼저 계산해 `accept` 에 넘기고 받아들인 점만 합산(`geolocator_walk_tracker.dart:151-165`) | `walk_tracking_policy.dart:5` |
| ④ ✓ | `clear()` finished 전용 · `start` 중복 검사 · `stop` → `walkNotFound`(종류 `notFound` 는 `93d722b`) | B2, 스펙 §2 |
| ⑥ ✓ | `saved(walk.id)` · 수정 폼은 `discardWalk` 대신 파일만 정리 | B2 |
| ⑥⑦ ✓ | `getWalk` 의 `Ok(null)` → `walkNotFound`(`walk_detail_cubit.dart`), 강아지 0 산책은 상세 · 카드에서 아바타 줄 생략 | — |
| ⑧ | 설계 스펙 §2 · §3 을 위 "설계 대비" 의 "다름" 13건에 맞춰 고친다(특히 `PhotoStorage` · 레포 시그니처 · `accept` 의사코드 · ARB 설명 범위) | 스펙 §0 |

---

## ② 데이터 계층 (bdb60c3)

경로 접두 `packages/features/walk/lib/src/` 는 `walk/`, 테스트 접두 `packages/features/walk/test/` 는
`test/` 로 줄인다.

### 무엇이 들어왔나

| 묶음 | 내용 | 위치 |
|---|---|---|
| 스키마 | `dogs` · `walks` · `walk_dogs` · `walk_points` · `walk_photos`. FK 4개 모두 `onDelete: cascade`, 인덱스 `walks_started_at` · `walk_photos_walk_id`, 복합 pk `(walk_id, dog_id)` · `(walk_id, seq)` | `walk/data/database/tables.dart:3-73` |
| DB | `WalkDatabase(QueryExecutor)`, `schemaVersion 1`, `storeDateTimeAsText: true`, `beforeOpen` 에서 `PRAGMA foreign_keys = ON` | `walk/data/database/walk_database.dart:7-24` |
| 매퍼 | 행 ↔ 엔티티, 생일 `yyyy-MM-dd` 포맷 · 파싱, 조인 행 묶기 `walksFromJoinRows` | `walk/data/database/walk_mapper.dart:14-126` |
| 레포 | `DriftDogRepository`(이름순), `DriftWalkRepository`(4테이블 LEFT JOIN watch, 트랜잭션 insert · update, cascade delete) | `walk/data/repository/drift_dog_repository.dart`, `drift_walk_repository.dart` |
| 사진 | `FilePhotoStorage(@Named('walkPhotosRoot') Directory, IdGenerator)` — `<id>.<ext>` 상대 경로, 실패 시 `walkPhotoSaveFailed` | `walk/data/repository/file_photo_storage.dart:9-49` |
| DI | `WalkRegisterModule`: `WalkDatabase`(`driftDatabase(name: 'pawlog')`) · `walkPhotosRoot`(`@preResolve`) · `TileProvider`. 생성 모듈이 레포 3개를 등록하고 `init` 이 `async` 가 됐다 | `walk/di/walk_register_module.dart:10-25`, `walk/di/feature_walk.module.dart` |
| barrel | data 4개 · `WalkRegisterModule` 추가 export | `packages/features/walk/lib/feature_walk.dart:1-6` |
| ① 반영 | B1 · B3(위 ① 소견 표) | `route_preview.dart`, `save_walk_scenario.dart`, `update_walk_scenario.dart` |
| 테스트 | data **15개**(매퍼 1 · 강아지 레포 4 · 산책 레포 7 · 사진 3) + ① 반영 3개 → 패키지 전체 **42개** | `test/data/**` |

`bdb60c3` 에서 `flutter test` → `+42: All tests passed!`, `flutter analyze` → `No issues found!`.

테스트가 실제로 단언하는 것: 4행 × 빈 산책 묶기 · 정렬 · 중복 제거(`walk_mapper_test.dart:30-52`), 이름순 watch ·
수정 전파 · `findById` null(`drift_dog_repository_test.dart:28-66`), 4테이블 왕복 · 사진 정렬(`drift_walk_repository_test.dart:51-77`),
빈 산책도 나오는 최신순(`:79-92`), **이름 변경 전파 `['하늘', '바다']`**(`:94-110`), **cascade — pragma 를 빼면 실패하는
단언**(`:112-130`), update 범위(`:145-181`), 강아지 삭제 후 산책 유지(`:183-194`), 사진 저장 · `resolve` · 이중 `remove`.

### 설계 대비

기준은 [설계 스펙](../../../../docs/superpowers/specs/2026-10-03-walk-app-design.md) §3 · §5 와
[기획서](../overview.md) §7.

| 항목 | 스펙 · 기획 | 구현 | 판정 |
|---|---|---|---|
| 테이블 · 컬럼 · 키 | 스펙 §3 표 | 5테이블 컬럼 · pk · cascade · 인덱스 모두 일치(`tables.dart`) | 일치 |
| 시각 저장 | `build.yaml` 의 `store_date_time_values_as_text` | `build.yaml` 없이 런타임 `DriftDatabaseOptions(storeDateTimeAsText: true)`(`walk_database.dart:15-16`) | 다름 — 결과는 같다(ISO 텍스트). 스펙 §3 · §5 의 `build.yaml` 문구를 고칠 것 |
| `foreign_keys` | `beforeOpen` 에서 ON | `walk_database.dart:21-23` | 일치 — cascade 테스트가 증명 |
| 생일 | `TEXT yyyy-MM-dd`, `DateOnlyConverter` | 컨버터 대신 매퍼 함수(`walk_mapper.dart:14-17,23,33`) | 다름 — 무해. 시각 컬럼과 달리 시간대로 하루가 밀리지 않는다(`tables.dart:9`) |
| watch 조인 | 4테이블 LEFT JOIN, `started_at DESC, position`, id 로 중복 제거 | 그대로(`drift_walk_repository.dart:20-34`), 묶기는 삽입 순서 보존 `Map`(`walk_mapper.dart:84-125`) | 일치 — 강아지 이름순 정렬은 구현이 더함 |
| insert | 트랜잭션: walks → walk_dogs → points(batch, seq = 인덱스) → photos | 트랜잭션: walks → dogs · photos(batch) → points(batch)(`drift_walk_repository.dart:82-90`) | 일치 — 순서만 다르고 원자성은 같다 |
| update | 트랜잭션: walks 갱신, walk_dogs · walk_photos 지우고 다시 | `memo` · `updatedAt` 만 쓰고 연결 두 테이블 재삽입(`:101-115`) | 일치 — 인터페이스 주석(`walk_repository.dart:16`)과도 맞다 |
| 오류 변환 | 모든 메서드 `try/catch` → `Failure.unknown`, watch 는 `StreamTransformer` 로 `Err` | 그대로. 단 watch 의 매핑 예외는 빠진다 | **부분 — 소견 D1** |
| `FilePhotoStorage` | `save` · `resolve: String` · `delete`, 루트 `<documents>/pawlog_photos/` | ① 의 인터페이스대로 `store` · `File resolve` · `remove`. 폴더는 `store` 가 매번 `create(recursive)`(`file_photo_storage.dart:24`) | 일치(① 결정 계승) |
| 모듈 DB | `@lazySingleton @disposeMethod WalkDatabase database()` | `@disposeMethod` 없음(`walk_register_module.dart:12-13`) | **다름 — 소견 D2** |
| 모듈 사진 루트 | `@preResolve`, `Directory(...).create(recursive: true)` | 만들지 않고 경로만(`walk_register_module.dart:15-20`) | 다름 — `store` 가 만들므로 무해 |
| 모듈 `TileProvider` | `NetworkTileProvider()` lazySingleton | `walk_register_module.dart:22-24` | 일치 |
| barrel | 페이지 · `WalkUseCase` · 모듈 | data 구현 · `WalkDatabase` 까지 export | 다름 — 통근 barrel 관례(① 설계 대비)와 같다. 소견 D6 |

### 리뷰 소견

등급은 ① 과 같다. 번호는 ② 의 것(D = data).

#### B — 버그 · 잠재 결함

| # | 소견 | 위치 | 비고 |
|---|---|---|---|
| D1 | watch 의 `handleError` 는 원천(drift) 오류만 `Err` 로 바꾸고, `handleData` 안 매핑 예외는 출력 스트림의 날 오류가 됐다(`dart-sdk/lib/async/stream_transformers.dart:113-118`). drift 자체는 오류 뒤에도 스트림을 유지한다(`drift-2.34.4/.../stream_queries.dart:352-357`) | `drift_dog_repository.dart:23-30`, `drift_walk_repository.dart:46-52` | **반영됨**(`cdc1ac2`) — `handleData` 를 `try/catch`(`drift_dog_repository.dart:25-31`, `drift_walk_repository.dart:49-55`), 생일 `DateTime.tryParse`(`walk_mapper.dart:23`). 테스트(`drift_dog_repository_test.dart:69`)는 `tryParse` 경로만 지나 `catch` 자체는 미검증 |
| D2 | `WalkDatabase` 에 dispose 가 없었다 | `walk_register_module.dart:12-13` | **반영됨**(`cdc1ac2`) — `@LazySingleton(dispose: disposeWalkDatabase)`(`walk_register_module.dart:11-17`) |
| D3 | `WalkTracker` 등록처가 없어 `WalkUseCase` 를 resolve 할 수 없었다 | `feature_walk.module.dart:49-57` | **반영됨**(`cdc1ac2`) — `GeolocatorWalkTracker` 를 ⑤ 에서 당겨 등록(④ 절) |

#### R — 규칙 · 경계

| # | 소견 | 위치 | 의견 |
|---|---|---|---|
| D4 | drift · `dart:io` · path_provider 타입은 `data/` 와 `di/` 안에만 있다. domain 은 data 를 import 하지 않는다 | `walk/data/**`, `walk/di/walk_register_module.dart` | [아키텍처 ⑤](../../../../docs/architecture.md) 위반 없음 |
| D5 | `.g.dart` · 모듈은 생성 산출물. 오류 변환은 [아키텍처 ④](../../../../docs/architecture.md) 처럼 레포에서 끝난다 | `walk_database.g.dart`, `feature_walk.module.dart` | 위반 없음 |
| D6 | barrel 이 `WalkDatabase` 와 생성 행 타입(`DogRow` 등)까지 공개한다. 앱 · presentation 이 drift 타입을 import 할 길이 열린다 | `feature_walk.dart:1-4` | 통근도 data 를 export 하므로 관례 위반은 아니다. ③ 의 `package_boundary_test` 를 "앱이 `WalkDatabase` 를 import 하지 않는다" 까지 넓히면 막힌다 |

#### I — 개선 제안

1. **테스트 공백.** 스트림 오류 → `Err`(D1), `store` 실패 → `walkPhotoSaveFailed`
   (`file_photo_storage.dart:27-33`), 트랜잭션 롤백(없는 `dog_id` 로 insert → FK 위반 → walks 행도 없음),
   생일 깨진 값, `findById` 의 조인 경로(사진 · 강아지가 있는 단건)는 insert 테스트가 겸한다.
2. **update 가 남는 사진의 `created_at` 을 `walk.updatedAt` 으로 덮는다**(`drift_walk_repository.dart:111-114`,
   `photoToCompanion` `walk_mapper.dart:70-80`). 지우고 다시 넣는 방식의 부작용이다. 도메인이 이 컬럼을
   읽지 않아 지금은 무해하지만, 쓸 생각이 없다면 컬럼을 빼고, 쓸 거라면 남는 사진은 `UPDATE` 로.
3. **`started_at` 정렬이 텍스트 비교다.** drift 텍스트 모드는 로컬 시각을 `…+09:00` 처럼 오프셋과
   함께 쓴다(`drift-2.34.4/lib/src/runtime/types/mapping.dart:46-74`). 오프셋이 다른 기록(해외 · DST)이
   섞이면 실제 순서와 어긋날 수 있다. v1(한국 · DST 없음)은 무해. 같은 `started_at` 끼리의 순서도 정해지지
   않는다 — `walks.id` tie-break 를 더하면 피드가 흔들리지 않는다. **tie-break 반영됨**(`cdc1ac2`, `drift_walk_repository.dart:31`, 테스트 `:196`).
4. `FilePhotoStorage.store` 는 `FileSystemException` 만 잡는다(`:27`). `writeAsBytes` · `create` 의 IO 오류는
   모두 그 하위 타입이라 충분하다. `_ids.newId()` 가 `try` 밖이지만 던질 일이 없다. `remove` 는
   `existsSync` 동기 IO 후 모든 예외를 삼킨다(`:41-47`) — 계약(① I4)은 "없는 파일" 만 테스트됐다.
5. `walk_dogs.dog_id` 에 인덱스가 없어 강아지 삭제 cascade 가 `walk_dogs` 를 훑는다. v1 규모에서 무시 가능.

#### G — 괜찮은 점

- cascade 와 이름 변경 전파를 실제 DB 로 단언(`drift_walk_repository_test.dart:94-130`), 조인 묶기가 순서 · 중복 · 0마리 · 0장을
  모두 맞게 다루고(`walk_mapper.dart:89-118`), update 는 `WalksCompanion(memo, updatedAt)` 만 써서 구조적으로 범위를 지킨다.

### 다음 단계에 넘기는 것

| 단계 | 할 일 | 근거 |
|---|---|---|
| ③ ✓ | `externalPackageModulesBefore: [Core, FeatureWalk]` 순서로 `IdGenerator` 를 먼저 등록. microPackage 빌드가 `IdGenerator` 미등록 경고를 내도 런타임에는 Core 모듈이 준다 | `feature_walk.module.dart:40,55`, 스펙 §5 |
| ③ ✓ | `init` 이 `async`(preResolve) 가 됐으니 `configureDependencies` 를 `await` | `feature_walk.module.dart` `init(...) async` |
| ④ ✓ | `WalkTracker` 등록(D3) | D3 |
| ③ ✗ | `package_boundary_test` 에 "앱은 `WalkDatabase` · drift 를 직접 쓰지 않는다" 추가 고려 | D6 |
| ④ — | tracker 는 매핑 없이 상태를 직접 내므로 D1 류 구멍이 없다 | D1 |
| ④ ✓ | D1 이 레포에서 고쳐져 `WalkFeedCubit` 은 `Err` 값만 다루면 된다 | D1 |
| ⑧ | 스펙 §3 · §5 의 `build.yaml` · `DateOnlyConverter` · `photosRoot().create` · `@disposeMethod` 문구를 구현에 맞춘다(또는 D2 를 고친다) | 설계 대비 |

---

## ③ 앱 셸 (87c680d)

경로 접두 `apps/pawlog/` 는 생략한다. 비교 대상은 같은 커밋의 `apps/commute/`.

### 무엇이 들어왔나

| 묶음 | 내용 | 위치 |
|---|---|---|
| 부팅 | `main` → `bootstrap`(ensureInitialized → `await configureDependencies()` → `runApp(PawlogApp())`) | `lib/main.dart:3`, `lib/bootstrap.dart:6-10` |
| DI | `externalPackageModulesBefore: [Core, FeatureWalk]`, 생성물은 두 모듈 `init` 을 차례로 `await` | `lib/di/injection.dart:7-18`, `lib/di/injection.config.dart:20-28` |
| 앱 | `PawlogApp` 이 `FutureBuilder` 로 `getDogs()` 1회 → `createRouter(hasDogs)`, 그동안 스피너. `MaterialApp.router` + `AppTheme` · `AppLocalizations` · `walkAppTitle` | `lib/app/app.dart:17-59` |
| 라우터 | `GoRoute` **9개**(아래 설계 대비), 화면은 모두 `_Placeholder` + `TODO(phase ④~⑦)` | `lib/app/router/app_router.dart:6-81` |
| 리다이렉트 | `PawlogPaths` · `DogsRedirect(hasDogs)` — 0마리면 `/dogs` 로 시작하지 않는 경로를 `/dogs/new` 로, `markHasDogs()` | `lib/app/router/dogs_redirect.dart:1-28` |
| 플랫폼 | Android 권한 6개, iOS 위치 2 · 사진 · 카메라 문구 + `UIBackgroundModes: location` | `android/app/src/main/AndroidManifest.xml:2-7`, `ios/Runner/Info.plist:69-80` |
| 공용 패키지 | `AppAvatar.imageFile`(bytes > file > url), `ImagePickerService.captureImage` | `packages/design_system/lib/src/widget/app_avatar.dart:28-46`, `packages/core/lib/src/media/image_picker_service.dart:49-56` |
| 테스트 | 앱 **5개**(리다이렉트 4 · 경계 1), `AppAvatar` **3개** | `test/app/router/dogs_redirect_test.dart`, `test/convention/package_boundary_test.dart`, `packages/design_system/test/widget/app_avatar_test.dart` |

`87c680d` 를 깨끗한 worktree 로 꺼내 확인했다: 앱 `flutter test` → `+5: All tests passed!`,
`flutter analyze` → `No issues found!`, `app_avatar_test.dart` → `+3`, `core` analyze 통과.
Android · iOS 빌드는 이 환경에서 돌리지 않았다.

추적 파일 집합(png 제외)은 통근 앱과 **`settings_redirect` ↔ `dogs_redirect` 두 쌍 말고 같다.**

### 설계 대비

기준은 [설계 스펙](../../../../docs/superpowers/specs/2026-10-03-walk-app-design.md) §1 · §5 와 통근 앱 셸.

| 항목 | 스펙 | 구현 | 판정 |
|---|---|---|---|
| 부팅 순서 | `bootstrap` 이 `getDogs()` 1회 → `runApp(PawlogApp(hasDogs))` | 통근 앱과 같은 `FutureBuilder` 방식(`app.dart:18-27`, 통근 `apps/commute/lib/app/app.dart:18-27`) | 다름 — 선례를 따랐다. 오류 처리 구멍은 소견 S1 |
| DI 순서 | `[Core, FeatureWalk]` | 일치(`injection.dart:11-14`). `IdGenerator` 는 Core 가 먼저 준다 | 일치 — ② 다음 단계 표 두 줄 해소 |
| 경로 | 8개 | 8개 + **`/walks` 목록 자리표시**(`app_router.dart:27-31`) | **다름 — 소견 S2.** 커밋 메시지도 "8경로" |
| `/dogs/new` 순서 | `:id` 보다 먼저 | `app_router.dart:54-65`, 주석 포함 | 일치 |
| 경로 구조 | 정하지 않음 | `/walks/:id/edit` 는 `:id` 의 자식, `/walk/save` 는 `/walk` 와 형제(최상위) | 일치 — `pushReplacement('/walk/save')` 에 맞다 |
| 리다이렉트 | 0마리면 `/dogs/new` **외** 모든 경로를 보낸다 | `/dogs` 로 시작하는 경로는 모두 통과(`dogs_redirect.dart:21`) | **다름 — 소견 S3** |
| `markHasDogs` 연결 | `DogEditPage.onDone` 에서 | 통근 `markComplete` 처럼 `createRouter` 클로저에서 부를 자리가 있다(`app_router.dart:57` TODO, 통근 `app_router.dart:21-24`) | 일치 — ④ 몫 |
| 경계 테스트 | 통근 것 복사, `feature_` · `supabase_flutter` · `go_router` 없음 | 통근과 패키지 이름만 다르다 | 일치 |
| Android 권한 | INTERNET · FINE · COARSE · FOREGROUND_SERVICE · FOREGROUND_SERVICE_LOCATION · POST_NOTIFICATIONS, CAMERA 없음 | 일치(`AndroidManifest.xml:2-7`) | 일치 — 아래 소견 S5 |
| iOS | 위치 2 · 카메라 · 사진 · `UIBackgroundModes: [location]` | 일치(`Info.plist:69-80`) | 일치 |
| `AppAvatar` | `File? imageFile`, `imageBytes > imageFile > imageUrl` | 레코드 패턴 `switch`(`app_avatar.dart:39-46`) | 일치 |
| `captureImage` | `ImageSource.camera` → `prepare` | 같은 `requestFullMetadata: false` 로 `prepare` 재사용(`image_picker_service.dart:50-55`) | 일치 |

### 리뷰 소견

등급은 ① 과 같다. 번호는 ③ 의 것(S = shell).

#### B — 버그 · 잠재 결함

| # | 소견 | 위치 | 비고 |
|---|---|---|---|
| S1 | D3 때문에 `getIt<WalkUseCase>()` 가 던지고 `FutureBuilder` 가 `hasError` 를 보지 않아 부팅 스피너가 영원히 돌았다 | `app.dart:20-45` | **반영됨**(`cdc1ac2`) — D3 해소 + `snapshot.error` 를 `SelectableText` 로 표시(`app.dart:38-50`). l10n 전이라 원문 그대로인 것은 의도(주석). 통근 앱은 같은 구멍이 남아 있다 |
| S2 | 스펙에 없는 `/walks` 목록 경로가 있다. 피드(`/`)가 목록이라 페이지 표에도 없다. `/walks/:id` 를 자식으로 두려고 만든 부모로 보이는데, 그 부모가 화면을 가져 `/walks` 로 갈 수 있게 됐다 | `app_router.dart:27-31` | 부모 `builder` 대신 `redirect: (_, _) => PawlogPaths.feed` 로 막거나, `/walks/:id` 를 최상위로 두면 8개로 맞는다 **`93d722b`**: 부모에 redirect 를 더했으나 자식까지 막는 결함이 생겼다 → ⑥ W1, `d5f95b0` 에서 반영 |

#### R — 규칙 · 경계

| # | 소견 | 위치 | 의견 |
|---|---|---|---|
| S3 | 0마리일 때 `/dogs` 와 `/dogs/:id` 도 통과한다. 스펙은 `/dogs/new` 만 | `dogs_redirect.dart:21`, `dogs_redirect_test.dart:12-18` | 목록 → 추가로 가는 길이라 오히려 자연스럽다. 테스트도 이 의도로 썼다. **코드를 두고 스펙 §5 문구를 고치는 쪽을 권한다.** `startsWith('/dogs')` 는 `/dogsx` 도 통과시키지만 그런 경로는 없다 |
| S4 | `_Placeholder` 가 `Text` 하드코딩 영문 · 공통 위젯 미사용. [CLAUDE.md](../../../../CLAUDE.md) UI 규칙과 어긋나지만 TODO 로 표시된 임시물이다 | `app_router.dart:72-81` | ④~⑦ 에서 사라지는지만 본다. TODO 가 전부 "④~⑦" 이라 어느 단계 몫인지 흐리다 |
| S5 | `CAMERA` 를 선언하지 않은 것은 맞다 — image_picker 는 선언이 없으면 카메라 앱 인텐트로 동작하고, 선언하면 런타임 요청 의무가 생긴다. `ACCESS_BACKGROUND_LOCATION` 도 필요 없다 — geolocator 가 자기 매니페스트에 `foregroundServiceType="location"` 서비스를 선언한다(`geolocator_android-5.0.3/android/src/main/AndroidManifest.xml:5-8`). `POST_NOTIFICATIONS` 는 선언만 하고 요청하지 않으므로 Android 13+ 에서는 알림이 기본 거부다 — 스펙 §5 가 받아들인 결정 | `AndroidManifest.xml:2-7` | 위반 없음. ⑤ 에뮬레이터 검증 3번("알림이 보인다")은 Android 13+ 이미지에서 실패할 수 있으니 기대값을 맞춰 둘 것 |
| S6 | `design_system` 이 `dart:io` 를 import 하게 됐다(① R1 과 같은 결) | `app_avatar.dart:1` | 세 앱 모두 `android/` · `ios/` 만 있고 `web/` 이 없어 실제 문제는 없다. 공용 패키지라 web 을 열 때 걸림돌이 된다는 점만 기록 |

#### I — 개선 제안

1. **`flutter create` 템플릿 세대 차.** pawlog 는 더 새 Flutter(`.metadata` revision `5fc3468…`, 통근 `cc0734a…`)로 만들어져
   플랫폼 설정이 통근과 다르다(권한 외 차이는 아래가 전부).

   차이: AGP · Kotlin 플러그인 8.11.1 · 2.2.20 → **9.1.0 · 2.4.0**(`android/settings.gradle.kts:22-23`), Gradle 8.14 → **9.3.1**,
   `android.newDsl=false` · `android.builtInKotlin=false`(`android/gradle.properties:3-6`), `kotlin { compilerOptions }`,
   iOS 13.0 · CocoaPods → **15.0** · SwiftPM(`project.pbxproj`).

   각 앱의 Gradle · Xcode 프로젝트는 독립이라 **모노레포 빌드끼리 충돌하지는 않는다.** 위험은 둘이다:
   (a) AGP 9 에서 플러그인(drift 의 sqlite3 · geolocator · image_picker · path_provider)이 빌드되는지 아직
   아무도 확인하지 않았다 — 템플릿의 두 호환 플래그가 그 대비다, (b) 앱마다 JDK · Xcode 요구가 달라진다.
   ⑤ 에뮬레이터 검증 전에 `flutter build apk --debug` 를 한 번 돌리고, [공통 개발 환경](../../../../docs/setup.md)에
   앱별 툴체인 차이를 한 줄 남기자. 통근 · 트레이더를 올릴지는 따로 정한다.
2. **`AppAvatar` 테스트 방식.** 1×1 PNG 를 실제 파일로 쓰지만 단언은 provider 타입뿐이고, `FakeAsync` 안에서
   파일 디코드는 끝나지 않는다 — 실제 디코드를 검증하지는 않는다(`app_avatar_test.dart:27-39`). 타입 선택이
   목적이라면 충분하다. 다만 임시 파일을 지우지 않고(`:28`), 두 번째 테스트가 같은 경로를 쓴다(`:47`).
   네트워크 경우의 `tester.takeException()`(`:61`)은 반환값을 버린다 — `isA<NetworkImageLoadException>()` 로
   단언하면 "왜 삼키는가" 가 테스트에 남고, 오류 종류가 바뀌면 드러난다. 통과 자체는 허용할 만하다.
3. `captureImage` · `pickImages` 모두 `core` 테스트가 없다(`packages/core/test` 에 호출 없음). image_picker 를
   감싼 얇은 층이라 기존 관례와 같다.
4. `dogs_redirect_test` 는 `walk(id)` · `walkEdit(id)` · `saveWalk` 의 0마리 리다이렉트를 보지 않는다.
   `startsWith` 하나라 위험은 낮다.

#### G — 괜찮은 점

- 통근 셸과 파일 집합 · 부팅 · DI · 리다이렉트 모양이 같고, 권한 선언이 스펙 표와 정확히 같다. `AppAvatar` 우선순위는 레코드 `switch` 로 additive.

### 다음 단계에 넘기는 것

| 단계 | 할 일 | 근거 |
|---|---|---|
| ④ ✓ | D3 수정 · `hasError` 분기 | S1 |
| ④ ✓ | `onDone` → `markHasDogs()` → `canPop` 이면 `pop`, 아니면 `go(feed)`(`app_router.dart:11-18`). 0마리 `/dogs` 진입은 빈 상태 `AppPlaceholder` 가 감당 | S3 |
| ⑦ ✓ | `/walks` 부모 경로는 redirect 로 피드에 합쳤다 — 자식까지 막던 결함(⑥ W1)은 `d5f95b0` 에서 반영 | S2 |
| ⑤ W2 | 첫 실기기 빌드 전에 AGP 9 / iOS SwiftPM 빌드 확인, Android 13+ 알림 기대값 | I1, S5 |
| ⑧ | 스펙 §5 의 부팅 순서(`PawlogApp(hasDogs)`) · 리다이렉트 범위 문구를 구현에 맞춘다 | 설계 대비 |

---

## ④ tracker + W1 dog (cdc1ac2)

경로 접두 `packages/features/walk/lib/src/` 는 `walk/`, 테스트는 `test/`. 기준은 설계 스펙 §3 ·
[W2 계획](../features/tracking/plan.md) "추적기 계약" · [W1 계획](../features/dog/plan.md) ·
[CLAUDE.md](../../../../CLAUDE.md) UI 규칙. tracker 는 기획서 §8 의 ⑤ 몫이지만 D3 을 풀려고 앞당겼다.

### 무엇이 들어왔나

| 묶음 | 내용 | 위치 |
|---|---|---|
| 위치 | `LocationGateway` 인터페이스 + `GeolocatorGateway`(통근 것 + `positionStream` · `distanceBetween(GeoPoint, GeoPoint)`) | `walk/data/location/location_gateway.dart:7-39` |
| tracker | `GeolocatorWalkTracker`(`@LazySingleton(as: WalkTracker, dispose: disposeWalkTracker)`), `withClock` 생성자, 브로드캐스트 `states` | `walk/data/tracker/geolocator_walk_tracker.dart:17-208` |
| ②③ 반영 | D1 · D2 · D3 · S1 · id tie-break(위 각 절) | `drift_*_repository.dart`, `walk_register_module.dart`, `apps/pawlog/lib/app/app.dart` |
| W1 cubit | `DogListCubit.start()`(재구독) · `DogEditCubit`(`load` · `set*` · `setPhoto` · `save` · `delete` · `close` 정리), sealed `DogListState` · `DogEditState`(+`loadFailure`), 폼 `DogForm` | `walk/presentation/cubit/` |
| W1 페이지 | `DogListPage(onAddDog, onOpenDog)` · `DogEditPage({dogId, onDone})`, 위젯 키 8종 계획대로 | `walk/presentation/page/` |
| 앱 | `/dogs` · `/dogs/new` · `/dogs/:id` 연결, `finishDogEdit`, 피드 자리표시에 임시 "dogs" 버튼 | `apps/pawlog/lib/app/router/app_router.dart:11-18,66-83` |
| l10n | `walkDog*` 15키 × 3로케일, ko 15개 모두 `@` 설명 | `packages/l10n/lib/l10n/app_*.arb` |
| 테스트 | +35: tracker 12 · cubit 13(목록 3 · 편집 10) · 페이지 8(목록 3 · 편집 5) · 레포 2. `test/support/mock_walk_use_case.dart` · `pump_app.dart`(ko, `AppTheme.light`) | `test/data/tracker/`, `test/presentation/` |

`cdc1ac2` 를 깨끗한 worktree 로 확인: `feature_walk` `+77`, 앱 `+5`, `l10n` `+10`, 두 패키지 analyze 0건.
`git grep` 으로 `Colors.` · `BorderRadius.circular` · 숫자 `EdgeInsets` / `SizedBox` · `.when(` 을 찾았고 0건.

### 설계 대비

| 항목 | 기준 | 구현 | 판정 |
|---|---|---|---|
| `start` 순서 | 계약 표: 중복 → 서비스 → 권한(세션당 1회) → 구독 → `tracking(빈 세션)` | `geolocator_walk_tracker.dart:60-109`, `_requestDeclined` 는 통근과 같은 규칙(`:72-78`) | 일치 |
| await 뒤 경합 | 정하지 않음 | 권한 await 뒤 `tracking` 재확인(`:86-93`) | 일치(보강) — 테스트 없음 |
| 위치 수신 | `distanceBetween(직전, p)` → 정책 → 누적 | 첫 점 `step = 0`, 받아들인 점 기준 거리(`:151-165`), `recordedAt = position.timestamp`(`:148`) | 일치. `timestamp` 는 UTC, `startedAt` 은 로컬 `now` — 비교에 쓰지 않아 무해 |
| 스트림 오류 | 세션 유지 | `onError` → `debugPrint`(`:171-173`) | 일치 |
| `stop` 미추적 | `Err(walkNotFound)`, 스펙 §2 실패 표는 `notFound` 종류 | `Failure.validation(walkNotFound)`(`:178-181`) | **다름 — T4** |
| `clear` | `finished` 에서만 `idle` | `:197-201` | 일치(B2 반영) |
| 플랫폼 설정 | Android `accuracy: high`, iOS `best` · fitness · background | `defaultTargetPlatform` 분기, 둘 다 `best`, Android `intervalDuration: 2s` 추가, 그 외 플랫폼은 기본 설정(`:115-139`) | 다름 — Android 정확도 · 간격은 배터리 차이. ⑤ 실기기에서 고르면 된다 |
| `states` | "구독 즉시 현재값부터"(스펙 §2) ↔ "현재값을 먼저 내지 않는다. cubit 이 `trackerState` 를 먼저 읽는다"(W2 계획) | 순수 브로드캐스트(`:34-35,48`) | W2 계획과 일치, 스펙 §2 와 다름 — ⑧ 에서 스펙 정정 |
| dispose | 정하지 않음 | 등록 타입이 인터페이스라 최상위 함수로 타입 검사 후 `dispose()`(`:17-21,203-207`) | 일치 — 인터페이스를 넓히지 않은 선택이 깔끔하다 |
| W1 상태 | 계획 표(`loadFailure` 포함) | 그대로(`dog_edit_state.dart:10-24`) | 일치 |
| `DogListCubit.start()` | W1 계획 · 스펙 §4 모두 `start()` | `dog_list_cubit.dart:20-32` | 일치 — "`load()` 대신" 은 이탈이 아니다 |
| 사진 파일 규칙 1~3 | 즉시 저장 · 직전 새 파일 삭제 · 저장 안 하고 닫으면 삭제 | `dog_edit_cubit.dart:61-91,131-139` | 일치 — 경합 하나(T1) |
| `onDone` | `markHasDogs` → `pop` / `go('/')` | `app_router.dart:11-18` | 일치. 삭제 뒤에도 `markHasDogs` 를 부르는 것은 무해(마지막 강아지 삭제는 §9 남은 판단) |
| 카메라 | 범위 밖(앨범 한 장) | `pickImage()` 만(`dog_edit_page.dart:57-76`) | 일치 |

### 리뷰 소견

번호는 ④ 의 것(T). T1 · T2 · T4 · I1 은 `93d722b` 에서 반영됐다.

#### B — 버그 · 잠재 결함

| # | 소견 | 위치 | 비고 |
|---|---|---|---|
| T1 | 사진 저장 중 `save()` 경합 — 늦게 온 `setPhoto` 가 `isSaving` 을 덮고, 저장된 강아지와 무관한 새 파일이 고아로 남았다 | `dog_edit_cubit.dart:61-108` | **반영됨**(`93d722b`) — await 뒤 `_cannotAcceptPhoto`(닫힘 · 비편집 · 저장 중)면 새 파일을 지우고 끝(`dog_edit_cubit.dart:62,74,149-152`), 테스트 `dog_edit_cubit_test.dart:199`. 대가: 저장 직전에 고른 사진은 **조용히 빠진다** — 사진 고르기 UI 가 앞을 가려 실제로 겹치기 어렵고, 고아 파일보다 낫다. 받아들일 만하다 |
| T2 | 수정 화면 제목 · 메뉴가 `form?.id` 기준이라 로딩 · `loadFailure` 중 "등록" 으로 보였다 | `dog_edit_page.dart:137` | **반영됨**(`93d722b`) — `isEdit: dogId != null`(`dog_edit_page.dart:23,138`), 로딩 중 제목 테스트(`dog_edit_page_test.dart:62`) |

#### R — 규칙 · 경계

| # | 소견 | 위치 | 의견 |
|---|---|---|---|
| T3 | UI 규칙 준수: `AppListTile` · `AppAvatar` · `AppPlaceholder`(빈 · 실패 · loadFailure) · `AppOverflowMenu` · `AppConfirmDialog`(기본 파괴적) · `AppSnackBar` · `AppButton`. 상태 분기는 전부 `switch`, 모든 await 뒤 `isClosed`, `close()` 에서 구독 해제(`dog_list_cubit.dart:36-40`) | `walk/presentation/**` | 위반 없음. 단 아바타 크기에 여백 토큰을 쓴다(`radius: AppSpacing.lg`, `AppSpacing.xl * 2` — `dog_list_page.dart:82`, `dog_edit_page.dart:218`). 크기 토큰이 없어서이지만 의미가 어긋난다 → `AppAvatar` 에 크기 프리셋을 두는 쪽을 설계 §7 후보로 |
| T4 | 미추적 `stop` 이 `Failure.validation(walkNotFound)` 이었다(스펙은 `notFound`) | `geolocator_walk_tracker.dart:178-181` | **반영됨**(`93d722b`) — `Failure.notFound` |
| T5 | `photoFile` 을 cubit 이 위임한다 | `dog_list_cubit.dart:34`, `dog_edit_cubit.dart:128` | 괜찮다 — 페이지가 `getIt<WalkUseCase>()` 를 직접 잡지 않게 하는 통로라 [아키텍처 ③](../../../../docs/architecture.md)과 맞는다. 매 빌드 `File` 을 새로 만들지만 `FileImage` 는 경로로 같음을 판단해 다시 읽지 않는다 |
| T6 | `saved` · `deleted` 가 `SizedBox.shrink` | `dog_edit_page.dart:165-166` | 괜찮다 — listener 가 같은 프레임에 `onDone` 으로 떠난다. AppBar 는 남아 깜빡임도 작다 |

#### I — 개선 제안

1. ~~`setBirthday` · `_withPhoto` 를 손으로 생성~~ — Freezed `copyWith` 는 nullable 에 `null` 을 받는다. **반영됨**(`93d722b`, `copyWith` 로)
2. **테스트 공백.** tracker: await 뒤 경합 가드(`:86-93`), 권한 요청 후 허용 경로, `catch` → `unknown`,
   `dispose`. cubit: `setPhoto` 실패(`walkPhotoSaveFailed`), `delete` 실패, `load` 의 `Err`, 수정 폼에서
   새 사진을 고른 뒤 닫을 때 **원래 사진은 남는지**(현재 테스트는 신규 폼만). 페이지: 사진 버튼 흐름
   (`_pickPhoto`, `prepare` 예외 → 스낵바)이 없다 — `ImagePickerService` 를 mocktail 로 `getIt` 에 넣으면
   된다. 계획의 "닫힌 뒤 스트림 값" 은 있다(`dog_list_cubit_test.dart:43`).
3. `DogListPage` · `DogEditPage` 로딩이 맨 `CircularProgressIndicator` 다. 공통 로딩 위젯이 없어 규칙 위반은
   아니지만 세 앱에서 반복된다 — `design_system` 승격 후보.
4. 품종이 공백만이면 `toDraft()` 가 `"  "` 를 넘긴다(`dog_form.dart:46`). ① I5 와 같은 결 — trim 을 폼이나
   시나리오 한 곳에서.

#### G — 괜찮은 점

- 사진 파일 규칙을 cubit `close()` 한 곳에 모아 뒤로 가기 · 삭제 · 저장 실패가 모두 같은 길을 탄다
  (`dog_edit_cubit.dart:131-139`). `setPhoto` 가 await 뒤 `isClosed` 면 **방금 쓴 파일까지** 지운다(`:69-74,82-85`).
- tracker 가 권한 await 뒤 상태를 다시 보고, `_emit` 이 닫힌 컨트롤러를 피한다(`:50-53`). 플랫폼 설정 테스트가
  `debugDefaultTargetPlatformOverride` 로 Android · iOS 설정 객체를 실제로 꺼내 본다(`geolocator_walk_tracker_test.dart:124-142`).
- 스낵바 `listenWhen` 이 "새 실패" 만 골라(`dog_edit_page.dart:109-116`) 같은 실패를 재빌드마다 띄우지 않는다.
- ②③ 소견 다섯 건을 테스트와 함께 반영했고, 커밋 메시지에 소견 번호를 남겼다.

### 다음 단계에 넘기는 것

| 단계 | 할 일 | 근거 |
|---|---|---|
| ⑤ ✓ | `ActiveWalkCubit.load()` 가 구독을 먼저 걸고 `trackerState` 를 읽는다 | ⑤ 설계 대비 |
| ⑤ ✓ | `finished` 재진입 → `stopped` → 저장 폼(화면 수준). tracker 자체는 여전히 허용 | 열린 질문 1 |
| ⑤ ✗ | 실기기 Android `accuracy` · `intervalDuration`, AGP 9 빌드 — 에뮬레이터 검증으로 넘김 | 설계 대비 |
| ⑥ ✓ | T1 · T2 · T4 · I1 (`93d722b`) | T1 · T2 · T4 |
| ⑥ ✓ | 수정 모드는 `discardWalk` 를 부르지 않는다(`walk_edit_cubit.dart:174-185`). 사진 경합은 T1 과 같은 가드(`:109-123`) | B2, T1 |
| ⑧ | 스펙 §2 `states` 문구, W1 계획의 생일 지우기 여부 | 설계 대비, I1 |

---

## ⑤ W2 tracking 화면 (4627805)

경로 접두는 ④ 와 같다. 기준은 [W2 계획](../features/tracking/plan.md)(상태 표 · 상태 규칙 · `RouteMap` ·
`WalkFormat` · 테스트 표)과 설계 스펙 §4.

### 무엇이 들어왔나

| 묶음 | 내용 | 위치 |
|---|---|---|
| cubit | `ActiveWalkCubit`(`withClock`) — `load` · `toggleDog` · `start(notice)` · `stop` · `retry`, 1초 타이머 | `walk/presentation/cubit/active_walk_cubit.dart:15-193` |
| 상태 | sealed `loading` · `selectingDogs` · `starting` · `tracking(session, elapsed)` · `stopped` · `failure(failure, dogs, selectedIds)` | `active_walk_state.dart:9-39` |
| 위젯 | `RouteMap`(flutter_map, follow, 빈 점 안내) · `WalkStatsRow` · `DogChips` | `walk/presentation/widget/` |
| 포맷 | `WalkFormat.distance` · `duration` · `clock` | `walk/presentation/format/walk_format.dart:4-26` |
| 페이지 | `ActiveWalkPage({onStopped, onOpenDogs})` | `walk/presentation/page/active_walk_page.dart:17-165` |
| 앱 | `/walk` 연결(`onStopped → go(saveWalk)`), 피드 자리표시에 임시 "walk" 버튼 | `apps/pawlog/lib/app/router/app_router.dart:29,35-38` |
| l10n | `walk*` 19키 × 3, 숫자 자리표시자 `placeholders` 타입 명시(`meters` · `minutes` · `hours` int, `km` String) | `app_ko.arb` |
| 테스트 | +27: cubit 11(`fakeAsync` 1 포함) · 포맷 7 · 페이지 9, `StubTileProvider`(1×1 투명 PNG), `fake_async` dev 의존 | `test/presentation/{cubit,format,page}/`, `test/support/stub_tile_provider.dart` |

`4627805` 를 깨끗한 worktree 로 확인: `feature_walk` `+104`, 앱 `+5`, `l10n` `+10`, analyze 0건,
`Colors.` · `BorderRadius.circular` · 숫자 여백 · `.when(` grep 0건.

### 설계 대비

| 항목 | 계획 | 구현 | 판정 |
|---|---|---|---|
| 상태 집합 | 표에 `loading` 없음 | `loading` 추가(`active_walk_state.dart:11-12`) — 초기 상태가 필요하다 | 다름 — 무해, 계획 표에 한 줄 |
| `starting` · `failure` 의 선택 | `failure` 가 선택을 들고 있어야 재시도 | `starting` 도 `dogs` · `selectedIds` 를 든다(`:20-23`). 실패 시 그대로 넘긴다(`active_walk_cubit.dart:86-87`) | 일치(보강) |
| 진입 | `trackerState` 를 먼저 본 뒤 구독 | **구독을 먼저 걸고** 현재값을 읽는다(`:36-45`) — 브로드캐스트 사이 틈을 막는 더 나은 순서 | 일치(보강) — ④ 다음 단계 표 해소 |
| 재진입 | `tracking` → 바로 추적, `finished` → `stopped` | `:38-44`, 테스트 2개 | 일치. 열린 질문 1 을 **화면 수준에서** 닫는다 |
| `retry` | 선택 있으면 `start(notice)`, 없으면 `load()` | 기억한 `_notice` 로(`:106-116`). `stop` 실패도 `failure([], {})` → `load()` 가 추적 상태를 다시 읽는다(`:101-102`) | 일치 |
| 타이머 | `tracking` 일 때만, 벗어나거나 `close()` 에서 취소, 다시 계산 | `_timer ??=`(`:154`), `stopped` · `failure` · `close` 에서 취소(`:166,172,189`), `elapsedAt(now)`(`:161`) | 일치 — `fakeAsync` 테스트가 1 · 2 · 3초와 `close` 뒤 정지를 본다 |
| `stopped` 한 번 | 구독 · `stop()` 중 먼저 온 쪽 | `_emitStopped` 가드(`:165-169`) + `listenWhen`(`active_walk_page.dart:59-60`) | 일치 |
| `onStopped` | `pushReplacement(saveWalk)` | **`go(saveWalk)`**(`app_router.dart:36`) | **다름 — 소견 V1** |
| `RouteMap` 생성자 · 레이어 | 계획 표 | 그대로. `tileProvider ?? getIt<TileProvider>()`(`route_map.dart:87`), `userAgentPackageName: 'com.karma.pawlog'`, `SimpleAttributionWidget` | 일치 |
| 첫 화면 · 추종 | `CameraFit.coordinates`, 점 1개면 줌 17, `didUpdateWidget` 에서 `move(last, 현재 줌)` | `route_map.dart:40-50,73-82`. 한 장소에 몰린 점도 "점 1개" 로 취급(`:69`) | 일치(보강) |
| `WalkFormat` | 999 · 1000 · 1250 m, 59 · 65분, `07:05` · `1:02:03` | 모두 테스트(`walk_format_test.dart`), 999.6 m → `1.0 km` 경계도 | 일치 |
| 위젯 키 | 7종 | `walk-active-retry` 없음 | 다름 — `AppPlaceholder.actionKey` 는 `93d722b` 에 들어왔지만(`app_placeholder.dart`, 테스트 `app_placeholder_test.dart:58`) 진행 화면 연결은 **반영됨**(`b4abf9c`, `active_walk_page.dart:156`) |
| 플랫폼 설정 | Android `high` | ④ 그대로 `best` + 2초 간격 | 다름 — 실기기 검증 때 정한다(④ 설계 대비) |

### 리뷰 소견

번호는 ⑤ 의 것(V).

#### B — 버그 · 잠재 결함

| # | 소견 | 위치 | 비고 |
|---|---|---|---|
| V1 | `onStopped → go(saveWalk)` 가 피드를 스택에서 지워 저장 폼의 뒤로 가기가 앱을 닫았다(go_router 로 재현: `canPop() == false`) | `app_router.dart:36` | **반영됨**(`93d722b`) — `pushReplacement`, 이유 주석 |
| V2 | 0마리 안내에서 반려견을 등록하고 돌아와도 `getDogs()` 한 번뿐이라 안내가 그대로였다 | `active_walk_cubit.dart:118-133` | **반영됨**(`d5f95b0`) — `watchDogs()` 구독(`active_walk_cubit.dart:123-162`), 테스트 `active_walk_cubit_test.dart:72`. 판단은 ⑦ 절 |

#### R — 규칙 · 경계

| # | 소견 | 위치 | 의견 |
|---|---|---|---|
| V3 | 상태 분기 전부 `switch`, await 뒤 `isClosed`, `close()` 에서 타이머 · 구독 해제, 공통 위젯(`AppPlaceholder` · `AppButton` · `AppConfirmDialog(isDestructive: false)` · `AppAvatar`) | `walk/presentation/**` | 위반 없음. ④ T3 처럼 크기에 여백 토큰을 쓴다 — 선 굵기 `AppSpacing.xs`, 마커 · 아이콘 `AppSpacing.md/lg/xl`(`route_map.dart:93,102-117`), 칩 아바타 `AppSpacing.md`(`dog_chips.dart:35`) |
| V4 | `RouteMap` 이 `getIt<TileProvider>()` 를 위젯 안에서 푼다 | `route_map.dart:87` | 계획대로이고 인자로 덮을 수 있어 받아들일 만하다. 위젯이 서비스 로케이터를 아는 첫 사례라, W3 · W4 에서 또 늘면 페이지가 넘기는 쪽으로 |
| V5 | OSM 출처가 `'OpenStreetMap contributors'` 로 `©` 가 빠졌다 | `route_map.dart:123-125` | OSM 저작자 표시 지침은 "© OpenStreetMap contributors". 고유명이라 l10n 대상은 아니다 |
| V6 | `stopped` 가 `SizedBox.shrink` | `active_walk_page.dart:71` | ④ T6 과 같이 괜찮다 — 같은 프레임에 `onStopped` 로 떠난다 |

#### I — 개선 제안

1. **테스트 공백.** `RouteMap` 의 추종(`didUpdateWidget` → `move`)과 `CameraFit` 이 테스트되지 않았다 —
   `MapController` 는 위젯 내부라 `tester.widget<FlutterMap>` 의 `options` 정도만 볼 수 있다. 추적 중 새 점이
   스트림으로 와서 `tracking(session')` 으로 바뀌는 경로(타이머 중복 생성 없음)도 cubit 테스트에 없다.
   페이지는 권한 거부 재시도를 보지만 **서비스 꺼짐**(안내 문구 없음 분기)은 없다. 계획 표의 나머지는 모두 있다.
2. `WalkFormat.duration` 은 정확히 60분이면 `1시간 0분`, 1분 미만이면 `0분` 이다(`walk_format.dart:13-15`). 카드(W4)에서
   어색하면 `분 == 0` 이면 `walkDurationHours`, 1분 미만은 `1분 미만` 같은 키를 두자.
3. `CameraFit.coordinates` 에 `maxZoom` 이 없어, 몇 m 떨어진 두 점으로 다시 들어오면 OSM 타일 최대 줌(19)을 넘겨
   흐릿하게 확대된다(`route_map.dart:78-81`). `maxZoom: _singlePointZoom` 정도로 막으면 된다.
4. 타이머 테스트는 `close` 뒤 정지만 본다. `stopped` 로 바뀐 뒤 `async.pendingTimers` 가 비는지도 보면
   `_cancelTimer` 누락을 잡는다.

#### G — 괜찮은 점

- 구독 먼저 · 현재값 나중 순서와 `start` 결과 · 스트림 중 먼저 온 쪽을 받아들이는 처리(`:79-85`)로 브로드캐스트
  스트림의 틈을 정확히 메웠다.
- `fakeAsync` + `async.getClock(t0)` 로 타이머와 시계를 한 번에 돌려 "틱 누적 금지" 를 실제로 검증한다
  (`active_walk_cubit_test.dart:253-278`).
- `StubTileProvider` 로 지도 페이지 테스트가 네트워크를 타지 않는다(설계 §4 요구).
- 알림 문구를 페이지가 l10n 으로 만들어 넘겨 cubit 이 로케일을 모른다(`active_walk_page.dart:104-109`).

### 다음 단계에 넘기는 것

| 단계 | 할 일 | 근거 |
|---|---|---|
| ✓ | ④ T1 · T2 · T4 · I1, `AppPlaceholder.actionKey`(`93d722b`), `walk-active-retry` 연결(`b4abf9c`, `active_walk_page.dart:156`) | ④, 위젯 키 |
| ⑥ ✓ | `onStopped` → `pushReplacement`(V1). 저장 뒤 `go(feed)` + `push(walk(id))` 스택도 go_router 로 확인: `[/, /walks/w1]`, 뒤로 → 피드 | V1 |
| ⑦ ✓ | 0마리 안내 복귀 갱신(V2) | V2 |
| ⑦ △ | 피드 FAB 는 `finished` 면 숨기고 배너가 저장 폼으로(✓). `WalkFormat.duration` 경계(I2)는 그대로 | I2, 열린 질문 1 |
| 에뮬레이터 | Android `accuracy` · 간격, `©` 표기, 실제 추종 · 줌 | ④ 설계 대비, V5, I3 |

---

## ⑥ W3 record 화면 (93d722b)

기준은 [W3 계획](../features/record/plan.md). 경로 접두는 ④ 와 같다.

### 무엇이 들어왔나

| 묶음 | 내용 | 위치 |
|---|---|---|
| 폼 | `WalkEditForm`(신규 = `session`, 수정 = `existing`), `addedPhotoPaths` · `toDraft` · `toUpdate`(메모 trim → 빈 값 `null`), `maxPhotos = 10` | `walk/presentation/cubit/walk_edit_form.dart:14-93` |
| 편집 | `WalkEditCubit` — `loadNew` · `loadExisting`(레코드 `.wait`) · `toggleDog` · `setMemo` · `addPhotos` · `removePhoto` · `save` · `discard` · `close` 정리, 상태에 `loadFailure` | `walk_edit_cubit.dart:14-213`, `walk_edit_state.dart` |
| 상세 | `WalkDetailCubit` — `getWalk` + `getWalkTrack` 동시, 내용이 떠 있으면 `loading` 없이 재조회, 삭제 실패는 `loaded(failure)` | `walk_detail_cubit.dart:10-65` |
| 페이지 | `WalkEditPage({walkId, onSaved, onDiscarded})`(신규만 `PopScope`), `WalkDetailPage({walkId, onEdit, onDeleted})` | `walk/presentation/page/` |
| 위젯 | `PhotoStrip` · `PhotoSourceSheet` · `WalkPhotoGrid` · `DogAvatars`, `DogChips.keyPrefix` | `walk/presentation/widget/` |
| 앱 | `/walk/save` · `/walks/:id` · `/walks/:id/edit` 연결, `/walks` 부모에 route-level redirect | `apps/pawlog/lib/app/router/app_router.dart:38-87` |
| 그 외 | ④⑤ 소견 반영(위), `AppPlaceholder.actionKey`, l10n `walk*` 약 20키(ko `@walk*` 35 → 56) | — |
| 테스트 | +46(패키지 `+150`). `test/support/mock_image_picker_service.dart` | `test/presentation/{cubit,page}/` |

`93d722b` worktree: `feature_walk` `+150`, `design_system` `+42`, 앱 `+5`, analyze 0건, 토큰 · `.when(` grep 0건.

### 설계 대비

| 항목 | 계획 | 구현 | 판정 |
|---|---|---|---|
| 신규 · 수정 | 한 페이지 두 모드, 신규 `loadFailure` 는 "저장할 산책 없음" + 피드로 | `walk_edit_page.dart:183-193` | 일치 |
| 사진 규칙 1~3 | 즉시 저장, **이번 폼 추가분만** 즉시 삭제, 기존은 `UpdateWalkScenario` 몫, 10장 상한, `close()` 에서 추가분 삭제 | `walk_edit_cubit.dart:96-150,190-201`. 늦게 도착한 사진은 상태 재확인 후 파일 삭제(`:109-123`) | 일치 — 아래 "저장 중 닫힘" 만 다름 |
| 저장 중 닫힘 | 규칙 3: `saved` · `discarded` 아니면 삭제 | `isSaving` 이면 **지우지 않는다**(`:189-195`) | 다름 — 소견 W2 |
| 수정 모드 `discard` | `discardWalk` 를 부르지 않는다 | `if (!form.isNew) return`(`:178`), 페이지에 버리기 버튼 없음 | 일치(① B2 잔여 해소) |
| 뒤로(신규) | `PopScope(canPop: false)` → 버리기와 같은 확인 | `walk_edit_page.dart:161-168`, 저장 중에는 조용히 무시 | 일치 |
| 이동 | 신규 저장 `go(feed)` + `push(walk(id))`, 버리기 `go(feed)`, 수정 `pop`, 삭제 `canPop ? pop : go(feed)` | 그대로(`app_router.dart:44-87`) | 일치 — 단 `/walks/:id` 가 열리지 않는다(W1) |
| 상세 재조회 | 수정에서 돌아오면 다시 읽기 | `onEdit` Future 를 기다린 뒤 `load`(`walk_detail_page.dart:56-61`), 내용이 있으면 `loading` 생략(`walk_detail_cubit.dart:19-21`) | 일치(보강) — 깜빡임 없이 바뀌는 쪽이 낫다 |
| 실패 반복 | — | `addPhotos` 시작 때 이전 `failure` 를 비워(`:100`) 같은 실패도 다시 스낵바 | 일치(보강) — bloc 의 같은 상태 무시를 정확히 피했다 |
| 사진 원천 | `ImagePickerService` 는 탭할 때 | `getIt` 을 탭 시점에 푼다(`walk_edit_page.dart:109`), 카메라는 `[?await captureImage()]` | 일치 |

### 리뷰 소견

번호는 ⑥ 의 것(W).

| # | 등급 | 소견 | 위치 | 의견 |
|---|---|---|---|---|
| W1 | **B** | `/walks` 부모 redirect 가 `matchedLocation`(부모 자신)을 비교해 상세 · 수정까지 피드로 보냈다(go_router 로 재현) | `app_router.dart:56-58` | **반영됨**(`d5f95b0`) — `state.uri.path` 비교(`app_router.dart:59`). 같은 확인을 다시 돌렸다: `/walks` → `/`, `/walks/w1` · `/walks/w1/edit` 은 그대로. 실제 `createRouter` 로 같은 세 경로와 첫 실행 리다이렉트를 보는 앱 테스트 4개(`b4abf9c`, `apps/pawlog/test/app/router/app_router_test.dart:88-121`) |
| W2 | I | 저장 중 닫히면 추가 사진을 지우지 않아, 닫힌 뒤 저장이 **실패**하면 고아가 남았다 | `walk_edit_cubit.dart:152-170,189-201` | **반영됨**(`b4abf9c`) — `isClosed` 면 `Err` 일 때만 `addedPhotoPaths` 삭제(`walk_edit_cubit.dart:161-169`), 성공 · 실패 테스트 2개 |
| W3 | R | 사진 빼기 버튼에 의미 라벨이 없었다 | `photo_strip.dart:114-129` | **반영됨**(`b4abf9c`) — `Semantics(label: walkRemovePhoto)` + `Tooltip`(`photo_strip.dart:121-126`), 테스트 `photo_strip_test.dart:10`. 터치 영역이 작은 것은 그대로 |
| W4 | R | `cacheWidth` 가 고정값(`400`, `tileSize * 2`)이었고 scrim `0.6` · 지도 높이 `AppSpacing.xl * 8` 이 이름 없는 수치였다 | `walk_photo_grid.dart:36`, `photo_strip.dart:104,122`, `walk_detail_page.dart:169` | **반영됨**(`b4abf9c`) — `cacheWidth` 는 칸 크기 × 기기 배율(`walk_photo_grid.dart:43`, `photo_strip.dart:108`), `_scrimAlpha` 이름, 지도 높이엔 이유 주석. 크기 토큰 부재 자체는 열린 항목(전체 요약) |
| W5 | G | `Card` 를 쓰지 않았고 공통 위젯(`AppConfirmDialog` · `AppOverflowMenu` · `AppPlaceholder` · `AppSnackBar` · `AppListTile` · `AppButton`)만 썼다. `+n` 칩만 `CircleAvatar` — `AppAvatar` 로는 표현할 수 없어 타당한 예외 | `dog_avatars.dart:68-81` | 위반 없음 |
| W6 | G | 늦게 도착한 사진 · 닫힘 · 저장 · 버리기 경합을 모두 상태 재확인 한 줄로 막고, 각 경우를 테스트했다(`walk_edit_cubit_test.dart:375,471`) | `walk_edit_cubit.dart:109-123` | ④ T1 수정과 같은 모양으로 일관된다 |

**테스트 공백**: 저장 중 닫힘 · 라우터 연결 · `DogAvatars` `+N`(`dog_avatars_test.dart:12,26`)은 `b4abf9c` 에서 채워졌다.
남은 것은 카메라 경로(`PhotoSource.camera`)와 0마리 산책(강아지 삭제 후)의 상세 표시. 계획 표의 나머지는 모두 있다.

### 다음 단계에 넘기는 것

| 단계 | 할 일 | 근거 |
|---|---|---|
| ✓ | `/walks` redirect 를 `uri.path` 비교로(W1, `d5f95b0`), 앱 라우터 테스트(`b4abf9c`) | W1 |
| ⑦ ✓ | `WalkCard` 탭 → `push(walk(id))`, `DogAvatars` 재사용 | W1 |
| ✓ | W2 · W3 · W4, `walk-active-retry`(`b4abf9c`) | W2 · W3 · W4 |

---

## ⑦ W4 feed 화면 (d5f95b0)

기준은 [W4 계획](../features/feed/plan.md). 이 커밋으로 8경로가 모두 실제 페이지가 됐고 `_Placeholder` · TODO 가 사라졌다.

### 무엇이 들어왔나

| 묶음 | 내용 | 위치 |
|---|---|---|
| cubit | `WalkFeedCubit` — `start`(추적 구독 → 현재값 → 산책 구독) · `retry`(산책만 재구독) · 마지막 `walks` · `tracker` 합치기 | `walk/presentation/cubit/walk_feed_cubit.dart:13-77` |
| 페이지 | `WalkFeedPage({onStartWalk, onSaveWalk, onOpenWalk, onOpenDogs})` — 배너 · 카드 목록 · FAB · 빈 상태 · 실패 | `page/walk_feed_page.dart:16-151` |
| 위젯 | `WalkCard`(`Card` + `InkWell`), `RoutePreviewPainter`, `ActiveWalkBanner.tracking/.unsaved` | `widget/` |
| ⑤⑥ 반영 | V2(`watchDogs`), W1(`uri.path`) — 위 각 절 | `active_walk_cubit.dart:123-166`, `app_router.dart:59` |
| 그 외 | l10n 6키, 위젯 키 5종 계획대로, 테스트 +22(패키지 `+172`) | — |

`d5f95b0` worktree: `feature_walk` `+172`, 앱 `+5`, analyze 0건, 하드코딩 색 · 반경 · 여백 · `.when(` · `_Placeholder` · `TODO` grep 0건.

### 설계 대비 · 판단

| 항목 | 계획 | 구현 · 판단 |
|---|---|---|
| 시작 순서 | `trackerState` 를 먼저 읽고 구독 | 구독 먼저 · 현재값 나중(`walk_feed_cubit.dart:29-32`) — ⑤ 와 같은 더 나은 순서. 목록 전 `tracker` 변화는 보관만 하고 `loading` 유지, 첫 `loaded` 에 반영(테스트 `walk_feed_cubit_test.dart:96`). **일치** |
| 배너 · FAB | `idle` 시작 / `tracking` 계속 + 배너 / `finished` 저장 배너 + FAB 숨김 | 그대로(`walk_feed_page.dart:73-85,142-150`). 빈 피드 + `finished` 에서 시작 버튼도 숨긴 것(`:111-113`)은 계획 표엔 없지만 "저장 · 버리기 전에 새 산책 없음" 규칙을 일관되게 지킨 것 — **타당**. 열린 질문 1 이 피드에서도 닫혔다 |
| 배너 경과 시간 | 새 점이 올 때만 갱신(타이머 없음) | `session.elapsedAt(DateTime.now())` 를 빌드 때 계산(`:146`). 계획대로지만, 서 있으면 점이 안 와 시간이 멈춘 듯 보인다 — 의도된 절충 |
| `retry` · `close` | 산책 구독만 재구독, 두 구독 해제 | 일치. 단 `_watchWalks` 가 이전 구독 `cancel` 을 기다리지 않는 이유가 "위젯 테스트의 가짜 비동기" 라고 적혀 있다(`:41-42`) — `cancel()` 은 호출 즉시 전달을 멈추므로 동작은 맞지만, **테스트 사정으로 제품 코드를 바꾼 것** 은 주석보다 테스트 쪽(`runAsync` 등)에서 푸는 편이 낫다 |
| 카드 통계 | `WalkStatsRow` 압축형 | 한 줄 `Text`(`walk_card.dart:64-68`) — **더 낫다.** `WalkStatsRow` 는 값에 `walk-active-*` 키를 달아 카드마다 키가 겹친다 |
| 카드 바탕 | — | `Card` + `InkWell` 예외, 이유 주석(`walk_card.dart:13-14`). 공통 카드가 없고 한 곳뿐이라 CLAUDE.md 예외 조건에 맞다 |
| 썸네일 | 첫 사진, 실패 시 경로 썸네일, 점 2개 미만이면 아이콘 | 일치(`:105-125`), `cacheWidth` 는 기기 배율 반영. `errorBuilder` 경로는 미검증 |
| 날짜 | `core` 의 `displayDateTime` | 일치 |
| V2 방식 | — | `watchDogs()` 첫 값을 기다리고(`Completer`), 새 강아지는 자동 선택 · 해제는 유지 · 삭제는 제외(`:135-162`), 시작 · 추적 · 종료 · 닫힘에서 해제. `unawaited(_cancelDogs())` 는 필드를 먼저 비우고 `_onDogs` 가 상태로 거르므로 안전하다. 첫 값 전에 닫히면 `load()` Future 가 끝나지 않지만 아무도 기다리지 않아 무해 |

### 리뷰 소견

번호는 ⑦ 의 것(F).

| # | 등급 | 소견 | 위치 | 의견 |
|---|---|---|---|---|
| F1 | **B**(표시) | 경로 썸네일이 위도 · 경도 각도를 같은 비율로 그려 동서로 약 1.26배 늘어났다(위도 37.5° 에서 cos ≈ 0.79) | `route_preview_painter.dart:41-58` | **반영됨**(`a6fc098`) — 경도에 `cos(평균 위도)` 를 곱한다(`route_preview_painter.dart:43`). 0 나눗셈 방어는 그대로 유지. 가로세로 비를 단언하는 테스트는 없다 |
| F2 | R | 수치 하드코딩이 늘었다 — 썸네일 `88.0`(`walk_card.dart:27`), 선 굵기 `3.0`(`route_preview_painter.dart:18`), FAB 여백 `AppSpacing.xl * 3`(`walk_feed_page.dart:120`) | 각 위치 | `b4abf9c` 에서도 그대로다 — 크기 토큰이 생길 때 함께 정리(전체 요약 열린 항목) |
| F3 | I | 테스트 공백: 썸네일 `errorBuilder`(파일 없음 → 경로 썸네일), 모든 점이 같은 2점 이상 경로, 강아지 0마리 산책 카드(아바타 줄 생략), 배너 탭(`tracking` → `onStartWalk`) 은 FAB 와 한 테스트로 묶여 있다(`walk_feed_page_test.dart:143`) | `test/presentation/` | 계획 표의 나머지 — 빈 피드 · 카드 내용 · 메모 생략 · 탭 · 사진/경로 썸네일 · FAB · 저장 배너 · 앱바 · 실패 재시도, cubit 7건, painter 4건 — 는 모두 있다 |
| F4 | G | 피드가 drift `watch()` 만으로 저장 · 수정 · 삭제 · 강아지 이름 변경을 받아 "돌아오면 새로고침" 콜백이 하나도 없다. 스펙 §5 의 의도대로다 | `walk_feed_page.dart:15` | — |

### 다음 단계에 넘기는 것

| 단계 | 할 일 | 근거 |
|---|---|---|
| ✓ | 라우터 위젯 테스트, ⑥ W2 · W3 · W4, `walk-active-retry`(`b4abf9c`), F1(`a6fc098`) | ⑥ · ⑦ |
| 열림 | F2 크기 수치, F3 테스트(썸네일 `errorBuilder` 등) | F2 · F3 |
| ⑧ | feature 별 `history` · `testing`, 스펙 §2 · §3 · §5 정정(① · ② · ③ "다름" 목록) | 스펙 §0 |

## 열린 질문

1. **`finished` 세션이 남은 채로 새 산책을 시작하면?** 지금은 시나리오 · 스펙 모두 `tracking` 만
   막아 저장 안 된 세션이 덮어써진다(`start_walk_scenario.dart:21`). `finished` 면 저장 폼으로
   돌려보낼지(피드 배너 · FAB 가 `finished` 도 "계속" 으로 보일지), 덮어쓰기를 허용할지 ⑤ 착수 전에
   정해야 한다. `cdc1ac2` 의 tracker 도 `tracking` 만 막는다(`geolocator_walk_tracker.dart:60`) — 여전히 열림.
   **화면 수준에서 해소**(`4627805`): `/walk` 진입 시 `finished` 면 곧바로 저장 폼으로 보낸다. 피드(⑦, `d5f95b0`)도 `finished` 면 시작을 숨기고 저장 배너로 보낸다 — **해소**.
2. **domain 의 `dart:io` 를 규칙으로 인정할지.** R1 처럼 허용한다면 [아키텍처 ⑤](../../../../docs/architecture.md)에
   "Dart 코어(`dart:io` 포함)는 허용" 을 한 줄 적어 두는 편이 다음 앱의 판단을 줄인다.
3. ~~⑤ 이전에 `WalkUseCase` 를 어떻게 resolve 할지~~ — **해소**(`cdc1ac2`): 임시 구현 대신 실제 tracker 를 ④ 로 당겼다.

---

## 전체 요약

**①~⑦ 의 품질.** 도메인 → 데이터 → 셸 → 화면 순서로 쌓으며 계층 규칙(SDK 타입은 data 안, presentation 은 facade 하나,
`switch` 분기, Freezed 두 패턴)을 한 번도 어기지 않았고, 모든 단계가 깨끗한 checkout 에서 `flutter test` · `analyze` 0건이다
(최종 `a6fc098`: `feature_walk` 177 · 앱 9 · `l10n` 10 · `design_system` 42, analyze 0건). 리뷰 소견은 다음 커밋에서 빠르게
반영됐다 — 버그급 소견(B1 · B3 · D1~D3 · S1 · T1 · T2 · V1 · V2 · W1 · F1)이 모두 닫혔고, 접근성(W3) · 고아 파일(W2)까지 정리됐다. 반복된 약점은 **"단위 테스트가 통과해도 조립이 깨지는"** 종류였다: 미등록 `WalkTracker`
로 부팅 정지(D3 → S1), `go` 로 뒤로 가기 상실(V1), 부모 redirect 로 상세 불가(W1). 셋 다 페이지를 라우터 · DI 없이 띄우는
테스트로는 못 잡았고, 리뷰어가 go_router 를 직접 돌려 재현했다 — 지금은 실제 `createRouter` 를 쓰는 앱 라우터 테스트가 그 자리를 막는다. 다른 반복 약점은 여백 토큰으로 크기를 쓰는 습관(④ T3 →
⑦ F2)이다.

### 아직 열린 것

| 항목 | 상태 | 담당 단계 |
|---|---|---|
| 에뮬레이터 검증(기획서 §8 시나리오 1~8, GPX 재생 · 백그라운드 30초 · `adb` 로 파일 삭제 확인) | **안 함** — 이 환경에 Android SDK 가 없다 | 에뮬레이터 단계 → `fix(walk)` |
| AGP 9 · Kotlin 2.4 · Gradle 9.3 빌드(③ I1) | 미확인 | 에뮬레이터 단계 |
| iOS 빌드 · 백그라운드 위치 | 미확인(계획상 기기 검증 안 함) | 기록만 |
| Android 13+ `POST_NOTIFICATIONS` 미요청 → 알림 기본 숨김(③ S5) | 설계상 수용. 시나리오 3 기대값 조정 필요 | 에뮬레이터 단계 |
| Android `accuracy: best` + 2초 간격(계획은 `high`) | 미결 — 배터리 확인 후 결정 | 에뮬레이터 단계 |
| 크기 토큰 부재 — 여백 토큰으로 크기를 쓰거나 이름 없는 수치(④ T3 · ⑤ V3 · ⑦ F2: `88.0` · `3.0` · `AppSpacing.xl * 3` · 지도 높이) | 열림 | 다음 세션(권고 3) |
| ⑤ I2 `WalkFormat.duration` 경계(정확히 60분 → `1시간 0분`, 1분 미만 → `0분`) | 열림 | 다음 세션 |
| 미검증 경로: 카메라 촬영, 카드 썸네일 `errorBuilder`(사진 파일 없음), tracker 의 await 뒤 경합 · 권한 허용 경로 · `dispose`, `RouteMap` 추종, 서비스 꺼짐 페이지 | 열림 | 다음 세션 |
| 스펙 정정(① · ② · ③ 설계 대비의 "다름" 항목, ④ `states` 문구) | 열림 | ⑧ |
| 열린 질문 2(domain 의 `dart:io` 허용 여부) | 열림 | ⑧ (아키텍처 문서) |

### 다음 세션 권고

1. **조립 테스트를 흐름 하나로 넓힌다.** `b4abf9c` 의 앱 라우터 테스트(경로별 4개)를 한 걸음 더 — mock `getIt` + 실제
   `createRouter` 로 `/` → `/walk` → 종료 → `/walk/save` → 저장 → 상세 → 뒤로 → 피드를 한 번 걷는다. V1 같은 스택 결함까지 CI 가 잡는다.
2. **에뮬레이터 검증을 먼저 하고 그 결과로 수치를 정한다.** 정확도 · 간격 · `distanceFilter` · 2 m / 50 m 정책 · 알림 기대값은
   모두 실기기 값에 기대고 있다. 고친 것은 기획서 §8 대로 `fix(walk)` 와 `history.md` 에.
3. **크기 토큰을 `design_system` 에 둔다.** `AppAvatar` 크기 프리셋 · 썸네일 · 지도 높이처럼 반복된 크기를 이름 붙여, 여백
   토큰 곱셈과 `88.0` 같은 수치를 걷어 낸다(설계 §7 리팩터링 후보에 추가).
