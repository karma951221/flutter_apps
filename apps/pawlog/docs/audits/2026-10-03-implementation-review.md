# 구현 리뷰 · 요약 — pawlog

> [pawlog 허브](../README.md) · [기획서](../overview.md) · [진행 현황](../status.md) ·
> [설계 스펙](../../../../docs/superpowers/specs/2026-10-03-walk-app-design.md) ·
> [아키텍처](../../../../docs/architecture.md) · [에이전트 가이드](../../../../CLAUDE.md)

작성 2026-10-03 · 대상 커밋 `077640e`(단계 ①) · `bdb60c3`(단계 ②)

구현 에이전트와 별개인 리뷰어 에이전트가 [기획서](../overview.md) §8 의 단계 커밋을 하나씩
독립적으로 읽고, 기획서 · 설계 스펙 · [CLAUDE.md](../../../../CLAUDE.md) 규칙에 비추어 쓴 기록이다.
커밋에 들어간 파일만 보고, 작업 트리의 미커밋 변경은 보지 않는다. 위치(`path:line`)는 대상
커밋 시점 기준이고, 뒤 단계에서 고쳐진 소견은 지우지 않고 "반영됨" 으로 표시한다. 무엇이 끝났고 다음이 무엇인지는 이 문서가 아니라 [진행 현황](../status.md)이
기준이다.

## 요약

| 단계 | 커밋 | 범위 | 판정 |
|---|---|---|---|
| ① | `077640e` | `feature_walk` 뼈대 · 도메인(엔티티 11 · 정책 2 · 인터페이스 4 · facade · 시나리오 15) · `FailureCode` +5 · ARB 3개 | **통과(조건부)** — 버그 확정 0, 스펙과 다른 결정 13건(스펙 문서 반영 필요), 잠재 결함 3건을 다음 단계로 넘김(B1 · B3 은 `bdb60c3` 에서 반영됨) |
| ② | `bdb60c3` | drift `WalkDatabase`(5테이블) · 매퍼 · `DriftDogRepository` · `DriftWalkRepository` · `FilePhotoStorage` · `WalkRegisterModule` · ① 소견 B1 · B3 반영 | **통과(조건부)** — 스키마 · cascade · 조인 watch 는 스펙대로이고 테스트가 실제로 단언한다. `WalkTracker` 미등록이라 ⑤ 전에는 `WalkUseCase` 를 resolve 할 수 없음(D3), watch 의 매핑 예외가 `Err` 로 바뀌지 않는 구멍(D1), DB dispose 누락(D2) |

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
| B1 **반영됨** | `RoutePreview.decode` 가 깨진 JSON(`'x'`)에서 `FormatException`, 모양이 다른 JSON(`'{}'`, `'[[1]]'`)에서 `TypeError` / `RangeError` 를 던진다. 스펙은 빈 목록. ② 의 레포가 `watchWalks` 매핑 안에서 부르면 행 하나 때문에 피드 스트림 전체가 오류가 된다 | `route_preview.dart:28-38` | `try/catch` → `const []` 로 고치고 깨진 값 테스트 추가(스펙 §6 표에도 있다). **`bdb60c3` 반영**: `FormatException` · `TypeError` · `RangeError` 를 잡아 빈 목록(`route_preview.dart:30-48`), 깨진 값 4종 테스트(`route_preview_test.dart:37-42`) |
| B2 **열림** | `DiscardWalkScenario` 가 **항상** `tracker.clear()` 를 부른다. 스펙 §4 는 수정 폼 버리기도 있는데("이번 편집에서 추가한 사진만 지운다"), 그 경로가 `discardWalk` 를 쓰면 다른 산책을 추적 중일 때 tracker 를 건드린다 | `discard_walk_scenario.dart:10-15` | 지금은 인터페이스 주석 "finished → idle"(`walk_tracker.dart:20`)에 기대고 있다. ⑤ 의 tracker 가 `finished` 가 아니면 no-op 이어야 하고, ⑥ 수정 폼은 `removePhoto` 를 써야 한다 |
| B3 **반영됨** | `SaveWalk` · `UpdateWalk` 는 `dogIds` 가 비었는지만 보고, `getAll()` 에서 **못 찾은 id 는 조용히 버린다**. 선택 직후 강아지가 삭제되면 반려견 0마리 산책이 저장돼 기획서 §9 확정 7("1마리 이상")을 어긴다 | `save_walk_scenario.dart:35-38`, `update_walk_scenario.dart:50-53` | 드문 경합. `selected.isEmpty` 면 `walkDogRequired` 로 막는 한 줄이면 된다. **`bdb60c3` 반영**: 두 시나리오 모두 `selected.isEmpty` → `walkDogRequired`(`save_walk_scenario.dart:39-44`, `update_walk_scenario.dart:40-49`), 테스트는 `insert` · `update` · `clear` 미호출까지 확인(`save_walk_scenario_test.dart:54-63`, `update_walk_scenario_test.dart:42-54`) |

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

단계 칸의 ✓ 는 그 단계 커밋에서 확인된 것, △ 는 일부만 된 것(② 절 참고).

| 단계 | 할 일 | 근거 |
|---|---|---|
| ② ✓ | `FilePhotoStorage.store` 실패를 `Failure.unknown(failureCode: walkPhotoSaveFailed)` 로 바꾼다(시나리오가 안 하므로 여기서) | `store_photo_scenario.dart:12-15`, 스펙 §2 실패 코드 표 |
| ② ✓ | `findById` 는 없으면 `Ok(null)` — 스펙의 "없으면 `Err`" 가 아니다. 레포 테스트도 이 계약으로 | `dog_repository.dart:10`, `walk_repository.dart:10` |
| ② ✓ | `route_preview` 컬럼 읽기에서 B1 을 막는다(도메인을 고치든 매퍼에서 잡든) | B1 |
| ② △ | `PhotoStorage.remove` 가 없는 파일 · IO 오류에서 던지지 않음을 테스트로 고정 | I4 |
| ② ✓ | 레포 2개 · `FilePhotoStorage` · `WalkRegisterModule` DI 등록. 지금 모듈은 `WalkUseCase` 만 등록해 해석 시 실패한다 | `feature_walk.module.dart:22-30` |
| ③ | `AppAvatar.imageFile` 을 `File` 로 — facade `photoFile` 과 짝 | R1 |
| ④ W1 | 강아지 폼 버리기는 새로 쓴 사진을 `removePhoto` 로 지운다. `getDog` 의 `Ok(null)` 을 notFound 로 다룬다 | `walk_use_case.dart:64`, 스펙 §2 "강아지 폼도 같은 규칙" |
| ⑤ W2 | tracker 가 `distanceBetween` 으로 `stepMeters` 를 **먼저** 계산해 `accept` 에 넘기고, 받아들인 점의 거리만 합산. 첫 점은 `previous: null` | `walk_tracking_policy.dart:5,12-16` |
| ⑤ W2 | `clear()` 는 `finished` 일 때만 `idle` 로(아니면 no-op), `start` 는 tracker 도 `walkTrackingAlreadyActive` 검사, `stop` 은 추적 중이 아니면 `walkNotFound` | B2, `walk_tracker.dart:20-21`, 스펙 §2 |
| ⑥ W3 | `saveWalk` 가 `Walk` 를 돌려주므로 `saved(walk.id)`. 수정 폼 버리기는 `discardWalk` 가 아니라 `removePhoto` 로 | `walk_use_case.dart:43`, B2 |
| ⑦ W4 | `getWalk` 의 `Ok(null)` → `WalkDetailCubit` 이 `walkNotFound`. 강아지 삭제 뒤 `dogs` 가 빈 산책을 `WalkCard` · `DogAvatars` 가 그려야 한다 | `walk_repository.dart:10`, 기획서 W1 "산책 기록은 남는다" |
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

| 테스트 | 확인하는 것 |
|---|---|
| `test/data/database/walk_mapper_test.dart:30-52` | 2마리 × 2장 = 4행 + 빈 산책 1행 → 산책 2개, 순서 유지, 강아지 이름순 · 사진 position 순 · 중복 제거, 0마리 · 0장 산책도 나온다 |
| `drift_dog_repository_test.dart:28-66` | 이름순 watch · 생일 왕복, 수정이 스트림에 흐름, 삭제, `findById` 없으면 `null` |
| `drift_walk_repository_test.dart:51-77` | 한 번에 저장한 4테이블 왕복, 사진을 position 역순으로 넣어도 정렬돼 나온다 |
| `drift_walk_repository_test.dart:79-92` | 최신순 watch. `'new'` 는 강아지 · 사진 0 이라 LEFT JOIN 이 빈 산책도 내보냄을 겸해 확인 |
| `drift_walk_repository_test.dart:94-110` | **강아지 이름 변경이 `watchAll` 에 흐른다** — 방출을 `['하늘', '바다']` 로 정확히 단언 |
| `drift_walk_repository_test.dart:112-130` | **산책 삭제 → points · photos · walk_dogs 0, dogs 2 그대로.** pragma 가 꺼져 있으면 실패하는 단언이라 cascade 를 실제로 증명한다 |
| `drift_walk_repository_test.dart:145-181` | update 가 시각 · 거리 · 프리뷰 · 점을 건드리지 않고 memo · updatedAt · dogs · photos 만 바꾼다 |
| `drift_walk_repository_test.dart:183-194` | 강아지 삭제 → 산책은 남고 연결만 끊김 |
| `file_photo_storage_test.dart:25-51` | 없는 하위 폴더에 저장 · 상대 경로(`/` 없음), `resolve`, 두 번 `remove` 해도 조용함 |

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
| D1 | watch 의 `handleError` 는 **원천(drift) 오류만** `Err` 로 바꾼다. `handleData` 안의 매핑이 던지면 Dart 의 `_SinkTransformerStreamSubscription._handleData` 가 잡아 **출력 스트림에 날 오류**로 흘린다(`dart-sdk/lib/async/stream_transformers.dart:113-118`). 구독은 살아 있지만 cubit 이 `onError` 없이 `listen` 하면 zone 의 미처리 오류가 되고 상태는 그대로다. 지금 던질 수 있는 매핑은 생일 `DateTime.parse`(`walk_mapper.dart:23`) — 앱만 쓰는 컬럼이라 확률은 낮다. B1 로 `RoutePreview.decode` 는 안전해졌다 | `drift_dog_repository.dart:23-30`, `drift_walk_repository.dart:46-52` | `handleData` 를 `try/catch` 로 감싸 `Err` 로. 원천 오류 쪽은 문제없다 — drift 는 질의 실패를 `addError` 로 흘리고 스트림을 닫지 않으며(`drift-2.34.4/lib/src/runtime/executor/stream_queries.dart:352-357`) `fromHandlers` 도 오류 뒤 닫지 않으므로 다음 테이블 변경에 다시 값이 온다 |
| D2 | `WalkDatabase` 에 `@disposeMethod` 가 없어 `getIt.reset()` · 테스트 해제 때 `close()` 가 불리지 않는다 | `walk_register_module.dart:12-13` | 앱 수명 싱글턴이라 운영 영향은 없다. 스펙 §5 대로 붙이면 끝 |
| D3 | **`WalkTracker` 구현이 아직 없어 `WalkUseCase` 를 resolve 할 수 없다.** 생성 모듈이 `gh<WalkTracker>()` 를 부르는데(`feature_walk.module.dart:53`) 등록처가 없다. lazySingleton 이라 부팅은 되지만 ③ `bootstrap` 의 `getDogs()` 1회 호출과 ④ W1 화면이 첫 resolve 에서 던진다 | `feature_walk.module.dart:49-57` | 기획서 §8 순서상 tracker 는 ⑤. ③ · ④ 가 쓰려면 임시 등록이 필요하다 → 열린 질문 3 |

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
   않는다 — `walks.id` tie-break 를 더하면 피드가 흔들리지 않는다.
4. `FilePhotoStorage.store` 는 `FileSystemException` 만 잡는다(`:27`). `writeAsBytes` · `create` 의 IO 오류는
   모두 그 하위 타입이라 충분하다. `_ids.newId()` 가 `try` 밖이지만 던질 일이 없다. `remove` 는
   `existsSync` 동기 IO 후 모든 예외를 삼킨다(`:41-47`) — 계약(① I4)은 "없는 파일" 만 테스트됐다.
5. `walk_dogs.dog_id` 에 인덱스가 없어 강아지 삭제 cascade 가 `walk_dogs` 를 훑는다. v1 규모에서 무시 가능.

#### G — 괜찮은 점

- cascade 와 이름 변경 전파를 **실제 DB 로 단언**한다(`drift_walk_repository_test.dart:94-130`). 둘 다
  pragma · 조인을 빼면 실패하는 테스트다.
- 조인 묶기가 `Map` 삽입 순서로 피드 순서를 지키고, 강아지 × 사진 곱을 id 로 걷어 내며, LEFT JOIN 의
  `null` 을 건너뛰어 0마리 · 0장 산책도 빈 목록으로 낸다(`walk_mapper.dart:89-98`). 사진은 SQL 정렬에
  기대지 않고 묶은 뒤 다시 정렬한다(`:116-118`).
- update 는 `WalksCompanion(memo, updatedAt)` 만 써서 시각 · 거리 · 프리뷰를 구조적으로 못 바꾼다
  (`drift_walk_repository.dart:102-107`). 테스트가 일부러 엉뚱한 값을 넘겨 확인한다(`drift_walk_repository_test.dart:156-180`).
- 상대 경로 · `iOS 컨테이너` 이유를 주석과 테스트(`/` 없음)로 고정했다(`file_photo_storage.dart:16`,
  `file_photo_storage_test.dart:33`).
- ① 소견 B1 · B3 을 테스트와 함께 반영했다.

### 다음 단계에 넘기는 것

| 단계 | 할 일 | 근거 |
|---|---|---|
| ③ | `externalPackageModulesBefore: [Core, FeatureWalk]` 순서로 `IdGenerator` 를 먼저 등록. microPackage 빌드가 `IdGenerator` 미등록 경고를 내도 런타임에는 Core 모듈이 준다 | `feature_walk.module.dart:40,55`, 스펙 §5 |
| ③ | `init` 이 `async`(preResolve) 가 됐으니 `configureDependencies` 를 `await` | `feature_walk.module.dart` `init(...) async` |
| ③ · ④ | `WalkTracker` 가 ⑤ 까지 없으므로 `WalkUseCase` resolve 를 막지 않을 방법을 정한다 | D3, 열린 질문 3 |
| ③ | `package_boundary_test` 에 "앱은 `WalkDatabase` · drift 를 직접 쓰지 않는다" 추가 고려 | D6 |
| ⑤ W2 | tracker 등록 시 D1 과 같은 이유로 `states` 스트림도 매핑 예외를 값으로 바꾼다 | D1 |
| ⑦ W4 | `WalkFeedCubit` 은 `watchWalks` 를 `onError` 와 함께 구독하거나 D1 을 먼저 고친다 | D1 |
| ⑧ | 스펙 §3 · §5 의 `build.yaml` · `DateOnlyConverter` · `photosRoot().create` · `@disposeMethod` 문구를 구현에 맞춘다(또는 D2 를 고친다) | 설계 대비 |

## 열린 질문

1. **`finished` 세션이 남은 채로 새 산책을 시작하면?** 지금은 시나리오 · 스펙 모두 `tracking` 만
   막아 저장 안 된 세션이 덮어써진다(`start_walk_scenario.dart:21`). `finished` 면 저장 폼으로
   돌려보낼지(피드 배너 · FAB 가 `finished` 도 "계속" 으로 보일지), 덮어쓰기를 허용할지 ⑤ 착수 전에
   정해야 한다.
2. **domain 의 `dart:io` 를 규칙으로 인정할지.** R1 처럼 허용한다면 [아키텍처 ⑤](../../../../docs/architecture.md)에
   "Dart 코어(`dart:io` 포함)는 허용" 을 한 줄 적어 두는 편이 다음 앱의 판단을 줄인다.
3. **⑤ 이전에 `WalkUseCase` 를 어떻게 resolve 할지.** ② 시점에 `WalkTracker` 등록처가 없다(D3).
   (a) ③ 에서 `idle` 만 내는 임시 구현을 등록하고 ⑤ 에서 바꾼다, (b) ⑤ 의 tracker 를 ③ 앞으로 당긴다,
   (c) ④ 를 ⑤ 뒤로 미룬다 — 기획서 §8 의 순서를 지키려면 (a) 가 가장 작다.
