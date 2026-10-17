-- =============================================================================
-- pawlog W5 social — 공유 산책(walk_posts) · 좋아요(walk_post_likes) ·
-- 공유 RPC 2개 · 목록 뷰 walk_posts_with_author
--
-- 트레이더와 같은 프로젝트 · 같은 계정(profiles)을 쓴다. 트레이더의 posts 와
-- 섞이지 않게 walk_ 접두사를 붙인다(apps/pawlog/docs/features/social/plan.md 결정 2).
--
-- 산책 기록은 기기(drift)에 먼저 저장되고, 사용자가 고른 한 건만 여기로 올라온다.
-- 같은 산책은 (author_id, local_walk_id) 로 한 행이다. 공유 취소는 소프트 삭제,
-- 다시 공유하면 그 행을 되살린다 — 둘 다 RPC 로만 한다.
--
-- 결과의 전체 모습은 apps/trader/docs/schema.md §18 을 본다.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. 테이블
-- -----------------------------------------------------------------------------

-- 반려견 이름 배열의 원소 검사. CHECK 안에는 서브쿼리를 못 쓰므로 immutable 함수로 감싼다.
-- 이름마다 공백을 빼고 1자 이상, 30자 이하. null 원소도 거부한다.
create function public.walk_dog_names_valid(p_names text[])
returns boolean
language sql
immutable
set search_path = ''
as $$
  select coalesce(bool_and(n is not null and char_length(btrim(n)) between 1 and 30), false)
    from unnest(p_names) as n;
$$;

comment on function public.walk_dog_names_valid(text[]) is
  'walk_posts.dog_names CHECK 용. 원소가 모두 공백 아닌 1~30자면 true.';

create table public.walk_posts (
  id               uuid             primary key default gen_random_uuid(),
  author_id        uuid             not null default auth.uid()
                                    references public.profiles (id) on delete cascade,
  -- 기기의 산책 id. 같은 산책을 두 번 공유해도 한 행이 되게 하는 열쇠다.
  local_walk_id    uuid             not null,
  started_at       timestamptz      not null,
  duration_seconds integer          not null check (duration_seconds >= 0),
  distance_meters  double precision not null check (distance_meters >= 0),
  dog_names        text[]           not null check (cardinality(dog_names) between 1 and 10)
                                    check (public.walk_dog_names_valid(dog_names)),
  memo             text             check (char_length(memo) <= 500),
  -- 앞뒤 150 m 를 잘라 낸 경로 미리보기([{lat, lng}, ...]). 잘라 내기는 앱이 한다.
  -- 원소 모양({lat, lng} 숫자)은 publish_walk_post 가 검사한다. 크기는 여기서 막는다.
  route_preview    jsonb            check (route_preview is null or jsonb_array_length(route_preview) <= 64)
                                    check (route_preview is null or pg_column_size(route_preview) <= 8192),
  created_at       timestamptz      not null default now(),
  deleted_at       timestamptz,
  unique (author_id, local_walk_id)
);

-- 모두의 산책 커서 (created_at desc, id desc). 살아 있는 행만 담는 부분 인덱스(§2).
create index walk_posts_created_at_idx
  on public.walk_posts (created_at desc, id desc) where deleted_at is null;

comment on table public.walk_posts is
  'pawlog 에서 사용자가 골라 공유한 산책 한 건. 쓰기는 publish_walk_post · unpublish_walk_post RPC 로만 한다.';
comment on column public.walk_posts.deleted_at is
  '공유 취소 시각. null 이면 공유 중이다. 다시 공유하면 null 로 돌아간다.';

create table public.walk_post_likes (
  post_id    uuid        not null references public.walk_posts (id) on delete cascade,
  user_id    uuid        not null default auth.uid()
                         references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

-- "내가 누른 좋아요" 를 user_id 로 찾는 경로와 탈퇴 cascade 용.
-- (post_id, ...) 쪽은 PK 가 이미 덮는다.
create index walk_post_likes_user_id_idx on public.walk_post_likes (user_id);

comment on table public.walk_post_likes is
  '공유 산책 좋아요. 한 사람이 한 글에 한 번(PK). 살아 있는 글에만 누를 수 있다.';

-- -----------------------------------------------------------------------------
-- 2. RLS
-- -----------------------------------------------------------------------------
alter table public.walk_posts enable row level security;
alter table public.walk_post_likes enable row level security;

-- 조회: 공유 중인 글만. 둘러보기는 로그인 없이 된다(결정 6).
create policy "walk_posts_select_visible"
  on public.walk_posts for select to anon, authenticated
  using (deleted_at is null);

-- insert · update · delete 정책은 없다 — 쓰기는 RPC(definer) 둘로만 한다.
-- 소프트 삭제를 UPDATE 로 하면 42501 이 나는 이유는 schema.md §11 에 있다.

-- 조회: 공유 중인 글의 좋아요만. walk_posts 는 조회자 RLS 로 삭제행이 가려지므로
-- exists 만으로 공유 취소한 글의 좋아요가 숨는다. 다른 테이블 참조라 42P17 은 아니다.
create policy "walk_post_likes_select_visible"
  on public.walk_post_likes for select to anon, authenticated
  using (
    exists (select 1 from public.walk_posts wp where wp.id = walk_post_likes.post_id)
  );

-- 삽입: 본인 것만, 그리고 공유 중인 글에만. 다른 테이블 참조라 42P17 은 아니다(§11).
create policy "walk_post_likes_insert_own"
  on public.walk_post_likes for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.walk_posts wp
       where wp.id = walk_post_likes.post_id and wp.deleted_at is null
    )
  );

create policy "walk_post_likes_delete_own"
  on public.walk_post_likes for delete to authenticated
  using ((select auth.uid()) = user_id);

-- -----------------------------------------------------------------------------
-- 3. GRANT — 컬럼 단위, 최소한만
-- -----------------------------------------------------------------------------
-- Supabase 기본 권한으로 붙은 것까지 모두 회수하고 필요한 것만 다시 준다.
revoke all privileges on public.walk_posts from anon, authenticated;
revoke all privileges on public.walk_post_likes from anon, authenticated;

-- 앱(anon 포함)은 보기만 읽는다. 다만 기반 테이블 select 는 security_invoker 뷰가
-- 평가될 때 필요하다. posts(§5)처럼 테이블 단위로 준다 — deleted_at 을 빼면
-- walk_post_likes 삽입 정책의 exists 서브쿼리(조회자 권한으로 돈다)가 그 컬럼을
-- 못 읽어 좋아요가 42501 로 막힌다. 조회 정책이 삭제행을 가리므로 보이는 행의
-- deleted_at 은 언제나 null 이라 새는 것이 없다.
-- insert · update · delete 는 어떤 role 에도 주지 않는다.
grant select on public.walk_posts to anon, authenticated;

grant select            on public.walk_post_likes to anon, authenticated;
grant insert (post_id)  on public.walk_post_likes to authenticated;
grant delete            on public.walk_post_likes to authenticated;

-- -----------------------------------------------------------------------------
-- 4. RPC
-- -----------------------------------------------------------------------------

-- 공유(또는 다시 공유). 같은 (auth.uid(), local_walk_id) 가 있으면 내용을 갱신하고
-- deleted_at 을 지운다. 되살린 행은 id 가 그대로라 좋아요도 그대로 돌아온다.
-- created_at 도 now() 로 다시 찍는다 — 다시 공유한 산책은 모두의 산책 맨 위에 온다.
--
-- security definer 다. update 를 어떤 role 에도 주지 않았고, 공유 취소된 행은
-- 조회 정책에 걸려 invoker 로는 on conflict do update 가 닿지 않는다.
-- 그래서 author_id 를 auth.uid() 로 직접 넣는 것이 권한 경계 그 자체다 —
-- 남의 행은 (author_id, local_walk_id) 충돌 대상에 들어올 수 없다.
create function public.publish_walk_post(
  p_local_walk_id    uuid,
  p_started_at       timestamptz,
  p_duration_seconds integer,
  p_distance_meters  double precision,
  p_dog_names        text[],
  p_memo             text,
  p_route_preview    jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_id  uuid;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  -- 경로 미리보기는 null 이거나 {lat, lng} 숫자 객체의 배열이어야 한다.
  -- 앱이 그대로 그림으로 그리므로 모양이 어긋난 값은 저장 전에 막는다.
  if p_route_preview is not null and (
       jsonb_typeof(p_route_preview) <> 'array'
       or exists (
         select 1
           from jsonb_array_elements(p_route_preview) as e
          where jsonb_typeof(e) <> 'object'
             or jsonb_typeof(e -> 'lat') is distinct from 'number'
             or jsonb_typeof(e -> 'lng') is distinct from 'number'
       )
     ) then
    raise exception 'invalid route_preview' using errcode = '22023';
  end if;

  insert into public.walk_posts as wp (
    author_id, local_walk_id, started_at, duration_seconds,
    distance_meters, dog_names, memo, route_preview
  )
  values (
    v_uid, p_local_walk_id, p_started_at, p_duration_seconds,
    p_distance_meters, p_dog_names, p_memo, p_route_preview
  )
  on conflict (author_id, local_walk_id) do update
     set started_at       = excluded.started_at,
         duration_seconds = excluded.duration_seconds,
         distance_meters  = excluded.distance_meters,
         dog_names        = excluded.dog_names,
         memo             = excluded.memo,
         route_preview    = excluded.route_preview,
         created_at       = now(),
         deleted_at       = null
  returning wp.id into v_id;

  return v_id;
end;
$$;

comment on function public.publish_walk_post(uuid, timestamptz, integer, double precision, text[], text, jsonb) is
  '산책 한 건을 공유한다. 같은 local_walk_id 면 내용을 갱신하고 공유 취소를 되돌린다. 글 id 를 돌려준다.';

revoke execute on function public.publish_walk_post(uuid, timestamptz, integer, double precision, text[], text, jsonb)
  from public, anon;
grant execute on function public.publish_walk_post(uuid, timestamptz, integer, double precision, text[], text, jsonb)
  to authenticated;

-- 공유 취소. 본인 것만 deleted_at 을 채운다. 바뀐 행이 있으면 true.
-- soft_delete_post 와 같은 모양이다 — where 의 author_id 조건이 권한 경계다.
create function public.unpublish_walk_post(p_local_walk_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected integer;
begin
  update public.walk_posts
     set deleted_at = now()
   where local_walk_id = p_local_walk_id
     and author_id = (select auth.uid())
     and deleted_at is null;

  get diagnostics affected = row_count;
  return affected > 0;
end;
$$;

comment on function public.unpublish_walk_post(uuid) is
  '내 공유 산책을 공유 취소(소프트 삭제)한다. 바뀐 행이 있으면 true, 없거나 남의 것이면 false.';

revoke execute on function public.unpublish_walk_post(uuid) from public, anon;
grant execute on function public.unpublish_walk_post(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 5. 목록 뷰
--
-- security_invoker = on: 조회자의 권한으로 walk_posts_select_visible 이 평가되어
-- 공유 취소된 글이 저절로 빠진다(§6 과 같은 이유).
-- liked_by_me 는 anon 이면 auth.uid() 가 null 이라 false 다.
-- -----------------------------------------------------------------------------
create view public.walk_posts_with_author
with (security_invoker = on) as
select
  wp.id,
  wp.author_id,
  wp.local_walk_id,
  wp.started_at,
  wp.duration_seconds,
  wp.distance_meters,
  wp.dog_names,
  wp.memo,
  wp.route_preview,
  wp.created_at,
  pr.nickname   as author_nickname,
  pr.avatar_url as author_avatar_url,
  (select count(*) from public.walk_post_likes l where l.post_id = wp.id) as like_count,
  exists (
    select 1 from public.walk_post_likes l
     where l.post_id = wp.id and l.user_id = (select auth.uid())
  ) as liked_by_me
from public.walk_posts wp
join public.profiles pr on pr.id = wp.author_id;

comment on view public.walk_posts_with_author is
  '모두의 산책 목록. 공유 산책 + 작성자 프로필 + 좋아요 수 · 내 좋아요. security_invoker=on.';

-- 뷰는 기반 테이블의 GRANT 를 물려받지 않는다. 조회 전용.
grant select on public.walk_posts_with_author to anon, authenticated;
