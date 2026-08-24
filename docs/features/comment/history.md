# F6 comment — 구현 기록

> [문서 허브](../../README.md) · [계획](plan.md) · [스키마 §8·§9](../../schema.md) · [테스트](../../testing/features/comment.md)

## 2026-08-24 — 2단 댓글과 삭제된 부모

`post_comments` 한 테이블에 self-FK 로 담고, 2단 제한은 BEFORE INSERT 트리거가
강제한다. 컬럼은 무한 depth 를 담을 수 있으므로 나중에 다단계로 열어도
마이그레이션이 필요 없다.

### 조회 정책에서 재귀에 걸렸다

"삭제됐지만 답글이 남은 부모는 목록에 남긴다"를 테이블의 SELECT 정책에도 그대로
쓰려고 했다. 정책 안에서 `post_comments` 를 서브쿼리로 다시 참조하는 모양이 되고,
PostgreSQL 이 이를 재귀 평가로 판단해 거부한다.

```text
42P17: infinite recursion detected in policy for relation "post_comments"
```

조회뿐 아니라 `insert ... returning` 까지 막혀 작성 경로가 통째로 죽었다.

**가시성 예외는 뷰가 전담하고 정책은 전역 규칙(`deleted_at is null`)대로 단순하게
두는 것**으로 정리했다. 테이블에 SELECT 를 남긴 이유는 `insert ... returning` 과
`posts_with_author` 의 `comment_count` 둘뿐이고 둘 다 살아 있는 행만 본다. 테이블
경로가 뷰보다 **좁은** 것은 유출이 아니므로 안전하다. 함정은
[스키마 §11](../../schema.md)에 남겼다.

### 이 스키마의 첫 `security_invoker = off` 뷰

`post_comments_visible` 만 예외다. `on` 이면 조회 정책이 삭제행을 먼저 가려서
"삭제된 부모"를 되살릴 수 없고, 정책을 넓히면 위의 42P17 이거나 본문 유출이다.

뷰가 RLS 를 우회하므로 RLS 가 해주던 일을 뷰 정의에 손으로 적었다.

- `join posts ... and p.deleted_at is null` — 삭제된 게시물의 댓글 제외
- F7 차단 필터도 이 뷰의 `where` 에 손으로 넣어야 한다 (`posts_with_author` 와 **두 곳**)

본문 유출을 막는 것은 컬럼 GRANT 다. `content` 를 SELECT GRANT 에서 빼서 본문에
닿는 유일한 경로를 뷰로 만들었고, 뷰가 삭제행의 본문을 `null` 로 지운다. 트리거
함수를 `security definer` 로 둔 것도 이 때문이다 — invoker 로는 부모 행의 본문을
읽지 못해 삽입 자체가 막힌다.

### 오래된 순 커서

피드는 최신순이지만 댓글은 오래된 순이다. 대댓글이 있는 목록에서 최신순은 대화
흐름이 깨진다. 방향만 `gt` 로 뒤집고 `id` tie-break 규칙은 그대로 지켰다.

부모 인덱스에는 `deleted_at is null` 부분 조건을 **일부러 넣지 않았다.** 삭제된
부모도 살아 있는 답글이 있으면 조회가 읽어야 하기 때문이다. [스키마 §2](../../schema.md)의
부분 인덱스 규칙에서 의도적으로 벗어난 지점이다.

### 화면이 서버의 판단을 미리 그린다

삭제 직후 목록을 다시 읽지 않기 위해, 앱이 서버 뷰와 같은 판단을 한다 — 답글이
남은 부모는 본문만 지우고 자리를 남기고(`PostComment.asDeleted`), 답글과 답글 없는
부모는 목록에서 뺀다. `copyWith` 로는 `content` 를 `null` 로 되돌릴 수 없어 엔티티에
전용 메서드를 뒀다.

댓글 수는 화면을 나갈 때 `initialCount + countDelta` 로 피드에 돌려준다. 댓글 하나
쓸 때마다 피드를 다시 읽으면 읽던 자리가 사라진다.

## 검증

로컬 Supabase 에 PostgREST 로 확인했다 (앱이 보내는 쿼리와 같은 모양).

| 확인 | 결과 |
|---|---|
| 댓글·답글 작성 (`insert ... returning id, created_at`) | 성공 — 컬럼 GRANT 와 충돌 없음 |
| 답글에 답글 | `400` (트리거) |
| 삭제된 댓글에 답글 | `400` (트리거) |
| 300자 초과 · 공백만 | `400` (CHECK) |
| 남의 댓글 삭제 | `false` |
| 답글 있는 부모 삭제 | `content: null` · `reply_count: 1` 로 목록에 남음 |
| 삭제된 본문을 테이블 직접 조회 | `42501` — `content` GRANT 없음 |
| 답글까지 삭제 | 부모가 목록에서 사라짐 |
| `posts_with_author.comment_count` | 살아 있는 댓글·답글만 셈 |
