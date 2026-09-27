# chat — 구현 기록 (F9 오픈 채팅 · F9-DM)

> [계획](plan.md) · [DM 계획](plan-dm.md) · [테스트](testing.md) ·
> [스키마 §14](../../schema.md)

구현 2026-08-28. 계획과 달라진 것과 그 이유만 적는다.

## 계획과 달라진 것

### `image_url` → `image_path` (컬럼 이름을 바꿨다)

계획서의 `chat_messages.image_url` 은 `post_images.url` 과 같은 이름인데, 담는 것이
다르다. `chat-images` 는 **비공개 버킷**이라 공개 URL 이 존재하지 않는다 — 저장할 수
있는 값은 버킷 안의 객체 경로뿐이고, 화면에 띄울 때 서명 URL 을 만든다.

계획 안에 이미 긴장이 있었다: "비공개 버킷"과 "`image_url`" 이 같은 문서에 있었다.
공개 버킷을 전제한 이름이 남은 것으로 보고 경로 쪽에 맞췄다. 같은 이름이 서로 다른
것을 가리키면 나중에 `post_images` 를 참고해 코드를 짜는 사람이 반드시 헷갈린다.

앱 쪽도 같이 정리했다 — `ImageStorage` 에 `uploadToPath` 와 `signedUrl` 을 더했다.
기존 `upload` 는 경로의 첫 조각을 **언제나 사용자 id** 로 만들어서 채팅의
`{room_id}/{user_id}/...` 순서를 표현할 수 없었다.

### `sender_id` 에 `default auth.uid()` 를 넣었다 (계획에 없던 필수 항목)

계획의 DDL 에는 `sender_id uuid references profiles(id)` 만 있었다. 그대로 만들면
**메시지를 한 건도 보낼 수 없다.** `sender_id` 는 위조를 막으려고 INSERT GRANT 에서
빼는데, 기본값이 없으면 `null` 로 들어가 삽입 정책(`sender_id = auth.uid()`)이 언제나
실패한다.

로컬 검증 첫 판에서 "참여자가 메시지를 보낸다 → 403" 으로 잡혔다. 시스템 메시지를
만드는 트리거는 `null` 을 명시해 이 기본값을 덮는다.

### 정원 트리거가 `UPDATE` 도 본다

계획은 "참여자 insert 전 `member_limit` 검사"라고만 적었다. 재입장은 insert 가 아니라
`left_at` 을 되돌리는 **update** 라, insert 만 보면 정원이 찬 방에 나갔다 들어오는
것으로 얼마든지 넘어설 수 있다. `before insert or update` 로 걸고, 나가는 중이거나
다른 컬럼만 바뀌는 update 는 그냥 통과시킨다.

### `ChatRoomListCubit` 을 셸이 소유한다

계획의 구조도에는 `chat_room_list_cubit` 이 채팅 화면 아래에 있다. 그대로 두면 탭
배지가 그 화면 안에 갇혀서 **다른 탭에 있을 때 숫자를 알 수 없다.** `HomeShellPage`
가 만들어 아래로 내려주고, `ChatRoomListPage` 는 읽어 쓰기만 한다.

### `room_cursor.dart` 를 하나 더 두었다

계획은 `data/cursor/message_cursor.dart` 하나만 적었는데, 탐색 목록도 커서
페이지네이션이라 방 커서가 따로 필요했다. 정렬 기준을 **개설 시각**으로 잡았다 —
마지막 활동 시각으로 하면 방이 오갈 때마다 순서가 바뀌어 페이지 경계가 흔들린다.

### 입장을 upsert 가 아니라 "읽고 나서 쓴다" 로 바꿨다

계획은 재입장을 upsert 로 적었다(`PK 가 (room_id, user_id) 라 ... left_at 을 null 로
되돌리는 것이 재입장`). 실제로 해 보니 **PostgREST 의 upsert 는 보내는 모든 컬럼에
INSERT 와 UPDATE 권한을 함께 요구한다.** 그러려면 `room_id` 에 UPDATE 를 줘야 하는데,
그 순간 자기 참여자 행의 `room_id` 를 고쳐 **들어간 적 없는 방으로 옮길 수 있다** —
삽입 정책의 "살아 있는 공개방인가" 검사가 통째로 건너뛰어진다.

그래서 datasource 가 자기 참여자 행을 먼저 읽고 insert 와 update 를 고른다. 참여자
조회 정책에 `user_id = auth.uid()` 를 or 로 붙여 둔 것이 정확히 이걸 위해서였다 —
계획이 예상한 그림대로다.

로컬 검증에 두 건을 더해 고정했다: `room_id` 는 고칠 수 없다, upsert 는 권한 부족으로
막힌다.

### `LikePattern` 을 core 로 뽑았다

방 제목 검색이 `ilike` 를 쓰는데, 사용자가 친 `%` 와 `_` 는 리터럴이어야 한다.
2026-08-27 리뷰에서 닉네임 중복 확인에 넣었던 이스케이프와 같은 규칙이라
`core/data/like_pattern.dart` 로 올리고 `NicknameMatch` 가 그걸 쓰게 했다.

## 계획대로였지만 적어둘 것

- **구독을 히스토리보다 먼저 건다.** 반대로 하면 읽는 동안 도착한 메시지가 두 경로
  어디에도 들어오지 않고 조용히 사라진다. bloc 테스트가 `verifyInOrder` 로 이 순서를
  고정한다.
- **전송 성공에서 버블을 확정하지 않는다.** 확정은 실시간 페이로드가 한다. 성공 응답
  만으로 `sent` 로 바꾸면 구독이 끊긴 상태에서도 보낸 것처럼 보여 거짓이 된다.
- **차단은 앱 코드가 0줄이다.** `is_blocked_with(sender_id)` 가 select 정책에 있고
  Postgres Changes 가 구독자마다 그 정책을 다시 평가한다. 실시간 검사로 확인했다.
- 메시지 삭제는 화면에서 아예 걷어낸다. 게시물·댓글처럼 "삭제됨" 자리를 남기지
  않는다 — 대화는 흐름이라 빈 자리가 더 어수선하다.

## 겪은 것

**실시간 구독의 준비 신호를 잘못 짚었다.** 검증 스크립트를 처음 짤 때 `phx_reply`
(채널 참여 응답)를 준비 완료로 보고 곧바로 메시지를 넣었더니 0건 수신이었다. 실제로
WAL 을 읽기 시작하는 시점은 그 뒤에 오는 `system` 이벤트(`"Subscribed to
PostgreSQL"`)다. 스키마 문제로 한참 헤맸는데 원인은 검사 쪽이었다.

앱은 이 함정을 피해 간다 — 구독을 먼저 걸고 히스토리를 읽으므로, 준비되는 동안
도착한 메시지도 복제 슬롯에 쌓였다가 전달된다.

### 읽음 갱신을 조용히 실패시킨다

디바운스 타이머가 부르는 경로라 `_markReadNow()` 가 돌려주는 Future 를 아무도
기다리지 않는다. 여기서 예외가 새면 붙잡는 곳이 없어 **uncaught async error** 가
되고, 화면과 아무 상관 없는 실패가 앱을 통째로 무너뜨린다. E2E 가 이걸 잡았다 —
메시지 전송까지 다 통과한 뒤 2초쯤 지나 테스트가 통째로 죽었고, 원인은 화면이
아니라 배경에서 도는 읽음 갱신이었다.

읽음 시각이 한 번 밀리는 것은 다음 갱신이 바로잡고 사용자에게 알릴 일도 아니다.
`close()` 의 채널 정리도 같은 이유로 `catchError` 를 단다.

## 남은 것

- **탈퇴한 계정의 채팅 이미지가 Storage 에 남는다.** `delete_account()` 가 메시지
  행을 cascade 로 지우지만, 앱의 `removeAllForCurrentUser` 는 `{user_id}/` 접두사로
  훑기 때문에 `{room_id}/{user_id}/...` 는 찾지 못한다. 객체는 아무 행과도 이어지지
  않아 노출되지는 않고 저장 공간만 차지한다. 방을 가로질러 훑는 것은 비싸서 v1 에서는
  두었다.
- 계획의 "열린 문제"(악성 방을 닫을 사람이 없다)는 그대로 남아 있다.

## F9-DM (1:1 채팅) — 계획과 달라진 것

구현 2026-08-30. 스펙은 [DM 계획](plan-dm.md). 스키마·RLS·RPC·트리거는 계획대로
붙었고([스키마 §14](../../schema.md) DM 절 참고), 화면 쪽에서 계획서가 정하지 않은
것 셋을 구현 중에 확정했다.

### en·ja 실패 문구는 저장소 어투를 따랐다 (계획서 문구 그대로 옮기지 않았다)

계획서는 트리거 문구로 한국어 원문(`대화를 시작할 수 없습니다` · `메시지를 보낼 수
없습니다`)만 적어 두었다. en·ja ARB 는 그 한국어를 직역하지 않고, 저장소의 기존
실패 문구들과 같은 자연스러운 어투로 새로 썼다(예: en
`"You can't start this conversation right now"`, ja
`"現在この会話を開始できません"`) — 다른 `FailureCode` 문구들이 전부 이런
모양이라 DM 문구만 직역투로 튀는 것을 피했다.

### DM 타일은 인원 수를 표시하지 않는다

`ChatRoomTile` 이 direct 방이면 `l10n.chatMemberCount(...)` 렌더를 건너뛴다 — 정원이
`chat_rooms_limit_range` 로 항상 2로 고정되어 있어 인원 수가 알려줄 정보가 없다.
open 방과 같은 자리에 그 텍스트를 채우면 "2/2"만 반복해서 보여주는 잡음이 된다.

### 차단 상대 프로필에서는 메시지 버튼도 통째로 숨긴다

F7 이 차단 상대 프로필에서 팔로우 버튼을 숨기던 것과 같은 근거다 —
`open_direct_room()` 이 차단 관계면 42501 로 거부하므로 버튼을 눌러도 실패
스낵바만 뜬다. 눌러서 실패를 확인시키는 대신 아예 안 보이게 하는 쪽을 택했다.
기존에 팔로우 버튼 하나만 감싸던 위젯을 `_ProfileActions` 로 승격해 팔로우·메시지
버튼 둘을 같은 `BlockActionCubit` 상태로 함께 게이팅한다
(`app/lib/features/profile/presentation/page/profile_page.dart`).

### self-DM 거부 문구가 FailureCode 로 매핑됐다

트리거의 `자기 자신과는 대화할 수 없습니다`는 `FailureCode.directChatSelfNotAllowed`
로 매핑된다(`supabase_error_mapper.dart`). 다른 DM 실패 문구와 달리 방향 중립이
아니라 원인을 그대로 밝히는데, 컨벤션 테스트가 `FailureCode` 전 항목에 로컬라이즈된
문구를 요구해 새 코드를 그대로 추가했다 — 자기 자신과의 대화 시도는 차단처럼 상대에게
노출될 정보가 없으므로 문구를 흐릴 이유가 없었다.

## F9-DM 이 남긴 것 (알려진 잠재 갭)

- **`ChatRoomPageArgs` 없이 direct 방에 진입하는 경로가 생기면 참여자 메뉴가
  다시 보인다.** direct 여부는 방 행이 아니라 화면 전환 인자로 전달된다 — 방 화면이
  `isDirect` 를 모르면 open 방과 같은 참여자 메뉴를 그대로 그린다. 현재 진입 경로
  넷(`chat_room_list_page.dart` · `create_room_page.dart` · `chat_explore_page.dart` ·
  `profile_page.dart`)은 전부 `ChatRoomPageArgs` 를 넘기므로 지금은 문제가 없지만,
  미래에 딥링크 등 인자 없이 방 id 만으로 진입하는 경로가 추가되면 이 갭이 드러난다.
- **상대가 탈퇴한 direct 방은 이름 없는 타일로 남는다.** `chat_participants.
  user_id` 가 `profiles(id)` 를 `on delete cascade` 로 참조해, 상대 계정이
  지워지면 상대의 참여자 행 자체가 사라진다. `my_chat_rooms` 의 partner
  lateral 이 짝을 못 찾아 `partner_id`·`partner_nickname`·`partner_avatar_url`
  이 전부 null 이 되고, 목록 타일은 아바타 자리에 '?' 만 뜨고 방 이름이 빈다.
  그 방을 고치는 화면은 없다 — 나가기로 정리하는 것만 남는다.
- **운영자가 soft-delete 한 direct 방에서 상대가 나가 있으면 전송이 '없는
  방입니다' 로 실패한다.** `enforce_direct_message()` 의 카톡식 자동 재등장은
  상대의 `left_at` 을 되돌리는 UPDATE 인데, 이 UPDATE 가 다시 지나는
  `enforce_room_capacity()` 가 `deleted_at` 채워진 방을 "없는 방"으로 보고
  `23503` 을 던진다(`add_chat.sql`). 상대가 나가지 않은 상태라면 이 UPDATE
  자체가 안 돌아 드러나지 않는 조합이다. 운영자 삭제 방을 되살리는 화면은
  없다(계획서 범위 밖) — `deleted_at` 을 되돌리는 것은 수동 운영 경로뿐이다.
