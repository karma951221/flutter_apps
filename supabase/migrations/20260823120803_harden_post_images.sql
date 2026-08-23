-- =============================================================================
-- 이미지 첨부 게시물 다듬기
--
-- 1. 작성을 한 트랜잭션으로 묶는 create_post_with_images() RPC
-- 2. soft_delete_post() 가 post_images 행도 함께 지우도록 교체
-- 3. post-images 버킷의 DELETE 정책 (avatars 와 동일한 모양)
-- 4. 두 버킷의 허용 MIME 확대 (iOS 는 WebP 인코딩을 못 한다)
--
-- 결과의 전체 모습은 docs/schema.md 를 본다.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. 게시물 + 이미지 원자적 작성
--
-- 앱이 posts 를 먼저 INSERT 하고 post_images 를 뒤이어 INSERT 하면, 중간에
-- 실패했을 때 이미지 없는 유령 게시물이 남는다. 재시도하면 게시물이 두 번
-- 생긴다. 두 INSERT 를 함수 하나(= 트랜잭션 하나)에 넣어 없앤다.
--
-- 이미지 바이트는 이 함수를 부르기 전에 Storage 로 먼저 올라가 있어야 한다.
-- Storage 는 트랜잭션 밖이므로, 실패 시 정리는 앱이 best-effort 로 한다.
--
-- security definer 지만 새 권한을 열지는 않는다. author_id 를 auth.uid() 로
-- 고정하므로 남의 이름으로 쓰는 경로가 없고, 길이·장수 제약은 테이블의
-- posts_content_length · post_images_sort_order_range · (post_id, sort_order)
-- 유니크가 그대로 걸린다.
-- -----------------------------------------------------------------------------
create function public.create_post_with_images(content text, images jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  author       uuid := (select auth.uid());
  new_post_id  uuid;
begin
  if author is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  insert into public.posts (author_id, content)
  values (author, create_post_with_images.content)
  returning id into new_post_id;

  insert into public.post_images (post_id, url, width, height, sort_order)
  select
    new_post_id,
    item ->> 'url',
    (item ->> 'width')::integer,
    (item ->> 'height')::integer,
    (item ->> 'sort_order')::smallint
  from jsonb_array_elements(
    coalesce(create_post_with_images.images, '[]'::jsonb)
  ) as item;

  return new_post_id;
end;
$$;

comment on function public.create_post_with_images(text, jsonb) is
  '게시물과 이미지 메타데이터를 한 트랜잭션에 만든다. 새 게시물 id 를 돌려준다.';

-- 함수는 기본적으로 PUBLIC 에 EXECUTE 가 부여된다. 먼저 회수하고 다시 준다.
revoke execute on function public.create_post_with_images(text, jsonb)
  from public, anon;
grant execute on function public.create_post_with_images(text, jsonb)
  to authenticated;

-- -----------------------------------------------------------------------------
-- 2. 소프트 삭제가 이미지 행까지 지운다
--
-- post_images 는 posts 를 on delete cascade 로 참조하지만, 소프트 삭제는 행을
-- 지우지 않으므로 cascade 가 돌지 않는다. 조회 정책이 가려줄 뿐 행은 영원히
-- 남는다. 같은 함수 안에서 지운다 — security definer 라 post_images 의 RLS 가
-- 막지 않는다.
--
-- 시그니처와 반환 의미는 그대로다.
-- -----------------------------------------------------------------------------
create or replace function public.soft_delete_post(post_id uuid)
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

  if affected > 0 then
    delete from public.post_images as pi
     where pi.post_id = soft_delete_post.post_id;
  end if;

  return affected > 0;
end;
$$;

comment on function public.soft_delete_post(uuid) is
  '본인 게시물을 소프트 삭제하고 이미지 메타데이터를 지운다. 삭제된 행이 있으면 true.';

-- -----------------------------------------------------------------------------
-- 3. post-images 객체 삭제
--
-- 게시물을 지우면 Storage 객체도 지워야 한다. avatars_delete_own 과 같은 모양으로
-- 첫 경로 조각이 본인일 때만 허용한다.
-- -----------------------------------------------------------------------------
create policy "post_images_storage_delete_own"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'post-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- -----------------------------------------------------------------------------
-- 4. 허용 MIME 확대
--
-- flutter_image_compress 는 iOS 에서 WebP 를 **인코딩하지 못한다**. WebP 만
-- 허용하면 iOS 빌드가 생기는 순간 모든 업로드가 실패한다. 두 버킷 모두
-- JPEG 을 함께 허용한다.
-- -----------------------------------------------------------------------------
update storage.buckets
   set allowed_mime_types = array['image/webp', 'image/jpeg']
 where id in ('avatars', 'post-images');
