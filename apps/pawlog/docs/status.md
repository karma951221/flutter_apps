# 진행 현황 — pawlog

> [pawlog 허브](README.md) · [기획서](overview.md) · [전체 진행 현황](../../../docs/status.md)

**pawlog 앱 진행 현황의 단일 기준은 이 문서다.** 다른 문서에는 진행 상태를 적지 않는다.

## 단계 요약

| 단계 | 범위 | 상태 |
|------|------|------|
| 0 | 기획 — 기획서 · feature 정의 · 허브 | **완료** |
| 1 | 바닥(패키지 뼈대 · drift · 앱 셸) + W1 dog + W2 tracking | 대기 |
| 2 | W3 record + W4 feed + 에뮬레이터 검증 + 문서 | 대기 |
| 3 | W5 social (v2) | 미정 |

## 0 — 기획 (완료, 2026-10-03)

셋째 앱 `apps/pawlog` 의 기획서를 코드보다 먼저 썼다. 사용자 결정(로컬 우선 → Supabase 는
v2, GPS 자동 추적, 강아지 여러 마리, 사진 포함)을 [기획서](overview.md)에 고정하고
feature 를 W1 dog · W2 tracking · W3 record · W4 feed · W5 social 로 나눴다. 브랜치
`claude/dog-walk-log-app-8zyycw`.

- [x] **기획서** — [overview.md](overview.md) §1~§9
- [x] **허브 · 진행 현황** — 이 폴더, [문서 허브](../../../docs/README.md) ·
      [전체 진행 현황](../../../docs/status.md) · [아키텍처 §1](../../../docs/architecture.md) ·
      `CLAUDE.md` 에 행 추가, `documentation_links_test` 스캔 대상에 추가
- [x] **설계 스펙** — [설계 문서](../../../docs/superpowers/specs/2026-10-03-walk-app-design.md)
      (통근 설계 문서와 같은 절 구성, §0~§8)

## 다음 할 일

[기획서 §8](overview.md#8-개발-단계)의 순서대로 간다. 개발 환경에는 Flutter stable
(≥ 3.38.4) 이 필요하다 — 이 저장소의 `pubspec.lock` 이 요구한다.

- ① 패키지 뼈대 + 도메인 → ② drift → ③ 앱 셸 → ④ W1 (착수 시 `features/dog/plan.md`)
