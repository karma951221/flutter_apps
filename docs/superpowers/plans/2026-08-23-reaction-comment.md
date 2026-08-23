# F5 reaction · F6 comment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 게시물과 댓글에 감정표현(좋아요·싫어요)을 남기고, 게시물에 2단 깊이의 댓글·답글을 달 수 있게 한다.

**Architecture:** 감정표현은 대상별 테이블(`post_reactions` · `comment_reactions`)로 두고 앱의 domain 계층에서 `ReactionTarget`으로 일반화한다. 댓글은 `post_comments` 한 테이블에 self-FK 로 담고 2단 제한을 트리거가 강제하며, 조회는 `security_invoker = off` 전용 뷰로만 한다. 집계(반응 수·내 반응·댓글 수)는 앱 쿼리가 아니라 목록 뷰 안에서 계산해 N+1 을 없앤다.

**Tech Stack:** Flutter · bloc/cubit · freezed 3 · json_serializable · get_it + injectable · supabase_flutter · PostgreSQL(로컬 Supabase) · mocktail · bloc_test

**스펙 (요구사항의 단일 기준):**
- [docs/features/reaction/plan.md](../../features/reaction/plan.md)
- [docs/features/comment/plan.md](../../features/comment/plan.md)

## Global Constraints

모든 태스크의 요구사항에 아래가 암묵적으로 포함된다.

- **Supabase 타입은 `data/` 밖으로 나가지 않는다.** `PostgrestException` · `Session` · `User` 가 `domain/` 이나 `presentation/` 에 등장하면 안 된다 ([아키텍처 규칙 ①](../../architecture.md))
- **Repository 는 `domain/repository/` 의 `abstract interface class` 로 선언하고 `data/repository/` 구현체를 `@LazySingleton(as: …)` 로 등록한다** (규칙 ②)
- **presentation 은 feature 별 UseCase facade 하나만 주입받는다.** scenario 는 `@injectable` 을 붙이지 않는 일반 Dart 클래스다 (규칙 ③)
- **Supabase 예외는 `data/repository/` 의 error handler mixin 이 `Result`/`Failure` 로 변환한다.** domain 은 예외를 보지 않는다 (규칙 ④)
- **feature 간 참조는 `domain` 계층만.** `data` 끼리는 참조하지 않고 DTO 는 각자 만든다 (규칙 ⑥)
- **Freezed 는 두 패턴만 쓴다** ([CLAUDE.md](../../../CLAUDE.md)): 단일 불변 모델은 Primary Constructor, 여러 변형이 필요한 모델은 `sealed class` + named `factory`. 분기는 `when`/`map` 대신 Dart pattern matching `switch`
- **생성 파일(`.freezed.dart` · `.g.dart` · `injection.config.dart`)은 직접 수정하지 않는다.** `dart run build_runner build --delete-conflicting-outputs` 로만 갱신한다
- **테스트 위치는 구현 구조를 그대로 미러링한다.** `app/lib/features/<name>/` ↔ `app/test/features/<name>/`
- **스키마를 바꾸면 같은 커밋에서 [docs/schema.md](../../schema.md) 를 갱신한다.** Studio UI 로 테이블을 만들지 않는다
- **문서 링크는 상대 Markdown 링크만 쓴다.** `app/test/convention/documentation_links_test.dart` 가 깨진 링크를 잡는다
- **커밋 메시지는 한국어 현재형이다.** 기존 이력의 형식을 따른다 — `feat(db): feed_posts를 posts로 바꾸고 소프트 삭제를 도입한다`
- **DB 값과 앱 상수는 일치해야 한다.** 댓글 본문 최대 길이는 DB CHECK 와 `CommentPolicy.maxContentLength` 양쪽에서 **300**
- **감정표현 코드는 `'like'` · `'dislike'` 두 개다.** DB CHECK 와 `ReactionType.code` 가 같은 문자열을 쓴다

**작업 디렉터리:** SQL 은 리포지터리 루트 기준, Dart 명령은 `app/` 기준이다.

**검증 명령:**

```bash
supabase db reset          # 리포지터리 루트. 마이그레이션 전체 재적용
cd app && flutter analyze
cd app && flutter test
```

---

### Task 1: 댓글 스키마 — 테이블 · 트리거 · RLS · 전용 뷰 · 삭제 함수

**Files:**
- Create: `supabase/migrations/20260823170000_add_post_comments.sql`
- Modify: `docs/schema.md` (§1 관계도, 새 절 추가, §8 함정에 예외 2건)

**Interfaces:**
- Consumes: 기존 `public.posts` · `public.profiles` · `public.set_updated_at()`
- Produces: 테이블 `public.post_comments`, 뷰 `public.post_comments_visible`(컬럼 `id, post_id, parent_id, author_id, content, created_at, deleted_at, author_nickname, author_avatar_url, reply_count`), 함수 `public.soft_delete_post_comment(comment_id uuid) → boolean`, 트리거 함수 `public.enforce_comment_depth()`

- [ ] **Step 1: 마이그레이션 파일 작성**

`supabase/migrations/20260823170000_add_post_comments.sql` 에 아래를 그대로 쓴다.

```sql
-- F6 댓글. depth 2 고정, 소프트 삭제, 본문 조회는 전용 뷰로만.
-- 설계 근거는 docs/features/comment/plan.md 에 있다.

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

-- 부모 댓글 커서. 조회 방향이 오래된 순이라 asc 다.
-- deleted_at 부분 조건을 일부러 넣지 않는다 — 삭제된 부모도 살아 있는 답글이
-- 있으면 목록에 나와야 하므로 조회가 삭제행을 읽는다.
create index post_comments_root_idx
  on public.post_comments (post_id, created_at, id)
  where parent_id is null;

-- 답글 커서. 답글은 삭제되면 항상 숨기므로 부분 인덱스를 그대로 쓴다.
-- reply_count 서브쿼리와 "살아 있는 답글이 있는가" 검사도 이 인덱스를 탄다.
create index post_comments_reply_idx
  on public.post_comments (parent_id, created_at, id)
  where parent_id is not null and deleted_at is null;

-- depth 2 제한과 부모 무결성. CHECK 로는 표현할 수 없다.
-- security definer 인 이유: authenticated 에게 content SELECT 권한을 주지 않으므로
-- invoker 로 두면 트리거가 부모 행을 읽지 못해 삽입 자체가 막힌다.
create function public.enforce_comment_depth()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  parent_post_id   uuid;
  parent_parent_id uuid;
  parent_deleted   timestamptz;
begin
  if new.parent_id is null then
    return new;
  end if;

  select post_id, parent_id, deleted_at
    into parent_post_id, parent_parent_id, parent_deleted
    from public.post_comments
   where id = new.parent_id;

  if not found then
    raise exception '부모 댓글이 없습니다' using errcode = '23503';
  end if;
  if parent_parent_id is not null then
    raise exception '답글에는 답글을 달 수 없습니다' using errcode = '23514';
  end if;
  if parent_post_id <> new.post_id then
    raise exception '부모 댓글이 다른 게시물의 댓글입니다' using errcode = '23514';
  end if;
  if parent_deleted is not null then
    raise exception '삭제된 댓글에는 답글을 달 수 없습니다' using errcode = '23514';
  end if;

  return new;
end;
$$;

create trigger post_comments_enforce_depth
  before insert on public.post_comments
  for each row execute function public.enforce_comment_depth();

alter table public.post_comments enable row level security;

-- 뷰의 가시성과 같은 규칙. 테이블 직접 조회 경로에도 같은 경계를 건다.
create policy "post_comments_select_visible"
  on public.post_comments for select to anon, authenticated
  using (
    deleted_at is null
    or (
      parent_id is null
      and exists (
        select 1 from public.post_comments reply
        where reply.parent_id = post_comments.id and reply.deleted_at is null
      )
    )
  );

create policy "post_comments_insert_own"
  on public.post_comments for insert to authenticated
  with check ((select auth.uid()) = author_id);

-- UPDATE · DELETE 정책은 두지 않는다. 수정 기능이 없고 삭제는 아래 함수 전용이다.

-- content 는 GRANT 에서 빠진다. 본문에 닿는 유일한 경로가 아래 뷰이고,
-- 뷰가 삭제행의 본문을 null 로 지운다.
-- 나머지 컬럼을 남기는 이유는 둘이다.
--   1) insert ... returning id, created_at 이 동작해야 한다 (왕복 한 번으로 작성)
--   2) posts_with_author(security_invoker = on)의 comment_count 서브쿼리가
--      post_id · deleted_at 을 조회자 권한으로 읽어야 한다
grant select (id, post_id, parent_id, author_id, created_at, deleted_at)
  on public.post_comments to anon, authenticated;
grant insert (post_id, parent_id, content)
  on public.post_comments to authenticated;

-- ★ 이 뷰만 security_invoker = off(기본값) 다.
-- on 으로 두면 조회 정책이 삭제행을 먼저 가려서 "삭제됐지만 답글이 남은 부모"를
-- 되살릴 수 없고, 정책을 열면 삭제된 본문이 테이블 직접 조회로 샌다.
-- 뷰가 RLS 를 우회하므로 RLS 가 대신 해주던 것을 여기에 직접 쓴다:
--   - join posts ... and p.deleted_at is null (삭제된 게시물의 댓글 제외)
--   - F7 차단 필터가 붙을 자리도 아래 where 다
create view public.post_comments_visible as
select
  c.id,
  c.post_id,
  c.parent_id,
  c.author_id,
  case when c.deleted_at is null then c.content end as content,
  c.created_at,
  c.deleted_at,
  pr.nickname   as author_nickname,
  pr.avatar_url as author_avatar_url,
  (
    select count(*)
      from public.post_comments reply
     where reply.parent_id = c.id and reply.deleted_at is null
  ) as reply_count
from public.post_comments c
join public.profiles pr on pr.id = c.author_id
join public.posts    p  on p.id = c.post_id and p.deleted_at is null
where c.deleted_at is null
   or (
     c.parent_id is null
     and exists (
       select 1 from public.post_comments reply
       where reply.parent_id = c.id and reply.deleted_at is null
     )
   );

grant select on public.post_comments_visible to anon, authenticated;

-- 댓글을 삭제하는 유일한 경로. security definer 가 RLS 를 우회하므로
-- 함수 안의 author_id = (select auth.uid()) 가 권한 경계 그 자체다.
-- 클라이언트 UPDATE 로는 애초에 불가능하다 — docs/schema.md §8 참고.
create function public.soft_delete_post_comment(comment_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected integer;
begin
  update public.post_comments
     set deleted_at = now()
   where id = comment_id
     and author_id = (select auth.uid())
     and deleted_at is null;

  get diagnostics affected = row_count;
  return affected > 0;
end;
$$;

revoke execute on function public.soft_delete_post_comment(uuid) from public, anon;
grant execute on function public.soft_delete_post_comment(uuid) to authenticated;
```

- [ ] **Step 2: 마이그레이션 전체 재적용**

리포지터리 루트에서:

```bash
supabase db reset
```

Expected: 오류 없이 모든 마이그레이션이 적용된다. 실패하면 SQL 을 고치고 다시 돌린다.

- [ ] **Step 3: 스키마 동작을 psql 로 검증**

리포지터리 루트에서 아래를 실행한다. 각 블록의 기대 결과가 주석에 있다.

```bash
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres <<'SQL'
-- 검증용 사용자 두 명과 게시물 하나
insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                        email_confirmed_at, raw_user_meta_data, created_at, updated_at)
values ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000000',
        'authenticated', 'authenticated', 'a@example.com', 'x', now(),
        '{"nickname":"글쓴이"}'::jsonb, now(), now()),
       ('22222222-2222-2222-2222-222222222222', '00000000-0000-0000-0000-000000000000',
        'authenticated', 'authenticated', 'b@example.com', 'x', now(),
        '{"nickname":"이웃"}'::jsonb, now(), now());

insert into public.posts (id, author_id, content)
values ('33333333-3333-3333-3333-333333333333',
        '11111111-1111-1111-1111-111111111111', '첫 글');

insert into public.post_comments (id, post_id, author_id, content)
values ('44444444-4444-4444-4444-444444444444',
        '33333333-3333-3333-3333-333333333333',
        '22222222-2222-2222-2222-222222222222', '부모 댓글');

insert into public.post_comments (id, post_id, parent_id, author_id, content)
values ('55555555-5555-5555-5555-555555555555',
        '33333333-3333-3333-3333-333333333333',
        '44444444-4444-4444-4444-444444444444',
        '11111111-1111-1111-1111-111111111111', '답글');

-- 1) depth 3 거부 — ERROR: 답글에는 답글을 달 수 없습니다
do $$ begin
  insert into public.post_comments (post_id, parent_id, author_id, content)
  values ('33333333-3333-3333-3333-333333333333',
          '55555555-5555-5555-5555-555555555555',
          '22222222-2222-2222-2222-222222222222', '답글의 답글');
  raise exception '실패: depth 3 이 통과했다';
exception when check_violation then
  raise notice 'OK depth 3 거부';
end $$;

-- 2) 다른 게시물의 댓글을 부모로 지정 — 거부
insert into public.posts (id, author_id, content)
values ('66666666-6666-6666-6666-666666666666',
        '11111111-1111-1111-1111-111111111111', '두 번째 글');
do $$ begin
  insert into public.post_comments (post_id, parent_id, author_id, content)
  values ('66666666-6666-6666-6666-666666666666',
          '44444444-4444-4444-4444-444444444444',
          '22222222-2222-2222-2222-222222222222', '남의 글에 붙는 답글');
  raise exception '실패: 다른 게시물의 부모가 통과했다';
exception when check_violation then
  raise notice 'OK 다른 게시물 부모 거부';
end $$;

-- 3) 답글이 있는 부모를 삭제하면 목록에 남고 본문만 사라진다
set local role authenticated;
set local request.jwt.claims to '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
select public.soft_delete_post_comment('44444444-4444-4444-4444-444444444444');
-- 기대: t
select id, content is null as content_hidden, reply_count
  from public.post_comments_visible
 where id = '44444444-4444-4444-4444-444444444444';
-- 기대: 1행, content_hidden = t, reply_count = 1

-- 4) 남의 댓글 삭제는 false
select public.soft_delete_post_comment('55555555-5555-5555-5555-555555555555');
-- 기대: f (55555555 의 작성자는 11111111)

-- 5) content 는 클라이언트가 직접 읽을 수 없다 — ERROR 42501
do $$ begin
  perform content from public.post_comments limit 1;
  raise exception '실패: content 를 읽을 수 있다';
exception when insufficient_privilege then
  raise notice 'OK content 직접 조회 거부';
end $$;
reset role;

-- 6) 답글까지 삭제하면 부모도 목록에서 사라진다
update public.post_comments set deleted_at = now()
 where id = '55555555-5555-5555-5555-555555555555';
select count(*) from public.post_comments_visible
 where post_id = '33333333-3333-3333-3333-333333333333';
-- 기대: 0
SQL
```

Expected: `OK` notice 4건, 3)에서 `content_hidden = t` / `reply_count = 1`, 4)에서 `f`, 6)에서 `0`.
검증이 끝나면 `supabase db reset` 으로 데이터를 되돌린다.

- [ ] **Step 4: `docs/schema.md` 갱신**

세 곳을 고친다.

1. **§1 관계** 의 다이어그램에 `post_comments` 를 넣고, "앞으로 추가될 테이블" 목록에서 `post_comments` 를 뺀다.
2. **`post_images` 절 뒤에 새 절 `post_comments`** 를 추가한다. 위 마이그레이션의 DDL·RLS·GRANT 를 그대로 옮기고, 아래 세 문단을 반드시 포함한다.
   - `post_comments_root_idx` 가 부분 인덱스가 **아닌** 이유 (삭제된 부모를 조회가 읽는다)
   - `content` 가 SELECT GRANT 에서 빠진 이유와, 나머지 컬럼을 남긴 두 가지 이유
   - `enforce_comment_depth()` 가 `security definer` 여야 하는 이유 (content GRANT 가 없어 invoker 로는 부모를 못 읽는다)
3. **새 절 `post_comments_visible` (뷰)** 를 추가하고, `security_invoker = on` 규칙의 **첫 예외**임을 명시한다. §6 의 "앞으로 이 스키마에 추가되는 모든 뷰에 같은 규칙을 적용한다" 문장 바로 뒤에 예외를 가리키는 한 줄을 넣는다. 뷰가 RLS 를 우회하므로 손으로 진 부채 2건(살아 있는 게시물 조건 · F7 차단 필터)을 목록으로 적는다.

- [ ] **Step 5: 문서 링크 검사**

```bash
cd app && flutter test test/convention
```

Expected: PASS

- [ ] **Step 6: 커밋**

```bash
git add supabase/migrations/20260823170000_add_post_comments.sql docs/schema.md
git commit -m "feat(db): 댓글 테이블과 2단 제한 트리거, 전용 조회 뷰를 만든다"
```

---

### Task 2: 감정표현 스키마 — 대상별 테이블 · 뷰 집계 확장

**Files:**
- Create: `supabase/migrations/20260823180000_add_reactions.sql`
- Modify: `docs/schema.md`

**Interfaces:**
- Consumes: Task 1 의 `public.post_comments` · `public.post_comments_visible`, 기존 `public.posts_with_author`
- Produces:
  - 테이블 `public.post_reactions(user_id, post_id, type, created_at)` PK `(user_id, post_id)`
  - 테이블 `public.comment_reactions(user_id, comment_id, type, created_at)` PK `(user_id, comment_id)`
  - `posts_with_author` 에 컬럼 추가: `reaction_counts jsonb` · `my_reaction text` · `comment_count bigint`
  - `post_comments_visible` 에 컬럼 추가: `reaction_counts jsonb` · `my_reaction text`

- [ ] **Step 1: 마이그레이션 파일 작성**

`supabase/migrations/20260823180000_add_reactions.sql` 에 아래를 그대로 쓴다.

```sql
-- F5 감정표현. 대상별 테이블 + 같은 모양. 폴리모픽을 쓰지 않는 이유는
-- docs/features/reaction/plan.md 에 있다.

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

alter table public.post_reactions enable row level security;

create policy "post_reactions_select_all"
  on public.post_reactions for select to anon, authenticated
  using (true);

create policy "post_reactions_insert_own"
  on public.post_reactions for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.posts
      where posts.id = post_reactions.post_id and posts.deleted_at is null
    )
  );

-- with check 를 INSERT 와 같은 강도로 맞춘다. upsert 때문에 post_id 에도
-- UPDATE 권한을 줘야 하는데, 그러지 않으면 삭제된 게시물로 반응을 옮길 수 있다.
create policy "post_reactions_update_own"
  on public.post_reactions for update to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.posts
      where posts.id = post_reactions.post_id and posts.deleted_at is null
    )
  );

create policy "post_reactions_delete_own"
  on public.post_reactions for delete to authenticated
  using ((select auth.uid()) = user_id);

-- update 에 post_id 가 들어가는 이유: PostgREST 는 on conflict ... do update set 에
-- 페이로드의 모든 컬럼을 넣는다. {post_id, type} 을 보내면
-- set post_id = excluded.post_id, type = excluded.type 이 되므로
-- type 만 GRANT 하면 전환이 42501 로 막힌다.
grant select                 on public.post_reactions to anon, authenticated;
grant insert (post_id, type) on public.post_reactions to authenticated;
grant update (post_id, type) on public.post_reactions to authenticated;
grant delete                 on public.post_reactions to authenticated;

create table public.comment_reactions (
  user_id    uuid        not null default auth.uid()
                         references public.profiles (id) on delete cascade,
  comment_id uuid        not null references public.post_comments (id) on delete cascade,
  type       text        not null,
  created_at timestamptz not null default now(),

  primary key (user_id, comment_id),
  constraint comment_reactions_type_valid check (type in ('like', 'dislike'))
);

create index comment_reactions_comment_id_type_idx
  on public.comment_reactions (comment_id, type);

alter table public.comment_reactions enable row level security;

create policy "comment_reactions_select_all"
  on public.comment_reactions for select to anon, authenticated
  using (true);

create policy "comment_reactions_insert_own"
  on public.comment_reactions for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.post_comments
      where post_comments.id = comment_reactions.comment_id
        and post_comments.deleted_at is null
    )
  );

create policy "comment_reactions_update_own"
  on public.comment_reactions for update to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.post_comments
      where post_comments.id = comment_reactions.comment_id
        and post_comments.deleted_at is null
    )
  );

create policy "comment_reactions_delete_own"
  on public.comment_reactions for delete to authenticated
  using ((select auth.uid()) = user_id);

grant select                    on public.comment_reactions to anon, authenticated;
grant insert (comment_id, type) on public.comment_reactions to authenticated;
grant update (comment_id, type) on public.comment_reactions to authenticated;
grant delete                    on public.comment_reactions to authenticated;

-- 집계는 목록 뷰 안에서 한다. 화면마다 따로 조회하면 N+1 이고 언젠가 빠뜨린다.
-- 개수를 like_count / dislike_count 컬럼으로 박지 않고 jsonb 로 내리는 이유는
-- 감정을 하나 추가할 때 뷰를 고치지 않기 위해서다.
create or replace view public.posts_with_author
with (security_invoker = on) as
select
  p.id,
  p.author_id,
  p.content,
  p.created_at,
  p.updated_at,
  pr.nickname as author_nickname,
  pr.avatar_url as author_avatar_url,
  coalesce(images.items, '[]'::jsonb) as images,
  coalesce(reactions.counts, '{}'::jsonb) as reaction_counts,
  mine.type as my_reaction,
  coalesce(comments.total, 0) as comment_count
from public.posts p
join public.profiles pr on pr.id = p.author_id
left join lateral (
  select jsonb_agg(
    jsonb_build_object(
      'id', pi.id,
      'url', pi.url,
      'width', pi.width,
      'height', pi.height,
      'sort_order', pi.sort_order
    ) order by pi.sort_order
  ) as items
  from public.post_images pi
  where pi.post_id = p.id
) images on true
left join lateral (
  select jsonb_object_agg(grouped.type, grouped.total) as counts
  from (
    select r.type, count(*) as total
    from public.post_reactions r
    where r.post_id = p.id
    group by r.type
  ) grouped
) reactions on true
left join lateral (
  select r.type
  from public.post_reactions r
  where r.post_id = p.id and r.user_id = (select auth.uid())
) mine on true
left join lateral (
  select count(*) as total
  from public.post_comments c
  where c.post_id = p.id and c.deleted_at is null
) comments on true;

-- auth.uid() 는 JWT 클레임을 읽는 세션 GUC 기반이라 definer 뷰 안에서도
-- 조회자 기준으로 동작한다. my_reaction 이 여기 의존한다.
create or replace view public.post_comments_visible as
select
  c.id,
  c.post_id,
  c.parent_id,
  c.author_id,
  case when c.deleted_at is null then c.content end as content,
  c.created_at,
  c.deleted_at,
  pr.nickname   as author_nickname,
  pr.avatar_url as author_avatar_url,
  (
    select count(*)
      from public.post_comments reply
     where reply.parent_id = c.id and reply.deleted_at is null
  ) as reply_count,
  coalesce(reactions.counts, '{}'::jsonb) as reaction_counts,
  mine.type as my_reaction
from public.post_comments c
join public.profiles pr on pr.id = c.author_id
join public.posts    p  on p.id = c.post_id and p.deleted_at is null
left join lateral (
  select jsonb_object_agg(grouped.type, grouped.total) as counts
  from (
    select r.type, count(*) as total
    from public.comment_reactions r
    where r.comment_id = c.id
    group by r.type
  ) grouped
) reactions on true
left join lateral (
  select r.type
  from public.comment_reactions r
  where r.comment_id = c.id and r.user_id = (select auth.uid())
) mine on true
where c.deleted_at is null
   or (
     c.parent_id is null
     and exists (
       select 1 from public.post_comments reply
       where reply.parent_id = c.id and reply.deleted_at is null
     )
   );

grant select on public.posts_with_author    to anon, authenticated;
grant select on public.post_comments_visible to anon, authenticated;
```

- [ ] **Step 2: 마이그레이션 전체 재적용**

```bash
supabase db reset
```

Expected: 오류 없이 적용. `create or replace view` 가 컬럼 타입 불일치로 실패하면 해당 뷰를 `drop view` 후 `create view` 로 바꾼다.

- [ ] **Step 3: upsert 와 정책을 REST 로 검증**

이 단계가 이 태스크의 핵심이다. **`psql` 이 아니라 PostgREST 를 거쳐야** GRANT 와 upsert 의 상호작용이 드러난다.

```bash
cd /Users/no/Desktop/socialapp
supabase status   # ANON_KEY 확인
```

로컬 Supabase 에 사용자를 만들고 access token 을 받는다.

```bash
API=http://127.0.0.1:54321
ANON=<supabase status 의 ANON_KEY>

curl -s "$API/auth/v1/signup" -H "apikey: $ANON" -H "Content-Type: application/json" \
  -d '{"email":"r1@example.com","password":"password123","data":{"nickname":"검증자"}}' > /tmp/u1.json
TOKEN=$(python3 -c "import json;print(json.load(open('/tmp/u1.json'))['access_token'])")

# 게시물 하나 작성
POST=$(curl -s "$API/rest/v1/posts" -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -H "Prefer: return=representation" \
  -d '{"content":"반응 검증"}' | python3 -c "import json,sys;print(json.load(sys.stdin)[0]['id'])")

# 1) 좋아요
curl -s -o /dev/null -w '%{http_code}\n' "$API/rest/v1/post_reactions?on_conflict=user_id,post_id" \
  -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -H "Prefer: resolution=merge-duplicates" -d "{\"post_id\":\"$POST\",\"type\":\"like\"}"
# 기대: 201

# 2) 싫어요로 전환 — upsert 한 번, 42501 이 나오면 안 된다
curl -s -o /dev/null -w '%{http_code}\n' "$API/rest/v1/post_reactions?on_conflict=user_id,post_id" \
  -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -H "Prefer: resolution=merge-duplicates" -d "{\"post_id\":\"$POST\",\"type\":\"dislike\"}"
# 기대: 201

# 3) 집계가 뷰로 내려온다
curl -s "$API/rest/v1/posts_with_author?id=eq.$POST&select=reaction_counts,my_reaction,comment_count" \
  -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN"
# 기대: [{"reaction_counts":{"dislike":1},"my_reaction":"dislike","comment_count":0}]

# 4) 취소
curl -s -o /dev/null -w '%{http_code}\n' -X DELETE \
  "$API/rest/v1/post_reactions?post_id=eq.$POST" \
  -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN"
# 기대: 204

# 5) 정의되지 않은 감정은 거부
curl -s -o /dev/null -w '%{http_code}\n' "$API/rest/v1/post_reactions" \
  -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d "{\"post_id\":\"$POST\",\"type\":\"love\"}"
# 기대: 400 (check_violation)
```

Expected: 순서대로 `201` · `201` · 집계 JSON · `204` · `400`.

**2) 가 `403`/`42501` 이면** GRANT 를 고쳐도 통하지 않는 경우다. 그때는 이 태스크를 멈추고 컨트롤러에게 보고한다 — 대안(`set_reaction` RPC)은 스펙 변경이므로 사람이 결정한다.

- [ ] **Step 4: `docs/schema.md` 갱신**

- §1 관계도에 `post_reactions` · `comment_reactions` 를 넣고, "앞으로 추가될 테이블" 목록에서 뺀다
- 새 절 `post_reactions` · `comment_reactions` 를 추가한다. DDL·RLS·GRANT 를 옮기고, **`update` 에 대상 id 컬럼이 들어가는 이유(PostgREST upsert)** 와 **UPDATE `with check` 를 INSERT 와 같은 강도로 맞춘 이유**를 반드시 적는다
- §6 `posts_with_author` 절의 컬럼 목록과 "앞으로 여기에 붙는 것" 문단을 갱신한다 (반응 수·댓글 수·내 반응은 이제 **붙었다**. 남은 것은 F7 차단 필터뿐)
- Task 1 이 만든 `post_comments_visible` 절에 `reaction_counts` · `my_reaction` 을 더한다

- [ ] **Step 5: 검사**

```bash
cd app && flutter test test/convention
```

Expected: PASS

- [ ] **Step 6: 커밋**

```bash
git add supabase/migrations/20260823180000_add_reactions.sql docs/schema.md
git commit -m "feat(db): 게시물·댓글 감정표현 테이블과 목록 뷰 집계를 추가한다"
```

---

### Task 3: `features/reaction` — domain · data · DI

**Files:**
- Create: `app/lib/features/reaction/domain/entity/reaction_type.dart`
- Create: `app/lib/features/reaction/domain/entity/reaction_target.dart`
- Create: `app/lib/features/reaction/domain/entity/reaction_summary.dart`
- Create: `app/lib/features/reaction/domain/repository/reaction_repository.dart`
- Create: `app/lib/features/reaction/domain/usecase/reaction_use_case.dart`
- Create: `app/lib/features/reaction/domain/usecase/scenario/toggle_reaction_scenario.dart`
- Create: `app/lib/features/reaction/data/datasource/reaction_data_source.dart`
- Create: `app/lib/features/reaction/data/datasource/supabase_reaction_data_source.dart`
- Create: `app/lib/features/reaction/data/repository/reaction_repository_error_handler.dart`
- Create: `app/lib/features/reaction/data/repository/reaction_repository_impl.dart`
- Test: `app/test/features/reaction/domain/entity/reaction_summary_test.dart`
- Test: `app/test/features/reaction/domain/usecase/scenario/toggle_reaction_scenario_test.dart`
- Create: `docs/testing/features/reaction.md`
- Modify: `docs/testing/README.md` (feature 목록에 링크 추가)

**Interfaces:**
- Consumes: Task 2 의 테이블 `post_reactions` · `comment_reactions` 와 컬럼 이름(`user_id` · `post_id` · `comment_id` · `type`), 감정 코드 `'like'` · `'dislike'`
- Produces (Task 4 · 5 가 쓴다):
  - `enum ReactionType { like, dislike }` — `String get code`, `static ReactionType? fromCode(String? code)`
  - `sealed class ReactionTarget` — `ReactionTarget.post(String id)` = `ReactionPostTarget`, `ReactionTarget.comment(String id)` = `ReactionCommentTarget`
  - `class ReactionSummary` — `Map<ReactionType,int> counts`, `ReactionType? mine`, `int countOf(ReactionType)`, `bool isMine(ReactionType)`, `ReactionSummary toggled(ReactionType tapped)`, `static ReactionSummary fromRaw(Map<String,int> counts, String? mine)`
  - `abstract interface class ReactionUseCase` — `Future<Result<ReactionSummary>> toggle({required ReactionTarget target, required ReactionType tapped, required ReactionSummary current})`

- [ ] **Step 1: 실패하는 테스트 작성 — `ReactionSummary.toggled`**

`app/test/features/reaction/domain/entity/reaction_summary_test.dart`:

```dart
import 'package:daylog/features/reaction/domain/entity/reaction_summary.dart';
import 'package:daylog/features/reaction/domain/entity/reaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('처음 누르면 개수가 늘고 내 반응이 된다', () {
    const summary = ReactionSummary();

    final next = summary.toggled(ReactionType.like);

    expect(next.countOf(ReactionType.like), 1);
    expect(next.mine, ReactionType.like);
    expect(next.isMine(ReactionType.like), isTrue);
  });

  test('같은 것을 다시 누르면 취소된다', () {
    const summary = ReactionSummary(
      counts: {ReactionType.like: 3},
      mine: ReactionType.like,
    );

    final next = summary.toggled(ReactionType.like);

    expect(next.countOf(ReactionType.like), 2);
    expect(next.mine, isNull);
  });

  test('취소로 0이 되면 항목 자체가 사라진다', () {
    const summary = ReactionSummary(
      counts: {ReactionType.like: 1},
      mine: ReactionType.like,
    );

    final next = summary.toggled(ReactionType.like);

    expect(next.counts.containsKey(ReactionType.like), isFalse);
    expect(next.mine, isNull);
  });

  test('다른 것을 누르면 이전 반응이 해제되고 새 반응이 선다', () {
    const summary = ReactionSummary(
      counts: {ReactionType.like: 2, ReactionType.dislike: 1},
      mine: ReactionType.like,
    );

    final next = summary.toggled(ReactionType.dislike);

    expect(next.countOf(ReactionType.like), 1);
    expect(next.countOf(ReactionType.dislike), 2);
    expect(next.mine, ReactionType.dislike);
  });

  test('내 반응이 없으면 남의 개수를 줄이지 않는다', () {
    const summary = ReactionSummary(counts: {ReactionType.like: 5});

    final next = summary.toggled(ReactionType.dislike);

    expect(next.countOf(ReactionType.like), 5);
    expect(next.countOf(ReactionType.dislike), 1);
  });

  test('fromRaw 는 뷰가 내려준 문자열을 엔티티로 옮긴다', () {
    final summary = ReactionSummary.fromRaw(
      const {'like': 4, 'dislike': 1},
      'like',
    );

    expect(summary.countOf(ReactionType.like), 4);
    expect(summary.countOf(ReactionType.dislike), 1);
    expect(summary.mine, ReactionType.like);
  });

  test('앱이 모르는 감정 코드는 무시한다', () {
    // 감정을 DB 에 먼저 추가하고 앱을 나중에 배포해도 목록이 깨지지 않아야 한다.
    final summary = ReactionSummary.fromRaw(const {'like': 2, 'love': 9}, 'love');

    expect(summary.countOf(ReactionType.like), 2);
    expect(summary.counts.length, 1);
    expect(summary.mine, isNull);
  });
}
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

```bash
cd app && flutter test test/features/reaction
```

Expected: 컴파일 실패 (`reaction_summary.dart` 없음)

- [ ] **Step 3: domain entity 구현**

`app/lib/features/reaction/domain/entity/reaction_type.dart`:

```dart
/// 남길 수 있는 감정. `code` 는 DB 의 type CHECK 와 같은 문자열이어야 한다.
///
/// 감정을 추가할 때는 여기와 두 테이블의 CHECK 제약만 손대면 된다. 개수는
/// 컬럼이 아니라 jsonb 로 내려오므로 뷰는 고치지 않는다.
enum ReactionType {
  like('like'),
  dislike('dislike');

  const ReactionType(this.code);

  final String code;

  /// 모르는 코드는 null 이다. DB 에 감정을 먼저 추가하고 앱을 나중에 배포해도
  /// 목록이 깨지지 않도록, 호출부는 null 을 "표시하지 않음"으로 다룬다.
  static ReactionType? fromCode(String? code) {
    if (code == null) return null;
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}
```

`app/lib/features/reaction/domain/entity/reaction_target.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reaction_target.freezed.dart';

/// 감정을 남길 대상.
///
/// 이 타입이 재사용의 축이다. 대상이 늘어나면 여기에 변형을 하나 더하고,
/// data 계층의 테이블 매핑 한 줄과 마이그레이션만 는다. domain 과
/// presentation 의 다른 코드는 그대로다.
@freezed
sealed class ReactionTarget with _$ReactionTarget {
  const factory ReactionTarget.post(String id) = ReactionPostTarget;
  const factory ReactionTarget.comment(String id) = ReactionCommentTarget;
}
```

`app/lib/features/reaction/domain/entity/reaction_summary.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'reaction_type.dart';

part 'reaction_summary.freezed.dart';

/// 한 대상의 감정 집계와 내 반응.
///
/// 목록 항목 안에 산다 (`FeedPost.reactions` · `PostComment.reactions`).
/// 감정 전용 Bloc 을 두지 않는 이유는 목록 상태를 목록이 소유하기 때문이다
/// (아키텍처 규칙 ⑥).
@freezed
class ReactionSummary with _$ReactionSummary {
  const ReactionSummary({this.counts = const {}, this.mine});

  @override
  final Map<ReactionType, int> counts;

  /// 내가 남긴 감정. 대상당 하나다.
  @override
  final ReactionType? mine;

  int countOf(ReactionType type) => counts[type] ?? 0;

  bool isMine(ReactionType type) => mine == type;

  /// [tapped] 를 눌렀을 때의 다음 상태.
  ///
  /// 낙관적 업데이트의 계산이 여기 한 곳에 있다. 게시물이든 댓글이든 같은
  /// 함수를 쓴다. 같은 것을 다시 누르면 취소이고, 다른 것을 누르면 이전 반응이
  /// 해제되면서 새 반응이 선다 — 대상당 감정은 하나다.
  ReactionSummary toggled(ReactionType tapped) {
    final next = Map<ReactionType, int>.from(counts);

    final previous = mine;
    if (previous != null) {
      final decreased = (next[previous] ?? 0) - 1;
      if (decreased > 0) {
        next[previous] = decreased;
      } else {
        next.remove(previous);
      }
    }

    if (previous == tapped) {
      return ReactionSummary(counts: next);
    }

    next[tapped] = (next[tapped] ?? 0) + 1;
    return ReactionSummary(counts: next, mine: tapped);
  }

  /// 목록 뷰가 내려준 `reaction_counts` · `my_reaction` 을 엔티티로 옮긴다.
  ///
  /// JSON 파싱은 각 feature 의 DTO 가 하고, 문자열 → 감정 변환만 여기서 한다.
  /// feature 의 data 계층끼리 참조하지 않으면서도 이 규칙이 한 곳에 있다.
  static ReactionSummary fromRaw(Map<String, int> counts, String? mine) {
    final parsed = <ReactionType, int>{};
    for (final entry in counts.entries) {
      final type = ReactionType.fromCode(entry.key);
      if (type != null) parsed[type] = entry.value;
    }
    return ReactionSummary(counts: parsed, mine: ReactionType.fromCode(mine));
  }
}
```

- [ ] **Step 4: 코드 생성 후 테스트 통과 확인**

```bash
cd app && dart run build_runner build --delete-conflicting-outputs && flutter test test/features/reaction
```

Expected: PASS

- [ ] **Step 5: scenario 의 실패하는 테스트 작성**

`app/test/features/reaction/domain/usecase/scenario/toggle_reaction_scenario_test.dart`:

```dart
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/reaction/domain/entity/reaction_summary.dart';
import 'package:daylog/features/reaction/domain/entity/reaction_target.dart';
import 'package:daylog/features/reaction/domain/entity/reaction_type.dart';
import 'package:daylog/features/reaction/domain/repository/reaction_repository.dart';
import 'package:daylog/features/reaction/domain/usecase/scenario/toggle_reaction_scenario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockReactionRepository extends Mock implements ReactionRepository {}

void main() {
  late _MockReactionRepository repository;
  late ToggleReactionScenario scenario;

  const target = ReactionTarget.post('post-1');

  setUpAll(() => registerFallbackValue(const ReactionTarget.post('_')));

  setUp(() {
    repository = _MockReactionRepository();
    scenario = ToggleReactionScenario(repository);
  });

  test('새 감정은 setReaction 을 부르고 다음 상태를 돌려준다', () async {
    when(
      () => repository.setReaction(any(), any()),
    ).thenAnswer((_) async => const Ok(null));

    final result = await scenario(
      target: target,
      tapped: ReactionType.like,
      current: const ReactionSummary(),
    );

    verify(() => repository.setReaction(target, ReactionType.like)).called(1);
    verifyNever(() => repository.clearReaction(any()));
    expect((result as Ok).value.mine, ReactionType.like);
  });

  test('같은 감정을 다시 누르면 clearReaction 을 부른다', () async {
    when(
      () => repository.clearReaction(any()),
    ).thenAnswer((_) async => const Ok(null));

    final result = await scenario(
      target: target,
      tapped: ReactionType.like,
      current: const ReactionSummary(
        counts: {ReactionType.like: 1},
        mine: ReactionType.like,
      ),
    );

    verify(() => repository.clearReaction(target)).called(1);
    verifyNever(() => repository.setReaction(any(), any()));
    expect((result as Ok).value.mine, isNull);
  });

  test('전환은 삭제 없이 setReaction 한 번이다', () async {
    when(
      () => repository.setReaction(any(), any()),
    ).thenAnswer((_) async => const Ok(null));

    await scenario(
      target: target,
      tapped: ReactionType.dislike,
      current: const ReactionSummary(
        counts: {ReactionType.like: 1},
        mine: ReactionType.like,
      ),
    );

    verify(() => repository.setReaction(target, ReactionType.dislike)).called(1);
    verifyNever(() => repository.clearReaction(any()));
  });

  test('실패하면 Err 를 그대로 올린다 (화면이 이전 상태로 되돌린다)', () async {
    when(
      () => repository.setReaction(any(), any()),
    ).thenAnswer((_) async => const Err(Failure.network()));

    final result = await scenario(
      target: target,
      tapped: ReactionType.like,
      current: const ReactionSummary(),
    );

    expect(result, isA<Err<ReactionSummary>>());
  });
}
```

- [ ] **Step 6: 테스트가 실패하는지 확인**

```bash
cd app && flutter test test/features/reaction/domain/usecase
```

Expected: 컴파일 실패

- [ ] **Step 7: repository 계약 · scenario · facade 구현**

`app/lib/features/reaction/domain/repository/reaction_repository.dart`:

```dart
import '../../../../core/result/result.dart';
import '../entity/reaction_target.dart';
import '../entity/reaction_type.dart';

/// 감정표현 저장소.
///
/// 조회는 여기 없다. 개수와 내 반응은 목록 뷰가 항목과 함께 내려준다 —
/// 항목마다 다시 조회하면 그게 없애려던 N+1 이다.
abstract interface class ReactionRepository {
  /// 감정을 남기거나 다른 감정으로 바꾼다. 전환도 한 번의 왕복이다.
  Future<Result<void>> setReaction(ReactionTarget target, ReactionType type);

  /// 내 감정을 취소한다.
  Future<Result<void>> clearReaction(ReactionTarget target);
}
```

`app/lib/features/reaction/domain/usecase/scenario/toggle_reaction_scenario.dart`:

```dart
import '../../../../../core/result/result.dart';
import '../../entity/reaction_summary.dart';
import '../../entity/reaction_target.dart';
import '../../entity/reaction_type.dart';
import '../../repository/reaction_repository.dart';

/// 감정 하나를 누른 결과를 저장하고 다음 상태를 돌려준다.
///
/// 현재 상태를 인자로 받는 이유: "같은 것을 다시 누르면 취소"를 판정하려면
/// 현재 값이 필요한데, DB 에서 다시 읽으면 왕복이 하나 늘고 낙관적 업데이트와
/// 상충한다. 정책은 domain 이 갖고 상태는 호출자가 준다.
class ToggleReactionScenario {
  const ToggleReactionScenario(this._repository);

  final ReactionRepository _repository;

  Future<Result<ReactionSummary>> call({
    required ReactionTarget target,
    required ReactionType tapped,
    required ReactionSummary current,
  }) async {
    final next = current.toggled(tapped);

    final saved = next.mine == null
        ? await _repository.clearReaction(target)
        : await _repository.setReaction(target, tapped);

    return saved.when(
      ok: (_) => Ok(next),
      err: (failure) => Err(failure),
    );
  }
}
```

`app/lib/features/reaction/domain/usecase/reaction_use_case.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/result/result.dart';
import '../entity/reaction_summary.dart';
import '../entity/reaction_target.dart';
import '../entity/reaction_type.dart';
import '../repository/reaction_repository.dart';
import 'scenario/toggle_reaction_scenario.dart';

/// 감정표현 feature 의 presentation 진입점.
abstract interface class ReactionUseCase {
  Future<Result<ReactionSummary>> toggle({
    required ReactionTarget target,
    required ReactionType tapped,
    required ReactionSummary current,
  });
}

@LazySingleton(as: ReactionUseCase)
class DefaultReactionUseCase implements ReactionUseCase {
  DefaultReactionUseCase(this._repository);

  final ReactionRepository _repository;

  @override
  Future<Result<ReactionSummary>> toggle({
    required ReactionTarget target,
    required ReactionType tapped,
    required ReactionSummary current,
  }) => ToggleReactionScenario(
    _repository,
  )(target: target, tapped: tapped, current: current);
}
```

- [ ] **Step 8: data 계층 구현**

`app/lib/features/reaction/data/datasource/reaction_data_source.dart`:

```dart
import '../../domain/entity/reaction_target.dart';
import '../../domain/entity/reaction_type.dart';

abstract interface class ReactionDataSource {
  Future<void> setReaction(ReactionTarget target, ReactionType type);

  Future<void> clearReaction(ReactionTarget target);
}
```

`app/lib/features/reaction/data/datasource/supabase_reaction_data_source.dart`:

```dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entity/reaction_target.dart';
import '../../domain/entity/reaction_type.dart';
import 'reaction_data_source.dart';

@LazySingleton(as: ReactionDataSource)
class SupabaseReactionDataSource implements ReactionDataSource {
  SupabaseReactionDataSource(this._client);

  final SupabaseClient _client;

  /// 대상 → 테이블·컬럼 매핑이 있는 **유일한 곳**.
  ///
  /// 반응 대상이 늘어나면 여기 한 줄과 ReactionTarget 의 변형, 그리고
  /// 마이그레이션만 는다. domain 과 presentation 은 그대로다.
  static ({String table, String column, String id}) _mapping(
    ReactionTarget target,
  ) => switch (target) {
    ReactionPostTarget(:final id) => (
      table: 'post_reactions',
      column: 'post_id',
      id: id,
    ),
    ReactionCommentTarget(:final id) => (
      table: 'comment_reactions',
      column: 'comment_id',
      id: id,
    ),
  };

  @override
  Future<void> setReaction(ReactionTarget target, ReactionType type) async {
    if (_client.auth.currentUser == null) {
      throw const Failure.auth(message: '로그인이 필요합니다');
    }

    final mapping = _mapping(target);

    // 좋아요 ↔ 싫어요 전환은 upsert 한 번이다. 삭제 후 삽입이면 왕복이 둘이고
    // 중간 상태가 화면에 보인다. user_id 는 페이로드에 넣지 않는다 —
    // DB 의 default auth.uid() 가 채우므로 위조 경로가 없다. 충돌 대상에는
    // 이름으로만 지정한다.
    await _client
        .from(mapping.table)
        .upsert({
          mapping.column: mapping.id,
          'type': type.code,
        }, onConflict: 'user_id,${mapping.column}');
  }

  @override
  Future<void> clearReaction(ReactionTarget target) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const Failure.auth(message: '로그인이 필요합니다');
    }

    final mapping = _mapping(target);

    // 취소는 행 삭제다. 반응에는 자식이 달리지 않으므로 소프트 삭제의 이유가
    // 없다. user_id 조건은 PK 를 좁히기 위한 것이고, 권한 경계는 삭제 정책이다.
    await _client
        .from(mapping.table)
        .delete()
        .eq(mapping.column, mapping.id)
        .eq('user_id', userId);
  }
}
```

`app/lib/features/reaction/data/repository/reaction_repository_error_handler.dart` — `app/lib/features/feed/data/repository/feed_repository_error_handler.dart` 와 같은 mixin 이다. 이름만 `ReactionRepositoryErrorHandler` 로 바꾸고 import 경로를 이 feature 기준으로 맞춘다.

```dart
import '../../../../core/data/mapper/supabase_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';

/// reaction data 저장소의 예외를 Result 로 변환하는 공통 처리.
mixin ReactionRepositoryErrorHandler {
  Future<Result<T>> guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Failure catch (failure) {
      return Err(failure);
    } catch (error) {
      return Err(SupabaseErrorMapper.map(error));
    }
  }
}
```

`app/lib/features/reaction/data/repository/reaction_repository_impl.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/result/result.dart';
import '../../domain/entity/reaction_target.dart';
import '../../domain/entity/reaction_type.dart';
import '../../domain/repository/reaction_repository.dart';
import '../datasource/reaction_data_source.dart';
import 'reaction_repository_error_handler.dart';

@LazySingleton(as: ReactionRepository)
class ReactionRepositoryImpl
    with ReactionRepositoryErrorHandler
    implements ReactionRepository {
  ReactionRepositoryImpl(this._dataSource);

  final ReactionDataSource _dataSource;

  @override
  Future<Result<void>> setReaction(
    ReactionTarget target,
    ReactionType type,
  ) => guard(() => _dataSource.setReaction(target, type));

  @override
  Future<Result<void>> clearReaction(ReactionTarget target) =>
      guard(() => _dataSource.clearReaction(target));
}
```

- [ ] **Step 9: 코드 생성 · 정적 분석 · 테스트**

```bash
cd app && dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test
```

Expected: analyze 무경고, 전체 테스트 PASS. `injection.config.dart` 에 `ReactionRepository` · `ReactionDataSource` · `ReactionUseCase` 등록이 생겼는지 확인한다 (직접 편집하지 않는다).

- [ ] **Step 10: 테스트 문서 작성**

`docs/testing/features/reaction.md` 를 만든다. 다른 feature 문서와 같은 **대상 · 시나리오 · 기대 결과** 표 형식을 쓰고, 헤더 링크 줄은 `docs/testing/features/feed.md` 를 본뜬다. 위에서 만든 두 테스트 파일의 케이스를 표로 옮기고, 마지막에 "로컬 Supabase 로만 확인되는 것" 문단을 넣어 [reaction 계획서](../../features/reaction/plan.md)의 검증 항목을 가리킨다.

`docs/testing/README.md` 의 "Feature별 범위" 목록에서 `post` 다음 줄에 항목을 하나 더한다 — 표시 문구는 `reaction`, 대상은 `features/reaction.md` 인 상대 Markdown 링크다.

- [ ] **Step 11: 검사 후 커밋**

```bash
cd app && flutter test && cd .. && git add app/lib/features/reaction app/test/features/reaction app/lib/core/di/injection.config.dart docs/testing/features/reaction.md docs/testing/README.md && git commit -m "feat(reaction): 게시물·댓글 공용 감정표현 usecase 를 만든다"
```

---

### Task 4: `features/comment` — domain · data · DI

**Files:**
- Create: `app/lib/features/comment/domain/entity/post_comment.dart`
- Create: `app/lib/features/comment/domain/comment_policy.dart`
- Create: `app/lib/features/comment/domain/repository/comment_repository.dart`
- Create: `app/lib/features/comment/domain/usecase/comment_use_case.dart`
- Create: `app/lib/features/comment/domain/usecase/scenario/get_comments_scenario.dart`
- Create: `app/lib/features/comment/domain/usecase/scenario/get_replies_scenario.dart`
- Create: `app/lib/features/comment/domain/usecase/scenario/add_comment_scenario.dart`
- Create: `app/lib/features/comment/domain/usecase/scenario/delete_comment_scenario.dart`
- Create: `app/lib/features/comment/data/cursor/comment_cursor.dart`
- Create: `app/lib/features/comment/data/dto/post_comment_dto.dart`
- Create: `app/lib/features/comment/data/mapper/post_comment_mapper.dart`
- Create: `app/lib/features/comment/data/datasource/comment_data_source.dart`
- Create: `app/lib/features/comment/data/datasource/supabase_comment_data_source.dart`
- Create: `app/lib/features/comment/data/repository/comment_repository_error_handler.dart`
- Create: `app/lib/features/comment/data/repository/comment_repository_impl.dart`
- Test: `app/test/features/comment/data/cursor/comment_cursor_test.dart`
- Test: `app/test/features/comment/data/mapper/post_comment_mapper_test.dart`
- Test: `app/test/features/comment/data/repository/comment_repository_impl_test.dart`
- Test: `app/test/features/comment/domain/usecase/scenario/comment_scenarios_test.dart`
- Create: `docs/testing/features/comment.md`
- Modify: `docs/testing/README.md`

**Interfaces:**
- Consumes:
  - Task 1 의 뷰 `post_comments_visible` (컬럼: `id, post_id, parent_id, author_id, content, created_at, deleted_at, author_nickname, author_avatar_url, reply_count`) · 테이블 `post_comments` · 함수 `soft_delete_post_comment(comment_id uuid)`
  - Task 2 가 뷰에 더한 `reaction_counts` · `my_reaction`
  - Task 3 의 `ReactionSummary` (`ReactionSummary.fromRaw`)
  - 기존 `PostAuthor` (`app/lib/features/post/domain/entity/post_author.dart`)
  - 기존 `CursorPage<T>` · `Result<T>` · `Failure`
- Produces (Task 5 는 쓰지 않는다. 후속 화면 작업이 쓴다):
  - `class PostComment` — `id, postId, parentId, author, content, createdAt, deletedAt, replyCount, reactions`, `bool get isDeleted`, `bool get isReply`
  - `abstract interface class CommentUseCase` — `getComments` · `getReplies` · `addComment` · `deleteComment`

- [ ] **Step 1: 커서의 실패하는 테스트 작성**

`app/test/features/comment/data/cursor/comment_cursor_test.dart`:

```dart
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/features/comment/data/cursor/comment_cursor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('인코딩한 커서를 그대로 되돌린다', () {
    final cursor = CommentCursor(
      createdAt: DateTime.utc(2026, 8, 23, 9, 30),
      id: 'comment-1',
    );

    final decoded = CommentCursor.decode(cursor.encode());

    expect(decoded, cursor);
  });

  test('null 과 빈 문자열은 첫 페이지를 뜻한다', () {
    expect(CommentCursor.decode(null), isNull);
    expect(CommentCursor.decode(''), isNull);
  });

  test('형식이 아니면 validation 실패를 던진다', () {
    expect(
      () => CommentCursor.decode('not-a-cursor'),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
```

- [ ] **Step 2: 실패 확인**

```bash
cd app && flutter test test/features/comment
```

Expected: 컴파일 실패

- [ ] **Step 3: 커서 구현**

`app/lib/features/comment/data/cursor/comment_cursor.dart` 는 `app/lib/features/feed/data/cursor/feed_cursor.dart` 와 **같은 구조**다. 클래스 이름을 `CommentCursor` 로 바꾸고, 문서 주석을 아래로 교체한다. 나머지(`_separator` · `encode` · `decode` · `==` · `hashCode` · `toString`)는 `FeedCursor` 와 동일하게 쓴다. 실패 메시지는 `'잘못된 댓글 커서입니다'` 로 한다.

```dart
/// 댓글 커서. `(created_at, id)` 복합 커서를 불투명 문자열로 감싼다.
///
/// 피드와 달리 **오래된 순**으로 읽는다. 대댓글이 있는 목록에서 최신순은 대화
/// 흐름이 깨지기 때문이다. 방향이 달라도 커서의 성질은 같다 — `created_at` 이
/// 같은 항목이 여러 개일 수 있으므로 `id` tie-break 를 반드시 넣는다.
///
/// 이 형식을 아는 곳은 data 계층뿐이다. domain 과 presentation 은 문자열을
/// 해석하지 않고 그대로 되돌려준다.
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
cd app && flutter test test/features/comment/data/cursor
```

Expected: PASS

- [ ] **Step 5: entity · policy 구현**

`app/lib/features/comment/domain/comment_policy.dart`:

```dart
/// 댓글 domain 정책 상수.
///
/// DB 의 post_comments_content_length CHECK 와 같은 값을 쓴다. 앱 검증은 UX 이고
/// 최종 판정은 DB 가 하지만, 두 값이 어긋나면 사용자에게 날것의 DB 오류가 간다.
abstract final class CommentPolicy {
  /// 본문 최대 길이. docs/schema.md 의 post_comments_content_length 와 같아야 한다.
  static const maxContentLength = 300;

  /// 한 번에 가져올 수 있는 최대 개수.
  static const maxPageSize = 50;
}
```

`app/lib/features/comment/domain/entity/post_comment.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../post/domain/entity/post_author.dart';
import '../../../reaction/domain/entity/reaction_summary.dart';

part 'post_comment.freezed.dart';

/// 댓글 또는 답글 하나.
///
/// depth 는 2단 고정이다 — [parentId] 가 있으면 답글이고, 답글에는 답글을 달 수
/// 없다. 그 판정은 앱이 아니라 DB 트리거가 한다.
///
/// [content] 가 null 이면 **삭제된 댓글**이다. 답글이 남아 있는 부모는 목록에서
/// 사라지지 않고 본문만 가려진다 — 완전히 숨기면 답글이 고아가 되기 때문이다.
/// 답글은 자식을 가질 수 없으므로 삭제되면 그냥 목록에서 빠진다.
///
/// 작성자 표시는 post feature 의 `PostAuthor` 를 그대로 쓴다. 같은 사람을 두
/// 벌로 표현하지 않기 위해서다 (아키텍처 규칙 ⑥ — feature 간 참조는 domain 까지).
@freezed
class PostComment with _$PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.author,
    required this.createdAt,
    this.parentId,
    this.content,
    this.deletedAt,
    this.replyCount = 0,
    this.reactions = const ReactionSummary(),
  });

  @override
  final String id;
  @override
  final String postId;
  @override
  final PostAuthor author;
  @override
  final DateTime createdAt;

  /// null 이면 부모 댓글, 값이 있으면 답글이다.
  @override
  final String? parentId;

  /// 삭제된 댓글은 null 이다. 뷰가 본문을 지워서 내려주므로 앱이 판단하지 않는다.
  @override
  final String? content;
  @override
  final DateTime? deletedAt;

  /// 살아 있는 답글 수. 목록 조회가 함께 내려준다 — 답글은 눌렀을 때 읽는다.
  @override
  final int replyCount;
  @override
  final ReactionSummary reactions;

  bool get isDeleted => deletedAt != null;

  bool get isReply => parentId != null;
}
```

- [ ] **Step 6: DTO · mapper 의 실패하는 테스트 작성**

`app/test/features/comment/data/mapper/post_comment_mapper_test.dart`:

```dart
import 'package:daylog/features/comment/data/dto/post_comment_dto.dart';
import 'package:daylog/features/comment/data/mapper/post_comment_mapper.dart';
import 'package:daylog/features/reaction/domain/entity/reaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('뷰 한 행을 댓글 엔티티로 옮긴다', () {
    final dto = PostCommentDto(
      id: 'comment-1',
      postId: 'post-1',
      authorId: 'author-1',
      authorNickname: '카르마',
      content: '첫 댓글',
      createdAt: DateTime.utc(2026, 8, 23, 9),
      replyCount: 2,
      reactionCounts: const {'like': 3},
      myReaction: 'like',
    );

    final comment = dto.toEntity();

    expect(comment.id, 'comment-1');
    expect(comment.author.nickname, '카르마');
    expect(comment.content, '첫 댓글');
    expect(comment.isDeleted, isFalse);
    expect(comment.isReply, isFalse);
    expect(comment.replyCount, 2);
    expect(comment.reactions.countOf(ReactionType.like), 3);
    expect(comment.reactions.mine, ReactionType.like);
  });

  test('삭제된 댓글은 본문이 없고 isDeleted 가 참이다', () {
    final dto = PostCommentDto(
      id: 'comment-1',
      postId: 'post-1',
      authorId: 'author-1',
      authorNickname: '카르마',
      createdAt: DateTime.utc(2026, 8, 23, 9),
      deletedAt: DateTime.utc(2026, 8, 23, 10),
      replyCount: 1,
    );

    final comment = dto.toEntity();

    expect(comment.content, isNull);
    expect(comment.isDeleted, isTrue);
  });

  test('답글은 parentId 를 갖는다', () {
    final dto = PostCommentDto(
      id: 'reply-1',
      postId: 'post-1',
      parentId: 'comment-1',
      authorId: 'author-1',
      authorNickname: '이웃',
      content: '답글',
      createdAt: DateTime.utc(2026, 8, 23, 9, 1),
    );

    expect(dto.toEntity().isReply, isTrue);
  });

  test('마지막 항목으로 다음 페이지 커서를 만든다', () {
    final dto = PostCommentDto(
      id: 'comment-9',
      postId: 'post-1',
      authorId: 'author-1',
      authorNickname: '카르마',
      content: '댓글',
      createdAt: DateTime.utc(2026, 8, 23, 9, 5),
    );

    final cursor = dto.toCursor();

    expect(cursor.id, 'comment-9');
    expect(cursor.createdAt, DateTime.utc(2026, 8, 23, 9, 5));
  });
}
```

- [ ] **Step 7: 실패 확인**

```bash
cd app && flutter test test/features/comment/data/mapper
```

Expected: 컴파일 실패

- [ ] **Step 8: DTO · mapper 구현**

`app/lib/features/comment/data/dto/post_comment_dto.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_comment_dto.freezed.dart';
part 'post_comment_dto.g.dart';

/// `post_comments_visible` 뷰 한 행의 전송 형식.
///
/// 이 뷰는 security_invoker = off 라서 조회 권한 경계가 뷰의 where 에 있다.
/// 삭제된 댓글의 [content] 는 뷰가 null 로 지워서 내려준다.
@freezed
@JsonSerializable()
class PostCommentDto with _$PostCommentDto {
  const PostCommentDto({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorNickname,
    required this.createdAt,
    this.parentId,
    this.content,
    this.deletedAt,
    this.authorAvatarUrl,
    this.replyCount = 0,
    this.reactionCounts = const {},
    this.myReaction,
  });

  @override
  final String id;
  @override
  @JsonKey(name: 'post_id')
  final String postId;
  @override
  @JsonKey(name: 'parent_id')
  final String? parentId;
  @override
  @JsonKey(name: 'author_id')
  final String authorId;

  /// 삭제된 댓글은 뷰가 null 로 내려준다.
  @override
  final String? content;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;
  @override
  @JsonKey(name: 'author_nickname')
  final String authorNickname;
  @override
  @JsonKey(name: 'author_avatar_url')
  final String? authorAvatarUrl;

  /// 살아 있는 답글 수.
  @override
  @JsonKey(name: 'reply_count', defaultValue: 0)
  final int replyCount;

  /// 감정별 개수. 개수를 컬럼이 아니라 map 으로 받으므로 감정이 늘어도
  /// DTO 를 고치지 않는다.
  @override
  @JsonKey(name: 'reaction_counts', defaultValue: <String, int>{})
  final Map<String, int> reactionCounts;
  @override
  @JsonKey(name: 'my_reaction')
  final String? myReaction;

  factory PostCommentDto.fromJson(Map<String, dynamic> json) =>
      _$PostCommentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PostCommentDtoToJson(this);
}
```

`app/lib/features/comment/data/mapper/post_comment_mapper.dart`:

```dart
import '../../../post/domain/entity/post_author.dart';
import '../../../reaction/domain/entity/reaction_summary.dart';
import '../../domain/entity/post_comment.dart';
import '../cursor/comment_cursor.dart';
import '../dto/post_comment_dto.dart';

/// data/domain 경계의 댓글 변환.
extension PostCommentDtoMapper on PostCommentDto {
  PostAuthor toAuthor() => PostAuthor(
    id: authorId,
    nickname: authorNickname,
    avatarUrl: authorAvatarUrl,
  );

  PostComment toEntity() => PostComment(
    id: id,
    postId: postId,
    parentId: parentId,
    author: toAuthor(),
    content: content,
    createdAt: createdAt,
    deletedAt: deletedAt,
    replyCount: replyCount,
    reactions: ReactionSummary.fromRaw(reactionCounts, myReaction),
  );

  /// 이 행을 마지막 항목으로 하는 다음 페이지 커서.
  CommentCursor toCursor() => CommentCursor(createdAt: createdAt, id: id);
}
```

- [ ] **Step 9: 코드 생성 후 테스트 통과 확인**

```bash
cd app && dart run build_runner build --delete-conflicting-outputs && flutter test test/features/comment
```

Expected: PASS

- [ ] **Step 10: repository 의 실패하는 테스트 작성**

`app/test/features/comment/data/repository/comment_repository_impl_test.dart`:

```dart
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/comment/data/cursor/comment_cursor.dart';
import 'package:daylog/features/comment/data/datasource/comment_data_source.dart';
import 'package:daylog/features/comment/data/dto/post_comment_dto.dart';
import 'package:daylog/features/comment/data/repository/comment_repository_impl.dart';
import 'package:daylog/features/post/domain/entity/post_author.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCommentDataSource extends Mock implements CommentDataSource {}

PostCommentDto _dto(int index) => PostCommentDto(
  id: 'comment-$index',
  postId: 'post-1',
  authorId: 'author-1',
  authorNickname: '카르마',
  content: '댓글 $index',
  createdAt: DateTime.utc(2026, 8, 23, 9).add(Duration(minutes: index)),
);

void main() {
  late _MockCommentDataSource dataSource;
  late CommentRepositoryImpl repository;

  const author = PostAuthor(id: 'author-1', nickname: '카르마');

  setUp(() {
    dataSource = _MockCommentDataSource();
    repository = CommentRepositoryImpl(dataSource);
  });

  test('다음 페이지 유무를 알려고 한 개를 더 요청한다', () async {
    when(
      () => dataSource.getComments(
        postId: any(named: 'postId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => []);

    await repository.getComments(postId: 'post-1', limit: 20);

    verify(
      () => dataSource.getComments(postId: 'post-1', limit: 21, cursor: null),
    ).called(1);
  });

  test('요청한 개수보다 많이 오면 잘라내고 다음 커서를 만든다', () async {
    when(
      () => dataSource.getComments(
        postId: any(named: 'postId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => [_dto(0), _dto(1), _dto(2)]);

    final page = ((await repository.getComments(postId: 'post-1', limit: 2))
            as Ok)
        .value;

    expect(page.items.length, 2);
    expect(page.hasMore, isTrue);
    // 커서는 마지막으로 **돌려준** 항목 기준이어야 한다. 잘라낸 항목 기준이면
    // 다음 페이지에서 한 건이 건너뛰어진다.
    expect(CommentCursor.decode(page.nextCursor)!.id, 'comment-1');
  });

  test('답글도 같은 규칙으로 페이지를 나눈다', () async {
    when(
      () => dataSource.getReplies(
        parentId: any(named: 'parentId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => [_dto(0)]);

    final page =
        ((await repository.getReplies(parentId: 'comment-1', limit: 20)) as Ok)
            .value;

    expect(page.items.single.id, 'comment-0');
    expect(page.hasMore, isFalse);
  });

  test('작성은 서버가 준 id·시각에 화면이 아는 작성자를 붙여 돌려준다', () async {
    when(
      () => dataSource.addComment(
        postId: any(named: 'postId'),
        parentId: any(named: 'parentId'),
        content: any(named: 'content'),
      ),
    ).thenAnswer(
      (_) async => (id: 'comment-9', createdAt: DateTime.utc(2026, 8, 23, 10)),
    );

    final comment =
        ((await repository.addComment(
                  postId: 'post-1',
                  content: '새 댓글',
                  author: author,
                ))
                as Ok)
            .value;

    expect(comment.id, 'comment-9');
    expect(comment.content, '새 댓글');
    expect(comment.author, author);
    expect(comment.replyCount, 0);
    expect(comment.isDeleted, isFalse);
  });

  test('로그인하지 않은 상태의 작성은 인증 실패다', () async {
    when(
      () => dataSource.addComment(
        postId: any(named: 'postId'),
        parentId: any(named: 'parentId'),
        content: any(named: 'content'),
      ),
    ).thenAnswer((_) async => null);

    final result = await repository.addComment(
      postId: 'post-1',
      content: '새 댓글',
      author: author,
    );

    expect(result, isA<Err<dynamic>>());
  });
}
```

- [ ] **Step 11: 실패 확인**

```bash
cd app && flutter test test/features/comment/data/repository
```

Expected: 컴파일 실패

- [ ] **Step 12: datasource · repository 구현**

`app/lib/features/comment/data/datasource/comment_data_source.dart`:

```dart
import '../cursor/comment_cursor.dart';
import '../dto/post_comment_dto.dart';

/// 작성 결과. 본문과 작성자는 호출부가 이미 알고 있으므로 서버가 정하는 값만
/// 돌려받는다. 왕복을 한 번으로 끝내기 위한 모양이다.
typedef CreatedComment = ({String id, DateTime createdAt});

abstract interface class CommentDataSource {
  /// 부모 댓글을 오래된 순으로 [limit] 개까지. [cursor] 가 null 이면 첫 페이지다.
  Future<List<PostCommentDto>> getComments({
    required String postId,
    required int limit,
    CommentCursor? cursor,
  });

  /// 한 부모의 답글을 오래된 순으로 [limit] 개까지.
  Future<List<PostCommentDto>> getReplies({
    required String parentId,
    required int limit,
    CommentCursor? cursor,
  });

  /// 로그인하지 않았으면 null.
  Future<CreatedComment?> addComment({
    required String postId,
    String? parentId,
    required String content,
  });

  /// 로그인하지 않았으면 null, 남의 댓글이면 false.
  Future<bool?> deleteComment(String commentId);
}
```

`app/lib/features/comment/data/datasource/supabase_comment_data_source.dart`:

```dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../cursor/comment_cursor.dart';
import '../dto/post_comment_dto.dart';
import 'comment_data_source.dart';

@LazySingleton(as: CommentDataSource)
class SupabaseCommentDataSource implements CommentDataSource {
  SupabaseCommentDataSource(this._client);

  final SupabaseClient _client;

  /// 본문에 닿는 유일한 경로. post_comments 테이블에는 content SELECT 권한이
  /// 없다 — docs/schema.md 의 post_comments_visible 항목 참고.
  static const _source = 'post_comments_visible';

  static const _columns =
      'id, post_id, parent_id, author_id, content, created_at, deleted_at, '
      'author_nickname, author_avatar_url, reply_count, '
      'reaction_counts, my_reaction';

  @override
  Future<List<PostCommentDto>> getComments({
    required String postId,
    required int limit,
    CommentCursor? cursor,
  }) async {
    var query = _client
        .from(_source)
        .select(_columns)
        .eq('post_id', postId)
        .isFilter('parent_id', null);

    query = _applyCursor(query, cursor);
    return _fetch(query, limit);
  }

  @override
  Future<List<PostCommentDto>> getReplies({
    required String parentId,
    required int limit,
    CommentCursor? cursor,
  }) async {
    var query = _client
        .from(_source)
        .select(_columns)
        .eq('parent_id', parentId);

    query = _applyCursor(query, cursor);
    return _fetch(query, limit);
  }

  /// 오래된 순이므로 커서 비교가 `gt` 다. 피드(`lt`)와 방향만 다르다.
  PostgrestFilterBuilder<List<Map<String, dynamic>>> _applyCursor(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query,
    CommentCursor? cursor,
  ) {
    if (cursor == null) return query;

    final createdAt = cursor.createdAt.toUtc().toIso8601String();
    // (created_at, id) 사전식 비교. 같은 시각에 두 댓글이 들어와도 순서가
    // 정해지고 경계에서 중복·누락이 생기지 않는다.
    return query.or(
      'created_at.gt.$createdAt,'
      'and(created_at.eq.$createdAt,id.gt.${cursor.id})',
    );
  }

  Future<List<PostCommentDto>> _fetch(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query,
    int limit,
  ) async {
    final rows = await query
        .order('created_at', ascending: true)
        .order('id', ascending: true)
        .limit(limit);

    return rows.map(PostCommentDto.fromJson).toList();
  }

  @override
  Future<CreatedComment?> addComment({
    required String postId,
    String? parentId,
    required String content,
  }) async {
    if (_client.auth.currentUser == null) return null;

    // author_id 는 보내지 않는다. DB 의 default auth.uid() 가 채운다.
    // returning 으로 서버가 정하는 값만 받고, 본문·작성자는 호출부가 채운다.
    // content 는 SELECT GRANT 에서 빠져 있으므로 여기에 넣을 수 없다.
    final row = await _client
        .from('post_comments')
        .insert({
          'post_id': postId,
          if (parentId != null) 'parent_id': parentId,
          'content': content,
        })
        .select('id, created_at')
        .single();

    return (
      id: row['id'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  @override
  Future<bool?> deleteComment(String commentId) async {
    if (_client.auth.currentUser == null) return null;

    // deleted_at 을 직접 UPDATE 할 수는 없다. UPDATE 의 SELECT 정책이 새 행에도
    // 적용되기 때문이다. 삭제 경로는 security definer 함수 하나뿐이다.
    final deleted = await _client.rpc(
      'soft_delete_post_comment',
      params: {'comment_id': commentId},
    );
    return deleted == true;
  }
}
```

> `PostgrestFilterBuilder` 의 정확한 제네릭 인자가 설치된 `supabase_flutter` 버전과 다르면, `_applyCursor` / `_fetch` 를 인라인으로 펴서 `getComments` · `getReplies` 각각에 같은 내용을 쓴다. **동작이 우선이고 헬퍼 추출은 그다음이다.**

`app/lib/features/comment/data/repository/comment_repository_error_handler.dart` — Task 3 의 mixin 과 같은 내용이고 이름만 `CommentRepositoryErrorHandler` 다.

`app/lib/features/comment/data/repository/comment_repository_impl.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/pagination/cursor_page.dart';
import '../../../../core/result/result.dart';
import '../../../post/domain/entity/post_author.dart';
import '../../domain/entity/post_comment.dart';
import '../../domain/repository/comment_repository.dart';
import '../cursor/comment_cursor.dart';
import '../datasource/comment_data_source.dart';
import '../dto/post_comment_dto.dart';
import '../mapper/post_comment_mapper.dart';
import 'comment_repository_error_handler.dart';

@LazySingleton(as: CommentRepository)
class CommentRepositoryImpl
    with CommentRepositoryErrorHandler
    implements CommentRepository {
  CommentRepositoryImpl(this._dataSource);

  final CommentDataSource _dataSource;

  @override
  Future<Result<CursorPage<PostComment>>> getComments({
    required String postId,
    required int limit,
    String? cursor,
  }) => guard(() async {
    final rows = await _dataSource.getComments(
      postId: postId,
      // 한 개를 더 요청해서 다음 페이지 존재 여부를 알아낸다.
      limit: limit + 1,
      cursor: CommentCursor.decode(cursor),
    );
    return _toPage(rows, limit);
  });

  @override
  Future<Result<CursorPage<PostComment>>> getReplies({
    required String parentId,
    required int limit,
    String? cursor,
  }) => guard(() async {
    final rows = await _dataSource.getReplies(
      parentId: parentId,
      limit: limit + 1,
      cursor: CommentCursor.decode(cursor),
    );
    return _toPage(rows, limit);
  });

  CursorPage<PostComment> _toPage(List<PostCommentDto> rows, int limit) {
    final hasMore = rows.length > limit;
    final page = hasMore ? rows.take(limit).toList() : rows;

    return CursorPage<PostComment>(
      items: page.map((dto) => dto.toEntity()).toList(),
      // 다음 커서는 잘라낸 뒤 실제로 돌려주는 마지막 항목 기준이다.
      nextCursor: hasMore ? page.last.toCursor().encode() : null,
    );
  }

  @override
  Future<Result<PostComment>> addComment({
    required String postId,
    String? parentId,
    required String content,
    required PostAuthor author,
  }) => guard(() async {
    final created = await _dataSource.addComment(
      postId: postId,
      parentId: parentId,
      content: content,
    );
    if (created == null) {
      throw const Failure.auth(message: '로그인이 필요합니다');
    }

    // 서버가 정하는 값은 id 와 시각뿐이다. 본문과 작성자는 호출부가 이미 알고
    // 있으므로 방금 쓴 댓글을 다시 조회하지 않는다. 피드의 prependPost 와 같다.
    return PostComment(
      id: created.id,
      postId: postId,
      parentId: parentId,
      author: author,
      content: content,
      createdAt: created.createdAt,
    );
  });

  @override
  Future<Result<bool>> deleteComment(String commentId) => guard(() async {
    final deleted = await _dataSource.deleteComment(commentId);
    if (deleted == null) {
      throw const Failure.auth(message: '로그인이 필요합니다');
    }
    return deleted;
  });
}
```

`app/lib/features/comment/domain/repository/comment_repository.dart`:

```dart
import '../../../../core/pagination/cursor_page.dart';
import '../../../../core/result/result.dart';
import '../../../post/domain/entity/post_author.dart';
import '../entity/post_comment.dart';

/// 댓글 저장소.
///
/// 부모 댓글과 답글을 **별도로** 읽는다. 답글은 부모를 눌렀을 때 가져오므로
/// 첫 조회 페이로드가 답글 수에 좌우되지 않는다. 두 조회는 같은 뷰를 읽고
/// 좁히는 조건만 다르다.
abstract interface class CommentRepository {
  Future<Result<CursorPage<PostComment>>> getComments({
    required String postId,
    required int limit,
    String? cursor,
  });

  Future<Result<CursorPage<PostComment>>> getReplies({
    required String parentId,
    required int limit,
    String? cursor,
  });

  /// [author] 는 세션의 본인이다. 방금 쓴 댓글을 다시 조회하지 않기 위해
  /// 호출부가 넘긴다 (피드의 `prependPost` 와 같은 방식).
  Future<Result<PostComment>> addComment({
    required String postId,
    String? parentId,
    required String content,
    required PostAuthor author,
  });

  /// 지워졌으면 true, 없거나 남의 댓글이면 false.
  Future<Result<bool>> deleteComment(String commentId);
}
```

- [ ] **Step 13: 코드 생성 후 테스트 통과 확인**

```bash
cd app && dart run build_runner build --delete-conflicting-outputs && flutter test test/features/comment
```

Expected: PASS

- [ ] **Step 14: scenario 의 실패하는 테스트 작성**

`app/test/features/comment/domain/usecase/scenario/comment_scenarios_test.dart`:

```dart
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/pagination/cursor_page.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/comment/domain/entity/post_comment.dart';
import 'package:daylog/features/comment/domain/repository/comment_repository.dart';
import 'package:daylog/features/comment/domain/usecase/scenario/add_comment_scenario.dart';
import 'package:daylog/features/comment/domain/usecase/scenario/delete_comment_scenario.dart';
import 'package:daylog/features/comment/domain/usecase/scenario/get_comments_scenario.dart';
import 'package:daylog/features/comment/domain/usecase/scenario/get_replies_scenario.dart';
import 'package:daylog/features/post/domain/entity/post_author.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCommentRepository extends Mock implements CommentRepository {}

void main() {
  late _MockCommentRepository repository;

  const author = PostAuthor(id: 'author-1', nickname: '카르마');

  PostComment comment() => PostComment(
    id: 'comment-1',
    postId: 'post-1',
    author: author,
    content: '댓글',
    createdAt: DateTime.utc(2026, 8, 23, 9),
  );

  setUp(() => repository = _MockCommentRepository());

  group('GetCommentsScenario', () {
    test('허용 범위를 넘는 limit 은 요청 자체를 막는다', () async {
      final result = await GetCommentsScenario(repository)(
        postId: 'post-1',
        limit: 51,
      );

      expect(result, isA<Err<CursorPage<PostComment>>>());
      verifyNever(
        () => repository.getComments(
          postId: any(named: 'postId'),
          limit: any(named: 'limit'),
        ),
      );
    });

    test('정상 범위는 저장소로 넘긴다', () async {
      when(
        () => repository.getComments(
          postId: any(named: 'postId'),
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Ok(CursorPage<PostComment>(items: [comment()])));

      final result = await GetCommentsScenario(repository)(
        postId: 'post-1',
        limit: 20,
      );

      expect((result as Ok).value.items.single.id, 'comment-1');
    });
  });

  group('GetRepliesScenario', () {
    test('부모 id 로 답글을 읽는다', () async {
      when(
        () => repository.getReplies(
          parentId: any(named: 'parentId'),
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Ok(CursorPage<PostComment>(items: [comment()])));

      await GetRepliesScenario(repository)(parentId: 'comment-1', limit: 20);

      verify(
        () => repository.getReplies(
          parentId: 'comment-1',
          limit: 20,
          cursor: null,
        ),
      ).called(1);
    });
  });

  group('AddCommentScenario', () {
    test('앞뒤 공백을 다듬어 저장한다', () async {
      when(
        () => repository.addComment(
          postId: any(named: 'postId'),
          parentId: any(named: 'parentId'),
          content: any(named: 'content'),
          author: any(named: 'author'),
        ),
      ).thenAnswer((_) async => Ok(comment()));

      await AddCommentScenario(repository)(
        postId: 'post-1',
        content: '  댓글  ',
        author: author,
      );

      verify(
        () => repository.addComment(
          postId: 'post-1',
          parentId: null,
          content: '댓글',
          author: author,
        ),
      ).called(1);
    });

    test('공백뿐인 본문은 저장하지 않는다', () async {
      final result = await AddCommentScenario(repository)(
        postId: 'post-1',
        content: '   ',
        author: author,
      );

      expect(result, isA<Err<PostComment>>());
      verifyNever(
        () => repository.addComment(
          postId: any(named: 'postId'),
          content: any(named: 'content'),
          author: any(named: 'author'),
        ),
      );
    });

    test('300자를 넘으면 저장하지 않는다', () async {
      final result = await AddCommentScenario(repository)(
        postId: 'post-1',
        content: 'ㄱ' * 301,
        author: author,
      );

      expect(result, isA<Err<PostComment>>());
      verifyNever(
        () => repository.addComment(
          postId: any(named: 'postId'),
          content: any(named: 'content'),
          author: any(named: 'author'),
        ),
      );
    });
  });

  group('DeleteCommentScenario', () {
    test('빈 id 는 요청 자체를 막는다', () async {
      final result = await DeleteCommentScenario(repository)('  ');

      expect(result, isA<Err<bool>>());
      verifyNever(() => repository.deleteComment(any()));
    });

    test('저장소 결과를 그대로 돌려준다', () async {
      when(
        () => repository.deleteComment(any()),
      ).thenAnswer((_) async => const Ok(false));

      final result = await DeleteCommentScenario(repository)('comment-1');

      expect((result as Ok).value, isFalse);
    });
  });
}
```

- [ ] **Step 15: 실패 확인**

```bash
cd app && flutter test test/features/comment/domain
```

Expected: 컴파일 실패

- [ ] **Step 16: scenario 4개와 facade 구현**

`get_comments_scenario.dart`:

```dart
import '../../../../../core/error/failure.dart';
import '../../../../../core/pagination/cursor_page.dart';
import '../../../../../core/result/result.dart';
import '../../comment_policy.dart';
import '../../entity/post_comment.dart';
import '../../repository/comment_repository.dart';

class GetCommentsScenario {
  const GetCommentsScenario(this._repository);

  final CommentRepository _repository;

  Future<Result<CursorPage<PostComment>>> call({
    required String postId,
    required int limit,
    String? cursor,
  }) {
    if (limit < 1 || limit > CommentPolicy.maxPageSize) {
      return Future.value(
        const Err(Failure.validation(message: '올바른 댓글 조회 범위가 아닙니다')),
      );
    }
    if (cursor != null && cursor.trim().isEmpty) {
      return Future.value(
        const Err(Failure.validation(message: '잘못된 댓글 커서입니다', field: 'cursor')),
      );
    }
    return _repository.getComments(postId: postId, limit: limit, cursor: cursor);
  }
}
```

`get_replies_scenario.dart` 는 같은 검증에 `_repository.getReplies(parentId: parentId, …)` 를 호출한다. 파라미터 이름은 `postId` 대신 `parentId` 다.

`add_comment_scenario.dart`:

```dart
import '../../../../../core/error/failure.dart';
import '../../../../../core/result/result.dart';
import '../../../../post/domain/entity/post_author.dart';
import '../../comment_policy.dart';
import '../../entity/post_comment.dart';
import '../../repository/comment_repository.dart';

/// 댓글·답글 작성. 앞뒤 공백을 다듬고 길이를 확인한 뒤 저장한다.
///
/// 길이 검증은 UX 이고 최종 판정은 DB 의 CHECK 다. 두 값이 어긋나면 사용자에게
/// 날것의 DB 오류가 가므로 `CommentPolicy` 가 같은 숫자를 들고 있다.
/// 2단 제한도 마찬가지로 최종 판정은 DB 트리거다.
class AddCommentScenario {
  const AddCommentScenario(this._repository);

  final CommentRepository _repository;

  Future<Result<PostComment>> call({
    required String postId,
    String? parentId,
    required String content,
    required PostAuthor author,
  }) {
    final trimmed = content.trim();

    if (trimmed.isEmpty) {
      return Future.value(
        const Err(
          Failure.validation(message: '댓글 내용을 입력해 주세요', field: 'content'),
        ),
      );
    }
    if (trimmed.length > CommentPolicy.maxContentLength) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '댓글은 ${CommentPolicy.maxContentLength}자까지 쓸 수 있습니다',
            field: 'content',
          ),
        ),
      );
    }

    return _repository.addComment(
      postId: postId,
      parentId: parentId,
      content: trimmed,
      author: author,
    );
  }
}
```

> `const Err(Failure.validation(message: '댓글은 ${…}자까지…'))` 는 상수 보간이 안 되면 `const` 를 빼고 일반 표현식으로 쓴다.

`delete_comment_scenario.dart`:

```dart
import '../../../../../core/error/failure.dart';
import '../../../../../core/result/result.dart';
import '../../repository/comment_repository.dart';

class DeleteCommentScenario {
  const DeleteCommentScenario(this._repository);

  final CommentRepository _repository;

  Future<Result<bool>> call(String commentId) {
    if (commentId.trim().isEmpty) {
      return Future.value(
        const Err(Failure.validation(message: '삭제할 댓글을 찾을 수 없습니다')),
      );
    }
    return _repository.deleteComment(commentId);
  }
}
```

`app/lib/features/comment/domain/usecase/comment_use_case.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/pagination/cursor_page.dart';
import '../../../../core/result/result.dart';
import '../../../post/domain/entity/post_author.dart';
import '../entity/post_comment.dart';
import '../repository/comment_repository.dart';
import 'scenario/add_comment_scenario.dart';
import 'scenario/delete_comment_scenario.dart';
import 'scenario/get_comments_scenario.dart';
import 'scenario/get_replies_scenario.dart';

/// 댓글 feature 의 presentation 진입점.
abstract interface class CommentUseCase {
  Future<Result<CursorPage<PostComment>>> getComments({
    required String postId,
    int limit,
    String? cursor,
  });

  Future<Result<CursorPage<PostComment>>> getReplies({
    required String parentId,
    int limit,
    String? cursor,
  });

  Future<Result<PostComment>> addComment({
    required String postId,
    String? parentId,
    required String content,
    required PostAuthor author,
  });

  Future<Result<bool>> deleteComment(String commentId);
}

@LazySingleton(as: CommentUseCase)
class DefaultCommentUseCase implements CommentUseCase {
  DefaultCommentUseCase(this._repository);

  final CommentRepository _repository;

  @override
  Future<Result<CursorPage<PostComment>>> getComments({
    required String postId,
    int limit = 20,
    String? cursor,
  }) => GetCommentsScenario(
    _repository,
  )(postId: postId, limit: limit, cursor: cursor);

  @override
  Future<Result<CursorPage<PostComment>>> getReplies({
    required String parentId,
    int limit = 20,
    String? cursor,
  }) => GetRepliesScenario(
    _repository,
  )(parentId: parentId, limit: limit, cursor: cursor);

  @override
  Future<Result<PostComment>> addComment({
    required String postId,
    String? parentId,
    required String content,
    required PostAuthor author,
  }) => AddCommentScenario(
    _repository,
  )(postId: postId, parentId: parentId, content: content, author: author);

  @override
  Future<Result<bool>> deleteComment(String commentId) =>
      DeleteCommentScenario(_repository)(commentId);
}
```

- [ ] **Step 17: 코드 생성 · 정적 분석 · 전체 테스트**

```bash
cd app && dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test
```

Expected: analyze 무경고, 전체 PASS

- [ ] **Step 18: 테스트 문서 작성**

`docs/testing/features/comment.md` 를 만든다. 형식은 `docs/testing/features/feed.md` 와 같은 **대상 · 시나리오 · 기대 결과** 표다. 위 네 테스트 파일의 케이스를 옮기고, 마지막에 "로컬 Supabase 로만 확인되는 것" 문단으로 [comment 계획서](../../features/comment/plan.md)의 검증 항목(2단 제한 트리거 · 삭제 본문 차단 · asc 커서 경계)을 가리킨다.

`docs/testing/README.md` 의 "Feature별 범위" 목록에 항목을 하나 더한다 — 표시 문구는 `comment`, 대상은 `features/comment.md` 인 상대 Markdown 링크다.

- [ ] **Step 19: 커밋**

```bash
cd app && flutter test && cd .. && git add app/lib/features/comment app/test/features/comment app/lib/core/di/injection.config.dart docs/testing/features/comment.md docs/testing/README.md && git commit -m "feat(comment): 2단 댓글의 조회·작성·삭제 usecase 를 만든다"
```

---

### Task 5: 피드에 반응·댓글 수 반영

**Files:**
- Modify: `app/lib/features/feed/data/dto/feed_post_dto.dart`
- Modify: `app/lib/features/feed/data/datasource/supabase_feed_data_source.dart`
- Modify: `app/lib/features/feed/data/mapper/feed_post_mapper.dart`
- Modify: `app/lib/features/feed/domain/entity/feed_post.dart`
- Modify: `app/lib/features/feed/presentation/cubit/feed_cubit.dart`
- Test: `app/test/features/feed/data/mapper/feed_post_mapper_test.dart` (케이스 추가)
- Test: `app/test/features/feed/presentation/cubit/feed_cubit_test.dart` (케이스 추가)
- Modify: `docs/testing/features/feed.md`
- Modify: `docs/status.md`

**Interfaces:**
- Consumes: Task 2 가 `posts_with_author` 에 더한 `reaction_counts` · `my_reaction` · `comment_count`, Task 3 의 `ReactionSummary`(`fromRaw`)
- Produces: `FeedPost.reactions` (`ReactionSummary`) · `FeedPost.commentCount` (`int`) · `FeedPost.withReactions(ReactionSummary)` · `FeedCubit.applyReaction(String postId, ReactionSummary next)`

- [ ] **Step 1: 실패하는 테스트 추가 — mapper**

`app/test/features/feed/data/mapper/feed_post_mapper_test.dart` 에 아래 두 케이스를 추가한다. 기존 케이스는 그대로 둔다.

```dart
  test('뷰가 내려준 반응 집계와 댓글 수를 항목에 담는다', () {
    final dto = FeedPostDto(
      id: 'post-1',
      authorId: 'author-1',
      content: '기록',
      createdAt: DateTime.utc(2026, 8, 23, 9),
      updatedAt: DateTime.utc(2026, 8, 23, 9),
      authorNickname: '카르마',
      reactionCounts: const {'like': 4, 'dislike': 1},
      myReaction: 'like',
      commentCount: 7,
    );

    final item = dto.toEntity();

    expect(item.reactions.countOf(ReactionType.like), 4);
    expect(item.reactions.countOf(ReactionType.dislike), 1);
    expect(item.reactions.mine, ReactionType.like);
    expect(item.commentCount, 7);
  });

  test('반응이 없으면 빈 집계이고 내 반응은 없다', () {
    final dto = FeedPostDto(
      id: 'post-1',
      authorId: 'author-1',
      content: '기록',
      createdAt: DateTime.utc(2026, 8, 23, 9),
      updatedAt: DateTime.utc(2026, 8, 23, 9),
      authorNickname: '카르마',
    );

    final item = dto.toEntity();

    expect(item.reactions.counts, isEmpty);
    expect(item.reactions.mine, isNull);
    expect(item.commentCount, 0);
  });
```

import 에 `package:daylog/features/reaction/domain/entity/reaction_type.dart` 를 추가한다.

- [ ] **Step 2: 실패하는 테스트 추가 — cubit**

`app/test/features/feed/presentation/cubit/feed_cubit_test.dart` 에 아래를 추가한다.

```dart
  blocTest<FeedCubit, FeedState>(
    '반응 결과를 해당 항목에만 반영한다',
    setUp: () => when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async =>
          Ok(CursorPage<FeedPost>(items: [_item('1'), _item('2')])),
    ),
    build: () => FeedCubit(useCase),
    act: (cubit) async {
      await cubit.load();
      cubit.applyReaction(
        '2',
        const ReactionSummary(
          counts: {ReactionType.like: 1},
          mine: ReactionType.like,
        ),
      );
    },
    verify: (cubit) {
      expect(cubit.state.items.first.reactions.mine, isNull);
      expect(cubit.state.items.last.reactions.mine, ReactionType.like);
      // 작성자는 반응으로 바뀌지 않는다.
      expect(cubit.state.items.last.author.nickname, '카르마');
    },
  );

  blocTest<FeedCubit, FeedState>(
    '목록을 읽기 전의 반응 반영은 무시한다',
    build: () => FeedCubit(useCase),
    act: (cubit) => cubit.applyReaction('1', const ReactionSummary()),
    expect: () => <FeedState>[],
  );
```

import 에 `reaction_summary.dart` 와 `reaction_type.dart` 를 추가한다.

- [ ] **Step 3: 실패 확인**

```bash
cd app && flutter test test/features/feed
```

Expected: 컴파일 실패

- [ ] **Step 4: DTO 에 세 필드 추가**

`feed_post_dto.dart` 의 생성자와 필드에 아래를 더한다. 기존 필드와 문서 주석은 그대로 둔다.

```dart
    this.reactionCounts = const {},
    this.myReaction,
    this.commentCount = 0,
```

```dart
  /// 감정별 개수. 개수를 컬럼이 아니라 map 으로 받으므로 감정이 늘어도
  /// DTO 를 고치지 않는다 — 뷰가 jsonb 로 내려준다.
  @override
  @JsonKey(name: 'reaction_counts', defaultValue: <String, int>{})
  final Map<String, int> reactionCounts;

  /// 내가 남긴 감정. 비로그인 조회이거나 남기지 않았으면 null 이다.
  @override
  @JsonKey(name: 'my_reaction')
  final String? myReaction;

  /// 살아 있는 댓글과 답글의 합.
  @override
  @JsonKey(name: 'comment_count', defaultValue: 0)
  final int commentCount;
```

클래스 문서 주석의 "앞으로 반응 수 · 댓글 수 컬럼이 여기에만 더해진다" 문장을 "반응 수 · 댓글 수 컬럼이 여기에만 있다" 로 고친다.

- [ ] **Step 5: datasource 의 조회 컬럼 추가**

`supabase_feed_data_source.dart` 의 `_columns` 를 바꾼다.

```dart
  static const _columns =
      'id, author_id, content, created_at, updated_at, '
      'author_nickname, author_avatar_url, images, '
      'reaction_counts, my_reaction, comment_count';
```

- [ ] **Step 6: entity 에 두 필드와 갱신 메서드 추가**

`feed_post.dart` 를 아래로 바꾼다. 기존 문서 주석은 유지하고 필드만 더한다.

```dart
  const FeedPost({
    required this.post,
    required this.author,
    this.reactions = const ReactionSummary(),
    this.commentCount = 0,
  });

  @override
  final Post post;
  @override
  final PostAuthor author;

  /// 감정 집계와 내 반응. 목록 뷰가 항목과 함께 내려준다.
  @override
  final ReactionSummary reactions;

  /// 살아 있는 댓글과 답글의 합.
  @override
  final int commentCount;

  String get id => post.id;

  /// 내용만 바뀐 게시물로 교체한다. 작성자·반응·댓글 수는 수정으로 바뀌지 않는다.
  FeedPost withPost(Post updated) => FeedPost(
    post: updated,
    author: author,
    reactions: reactions,
    commentCount: commentCount,
  );

  /// 반응만 교체한다. 낙관적 업데이트가 이 메서드를 쓴다.
  FeedPost withReactions(ReactionSummary next) => FeedPost(
    post: post,
    author: author,
    reactions: next,
    commentCount: commentCount,
  );
```

import 에 `../../../reaction/domain/entity/reaction_summary.dart` 를 추가한다.

- [ ] **Step 7: mapper 에 변환 추가**

`feed_post_mapper.dart` 의 `toEntity()` 를 바꾼다.

```dart
  FeedPost toEntity() => FeedPost(
    post: toPost(),
    author: toAuthor(),
    reactions: ReactionSummary.fromRaw(reactionCounts, myReaction),
    commentCount: commentCount,
  );
```

import 에 `../../../reaction/domain/entity/reaction_summary.dart` 를 추가한다.

- [ ] **Step 8: cubit 에 `applyReaction` 추가**

`feed_cubit.dart` 의 `removePost` 아래에 더한다.

```dart
  /// 반응 결과를 해당 항목에만 반영한다.
  ///
  /// 낙관적 업데이트의 두 방향이 모두 이 메서드를 쓴다 — 탭 직후에는 계산된
  /// 다음 상태를, 실패하면 이전 상태를 넣는다. 목록 상태는 목록이 소유한다
  /// (아키텍처 규칙 ⑥).
  void applyReaction(String postId, ReactionSummary next) {
    final current = state;
    if (current.status != FeedStatus.loaded) return;
    emit(
      current.copyWith(
        items: [
          for (final item in current.items)
            if (item.id == postId) item.withReactions(next) else item,
        ],
      ),
    );
  }
```

import 에 `../../../reaction/domain/entity/reaction_summary.dart` 를 추가한다.

- [ ] **Step 9: 코드 생성 · 정적 분석 · 전체 테스트**

```bash
cd app && dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test
```

Expected: analyze 무경고, 전체 PASS

- [ ] **Step 10: 문서 갱신**

`docs/testing/features/feed.md` 의 표에 Step 1·2 에서 추가한 케이스를 넣는다.

`docs/status.md` 를 갱신한다. **주의: 아래 항목에 다는 문서 링크는 `status.md` 기준
상대 경로이고, 형식은 1단계의 F2 · F3 항목과 같다** (`([계획] · [기록])` 모양).
`history.md` 는 아직 없으므로 계획 문서만 건다 — 없는 파일을 가리키면
`documentation_links_test` 가 잡는다.

- "단계 요약" 표의 2단계 상태를 `대기` → `진행 중` 으로 바꾼다
- "1단계 — 진행 중" 절 아래에 `## 2단계 — 진행 중` 절을 새로 만들고 네 항목을 넣는다

| 체크 | 항목 | 내용 | 링크 대상 |
|---|---|---|---|
| `[x]` | **F5 reaction** | 게시물·댓글 공용 감정표현. 대상별 테이블 + `ReactionTarget` 으로 일반화, 집계는 목록 뷰의 `jsonb` | `features/reaction/plan.md` |
| `[x]` | **F6 comment** | 2단 댓글. 제한은 트리거, 조회는 `post_comments_visible`(`security_invoker = off` 예외), 오래된 순 커서 | `features/comment/plan.md` |
| `[ ]` | F5 · F6 화면 | 반응 버튼 · 댓글 목록 · 답글 지연 로딩 | — |
| `[ ]` | **F7 safety** | 신고 · 차단 | — |

- "다음 할 일" 절의 항목을 아래 셋으로 바꾼다

| # | 내용 | 링크 대상 |
|---|---|---|
| 1 | 로컬 Supabase 통합 확인 — 두 계획서의 "검증 항목" | `features/reaction/plan.md` · `features/comment/plan.md` |
| 2 | F5 · F6 화면 작업 (게시물 상세 · 댓글 목록 · 반응 버튼) | — |
| 3 | F7 safety 착수 — **차단 필터를 `posts_with_author` 와 `post_comments_visible` 양쪽에 넣어야 한다** | — |

- [ ] **Step 11: 검사 후 커밋**

```bash
cd app && flutter test && cd .. && git add app/lib/features/feed app/test/features/feed docs/testing/features/feed.md docs/status.md && git commit -m "feat(feed): 목록 항목에 반응 집계와 댓글 수를 싣는다"
```
