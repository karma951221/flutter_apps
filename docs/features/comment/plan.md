# F6 comment — 계획 (스키마 · 권한 · usecase)

> [문서 허브](../../README.md) · [기획 F6](../../overview.md) · [스키마](../../schema.md) · [아키텍처](../../architecture.md)

> 상태: **착수 전** · 작성 2026-08-23 · 이 문서는 화면이 아니라 **데이터·권한·usecase**를 확정한다.
> 화면과 상태 전이는 구현 시점에 이 문서에 절을 더한다.

## 범위

게시물에 댓글을 달고, 댓글에 답글을 단다. **depth는 2단 고정** — 답글의 답글은 없다.
내 댓글을 삭제한다. 댓글과 답글 모두 [반응](../reaction/plan.md)을 받고, 둘 다 커서
페이지네이션으로 읽는다.

댓글의 두 번째 부모(게시물이 아닌 다른 엔티티의 댓글)는 아직 없다. [기획 §7의 명명
규칙](../../overview.md)대로 `post_comments`로 두고, 생기면 `photo_comments`를
**추가**한다. 기존 테이블은 손대지 않는다.

## 확정한 결정과 근거

| 항목 | 결정 | 근거 |
|---|---|---|
| depth | **2단 고정**, 컬럼은 무한 depth를 담을 수 있게 | 제한을 스키마가 아니라 트리거에 두면 나중에 다단계로 바꿔도 마이그레이션이 필요 없다 |
| 조회 구조 | 부모 목록과 답글 목록이 **별도 조회** | 답글에 각자 반응 상태가 붙는다. 답글을 `jsonb` 배열로 동봉하면 앱 상태가 중첩되고, 반응은 이 앱에서 가장 자주 눌리는 동작이다 |
| 답글 로딩 | 부모를 눌렀을 때 지연 로딩. 목록에는 **`reply_count`만** 동봉 | 첫 조회 페이로드가 답글 수에 좌우되지 않는다 |
| 정렬 | 부모·답글 모두 **오래된 순** (`created_at asc, id asc`) | 전역 규칙 `desc`는 피드의 규칙이다. 대댓글이 있는 목록에서 최신순은 대화 흐름이 깨진다. 커서의 `id` tie-break는 방향과 무관하게 지킨다 |
| 본문 길이 | **1~300자** (`btrim` 기준) | 게시물(500자)보다 짧게. 댓글은 목록에서 여러 개가 한 번에 읽혀야 한다 |
| 수정 | **없음** | [기획 F6](../../overview.md)의 범위 그대로. `updated_at` 컬럼도 만들지 않는다. 필요해지면 컬럼·트리거·정책을 더하는 마이그레이션 하나다 |
| 삭제 권한 | **댓글 작성자 본인만** | 게시물 작성자에게 남의 댓글 삭제권을 주는 것은 검열 권한이다. 부적절한 댓글 대응은 F7 신고·차단이 맡는다 |
| 삭제된 댓글 | **부모는 남기고 본문만 가린다. 답글은 그냥 숨긴다** | 답글은 자식을 가질 수 없으므로(2단 고정) 숨겨도 고아가 생기지 않는다 |

## 데이터 · 권한

확정된 스키마의 단일 기준은 [스키마 문서](../../schema.md)다. 아래는 마이그레이션에
담을 의도이며, 적용 후 스키마 문서를 같은 커밋에서 갱신한다.

### 테이블

```sql
create table public.post_comments (
  id         uuid        primary key default gen_random_uuid(),
  post_id    uuid        not null references public.posts (id) on delete cascade,
  parent_id  uuid        references public.post_comments (id) on delete cascade,
  author_id  uuid        not null default auth.uid()
                         references public.profiles (id) on delete cascade,
  content    text        not null,
  created_at timestamptz not null default now(),
  deleted_at timestamptz,

  constraint post_comments_content_length check (
    char_length(btrim(content)) between 1 and 300
  )
);
```

### 인덱스 — 조회 방향이 asc다

```sql
-- 부모 댓글 커서
create index post_comments_root_idx
  on public.post_comments (post_id, created_at, id)
  where parent_id is null;

-- 답글 커서
create index post_comments_reply_idx
  on public.post_comments (parent_id, created_at, id)
  where parent_id is not null and deleted_at is null;
```

**부모 인덱스에는 `deleted_at is null`을 일부러 넣지 않았다.** 삭제된 부모도 살아 있는
답글이 있으면 목록에 나와야 하므로 조회가 삭제행을 읽는다. [스키마 문서](../../schema.md)의
"소프트 삭제 테이블의 커서 인덱스는 부분 인덱스" 규칙에서 의도적으로 벗어나는 지점이고,
그 이유를 스키마 문서에 함께 적는다. 답글은 삭제되면 항상 숨기므로 부분 인덱스를 그대로 쓴다.

답글 인덱스는 `reply_count` 서브쿼리와 "살아 있는 답글이 있는가" 검사도 함께 탄다.

### 2단 제한 트리거

CHECK로는 표현할 수 없다. BEFORE INSERT 트리거가 네 가지를 본다.

| 검사 | 거부 이유 |
|---|---|
| 부모가 존재하는가 | 없는 댓글에 답글을 달 수 없다 |
| 부모가 이미 답글인가 | depth 3 차단 |
| **부모가 같은 게시물의 댓글인가** | 다르면 댓글 하나가 두 게시물에 걸친다 |
| 부모가 삭제되지 않았는가 | 삭제된 댓글에는 답글을 달 수 없다 |

셋째는 [기획 F6](../../overview.md)에 없던 구멍이라 여기서 메운다.

이 함수는 **`security definer`여야 한다.** 아래에서 클라이언트에게 `content`의 SELECT
권한을 주지 않으므로, invoker로 두면 트리거가 부모 행을 읽지 못해 삽입 자체가 막힌다.

### 조회 경계 — `post_comments_visible`

이 feature의 가장 까다로운 지점이다. [기획 F6](../../overview.md)은 "삭제된 부모를
목록에 남긴다"고 정했는데, 그것이 [스키마 문서](../../schema.md)의 두 규칙과 충돌한다.

- 조회 정책이 `deleted_at is null`을 강제한다
- 모든 뷰는 `security_invoker = on`이다

둘을 지키면 삭제행이 RLS 단계에서 사라지므로 뷰에서 되살릴 방법이 없다. 반대로 테이블
정책을 열면 **삭제된 댓글의 본문이 테이블 직접 조회로 샌다** — 뷰에서 마스킹해도
`security_invoker = on`이면 조회자에게 기반 테이블의 본문 읽기 권한이 필요하므로
우회된다.

**결정: 이 뷰만 `security_invoker = off` 예외로 두고, `content`를 컬럼 GRANT에서 뺀다.**

```sql
create view public.post_comments_visible as   -- security_invoker 미지정 = off
select
  c.id, c.post_id, c.parent_id, c.author_id,
  case when c.deleted_at is null then c.content end as content,
  c.created_at,
  c.deleted_at,
  pr.nickname   as author_nickname,
  pr.avatar_url as author_avatar_url,
  (select count(*) from public.post_comments r
    where r.parent_id = c.id and r.deleted_at is null) as reply_count,
  ... reaction_counts jsonb ...,
  ... my_reaction text ...
from public.post_comments c
join public.profiles pr on pr.id = c.author_id
join public.posts    p  on p.id = c.post_id and p.deleted_at is null
where c.deleted_at is null
   or (c.parent_id is null
       and exists (select 1 from public.post_comments r
                    where r.parent_id = c.id and r.deleted_at is null));
```

집계 컬럼의 형태는 [F5 계획](../reaction/plan.md)에 있다. `auth.uid()`는 JWT 클레임을
읽는 세션 GUC 기반이라 definer 뷰 안에서도 조회자 기준으로 동작한다 — `my_reaction`이
여기 의존한다.

**뷰가 RLS를 우회하므로 RLS가 대신 해주던 것을 뷰 안에 직접 써야 한다.** 지금 진 부채가 둘이다.

1. `join posts ... and p.deleted_at is null` — 삭제된 게시물의 댓글 제외
2. **F7의 차단 필터를 이 뷰에도 손으로 넣어야 한다** — `posts_with_author`와 두 곳이 된다

삭제된 부모 행은 `content`만 `null`이 된다. `author_id` · 닉네임 · `reply_count`는
그대로 나온다. 표시는 앱이 정한다.

### GRANT — A안의 핵심

```sql
grant select (id, post_id, parent_id, author_id, created_at, deleted_at)
  on public.post_comments to anon, authenticated;          -- ★ content 없음
grant insert (post_id, parent_id, content)
  on public.post_comments to authenticated;
grant select on public.post_comments_visible to anon, authenticated;
```

`content`에 닿는 유일한 경로가 뷰이고, 뷰가 삭제행의 본문을 지운다. 이것은 스키마에 새
예외를 만드는 게 아니라 이미 있는 규칙("GRANT는 컬럼 단위로 최소한만 준다")을 그대로
적용한 결과다.

나머지 컬럼에 SELECT를 남기는 이유는 둘이다.

- `insert ... returning id, created_at`이 동작해야 한다 (왕복 한 번으로 작성)
- `posts_with_author`의 `comment_count` 서브쿼리가 `post_id` · `deleted_at`을 읽어야
  한다 — 그 뷰는 계속 `security_invoker = on`이라 조회자 권한으로 실행된다

`update` · `delete` 권한은 주지 않는다.

### RLS

```sql
-- 조회: 뷰의 가시성과 같은 규칙 (테이블 직접 조회 경로에도 같은 경계를 건다)
create policy "post_comments_select_visible"
  on public.post_comments for select to authenticated, anon
  using (
    deleted_at is null
    or (parent_id is null
        and exists (select 1 from public.post_comments r
                     where r.parent_id = post_comments.id
                       and r.deleted_at is null))
  );

-- 작성: 세션 사용자와 작성자가 일치할 때만
create policy "post_comments_insert_own"
  on public.post_comments for insert to authenticated
  with check ((select auth.uid()) = author_id);
```

UPDATE · DELETE 정책은 두지 않는다. 수정 기능이 없고, 삭제는 아래 함수 전용이다.

### `soft_delete_post_comment(comment_id uuid) → boolean`

댓글을 삭제하는 유일한 경로다. `soft_delete_post`와 같은 패턴이고, `security definer`가
RLS를 우회하므로 **함수 안의 `author_id = (select auth.uid())`가 권한 경계 그 자체다.**

```sql
update public.post_comments
   set deleted_at = now()
 where id = comment_id
   and author_id = (select auth.uid())
   and deleted_at is null;
```

[스키마 문서 §8의 함정](../../schema.md)("소프트 삭제를 UPDATE로 하면 42501로 거부된다")이
여기에도 그대로 적용된다. 답글이나 답글 없는 부모를 지우면 새 행이 조회 정책에 걸리므로,
클라이언트 UPDATE로는 애초에 불가능하다.

## usecase

```
features/comment/
├── domain/
│   ├── entity/post_comment.dart      { id, postId, parentId, author, content?,
│   │                                    createdAt, isDeleted, replyCount, reactions }
│   ├── comment_policy.dart           maxLength 300 · trim · 검증
│   ├── repository/comment_repository.dart
│   └── usecase/
│       ├── comment_use_case.dart     ← presentation이 주입받는 facade
│       └── scenario/
│           ├── get_comments_scenario.dart
│           ├── get_replies_scenario.dart
│           ├── add_comment_scenario.dart
│           └── delete_comment_scenario.dart
└── data/
    ├── cursor/comment_cursor.dart    ← asc 방향 커서 (created_at, id)
    ├── datasource/ · dto/ · mapper/
    └── repository/comment_repository_impl.dart
```

| 동작 | 시그니처 |
|---|---|
| 댓글 목록 | `Future<Result<CursorPage<PostComment>>> getComments(String postId, {String? cursor})` |
| 답글 목록 | `Future<Result<CursorPage<PostComment>>> getReplies(String parentId, {String? cursor})` |
| 작성 | `Future<Result<PostComment>> addComment(String postId, {String? parentId, required String content})` |
| 삭제 | `Future<Result<bool>> deleteComment(String commentId)` |

두 조회는 **같은 뷰**를 읽는다. `getComments`는 `parent_id is null`, `getReplies`는
`parent_id = ?`로 좁힐 뿐이다.

`content`가 nullable인 것이 "삭제됐지만 남아 있는 부모"를 표현한다. `isDeleted`는
`deletedAt != null`의 별칭이며 둘을 함께 두는 이유는, 앱이 `content == null`을
"본문 없음"이 아니라 **"삭제됨"**으로 읽어야 하기 때문이다.

`addComment`는 `returning id, created_at`으로 서버 값만 받고 본문·작성자는 앱이 이미
아는 값으로 채워 엔티티를 완성한다. 왕복 한 번이다. 답글을 달면 부모의 `replyCount`를
앱에서 하나 올린다.

`comment_policy.dart`의 길이 검증은 UX이고 **최종 판정은 DB의 CHECK다.** 2단 제한도
같다 — 앱이 답글에 답글 버튼을 그리지 않는 것은 UX이고, 경계는 트리거다.

### 커서

방향만 다르고 규칙은 [아키텍처 3-1](../../architecture.md)과 같다.

- 조건: `created_at > c.created_at or (created_at = c.created_at and id > c.id)`
- 형식을 아는 곳은 `features/comment/data/cursor/`뿐이다. domain과 presentation은
  불투명 문자열로만 다룬다
- `limit + 1`을 요청해 다음 페이지 유무를 판단하고, **잘라낸 뒤 실제로 돌려주는 마지막
  항목**으로 다음 커서를 만든다

## 다른 feature에 미치는 변경

| 대상 | 변경 |
|---|---|
| `posts_with_author` | `comment_count integer` 추가 — 살아 있는 댓글과 답글 전부 |
| `features/feed` | `FeedPost`에 `commentCount` 추가 |
| `features/post` | `PostAuthor`를 `PostComment`가 재사용한다 (domain만 참조) |
| `features/reaction` | `comment_reactions`의 대상이 된다 ([F5](../reaction/plan.md)) |

## 완료 조건

- [ ] 게시물에 댓글을 달고, 댓글에 답글을 단다
- [ ] 답글에 답글을 다는 삽입이 DB에서 거부된다
- [ ] 다른 게시물의 댓글을 `parent_id`로 지정한 삽입이 거부된다
- [ ] 댓글 목록과 답글 목록이 각각 오래된 순 커서 페이지네이션으로 이어진다
- [ ] 댓글 목록 조회 한 번에 `reply_count`와 반응 요약이 함께 온다
- [ ] 내 댓글만 삭제되고, 남의 댓글 삭제 시도는 `false`를 돌려준다
- [ ] 답글이 있는 부모를 삭제하면 본문만 사라지고 답글은 남는다
- [ ] 답글을 삭제하면 목록에서 사라진다
- [ ] 답글이 전부 삭제된 부모는 목록에서 사라진다
- [ ] 감정을 댓글과 답글 양쪽에 남길 수 있다

## 검증 항목 (로컬 Supabase)

- [ ] **삭제된 댓글의 본문을 어떤 경로로도 읽을 수 없다** — 뷰는 `null`, 테이블 직접
      조회는 42501(`content` GRANT 없음)
- [ ] 삭제된 게시물의 댓글이 뷰에서 빠진다 (RLS가 아니라 뷰의 join이 막는다)
- [ ] `created_at`이 같은 댓글이 여러 개일 때 asc 커서에 중복·누락이 없다
- [ ] `insert ... returning id, created_at`이 컬럼 단위 GRANT와 충돌하지 않는다
- [ ] 300자를 넘는 본문과 공백만 있는 본문을 CHECK가 거부한다
- [ ] 비로그인(anon) 조회에서 목록은 보이고 `my_reaction`은 `null`이다

## 범위 밖

- 댓글 수정 — 넣기로 하면 `updated_at` · 트리거 · `grant update (content)` · UPDATE 정책
- 3단 이상 depth — 컬럼은 이미 담을 수 있다. 트리거의 검사를 풀고 조회를 재설계하면 된다
- 댓글 알림 · 멘션 — 푸시는 v1.1 범위다
- 차단한 사용자의 댓글 제외 — F7 완료 후 `post_comments_visible`의 `where`에 넣는다
- 게시물 작성자의 댓글 삭제권 — 필요해지면 함수 조건에 `or 게시물 작성자`를 더하고,
  삭제 주체를 구분해 기록할지 함께 정한다
