# pawlog(강아지 산책) 허브

> [문서 허브](../../../docs/README.md) · [전체 진행 현황](../../../docs/status.md)

강아지와 산책한 기록을 쌓고 피드로 돌아보는 앱이다. 산책 시작을 누르면 GPS 로 코스를
그리고, 끝나면 강아지 · 사진 · 메모를 붙여 저장한다. v1 은 로그인 · 백엔드 없이 기기에만
저장하고(drift), v2 에서 Supabase 소셜 피드를 얹는다. 앱 코드는 `apps/pawlog/`, feature
코드는 `packages/features/walk/` 에 둘 예정이다(아직 기획 단계).

## 문서

| 문서 | 단일 진실 소스 |
|---|---|
| [진행 현황](status.md) | 단계별 체크리스트, 다음 할 일 |
| [기획서](overview.md) | 한 줄 정의 · 범위 · 기술 스택 · feature 분해(W1~W5) · 데이터 모델 · 개발 단계 · 확정 사항 |
| `features/<name>/` | feature 착수 시 `plan.md`, 완료 시 `history.md` · `testing.md` (아직 없음) |
| [구현 리뷰 · 요약](audits/2026-10-03-implementation-review.md) | 리뷰어 에이전트가 단계 커밋마다 독립적으로 읽고 쓴 소견과 요약 |

실행은 [공통 개발환경 §1](../../../docs/setup.md#1-앱-실행)을 따른다. Supabase 없이 바로 뜬다.
