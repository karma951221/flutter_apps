# pawlog(강아지 산책) 허브

> [문서 허브](../../../docs/README.md) · [전체 진행 현황](../../../docs/status.md)

강아지와 산책한 기록을 쌓고 피드로 돌아보는 앱이다. 산책 시작을 누르면 GPS 로 코스를
그리고, 끝나면 강아지 · 사진 · 메모를 붙여 저장한다. v1 은 로그인 · 백엔드 없이 기기에만
저장하고(drift), v2 에서 Supabase 소셜 피드를 얹는다. 앱 코드는 `apps/pawlog/`, feature
코드는 `packages/features/walk/` 에 있다. v1(W1~W4)은 구현을 마쳤고 에뮬레이터 검증은 아직이다
([진행 현황](status.md)).

## 문서

| 문서 | 단일 진실 소스 |
|---|---|
| [진행 현황](status.md) | 단계별 체크리스트, 검증 결과, 다음 할 일 |
| [기획서](overview.md) | 한 줄 정의 · 범위 · 기술 스택 · feature 분해(W1~W5) · 데이터 모델 · 개발 단계 · 확정 사항 |
| W1 dog — [계획](features/dog/plan.md) · [기록](features/dog/history.md) · [테스트](features/dog/testing.md) | 반려견 목록 · 등록 · 수정, 첫 실행 리다이렉트 |
| W2 tracking — [계획](features/tracking/plan.md) · [기록](features/tracking/history.md) · [테스트](features/tracking/testing.md) | GPS 추적기와 진행 화면 |
| W3 record — [계획](features/record/plan.md) · [기록](features/record/history.md) · [테스트](features/record/testing.md) | 산책 저장 · 수정 폼, 사진, 상세 |
| W4 feed — [계획](features/feed/plan.md) · [기록](features/feed/history.md) · [테스트](features/feed/testing.md) | 첫 화면 피드 · 카드 · 추적 상태 배너 |
| [구현 리뷰 · 요약](audits/2026-10-03-implementation-review.md) | 리뷰어 에이전트가 단계 커밋마다 독립적으로 읽고 쓴 소견과 요약 |

feature 문서는 `features/<name>/` 에 착수 시 `plan.md`, 완료 시 `history.md` · `testing.md` 를 둔다.
설계는 [설계 스펙](../../../docs/superpowers/specs/2026-10-03-walk-app-design.md)이지만 화면 · 상태 ·
문자열 키는 각 `plan.md` 가 우선한다.

실행은 [공통 개발환경 §1](../../../docs/setup.md#1-앱-실행)을 따른다. Supabase 없이 바로 뜬다.
