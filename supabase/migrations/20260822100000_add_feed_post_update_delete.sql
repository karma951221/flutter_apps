-- =============================================================================
-- 피드 게시물 수정·삭제 지원
-- =============================================================================

alter table public.feed_posts
  add column updated_at timestamptz not null default now();

create trigger feed_posts_set_updated_at
  before update on public.feed_posts
  for each row execute function public.set_updated_at();

create policy "feed_posts_update_own"
  on public.feed_posts
  for update
  to authenticated
  using ((select auth.uid()) = author_id)
  with check ((select auth.uid()) = author_id);

create policy "feed_posts_delete_own"
  on public.feed_posts
  for delete
  to authenticated
  using ((select auth.uid()) = author_id);

grant update (content) on public.feed_posts to authenticated;
grant delete on public.feed_posts to authenticated;
