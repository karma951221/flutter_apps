# F9-DM — 1:1 다이렉트 메시지 계획

> [트레이더 허브](../../README.md) · [기획](../../overview.md) · [F9 계획](plan.md) ·
> [스키마](../../schema.md) · [아키텍처](../../../../../docs/architecture.md)

> 상태: **착수** · 작성 2026-08-30
> 진행 상태의 단일 기준은 [진행 현황](../../status.md)이다.

## 범위

[F9 계획](plan.md)이 "마이그레이션 하나와 화면 몇 개"로 붙는다고 자리를 남겨 둔
1:1 DM 을 그 자리에 채운다. **새 테이블은 없다** — `chat_rooms.type='direct'` 와
`direct_key`, 기존 참여자·메시지·실시간·신고·차단 경로를 그대로 쓴다.

v1-DM 에 들어가는 것:

- 타인 프로필에서 DM 시작 (같은 두 사람의 방은 항상 하나)
- 채팅 탭 목록에 DM 이 섞여 나오고, 타일은 상대 프로필(닉네임·아바타)로 표시
- 실시간 텍스트·사진, 안읽음 배지, 메시지 신고·삭제 — 기존 경로 재사용
- 나가기 + **카톡식 자동 재등장** (상대가 보내면 내 목록에 다시 나타난다)
- 차단 연동 — 시작 거부 · 전송 거부 · 수신 숨김

## 확정한 결정과 근거

| 항목 | 결정 | 근거 |
|---|---|---|
| 수신 정책 | **아무나 시작 + 차단으로 방어** | 오픈채팅의 개방적 질감과 일치. 메시지 요청함은 상태·화면·정책이 범위를 크게 키운다(범위 밖) |
| 방 유일성 | `direct_key` = 두 uuid 를 정렬해 `:` 로 이은 text, **unique** | 같은 두 사람의 방이 둘 생기지 않는다. 동시 호출도 유니크 제약이 판정한다 |
| 방 생성 | **`open_direct_room(partner_id)` RPC 하나** | 방 + 참여자 2행이 원자적이어야 하고, 상대 참여자 행은 클라이언트 INSERT 정책(`user_id = auth.uid()`)으로 넣을 수 없다. `chat_rooms` 의 INSERT 정책은 계속 `type='open'` 만 허용 — DM 방이 생기는 경로는 이 함수뿐이다 |
| 정체성 | **프로필 기준 표시** · 입장 시트 없음 | F9 계획 "상대 프로필 기준 표시"를 따른다. `chat_participants.nickname` 은 제약 충족용으로 프로필 닉네임을 스냅샷하지만 화면은 쓰지 않는다 |
| 제목 | direct 방은 `title` **null** | 화면이 상대 프로필로 표시하므로 제목이 없다. CHECK 를 type 별로 나눈다 |
| 나가기 | `left_at` 재사용 + **자동 재등장** | 상대가 메시지를 보내면 트리거가 나간 쪽 `left_at` 을 null 로 되돌린다. 히스토리는 방에 남아 재등장 후 그대로 보인다 |
| 시스템 메시지 | direct 방은 **내지 않는다** | 1:1 에서 입퇴장 문구는 어색하고, "나갔습니다"는 나가기 사실을 상대에게 노출한다. `emit_membership_system_message()` 가 direct 방이면 이른 반환한다 |
| 차단 × 전송 | **서버(트리거)가 거부** | 수신 숨김은 기존 select 정책이 이미 한다. 1:1 에서 전송만 허용하면 허공에 말하는 상황이 된다. 거부 문구는 `enforce_comment_depth()` 전례대로 방향 중립 |
| 탐색 노출 | 없음 (기존 그대로) | `open_chat_rooms` 뷰와 `chat_rooms_select_open` 계열 정책이 이미 `type='open'` 으로 좁힌다. select 정책에 direct 멤버 분기만 더한다 |
| 정원 | direct 방은 `member_limit = 2` CHECK | 기존 `enforce_room_capacity()` 가 그대로 지킨다 |

## 데이터 · 권한 (마이그레이션 하나)

적용 후 [스키마 문서](../../schema.md) §14 를 같은 커밋에서 갱신한다.

### `chat_rooms` 변경

```sql
alter table public.chat_rooms add column direct_key text;
alter table public.chat_rooms add constraint chat_rooms_direct_key_unique unique (direct_key);
alter table public.chat_rooms alter column title drop not null;

-- 기존 chat_rooms_title_len · chat_rooms_limit_range 를 type 별 제약으로 교체
--   open   : title not null · 1~30자 · member_limit 2~500 · direct_key null
--   direct : title null · member_limit = 2 · direct_key not null
```

`direct_key` 는 `least/greatest` 로 정렬한 두 참여자 uuid 를 이은 값이다. unique
제약(부분 인덱스가 아니라 컬럼 제약 — `on conflict (direct_key)` 가 성립해야 한다)이
방 유일성과 동시 생성 경쟁을 모두 판정한다. open 방은 null 이고 null 끼리는
충돌하지 않는다.

### `open_direct_room(partner_id uuid) → uuid`

security definer. 멱등 — 몇 번을 불러도 같은 방 id 를 돌려준다.

1. 비로그인 42501 · `partner_id = auth.uid()` 거부 · 상대 프로필 없으면 거부
2. `is_blocked_with(partner_id)` 면 42501, 방향 중립 문구 `대화를 시작할 수 없습니다`
3. `insert into chat_rooms (type, title, member_limit, direct_key) values ('direct', null, 2, key) on conflict (direct_key) do nothing` → 행이 없으면 기존 방을 select
4. 참여자 upsert — **내 행**은 insert 또는 `left_at = null` 복원, **상대 행**은 없을 때만 insert (상대의 나가기 상태를 건드리지 않는다). nickname 은 각자의 프로필 닉네임 스냅샷
5. `revoke from public, anon` + `grant execute to authenticated` (기존 RPC 짝과 동일)

### `enforce_direct_message()` (트리거, `chat_messages` before insert)

방이 `type='direct'` 이고 메시지가 `text`·`image` 일 때:

- 상대와 차단 관계면 42501, 방향 중립 문구 `메시지를 보낼 수 없습니다`
- 상대의 `left_at` 이 채워져 있으면 null 로 복원 — **자동 재등장.** 이 UPDATE 가
  기존 트리거 둘을 다시 지나지만, 정원 검사는 2인 방에서 항상 통과하고 시스템
  메시지는 direct 억제 분기에 걸려 나오지 않는다

시스템 메시지(`sender_id is null`)와 open 방은 이른 반환한다.

### 기존 객체 수정 3곳

- `chat_rooms_select_open` 정책 → `(type = 'open' and deleted_at is null) or
  (type = 'direct' and deleted_at is null and public.is_room_member(id))`.
  anon 은 direct 분기가 항상 false 라 기존과 동일하게 동작한다
- `emit_membership_system_message()` — 방이 direct 면 이른 반환
- `my_chat_rooms` 뷰 — 끝에 `partner_id` · `partner_nickname` · `partner_avatar_url`
  컬럼 추가 (direct 가 아니면 null). 상대 참여자 행은 내가 멤버인 방이므로
  `is_room_member` 정책으로 읽힌다 — 상대가 나간 뒤에도 표시가 유지된다.
  **`create or replace view` 는 reloption 을 리셋하므로 `with (security_invoker = on)`
  을 반드시 다시 명시한다** ([스키마 §9](../../schema.md)의 함정)

건드리지 않는 것: `chat_rooms` INSERT 정책(계속 open 전용), 참여자·메시지 정책,
GRANT, Storage, 실시간 발행, `reports`(`chat_message` 분기가 DM 메시지도 그대로
덮는다), `open_chat_rooms` 뷰.

### 트리거 문구 → FailureCode

`대화를 시작할 수 없습니다` · `메시지를 보낼 수 없습니다` 를 기존 DB 문구 매핑
방식대로 mapper 에 더하고 세 언어 ARB 로 번역한다 (마이그레이션 없이 앱에서).

## 앱

```
features/chat/
├── domain/
│   ├── repository/  chat_repository.dart          + openDirectRoom(partnerId)
│   └── usecase/scenario/                          + open_direct_room_scenario.dart
├── data/datasource/ supabase_chat_data_source.dart + RPC 호출
└── presentation/
    ├── cubit·page — 기존 화면에 direct 분기 (새 화면 없음)
    └── 프로필 쪽 진입점은 features/profile 이 소유
```

- **진입점**: 타인 프로필의 팔로우 버튼 옆에 "메시지" 버튼. 탭 → RPC → 기존
  `ChatRoomPage` 로 이동. 시작 실패(차단)는 `AppSnackBar` 로 안내
- **목록 타일**: `my_chat_rooms` 의 `type` 으로 분기 — direct 면 상대 아바타
  (`AppAvatar`) + 상대 닉네임, open 이면 기존 그대로
- **방 화면**: direct 면 AppBar 제목이 상대 닉네임. 더보기 메뉴에서 참여자 목록을
  숨기고 나가기만 남긴다. 전송·실시간·사진·신고·삭제·읽음 처리는 기존 코드가
  그대로 돈다
- 새 문자열은 처음부터 ARB 세 벌 (ko·en·ja)

## 완료 조건

- [x] 타인 프로필에서 DM 을 열고, 같은 상대와 다시 열면 같은 방이다 —
      `chat_rls_check.py` 로 순차 재호출(같은 쪽·상대 쪽 모두)이 같은 방 id 를 주는
      것을 확인했다
- [ ] 위 항목의 동시(같은 순간) 호출 — 별도 프로세스로 실제 경쟁을 재현하지
      않았다. `insert ... on conflict (direct_key) do nothing` 뒤 select 하는
      패턴이 postgres 트랜잭션 차원에서 원자적으로 판정하는 구조라 follow/block
      처럼 앱 레벨에서 판정을 두 단계로 나누는 경쟁이 아니라고 보고
      `follow_block_race_check.py` 같은 별도 동시성 스크립트는 두지 않았지만,
      이는 설계상 안전하다는 추론이지 재현으로 확인한 사실이 아니다
- [ ] 두 기기에서 메시지가 재조회 없이 실시간으로 오간다 (기존 경로) — DM 전용 실시간
      스크립트는 없다. `chat_realtime_check.py`(F9, 4/4)가 확인한 Postgres Changes
      구독·RLS 재평가 메커니즘은 방 `type` 을 분기하지 않으므로 DM 방에도 그대로
      적용되지만, DM 메시지로 실제 왕복을 재현한 적은 없어 체크하지 않는다. 두 기기
      E2E 가 없으면 확인할 수 없는 항목이다
- [x] DM 방이 탐색 화면과 비참여자 REST 조회에 노출되지 않는다 — `chat_rls_check.py`
      (`open_chat_rooms` 비참여자·당사자 기준 모두 빈 목록, 비참여자의 `chat_rooms`
      직접 조회도 빈 목록)
- [x] 목록·방 화면이 상대 프로필 닉네임·아바타로 표시된다 — 위젯 테스트
      (`ChatRoomListPage`·`ChatRoomPage`) + `chat_rls_check.py` 의 `my_chat_rooms`
      DM 행 검증(`partner_nickname` 등)
- [x] 나간 DM 방은 목록에서 사라지고, 상대가 메시지를 보내면 다시 나타나며
      이전 히스토리가 보인다 — `chat_rls_check.py` 가 사라짐·재등장은 직접 확인한다.
      "이전 히스토리가 보인다"는 부분은 새로 만든 검증이 아니라 F9 의 기존 메커니즘을
      그대로 물려받은 것이다 — `is_room_member()` 는 현재 `left_at` 만 보고 과거
      시각을 따지지 않으므로, 재입장하면 나가기 전 메시지도 다시 보인다(오픈 채팅에서
      이미 확인된 동작)
- [x] DM 방에는 입퇴장 시스템 메시지가 생기지 않는다 — `chat_rls_check.py`
      ("DM 방에는 시스템 메시지가 없다", "자동 재등장 과정에서도 시스템 메시지는
      생기지 않는다")
- [x] 차단 관계면 시작·전송이 서버에서 거부되고(방향 중립 문구), 수신은 숨는다 —
      `chat_rls_check.py` (차단 후 A·B 양방향 전송 거부, `open_direct_room` 거부,
      차단 후 상대 메시지가 조회에서 사라짐, 차단 해제 후 복구)
- [x] 자기 자신과의 DM 이 거부된다 — `chat_rls_check.py` (`23514`,
      `FailureCode.directChatSelfNotAllowed` 로 매핑)
- [x] 새 문자열에 하드코딩된 한국어가 없다 — DM 이 추가한 ARB 키
      (`profileMessageButton` · `failureDirectChatNotAllowed` ·
      `failureDirectChatSelfNotAllowed` · `failureChatSendNotAllowed` 등) 를
      직접 확인했다. en·ja 는 한국어 원문을 직역하지 않고 저장소 어투로 새로
      썼다(`history.md` 참고). 세 ARB 의 키 집합 일치를 자동으로 지키는 컨벤션
      테스트는 아직 없다 — `test/convention/arb_description_convention_test.dart`
      는 ko 템플릿의 `@key` description 유무만 검사한다
- [x] `flutter analyze` 무결 · `flutter test` 전체 통과 ·
      `chat_rls_check.py` DM 경계 통과 — 2026-08-30 기준 analyze 무결,
      test 582/582, `chat_rls_check.py` 78/78(F9 52 + DM 26)

## 테스트

- **scenario 단위** — open_direct_room 성공·실패 경로 (`app/test/features/chat/`)
- **cubit·위젯** — 목록 타일 direct 분기, 프로필 메시지 버튼
- **RLS 부정 테스트** — `supabase/tests/chat_rls_check.py` 에 DM 절 추가:
  제3자 조회 불가 · 차단 시 시작/전송 거부 · 탐색 미노출 · 중복 방 불가 ·
  자기 DM 거부 · 자동 재등장
- Patrol E2E 는 기존 1건 유지 (범위 밖)

완료 시 [테스트 문서](testing.md)와
[스키마 §14](../../schema.md), [기록](history.md)을 갱신한다.

## 범위 밖

메시지 요청함(수락/거절) · 읽음 표시(1) · 푸시 알림(4단계) · DM 검색 ·
운영자가 지운 direct 방의 재생성 (unique `direct_key` 가 남아 막힌다 — 수동 운영
경로뿐인 현 단계에서는 방의 `deleted_at` 을 되돌리는 것으로 충분하다)
