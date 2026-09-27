# 진행 현황 — 걷기

> [걷기 허브](README.md) · [계획](plan.md) · [설계](../../../docs/superpowers/specs/2026-09-27-walk-app-design.md) · [전체 진행 현황](../../../docs/status.md)

**걷기 앱 진행 현황의 단일 기준은 이 문서다.** 다른 문서에는 진행 상태를 적지 않는다.

## 단계 요약

| 단계 | 범위 | 상태 |
|------|------|------|
| v1 | 오늘 걸음 · 주간/월간 막대그래프 · 거리/칼로리 (Health Connect) | **코드 완료 · 기기 확인 대기** |

## v1

- [x] **0 설계** — 브레인스토밍, [설계 문서](../../../docs/superpowers/specs/2026-09-27-walk-app-design.md) (2026-09-27)
- [x] **0 폴더 뼈대** — `flutter create`(android), workspace 등록, 계층 폴더
- [ ] **1 실제 폰 데이터 확인** — Health Connect 권한 · 걸음/거리/활동 칼로리가 실제로 있는지 ([설계 §9](../../../docs/superpowers/specs/2026-09-27-walk-app-design.md#9-기기-확인-구현-첫-단계와-마지막-단계))
- [x] **2 도메인** — 엔티티 · 기간 계산 · `ActivityRepository` · `WalkUseCase`
- [x] **3 데이터** — `HealthGateway` · `HealthConnectActivityRepository` · 안드로이드 매니페스트
- [x] **4 접근 상태 화면** — `HealthAccessCubit` · 설치/업데이트/권한 안내
- [x] **5 오늘 카드** — `TodayActivityCubit` · `TodayActivityCard`
- [x] **6 주간 · 월간 탭** — `PeriodActivityCubit` · 막대그래프 · 요약
- [ ] **7 기기 시나리오** — 에뮬레이터 + 실제 폰
- [x] **8 문서** — `history.md` · `testing.md` · 이 문서

커밋: `11d509b` 의존성 · 안드로이드 · gateway → `85c38f3` 도메인 → `fcbce26` 권한 source · 저장소 →
`f2d909d` 문자열 · 포맷 → `73a6afa` cubit → `7718543` 화면 → `2882562` 최종 리뷰 수정.
검증(2026-09-27): `flutter analyze` 0 · `flutter test` 65건 통과 · 디버그 APK 빌드.
판단과 고친 것은 [기록](history.md), 테스트 범위는 [테스트](testing.md).

## 다음 할 일

- 1 · 7단계 — 실제 폰에서 [기기 시나리오](testing.md#기기-시나리오--대기) ⓪~⑦.
  ⓪ 에서 활동 칼로리가 비면 칼로리 타입을 다시 정한다.
- `packages/permission` 은 다른 세션 작업으로 아직 커밋 전이다. walk 는 그것에 의존하므로
  그 커밋이 들어가야 깨끗한 체크아웃에서 빌드된다.
