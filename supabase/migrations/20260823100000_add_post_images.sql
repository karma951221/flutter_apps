-- F3 이미지 첨부. Storage 객체는 작성자/{post}/{순서}.webp 경로만 허용한다.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('post-images', 'post-images', true, 5242880, array['image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create table public.post_images (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.posts (id) on delete cascade,
  url        text not null,
  width      integer not null,
  height     integer not null,
  sort_order smallint not null,

  constraint post_images_width_positive check (width > 0),
  constraint post_images_height_positive check (height > 0),
  constraint post_images_sort_order_range check (sort_order between 0 and 4),
  constraint post_images_post_id_sort_order_key unique (post_id, sort_order)
);

create index post_images_post_id_sort_order_idx
  on public.post_images (post_id, sort_order);

alter table public.post_images enable row level security;

create policy "post_images_select_visible"
  on public.post_images for select to anon, authenticated
  using (
    exists (
      select 1 from public.posts
      where posts.id = post_images.post_id and posts.deleted_at is null
    )
  );

create policy "post_images_insert_own"
  on public.post_images for insert to authenticated
  with check (
    exists (
      select 1 from public.posts
      where posts.id = post_images.post_id
        and posts.author_id = (select auth.uid())
        and posts.deleted_at is null
    )
  );

create policy "post_images_update_own"
  on public.post_images for update to authenticated
  using (
    exists (
      select 1 from public.posts
      where posts.id = post_images.post_id and posts.author_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.posts
      where posts.id = post_images.post_id
        and posts.author_id = (select auth.uid())
        and posts.deleted_at is null
    )
  );

grant select on public.post_images to anon, authenticated;
grant insert (post_id, url, width, height, sort_order) on public.post_images to authenticated;
grant update (url, width, height, sort_order) on public.post_images to authenticated;

create policy "post_images_storage_insert_own"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'post-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "post_images_storage_update_own"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'post-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'post-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- 공개 버킷 URL은 CDN에서 읽히지만, SDK 목록/다운로드도 같은 공개 범위로 둔다.
create policy "post_images_storage_select_public"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'post-images');

-- 피드에 이미지 메타데이터를 한 번에 내려준다. security_invoker 유지가 필수다.
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
  coalesce(images.items, '[]'::jsonb) as images
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
) images on true;
