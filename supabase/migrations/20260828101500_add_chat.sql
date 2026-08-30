-- F9 채팅 (오픈 그룹방). 설계 근거는 docs/features/chat/plan.md 에 있다.
--
-- 새 테이블 셋(chat_rooms · chat_participants · chat_messages), 멤버 판정 함수,
-- 시스템 메시지·정원·이미지 경로 트리거, 뷰 둘, 비공개 Storage 버킷,
-- 그리고 기존 reports 트리거에 'chat_message' 분기를 더한다.
--
-- 실시간 전달은 Postgres Changes 다. 마지막의 publication 한 줄이 빠지면 구독이
-- 조용히 아무것도 받지 않는다.

-- =============================================================================
-- 1. 테이블
-- =============================================================================

create table public.chat_rooms (
  id           uuid        primary key default gen_random_uuid(),
  -- 'direct' 는 v1 에서 만들지 않는다. DM 을 붙일 때 마이그레이션 하나로
  -- 끝내려고 컬럼만 미리 둔다 (계획서 "DM 확장").
  type         text        not null default 'open',
  title        text        not null,
  description  text,
  -- 개설자가 탈퇴해도 방은 남는다. cascade 로 두면 남은 사람들의 대화가
  -- 통째로 사라진다.
  created_by   uuid        references public.profiles (id) on delete set null,
  member_limit int         not null default 100,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz,

  constraint chat_rooms_type_valid  check (type in ('open', 'direct')),
  constraint chat_rooms_title_len   check (char_length(btrim(title)) between 1 and 30),
  constraint chat_rooms_desc_len    check (
    description is null or char_length(description) <= 200
  ),
  constraint chat_rooms_limit_range check (member_limit between 2 and 500)
);

-- 나가기는 행 삭제가 아니라 left_at 이다. 참여자 행을 지우면 그 사람이 남긴
-- 메시지가 이름을 잃는다.
create table public.chat_participants (
  room_id      uuid        not null references public.chat_rooms (id) on delete cascade,
  user_id      uuid        not null default auth.uid()
                           references public.profiles (id) on delete cascade,
  nickname     text        not null,
  joined_at    timestamptz not null default now(),
  last_read_at timestamptz not null default now(),
  left_at      timestamptz,

  primary key (room_id, user_id),
  constraint chat_participants_nickname_len check (
    char_length(btrim(nickname)) between 2 and 20
  )
);

-- image_path 는 계획서의 image_url 에서 이름을 바꿨다. chat-images 는 비공개
-- 버킷이라 공개 URL 이 존재하지 않는다 — 저장하는 값은 버킷 안의 객체 경로이고,
-- 화면에 띄울 때 서명 URL 을 만든다. url 이라는 이름으로 경로를 담으면
-- post_images.url(진짜 공개 URL)과 같은 이름이 서로 다른 것을 가리키게 된다.
create table public.chat_messages (
  id           uuid        primary key default gen_random_uuid(),
  room_id      uuid        not null references public.chat_rooms (id) on delete cascade,
  -- default 가 있어야 한다. sender_id 는 INSERT GRANT 에서 빠져 있으므로 앱이
  -- 값을 넣을 수 없고, 기본값이 없으면 null 로 들어가 삽입 정책
  -- (sender_id = auth.uid()) 이 언제나 실패한다.
  -- 시스템 메시지를 만드는 트리거는 null 을 명시해 이 기본값을 덮는다.
  sender_id    uuid        default auth.uid()
                           references public.profiles (id) on delete cascade,
  type         text        not null default 'text',
  content      text,
  image_path   text,
  system_event text,
  created_at   timestamptz not null default now(),
  deleted_at   timestamptz,

  constraint chat_messages_type_valid check (type in ('text', 'image', 'system')),
  -- 타입마다 채워져야 하는 칸이 다르다. 세 갈래를 한 제약으로 묶어 두면
  -- 'image' 인데 content 가 들어오는 식의 어긋난 행이 아예 생기지 않는다.
  constraint chat_messages_shape check (
       (type = 'text'   and sender_id is not null and content is not null
                        and char_length(btrim(content)) between 1 and 1000
                        and image_path is null and system_event is null)
    or (type = 'image'  and sender_id is not null and image_path is not null
                        and content is null and system_event is null)
    or (type = 'system' and sender_id is null and system_event in ('join', 'leave')
                        and content is not null and image_path is null)
  )
);

-- =============================================================================
-- 2. 인덱스
-- =============================================================================

create index chat_messages_room_created_idx
  on public.chat_messages (room_id, created_at desc, id desc)
  where deleted_at is null;

create index chat_participants_user_idx
  on public.chat_participants (user_id)
  where left_at is null;

create index chat_rooms_open_activity_idx
  on public.chat_rooms (created_at desc, id desc)
  where deleted_at is null and type = 'open';

-- =============================================================================
-- 3. 멤버 판정 함수
-- =============================================================================
--
-- 정책 안에서 chat_participants 를 직접 서브쿼리하면 chat_participants 자신의
-- 정책이 다시 평가되어 무한 재귀(42P17)가 난다. is_blocked_with() 와 같은
-- 모양으로 security definer 함수에 가둔다.
--
-- EXECUTE 를 회수하지 않는다. chat_rooms 의 조회 정책이 anon 에게도 평가되고,
-- 정책 안에서 이 함수를 부르므로 anon 의 실행 권한이 없으면 조회 자체가
-- 실패한다 (docs/schema.md §3 의 경고와 같은 함정).
create function public.is_room_member(room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.chat_participants p
     where p.room_id = is_room_member.room_id
       and p.user_id = (select auth.uid())
       and p.left_at is null
  );
$$;

comment on function public.is_room_member(uuid) is
  '로그인 사용자가 이 방에 참여 중(나가지 않은 상태)인지. 채팅 RLS 의 단일 기준.';

-- =============================================================================
-- 4. 트리거
-- =============================================================================

-- 정원 검사. 삽입(첫 입장)과 재입장(left_at → null) 둘 다 본다.
create function public.enforce_room_capacity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_count integer;
  limit_count   integer;
begin
  -- 나가는 중이거나 이미 참여 중인 행의 다른 컬럼만 바뀌는 update 는 통과시킨다.
  if tg_op = 'UPDATE' and not (old.left_at is not null and new.left_at is null) then
    return new;
  end if;
  if new.left_at is not null then
    return new;
  end if;

  select member_limit into limit_count
    from public.chat_rooms
   where id = new.room_id and deleted_at is null;

  if not found then
    raise exception '없는 방입니다' using errcode = '23503';
  end if;

  select count(*) into current_count
    from public.chat_participants
   where room_id = new.room_id
     and left_at is null
     and user_id <> new.user_id;

  if current_count >= limit_count then
    raise exception '정원이 가득 찬 방입니다' using errcode = '23514';
  end if;

  return new;
end;
$$;

create trigger chat_participants_enforce_capacity
  before insert or update on public.chat_participants
  for each row execute function public.enforce_room_capacity();

-- 입장·퇴장 시스템 메시지.
--
-- 문구가 아니라 키('join' · 'leave')를 저장한다. 문장은 앱의 ARB 가 만든다 —
-- DB 에 한국어를 넣으면 다국어 이행에 갚을 빚을 하나 더 만든다.
-- content 에는 그 시점의 닉네임을 스냅샷으로 남긴다. 나중에 닉네임을 바꿔도
-- 지난 시스템 메시지의 이름은 그대로여야 한다.
create function public.emit_membership_system_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  event text;
begin
  if tg_op = 'INSERT' then
    event := case when new.left_at is null then 'join' end;
  elsif old.left_at is null and new.left_at is not null then
    event := 'leave';
  elsif old.left_at is not null and new.left_at is null then
    event := 'join';
  end if;

  if event is null then
    return null;
  end if;

  insert into public.chat_messages (room_id, sender_id, type, content, system_event)
  values (new.room_id, null, 'system', new.nickname, event);

  return null;
end;
$$;

create trigger chat_participants_emit_system_message
  after insert or update on public.chat_participants
  for each row execute function public.emit_membership_system_message();

-- 이미지 경로 위조 방지.
--
-- Storage 정책은 업로드만 막는다. 메시지 행이 가리키는 경로까지 같은 규칙으로
-- 묶으려면 여기서 봐야 한다 — 2026-08-24 리뷰가 게시물에 넣은
-- verify_post_image_urls 와 같은 이유다.
create function public.verify_chat_image_path()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.type <> 'image' then
    return new;
  end if;

  -- {room_id}/{user_id}/{객체 이름} 세 조각이어야 한다.
  if split_part(new.image_path, '/', 1) <> new.room_id::text then
    raise exception 'image path must start with the room id' using errcode = '42501';
  end if;
  if split_part(new.image_path, '/', 2) <> new.sender_id::text then
    raise exception 'image path must belong to the sender' using errcode = '42501';
  end if;
  if split_part(new.image_path, '/', 3) = '' then
    raise exception 'image path must point to an object' using errcode = '42501';
  end if;

  return new;
end;
$$;

create trigger chat_messages_verify_image_path
  before insert on public.chat_messages
  for each row execute function public.verify_chat_image_path();

-- =============================================================================
-- 5. 메시지 소프트 삭제
-- =============================================================================
--
-- 조회 정책이 삭제된 행을 가리므로 UPDATE ... RETURNING 이 42501 로 막힌다.
-- 게시물·댓글과 같은 방식으로 함수를 통해서만 지운다.
create function public.soft_delete_chat_message(message_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected integer;
begin
  update public.chat_messages
     set deleted_at = now()
   where id = message_id
     and sender_id = (select auth.uid())
     and deleted_at is null;

  get diagnostics affected = row_count;
  return affected > 0;
end;
$$;

comment on function public.soft_delete_chat_message(uuid) is
  '본인이 보낸 메시지를 소프트 삭제한다. 삭제된 행이 있으면 true.';

revoke execute on function public.soft_delete_chat_message(uuid) from public, anon;
grant execute on function public.soft_delete_chat_message(uuid) to authenticated;

-- =============================================================================
-- 6. RLS
-- =============================================================================

alter table public.chat_rooms        enable row level security;
alter table public.chat_participants enable row level security;
alter table public.chat_messages     enable row level security;

-- 방: 살아 있는 공개방은 누구나 본다(탐색 화면). 수정 정책은 v1 에 두지 않는다.
create policy "chat_rooms_select_open"
  on public.chat_rooms for select to anon, authenticated
  using (type = 'open' and deleted_at is null);

create policy "chat_rooms_insert_open"
  on public.chat_rooms for insert to authenticated
  with check (type = 'open' and (select auth.uid()) is not null);

-- 참여자 조회에 `user_id = auth.uid()` 를 or 로 붙이는 이유:
-- 나간 뒤에는 is_room_member 가 false 라 자기 행조차 못 읽는다. 그러면 앱이
-- "처음 들어가는 방"과 "다시 들어가는 방"을 구분할 수 없어 upsert 가 성립하지
-- 않는다.
create policy "chat_participants_select_member_or_self"
  on public.chat_participants for select to authenticated
  using (
    public.is_room_member(room_id) or user_id = (select auth.uid())
  );

create policy "chat_participants_insert_self"
  on public.chat_participants for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.chat_rooms r
       where r.id = room_id and r.type = 'open' and r.deleted_at is null
    )
  );

-- 재입장·닉네임 변경·읽음 갱신·나가기가 모두 여기를 지난다.
-- is_room_member 를 보지 않는다 — 나간 사람이 다시 들어오려면 자기 행을
-- 고칠 수 있어야 한다.
create policy "chat_participants_update_self"
  on public.chat_participants for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- 메시지 조회. 차단은 여기 한 줄로 끝난다 — Postgres Changes 가 구독자마다
-- 이 정책을 다시 평가하므로 히스토리에서도 실시간에서도 오지 않는다.
-- 시스템 메시지는 sender_id 가 null 이고 is_blocked_with(null) 은 false 라
-- 그대로 통과한다.
create policy "chat_messages_select_member"
  on public.chat_messages for select to authenticated
  using (
    deleted_at is null
    and public.is_room_member(room_id)
    and not public.is_blocked_with(sender_id)
  );

-- 시스템 메시지는 트리거(security definer)만 만든다. 앱은 text · image 만 보낸다.
create policy "chat_messages_insert_member"
  on public.chat_messages for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and type in ('text', 'image')
    and public.is_room_member(room_id)
  );

-- =============================================================================
-- 7. GRANT
-- =============================================================================
--
-- 위조를 막는 방법은 컬럼 단위 INSERT 다. created_by · user_id · sender_id 는
-- default auth.uid() 가 채우므로 넣을 권한을 주지 않는다.
-- DELETE 는 어디에도 주지 않는다.

grant select on public.chat_rooms to anon, authenticated;
grant insert (type, title, description, member_limit)
  on public.chat_rooms to authenticated;

grant select on public.chat_participants to authenticated;
grant insert (room_id, nickname) on public.chat_participants to authenticated;
grant update (nickname, last_read_at, left_at) on public.chat_participants to authenticated;

grant select on public.chat_messages to authenticated;
grant insert (id, room_id, type, content, image_path) on public.chat_messages to authenticated;

-- id 에 INSERT 를 주는 것은 의도다. 앱이 메시지 uuid 를 먼저 만들어 낙관적
-- 버블을 띄우고, 실시간으로 되돌아온 자기 메시지를 그 id 로 중복 제거한다
-- (계획서 "낙관적 전송"). PK 가 위조를 막는다 — 남의 id 를 쓰면 충돌한다.

-- created_by 는 컬럼 기본값으로 채운다. INSERT GRANT 에서 빠져 있으므로
-- 호출자가 다른 사람을 개설자로 적을 수 없다.
alter table public.chat_rooms alter column created_by set default auth.uid();

-- =============================================================================
-- 8. 뷰 둘
-- =============================================================================

-- 내가 참여 중인 방 목록. security_invoker = on 이라 내 참여자 행 · 내가 볼 수
-- 있는 메시지만 집계에 들어간다 — 차단한 상대의 메시지는 안읽음 수에서도
-- 자동으로 빠진다.
create view public.my_chat_rooms
with (security_invoker = on) as
select
  r.id,
  r.title,
  r.description,
  r.type,
  r.created_at,
  p.nickname       as my_nickname,
  p.last_read_at,
  p.joined_at,
  (
    select count(*)
      from public.chat_participants member
     where member.room_id = r.id and member.left_at is null
  ) as member_count,
  last_message.created_at    as last_message_at,
  last_message.type          as last_message_type,
  last_message.content       as last_message_content,
  last_message.system_event  as last_message_system_event,
  (
    select count(*)
      from public.chat_messages unread
     where unread.room_id = r.id
       and unread.deleted_at is null
       and unread.created_at > p.last_read_at
       and unread.sender_id is distinct from (select auth.uid())
  ) as unread_count
from public.chat_participants p
join public.chat_rooms r on r.id = p.room_id and r.deleted_at is null
left join lateral (
  select m.created_at, m.type, m.content, m.system_event
    from public.chat_messages m
   where m.room_id = r.id and m.deleted_at is null
   order by m.created_at desc, m.id desc
   limit 1
) last_message on true
where p.user_id = (select auth.uid())
  and p.left_at is null;

grant select on public.my_chat_rooms to authenticated;

-- 탐색용 공개방 목록.
--
-- security_invoker = off 는 이 스키마의 두 번째 예외다. 탐색 화면은 아직
-- 참여하지 않은 사람이 보는데, 참여자 수를 세려면 chat_participants 를 읽어야
-- 하고 그 정책은 is_room_member 다 — 호출자 권한으로는 모든 방이 0명으로 보인다.
-- 내보내는 것은 집계 수 하나뿐이고 참여자 신원은 나가지 않는다.
-- (첫 예외는 post_comments_visible, docs/schema.md §9)
--
-- 정책이 평가되지 않으므로 where 로 직접 좁힌다. 이 줄이 빠지면 삭제된 방과
-- 나중에 붙을 DM 방까지 탐색에 노출된다.
create view public.open_chat_rooms as
select
  r.id,
  r.title,
  r.description,
  r.created_at,
  (
    select count(*)
      from public.chat_participants member
     where member.room_id = r.id and member.left_at is null
  ) as member_count,
  (
    select max(m.created_at)
      from public.chat_messages m
     where m.room_id = r.id and m.deleted_at is null
  ) as last_message_at
from public.chat_rooms r
where r.deleted_at is null and r.type = 'open';

grant select on public.open_chat_rooms to anon, authenticated;

-- =============================================================================
-- 9. 신고 대상 확장
-- =============================================================================
--
-- 폴리모픽 reports 에 분기 하나만 더한다. 테이블을 새로 만들지 않는다.
alter table public.reports drop constraint reports_target_type_valid;
alter table public.reports add constraint reports_target_type_valid check (
  target_type in ('post', 'comment', 'user', 'chat_message')
);

create or replace function public.enforce_report_target()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_author uuid;
begin
  if new.target_type = 'post' then
    select author_id into target_author
      from public.posts
     where id = new.target_id and deleted_at is null;
    if not found then
      raise exception '신고할 대상이 없습니다';
    end if;
    if target_author = new.reporter_id then
      raise exception '내 게시물은 신고할 수 없습니다';
    end if;

  elsif new.target_type = 'comment' then
    select author_id into target_author
      from public.post_comments
     where id = new.target_id and deleted_at is null;
    if not found then
      raise exception '신고할 대상이 없습니다';
    end if;
    if target_author = new.reporter_id then
      raise exception '내 댓글은 신고할 수 없습니다';
    end if;

  elsif new.target_type = 'chat_message' then
    select sender_id into target_author
      from public.chat_messages
     where id = new.target_id and deleted_at is null;
    if not found then
      raise exception '신고할 대상이 없습니다';
    end if;
    -- 시스템 메시지(sender_id is null)는 신고 대상이 아니다.
    if target_author is null then
      raise exception '신고할 대상이 없습니다';
    end if;
    if target_author = new.reporter_id then
      raise exception '내 메시지는 신고할 수 없습니다';
    end if;

  elsif new.target_type = 'user' then
    perform 1 from public.profiles where id = new.target_id;
    if not found then
      raise exception '신고할 대상이 없습니다';
    end if;
  end if;

  return new;
end;
$$;

-- =============================================================================
-- 10. Storage `chat-images`
-- =============================================================================
--
-- 비공개 버킷이다. 읽기 권한이 방 단위라 경로의 첫 조각이 room_id 여야
-- 정책이 is_room_member 로 판정할 수 있다 — post-images 의 {user_id}/... 와
-- 순서가 다른 이유가 이것이다.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('chat-images', 'chat-images', false, 5242880, array['image/webp', 'image/jpeg'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy "chat_images_select_member"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'chat-images'
    and public.is_room_member(((storage.foldername(name))[1])::uuid)
  );

create policy "chat_images_insert_member_own"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'chat-images'
    and public.is_room_member(((storage.foldername(name))[1])::uuid)
    and (storage.foldername(name))[2] = (select auth.uid())::text
  );

-- UPDATE · DELETE 정책은 두지 않는다. 보낸 메시지의 사진은 바뀌지 않고,
-- 메시지 소프트 삭제는 객체를 지우지 않는다(방에 남은 인용이 깨지지 않도록).

-- =============================================================================
-- 11. 실시간 발행
-- =============================================================================
--
-- 이 줄이 빠지면 구독이 조용히 아무것도 받지 않는다. 오류도 나지 않는다.
alter publication supabase_realtime add table public.chat_messages;
