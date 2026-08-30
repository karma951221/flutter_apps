-- F8 팔로우. 단방향 엣지 하나로 팔로우·맞팔·목록·팔로잉 피드를 모두 만든다.
-- 설계 근거는 docs/features/follow/plan.md 에 있다.
--
-- 새 테이블 하나로 끝나지 않는다. blocks(§13)에 트리거가 하나 붙고,
-- 프로필 조회가 뷰를 타게 되며, 피드가 읽을 뷰가 하나 늘어난다.

-- -----------------------------------------------------------------------------
-- 1. 테이블
-- -----------------------------------------------------------------------------

create table public.follows (
  follower_id uuid        not null default auth.uid()
                          references public.profiles (id) on delete cascade,
  followee_id uuid        not null
                          references public.profiles (id) on delete cascade,
  created_at  timestamptz not null default now(),

  constraint follows_not_self check (follower_id <> followee_id),
  primary key (follower_id, followee_id)
);

-- "누가 나를 팔로우하는가" 방향. 복합 PK 는 반대 방향(내가 팔로우한 사람들)만
-- 덮으므로 팔로워 목록·팔로워 수에는 이 인덱스가 필요하다 — blocks_blocked_idx
-- 와 같은 이유다. 목록이 최신순 커서를 타므로 created_at 까지 넣는다.
create index follows_followee_idx
  on public.follows (followee_id, created_at desc, follower_id desc);

-- 팔로잉 목록도 같은 커서를 쓴다. PK 의 (follower_id, followee_id) 순서로는
-- created_at 정렬이 인덱스를 타지 못한다.
create index follows_follower_idx
  on public.follows (follower_id, created_at desc, followee_id desc);

-- -----------------------------------------------------------------------------
-- 2. RLS · GRANT
-- -----------------------------------------------------------------------------
--
-- blocks 와 달리 조회를 전체 공개로 연다. 남의 프로필에서도 팔로워 수와 목록이
-- 보여야 하는데, 본인 행만 열면 수·목록·맞팔 판정이 전부 security definer
-- 함수를 타야 한다. 팔로우 그래프가 공개인 것은 F8 의 확정 결정이다.

alter table public.follows enable row level security;

create policy "follows_select_all" on public.follows for select
  to anon, authenticated
  using (true);

-- 위조 방어는 GRANT 가 1차(follower_id 에 INSERT 권한이 없다), 이 정책이 2차다.
--
-- 차단 검사는 is_blocked_with()(§3) 를 그대로 부른다 — 양방향이라 내가
-- 차단했든 상대가 나를 차단했든 같은 결과가 나온다. 그래서 앱의 거부 문구는
-- 방향을 밝히면 안 된다 (docs/features/safety/plan-block.md 의 일반화된 규칙).
create policy "follows_insert_own" on public.follows for insert to authenticated
  with check (
    (select auth.uid()) = follower_id
    and not public.is_blocked_with(followee_id)
  );

create policy "follows_delete_own" on public.follows for delete to authenticated
  using ((select auth.uid()) = follower_id);

grant select on public.follows to anon, authenticated;
grant insert (followee_id) on public.follows to authenticated;
grant delete on public.follows to authenticated;

-- UPDATE 정책·권한은 두지 않는다. 팔로우는 수정되지 않고 걸거나 푸는 것뿐이다.

-- -----------------------------------------------------------------------------
-- 3. 차단이 팔로우 엣지를 지운다
-- -----------------------------------------------------------------------------
--
-- F7(차단) 계획이 "F8 착수 시점까지 미룬다"고 명시해 둔 결정이다. 지우는 쪽을
-- 고른 이유: 지우지 않으면 차단한 상대가 팔로워 수에는 계속 잡히고 목록에서만
-- 사라져 수와 목록이 어긋난다.
--
-- 대가도 명시한다 — 차단 계획의 "차단에는 자식이 달리지 않는다"는 전제가
-- 이 트리거로 깨진다. blocks 가 follows 에 부수 효과를 갖는 부모가 됐다.
--
-- security definer 가 필수다. 차단당한 쪽이 건 팔로우 행은 follows_delete_own
-- (follower_id = auth.uid()) 으로는 지울 수 없다.
create function public.drop_follows_on_block()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.follows
   where (follower_id = new.blocker_id and followee_id = new.blocked_id)
      or (follower_id = new.blocked_id and followee_id = new.blocker_id);
  return new;
end;
$$;

create trigger blocks_drop_follows
  after insert on public.blocks
  for each row execute function public.drop_follows_on_block();

-- 차단을 해제해도 팔로우는 되살아나지 않는다. 행이 지워졌으므로 다시 누르는
-- 것은 사용자의 몫이다.

-- -----------------------------------------------------------------------------
-- 4. profile_details — 프로필 화면이 읽는 하나의 대상
-- -----------------------------------------------------------------------------
--
-- 수 둘 + 관계 둘을 화면이 네 번 조회하지 않게 한다 (기획 F2 의 "뷰 또는 RPC
-- 하나로 묶어 내려준다").
--
-- security_invoker = on 이면 충분하다. profiles 에는 조회 정책이 없고
-- (차단 계획의 의도적 선택), follows 는 전체 공개다.
--
-- 수는 차단 필터를 타지 않는다. 내가 차단한 사람이 남의 팔로워 수에서 빠지면
-- 조회자마다 수가 달라지고 목록의 행 수와도 어긋난다. 필터는 목록 뷰에만
-- 건다 (§5).
create view public.profile_details
with (security_invoker = on) as
select
  pr.id,
  pr.nickname,
  pr.bio,
  pr.avatar_url,
  pr.created_at,
  pr.updated_at,
  coalesce(followers.total, 0) as follower_count,
  coalesce(followings.total, 0) as following_count,
  exists (
    select 1
      from public.follows f
     where f.follower_id = (select auth.uid())
       and f.followee_id = pr.id
  ) as is_following,
  exists (
    select 1
      from public.follows f
     where f.follower_id = pr.id
       and f.followee_id = (select auth.uid())
  ) as is_followed_by
from public.profiles pr
left join lateral (
  select count(*) as total
    from public.follows f
   where f.followee_id = pr.id
) followers on true
left join lateral (
  select count(*) as total
    from public.follows f
   where f.follower_id = pr.id
) followings on true;

grant select on public.profile_details to anon, authenticated;

-- -----------------------------------------------------------------------------
-- 5. 목록 뷰 둘 — 차단 필터를 손으로 적는 자리
-- -----------------------------------------------------------------------------
--
-- 차단이 가리는 다른 모든 것(posts · post_comments)은 정책이 걸린 테이블을
-- 거치지만, 여기는 follows → profiles 조인이고 profiles 에는 정책이 없다.
-- 차단 계획이 "F8 이 잊으면 차단한 상대가 서로의 팔로워 목록에 계속
-- 나타난다"고 예고한 부채가 이 자리다.
--
-- 트리거(§3)가 있어도 필터를 함께 둔다. 트리거는 차단 시점의 엣지만 지우고,
-- 두 사람이 제3자의 목록에 함께 나타나는 경우는 덮지 못한다.
--
-- 방향에 따라 "상대"가 반대쪽 컬럼이라 뷰를 둘로 나눈다. 하나로 묶으면
-- 화면이 매번 방향을 계산해야 한다.

-- user_id 를 팔로우하는 사람들.
create view public.user_followers
with (security_invoker = on) as
select
  f.followee_id as user_id,
  f.follower_id as id,
  f.created_at,
  pr.nickname,
  pr.avatar_url
from public.follows f
join public.profiles pr on pr.id = f.follower_id
where not public.is_blocked_with(f.follower_id);

-- user_id 가 팔로우하는 사람들.
create view public.user_followings
with (security_invoker = on) as
select
  f.follower_id as user_id,
  f.followee_id as id,
  f.created_at,
  pr.nickname,
  pr.avatar_url
from public.follows f
join public.profiles pr on pr.id = f.followee_id
where not public.is_blocked_with(f.followee_id);

grant select on public.user_followers to anon, authenticated;
grant select on public.user_followings to anon, authenticated;

-- -----------------------------------------------------------------------------
-- 6. following_posts_with_author — 팔로잉 피드
-- -----------------------------------------------------------------------------
--
-- 커서·컬럼·정렬이 posts_with_author 와 같아서 앱은 읽는 대상만 바꾼다.
-- PostgREST 에 서브쿼리를 흉내 내는 필터를 짜 넣지 않는다.
--
-- 감싸는 뷰라 삭제·차단 필터를 다시 쓰지 않는다 — posts_with_author 가
-- security_invoker = on 이라 posts_select_visible 정책을 그대로 물려받고,
-- 이 뷰도 invoker 다.
--
-- 비로그인이면 auth.uid() 가 null 이라 조인이 0행을 돌려준다. 팔로잉 피드는
-- 로그인 사용자의 것이므로 그 동작이 맞다.
create view public.following_posts_with_author
with (security_invoker = on) as
select p.*
from public.posts_with_author p
join public.follows f
  on f.followee_id = p.author_id
 and f.follower_id = (select auth.uid());

grant select on public.following_posts_with_author to authenticated;
