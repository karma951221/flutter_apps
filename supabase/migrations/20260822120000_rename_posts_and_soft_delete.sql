-- =============================================================================
-- feed_posts → posts 이름 변경 · 소프트 삭제 · 커서 인덱스
--
-- 기획서 §7 명명 규칙에 맞춘다. 화면 이름(feed_)이 아니라 엔티티 이름을 쓰고,
-- 자식 테이블은 post_images / post_reactions / post_comments 로 이어진다.
-- 스키마 전체 모습은 docs/schema.md 를 본다.
-- =============================================================================

alter table public.feed_posts rename to posts;

comment on table public.posts is '사용자가 작성한 공개 게시물.';

-- -----------------------------------------------------------------------------
-- 딸린 객체 이름 맞추기
--
-- rename 은 테이블 이름만 바꾼다. 인덱스·제약·트리거·정책 이름은 feed_posts_ 로
-- 남으므로 직접 맞춘다. 이름이 어긋나면 다음 마이그레이션에서 대상을 찾기 어렵다.
-- -----------------------------------------------------------------------------
alter table public.posts rename constraint feed_posts_pkey to posts_pkey;
alter table public.posts
  rename constraint feed_posts_author_id_fkey to posts_author_id_fkey;
alter table public.posts
  rename constraint feed_posts_content_length to posts_content_length;

alter trigger feed_posts_set_updated_at on public.posts
  rename to posts_set_updated_at;

alter policy "feed_posts_select_all" on public.posts rename to "posts_select_visible";
alter policy "feed_posts_insert_own" on public.posts rename to "posts_insert_own";
alter policy "feed_posts_update_own" on public.posts rename to "posts_update_own";

-- -----------------------------------------------------------------------------
-- 소프트 삭제
--
-- 댓글·반응이 붙기 전에 도입한다. 행이 사라지지 않으므로 자식의 참조 무결성이
-- 깨지지 않는다.
-- -----------------------------------------------------------------------------
alter table public.posts add column deleted_at timestamptz;

comment on column public.posts.deleted_at is
  '소프트 삭제 시각. null 이면 살아있는 행이다.';

-- 조회 정책이 삭제행을 가린다.
-- 앱 쿼리마다 deleted_at 필터를 붙이는 방식은 언젠가 빠뜨리므로 DB가 강제한다.
alter policy "posts_select_visible" on public.posts
  using (deleted_at is null);

-- 하드 삭제 경로를 없앤다.
drop policy "feed_posts_delete_own" on public.posts;
revoke delete on public.posts from authenticated;

-- -----------------------------------------------------------------------------
-- 소프트 삭제는 전용 함수로만 한다
--
-- 클라이언트가 deleted_at 을 직접 UPDATE 할 수는 없다.
-- PostgreSQL 은 UPDATE 의 SELECT 정책을 **새 행에도** 적용하기 때문이다.
-- deleted_at 을 채우면 새 행이 posts_select_visible(deleted_at is null)에 걸려
-- UPDATE 자체가 42501 로 거부된다. RETURNING 유무와 무관하다.
--
-- security definer 로 RLS 를 우회하되, 함수 안에서 작성자를 직접 검증한다.
-- 이 방식은 "작성자가 자기 글의 deleted_at 을 null 로 되돌리는" 경로도 함께 막는다.
-- -----------------------------------------------------------------------------
create function public.soft_delete_post(post_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected integer;
begin
  update public.posts
     set deleted_at = now()
   where id = post_id
     and author_id = (select auth.uid())
     and deleted_at is null;

  get diagnostics affected = row_count;
  return affected > 0;
end;
$$;

comment on function public.soft_delete_post(uuid) is
  '본인 게시물을 소프트 삭제한다. 삭제된 행이 있으면 true.';

-- 함수는 기본적으로 PUBLIC 에 EXECUTE 가 부여된다. 먼저 회수하고 다시 준다.
revoke execute on function public.soft_delete_post(uuid) from public, anon;
grant execute on function public.soft_delete_post(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 커서 페이지네이션용 부분 인덱스
--
-- 조회는 항상 deleted_at is null 이므로 인덱스도 그 조건으로 좁힌다.
-- (created_at desc, id desc) 는 커서 조건
--   created_at < :c or (created_at = :c and id < :id)
-- 와 정렬을 동시에 처리한다.
-- -----------------------------------------------------------------------------
drop index public.feed_posts_created_at_idx;
drop index public.feed_posts_author_id_created_at_idx;

create index posts_created_at_idx
  on public.posts (created_at desc, id desc)
  where deleted_at is null;

create index posts_author_id_created_at_idx
  on public.posts (author_id, created_at desc, id desc)
  where deleted_at is null;
