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

-- 조회 정책은 전역 규칙 그대로 단순하게 둔다.
-- ★ 여기서 post_comments 를 서브쿼리로 다시 참조하면 PostgreSQL 이 정책을 재귀로
-- 판단해 42P17 로 거부한다 (조회뿐 아니라 insert ... returning 까지 죽는다).
-- "삭제됐지만 답글이 남은 부모"를 되살리는 일은 아래 definer 뷰가 전담하므로
-- 정책을 좁게 두어도 새는 곳이 없다. 테이블 경로가 뷰보다 좁은 것은 안전하다.
create policy "post_comments_select_visible"
  on public.post_comments for select to anon, authenticated
  using (deleted_at is null);

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
