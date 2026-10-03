# 진행 현황 — 전체

> [문서 허브](README.md) · [아키텍처](architecture.md) · [의존 그래프](dependencies.md)

모노레포 공통 작업과 앱별 한 줄 상태만 둔다. 앱의 세부 진행은 각 앱의 `status.md`가
단일 기준이다.

## 앱

| 앱 | 상태 | 진행 현황 |
|---|---|---|
| trader (daylog) | 0~3.6단계 · 5단계(F10 모의투자) 완료, 4단계(v1.1) 대기 | [트레이더 진행 현황](../apps/trader/docs/status.md) |
| commute (통근) | v1(패키지 경계 시험) 완료 | [통근 진행 현황](../apps/commute/docs/status.md) |
| pawlog (강아지 산책) | v1 구현 완료(W1~W4, 에뮬레이터 검증 전), W5 social(v2) 미정 | [pawlog 진행 현황](../apps/pawlog/docs/status.md) |

## 모노레포

- [x] **모노레포 전환** — `apps/` · `packages/` pub workspace + melos
      ([프롬프트](superpowers/specs/2026-09-12-monorepo-codex-prompt.md))
- [x] **문서 앱별 재배치** — 앱 문서는 `apps/<app>/docs/`, 공통 문서만 `docs/` (2026-09-27)

### 패키지 경계 리팩터링

둘째 앱이 알려준 [설계 §7](superpowers/specs/2026-09-13-commute-app-design.md#7-리팩터링-후보--이-앱을-만들며-확인된-것)
의 후보 목록을 푼다. 셋째 앱이 더한 후보(`LocationGateway` 두 벌 등)는
[pawlog 설계 §7](superpowers/specs/2026-10-03-walk-app-design.md#7-리팩터링-후보--이-앱을-만들며-확인된-것)에 있다. 설계 문서 `superpowers/specs/2026-09-13-package-boundary-design.md` 는
아직 쓰지 않았다(검토 중, 브랜치 `refactor/package-boundary` 예정).
