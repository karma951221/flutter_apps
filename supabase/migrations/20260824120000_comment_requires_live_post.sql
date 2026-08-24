-- 삭제된 게시물에는 댓글을 달 수 없다.
--
-- 검수에서 드러난 구멍이다. post_comments_insert_own 은 "세션 사용자와 작성자가
-- 같은가"만 봤고, 게시물이 살아 있는지는 아무도 보지 않았다. 그래서 소프트
-- 삭제된 게시물에 댓글 삽입이 201 로 성공했다.
--
-- 유출은 아니다 — post_comments_visible 이 살아 있는 게시물만 조인하므로 그
-- 댓글은 어디에도 보이지 않는다. 문제는 **쓰기가 조용히 성공하는 것**이다.
-- 앱은 낙관적으로 목록에 붙이고, 새로고침하면 사라진다. 사용자에게는 댓글이
-- 증발한 것으로 보인다.
--
-- post_reactions_insert_own 은 처음부터 같은 검사를 하고 있었다(그쪽은 403 으로
-- 거부된다). 두 경로의 강도를 맞춘다.
drop policy "post_comments_insert_own" on public.post_comments;

create policy "post_comments_insert_own"
  on public.post_comments for insert to authenticated
  with check (
    (select auth.uid()) = author_id
    and exists (
      select 1 from public.posts
      where posts.id = post_comments.post_id
        and posts.deleted_at is null
    )
  );

-- 답글도 같은 정책을 탄다. enforce_comment_depth() 트리거는 부모의 삭제 여부만
-- 보고 게시물은 보지 않았는데, 이제 정책이 그 자리를 메운다.
