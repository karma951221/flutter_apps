# F9 chat — 계획 (오픈채팅 · 스키마 · 권한 · 화면)

> [트레이더 허브](../../README.md) · [기획](../../overview.md) · [스키마](../../schema.md) · [아키텍처](../../../../../docs/architecture.md)

> 상태: **완료** · 작성 2026-08-28 · 구현 2026-08-28 ([구현 기록](history.md))
> 진행 상태의 단일 기준은 [진행 현황](../../status.md)이다.

## 범위

**오픈 카카오톡 채팅방**을 만든다. 누구나 방을 개설하고, 방 목록에서 아무나 입장하며,
방 안에서는 그 방에서만 쓰는 닉네임으로 대화한다.

v1에 들어가는 것:

- 공개방 개설 · 탐색 · 입장 · 나가기
- 방별 닉네임
- 실시간 텍스트 메시지 · 사진 전송
- 안읽음 수와 방 목록 배지
- 신고 · 차단 연동 (기존 F7 재사용)
- 입장 · 퇴장 시스템 메시지

v1에 넣지 않지만 **자리는 남기는 것**: 1:1 DM. 방 테이블의 `type` 컬럼과 참여자 모델을
처음부터 공용으로 잡아, DM은 마이그레이션 하나와 화면 몇 개로 붙는다.

기획서에는 채팅이 "1:1 채팅 · DM"으로 4단계(v1.1)에 한 줄 적혀 있다
([기획 §8](../../overview.md)). 이 문서는 그 자리를 **공개 그룹방 먼저, DM은 나중**으로
바꿔 채운다.

## 확정한 결정과 근거

| 항목 | 결정 | 근거 |
|---|---|---|
| 방 모델 | **공개 오픈방만** (v1) | 오픈카톡의 정의가 "아무나 개설하고 아무나 들어오는 공개 방"이다. DM을 같이 하면 참여자 모델·목록 화면·알림 규칙이 두 갈래가 되어 범위가 1.7배가 된다 |
| DM 확장 | `chat_rooms.type` (`'open'` \| `'direct'`) 을 **처음부터** 둔다 | 나중에 `type='direct'` 와 `direct_key`(정렬한 두 uuid, unique) 하나만 더하면 된다. 참여자·메시지 테이블은 손대지 않는다 |
| 정체성 | **방별 닉네임** (`chat_participants.nickname`) | "익명으로 부담 없이"가 오픈방의 질감이다. 참여자 테이블에 컬럼 둘이면 끝난다. 기본값은 내 프로필 닉네임 |
| 신고·차단 | **실제 계정 기준** | 닉네임이 방별이어도 제재는 계정에 붙어야 의미가 있다. 기존 `blocks` · `reports` 를 그대로 쓴다 |
| 실시간 전달 | **Postgres Changes 구독** (A안) | 쓰기 경로가 하나뿐이라 이중 쓰기·순서 꼬임·중복 제거 문제가 없고, **권한을 테이블 RLS 한 곳이 계속 판단**한다. Broadcast(B안)는 구독자별 RLS 재검사가 없어 잘 늘지만, 권한이 `realtime.messages` 로 새어나가 이 저장소의 원칙이 깨진다. 이 규모에서 A가 막힐 일은 없다 |
| 실시간 교체 여지 | repository 인터페이스는 `Stream<ChatMessage>` 만 노출 | B안으로 옮길 때 **datasource 한 파일만** 바뀐다 (규칙 ①) |
| 나가기 | **행 삭제가 아니라 `left_at`** | 나간 사람의 메시지는 방에 남는다. 참여자 행을 지우면 그 메시지들이 이름을 잃는다. 소프트 삭제 규칙("자식이 생길 수 있는 테이블")과도 맞는다 |
| 개설자 | `created_by` nullable · `on delete set null` | 개설자가 탈퇴해도 방은 남아야 한다. `delete_account()` cascade 에 방이 딸려 사라지면 남은 사람들의 대화가 통째로 증발한다 |
| 시스템 메시지 | 문구가 아니라 **`system_event` 키** 로 저장 | 다국어 이행 중이고 "DB 트리거 문구 → 코드 매핑"이 이미 남은 일로 잡혀 있다([진행 현황](../../status.md)). DB에 한국어를 넣으면 그 빚을 하나 더 만든다. 문장은 앱의 ARB가 만든다 |
| 멤버 판정 | **`is_room_member(room_id)` security definer 함수** | 정책 안에서 `chat_participants` 를 서브쿼리하면 42P17 이 난다([스키마 §11](../../schema.md)). 기존 `is_blocked_with()` 와 같은 모양으로 푼다 |
| 메시지 목록 조인 | **뷰를 만들지 않는다.** cubit 이 참여자 맵을 들고 이름을 붙인다 | 실시간 페이로드는 조인이 안 된 생 행이다. 히스토리만 뷰로 읽으면 두 경로의 모양이 달라져 렌더링이 두 벌 생긴다. 정원이 100이라 입장 시 한 번에 읽힌다 |
| 메시지 id | **앱이 먼저 만든다** (`core/id/id_generator.dart`) | 낙관적 버블을 즉시 띄우고, 실시간으로 되돌아온 내 메시지를 이 id로 중복 제거한다 |
| 이미지 경로 | `chat-images/{room_id}/{user_id}/{uuid}` | 읽기 권한이 **방 단위**라 room_id 가 첫 칸이어야 Storage 정책이 `is_room_member` 로 판정한다. `post-images` 의 `{user_id}/...` 와 순서가 다른 이유가 이것이다 |
| 방 화면 | **Bloc** | 전송·수신·위로 더 읽기·읽음 처리·재전송으로 이벤트가 여럿이다([아키텍처 §4](../../../../../docs/architecture.md)). 목록·탐색·개설은 Cubit |
| 진입점 | **하단 탭 추가** (홈 · 채팅 · 프로필 · 설정) | 안읽음 배지를 달 자리가 생기고, `IndexedStack` 이라 방 목록 스크롤이 유지된다. 나중에 DM을 같은 목록에 섞기도 자연스럽다 |
| 문구 | **처음부터 ARB** | 지금 나머지 화면의 한국어를 걷어내는 중이다. 새 화면이 하드코딩하면 그 빚을 늘린다 |

## 데이터 · 권한

확정된 스키마의 단일 기준은 [스키마 문서](../../schema.md)다. 아래는 마이그레이션에 담을
의도이며, 적용 후 스키마 문서를 같은 커밋에서 갱신한다.

### 테이블

```sql
create table public.chat_rooms (
  id           uuid        primary key default gen_random_uuid(),
  type         text        not null default 'open',
  title        text        not null,
  description  text,
  created_by   uuid        references public.profiles (id) on delete set null,
  member_limit int         not null default 100,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz,

  constraint chat_rooms_type_valid   check (type in ('open', 'direct')),
  constraint chat_rooms_title_len    check (char_length(title) between 1 and 30),
  constraint chat_rooms_desc_len     check (description is null or char_length(description) <= 200),
  constraint chat_rooms_limit_range  check (member_limit between 2 and 500)
);

create table public.chat_participants (
  room_id      uuid        not null references public.chat_rooms (id) on delete cascade,
  user_id      uuid        not null default auth.uid()
                           references public.profiles (id) on delete cascade,
  nickname     text        not null,
  joined_at    timestamptz not null default now(),
  last_read_at timestamptz not null default now(),
  left_at      timestamptz,

  primary key (room_id, user_id),
  constraint chat_participants_nickname_len check (char_length(nickname) between 2 and 20)
);

create table public.chat_messages (
  id           uuid        primary key default gen_random_uuid(),  -- 앱이 덮어쓴다
  room_id      uuid        not null references public.chat_rooms (id) on delete cascade,
  sender_id    uuid        references public.profiles (id) on delete cascade,
  type         text        not null default 'text',
  content      text,
  image_path   text,   -- 비공개 버킷이라 URL 이 아니라 객체 경로다 (구현에서 개명)
  system_event text,
  created_at   timestamptz not null default now(),
  deleted_at   timestamptz,

  constraint chat_messages_type_valid check (type in ('text', 'image', 'system')),
  constraint chat_messages_shape check (
       (type = 'text'   and sender_id is not null and content is not null
                        and char_length(content) between 1 and 1000
                        and image_path is null and system_event is null)
    or (type = 'image'  and sender_id is not null and image_path is not null
                        and content is null and system_event is null)
    or (type = 'system' and sender_id is null and system_event in ('join', 'leave')
                        and content is not null and image_path is null)
  )
);
```

`chat_messages.content` 는 `type='system'` 일 때 **행위자 닉네임 스냅샷**을 담는다. 문장은
앱이 만든다.

### 인덱스

```sql
create index chat_messages_room_created_idx
  on public.chat_messages (room_id, created_at desc, id desc)
  where deleted_at is null;

create index chat_participants_user_idx
  on public.chat_participants (user_id)
  where left_at is null;

create index chat_rooms_open_activity_idx
  on public.chat_rooms (created_at desc, id desc)
  where deleted_at is null and type = 'open';
```

소프트 삭제 대상의 목록 인덱스는 부분 인덱스로 만든다는 공통 규칙을 따른다.

### 함수 `is_room_member(room_id uuid) → boolean`

```sql
create or replace function public.is_room_member(room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.chat_participants p
    where p.room_id = is_room_member.room_id
      and p.user_id = auth.uid()
      and p.left_at is null
  );
$$;
```

`is_blocked_with()` 와 같은 모양이다. **`anon` 의 `execute` GRANT 를 유지해야 한다**
([스키마 §3](../../schema.md)의 경고가 그대로 적용된다).

### RLS

| 대상 | select | insert | update |
|---|---|---|---|
| `chat_rooms` | `type = 'open' and deleted_at is null` | 로그인 사용자 · `type = 'open'` | **없음** (v1) |
| `chat_participants` | `is_room_member(room_id)` **or** `user_id = auth.uid()` | 본인 행 · 공개방 · 정원 미달(트리거) | `user_id = auth.uid()` (`nickname` · `last_read_at` · `left_at`) |
| `chat_messages` | `is_room_member(room_id)` **and** `not is_blocked_with(sender_id)` and `deleted_at is null` | `is_room_member(room_id)` · `sender_id = auth.uid()` · `type in ('text','image')` | 소프트 삭제 전용 함수로만 |

**나갔던 방에 다시 들어가는 것은 insert 가 아니라 update 다.** PK 가 `(room_id, user_id)` 라
이미 행이 있고, `left_at` 을 `null` 로 되돌리는 것이 재입장이다. 그래서 참여자 select 정책에
`user_id = auth.uid()` 를 or 로 붙였다 — 나간 뒤에는 `is_room_member` 가 false 라 자기 행조차
못 읽어 앱이 첫 입장과 재입장을 구분할 수 없다. (구현 메모: PostgREST 의 upsert 는
보내는 모든 컬럼에 UPDATE 권한을 요구해 `room_id` 까지 열어야 하므로 쓰지 않는다 —
datasource 가 자기 행을 읽고 insert / update 를 고른다. [기록](history.md)) update 정책은 `is_room_member` 를 보지 않고
본인 행만 본다.

`delete` 는 어디에도 GRANT 하지 않는다. 메시지 소프트 삭제는
`soft_delete_chat_message(message_id uuid) → boolean` 함수로 한다 — 조회 정책이 삭제행을
가려 UPDATE + RETURNING 이 42501 로 막히는 함정([스키마 §11](../../schema.md))을 게시물·댓글과
같은 방식으로 피한다.

**차단은 앱 코드 없이 끝난다.** `is_blocked_with()` 가 select 정책에 들어가면 히스토리에서도
실시간 경로에서도 차단한 사람의 메시지가 오지 않는다 — Postgres Changes 가 **구독자별로 RLS 를
다시 검사**하기 때문이다.

### 트리거 셋

- `enforce_room_capacity()` — 참여자 insert 전 `member_limit` 검사
- `emit_membership_system_message()` — 참여자 insert · `left_at` 이 채워질 때(퇴장) ·
  `left_at` 이 `null` 로 되돌아갈 때(재입장) `type='system'` 메시지 삽입
- `verify_chat_image_path()` — 메시지 insert 시 `image_path` 가 실제로
  `{room_id}/{auth.uid()}/` 경로인지 검증. 2026-08-24 리뷰에서 게시물에 넣은
  `verify_post_image_urls` 와 같은 이유다

### 신고 확장

기존 폴리모픽 `reports` 의 `enforce_report_target()` 에 `'chat_message'` 분기 하나를 더한다.
테이블을 새로 만들지 않는다 ([F7 계획](../safety/plan.md)의 설계를 그대로 잇는다).

### 실시간 발행

```sql
alter publication supabase_realtime add table public.chat_messages;
```

이 한 줄이 빠지면 구독이 **조용히 아무것도 받지 않는다.** 마이그레이션에 포함한다.

### 뷰 둘

- `my_chat_rooms` — 내가 참여 중인 방 · 마지막 메시지 미리보기 · **안읽음 수** · 참여자 수
- `open_chat_rooms` — 탐색용 공개방 목록 · 참여자 수 · 마지막 활동 시각

`my_chat_rooms` 는 `security_invoker = on` 이다. 내가 멤버인 방만 다루므로 호출자의 RLS 로
충분하다. 안읽음 수는 `created_at > last_read_at and sender_id is distinct from auth.uid()`
카운트이고, 차단한 상대의 메시지는 RLS 가 이미 걸러 세지 않는다.

**`open_chat_rooms` 는 `security_invoker = off` 로 둔다 — 이 스키마의 두 번째 예외다.**
탐색 화면은 **아직 참여하지 않은 사람**이 보는데, 참여자 수를 세려면
`chat_participants` 를 읽어야 하고 그 select 정책은 `is_room_member` 다. 호출자 권한으로는
모든 방의 참여자 수가 0으로 보인다. 뷰가 노출하는 것은 **집계 수 하나**이고 참여자 신원은
내보내지 않는다. `post_comments_visible` 이 같은 이유로 만든 첫 예외이며
([스키마 §9](../../schema.md)), 그 절의 주의사항이 그대로 적용된다.

비정규화 `member_count` 컬럼으로도 풀리지만, "카운트 컬럼은 성능 문제가 관측되기 전에 하지
않는다"는 [F5 계획](../reaction/plan.md)의 판단을 유지한다.

### Storage `chat-images`

비공개 버킷. 경로 `{room_id}/{user_id}/{uuid}`.

- select: `is_room_member((storage.foldername(name))[1]::uuid)`
- insert: 위 조건 **그리고** `(storage.foldername(name))[2] = auth.uid()::text`
- update · delete: 없음

## 앱 구조

```
features/chat/
├── domain/
│   ├── entity/          chat_room · chat_participant · chat_message · chat_room_summary
│   ├── repository/      chat_repository.dart                 ★ 인터페이스
│   └── usecase/
│       ├── chat_usecase.dart                                 ★ facade (DI 등록은 이것만)
│       └── scenario/    create_room · join_room · send_message · send_image_message
│                        · leave_room · mark_read · report_message · delete_message
├── data/
│   ├── datasource/      supabase_chat_data_source.dart       ← RealtimeChannel 이 사는 유일한 곳
│   ├── dto/ mapper/ repository/
│   └── cursor/          message_cursor.dart
└── presentation/
    ├── bloc/            chat_room_bloc (+ event · state)
    ├── cubit/           chat_room_list_cubit · room_explore_cubit · create_room_cubit
    ├── page/            chat_room_list_page · chat_explore_page · chat_room_page
    │                    · create_room_page
    └── widget/          message_bubble · chat_composer · chat_room_tile · join_room_sheet
```

`RealtimeChannel` · `PostgresChangePayload` 같은 SDK 타입은 datasource 밖으로 나가지 않는다
(규칙 ①). domain 이 보는 실시간은 `Stream<ChatMessage> messageStream(String roomId)` 하나다.

### 낙관적 전송

1. 앱이 메시지 uuid 를 만든다
2. 버블을 `pending` 으로 즉시 띄운다
3. insert 성공 → 확정 / 실패 → 재전송 버튼
4. 실시간으로 되돌아온 같은 id 는 버린다

### 목록 읽기

메시지는 `(created_at desc, id desc)` 커서로 최신부터 읽고 화면에서 뒤집는다. 위로 스크롤하면
더 오래된 페이지를 잇는다. 커서 형식을 아는 곳은 `data/cursor/` 뿐이다
([아키텍처 §3-1](../../../../../docs/architecture.md)).

### 읽음 처리

방을 보고 있는 동안 마지막 메시지 시각으로 `last_read_at` 을 갱신한다(디바운스). 방을 벗어날
때 한 번 더 확정한다.

## 화면

| 화면 | 내용 |
|---|---|
| **채팅 탭** `ChatRoomListPage` | 내 방 목록 — 제목 · 마지막 메시지 · 안읽음 배지. FAB 로 방 만들기, AppBar 에 탐색 진입 |
| **탐색** `ChatExplorePage` | 공개방 목록 + 제목 검색. 커서 페이지네이션 |
| **입장 시트** `JoinRoomSheet` | 이 방에서 쓸 닉네임 입력. 기본값은 내 프로필 닉네임 |
| **방** `ChatRoomPage` | 말풍선 목록(위로 무한 스크롤) · 입력창 · 사진 첨부. AppBar 더보기에 나가기 · 참여자 목록. 말풍선 길게 눌러 신고 · 내 메시지 삭제 |
| **방 만들기** `CreateRoomPage` | 제목 · 소개 · 정원 |

하단 탭은 홈 · **채팅** · 프로필 · 설정 넷이 되고 `IndexedStack` 구조는 그대로다
([아키텍처 §3-2](../../../../../docs/architecture.md)).

공통 위젯 규칙(CLAUDE.md)을 따른다 — 빈 상태 · 오류는 `AppPlaceholder`, 나가기 · 삭제 확인은
`AppConfirmDialog.show(isDestructive: true)`, 더보기는 `AppOverflowMenu`, 아바타는 `AppAvatar`.
**`MessageBubble` 은 새로 만든다** — 기존 공통 위젯으로 표현되지 않고 채팅에만 필요한 모양이다.
반복되면 그때 `design_system/widget/` 으로 승격을 검토한다.

## 오류

datasource 예외는 `core/data/repository/` 의 공용 guard 가 `Failure` 로 바꾼다(규칙 ④).
정원 초과 · 닉네임 길이 같은 트리거 문구는 새 매핑을 만들지 않고, 진행 중인 `FailureCode`
작업([다국어 계획](../preferences/plan-language.md))에 얹는다.

## 완료 조건

- [x] 방을 만들고, 목록에서 찾아 입장하고, 닉네임을 정할 수 있다
- [x] 두 기기에서 보낸 메시지가 상대 화면에 **재조회 없이** 뜬다
- [x] 전송 실패 시 버블이 실패 상태로 남고 재전송된다. 되돌아온 내 메시지가 중복되지 않는다
- [x] 사진을 보내고, 방 참여자만 그 사진을 볼 수 있다
- [x] 방 목록의 안읽음 배지와 탭 배지가 맞다. 방을 읽으면 0이 된다
- [x] 나가면 목록에서 사라지고, 내가 남긴 메시지는 방에 이름과 함께 남는다
- [x] 입장 · 퇴장 시스템 메시지가 **선택한 언어로** 뜬다
- [x] 차단한 상대의 메시지가 히스토리에도 실시간에도 오지 않는다
- [x] 메시지를 신고할 수 있고 `reports` 에 `chat_message` 로 쌓인다
- [x] 비참여자가 REST 로 메시지를 직접 조회하면 막힌다
- [x] 남의 메시지 삭제 · 정원 초과 입장 · 위조된 이미지 경로가 전부 막힌다
- [x] 새 화면에 하드코딩된 한국어가 없다
- [x] `flutter analyze` 무결 · `flutter test` 전체 통과

## 테스트

위치는 `app/test/features/chat/` 로 `lib/` 구조를 그대로 미러링한다
([테스트 가이드](../../../../../docs/testing/README.md)).

- **scenario 단위** — 입장 시 닉네임 정규화, 전송 실패 롤백, 읽음 갱신 디바운스
- **bloc_test** — 낙관적 버블 → 확정, 실패 → 재전송 상태, 실시간 중복 제거, 위로 더 읽기
- **RLS 부정 테스트** (실제 JWT + REST, 기존 방식) — 비참여자 조회 · 남의 메시지 삭제 ·
  차단 상대 메시지 미노출 · 정원 초과 · Storage 경로 위조
- **실시간 구독은 로컬 Supabase 로 실제 확인한다.** 단위 테스트로 잡히지 않는다
- **Patrol E2E 1건** — 방 개설 → 입장 → 전송 → 수신

완료 시 `docs/testing/features/chat.md` 를 신설한다.

## v1 범위 밖

자리만 남기고 만들지 않는다.

- **1:1 DM** — `type='direct'` · `direct_key`(정렬한 두 uuid, unique) · 상대 프로필 기준 표시
- **방장 권한** — 강퇴 · 방 정보 수정 · 방 닫기
- **탭 배지의 실시간 갱신** — v1은 방 목록에 있을 때만 실시간이고, 그 밖에서는 재조회 시점에
  갱신된다. 상시 갱신은 푸시 알림과 함께 4단계에서 다룬다
- 말풍선별 안읽음 숫자(카톡의 말풍선 옆 숫자) · 타이핑 표시 · 답장/인용 · 이모지 반응 ·
  메시지 검색 · 메시지 수정

## 열린 문제

**아무나 방을 만드는데 방을 닫을 사람이 없다.** v1에서 악성 방에 대한 대응은 신고와 나가기뿐이고,
운영자가 `deleted_at` 을 직접 채우는 수동 경로만 있다. 방장 권한을 붙일 때 **가장 먼저** 해결할
항목이다. 그때 필요한 것: `chat_participants.role`, 방 소프트 삭제 함수, 강퇴 후 재입장 금지 목록.
