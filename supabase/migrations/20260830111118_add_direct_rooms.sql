-- F9-DM (1:1 다이렉트 메시지). 설계 근거는 docs/features/chat/plan-dm.md 에 있다.
--
-- 새 테이블은 없다. chat_rooms 에 direct_key 를 더하고, DM 방을 만드는 유일한
-- 경로인 open_direct_room() RPC, direct 방 전용 메시지 트리거, 그리고 기존
-- 정책·트리거·뷰 세 곳의 direct 분기를 더한다.

-- =============================================================================
-- 1. chat_rooms — direct_key 와 type 별 제약
-- =============================================================================

alter table public.chat_rooms add column direct_key text;

-- 같은 두 사람의 방은 하나뿐이다. 부분 인덱스가 아니라 컬럼 unique 제약인
-- 이유: open_direct_room() 의 on conflict (direct_key) 가 성립해야 한다.
-- open 방은 null 이고 null 끼리는 충돌하지 않는다.
alter table public.chat_rooms
  add constraint chat_rooms_direct_key_unique unique (direct_key);

-- direct 방은 제목이 없다 — 화면이 상대 프로필로 표시한다.
alter table public.chat_rooms alter column title drop not null;

alter table public.chat_rooms drop constraint chat_rooms_title_len;
alter table public.chat_rooms add constraint chat_rooms_title_len check (
     (type = 'open'   and title is not null
                      and char_length(btrim(title)) between 1 and 30)
  or (type = 'direct' and title is null)
);

alter table public.chat_rooms drop constraint chat_rooms_limit_range;
alter table public.chat_rooms add constraint chat_rooms_limit_range check (
     (type = 'open'   and member_limit between 2 and 500)
  or (type = 'direct' and member_limit = 2)
);

alter table public.chat_rooms add constraint chat_rooms_direct_key_shape check (
     (type = 'open'   and direct_key is null)
  or (type = 'direct' and direct_key is not null)
);

-- =============================================================================
-- 2. open_direct_room() — DM 방이 생기는 유일한 경로
-- =============================================================================
--
-- 방 + 참여자 2행이 원자적이어야 하고, 상대 참여자 행은 클라이언트 INSERT
-- 정책(user_id = auth.uid())으로 넣을 수 없으므로 security definer 함수다.
-- chat_rooms 의 INSERT 정책은 계속 type='open' 만 허용한다.
-- 멱등이다 — 몇 번을 불러도, 양쪽 중 누가 부르더라도 같은 방 id 를 돌려준다.
create function public.open_direct_room(partner_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller           uuid := (select auth.uid());
  key              text;
  the_room_id      uuid;
  caller_nickname  text;
  partner_nickname text;
begin
  if caller is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if partner_id = caller then
    raise exception '자기 자신과는 대화할 수 없습니다' using errcode = '23514';
  end if;

  select nickname into partner_nickname
    from public.profiles where id = partner_id;
  if not found then
    -- 상대가 없는 것과 차단은 같은 문구다 — 존재 여부를 구분해 노출하지 않는다.
    raise exception '대화를 시작할 수 없습니다' using errcode = '42501';
  end if;
  if public.is_blocked_with(partner_id) then
    raise exception '대화를 시작할 수 없습니다' using errcode = '42501';
  end if;

  select nickname into caller_nickname
    from public.profiles where id = caller;

  key := least(caller, partner_id)::text || ':' || greatest(caller, partner_id)::text;

  -- 동시 호출은 unique(direct_key) 가 판정한다. 진 쪽은 do nothing 으로
  -- 빠져나와 이미 만들어진 방을 읽는다.
  insert into public.chat_rooms (type, title, member_limit, direct_key)
  values ('direct', null, 2, key)
  on conflict (direct_key) do nothing
  returning id into the_room_id;

  if the_room_id is null then
    select id into the_room_id
      from public.chat_rooms where direct_key = key;
  end if;

  -- 내 행: 없으면 만들고, 나갔던 방이면 되돌린다.
  insert into public.chat_participants (room_id, user_id, nickname)
  values (the_room_id, caller, caller_nickname)
  on conflict (room_id, user_id) do update set left_at = null;

  -- 상대 행: 없을 때만 만든다. 상대의 나가기 상태는 건드리지 않는다 —
  -- 자동 재등장은 메시지가 실제로 왔을 때(enforce_direct_message) 일어난다.
  insert into public.chat_participants (room_id, user_id, nickname)
  values (the_room_id, partner_id, partner_nickname)
  on conflict (room_id, user_id) do nothing;

  return the_room_id;
end;
$$;

comment on function public.open_direct_room(uuid) is
  'DM 방을 열거나(없으면 생성) 이미 있는 방의 id 를 돌려준다. 멱등.';

revoke execute on function public.open_direct_room(uuid) from public, anon;
grant execute on function public.open_direct_room(uuid) to authenticated;

-- =============================================================================
-- 3. enforce_direct_message() — 차단 시 전송 거부 + 카톡식 자동 재등장
-- =============================================================================
--
-- 수신 숨김은 기존 select 정책(not is_blocked_with)이 이미 한다. 1:1 에서
-- 전송만 허용하면 허공에 말하는 상황이 되므로 전송 자체를 거부한다.
-- 문구는 방향 중립이다 (enforce_comment_depth 전례, docs/schema.md §8).
create function public.enforce_direct_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  room_type text;
  partner   uuid;
begin
  -- 시스템 메시지는 direct 방에 생기지 않지만, 생겨도 이 검사 대상이 아니다.
  if new.sender_id is null then
    return new;
  end if;

  select type into room_type from public.chat_rooms where id = new.room_id;
  if room_type is distinct from 'direct' then
    return new;
  end if;

  select user_id into partner
    from public.chat_participants
   where room_id = new.room_id and user_id <> new.sender_id;

  if partner is not null and public.is_blocked_with(partner) then
    raise exception '메시지를 보낼 수 없습니다' using errcode = '42501';
  end if;

  -- 카톡식 자동 재등장: 나간 상대에게 메시지가 오면 상대 목록에 방이
  -- 되살아난다. 이 UPDATE 는 기존 트리거 둘을 다시 지나지만, 정원 검사는
  -- 2인 방에서 항상 통과하고 시스템 메시지는 아래 4번의 direct 억제
  -- 분기에 걸려 나오지 않는다.
  update public.chat_participants
     set left_at = null
   where room_id = new.room_id
     and user_id = partner
     and left_at is not null;

  return new;
end;
$$;

create trigger chat_messages_enforce_direct
  before insert on public.chat_messages
  for each row execute function public.enforce_direct_message();

-- =============================================================================
-- 4. 기존 객체 수정 셋
-- =============================================================================

-- 4-1. direct 방에는 입퇴장 시스템 메시지를 내지 않는다. 1:1 에서 입퇴장
-- 문구는 어색하고, '나갔습니다'는 나가기 사실을 상대에게 노출한다.
-- 아래는 20260828101500_add_chat.sql 의 함수에 direct 이른 반환 하나만 더한
-- 것이다 — 나머지는 그대로다.
create or replace function public.emit_membership_system_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  event text;
begin
  if exists (
    select 1 from public.chat_rooms r
     where r.id = new.room_id and r.type = 'direct'
  ) then
    return null;
  end if;

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

-- 4-2. 멤버는 자기 direct 방을 볼 수 있어야 한다. anon 은 direct 분기가
-- 항상 false 라 기존과 동일하게 동작한다. open_chat_rooms 뷰는 이미
-- type='open' 으로 좁혀져 있어 손대지 않는다 — DM 은 탐색에 노출되지 않는다.
drop policy "chat_rooms_select_open" on public.chat_rooms;
create policy "chat_rooms_select_visible"
  on public.chat_rooms for select to anon, authenticated
  using (
    deleted_at is null
    and (type = 'open' or (type = 'direct' and public.is_room_member(id)))
  );

-- 4-3. my_chat_rooms 에 상대 프로필 컬럼 셋을 덧붙인다 (direct 가 아니면 null).
-- 상대 참여자 행은 내가 멤버인 방이므로 is_room_member 정책으로 읽힌다 —
-- 상대가 나간 뒤에도 표시가 유지된다.
--
-- create or replace view 는 명시하지 않은 reloption 을 리셋하므로
-- security_invoker = on 을 반드시 다시 명시한다 (docs/schema.md §9 의 함정).
create or replace view public.my_chat_rooms
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
  ) as unread_count,
  partner.user_id            as partner_id,
  partner_profile.nickname   as partner_nickname,
  partner_profile.avatar_url as partner_avatar_url
from public.chat_participants p
join public.chat_rooms r on r.id = p.room_id and r.deleted_at is null
left join lateral (
  select m.created_at, m.type, m.content, m.system_event
    from public.chat_messages m
   where m.room_id = r.id and m.deleted_at is null
   order by m.created_at desc, m.id desc
   limit 1
) last_message on true
left join lateral (
  select cp.user_id
    from public.chat_participants cp
   where cp.room_id = r.id and cp.user_id <> (select auth.uid())
   limit 1
) partner on r.type = 'direct'
left join public.profiles partner_profile on partner_profile.id = partner.user_id
where p.user_id = (select auth.uid())
  and p.left_at is null;
