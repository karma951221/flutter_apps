-- =============================================================================
-- 소프트 삭제된 게시물의 댓글을 테이블 경로에서도 감춘다
--
-- `post_comments_select_visible` 은 `deleted_at is null` 과 차단만 봤고, **부모
-- 게시물이 살아 있는지는 보지 않았다.** 앱은 댓글 목록을 `post_comments_visible`
-- (definer 뷰, 부모 생존을 확인한다)로 읽으므로 화면에는 드러나지 않았지만,
-- 로그인한 사용자가 PostgREST 로 `post_comments` 를 직접 조회하면 이미 삭제된
-- 게시물의 댓글 본문과 작성자를 그대로 읽을 수 있었다.
--
-- 2026-08-27 검증에서 실제 JWT 로 재현했다 — 삭제 후 뷰는 `[]`, 원본 테이블은
-- 댓글 1건. §8 주석의 "테이블 경로가 뷰보다 좁은 것은 안전하다"가 이 축에서는
-- 성립하지 않았다.
--
-- `posts` 는 **다른 테이블**이라 42P17(정책 자기참조 재귀)이 나지 않는다. 같은
-- 모양의 `exists (posts …)` 를 `post_comments_insert_own` 이 이미 쓰고 있다.
--
-- 검증한 것 (같은 날, 트랜잭션 안에서 후보 정책으로):
--   · 삭제된 게시물의 댓글 → 0건
--   · 살아 있는 게시물의 댓글 → 그대로 보인다
--   · `insert ... returning` → 동작한다 (새 행에도 SELECT 정책이 걸리는 경로)
--   · 삭제된 게시물에 댓글 삽입 → 여전히 거부(42501)
--   · `post_comments_visible` 은 definer 라 영향 없음
-- =============================================================================
drop policy "post_comments_select_visible" on public.post_comments;

create policy "post_comments_select_visible"
  on public.post_comments for select to anon, authenticated
  using (
    deleted_at is null
    and not public.is_blocked_with(author_id)
    -- 부모가 소프트 삭제되면 댓글도 함께 사라진다. 여기서 post_comments 를 다시
    -- 참조하면 42P17 이지만, posts 참조는 안전하다.
    and exists (
      select 1
        from public.posts p
       where p.id = post_comments.post_id
         and p.deleted_at is null
    )
  );
