-- =============================================================================
-- pawlog W5 social 후속 — 공유한 산책을 고치면 공유 글도 고친다(update_walk_post)
--
-- 앱에서 산책의 메모 · 반려견을 고치면 이미 공유한 글에도 반영한다. 다시 공유
-- (publish_walk_post)는 created_at 을 now() 로 올려 글이 목록 맨 위로 튀므로,
-- 내용만 바꾸고 created_at 은 그대로 두는 RPC 를 따로 둔다.
--
-- 결과의 전체 모습은 apps/trader/docs/schema.md §18 을 본다.
-- =============================================================================

-- 내 공유 글(공유 중인 것만)의 반려견 · 메모 · 경로 미리보기를 바꾼다.
-- 바뀐 행이 있으면 true. 공유한 적 없거나, 공유 취소했거나, 남의 것이면 false —
-- 공유 취소한 글을 되살리지 않는다(되살리기는 publish_walk_post 만 한다).
--
-- security definer 다 — walk_posts 의 update 는 어떤 role 에도 주지 않았다.
-- unpublish_walk_post 와 같은 모양으로 where 의 author_id = auth.uid() 가 권한 경계다.
-- 입력 검사는 publish_walk_post 와 같다: 경로 원소 모양은 여기서, 개수 · 크기 ·
-- 반려견 이름 · 메모 길이는 테이블 CHECK 가 막는다.
create function public.update_walk_post(
  p_local_walk_id uuid,
  p_dog_names     text[],
  p_memo          text,
  p_route_preview jsonb
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid    uuid := (select auth.uid());
  affected integer;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  -- publish_walk_post 와 같은 검사 — null 이거나 {lat, lng} 숫자 객체의 배열.
  if p_route_preview is not null and (
       jsonb_typeof(p_route_preview) <> 'array'
       or exists (
         select 1
           from jsonb_array_elements(p_route_preview) as e
          where jsonb_typeof(e) <> 'object'
             or jsonb_typeof(e -> 'lat') is distinct from 'number'
             or jsonb_typeof(e -> 'lng') is distinct from 'number'
       )
     ) then
    raise exception 'invalid route_preview' using errcode = '22023';
  end if;

  update public.walk_posts
     set dog_names     = p_dog_names,
         memo          = p_memo,
         route_preview = p_route_preview
   where local_walk_id = p_local_walk_id
     and author_id = v_uid
     and deleted_at is null;

  get diagnostics affected = row_count;
  return affected > 0;
end;
$$;

comment on function public.update_walk_post(uuid, text[], text, jsonb) is
  '내 공유 산책의 반려견 · 메모 · 경로를 고친다. created_at 은 그대로. 공유 중인 내 글이 바뀌면 true, 아니면 false.';

revoke execute on function public.update_walk_post(uuid, text[], text, jsonb) from public, anon;
grant execute on function public.update_walk_post(uuid, text[], text, jsonb) to authenticated;
