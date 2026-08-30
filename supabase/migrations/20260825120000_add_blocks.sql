-- F7 차단. 서로의 게시물·댓글을 양방향으로 가린다.
-- 설계 근거는 docs/features/safety/plan-block.md 에 있다.
--
-- 이 마이그레이션은 신고(F7 신고)와 달리 새 테이블 하나로 끝나지 않는다.
-- 이미 동작하는 조회 경로 셋(posts_select_visible · post_comments_select_visible ·
-- post_comments_visible)을 재정의하고, 댓글 삽입 트리거에 검사를 하나 더한다.

-- -----------------------------------------------------------------------------
-- 1. 테이블과 판정 함수
-- -----------------------------------------------------------------------------

create table public.blocks (
  blocker_id uuid        not null default auth.uid()
                         references public.profiles (id) on delete cascade,
  blocked_id uuid        not null
                         references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),

  constraint blocks_not_self check (blocker_id <> blocked_id),
  primary key (blocker_id, blocked_id)
);

-- "누가 나를 차단했는가" 방향. PK 가 반대 방향만 덮으므로 따로 필요하다.
-- 이것이 없으면 양방향 판정(is_blocked_with)이 모든 게시물 조회마다
-- blocks 전체 스캔을 탄다.
create index blocks_blocked_idx on public.blocks (blocked_id);

-- 차단 여부의 유일한 정의다. 조회 정책 둘, post_comments_visible 뷰,
-- 댓글 삽입 트리거가 모두 이 함수 하나만 부른다 — 정의가 네 곳에 흩어지면
-- 언젠가 어긋난다.
--
-- security definer 가 필수다(방어적 선택이 아니다). blocks 의 조회 정책은
-- blocker_id = auth.uid() 인 행만 보여준다 — 내가 건 차단이다. "상대가 나를
-- 차단했는가"는 내 권한으로는 읽을 수 없는 행을 봐야 하므로 invoker 로는
-- 언제나 false 가 나와 판정 자체가 성립하지 않는다.
--
-- stable 이라 한 질의 안에서 같은 인자에 대해 한 번만 평가된다. auth.uid() 는
-- 세션 GUC 기반이라 definer 함수 안에서도 조회자 기준으로 동작한다
-- (posts_with_author 의 my_reaction 과 같은 근거, docs/schema.md §6).
create function public.is_blocked_with(other_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.blocks b
     where (b.blocker_id = (select auth.uid()) and b.blocked_id = other_id)
        or (b.blocker_id = other_id and b.blocked_id = (select auth.uid()))
  );
$$;

-- -----------------------------------------------------------------------------
-- 2. 조회 정책 둘 — 여기가 회귀 위험의 중심이다
-- -----------------------------------------------------------------------------
--
-- 비로그인(anon)이면 auth.uid() 가 null 이라 is_blocked_with() 의 exists 가
-- false 를 돌려주므로 필터가 그냥 통과된다. 차단은 로그인한 사용자 사이의
-- 관계이므로 이 동작이 맞다 — 비로그인 조회는 영향을 받지 않는다.
--
-- posts 정책을 고치면 posts_with_author 도 함께 막힌다 — 그 뷰가
-- security_invoker = on 이기 때문이다(docs/schema.md §6). 뷰의 where 에 쓰지
-- 않는 이유가 이것이다: 정책에 두면 뷰·테이블 직접 조회·comment_count
-- 서브쿼리가 한꺼번에 덮인다.
alter policy "posts_select_visible" on public.posts
  using (deleted_at is null and not public.is_blocked_with(author_id));

-- post_comments 정책을 고치면 posts_with_author 의 comment_count 도
-- 차단된 사람의 댓글을 세지 않는다. 목록에 보이는 개수와 실제로 열리는
-- 목록이 어긋나지 않는다.
alter policy "post_comments_select_visible" on public.post_comments
  using (deleted_at is null and not public.is_blocked_with(author_id));

-- -----------------------------------------------------------------------------
-- 3. post_comments_visible 재정의 — 손으로 써야 하는 자리
-- -----------------------------------------------------------------------------
--
-- 이 뷰만 security_invoker = off 라 위 정책이 평가되지 않는다
-- (docs/schema.md §9 가 예고한 부채). 최신 정의
-- (20260823180000_add_reactions.sql, 반응 집계가 붙은 판)를 그대로 가져와
-- 세 곳에만 조건을 더한다. create or replace view 는 컬럼을 빼거나 순서를
-- 바꿀 수 없으므로 컬럼 목록은 그대로다.
--
--   1) 본문 where 의 두 갈래(삭제 안 된 댓글 / 답글이 남은 부모 되살리기)를
--      모두 감싸도록 and not is_blocked_with(c.author_id) 를 건다
--   2) reply_count 서브쿼리 — 차단된 사람의 답글은 세지 않는다
--   3) "살아 있는 답글이 있는가" exists — 차단된 사람의 답글만 남은 부모는
--      되살리지 않는다
--
-- 셋 중 하나라도 빠지면 개수와 목록이 어긋난다. 답글 3개로 표시되는데
-- 펼치면 1개가 나오는 식이다.
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
       and not public.is_blocked_with(reply.author_id)
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
where not public.is_blocked_with(c.author_id)
  and (
    c.deleted_at is null
    or (
      c.parent_id is null
      and exists (
        select 1 from public.post_comments reply
        where reply.parent_id = c.id and reply.deleted_at is null
          and not public.is_blocked_with(reply.author_id)
      )
    )
  );

grant select on public.post_comments_visible to anon, authenticated;

-- -----------------------------------------------------------------------------
-- 4. enforce_comment_depth() — 댓글 삽입 차단
-- -----------------------------------------------------------------------------
--
-- 정책(with check)이 아니라 트리거에 검사를 얹는 이유가 있다. 정책 안에서
-- 게시물 작성자를 찾으려면 posts 를 서브쿼리로 읽어야 하는데, 그 조회는
-- 방금 posts_select_visible 에 넣은 차단 필터에 걸려 행 자체가 사라진다.
-- 그러면 author_id 가 null 로 조회되고 is_blocked_with(null) 이 false 가
-- 되어 삽입이 도리어 허용된다. enforce_comment_depth() 는 이미
-- security definer 라 RLS 를 우회하므로 이 함정이 없다 — 새 트리거를 만들지
-- 않고 여기에 얹는다.
--
-- 기존 검사 네 가지(부모 존재 · 답글의 답글 · 같은 게시물 · 삭제된 부모)는
-- 그대로 두고, 그보다 먼저 게시물 작성자 차단 검사를 추가한다. new.parent_id
-- 가 null(최상위 댓글)이어도 게시물 작성자 차단은 여전히 봐야 하므로, 이
-- 검사는 기존의 "parent_id is null 이면 통과" 이른 return 보다 앞에 있어야
-- 한다.
create or replace function public.enforce_comment_depth()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  post_author_id   uuid;
  parent_post_id   uuid;
  parent_parent_id uuid;
  parent_deleted   timestamptz;
begin
  select author_id into post_author_id
    from public.posts
   where id = new.post_id;

  if post_author_id is not null and public.is_blocked_with(post_author_id) then
    raise exception '차단한 사용자의 게시물에는 댓글을 달 수 없습니다'
      using errcode = '42501';
  end if;

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

-- -----------------------------------------------------------------------------
-- 5. blocked_users 뷰 · RLS · GRANT
-- -----------------------------------------------------------------------------

alter table public.blocks enable row level security;

create policy "blocks_select_own" on public.blocks for select to authenticated
  using ((select auth.uid()) = blocker_id);
create policy "blocks_insert_own" on public.blocks for insert to authenticated
  with check ((select auth.uid()) = blocker_id);
create policy "blocks_delete_own" on public.blocks for delete to authenticated
  using ((select auth.uid()) = blocker_id);

-- blocker_id 에 INSERT 를 주지 않는 것이 위조를 막는 방법이다.
-- default auth.uid() 가 채운다 — 신고(F7 신고)와 같은 규칙이다.
-- UPDATE 정책·권한은 없다. 차단은 수정되지 않고 걸거나 푸는 것뿐이다.
grant select, delete on public.blocks to authenticated;
grant insert (blocked_id) on public.blocks to authenticated;

-- 차단 목록 화면이 읽는 유일한 대상. security_invoker = on 이라
-- blocks_select_own 정책이 그대로 걸린다 — 뷰에 where 를 쓰지 않아도
-- 내가 건 차단만 나온다(docs/schema.md §6 의 기본 규칙).
create view public.blocked_users
with (security_invoker = on) as
select
  b.blocked_id  as id,
  b.created_at,
  pr.nickname,
  pr.avatar_url
from public.blocks b
join public.profiles pr on pr.id = b.blocked_id;

grant select on public.blocked_users to authenticated;
