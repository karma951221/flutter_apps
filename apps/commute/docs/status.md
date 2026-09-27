# 진행 현황 — 통근

> [통근 허브](README.md) · [계획](plan.md) · [기록](history.md) · [테스트](testing.md) · [전체 진행 현황](../../../docs/status.md)

**통근 앱 진행 현황의 단일 기준은 이 문서다.** 다른 문서에는 진행 상태를 적지 않는다.

## 단계 요약

| 단계 | 범위 | 상태 |
|------|------|------|
| v1 | 패키지 경계 시험 — 가짜 경로 · 역 30개 · 설정 · 홈 | **완료** |

## v1 — 패키지 경계 시험 (완료, 2026-09-13)

모노레포 전환(`feat/monorepo`, [프롬프트](../../../docs/superpowers/specs/2026-09-12-monorepo-codex-prompt.md))
위에 둘째 앱 `apps/commute` 를 얹었다. 통근 시간 앱이지만 목적은 **`packages/` 의 경계
시험**이다 — `core` · `design_system` · `l10n` 만 쓰고 `feature_*` 는 하나도 쓰지 않는다.
설계는 [설계 문서](../../../docs/superpowers/specs/2026-09-13-commute-app-design.md), 화면 · 상태는
[계획](plan.md), 판단과 에뮬레이터에서 고친 것은
[기록](history.md), 테스트는 [테스트 문서](testing.md).
브랜치 `feat/commute-app`.

- [x] **1 패키지 뼈대 + 도메인** — `packages/features/commute`, 엔티티 · 인터페이스 4개 ·
      `CommuteUseCase` · 시나리오 4개, `core` 에 `FailureCode` 5개, ARB 3개 (`c8dad99`)
- [x] **2 데이터 구현** — `FakeTransitRouteRepository` · `AssetStationRepository`(역 30개) ·
      `PrefsCommuteSettingsRepository` · `GeolocatorLocationRepository` + `LocationGateway` (`7221452`)
- [x] **3 앱 뼈대** — `apps/commute`, Supabase 없는 `bootstrap`, 라우터 2경로 + 설정 리다이렉트,
      위치 권한 선언, `package_boundary_test` (`5c0ec79`)
- [x] **4 설정 화면** — `CommuteSettingsCubit` · `StationSearchCubit` · 설정 페이지 · 역 검색 시트 (`d85d1a3`)
- [x] **5 홈 화면** — `CommuteHomeCubit` · 홈 페이지 · 토글 · 배너 · 카드 · `CommuteFormat` (`e0e87eb`)
- [x] **6 에뮬레이터 확인** — 4 시나리오 통과. 권한 거부 뒤 다이얼로그 반복과 설정 복귀 후
      결과 잔존 두 가지를 고쳤다 (`d1c7d8e`)
- [x] **7 문서** — 계획 · 기록 · 테스트 · 진행 현황 · 아키텍처 §1 · 개발환경 · 설계 §7 후보 7~9

검증(2026-09-13): `flutter analyze` 0 · `melos run test` 전체 통과 · `apps/commute` ·
`apps/trader` APK 빌드 · 에뮬레이터 4 시나리오 통과(릴리즈 arm64 APK —
`/data` 부족으로 디버그 APK 설치 불가).

## 다음 할 일

v1 은 경계 시험용이라 경로는 거리로 만든 가짜 값이고 역은 30개뿐이다. 실제로 쓰는 앱이
되려면 [계획 — 범위 밖](plan.md#범위-밖)에 둔 것들을 푼다. 순서는 아직 정하지 않았다.

- 실제 경로 API(ODsay 등) — `TransitRouteRepository` 구현 교체
- 공공데이터 전체 역 목록 — `stations.json` 교체 (설정은 역 id 만 저장하므로 깨지지 않는다)
- 경로 상세 · 실시간 도착 · 출발 알림 · 지도 · 즐겨찾기 · 최근 검색
- [설계 §7](../../../docs/superpowers/specs/2026-09-13-commute-app-design.md#7-리팩터링-후보--이-앱을-만들며-확인된-것)
  7 · 8 — 영어 복수형("1 transfers") · `OriginBanner` 공용 위젯 승격
