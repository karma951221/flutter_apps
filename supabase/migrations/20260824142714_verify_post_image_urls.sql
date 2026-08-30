-- =============================================================================
-- 이미지 URL 의 소유 경계를 DB 에서 강제한다
--
-- create_post_with_images() 는 security definer 로 post_images 행을 만들면서
-- 앱이 준 url 을 그대로 저장했다. 호출자가 게시물의 작성자인지만 보고 url 이
-- 어디를 가리키는지는 보지 않았으므로, RPC 를 직접 부르면 남의 공개 이미지나
-- 임의의 외부 URL 을 자기 게시물의 이미지로 붙일 수 있었다.
--
-- Storage 정책은 **업로드**만 막는다 (첫 경로 조각 = auth.uid()). 메타데이터가
-- 가리키는 곳까지 같은 규칙으로 묶으려면 이 함수가 직접 확인해야 한다.
--
-- 시그니처·반환 의미는 그대로다. 앱이 보내던 값(post-images 공개 URL)은 그대로
-- 통과한다. 결과의 전체 모습은 docs/schema.md §7 을 본다.
-- =============================================================================
create or replace function public.create_post_with_images(content text, images jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  -- 공개 URL 의 버킷 경계. 앱의 ImageStorage.objectPathFromPublicUrl 과 같은 표식을 본다.
  marker      constant text := '/object/public/post-images/';
  author      uuid := (select auth.uid());
  new_post_id uuid;
  image_item  jsonb;
  image_url   text;
  object_path text;
begin
  if author is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  -- 행을 만들기 전에 모든 url 을 본다. 하나라도 어긋나면 게시물 자체를 만들지 않는다.
  for image_item in
    select value
      from jsonb_array_elements(
        coalesce(create_post_with_images.images, '[]'::jsonb)
      )
  loop
    image_url := image_item ->> 'url';
    if image_url is null then
      raise exception 'image url required' using errcode = '22023';
    end if;

    -- 표식이 없으면 split_part 가 빈 문자열을 준다 — 외부 URL 이거나 다른 버킷이다.
    object_path := split_part(split_part(image_url, marker, 2), '?', 1);
    if object_path = '' then
      raise exception 'image url must point to the post-images bucket'
        using errcode = '42501';
    end if;

    -- Storage 정책과 같은 규칙: 첫 경로 조각이 곧 소유자다.
    if split_part(object_path, '/', 1) <> author::text then
      raise exception 'image url must belong to the caller'
        using errcode = '42501';
    end if;

    -- `{user_id}/...` 로 끝나면 사용자 폴더 자체를 가리킨 것이다.
    if split_part(object_path, '/', 2) = '' then
      raise exception 'image url must point to an object'
        using errcode = '42501';
    end if;
  end loop;

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
  '게시물과 이미지 메타데이터를 한 트랜잭션에 만든다. url 은 호출자 소유의 post-images 객체여야 한다. 새 게시물 id 를 돌려준다.';
