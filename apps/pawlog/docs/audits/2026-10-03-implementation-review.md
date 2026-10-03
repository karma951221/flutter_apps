# 구현 리뷰 · 요약 — pawlog

> [pawlog 허브](../README.md) · [기획서](../overview.md) · [진행 현황](../status.md) ·
> [설계 스펙](../../../../docs/superpowers/specs/2026-10-03-walk-app-design.md) ·
> [아키텍처](../../../../docs/architecture.md) · [에이전트 가이드](../../../../CLAUDE.md)

작성 2026-10-03 · 대상 커밋 `077640e`(단계 ①)

구현 에이전트와 별개인 리뷰어 에이전트가 [기획서](../overview.md) §8 의 단계 커밋을 하나씩
독립적으로 읽고, 기획서 · 설계 스펙 · [CLAUDE.md](../../../../CLAUDE.md) 규칙에 비추어 쓴 기록이다.
커밋에 들어간 파일만 보고, 작업 트리의 미커밋 변경은 보지 않는다. 위치(`path:line`)는 대상
커밋 시점 기준이다. 무엇이 끝났고 다음이 무엇인지는 이 문서가 아니라 [진행 현황](../status.md)이
기준이다.

## 요약

| 단계 | 커밋 | 범위 | 판정 |
|---|---|---|---|
| ① | `077640e` | `feature_walk` 뼈대 · 도메인(엔티티 11 · 정책 2 · 인터페이스 4 · facade · 시나리오 15) · `FailureCode` +5 · ARB 3개 | **통과(조건부)** — 버그 확정 0, 스펙과 다른 결정 13건(스펙 문서 반영 필요), 잠재 결함 3건을 다음 단계로 넘김 |

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

| 테스트 파일 | 수 | 확인하는 것 |
|---|---|---|
| `test/domain/policy/walk_tracking_policy_test.dart` | 4 | 50.1 m 탈락, 1.9 m 탈락, 첫 점(정확도 50 경계) 통과, 정확도 null 은 거리만 |
| `test/domain/policy/route_preview_test.dart` | 4 | 1000점 → ≤ 64 · 첫/끝 유지, 10점 그대로, 왕복, null · 빈 문자열 |
| `.../scenario/save_dog_scenario_test.dart` | 4 | 공백 이름, 신규 id · 시각, 사진 교체 시 옛 파일 삭제, 없는 반려견 |
| `.../scenario/save_walk_scenario_test.dart` | 3 | 반려견 0, 저장 값 · 사진 id/position · `clear`, 저장 실패 시 `clear` 안 함 |
| `.../scenario/update_walk_scenario_test.dart` | 2 | 없는 산책, 사진 id 보존 · 빠진 파일만 삭제 |
| `.../scenario/delete_walk_scenario_test.dart` | 3 | 삭제 → 파일 순서, DB 실패 시 파일 유지, 없는 산책 |
| `.../scenario/start_walk_scenario_test.dart` | 3 | 추적 중, 반려견 0, 정상 시작 |
| `.../scenario/discard_walk_scenario_test.dart` | 1 | 파일 삭제 → `clear` 순서 |

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
| B1 | `RoutePreview.decode` 가 깨진 JSON(`'x'`)에서 `FormatException`, 모양이 다른 JSON(`'{}'`, `'[[1]]'`)에서 `TypeError` / `RangeError` 를 던진다. 스펙은 빈 목록. ② 의 레포가 `watchWalks` 매핑 안에서 부르면 행 하나 때문에 피드 스트림 전체가 오류가 된다 | `route_preview.dart:28-38` | `try/catch` → `const []` 로 고치고 깨진 값 테스트 추가(스펙 §6 표에도 있다) |
| B2 | `DiscardWalkScenario` 가 **항상** `tracker.clear()` 를 부른다. 스펙 §4 는 수정 폼 버리기도 있는데("이번 편집에서 추가한 사진만 지운다"), 그 경로가 `discardWalk` 를 쓰면 다른 산책을 추적 중일 때 tracker 를 건드린다 | `discard_walk_scenario.dart:10-15` | 지금은 인터페이스 주석 "finished → idle"(`walk_tracker.dart:20`)에 기대고 있다. ⑤ 의 tracker 가 `finished` 가 아니면 no-op 이어야 하고, ⑥ 수정 폼은 `removePhoto` 를 써야 한다 |
| B3 | `SaveWalk` · `UpdateWalk` 는 `dogIds` 가 비었는지만 보고, `getAll()` 에서 **못 찾은 id 는 조용히 버린다**. 선택 직후 강아지가 삭제되면 반려견 0마리 산책이 저장돼 기획서 §9 확정 7("1마리 이상")을 어긴다 | `save_walk_scenario.dart:35-38`, `update_walk_scenario.dart:50-53` | 드문 경합. `selected.isEmpty` 면 `walkDogRequired` 로 막는 한 줄이면 된다 |

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

- **파일 삭제는 DB 성공 뒤**를 네 시나리오가 똑같이 지킨다: `delete_dog_scenario.dart:23-27`,
  `delete_walk_scenario.dart:21-26`, `update_walk_scenario.dart:67-74`, `save_dog_scenario.dart:52-58`.
  `DeleteWalk` 는 순서까지 `verifyInOrder` 로 고정했다(`delete_walk_scenario_test.dart:34-38`).
- `SaveWalk` 는 `insert` 가 `Ok` 일 때만 `tracker.clear()`(`save_walk_scenario.dart:58-62`) —
  실패하면 `finished` 세션이 남아 재시도할 수 있다. 테스트 있음(`save_walk_scenario_test.dart:72-81`).
- `UpdateWalk` 는 남는 사진의 id 를 경로로 찾아 보존하고 새 경로만 새 id 를 받는다
  (`update_walk_scenario.dart:42,57`). 강아지 행을 지우고 다시 넣는 ② 의 `update` 와 맞물려도
  사진 id 가 흔들리지 않는다.
- `RoutePreview.downsample` 은 `length ≤ 64`(0 · 1 · 2점 포함)면 그대로, 넘으면 인덱스
  `round(i·(n−1)/63)` 로 정확히 64점을 뽑아 `i=0` → 첫 점, `i=63` → 끝 점이 보장된다. 간격이
  1 이상이라 중복도 없다(`route_preview.dart:13-22`).
- `WalkSession.elapsedAt(now)` 는 `endedAt ?? now` 로 추적 중 · 종료 모두를 하나로 계산하고
  엔티티가 시계를 읽지 않는다(`walk_session.dart:28-29`). 스펙 §4 의 "틱을 누적하지 않는다" 와 맞다.
- `WalkTrackingPolicy` 는 거리를 받기만 해 geolocator 를 모른다(`walk_tracking_policy.dart:5`).
  정확도 검사가 첫 점에도 먼저 적용된다(`:18-19`) — 첫 점이 부정확해 경로가 튀는 것을 막는다.
- l10n exhaustive switch 덕분에 코드를 추가하고 문구를 빠뜨리면 컴파일이 깨진다
  (`failure_localizations.dart:122-127`).

### 다음 단계에 넘기는 것

| 단계 | 할 일 | 근거 |
|---|---|---|
| ② | `FilePhotoStorage.store` 실패를 `Failure.unknown(failureCode: walkPhotoSaveFailed)` 로 바꾼다(시나리오가 안 하므로 여기서) | `store_photo_scenario.dart:12-15`, 스펙 §2 실패 코드 표 |
| ② | `findById` 는 없으면 `Ok(null)` — 스펙의 "없으면 `Err`" 가 아니다. 레포 테스트도 이 계약으로 | `dog_repository.dart:10`, `walk_repository.dart:10` |
| ② | `route_preview` 컬럼 읽기에서 B1 을 막는다(도메인을 고치든 매퍼에서 잡든) | B1 |
| ② | `PhotoStorage.remove` 가 없는 파일 · IO 오류에서 던지지 않음을 테스트로 고정 | I4 |
| ② | 레포 2개 · `FilePhotoStorage` · `WalkRegisterModule` DI 등록. 지금 모듈은 `WalkUseCase` 만 등록해 해석 시 실패한다 | `feature_walk.module.dart:22-30` |
| ③ | `AppAvatar.imageFile` 을 `File` 로 — facade `photoFile` 과 짝 | R1 |
| ④ W1 | 강아지 폼 버리기는 새로 쓴 사진을 `removePhoto` 로 지운다. `getDog` 의 `Ok(null)` 을 notFound 로 다룬다 | `walk_use_case.dart:64`, 스펙 §2 "강아지 폼도 같은 규칙" |
| ⑤ W2 | tracker 가 `distanceBetween` 으로 `stepMeters` 를 **먼저** 계산해 `accept` 에 넘기고, 받아들인 점의 거리만 합산. 첫 점은 `previous: null` | `walk_tracking_policy.dart:5,12-16` |
| ⑤ W2 | `clear()` 는 `finished` 일 때만 `idle` 로(아니면 no-op), `start` 는 tracker 도 `walkTrackingAlreadyActive` 검사, `stop` 은 추적 중이 아니면 `walkNotFound` | B2, `walk_tracker.dart:20-21`, 스펙 §2 |
| ⑥ W3 | `saveWalk` 가 `Walk` 를 돌려주므로 `saved(walk.id)`. 수정 폼 버리기는 `discardWalk` 가 아니라 `removePhoto` 로 | `walk_use_case.dart:43`, B2 |
| ⑦ W4 | `getWalk` 의 `Ok(null)` → `WalkDetailCubit` 이 `walkNotFound`. 강아지 삭제 뒤 `dogs` 가 빈 산책을 `WalkCard` · `DogAvatars` 가 그려야 한다 | `walk_repository.dart:10`, 기획서 W1 "산책 기록은 남는다" |
| ⑧ | 설계 스펙 §2 · §3 을 위 "설계 대비" 의 "다름" 13건에 맞춰 고친다(특히 `PhotoStorage` · 레포 시그니처 · `accept` 의사코드 · ARB 설명 범위) | 스펙 §0 |

## 열린 질문

1. **`finished` 세션이 남은 채로 새 산책을 시작하면?** 지금은 시나리오 · 스펙 모두 `tracking` 만
   막아 저장 안 된 세션이 덮어써진다(`start_walk_scenario.dart:21`). `finished` 면 저장 폼으로
   돌려보낼지(피드 배너 · FAB 가 `finished` 도 "계속" 으로 보일지), 덮어쓰기를 허용할지 ⑤ 착수 전에
   정해야 한다.
2. **domain 의 `dart:io` 를 규칙으로 인정할지.** R1 처럼 허용한다면 [아키텍처 ⑤](../../../../docs/architecture.md)에
   "Dart 코어(`dart:io` 포함)는 허용" 을 한 줄 적어 두는 편이 다음 앱의 판단을 줄인다.
