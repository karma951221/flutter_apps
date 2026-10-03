# 진행 현황 — pawlog

> [pawlog 허브](README.md) · [기획서](overview.md) · [구현 리뷰](audits/2026-10-03-implementation-review.md) · [전체 진행 현황](../../../docs/status.md)

**pawlog 앱 진행 현황의 단일 기준은 이 문서다.** 다른 문서에는 진행 상태를 적지 않는다.

## 단계 요약

| 단계 | 범위 | 상태 |
|------|------|------|
| 0 | 기획 — 기획서 · 설계 스펙 · 허브 | **완료** |
| 1 | 바닥(패키지 뼈대 · drift · 앱 셸) + W1 dog + W2 tracking | **완료** |
| 2 | W3 record + W4 feed + 문서 | **완료** — 에뮬레이터 검증 미실행 |
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
- [ ] **에뮬레이터 검증** — [기획서 §8](overview.md#8-개발-단계) 8 시나리오. 미실행
- [x] **⑧ 문서** — feature 별 history · testing, 진행 현황, 허브, 아키텍처 §1 · 의존 그래프 ·
      개발환경 · 테스트 허브 · `CLAUDE.md` · 설계 스펙 §4 안내 (이 커밋)

- [x] **리뷰 소견 마감** — ⑥ W2 · W3 · W4, `walk-active-retry`, 앱 라우터 테스트 4건(`b4abf9c`),
      ⑦ F1 경로 썸네일 경도 보정(`a6fc098`)

검증(2026-10-03, `a6fc098`): `flutter analyze` 0건(`feature_walk` · `apps/pawlog` · `l10n` ·
`design_system`) · `flutter test` `feature_walk` `+177` · `apps/pawlog` `+9`(라우터 4 · 리다이렉트 4 ·
경계 1) · `l10n` `+10` · `design_system` `+42`. **에뮬레이터 8 시나리오 미실행 — 이 환경에 Android
SDK 없음, 다음 세션.** APK · iOS 빌드도 아직 한 번도 하지 않았다.

## 다음 할 일

1. **에뮬레이터 검증 8 시나리오** — [기획서 §8](overview.md#8-개발-단계) 순서대로. 첫
   `flutter build apk --debug` 로 AGP 9 템플릿에서 플러그인이 빌드되는지부터 본다
   ([개발환경 §1](../../../docs/setup.md#1-앱-실행)). feature 별 `testing.md` 의 "에뮬레이터" 표에 결과를
   채우고, 고친 것은 `fix(walk): …` 커밋과 해당 `history.md` 에 남긴다(통근 `d1c7d8e` 선례)
2. **리뷰 문서의 열린 항목** — [구현 리뷰](audits/2026-10-03-implementation-review.md)의 "다음 단계에
   넘기는 것" 표와 열린 질문. 남은 것: 크기 수치의 토큰화(④ T3 · ⑦ F2), `WalkFormat.duration`
   경계(⑤ I2), Android 정확도 `best` vs 계획 `high`(실기기에서 결정), `POST_NOTIFICATIONS` 런타임 요청,
   미테스트 경로(카메라 · 사진 없는 썸네일 fallback)
3. **W5 social 기획** — v2. Supabase 소셜 피드를 얹는다. 착수 시 `features/social/plan.md`
4. **리팩터링 후보** — [설계 §7](../../../docs/superpowers/specs/2026-10-03-walk-app-design.md#7-리팩터링-후보--이-앱을-만들며-확인된-것):
   `LocationGateway` 가 `feature_commute` · `feature_walk` 에 두 벌, `FailureCode` · ARB 의 앱별 증가,
   `AppAvatar.nickname`, 시계 추상 부재. 모노레포 공통 작업이라 [전체 진행 현황](../../../docs/status.md)에서 다룬다
