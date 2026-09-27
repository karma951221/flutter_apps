# 진행 현황 — 걷기

> [걷기 허브](README.md) · [계획](plan.md) · [설계](../../../docs/superpowers/specs/2026-09-27-walk-app-design.md) · [전체 진행 현황](../../../docs/status.md)

**걷기 앱 진행 현황의 단일 기준은 이 문서다.** 다른 문서에는 진행 상태를 적지 않는다.

## 단계 요약

| 단계 | 범위 | 상태 |
|------|------|------|
| v1 | 오늘 걸음 · 주간/월간 막대그래프 · 거리/칼로리 (Health Connect) | **착수 전** (계획 완료) |

## v1

- [x] **0 설계** — 브레인스토밍, [설계 문서](../../../docs/superpowers/specs/2026-09-27-walk-app-design.md) (2026-09-27)
- [x] **0 폴더 뼈대** — `flutter create`(android), workspace 등록, 계층 폴더
- [ ] **1 실제 폰 데이터 확인** — Health Connect 권한 · 걸음/거리/활동 칼로리가 실제로 있는지 ([설계 §9](../../../docs/superpowers/specs/2026-09-27-walk-app-design.md#9-기기-확인-구현-첫-단계와-마지막-단계))
- [ ] **2 도메인** — 엔티티 · 기간 계산 · `ActivityRepository` · `WalkUseCase`
- [ ] **3 데이터** — `HealthGateway` · `HealthConnectActivityRepository` · 안드로이드 매니페스트
- [ ] **4 접근 상태 화면** — `HealthAccessCubit` · 설치/업데이트/권한 안내
- [ ] **5 오늘 카드** — `TodayActivityCubit` · `TodayActivityCard`
- [ ] **6 주간 · 월간 탭** — `PeriodActivityCubit` · 막대그래프 · 요약
- [ ] **7 기기 시나리오** — 에뮬레이터 + 실제 폰
- [ ] **8 문서** — `history.md` · `testing.md` · 이 문서

## 다음 할 일

[실행 계획](../../../docs/superpowers/plans/2026-09-27-walk-app.md)의 Task 1부터. 계획의 Task 1~7 이 위 1~8단계에 대응한다.
