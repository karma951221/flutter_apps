# 걷기(walk) 허브

> [문서 허브](../../../docs/README.md) · [전체 진행 현황](../../../docs/status.md)

혼자 쓰는 만보기 앱이다. 오늘 걸음 수를 메인에 크게 보여주고, 주간 · 월간 막대그래프로
모아 본다. 걸음 · 거리 · 활동 칼로리는 폰의 헬스 앱이 **Health Connect** 에 기록한 값을
읽기만 한다. 로그인 · 백엔드 없음, 안드로이드만.

코드는 전부 `apps/walk/` 에 있다. commute 와 같이 `lib/` 바로 아래가 계층이다 —
`core/`(앱 셸: `app.dart` · `di/`) · `data/` · `domain/` · `presentation/`. 테스트도
`test/` 아래 같은 구조다.

## 문서

| 문서 | 단일 진실 소스 |
|---|---|
| [진행 현황](status.md) | 단계별 체크리스트, 다음 할 일 |
| [계획](plan.md) | 화면 · 상태 · 완료 조건 · 범위 밖 |
| [설계](../../../docs/superpowers/specs/2026-09-27-walk-app-design.md) | 결정 기록 · 도메인 · 데이터 · 테스트 |

완료하면 같은 폴더에 `history.md`(기록)와 `testing.md`(테스트 범위)를 더한다.
