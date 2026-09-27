# 트레이더(daylog) 허브

> [문서 허브](../../../docs/README.md) · [전체 진행 현황](../../../docs/status.md)

과거 시세로 매매를 연습하고 그 결과를 소셜 피드에 공유하는 모의투자 앱이다.
Flutter + Supabase. 앱 코드는 `apps/trader/`, feature 코드는 `packages/features/<name>/`,
백엔드는 루트의 `supabase/` 에 있다.

## 앱 문서

| 문서 | 단일 진실 소스 |
|---|---|
| [진행 현황](status.md) | 단계별 체크리스트, 다음 할 일 |
| [기획](overview.md) | 제품 목표, 범위, 결정과 근거 |
| [스키마](schema.md) | 테이블·RLS·GRANT의 현재 모습 |
| [개발환경](setup.md) | 로컬 Supabase · 스키마 변경 · 시세 seed · 백엔드 함정 |
| [E2E](e2e.md) | Patrol 설정, 에뮬레이터 실행, 셀렉터 규칙 |
| [검수 기록](audits/) | 2026-08-24 · 2026-08-27 검수 |

공통 문서(아키텍처 · 의존 그래프 · 도구 버전 · 테스트 컨벤션)는 [문서 허브](../../../docs/README.md)에 있다.

## Feature

폴더마다 `plan.md`(사전 — 화면·상태·완료 조건) · `history.md`(사후 — 설계 판단·버그·검증) ·
`testing.md`(테스트 범위)가 있다.

| Feature | 계획 | 기록 | 테스트 |
|---|---|---|---|
| F1 auth | [plan](features/auth/plan.md) | [history](features/auth/history.md) | [testing](features/auth/testing.md) |
| F2 profile | [plan](features/profile/plan.md) | [history](features/profile/history.md) | [testing](features/profile/testing.md) |
| F3 post | [plan](features/post/plan.md) | [history](features/post/history.md) | [testing](features/post/testing.md) |
| F4 feed | [plan](features/feed/plan.md) | [history](features/feed/history.md) | [testing](features/feed/testing.md) |
| F5 reaction | [plan](features/reaction/plan.md) | [history](features/reaction/history.md) | [testing](features/reaction/testing.md) |
| F6 comment | [plan](features/comment/plan.md) | [history](features/comment/history.md) | [testing](features/comment/testing.md) |
| F7 safety | [신고](features/safety/plan.md) · [차단](features/safety/plan-block.md) | [history](features/safety/history.md) | [testing](features/safety/testing.md) |
| F8 follow | [plan](features/follow/plan.md) | [history](features/follow/history.md) | [testing](features/follow/testing.md) |
| F9 chat | [오픈채팅](features/chat/plan.md) · [DM](features/chat/plan-dm.md) | [history](features/chat/history.md) | [testing](features/chat/testing.md) |
| F10 trade | [plan](features/trade/plan.md) | [history](features/trade/history.md) | [testing](features/trade/testing.md) |
| 설정 | [plan](features/settings/plan.md) | [history](features/settings/history.md) | [testing](features/settings/testing.md) |
| preferences | [다국어](features/preferences/plan-language.md) · [다크모드](features/preferences/plan-theme.md) | [history](features/preferences/history.md) | [testing](features/preferences/testing.md) |
