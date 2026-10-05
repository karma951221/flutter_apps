# 진행 현황 — pawlog

> [pawlog 허브](README.md) · [기획서](overview.md) · [구현 리뷰](audits/2026-10-03-implementation-review.md) · [전체 진행 현황](../../../docs/status.md)

**pawlog 앱 진행 현황의 단일 기준은 이 문서다.** 다른 문서에는 진행 상태를 적지 않는다.

## 단계 요약

| 단계 | 범위 | 상태 |
|------|------|------|
| 0 | 기획 — 기획서 · 설계 스펙 · 허브 | **완료** |
| 1 | 바닥(패키지 뼈대 · drift · 앱 셸) + W1 dog + W2 tracking | **완료** |
| 2 | W3 record + W4 feed + 문서 | **완료** — 에뮬레이터 QA 2026-10-04(일부 시나리오 미실행) |
| 3 | W5 social (v2) | 미정 |

## 0 — 기획 (완료, 2026-10-03)

[기획서](overview.md)에 사용자 결정(로컬 우선 → Supabase 는 v2, GPS 자동 추적, 강아지 여러 마리,
사진 포함)을 고정하고 feature 를 W1 dog · W2 tracking · W3 record · W4 feed · W5 social 로 나눴다.
설계는 [설계 스펙](../../../docs/superpowers/specs/2026-10-03-walk-app-design.md)(`02e03de`) — 화면 ·
상태 · 문자열이 다를 때는 feature 별 `plan.md` 가 우선한다. 허브 · 공통 문서 행 · 링크 검사 대상
추가까지 `324f77b`.

## 1 · 2 — v1 구현 (완료, 2026-10-03)

[기획서 §8](overview.md#8-개발-단계)의 단계 커밋 순서대로 갔다. 단계마다 리뷰어 에이전트가 따로
읽고 [구현 리뷰](audits/2026-10-03-implementation-review.md)에 소견을 남겼고, 고친 것은 feature 별
`history.md` 의 "리뷰에서 고친 것" 표에 있다. 브랜치 `claude/dog-walk-log-app-8zyycw`.

- [x] **① 패키지 뼈대 + 도메인** — `packages/features/walk`, 엔티티 · 정책 2 · 인터페이스 4 ·
      `WalkUseCase` · 시나리오, `core` 에 `FailureCode` 5개, ARB 3개 (`077640e`)
- [x] **② 데이터** — drift `WalkDatabase`(5테이블) · `DriftDogRepository` · `DriftWalkRepository` ·
      `FilePhotoStorage` (`bdb60c3`)
- [x] **③ 앱 셸** — `apps/pawlog`, Supabase 없는 부팅 · 라우터 · `DogsRedirect` · 권한 선언 ·
      `package_boundary_test`, `AppAvatar.imageFile` (`87c680d`)
- [x] **④ 추적기 + W1 dog** — `GeolocatorWalkTracker` · `LocationGateway` 를 앞당기고 반려견 목록 ·
      편집 ([계획](features/dog/plan.md) · [기록](features/dog/history.md) · [테스트](features/dog/testing.md)) (`cdc1ac2`)
- [x] **⑤ W2 tracking** — `ActiveWalkCubit`(1초 타이머) · `RouteMap` · `WalkStatsRow` · `WalkFormat`
      ([계획](features/tracking/plan.md) · [기록](features/tracking/history.md) · [테스트](features/tracking/testing.md)) (`4627805`)
- [x] **⑥ W3 record** — 저장 · 수정 폼과 상세(기획서의 ⑦ 몫인 상세를 당김), ④⑤ 소견 반영
      ([계획](features/record/plan.md) · [기록](features/record/history.md) · [테스트](features/record/testing.md)) (`93d722b`)
- [x] **⑦ W4 feed** — 피드 · 카드 · 경로 썸네일 · 배너, `/` 연결, ⑥ W1(`/walks` 리다이렉트) · ⑤ V2 수정
      ([계획](features/feed/plan.md) · [기록](features/feed/history.md) · [테스트](features/feed/testing.md)) (`d5f95b0`)
- [x] **에뮬레이터 검증** — [기획서 §8](overview.md#8-개발-단계) 8 시나리오. 2026-10-04 QA, 아래 "에뮬레이터 QA"
- [x] **⑧ 문서** — feature 별 history · testing, 진행 현황, 허브, 아키텍처 §1 · 의존 그래프 ·
      개발환경 · 테스트 허브 · `CLAUDE.md` · 설계 스펙 §4 안내 (이 커밋)

- [x] **리뷰 소견 마감** — ⑥ W2 · W3 · W4, `walk-active-retry`, 앱 라우터 테스트 4건(`b4abf9c`),
      ⑦ F1 경로 썸네일 경도 보정(`a6fc098`)

검증(2026-10-03, `a6fc098`): `flutter analyze` 0건(`feature_walk` · `apps/pawlog` · `l10n` ·
`design_system`) · `flutter test` `feature_walk` `+177` · `apps/pawlog` `+9`(라우터 4 · 리다이렉트 4 ·
경계 1) · `l10n` `+10` · `design_system` `+42`. **에뮬레이터 8 시나리오 미실행 — 이 환경에 Android
SDK 없음, 다음 세션.** APK · iOS 빌드도 아직 한 번도 하지 않았다.

## 다음 할 일

1. **남은 에뮬레이터 시나리오** — feature 별 `testing.md` 의 "에뮬레이터" 표에서 미실행 · 일부인 것:
   dog ②(삭제) ③④, tracking ⑤(저장 폼 뒤로 가기), record ④⑤, feed ③④⑥. 이번 수정(위치 오류 안내 ·
   설정 열기 · 빈 피드 안내)도 화면에서 한 번 더 본다
2. **QA 다듬을 것** (2026-10-04 에뮬레이터 QA 에서 본 것, 아직 안 고침)
   - Android 12+ 스플래시 아이콘 해상도 — 따로 다루는 중
   - 시작 전(반려견 선택) 화면 제목이 "산책 중" 이다
   - 강아지 칩의 선택 체크가 아바타 글자와 겹친다
   - 반려견 이름 검증이 스낵바뿐이고, 키보드가 올라오면 저장 버튼을 가린다
   - 다크 모드에서 입력칸 테두리 대비가 낮다
   - 앱 테마가 브랜드 주황(`#F08C3A`)이 아니라 기본 남색이다
   - image_picker 카메라 원본이 `cache/` 에 남는다
3. **리뷰 문서의 열린 항목** — [구현 리뷰](audits/2026-10-03-implementation-review.md)의 "다음 단계에
   넘기는 것" 표와 열린 질문. 남은 것: 크기 수치의 토큰화(④ T3 · ⑦ F2), `WalkFormat.duration`
   경계(⑤ I2), Android 정확도 `best` vs 계획 `high`(실기기에서 결정), `POST_NOTIFICATIONS` 런타임 요청,
   미테스트 경로(카메라 · 사진 없는 썸네일 fallback)
4. **W5 social 기획** — v2. Supabase 소셜 피드를 얹는다. 착수 시 `features/social/plan.md`
5. **리팩터링 후보** — [설계 §7](../../../docs/superpowers/specs/2026-10-03-walk-app-design.md#7-리팩터링-후보--이-앱을-만들며-확인된-것):
   남은 것은 `FailureCode` · ARB 의 앱별 증가, `AppAvatar.nickname`, `CLAUDE.md` 경로, `core` 등록을
   앱이 따로 하는 문제. 모노레포 공통 작업이라 [전체 진행 현황](../../../docs/status.md)에서 다룬다.
   2026-10-04 에 푼 것은 아래 "패키지 경계 정리" 에 있다

## 패키지 경계 정리 (2026-10-04)

브랜치 `refactor/package-boundary`. 동작은 바꾸지 않았다.

- [x] **코드를 앱 안으로** — `packages/features/walk`(`feature_walk`)를 `apps/pawlog/lib/` 의
      `core/`(app · router · di · bootstrap) · `data/` · `domain/` · `presentation/` 로 옮겼다. 영역은
      `dog` · `walk` · `tracking` · `feed` · `photo`. `WalkRegisterModule` 은 앱의 `RegisterModule` 이 됐고
      `FeatureWalkPackageModule` 은 없어졌다. 테스트도 `apps/pawlog/test/` 로 옮겨 `lib/` 와 1:1 이다.
      `package_boundary_test` 는 앱 pubspec 을 본다 (`edc71b9`)
- [x] **시계 주입** — 시나리오 · `DefaultWalkUseCase` · `GeolocatorWalkTracker` · `ActiveWalkCubit` 이
      `core` 의 `Clock` 을 받는다. `withClock` 테스트 생성자는 없어지고 테스트는 `FakeClock` 을 쓴다 (`c84ee4c`)
- [x] **위치는 `location` 패키지** — 추적기가 `packages/location` 의 `LocationGateway` · `LocationAccess` 를
      쓴다. 권한은 `permission` 의 `PermissionRequester`(세션당 1회). 스트림 설정(정확도 `best` ·
      `distanceFilter` 3 · 알림)은 그대로 추적기가 만든다 (`e908c25`)

검증(2026-10-04, `e908c25`): `apps/pawlog` `flutter analyze` 0건 · `flutter test` `+186`(옮긴 `feature_walk`
테스트 포함). 에뮬레이터 검증은 여전히 미실행이다.

## 에뮬레이터 QA (2026-10-04)

Android 17 에뮬레이터(`Medium_Phone`), 위치는 `adb emu geo fix` 로 경로를 흘렸다. 결과는 feature 별
`testing.md` 의 "에뮬레이터" 표([dog](features/dog/testing.md#에뮬레이터) ·
[tracking](features/tracking/testing.md#에뮬레이터) · [record](features/record/testing.md#에뮬레이터) ·
[feed](features/feed/testing.md#에뮬레이터)), 고친 이유는 각 `history.md` 의 "2026-10-04 — 에뮬레이터 QA" 에 있다.

- [x] **PASS** — dog ①, tracking ①②③④⑥, record ①②③⑥, feed ①②⑤. 일부 — dog ②, tracking ⑤.
      미실행 — dog ③④, record ④⑤, feed ③④⑥
- [x] `WAKE_LOCK` 미선언으로 위치 스트림이 `SecurityException` — 점이 하나도 안 들어왔다 (`1b97e83`)
- [x] `TileProvider` 싱글턴을 첫 `TileLayer` 가 dispose 해 이후 지도(재진입 · 상세)가 회색 (`e0594d9`)
- [x] 첫 반려견 등록 뒤 피드가 아니라 반려견 목록에 떨어져 갈 곳이 없음 (`fce4e77`)
- [x] 추적 중 위치 스트림 오류가 화면에 안 보여 "위치를 찾는 중…" 에 머묾 — `locationError` + 다시 시도
      (`0c1c07b`, `core` 에 `FailureCode.locationStreamFailed`)
- [x] 권한 거부 · 서비스 꺼짐 안내에 "설정 열기" · "위치 설정 열기" (`2d6fc8b`, `location` 게이트웨이에
      `openLocationSettings`)
- [x] 추적 중 빈 피드에 "첫 산책을 시작해 보세요 / 산책 시작" 이 함께 보임 (`af4cf22`)
- [x] 문서의 사진 폴더 경로 `files/pawlog_photos` → `app_flutter/pawlog_photos`

검증(2026-10-04, `af4cf22`): `apps/pawlog` `flutter analyze` 0건 · `flutter test` `+205` ·
`flutter build apk --debug` 성공. `packages/location` analyze 0건 · `+21`, `l10n` `+10`, `core` `+65`,
`apps/commute` `+45`.
