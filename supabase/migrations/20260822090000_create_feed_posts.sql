-- =============================================================================
-- 피드 게시물
-- =============================================================================

create table public.feed_posts (
  id         uuid        primary key default gen_random_uuid(),
  author_id  uuid        not null references public.profiles (id) on delete cascade,
  content    text        not null,
  created_at timestamptz not null default now(),

  constraint feed_posts_content_length check (
    char_length(btrim(content)) between 1 and 500
  )
);

comment on table public.feed_posts is '사용자가 작성한 공개 피드 게시물.';

create index feed_posts_created_at_idx
  on public.feed_posts (created_at desc, id desc);

create index feed_posts_author_id_created_at_idx
  on public.feed_posts (author_id, created_at desc, id desc);

alter table public.feed_posts enable row level security;

-- 피드 조회는 후속 기능에서 사용한다. 게시물은 공개 정보다.
create policy "feed_posts_select_all"
  on public.feed_posts
  for select
  to authenticated, anon
  using (true);

-- 작성자는 세션의 사용자와 항상 일치해야 한다. author_id는 DB에서 정한다.
create policy "feed_posts_insert_own"
  on public.feed_posts
  for insert
  to authenticated
  with check ((select auth.uid()) = author_id);

grant select on public.feed_posts to anon, authenticated;
grant insert (content) on public.feed_posts to authenticated;

-- author_id는 앱이 위조할 수 없도록 서버 기본값으로 채운다.
alter table public.feed_posts
  alter column author_id set default auth.uid();
