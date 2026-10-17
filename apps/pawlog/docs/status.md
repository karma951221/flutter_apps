# 진행 현황 — pawlog

> [pawlog 허브](README.md) · [기획서](overview.md) · [구현 리뷰](audits/2026-10-03-implementation-review.md) · [전체 진행 현황](../../../docs/status.md)

**pawlog 앱 진행 현황의 단일 기준은 이 문서다.** 다른 문서에는 진행 상태를 적지 않는다.

## 단계 요약

| 단계 | 범위 | 상태 |
|------|------|------|
| 0 | 기획 — 기획서 · 설계 스펙 · 허브 | **완료** |
| 1 | 바닥(패키지 뼈대 · drift · 앱 셸) + W1 dog + W2 tracking | **완료** |
| 2 | W3 record + W4 feed + 문서 | **완료** — 에뮬레이터 QA 2026-10-04(일부 시나리오 미실행) |
| 2+ | W6 stats — 주 · 월 통계, 피드 요약 줄 | **완료** 2026-10-16 — 에뮬레이터 일부([테스트](features/stats/testing.md#에뮬레이터)) |
| 2+ | W7 session — 일시정지 · 재개, 강제 종료 뒤 복구 | **완료** 2026-10-17 — 에뮬레이터 PASS(거리 제외, [테스트](features/session/testing.md#에뮬레이터)) |
| 2+ | W8 export — 산책 한 건 GPX 내보내기 | **완료** 2026-10-17 — [기록](features/export/history.md) · [테스트](features/export/testing.md) |
| 2+ | W9 backup — 전체 백업 내보내기 · 합쳐 가져오기 | **완료** 2026-10-17 — [기록](features/backup/history.md) · [테스트](features/backup/testing.md) |
| 2+ | W10 favorites — 산책 즐겨찾기 · 피드 필터 | **완료** 2026-10-17 — [기록](features/favorites/history.md) · [테스트](features/favorites/testing.md) |
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

1. ~~**남은 에뮬레이터 시나리오**~~ — 2026-10-17 에 tracking ⑤ · feed ③④ PASS, feed ⑥ 일부(`/walks` 는 라우터 테스트),
   record ⑤ 는 화면에서 갈 길이 없어 위젯 테스트로 둔다. 위치 오류 안내 · 설정 열기 · 빈 피드 안내도 이때 화면에서 봤다
2. **QA 다듬을 것** (2026-10-04 에뮬레이터 QA) — 아래 "디자인 시스템 적용" 에서 P1~P5 를 고쳤다. 남은 것:
   - Android 12+ 스플래시 아이콘 해상도 — 따로 다루는 중
   - ~~앱 테마가 브랜드 주황(`#F08C3A`)이 아니라 기본 남색이다~~ — [디자인 시스템](design.md)(회백지 · 남색 · 연두)이
     대신한다
3. **디자인 시스템 에뮬레이터 재확인** — 2026-10-05 라이트 · 다크 QA 는 PASS([디자인 테스트](features/design/testing.md#에뮬레이터)).
   그때 찾은 Q1~Q4 수정 중 Q2(경로 그림 여백) · Q4(반려견 카메라 — 에뮬레이터 카메라로 찍어 저장) 는 2026-10-17 화면에서 PASS.
   Q1(진행 화면 OSM 출처)은 GPS 점이 있어야 지도가 떠서 GPS 되는 기기에서 본다. 상세 화면 출처는 PASS
4. **리뷰 문서의 열린 항목** — [구현 리뷰](audits/2026-10-03-implementation-review.md)의 "다음 단계에
   넘기는 것" 표와 열린 질문. 남은 것: 크기 수치의 토큰화(④ T3 · ⑦ F2 — 디자인 적용에서 `PawlogSize` 로 옮김, 리뷰 표 확인만), Android 정확도 `best` vs 계획 `high`(실기기에서 결정),
   ~~미테스트 경로(카메라 · 사진 없는 썸네일 fallback)~~ — 2026-10-17 화면에서 둘 다 PASS. `POST_NOTIFICATIONS` 런타임 요청은 2026-10-17 에 했다([tracking 기록](features/tracking/history.md))
5. **W5 social 기획** — v2. Supabase 소셜 피드를 얹는다. 착수 시 `features/social/plan.md`
6. **리팩터링 후보** — [설계 §7](../../../docs/superpowers/specs/2026-10-03-walk-app-design.md#7-리팩터링-후보--이-앱을-만들며-확인된-것):
   남은 것은 `FailureCode` · ARB 의 앱별 증가, `AppAvatar.nickname`, `CLAUDE.md` 경로, `core` 등록을
   앱이 따로 하는 문제. 모노레포 공통 작업이라 [전체 진행 현황](../../../docs/status.md)에서 다룬다.
   2026-10-04 에 푼 것은 아래 "패키지 경계 정리" 에 있다

## W7 session (2026-10-16 ~ 17)

일시정지 · 재개와 강제 종료 뒤 복구. "묻지 말고 알아서" 지시로 오케스트레이터가 골랐다. 설계는
[일시정지 · 복구 설계](../../../docs/superpowers/specs/2026-10-16-pawlog-pause-recovery-design.md), 화면 · 문자열은
[계획](features/session/plan.md). **drift 스키마 v1 → v2**(`active_walks` · `active_walk_points`).

- [x] ① 세션 멈춤 시간 (`ffb6dfd`) · ② 추적기 pause/unpause (`c8929e3`) · ③ 버튼 · 표시 · 문자열 (`3210f23`) ·
      ④ drift v2 저장소 (`b7bf501`) · ⑤ 써 두기 · 복구 (`7419b14` · 리뷰 수정 `5affebb`) — [기록](features/session/history.md) · [테스트](features/session/testing.md)
- [x] 에뮬레이터 ①②④⑤ PASS, ③ 시간 PASS — 거리 이어짐은 GPS 가 앱에 안 들어와 못 봄
- [ ] 남은 것: GPS 가 되는 기기에서 — 추적 중 강제 종료 뒤 다시 열면 포그라운드 알림이 돌아오고 점 · 거리가 이어지는지(복구가 다시 구독하는 경로는 에뮬레이터에서 못 봤다). 그 밖의 넘긴 것: 저장 직후 몇 ms 안에 죽으면 같은 산책이 두 번 저장될 수 있음 · 첫 위치 전 멈춤이면 "위치 찾는 중" 이 남음 — [기록](features/session/history.md)

검증(2026-10-17, `5affebb`): `apps/pawlog` `flutter analyze` 0건 · `flutter test` `+360` · `flutter build apk --debug` 성공.
`packages/location` `+24` · `packages/l10n` `+10` · `apps/trader` `flutter test test/convention` 통과.

## W6 stats (2026-10-16)

사용자가 고른 범위: 기간 요약 · 막대 그래프 · 연속 · 최고 기록, 진입점은 피드 맨 위 요약 줄. 강아지별 누적은 뺐다.
설계는 [통계 설계](../../../docs/superpowers/specs/2026-10-16-pawlog-stats-design.md), 화면 · 상태 · 문자열은
[계획](features/stats/plan.md). 스키마 변경 없음.

- [x] 스펙 · 계획
- [x] ① 계산 정책 (`deb4198`) · ② 문자열 (`e43bcd1`) · ③ 상태 · 표기 (`74fc881`) · ④ 통계 화면 · `/stats`
      (`ac6c3bc` · 리뷰 수정 `6ecb8ac`) · ⑤ 피드 요약 줄 (`ab5e10a`) · 문서 — [기록](features/stats/history.md) · [테스트](features/stats/testing.md)
- [x] 에뮬레이터 — ①③⑤ PASS, ②④ 일부. 새 AVD 에서 GPS 가 앱에 들어오지 않아 거리 0 m 산책으로 봤다
- [ ] 남은 것: GPS 가 되는 기기에서 거리 · 막대 높이 · 지난 기간 이동을 한 번 더 본다. `Medium_Phone_2` 는 Google Play
      서비스 위치가 깨져 있어 안 된다([기록](features/stats/history.md#에뮬레이터-qa-2026-10-16))

검증(2026-10-16, `ab5e10a`): `apps/pawlog` `flutter analyze` 0건 · `flutter test` `+303` · `flutter build apk --debug`
성공. `packages/l10n` `+10`. `apps/trader` `flutter test test/convention` 은 워크트리에 미커밋 `design.md` 가 없어
링크 1건 실패 — 메인 체크아웃에서는 통과

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

## 디자인 시스템 적용 (2026-10-05)

[디자인 시스템](design.md)을 화면 전체에 입혔다. 범위 · 단계는 [계획](features/design/plan.md), 판단 ·
design.md 와 다르게 간 것은 [기록](features/design/history.md), 테스트는 [테스트](features/design/testing.md).

- [x] **1 토큰 · 테마 · 서체** — `lib/presentation/theme/`(`PawlogTheme` · `PawlogColors` · `PawlogTextStyles` ·
      간격 · 모서리 · 모션 · 그림자), 고운돋움 · 개구 · Pretendard 번들(OFL). **P4** 입력칸 테두리 (`fb18539`)
- [x] **2 주 버튼** — `PawlogPrimaryButton`(알약 58 · 누름 0.97 · 비활성 0.4 · 로딩 크로스페이드 · 먹색 `.stop`),
      `PawlogBottomAction` (`1ed0caa`)
- [x] **3 피드 타임라인** — 카드 제거, 날짜 열 · 리드줄, 같은 날 묶음, 달 머리, 하단 시작 버튼 (`be697c8`)
- [x] **4 배너 · 진행 화면 · 경로 선** — 남색 배너 + 연두 점멸, 지도 위 시트 44 숫자, 경로 남색 9 · 연두 5.
      **P1** "산책 준비" 제목(`walkReadyTitle`) (`5f2952a`)
- [x] **5 저장 · 상세 · 반려견** — 메모 개구, 사진 4:3 · 모서리 4, 아바타 겹침 12, 반려견 추가 하단 버튼.
      **P2** 칩 체크 제거 · **P3** 이름 `errorText` · **P5** 카메라 원본 삭제(`core`) (`f63f36a`)
- [x] **6 경로 그리기** — 신규 저장 폼 · 상세에서 1.6초, 애니메이션 줄이기면 바로 완성 (`6e0c902`)

검증(2026-10-05, `6e0c902`): `apps/pawlog` `flutter analyze` 0건 · `flutter test` `+242` ·
`flutter build apk --debug` 성공. `packages/core` `+67` · `packages/l10n` `+10` · `apps/trader`
`flutter test test/convention` 통과. 에뮬레이터 라이트 · 다크 확인은 미실행(다음 할 일 3).

## 디자인 적용 뒤 에뮬레이터 QA (2026-10-05)

Android 17 에뮬레이터, 라이트 · 다크. 디자인 항목(스플래시 · P1~P5 · 타임라인 · 배너 · 시트 · 경로 선 ·
경로 그리기 · 개구 메모 · 4:3 사진 · 다크 화면)은 모두 PASS — [디자인 테스트](features/design/testing.md#에뮬레이터).
dog ②③④ · record ④ 도 이때 PASS. 찾은 네 가지를 고쳤다([기록](features/design/history.md#에뮬레이터-qa-후속-2026-10-05)):

- [x] **Q1** 진행 화면 시트가 OSM 출처 표시를 가림 — 지도를 시트 위 끝 + 모서리까지, `RouteMap.bottomInset` (`b2755d2`)
- [x] **Q2** 경로 그림이 상자에 붙어 보임 — 여백 20 + 테두리 반 폭, 두 축 가운데(저장 폼 · 피드) (`34c7d80`)
- [x] **Q3** 1분 미만 산책이 "0분" — "1분 미만", 정확히 몇 시간이면 "1시간". 리뷰 ⑤ I2 해결 (`324c99f`)
- [x] **Q4** 반려견 사진에 카메라 없음 — 산책과 같은 출처 시트, 카메라는 임시 파일 삭제 (`62fc236`)

검증(2026-10-05, `62fc236`): `apps/pawlog` `flutter analyze` 0건 · `flutter test` `+253` ·
`flutter build apk --debug` 성공. `packages/l10n` `+10`, `apps/trader` `flutter test test/convention` 통과.
수정 뒤 화면 재확인은 다음 할 일 3.
