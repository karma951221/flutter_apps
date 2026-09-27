# 통근(commute) 허브

> [문서 허브](../../../docs/README.md) · [전체 진행 현황](../../../docs/status.md)

집·회사를 지하철역으로 등록해 두고 출근/퇴근 방향으로 지하철 · 버스 · 최적 소요 시간을
보여주는 앱이다. 로그인 · 백엔드 · 외부 API 없음. 앱 코드는 `apps/commute/`, feature
코드는 `packages/features/commute/` 에 있다.

## 문서

| 문서 | 단일 진실 소스 |
|---|---|
| [진행 현황](status.md) | 단계별 체크리스트, 다음 할 일 |
| [계획](plan.md) | 화면 · 도메인 · 데이터 · 상태 · 완료 조건 · 범위 밖 |
| [기록](history.md) | 설계 판단 · 에뮬레이터에서 고친 것 |
| [테스트](testing.md) | 단위 · 위젯 · 라우터 · 경계 검사 범위 |
| [설계](../../../docs/superpowers/specs/2026-09-13-commute-app-design.md) | v1 설계와 §7 리팩터링 후보 |

실행은 [공통 개발환경 §1](../../../docs/setup.md#1-앱-실행)을 따른다. Supabase 없이 바로 뜬다.
