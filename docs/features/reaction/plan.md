# F5 reaction — 계획 (스키마 · 권한 · usecase)

> [문서 허브](../../README.md) · [기획 F5](../../overview.md) · [스키마](../../schema.md) · [아키텍처](../../architecture.md)

> 상태: **착수 전** · 작성 2026-08-23 · 이 문서는 화면이 아니라 **데이터·권한·usecase**를 확정한다.
> 화면과 상태 전이는 구현 시점에 이 문서에 절을 더한다.

## 범위

게시물과 **댓글**에 감정을 남기고 취소한다. 좋아요·싫어요로 시작하되 종류를 늘릴 수
있게 두고, 개수와 내 반응 상태를 목록 조회가 한 번에 내려준다.

대상이 둘 이상이므로 이 feature의 목적은 기능 자체보다 **재사용 가능한 모양을 잡는
것**이다. 세 번째 대상이 생겼을 때 도메인 코드가 아니라 마이그레이션만 늘어나야 한다.

## 확정한 결정과 근거

| 항목 | 결정 | 근거 |
|---|---|---|
| 대상 확장 | **대상별 테이블** (`post_reactions` · `comment_reactions`) | 폴리모픽 단일 테이블은 FK·cascade를 잃고 RLS가 `target_type` 분기투성이가 된다. 앱의 재사용성은 두 방식이 같다 — 아래 「재사용은 어디서 나는가」 |
| 대상당 감정 수 | **하나** (PK `(user_id, 대상_id)`) | "좋아요 상태에서 싫어요를 누르면 좋아요가 해제된다"는 [기획 F5](../../overview.md)의 규칙이 성립하려면 하나여야 한다. 종류 확장은 PK와 무관하다 |
| 감정 종류 | `text` + CHECK, v1은 `like` · `dislike` | lookup 테이블로 빼면 마이그레이션 없이 추가되지만, 새 감정은 앱에 아이콘·라벨이 있어야 그려지므로 어차피 앱 배포가 필요하다. 이득 없이 조인만 는다 |
| 취소 | **행 삭제** | 자식이 달리지 않는다. 소프트 삭제 규칙은 자식이 생길 수 있는 테이블의 규칙이다 |
| 전환 | **upsert 하나** | 삭제 후 삽입은 왕복이 둘이고 중간 상태가 보인다 |
| 집계 | **실시간 집계를 `jsonb`로** | `like_count` 컬럼으로 박으면 감정을 추가할 때마다 뷰를 고쳐야 한다. 비정규화 카운트 컬럼은 성능 문제가 관측되기 전에 하지 않는다 |
| 노출 | 응답은 모든 종류를 담고, **무엇을 보여줄지는 앱이 고른다** | "싫어요 노출을 백엔드 변경 없이 되돌릴 수 있게" ([기획 F5](../../overview.md))가 이 모양에서 따라온다 |

## 데이터 · 권한

확정된 스키마의 단일 기준은 [스키마 문서](../../schema.md)다. 아래는 마이그레이션에
담을 의도이며, 적용 후 스키마 문서를 같은 커밋에서 갱신한다.

### 테이블

```sql
create table public.post_reactions (
  user_id    uuid        not null default auth.uid()
                         references public.profiles (id) on delete cascade,
  post_id    uuid        not null references public.posts (id) on delete cascade,
  type       text        not null,
  created_at timestamptz not null default now(),

  primary key (user_id, post_id),
  constraint post_reactions_type_valid check (type in ('like', 'dislike'))
);

create index post_reactions_post_id_type_idx
  on public.post_reactions (post_id, type);
```

`comment_reactions`는 `post_id` → `comment_id`(`references public.post_comments`)만
바뀌고 나머지가 같다. 인덱스는 `(comment_id, type)`.

`created_at`은 정렬·표시에 쓰지 않는다. 그래서 전환(upsert)에서 갱신되지 않는 것이
문제가 되지 않는다 — 필요해지면 그때 `updated_at`을 더한다.

### RLS

```sql
-- 조회: 개수는 공개 정보다
create policy "post_reactions_select_all"
  on public.post_reactions for select to authenticated, anon using (true);

-- 삽입: 본인 것만, 그리고 살아 있는 대상에만
create policy "post_reactions_insert_own"
  on public.post_reactions for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (select 1 from public.posts p
                 where p.id = post_id and p.deleted_at is null)
  );

-- 삭제: 본인 것만 (수정 정책은 아래 GRANT 항목에 있다)
create policy "post_reactions_delete_own"
  on public.post_reactions for delete to authenticated
  using ((select auth.uid()) = user_id);
```

`comment_reactions`의 삽입 정책은 `exists`가 `post_comments`를 보고
`deleted_at is null`을 확인한다. **삭제된 게시물·댓글에는 반응을 남길 수 없고, 그
판단은 앱이 아니라 DB가 한다.**

### GRANT

```sql
grant select                 on public.post_reactions to anon, authenticated;
grant insert (post_id, type) on public.post_reactions to authenticated;
grant update (post_id, type) on public.post_reactions to authenticated;
grant delete                 on public.post_reactions to authenticated;
```

`update`에 `post_id`가 들어가는 이유는 upsert 때문이다. PostgREST 는
`on conflict … do update set`에 **페이로드의 모든 컬럼**을 넣으므로,
`{post_id, type}`를 보내면 `set post_id = excluded.post_id, type = excluded.type`가
된다. `type`만 GRANT 하면 전환이 42501 로 막힌다.

그래서 UPDATE 정책의 `with check`를 INSERT 와 **같은 강도**로 맞춘다 — 그러지
않으면 `post_id`를 바꿔 삭제된 게시물로 반응을 옮길 수 있다.

```sql
create policy "post_reactions_update_own"
  on public.post_reactions for update to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and exists (select 1 from public.posts
                 where posts.id = post_reactions.post_id
                   and posts.deleted_at is null)
  );
```

`user_id`는 INSERT 목록에 없다. `default auth.uid()`로만 채워지므로 위조 경로가 없다.
`delete`를 주는 것은 이 프로젝트에서 예외적인데, 반응은 자식이 달리지 않아 소프트
삭제의 이유(참조 무결성·복원)가 없기 때문이다.

### 집계 — 조회 뷰에 넣는다

반응 수와 내 반응은 **대상 목록을 내려주는 뷰 안**에서 계산한다. 화면마다 따로 조회하면
N+1이 되고, 언젠가 한 화면에서 빠뜨린다.

| 뷰 | 더해지는 컬럼 |
|---|---|
| `posts_with_author` (기존) | `reaction_counts jsonb` · `my_reaction text` · `comment_count integer` |
| `post_comments_visible` ([F6](../comment/plan.md)) | `reaction_counts jsonb` · `my_reaction text` |

```sql
coalesce((
  select jsonb_object_agg(x.type, x.n)
    from (select type, count(*) as n
            from public.post_reactions r
           where r.post_id = p.id
           group by type) x
), '{}'::jsonb) as reaction_counts,

(select r.type from public.post_reactions r
  where r.post_id = p.id and r.user_id = auth.uid()) as my_reaction
```

`auth.uid()`는 JWT 클레임을 읽는 세션 GUC 기반이라 뷰의 실행 역할과 무관하게 동작한다.
`post_comments_visible`이 `security_invoker = off`인데도 `my_reaction`이 조회자 기준으로
나오는 이유다 ([F6 계획](../comment/plan.md) 참조).

## usecase

```
features/reaction/
├── domain/
│   ├── entity/reaction_type.dart      enum { like, dislike }
│   ├── entity/reaction_target.dart    sealed  .post(id) | .comment(id)
│   ├── entity/reaction_summary.dart   { Map<ReactionType,int> counts, ReactionType? mine }
│   ├── repository/reaction_repository.dart
│   └── usecase/
│       ├── reaction_use_case.dart                    ← presentation이 주입받는 facade
│       └── scenario/toggle_reaction_scenario.dart
└── data/
    ├── datasource/supabase_reaction_data_source.dart  ← 대상 → 테이블·컬럼 매핑의 유일한 곳
    ├── dto/ · mapper/
    └── repository/reaction_repository_impl.dart
```

| 계층 | 시그니처 |
|---|---|
| facade | `Future<Result<ReactionSummary>> toggle(ReactionTarget target, ReactionType tapped, ReactionSummary current)` |
| repository | `Future<Result<void>> setReaction(ReactionTarget, ReactionType)` · `Future<Result<void>> clearReaction(ReactionTarget)` |
| 순수 정책 | `ReactionSummary toggled(ReactionType tapped)` — 다음 상태를 계산한다 |

`toggle`이 현재 상태를 인자로 받는 이유: "같은 걸 다시 누르면 취소"를 도메인에서
판정하려면 현재 값이 필요한데, DB에서 다시 읽으면 왕복이 하나 늘고 낙관적 업데이트와
상충한다. **정책은 도메인이 갖고, 상태는 호출자가 준다.**

`ReactionTarget` → 테이블 매핑은 datasource 한 함수에만 둔다.

```dart
({String table, String column}) _tableFor(ReactionTarget target) => switch (target) {
  ReactionPostTarget()    => (table: 'post_reactions',    column: 'post_id'),
  ReactionCommentTarget() => (table: 'comment_reactions', column: 'comment_id'),
};
```

### 재사용은 어디서 나는가

재사용의 실체는 DB 구조가 아니라 **`ReactionSummary.toggled()`라는 순수 함수**다.
게시물이든 댓글이든 같은 함수로 다음 상태를 계산하고, 같은 facade를 호출한다. 대상이
셋째로 늘면 바뀌는 것은 `ReactionTarget`의 변형 하나와 `_tableFor`의 줄 하나,
그리고 마이그레이션이다. domain과 presentation은 손대지 않는다.

폴리모픽 단일 테이블을 택했다면 `_tableFor`가 문자열 하나로 줄었을 뿐, 위 구조는
그대로였다. 그 차이만큼을 FK·cascade·RLS 단순함과 바꾸지 않기로 했다.

### 상태는 목록이 갖는다

반응 전용 Bloc/Cubit을 두지 않는다. `ReactionSummary`는 목록 항목 안에 산다
(`FeedPost.reactions` · `PostComment.reactions`). 낙관적 업데이트는 목록을 소유한 쪽이
한다 — [아키텍처 규칙 ⑥](../../architecture.md).

```
탭 → toggled() 로 즉시 목록 갱신 → facade 호출 → 실패하면 이전 ReactionSummary 로 복원
```

`FeedCubit.applyReaction(postId, next)` · `CommentCubit.applyReaction(commentId, next)`.
기존 `prependPost` / `replacePost` / `removePost`와 같은 결이다.

## 다른 feature에 미치는 변경

| 대상 | 변경 |
|---|---|
| `posts_with_author` | `reaction_counts` · `my_reaction` · `comment_count` 추가 |
| `features/feed` | `FeedPost`에 `reactions` · `commentCount` 추가, DTO·mapper 갱신, `applyReaction` |
| `features/comment` | `PostComment`가 `reactions`를 갖는다 ([F6](../comment/plan.md)) |

feed와 comment는 reaction의 **`domain` 계층만** 참조한다. DTO는 각자 갖는다.

## 완료 조건

- [ ] 게시물·댓글에 좋아요와 싫어요를 남기고, 같은 것을 다시 눌러 취소한다
- [ ] 좋아요 상태에서 싫어요를 누르면 좋아요가 해제되고 왕복은 한 번이다
- [ ] 목록 조회 한 번으로 개수와 내 반응이 함께 온다 (항목당 추가 조회 없음)
- [ ] 탭 즉시 화면이 바뀌고, 실패하면 이전 값으로 돌아간다
- [ ] 감정 종류를 하나 더하는 데 필요한 변경이 CHECK 제약 두 곳과 앱의 표시 코드뿐이다

## 검증 항목 (로컬 Supabase)

- [ ] **`upsert`가 동작한다** — `user_id`가 페이로드에 없고 `default auth.uid()`로만
      채워지는 상태에서 `on conflict (user_id, post_id)`가 동작하는지 확인한다.
      GRANT 를 위와 같이 맞춰도 실패하면 대안은 `set_reaction` RPC 하나이고, 그때는
      권한 경계가 함수 본문으로 옮겨간다는 점을 스키마 문서에 적는다
- [ ] `post_id`를 바꿔 삭제된 게시물로 반응을 옮기는 UPDATE 가 거부된다
- [ ] 남의 `user_id`로 삽입·수정·삭제가 거부된다
- [ ] 삭제된 게시물·댓글에 반응 삽입이 거부된다
- [ ] `type`에 정의되지 않은 값을 넣으면 CHECK가 거부한다
- [ ] 반응이 없는 대상의 `reaction_counts`가 `{}`이고 `my_reaction`이 `null`이다
- [ ] 비로그인(anon) 조회에서 개수는 보이고 `my_reaction`은 `null`이다

## 범위 밖

- 비정규화 카운트 컬럼 + 트리거 — 성능 문제가 실제로 관측되기 전에 하지 않는다
- 반응한 사람 목록 화면 — 목록이 필요해지면 커서 페이지네이션을 새로 설계한다
- 반응 알림 — 푸시는 v1.1 범위다
- 차단한 사용자의 반응 제외 — F7 완료 후 집계 서브쿼리에 필터를 넣는다
