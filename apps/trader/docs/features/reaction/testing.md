# F5 reaction — 테스트 범위

> [테스트 가이드](../../../../../docs/testing/README.md) · [아키텍처](../../../../../docs/architecture.md) · [계획](plan.md) · [스키마 §10](../../schema.md)

감정을 남기고 취소하는 규칙만 담당한다. 개수 표시는 목록을 소유한 feature
([feed](../feed/testing.md) · [comment](../comment/testing.md))가 맡는다.

| 대상 | 시나리오 | 기대 결과 |
|---|---|---|
| `ReactionSummary` | 처음 누름 | 개수가 1 늘고 `mine` 이 그 감정이 된다. |
| `ReactionSummary` | 같은 것을 다시 누름 | 개수가 1 줄고 `mine` 이 null 이 된다. |
| `ReactionSummary` | 취소로 0이 됨 | 항목 자체가 `counts` 에서 사라진다 (`{"like": 0}` 을 남기지 않는다). |
| `ReactionSummary` | 다른 것을 누름 | 이전 감정이 1 줄고 새 감정이 1 늘며 `mine` 이 바뀐다 — 대상당 감정은 하나다. |
| `ReactionSummary` | 내 반응 없이 누름 | 남의 개수는 그대로고 누른 감정만 는다. |
| `ReactionSummary.fromRaw` | 뷰가 내려준 `reaction_counts` · `my_reaction` | 문자열 코드가 `ReactionType` 으로 바뀐다. |
| `ReactionSummary.fromRaw` | 앱이 모르는 감정 코드 | 무시한다. DB 에 감정을 먼저 추가하고 앱을 나중에 배포해도 목록이 깨지지 않는다. |
| `ToggleReactionScenario` | 새 감정 | `setReaction` 을 부르고 다음 상태를 돌려준다. `clearReaction` 은 부르지 않는다. |
| `ToggleReactionScenario` | 같은 감정 재탭 | `clearReaction` 을 부르고 `mine` 이 null 인 상태를 돌려준다. |
| `ToggleReactionScenario` | 전환 (좋아요 → 싫어요) | 삭제 없이 `setReaction` **한 번**이다. 왕복이 둘이면 중간 상태가 화면에 보인다. |
| `ToggleReactionScenario` | 저장 실패 | `Err` 를 그대로 올린다. 화면이 이전 상태로 되돌리는 근거가 된다. |
| `FeedCubit.toggleReaction` | 탭 | 눌린 즉시 목록에 반영하고, 성공하면 서버가 준 요약으로 남는다. |
| `FeedCubit.toggleReaction` | 저장 실패 | 이전 값으로 되돌린다. |
| `FeedCubit.toggleReaction` | 목록에 없는 id | 저장을 시도하지 않고 `Err` 다. |
| `CommentCubit.toggleReaction` | 댓글 / 답글 | 각각 자기 목록에만 반영된다. 답글의 감정이 부모를 건드리지 않는다. |

이 feature 의 재사용은 DB 구조가 아니라 `ReactionSummary.toggled()` 라는 **순수
함수**에서 나온다. 게시물이든 댓글이든 같은 함수로 다음 상태를 계산하므로, 테스트도
대상과 무관하게 이 함수 하나에 몰려 있다.

## 로컬 Supabase 로만 확인되는 것

upsert 와 컬럼 단위 GRANT 의 상호작용, RLS 거부는 mock 으로 드러나지 않는다.
[reaction 계획서의 검증 항목](plan.md)과
[스키마 문서 §10](../../schema.md)의 검증 표를 따른다 — `psql` 이 아니라 PostgREST 를
거쳐야 한다.

실행:

```bash
cd app
flutter test test/features/reaction
```
