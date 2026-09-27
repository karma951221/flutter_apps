# F5 reaction — 구현 기록

> [트레이더 허브](../../README.md) · [계획](plan.md) · [스키마 §10](../../schema.md) · [테스트](testing.md)

## 2026-08-24 — 대상별 테이블과 순수 함수 하나

게시물과 댓글에 좋아요·싫어요를 남긴다. 스키마는 `post_reactions` ·
`comment_reactions` 두 테이블이고 모양이 같다. 앱에서는 `ReactionTarget` 이 둘을
가르고, 그 매핑을 아는 곳은 `SupabaseReactionDataSource._mapping` **한 함수뿐**이다.

재사용의 실체는 DB 구조가 아니라 `ReactionSummary.toggled()` 라는 순수 함수다.
게시물이든 댓글이든 같은 함수로 다음 상태를 계산하고 같은 facade 를 부른다.

### upsert 와 컬럼 GRANT 가 부딪히는 지점

전환(좋아요 → 싫어요)을 upsert 한 번으로 하려면 `update` GRANT 에 **대상 id 컬럼도**
줘야 한다. PostgREST 가 `on conflict ... do update set` 에 페이로드의 모든 컬럼을
넣기 때문이다.

```sql
set post_id = excluded.post_id, type = excluded.type
```

`type` 만 GRANT 하면 전환이 42501 로 막힌다. 그 대가로 UPDATE 정책의 `with check` 를
INSERT 와 글자 그대로 같게 맞췄다 — 그러지 않으면 `post_id` 를 바꿔 반응을 **삭제된
게시물로 옮기는** 경로가 열린다.

이건 `psql` 로는 드러나지 않아 REST 로 확인했다. 결과는 [스키마 §10](../../schema.md)의
검증 표에 있다.

### 반응 전용 Bloc 을 두지 않았다

`ReactionSummary` 는 목록 항목 안에 산다 (`FeedPost.reactions` ·
`PostComment.reactions`). 전용 Cubit 을 만들면 같은 항목의 상태가 두 곳에 생기고,
낙관적 업데이트가 어느 쪽을 믿어야 하는지 모호해진다.

그래서 `FeedCubit` 이 `FeedUseCase` 와 `ReactionUseCase` 둘을 주입받는다.
[규칙 ③](../../../../../docs/architecture.md)은 **feature 당 facade 하나**를 말하므로 어긋나지
않는다.

### 집계는 뷰에서

개수와 내 반응은 `posts_with_author` · `post_comments_visible` 이 항목과 함께
내려준다. 화면마다 따로 조회하면 N+1 이고 언젠가 한 화면에서 빠뜨린다.

개수를 `like_count` 컬럼으로 박지 않고 `jsonb` 로 내린다. 감정을 하나 더할 때
뷰를 고치지 않기 위해서다 — 앱은 모르는 키를 무시한다(`ReactionSummary.fromRaw`).
DB 에 감정을 먼저 추가하고 앱을 나중에 배포해도 목록이 깨지지 않는다.

## 검증

로컬 Supabase 에 PostgREST 로 확인했다.

| 확인 | 결과 |
|---|---|
| 첫 `like` upsert | `201` |
| `dislike` 로 전환 (같은 요청 모양) | `200` — 42501 아님 |
| 뷰 집계 | `{"dislike": 1}` · `my_reaction: "dislike"` |
| 취소(DELETE) | `204` |
| 정의되지 않은 `type: "love"` | `400` (check_violation) |
| 댓글에 좋아요 | `201`, 댓글 목록의 `reaction_counts` 에 반영 |
| 비로그인 조회 | 개수는 보이고 `my_reaction` 은 `null` |
