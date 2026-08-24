-- F5 감정표현. 대상별 테이블 + 같은 모양. 폴리모픽을 쓰지 않는 이유는
-- docs/features/reaction/plan.md 에 있다.

create table public.post_reactions (
  user_id    uuid        not null default auth.uid()
                         references public.profiles (id) on delete cascade,
  post_id    uuid        not null references public.posts (id) on delete cascade,
  type       text        not null,
  created_at timestamptz not null default now(),

  primary key (user_id, post_id),
  constraint post_reactions_type_valid check (type in ('like', 'dislike'))
);

create index post_reactions_post_id_type_idx
  on public.post_reactions (post_id, type);

alter table public.post_reactions enable row level security;

-- 조회: 개수는 공개 정보다.
create policy "post_reactions_select_all"
  on public.post_reactions for select to anon, authenticated
  using (true);

-- 삽입: 본인 것만, 그리고 살아 있는 게시물에만.
create policy "post_reactions_insert_own"
  on public.post_reactions for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.posts
      where posts.id = post_reactions.post_id and posts.deleted_at is null
    )
  );

-- with check 를 INSERT 와 같은 강도로 맞춘다. upsert 때문에 post_id 에도
-- UPDATE 권한을 줘야 하는데, 그러지 않으면 삭제된 게시물로 반응을 옮길 수 있다.
create policy "post_reactions_update_own"
  on public.post_reactions for update to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.posts
      where posts.id = post_reactions.post_id and posts.deleted_at is null
    )
  );

create policy "post_reactions_delete_own"
  on public.post_reactions for delete to authenticated
  using ((select auth.uid()) = user_id);

-- update 에 post_id 가 들어가는 이유: PostgREST 는 on conflict ... do update set 에
-- 페이로드의 모든 컬럼을 넣는다. {post_id, type} 을 보내면
-- set post_id = excluded.post_id, type = excluded.type 이 되므로
-- type 만 GRANT 하면 전환이 42501 로 막힌다.
grant select                 on public.post_reactions to anon, authenticated;
grant insert (post_id, type) on public.post_reactions to authenticated;
grant update (post_id, type) on public.post_reactions to authenticated;
grant delete                 on public.post_reactions to authenticated;

create table public.comment_reactions (
  user_id    uuid        not null default auth.uid()
                         references public.profiles (id) on delete cascade,
  comment_id uuid        not null references public.post_comments (id) on delete cascade,
  type       text        not null,
  created_at timestamptz not null default now(),

  primary key (user_id, comment_id),
  constraint comment_reactions_type_valid check (type in ('like', 'dislike'))
);

create index comment_reactions_comment_id_type_idx
  on public.comment_reactions (comment_id, type);

alter table public.comment_reactions enable row level security;

create policy "comment_reactions_select_all"
  on public.comment_reactions for select to anon, authenticated
  using (true);

create policy "comment_reactions_insert_own"
  on public.comment_reactions for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.post_comments
      where post_comments.id = comment_reactions.comment_id
        and post_comments.deleted_at is null
    )
  );

create policy "comment_reactions_update_own"
  on public.comment_reactions for update to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.post_comments
      where post_comments.id = comment_reactions.comment_id
        and post_comments.deleted_at is null
    )
  );

create policy "comment_reactions_delete_own"
  on public.comment_reactions for delete to authenticated
  using ((select auth.uid()) = user_id);

grant select                    on public.comment_reactions to anon, authenticated;
grant insert (comment_id, type) on public.comment_reactions to authenticated;
grant update (comment_id, type) on public.comment_reactions to authenticated;
grant delete                    on public.comment_reactions to authenticated;

-- 집계는 목록 뷰 안에서 한다. 화면마다 따로 조회하면 N+1 이고 언젠가 빠뜨린다.
-- 개수를 like_count / dislike_count 컬럼으로 박지 않고 jsonb 로 내리는 이유는
-- 감정을 하나 추가할 때 뷰를 고치지 않기 위해서다.
create or replace view public.posts_with_author
with (security_invoker = on) as
select
  p.id,
  p.author_id,
  p.content,
  p.created_at,
  p.updated_at,
  pr.nickname as author_nickname,
  pr.avatar_url as author_avatar_url,
  coalesce(images.items, '[]'::jsonb) as images,
  coalesce(reactions.counts, '{}'::jsonb) as reaction_counts,
  mine.type as my_reaction,
  coalesce(comments.total, 0) as comment_count
from public.posts p
join public.profiles pr on pr.id = p.author_id
left join lateral (
  select jsonb_agg(
    jsonb_build_object(
      'id', pi.id,
      'url', pi.url,
      'width', pi.width,
      'height', pi.height,
      'sort_order', pi.sort_order
    ) order by pi.sort_order
  ) as items
  from public.post_images pi
  where pi.post_id = p.id
) images on true
left join lateral (
  select jsonb_object_agg(grouped.type, grouped.total) as counts
  from (
    select r.type, count(*) as total
    from public.post_reactions r
    where r.post_id = p.id
    group by r.type
  ) grouped
) reactions on true
left join lateral (
  select r.type
  from public.post_reactions r
  where r.post_id = p.id and r.user_id = (select auth.uid())
) mine on true
left join lateral (
  select count(*) as total
  from public.post_comments c
  where c.post_id = p.id and c.deleted_at is null
) comments on true;

-- auth.uid() 는 JWT 클레임을 읽는 세션 GUC 기반이라 definer 뷰 안에서도
-- 조회자 기준으로 동작한다. my_reaction 이 여기 의존한다.
create or replace view public.post_comments_visible as
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
  ) as reply_count,
  coalesce(reactions.counts, '{}'::jsonb) as reaction_counts,
  mine.type as my_reaction
from public.post_comments c
join public.profiles pr on pr.id = c.author_id
join public.posts    p  on p.id = c.post_id and p.deleted_at is null
left join lateral (
  select jsonb_object_agg(grouped.type, grouped.total) as counts
  from (
    select r.type, count(*) as total
    from public.comment_reactions r
    where r.comment_id = c.id
    group by r.type
  ) grouped
) reactions on true
left join lateral (
  select r.type
  from public.comment_reactions r
  where r.comment_id = c.id and r.user_id = (select auth.uid())
) mine on true
where c.deleted_at is null
   or (
     c.parent_id is null
     and exists (
       select 1 from public.post_comments reply
       where reply.parent_id = c.id and reply.deleted_at is null
     )
   );

grant select on public.posts_with_author     to anon, authenticated;
grant select on public.post_comments_visible to anon, authenticated;
