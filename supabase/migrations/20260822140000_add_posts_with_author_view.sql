-- =============================================================================
-- 피드용 게시물 + 작성자 뷰
--
-- 피드 카드는 게시물마다 작성자 닉네임·아바타가 필요하다. 목록을 받은 뒤
-- 작성자를 한 명씩 조회하면 페이지당 N번의 왕복이 생긴다(N+1). 조인을 뷰
-- 안에 넣어 한 번에 내려준다.
--
-- 앞으로 F5 반응 수 · F6 댓글 수 · F7 차단 필터가 붙는 자리도 여기다.
-- 앱 쿼리를 화면마다 고치지 않고 이 뷰 하나만 고치기 위해서다.
-- =============================================================================

-- security_invoker = on 이 이 뷰의 핵심이다.
--
-- 이 옵션이 없으면 뷰는 **소유자(postgres) 권한**으로 실행된다. 그러면
-- posts_select_visible(deleted_at is null)을 우회해 삭제된 게시물이 피드에
-- 그대로 나오고, profiles 의 RLS 도 함께 무력화된다. schema.md 가 말하는
-- "삭제행 숨김을 DB가 강제한다"는 성질이 뷰 하나로 무너지는 지점이다.
--
-- on 으로 두면 뷰를 조회한 **세션 사용자**의 권한으로 기반 테이블 정책이
-- 그대로 평가된다. 뷰는 정책을 우회하는 통로가 아니라 조인의 이름일 뿐이다.
create view public.posts_with_author
with (security_invoker = on) as
select
  p.id,
  p.author_id,
  p.content,
  p.created_at,
  p.updated_at,
  pr.nickname   as author_nickname,
  pr.avatar_url as author_avatar_url
from public.posts p
join public.profiles pr on pr.id = p.author_id;

comment on view public.posts_with_author is
  '피드 목록용 게시물 + 작성자 프로필. security_invoker=on 이라 posts·profiles 의 RLS 가 그대로 적용된다.';

-- 뷰는 기반 테이블의 GRANT 를 물려받지 않는다. 따로 준다.
-- 조회 전용이므로 insert/update 권한은 주지 않는다. 게시물 작성·수정은
-- posts 테이블에 직접 한다 (schema.md §5).
grant select on public.posts_with_author to anon, authenticated;

-- 인덱스는 따로 만들지 않는다. 뷰는 저장된 질의라 posts_created_at_idx
-- (created_at desc, id desc) where deleted_at is null 를 그대로 탄다.
-- 플래너가 posts 를 인덱스 순으로 훑다가 LIMIT 만큼만 profiles 를 PK 로
-- 붙이므로, 커서 페이지네이션의 비용은 조인 전과 같다.
