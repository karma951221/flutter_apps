# chat 테스트 (F9 오픈 채팅 · F9-DM)

> [테스트 가이드](../../../../../docs/testing/README.md) · [계획](plan.md) ·
> [DM 계획](plan-dm.md) · [기록](history.md) ·
> [스키마 §14](../../schema.md)

```bash
cd app
flutter test test/features/chat
```

## 단위 · 위젯

| 대상 | 시나리오 | 기대 결과 |
|---|---|---|
| `CreateRoomScenario` | 제목 정규화 | 앞뒤 공백을 제거한 제목으로 저장을 요청하고, 공백뿐인 제목은 저장하지 않는다. |
| `CreateRoomScenario` | 길이 검증 | DB CHECK 와 같은 기준(30자)에서 막고, 최대 길이는 허용한다. |
| `CreateRoomScenario` | 빈 소개 | 빈 문자열이 아니라 `null` 로 보낸다 — "소개 없음"과 "빈 칸"이 갈리지 않게. |
| `CreateRoomScenario` | 정원 범위 | 2–500 을 벗어나면 저장하지 않는다. 실패에 `field` 를 달아 돌려준다. |
| `JoinRoomScenario` | 닉네임 정규화 | 앞뒤 공백을 제거한 이름으로 입장한다. |
| `JoinRoomScenario` | 길이 검증 | 2자 미만·20자 초과를 막는다. 공백으로 길이를 채운 값도 막는다(DB 의 `btrim` 제약과 같은 기준). |
| `SendMessageScenario` | id 위임 | 호출부가 만든 id 를 **그대로** 넘긴다 — 새로 만들면 낙관적 버블과 서버 행의 id 가 갈려 중복이 쌓인다. |
| `SendMessageScenario` | 본문 정규화 · 길이 | 공백을 제거해 보내고, 공백뿐이면 보내지 않는다. 1000자에서 막고 최대 길이는 허용한다. |
| `MarkReadScenario` | 미래 시각 | 기기 시계가 앞서 있어도 지금으로 끌어내린다 — 아직 오지 않은 메시지까지 읽음 처리되면 안읽음이 영영 0 이 된다. |
| `MessageCursor` | 왕복 · 깨진 값 | 인코딩·디코딩이 같은 값이고, 형식이 아닌 값과 id 가 빠진 값은 `Failure` 로 막는다. |
| `ChatRoomBloc` | 구독 순서 | **구독을 히스토리보다 먼저** 건다. 반대면 읽는 동안 도착한 메시지가 두 경로 어디에도 들어오지 않는다. |
| `ChatRoomBloc` | 닉네임 붙이기 | 히스토리와 실시간 모두 참여자 맵의 **방별 닉네임**을 붙여 목록에 담는다. |
| `ChatRoomBloc` | 낙관적 전송 | 보내는 즉시 `pending` 버블이 목록 앞에 뜬다. |
| `ChatRoomBloc` | 실시간 중복 제거 | 같은 id 로 되돌아온 내 메시지는 새로 붙지 않고 기존 버블을 `sent` 로 확정한다. |
| `ChatRoomBloc` | 전송 실패 · 재전송 | 실패는 `failed` 로 남고, 재전송은 **같은 id** 로 다시 보낸다(새 id 를 만들지 않는다). |
| `ChatRoomBloc` | 모르는 발신자 | 참여자 목록에 없는 사람의 메시지가 오면 목록을 다시 읽어 이름을 채운다. |
| `ChatRoomBloc` | 위로 더 읽기 | 오래된 페이지가 목록 **뒤**에 붙고, 마지막 페이지면 커서가 비워진다. |
| `ChatRoomBloc` | 삭제 | 지워지면 목록에서 걷어내고, 지운 것이 없으면 목록을 건드리지 않는다. |
| `ChatRoomBloc` | 읽음 확정 | 나갈 때 **확정된** 마지막 메시지 시각으로 갱신한다 — 아직 서버에 없는 내 버블은 기준이 되지 않는다. |
| `ChatRoomBloc` | 읽음 실패 | 밖으로 새지 않는다 — 디바운스 타이머가 부르는 경로라 예외가 새면 uncaught async error 가 되어 앱이 무너진다. |
| `ChatRoomBloc` | 닫기 | 구독과 실시간 채널을 걷어낸다. 남기면 방을 드나들 때마다 구독이 쌓인다. |
| `ChatRoomListCubit` | 조회 성공 / 실패 | 목록을 담거나 `failure` 를 남긴다. |
| `ChatRoomListCubit` | 안읽음 합계 | 탭 배지의 근거가 되는 합계를 센다. |
| `ChatRoomListCubit` | 방을 읽고 나옴 | 그 줄의 안읽음만 0 이 되고 **목록을 다시 읽지 않는다**. 이미 0 이면 emit 하지 않는다. |
| `ChatExploreCubit` | 검색 디바운스 | 입력이 멎은 뒤 마지막 값 하나만 조회한다. |
| `ChatExploreCubit` | 더 읽기 | 커서를 이어 붙이고, 실패해도 읽은 목록과 커서를 지킨다. |
| `ChatRoomListPage` | 빈 상태 / 목록 / 배지 | 탐색으로 보내는 안내, 제목·참여자 수, 안읽음 배지를 보여준다. |
| `ChatRoomListPage` | 미리보기 | 사진은 '사진', 시스템 메시지는 **키로 만든 문장**, 대화가 없으면 그렇게 적는다. |
| `ChatRoomListPage` | 방 열기 | 제목을 함께 넘긴다 — 넘기지 않으면 방 화면 AppBar 가 방 이름 대신 '채팅' 으로 뜬다. |
| `ChatRoomPageArgs` extra codec | Map 왕복 | 제목·direct 여부를 복원하고 키·타입이 어긋나면 `null`로 거부한다. |
| 채팅방 라우터 | Map extra | `ChatRoomPage.args`로 복원하고 어긋난 Map은 `null`로 전달한다. |
| `ChatRoomPage` | 방별 닉네임 | 프로필 닉네임이 아니라 그 방에서 쓰는 이름이 보인다. |
| `ChatRoomPage` | 시스템 메시지 | DB 의 `'join'` 키 + 닉네임으로 "○○ 님이 들어왔습니다"를 만든다. |
| `ChatRoomPage` | 전송 | 버블이 즉시 뜨고 입력칸이 비워진다. 공백뿐인 입력은 보내지 않는다. |
| `ChatRoomPage` | 실시간 수신 | 재조회 없이 목록에 붙는다(조회는 처음 한 번뿐). |
| `ChatRoomPage` | 말풍선 메뉴 | 내 메시지는 삭제, 남의 메시지는 신고만 뜬다. |
| `ChatRoomPage` | 나가기 | 확인 다이얼로그를 거쳐야 `leaveRoom` 이 호출된다. |
| `CreateRoomPage` | 입력 항목 | 방 이름 · 소개 · 방에서 쓸 이름 · 정원 슬라이더가 있다. |
| `CreateRoomPage` | 기본값 | 방에서 쓸 이름은 내 프로필 닉네임, 정원은 `memberLimitDefault`. |
| `CreateRoomPage` | 개설 | 개설과 입장을 함께 요청하고 만든 방으로 들어간다 — 만든 사람도 참여자다. |
| `CreateRoomPage` | 개설 실패 | Snackbar 로 알리고 화면에 남는다. 입장은 시도하지 않는다. |
| `HomeShellPage` | 탭 · 배지 | 탭이 넷이 되고, 안읽음이 있으면 채팅 탭에 배지가 붙는다(셸이 그린다). |

## 단위 · 위젯 — DM (F9-DM)

```bash
cd app
flutter test test/features/chat
flutter test test/features/profile
```

| 대상 | 시나리오 | 기대 결과 |
|---|---|---|
| `OpenDirectRoomScenario` | 성공 | 저장소가 돌려준 방 id 를 그대로 전달한다 (`app/test/features/chat/domain/usecase/scenario/open_direct_room_scenario_test.dart`). |
| `OpenDirectRoomScenario` | 실패 | 저장소 실패(`Failure`)를 그대로 전달한다 — 차단·자기 자신 등 서버 판정을 앱이 다시 해석하지 않는다. |
| `ChatRoomListPage` | DM 줄 열기 | 상대 닉네임과 `isDirect: true` 를 방 화면에 넘긴다. |
| `ChatRoomListPage` | open 줄 열기 | 제목만 넘기고 `isDirect: false` — DM 과 open 이 같은 콜백에서 갈리는지 확인한다. |
| `ChatRoomTile`(위 페이지 테스트로 덮음) | direct 표시 | 상대 아바타·닉네임으로 그리고, **인원 수 텍스트를 그리지 않는다**(direct 는 항상 2 명이라 알려줄 정보가 없다). |
| `ChatRoomPage` | direct 방 메뉴 | 참여자 항목이 없고 나가기만 남는다 — 방 화면이 `ChatRoomPageArgs.isDirect` 를 받아 분기한다. |
| `ProfilePage` | 메시지 버튼 노출 | 타인 프로필에는 팔로우 옆에 메시지 버튼이 있고, 내 프로필에는 없다. |
| `ProfilePage` | 차단 상대 | 메시지 버튼을 아예 그리지 않는다 — 팔로우 버튼과 같은 `BlockActionCubit` 상태로 `_ProfileActions` 가 함께 게이팅한다. |
| `ProfilePage` | 메시지 버튼 탭 | `openDirectRoom` 을 호출해 성공하면 상대 닉네임과 함께 방으로 이동하고, 연타해도 한 번만 호출한다(진행 중 잠금). |
| `ProfilePage` | 메시지 버튼 실패 | 스낵바로 실패를 알리고 화면에 남는다. |

## 로컬 Supabase 로만 확인되는 것

단위 테스트는 스트림을 직접 밀어넣으므로 **publication 이 빠져도 통과한다.** 권한
경계와 실시간 전달은 실제 JWT + REST/WebSocket 으로 확인한다.

```bash
supabase start
python3 supabase/tests/chat_rls_check.py       # 78건 (F9 52 + DM 26)
python3 supabase/tests/chat_realtime_check.py  # 4건 (websockets 필요)
```

### 권한 경계 (`chat_rls_check.py`, 2026-08-30 78/78 통과)

| 묶음 | 확인한 것 |
|---|---|
| 방 개설 | 공개방 생성 · `created_by` 자동 채움 · `created_by` 위조 거부(`42501`) · `type='direct'` 거부 |
| 입장 | 개설자·타인 입장 · `user_id` 위조 거부 · 정원(3) 안 입장 · **정원 초과 거부**(`23514`) |
| 시스템 메시지 | 입장마다 `join` 적재 · 닉네임 스냅샷 · **한국어 문장이 DB 에 없음** |
| 송수신 | 참여자 전송·조회 · **비참여자 조회 `[]`** · 비참여자 전송 거부 · 앱의 시스템 메시지 위조 거부 · `sender_id` 위조 거부 |
| 이미지 경로 | 남의 폴더·다른 방 경로 거부(`42501`) · 본인 경로 통과 |
| 삭제 | 남의 메시지 삭제 실패(`false`) · 본인 메시지 소프트 삭제 · 삭제 후 조회에서 사라짐 |
| 차단 | 차단하면 히스토리에서 그 사람 메시지가 사라짐 · **시스템 메시지는 영향 없음** |
| 신고 | `chat_message` 신고 적재 · 시스템 메시지 신고 거부 · 자기 메시지 신고 거부 |
| 나가기·재입장 | `left_at` 갱신 · 퇴장 메시지 · 나간 뒤 조회 불가 · **나간 뒤에도 자기 참여자 행은 읽힘**(재입장 판정) · 재입장 시 `join` 재적재 |
| 입장 경로 | 참여자 행의 `room_id` 는 고칠 수 없다 · **upsert 는 권한 부족으로 막힌다** (앱은 읽고 나서 insert/update 를 고른다) |
| 뷰 | `my_chat_rooms` 의 방·참여자 수·내 닉네임 · 안읽음 계산과 0 복귀 · `open_chat_rooms` 를 비참여자와 **anon 이** 읽음 · 비참여자는 참여자 신원 못 봄 |
| 탐색 뷰 누출 | `security_invoker = off` 인 `open_chat_rooms` 를 발판으로 **참여자·메시지를 임베딩해도 비어 있다**(임베딩은 대상 테이블 RLS 를 따른다) · 뷰가 내보내는 컬럼은 집계 수까지뿐 |
| DM 개설(`open_direct_room`) | A 가 B 와 방을 연다 · **같은 상대로 재호출해도 같은 방 id** · **상대가 열어도 같은 방 id**(중복 방 없음) · 자기 자신과의 DM 거부(`23514`) · 존재하지 않는 상대 거부 + **문구가 중립적** |
| DM 노출 | 비참여자는 `chat_rooms` 로 DM 방을 조회할 수 없다 · **`open_chat_rooms` 에 DM 이 없다**(비참여자 기준·당사자 기준 모두) |
| DM 송수신 | 참여자 전송 · 비참여자 전송 거부 · 비참여자 조회 불가 · **DM 방에는 시스템 메시지가 없다** |
| DM 나가기·자동 재등장 | 나가면 `my_chat_rooms` 에서 사라진다 · **상대가 메시지를 보내면 자동으로 다시 나타난다**(시스템 메시지 없이) |
| `my_chat_rooms` DM 컬럼 | `type='direct'` · `title` 없음 · **상대 닉네임**을 준다 |
| DM 차단 | 차단 후 **양방향** 전송 거부 · `open_direct_room` 도 거부 · 차단 후 상대가 보낸 기존 메시지가 조회에서 사라짐 · 차단 해제 후 전송 복구 |

### 실시간 (`chat_realtime_check.py`, 2026-08-28 4/4 통과)

| 확인 | 결과 |
|---|---|
| 구독자가 재조회 없이 새 메시지를 받는다 | 통과 |
| 페이로드에 **앱이 만든 id** 가 그대로 온다 | 통과 (중복 제거의 근거) |
| 비참여자는 구독해도 받지 못한다 | 통과 — 구독자별 RLS 재검사 |
| 차단한 상대의 메시지는 실시간으로도 오지 않는다 | 통과 |

**구독 준비 신호에 주의한다.** `phx_reply` 는 채널 참여일 뿐이고, WAL 을 읽기
시작한 시점은 `system` 이벤트(`"Subscribed to PostgreSQL"`)다. 처음 이 검사를 짤 때
`phx_reply` 를 준비 신호로 삼아 메시지를 놓쳤다.

## E2E (Patrol)

```bash
cd app
patrol test -t patrol_test/chat_test.dart
```

방 개설 → 입장 → 전송 → **실시간 확정**까지 한 번에 태운다. 단위 테스트가 잡지
못하는 것은 publication 이 실제로 붙어 있는지다 — 단위 테스트는 스트림에 직접
값을 밀어넣으므로 발행이 빠져도 통과한다. 구독이 끊겨 있으면 '보내는 중' 이
사라지지 않아 이 테스트가 걸린다.

2026-08-28 에뮬레이터에서 통과 (`Successful: 1 / Failed: 0`).

**방을 나가는 흐름은 여기서 태우지 않는다.** 뒤로가기까지 넣었더니 테스트 본문이
끝난 **뒤에** 비동기 오류가 하나 더 올라와 실패로 잡혔고, harness 가 원문을 가려
원인을 짚지 못했다 — `auth_test` 에 이미 있는 같은 증상이다
([2026-08-27 검수](../../audits/audit-2026-08-27.md)). 나가기·목록 복귀는 위젯 테스트가 덮는다.

## 알아둘 것

- **`ChatRoomListCubit` 은 셸이 소유한다.** 탭 배지가 다른 탭에 있을 때도 숫자를
  알아야 하기 때문이다. 그래서 `ChatRoomListPage` 테스트는 cubit 을 직접 만들어
  `BlocProvider.value` 로 넣는다 — 프로덕션(`HomeShellPage`)과 같은 모양이다.
- `IndexedStack` 이 고르지 않은 탭 본문을 offstage 로 두고 finder 는 그것을
  건너뛴다. 셸 테스트에서 채팅 탭의 AppBar 제목이 잡히지 않는 이유다.
- 사진 말풍선은 서명 URL 을 받아 그린다. 위젯 테스트는 네트워크를 타지 않으므로
  **사진 렌더링은 E2E 와 수동 확인의 몫**이다.
- **E2E 는 텍스트가 아니라 `Key` 로 찾는다** (`createRoom.title` · `chatRoom.composer`
  등, `postEditor.*` 와 같은 규칙). 처음에는 `labelText` 를 텍스트로 기다렸는데,
  autofocus 로 라벨이 떠오르면 보이기 판정이 흔들리고 'FAB 라벨'과 '화면 제목'처럼
  같은 문구가 여럿일 때 무엇을 잡았는지도 알 수 없다. 실제로 그것 때문에 한 번
  실패했다.
- `CreateRoomPage` 테스트 하니스는 목록에서 **밀고 들어온 모양**이어야 한다. 성공
  경로가 pop 뒤에 방으로 push 하기 때문이다. 되돌아갈 자리가 없는 경우(딥링크)는
  화면이 `canPop()` 으로 막는다.
