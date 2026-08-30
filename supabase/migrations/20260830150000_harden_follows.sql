-- F8 팔로우 검수(2026-08-30)에서 나온 결함 둘을 막는다.
-- 근거와 재현 절차는 docs/features/follow/history.md 에 있다.
--
-- 1) 팔로우 삽입과 차단이 겹치면 엣지가 살아남는다 (정합성)
-- 2) following_posts_with_author 의 select p.* 가 컬럼을 동결한다 (취약성)

-- -----------------------------------------------------------------------------
-- 1. 팔로우 × 차단 동시성
-- -----------------------------------------------------------------------------
--
-- 원래 방어는 두 갈래였다 — follows_insert_own 정책의 is_blocked_with() 검사와
-- blocks 의 after insert 트리거. 둘 다 "상대 트랜잭션이 이미 커밋했다"를 전제한다.
--
-- READ COMMITTED 에서 두 트랜잭션이 겹치면 전제가 깨진다. 트리거의 delete 는
-- 아직 커밋되지 않은 follow 행을 보지 못하고, follow 를 넣는 쪽도 blocks 에
-- 락을 잡지 않아 상대의 차단을 보지 못한다. 둘 다 성공하고 엣지가 남는다.
--
-- 두 세션으로 재현된다:
--   A: begin; insert into follows(followee_id) values (B);   -- 아직 커밋 안 함
--   B: insert into blocks(blocked_id) values (A);            -- 트리거가 0행 삭제
--   A: commit;                                               -- 엣지 확정
--
-- 남은 엣지는 차단당한 쪽 화면에 "팔로잉 중"으로 그려지고, 차단한 쪽에서는
-- 수(1)와 목록(0행)이 어긋난다 — 트리거를 도입한 근거였던 그 어긋남이다.
-- 게다가 다시 차단해도 복구되지 않는다. blocks PK 가 이미 있어 insert 가
-- 23505 로 실패하고 after insert 트리거는 발화조차 하지 않는다.
--
-- 두 경로를 같은 advisory 락으로 직렬화해 막는다. 락 키는 두 id 를 정렬해
-- 만들므로 (A,B) 와 (B,A) 가 같은 키가 된다 — 방향이 반대인 두 동작이
-- 서로를 기다린다. 트랜잭션 락이라 커밋·롤백에서 자동으로 풀린다.

create function public.follow_pair_lock(a uuid, b uuid)
returns void
language sql
set search_path = ''
as $$
  select pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      case when a::text < b::text then a::text || b::text
           else b::text || a::text end,
      0
    )
  );
$$;

-- follows 쪽 가드. 락을 잡은 뒤 차단을 다시 확인한다.
--
-- is_blocked_with() 를 쓰지 않는다 — 그 함수는 auth.uid() 기준인데, 여기서는
-- 삽입되는 행의 두 사람 사이를 봐야 한다. definer 로 blocks 를 직접 읽는다
-- (blocks_select_own 이 상대가 건 차단을 가리므로 invoker 로는 판정할 수 없다.
-- is_blocked_with() 가 definer 인 것과 같은 이유다).
--
-- 정책의 is_blocked_with() 검사는 그대로 둔다. 정책은 1차 방어이고 이 트리거는
-- 경합 구간만 닫는다 — 하나로 합치면 정책이 하던 일까지 트리거가 지게 된다.
create function public.follows_guard_block()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.follow_pair_lock(new.follower_id, new.followee_id);

  if exists (
    select 1
      from public.blocks b
     where (b.blocker_id = new.follower_id and b.blocked_id = new.followee_id)
        or (b.blocker_id = new.followee_id and b.blocked_id = new.follower_id)
  ) then
    -- 방향 중립이어야 한다. 이 거부를 보는 쪽이 차단을 건 쪽이라고 가정할 수
    -- 없다 (docs/features/safety/plan-block.md 의 일반화된 규칙).
    -- 42501 로 던져 정책 거부와 같은 코드로 맞춘다.
    raise exception '지금은 팔로우할 수 없습니다' using errcode = '42501';
  end if;

  return new;
end;
$$;

create trigger follows_guard_block
  before insert on public.follows
  for each row execute function public.follows_guard_block();

-- 차단 쪽도 같은 락을 잡는다. 이것이 없으면 위 가드는 반대 순서의 경합
-- (차단이 먼저 시작하고 팔로우가 끼어드는 경우)을 막지 못한다.
create or replace function public.drop_follows_on_block()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.follow_pair_lock(new.blocker_id, new.blocked_id);

  delete from public.follows
   where (follower_id = new.blocker_id and followee_id = new.blocked_id)
      or (follower_id = new.blocked_id and followee_id = new.blocker_id);
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- 2. following_posts_with_author — 컬럼을 명시한다
-- -----------------------------------------------------------------------------
--
-- Postgres 는 뷰를 만들 때 select p.* 를 그 시점의 컬럼 목록으로 확정한다.
-- posts_with_author 에 컬럼이 하나 늘어도 이 뷰는 따라가지 않는다.
--
-- 앱은 두 뷰에 같은 컬럼 문자열을 쓴다(supabase_feed_data_source 의 _columns
-- 하나를 전체·팔로잉 양쪽에 넘긴다). 그래서 다음에 누가 posts_with_author 에
-- 컬럼을 더하고 앱의 _columns 에 반영하면 전체 피드는 멀쩡한데 팔로잉 피드만
-- PostgREST 400 이 된다. "앱은 읽는 대상만 바꾼다"는 이 뷰의 존재 이유가
-- 바로 그 시점에 깨진다.
--
-- 컬럼을 손으로 적어 두면 그 순간 마이그레이션이 실패하므로, 두 뷰를 함께
-- 고쳐야 한다는 사실이 드러난다. create or replace view 는 컬럼을 덧붙이는
-- 것만 허용하므로 목록과 순서는 지금 것을 그대로 유지한다.
create or replace view public.following_posts_with_author
with (security_invoker = on) as
select
  p.id,
  p.author_id,
  p.content,
  p.created_at,
  p.updated_at,
  p.author_nickname,
  p.author_avatar_url,
  p.images,
  p.reaction_counts,
  p.my_reaction,
  p.comment_count
from public.posts_with_author p
join public.follows f
  on f.followee_id = p.author_id
 and f.follower_id = (select auth.uid());

-- 앞선 마이그레이션의 주석은 "비로그인이면 조인이 0행을 돌려준다"고 적었는데
-- 사실이 아니다. grant 가 authenticated 뿐이라 조인에 닿기 전에 401 로 막힌다.
-- 앱은 로그인 뒤에만 이 탭에 들어가므로 동작은 그대로 두고 사실만 바로잡는다.
