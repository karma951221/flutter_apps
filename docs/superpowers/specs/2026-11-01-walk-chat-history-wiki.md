# walk — 물어보기 대화 기록 · 위키 수정 기획

> 작성 2026-11-01 · 결정 반영 2026-11-01(2차) · 앱: [Life Tool(walk)](../../../apps/walk/docs/README.md) · 계획: [walk 계획](../../../apps/walk/docs/plan.md)
> 앞선 설계: [물어보기 설계](2026-10-27-walk-life-chat-design.md) · 함께 보는 기획: [키 입력 · 멀티 벤더](2026-11-01-walk-chat-key-input.md) · [체감 속도](2026-11-01-walk-chat-streaming-ux.md)
> 상태: **1단계(대화 기록 · 임시 대화 · 사용량) 구현됨 · 2단계(위키) 기획** — 구현 기록은 [walk 기록](../../../apps/walk/docs/history.md#2026-11--물어보기-대화-기록--임시-대화--사용량)
> 화면 구성은 [하단 탭 재구성 · 설정 분산](2026-11-01-walk-nav-regroup-design.md)을 전제한다 — 설정 탭이 없고, 이 기획의 설정 행은
> **물어보기 설정 화면**(화면 전체가 잠금 아래)에 들어간다. 재구성이 먼저 들어간다(→ [겹치는 곳](#다른-기획과-겹치는-곳)).

## 왜

물어보기를 써 보니 **대화가 정리되지 않는다.** 지금은 대화가 메모리에만 있어 [새 대화]나 앱 종료로 사라지고,
대화에서 알게 된 것(“출근 알람은 ‘출근’ 라벨”, “동네 카페는 집 앞 가게”)을 다음 대화에서 다시 설명해야 한다.
사용자가 원하는 것은 셋이다.

1. 지난 대화를 **목록으로 보고 · 열고 · 이어가고 · 지운다.**
2. 대화 중 남길 만한 내용을 **위키로 정리**해 다음 대화에서 모델이 참고한다. 무엇을 위키로 만들지는 **사용자가 정한다.**
3. 남기고 싶지 않은 대화는 **임시 대화**로 해서 기기에 아무것도 남기지 않는다.

## 지금 모습(코드로 확인)

- [chat_session.dart](../../../apps/walk/lib/domain/chat/usecase/chat_session.dart) — `ChatSession` 은 `@lazySingleton`,
  대화는 `_messages`(API 메시지 원본 JSON) 메모리 리스트뿐. `reset()` · 앱 종료로 사라진다. 실패한 질문은 그 질문에서
  덧붙인 메시지를 되돌린다. 사진 한도 `maxImagesPerConversation = 12` 는 “지난 메시지를 고치지 않으므로(thinking 서명) 보낸
  사진이 매 요청에 다시 실린다”는 이유에서 나왔다.
- [chat_cubit.dart](../../../apps/walk/lib/presentation/chat/cubit/chat_cubit.dart) — 화면용 말풍선(`ChatBubble`: role · text ·
  cited · failure)만 든다. 탭(`ChatTab` State)이 소유하고, `newConversation()` 이 세션과 말풍선을 함께 비운다.
- [chat_tab.dart](../../../apps/walk/lib/presentation/chat/page/chat_tab.dart) — `DiaryLockGate` 안쪽. 앱바에는 [새 대화] 하나.
- [life_tools.dart](../../../apps/walk/lib/domain/chat/tool/life_tools.dart) — 도구 5개로 **원본 기록만** 읽는다. 기억 계층 없음.
- [anthropic_chat_model.dart](../../../apps/walk/lib/data/chat/anthropic_chat_model.dart) — Anthropic 전용. `system` 은 문자열 하나,
  매 요청에 `messages` 전체를 보낸다. 프롬프트 캐시 · 사용량 집계 없음.
- drift DB 는 둘 — `diary`(일기) · `ring_archive`(기상 기록). [register_module.dart](../../../apps/walk/lib/core/di/register_module.dart)
  에서 `driftDatabase(name: …)` 로 따로 연다.
- [walk 계획](../../../apps/walk/docs/plan.md) “범위 밖”에 **“물어보기: 대화 저장 · 여러 대화”**, “규약” 절에 “나에 대한 메모 ·
  LLM 위키는 아직 안 함”이 적혀 있다. 이번 기획이 둘을 범위 안으로 들인다(→ [문서 갱신](#문서-갱신구현-때)).

## 다른 기획과의 경계

[키 입력 · 멀티 벤더 기획](2026-11-01-walk-chat-key-input.md)이 물어보기를 **여러 벤더(한 번에 하나, 교체 가능, 모델은 API
목록에서 선택)** 로 넓힌다. MVP 벤더는 **Claude · GPT**, Grok 은 후속. 그 기획서가 소유하는 것:

- 벤더 중립 메시지(`ChatMessage` · `AssistantPart` · `ToolResultPart` · `ToolSpec`) · `ModelEvent` · `TokenUsage` 와 벤더별
  어댑터(`AnthropicChatModel` · `OpenAiResponsesChatModel`) — 그 기획서 §8
- thinking · 서명 · 암호화 reasoning(`VendorTurnState`, 저장하지 않는 불투명 값) · 프롬프트 캐시처럼 벤더마다 다른 것
- 키 · 벤더 · 모델 설정, 전송 동의 문구, **벤더를 바꿀 때의 재동의**
- 사용량 기록 **계약** `ChatUsageLog.record(ChatUsageRecord)` — 그 기획서 §9

이 기획서는 그 중립 계약 **위에서** 대화 저장 · 위키 · 임시 대화, 그리고 **사용량 저장 구현(테이블 · 보관 · 보기 화면)** 을 정한다.
그 밖에 [체감 속도 기획](2026-11-01-walk-chat-streaming-ux.md)의 **[■ 멈춤]** 이 남기는 멈춘 답을 저장 규칙에 넣는다.

이 기획이 중립 계약에 바라는 것:

1. 응답마다 사용량 — `ModelCompleted.usage`(`TokenUsage`)로 이미 들어 있다.
2. 벤더 서버에 대화 상태를 남기지 않는 요청 — MVP 두 어댑터가 이미 그렇다(Anthropic 은 상태 저장 없음, OpenAI 는 `store: false`
   상시). 임시 대화용 플래그를 따로 두지 않고, 후속 벤더 어댑터도 이 원칙을 지키게 그 기획서에 적어 둔다.
3. (선택) `ModelRequest.system` 을 **고정 앞부분 + 바뀌는 뒷부분**으로 나눠, 캐시를 지원하는 벤더에서 앞부분에 캐시를 건다.
   지금 계약은 `String system` 하나이므로 그 기획서에 제안만 한다.

## 결정

사용자 결정(2026-11-01)과 그에 따른 설계.

| # | 주제 | 결정 |
|---|---|---|
| D1 | 저장하는 것 | **보이는 대화만**(질문 · 답 글 · 근거 일기 id · 멈춤 표시). 원본 메시지 · thinking · 도구 결과 · 사진 · 진행 노트 · 단계 요약은 저장 안 함. 끝까지 받은 턴과 **[■ 멈춤]으로 멈춘 턴**(글이 조금이라도 왔을 때)을 저장, 실패한 턴은 저장 안 함 |
| D2 | 지난 대화 이어가기 | **저장된 글로 다시 채워 이어간다.** 최근 20턴, 사진 한도는 0부터 |
| D3 | 저장 기본값 | **항상 저장.** 남기지 않을 대화는 **임시 대화**로. 설정 스위치 없음 |
| D4 | 임시 대화 | 기기에 아무것도 저장 안 함 · 위키 색인과 위키 도구를 빼 위키가 전혀 나가지 않음 · [위키로 정리] 없음 · 벤더 서버에 대화 상태 안 남김 · **보이는 동안만 `FLAG_SECURE`**(끄는 설정 없음) · 사용량은 숫자만 · 일반 대화로 바꾸기 없음 |
| D5 | 위키 단위 | **사실 메모**(제목 · 한 줄 요약 · 본문). 메모끼리 **`[[id]]`**, 메모 → 일기 **`[[일기:<entryId>]]`** 링크 |
| D6 | 위키 만들기 | **사용자가 누를 때만.** 대화 화면 [위키로 정리] → 정리 요청 한 번(지금 고른 벤더 · 모델) → 후보 **최대 8개**를 하나씩 저장 / 고쳐서 저장 / 버림. 말풍선 [위키에 추가] · 위키 화면 직접 추가 유지. **답하는 중 자동 제안은 하지 않는다** |
| D7 | 위키 참고 방식 | **시스템 프롬프트엔 색인(제목 + 한 줄 요약)만, 본문은 `read_wiki` 도구로 필요할 때.** 링크를 따라 더 연다. 필요 없으면 모델이 안 연다. 토글 없음 |
| D8 | 위키 붙이는 부분 | 교체 가능한 정책 `WikiContextPolicy`. 이번엔 라우터(결정 모델) 없음. 요청별 토큰 · `read_wiki` 호출 수를 기기에 기록 |
| D9 | 모두 지우기 | **대화 목록 화면 · 위키 화면 · 물어보기 설정 화면 세 곳** |
| D10 | 오래된 대화 자동 삭제 | 물어보기 설정에서 **안 함 / 30일 / 90일**. 위키는 남긴다 |
| D11 | 재동의 | 벤더를 바꿀 때만(키 입력 기획 소유). 위키 도입은 동의 문구 · 위키 화면 안내만 갱신 |
| D12 | 위키를 언제 읽나 | 모델 판단. 임시 대화는 위키 없음 |
| D13 | 이름 | 화면 · 메뉴는 **“위키”**, 버튼은 **[위키로 정리]** · **[위키에 추가]**, 대화는 **“임시 대화”** |
| D14 | 색인 상한 | 기본 **최근 수정 순 150개 · 6,000자**, 사용자가 물어보기 설정에서 바꾼다(→ [색인 크기 설정](#색인-크기-설정)) |
| D15 | 지워진 메모 · 일기로의 링크 | 본문은 그대로 두고 화면에서 **흐리게**. `read_wiki` 는 not_found(일기는 `missing`) |
| D16 | 사용량 저장 | 이 기획이 맡는다 — 요청 하나에 한 행, 13개월 보관, 물어보기 설정 › [사용량] 화면(이번 달 합계 · 모델별, 잠금 아래) |
| D19 | 화면 자리 | 설정 탭 없음(재구성 설계). 물어보기 앱바 = **[새 대화] 아이콘 + ⋮**, 이 기획의 진입점은 ⋮ 위쪽. 설정 행은 물어보기 설정 화면(잠금 아래) |
| D17 | 멈춘 답 | ‘멈춤’ 표시와 함께 저장하고 이어가기 문맥에도 넣는다. 글이 하나도 안 왔으면 질문까지 되돌려 저장 안 함 |
| D18 | 모델 바꾸기 | 대화 중 벤더 · 모델을 바꿔도 같은 대화를 이어간다(문맥을 글로 다시 채움) |

### 코드 이름(D13)

| 개념 | 이름 |
|---|---|
| 위키 메모 하나 | 엔티티 `WikiNote`, 테이블 `wiki_notes` |
| 저장소 | `WikiRepository` · `DriftWikiRepository` |
| 정리 후보 | `WikiCandidate`(new / update) |
| 위키를 요청에 붙이는 정책 | `WikiContextPolicy`, 기본 구현 `IndexAndReadPolicy`, 임시 대화용 `NoWikiPolicy` |
| 위키 도구 | `read_wiki` (`lib/domain/chat/tool/wiki_tools.dart`) |
| 정리 유스케이스 | `WikiDistiller` |
| 화면 | `WikiPage`(목록) · `WikiNotePage`(보기 · 편집) · `WikiCandidatesSheet` |
| 대화 | `Conversation` · `ChatTurnRecord`, 테이블 `conversations` · `chat_turns` |
| 임시 대화 | 상태 플래그 `temporary`, l10n `walkChatTemporary*` |
| 사용량 기록 | 계약 `ChatUsageLog` · `ChatUsageRecord`(키 입력 기획), 구현 `DriftChatUsageLog`, 테이블 `chat_usage`, 화면 `ChatUsagePage` |
| 대화 · 위키 설정 | `ChatHistorySettings`(보관 기간 · 색인 크기) |

## 1. 대화 저장 모델

### 무엇을 저장하나(D1)

| 후보 | 저장? | 이유 |
|---|---|---|
| 질문 글 | ✅ | 목록 · 다시 보기 · 이어가기 |
| 답 글(최종 텍스트) | ✅ | 다시 보기 · 이어가기 문맥 |
| 근거 일기 id(`cited`) | ✅ id 만 | 칩은 열 때 `DiaryRepository.entry` 로 다시 읽는다. 휴지통 · 지운 기록은 지금처럼 빠진다 |
| 멈춘 턴(글이 온 뒤 [■ 멈춤]) | ✅ `stopped = true` | 말풍선에 ‘멈춤’ 표시로 남고, 다음 질문 문맥에도 들어간다(D17) |
| 멈춘 턴(글이 하나도 안 옴) | ❌ | 질문까지 되돌린다 — 실패와 같게 |
| 실패한 턴 | ❌ | 세션이 이미 되돌린다 |
| 원본 메시지(thinking · 도구 호출 · 도구 결과 · `VendorTurnState`) | ❌ | 일기 본문 · 사진 사본이 일기 밖에 남고, 벤더마다 형식이 다르다 |
| 진행 노트 · 단계 요약(“기록 3번 찾아봄 · 9초”) | ❌ | 화면 상태일 뿐이다(체감 속도 기획). 다시 연 대화에는 요약 줄이 없다 |
| 사진(base64) | ❌ | 대화 하나에 최대 12장 × 수백 KB. 일기에서 지운 사진이 채팅 DB 에 남는다 |

글만 저장하므로 지난 대화를 이어갈 때 모델은 **필요한 기록을 도구로 다시 찾는다** — 원래 설계(“원본 기록을 직접
찾아보는 쪽이 정확하다”)와 같은 방향이다.

### 이어서 대화하기(D2) — 벤더를 바꿔도 이어진다

- **앱이 켜져 있는 동안 지금 대화** — 지금처럼 메모리에 원본(어댑터가 요구하는 thinking · 서명 · 사진 포함)을 들고
  이어 간다. 저장은 턴이 끝날 때마다 보이는 글만 따로 쓴다.
- **지난 대화를 열어 이어가기**(앱 재시작 뒤 · 목록에서 열기) — 저장된 턴으로 문맥을 **글만으로** 다시 채운다:
  `ChatMessage.user(질문) → ChatMessage.assistant(parts: [text(답)], vendorState: null)` 의 반복. 그 뒤에 새 질문을 덧붙인다.
  - 멈춘 턴은 받은 글 그대로 넣고 끝에 `ChatSession.stoppedNote`(`(사용자가 여기서 멈춤)`) 한 줄을 붙인다 — 모델이 끊긴 답을 완성된 주장으로 읽지 않게.
  - 최근 **20턴**만 싣는다(상수). 목록 화면에서는 전부 보인다.
  - 사진이 없으므로 **사진 수는 0부터 다시 센다.** `photo_limit_reached` 안내는 “대화를 다시 열거나 새 대화를 시작하면…”으로.
  - thinking 서명은 진행 중인 도구 루프 안에서만 필요하므로, 글만 있는 지난 턴은 어느 벤더에도 그대로 보낼 수 있다.
- **벤더 · 모델을 바꾸면(D18)** — 글만 저장하는 덕분에 지난 대화를 새 벤더 · 모델로 그대로 이어갈 수 있다. 지금 대화가 열려
  있으면 다음 질문 전에 문맥을 글로 다시 채운다(다른 벤더 · 모델의 `VendorTurnState` 는 넘기지 않는다 — 같은 벤더의 다른
  모델이면 어댑터가 알아서 text · 도구 호출만 다시 만들지만, 이 기획은 단순하게 늘 글로 다시 채운다). 임시 대화는 저장된
  턴이 없으므로 화면 말풍선(`ChatBubble`)에서 같은 방식으로 다시 채운다. 턴마다 답한 벤더 · 모델을 저장해 목록 · 사용량에 쓴다.
- `ChatSession` 에 `resume(List<ChatTurnText> turns, {required bool temporary})` 를 더한다 — `reset()` 처럼 세대를 올리고
  문맥을 글로 채운다. “지난 메시지는 고치지 않는다” 주석은 “메모리의 지금 대화는 고치지 않는다 · 저장 · 복원은 글만”으로.

### 저장소(drift)

새 DB `chat`(`driftDatabase(name: 'chat')`), `lib/data/chat/database/chat_database.dart`. 일기 DB 와 분리한다 —
일기 백업 · 휴지통 · 스키마 버전과 엮이지 않게(기상 기록과 같은 결정).

```
conversations
  id            text  pk (uuid)
  title         text
  title_edited  bool  default false   -- 사용자가 바꿨으면 자동 제목으로 덮지 않음
  created_at    datetime
  updated_at    datetime              -- 목록 정렬 · 자동 삭제 기준

chat_turns
  conversation_id  text  fk → conversations.id  on delete cascade
  seq              int
  question         text
  answer           text
  cited_entry_ids  text               -- JSON 배열
  stopped          bool  default false -- [■ 멈춤]으로 끊긴 답
  vendor           text               -- 답한 벤더 · 모델(표시 · 통계용)
  model            text
  asked_at         datetime
  pk (conversation_id, seq)

chat_usage                            -- 요청(도구 라운드) 하나에 한 행. 내용 · 대화 id 는 담지 않는다
  id                 int  pk autoincrement
  at                 datetime
  question_key       text             -- 한 질문의 라운드를 묶는 무작위 값(대화와 잇지 않음)
  vendor, model      text
  purpose            text             -- 'chat' | 'wikiDistill'
  round              int
  temporary          bool
  input_tokens       int
  output_tokens      int
  cache_read_tokens  int              -- 벤더가 안 주면 0
  cache_write_tokens int
  reasoning_tokens   int null
  wiki_index_notes   int              -- 이번 요청에 붙인 색인 메모 수(없으면 0)
  wiki_index_chars   int
  read_wiki_calls    int              -- 이 응답이 부른 read_wiki 수

wiki_notes                            -- 2단계(migration 2)
  id          int  pk autoincrement   -- 모델에게 보이는 짧은 id, [[12]]
  title       text
  summary     text                    -- 한 줄. 색인에 실린다
  body        text                    -- [[id]] · [[일기:<entryId>]] 링크 포함 가능
  source_conversation_id  text null   -- 대화가 지워지면 null
  created_at, updated_at  datetime
```

- 대화 · 위키 · 사용량을 한 DB 에 둔다(“채팅 데이터” 단위로 지우고 옮긴다).
- 위키 id 를 정수로 두는 이유: 색인 · 링크에 실려 매 요청 토큰이 되므로 짧게.

### 대화 제목

- 첫 질문의 앞 30자(줄바꿈은 공백, 넘치면 `…`). 기기 안에서만 만든다(추가 요청 · 전송 없음).
- 목록의 더보기 [이름 바꾸기]. `title_edited` 이면 자동 제목을 다시 쓰지 않는다.

### 언제 저장하나

- 턴이 **끝까지 받아지거나**, **[■ 멈춤]으로 멈췄는데 글이 조금이라도 왔으면** 그 턴 하나를 쓴다(멈춘 것은 `stopped = true`).
  대화 행은 첫 저장 턴에서 만든다(빈 대화는 목록에 안 생김). 실패 · 글 없는 멈춤은 쓰지 않는다.
- 세션 쪽 규칙도 맞춘다: 멈춤에서 글이 왔으면 그 질문의 메시지를 되돌리지 않고 **받은 글까지를 assistant 텍스트로 남긴다**
  (진행 중이던 도구 호출 · `VendorTurnState` 는 버림). 멈춤 동작 자체(취소 · 이벤트)는 체감 속도 기획 소유.
- 저장은 cubit 이 한다(세션은 저장소를 모른다). 답 글은 cubit 이 이미 delta 로 쌓아 든 말풍선 글을 쓴다.
- 사용량은 세션이 `ChatUsageLog.record` 로 요청마다 넘긴다(아래 [사용량](#사용량d16)). 임시 대화도 **숫자만**.
- 임시 대화는 `conversations` · `chat_turns` 에 아무것도 쓰지 않는다.

### 사용량(D16)

- **테이블** 위 `chat_usage`. 키 입력 기획 §9 의 `ChatUsageRecord` 필드를 그대로 받고, 이 기획이 `question_key` · `temporary` ·
  위키 숫자 세 개를 더한다(그 기획서의 `purpose: wiki` 는 이 기획의 `wikiDistill` 로 맞춘다 — 후속 라우터가 생기면 값을 더한다).
- 실패한 요청은 usage 가 없으므로 행이 없다(그 기획서 규칙). 멈춘 요청도 usage 를 못 받으면 없다.
- **보관**: 내용이 없는 숫자라 대화 보관 기간과 무관하게 **13개월**(지난해 같은 달까지 비교). 앱 시작 때 오래된 행을 지운다.
  [대화 모두 지우기] · [위키 모두 지우기]는 사용량을 지우지 않는다. 사용량 화면에 [사용량 기록 지우기]만 따로 둔다.
- **보기** — 물어보기 설정 화면 [사용량] → `ChatUsagePage`. 물어보기 설정이 잠금 아래이므로 이 화면도 `pushDiaryRoute`
  로 연다(다시 잠기면 가려진다):
  - 이번 달 합계: 질문 수 · 입력 · 출력 · 캐시 읽기 토큰. 월 넘기기(‹ ›)로 지난 달.
  - 모델별 표: 벤더 · 모델 · 질문 수 · 입력 / 출력 토큰. `purpose` 가 `wikiDistill` 인 것은 “위키 정리” 줄로 따로.
  - 위키 숫자(2단계): 질문당 평균 색인 크기, `read_wiki` 를 부른 질문 비율.
  - 금액은 보이지 않는다 — 단가가 모델마다 바뀌고 앱이 따라가기 어렵다. “요금은 각 벤더 콘솔에서 확인” 안내 한 줄.

### 오래된 대화 자동 삭제(D10)

- 물어보기 설정 화면에 **“대화 보관 기간: 안 함 · 30일 · 90일”**(기본 안 함). `SharedPreferences` 한 값.
- 앱 시작 · 복귀 때(기상 기록 보관과 같은 때) `updated_at` 이 기간보다 오래된 대화를 지운다. 위키는 남고
  `source_conversation_id` 만 null 이 된다. 사용량은 따로 13개월.
- 지금 열려 있는 대화는 지우지 않는다(다음 시작 때 판단).

## 2. 목록 · 열기 · 삭제 화면

### 진입점(물어보기 탭 앱바)

재구성 설계의 앱바 규칙(핵심 아이콘 하나 + ⋮, ⋮ 끝 두 항목 고정)을 따른다.

- 아이콘: **[새 대화]**(지금 것) 하나.
- ⋮(`AppOverflowMenu`) 위에서부터:
  1. [대화 목록] — 1단계
  2. [위키] — 2단계
  3. [위키로 정리] — 2단계, 저장된 대화가 열려 있을 때만(임시 대화 · 빈 대화에선 없음)
  4. [임시 대화로 시작] — 1단계
  5. ─ · **물어보기 설정** · **앱 설정** — 재구성 설계가 고정한 끝 두 항목. 이 기획은 위 1~4 를 그 위에 끼운다.
- 잠겨 있으면 재구성 설계대로 [새 대화]와 1~4 · 물어보기 설정을 숨기고 ⋮ 에는 “앱 설정”만 남는다.

### 대화 목록 `ChatHistoryPage`

- `pushDiaryRoute` 로 연다(일기 잠금 게이트를 함께 씌움 — 다시 잠기면 가려진다).
- 행은 `AppListTile`: 제목 · 마지막 시각(오늘이면 시:분, 아니면 날짜) · 턴 수. 최근 순.
- 행을 누르면 탭으로 돌아와 그 대화를 **불러온다**(말풍선 + 근거 칩 + ‘멈춤’ 표시 복원 → 이어서 묻기).
  지금 대화가 답하는 중이면 끊고 불러온다(`newConversation` 과 같은 규칙). 임시 대화 중이었으면 그 대화는 사라진다.
- 행 더보기(`AppOverflowMenu`): [이름 바꾸기] · [삭제] — 삭제는 `AppConfirmDialog.show` 뒤에(destructive).
  지금 열린 대화를 지우면 탭은 빈 새 대화로.
- 앱바 더보기: [대화 모두 지우기] — `AppConfirmDialog`(“대화 n개를 지웁니다. 위키는 남습니다”).
- 빈 상태: `AppPlaceholder`(“저장된 대화가 없어요”).
- 검색 · 고정 · 묶기는 안 한다(범위 밖).

### 대화 안에서

- 말풍선 길게 누르기 → 시트:
  - [이 질문과 답 지우기] — 저장된 턴 삭제, `AppConfirmDialog` 뒤에. 메모리 문맥에서도 빼야 하므로 **세션을 남은 턴으로
    `resume` 해서 다시 만든다**(서명이 있는 원본을 부분 삭제하지 않는다).
  - [위키에 추가] — 위키 편집 화면을 그 말풍선 글로 미리 채워 연다(요청 없음). 2단계.
- [위키로 정리]는 앱바 ⋮ 에 있다(위 진입점 3).

### 임시 대화(D4)

- 시작: 앱바 ⋮ [임시 대화로 시작]. 지금 대화를 닫고 빈 임시 대화를 연다.
- 표시: 입력칸 위 한 줄 배너 — “임시 대화 · 이 폰에 저장되지 않아요. 질문과 찾은 기록은 ○○(벤더)로 전송되고, 그쪽 보관
  정책은 앱이 정할 수 없어요.” 벤더 이름은 지금 설정된 벤더.
- 동작:
  - `conversations` · `chat_turns` 에 쓰지 않는다. 탭을 [새 대화] · 목록 열기 · 앱 종료로 떠나면 사라진다.
  - `WikiContextPolicy` 를 `NoWikiPolicy` 로 — 색인도 `read_wiki` 도 요청에 실리지 않는다.
  - [위키로 정리] · [위키에 추가] 숨김.
  - 벤더 서버에 대화 상태를 남기지 않는 요청(MVP 어댑터는 늘 그렇다 — [경계](#다른-기획과의-경계) 2). 벤더의 로그 보관은
    앱이 통제하지 못하므로 배너가 그렇게 말한다.
  - 사용량은 `temporary = true` 로 숫자만.
  - 일반 대화로 바꾸는 기능은 없다(임시는 임시로).
  - 다시 잠기면 가려지고 풀면 그대로(지금 규칙).
- **화면 캡처 차단**: 임시 대화가 **보이는 동안만** 창에 `FLAG_SECURE` 를 켜 스크린샷 · 화면 녹화 · 최근 앱 썸네일을 막는다.
  끄는 설정은 없다. 앱에 이미 네이티브 코드(알람)가 있으므로 `MethodChannel` 하나(`setSecure(bool)`)로 켜고 끈다.
  켜는 때: 임시 대화가 열려 있고 물어보기 탭이 보일 때. 끄는 때: 다른 탭으로 가기 · [새 대화] · 지난 대화 열기 · 탭 dispose.
  위에 푸시된 화면(근거 일기 뷰어 등)이 덮어도 켠 채 둔다(임시 대화 내용이 뒤에 있다).

## 3. 위키

### 무엇이 항목인가(D5)

**위키 메모** — 제목 · 한 줄 요약 · 본문(몇 줄)으로 된 “나에 대한 사실 하나”. 예:

```
[[3]] 출근 알람 — 평일 07:00 '출근' 라벨이 기상 알람이다.
  본문: 주말엔 울리지 않는다. 스누즈는 보통 두 번. 관련: [[7]] 수면 패턴
[[7]] 수면 패턴 — 평일 7시 전후 기상, 주말은 9시 넘어 일어난다.
  본문: 10월 기준. [[3]] 출근 알람으로 깬다. 근거: [[일기:a1b2…]]
```

- 링크 `[[id]]` 는 다른 메모로, `[[일기:<entryId>]]` 는 일기 기록으로 간다.
- 화면에서는 링크를 **칩**으로 그린다 — 메모 링크는 메모 제목, 일기 링크는 날짜 · 본문 앞부분(근거 칩과 같은 모양).
  누르면 메모는 `WikiNotePage`, 일기는 근거 칩과 같은 `openStoryViewer` 로 연다.
- **지워진 대상(D15)**: 본문의 링크는 그대로 둔다. 메모가 없으면 흐린 “지워진 메모”, 일기가 휴지통 · 삭제면 흐린 “지워진 일기”
  칩(누를 수 없음). 일기를 휴지통에서 되살리면 다시 보인다.
- 주제별 긴 문서는 만들지 않는다. 묶음은 링크와 (나중에) 태그로.

### 누가 · 언제 쓰나(D6)

**사용자가 누를 때만** 위키가 생긴다. 세 경로:

| 경로 | 요청 | 흐름 |
|---|---|---|
| **[위키로 정리]**(물어보기 앱바 ⋮) | 1번(정리 요청) | 아래 |
| [위키에 추가] — 말풍선 길게 누르기 | 없음 | 편집 화면을 그 글로 미리 채움 → 사용자가 제목 · 요약 · 본문 고쳐 저장 |
| 위키 화면 [추가] | 없음 | 빈 편집 화면 |

**[위키로 정리] 흐름** — `WikiDistiller`:

1. 모델: **지금 고른 벤더 · 모델 그대로**(D6). 키 · 모델이 없으면 버튼 대신 물어보기와 같은 안내.
2. 보내는 것: 이 대화의 저장된 턴(글만, 최근 20턴, 멈춘 턴 포함) — 턴마다 **근거 일기 id** 를 `[근거 일기: id(날짜), …]` 한 줄로
   붙인다 — + 지금 위키 **색인** + `read_wiki` 도구. 일기 도구는 싣지 않는다(대화 글에서만 뽑는다 — 새 기록을 더 읽어 오지 않게).
3. 지시: “이 대화에서 앞으로도 쓸 사용자에 대한 사실만 후보로 뽑는다. 이미 있는 메모를 고쳐야 하면 `read_wiki` 로 읽고
   update 후보로, 관련된 메모가 있으면 본문에 `[[id]]` 를, 근거가 된 일기가 있으면 `[[일기:id]]` 를 넣는다. 위에 적힌 근거
   일기 id 만 쓴다. 일기 문장을 옮겨 적지 않는다. 없으면 빈 목록.”
4. 받는 것: 후보 목록(JSON) — `{action: "new"|"update", id?, title, summary, body}`. 중립 형식에서 구조화 출력을 지원하면
   그걸 쓰고, 아니면 텍스트 JSON 을 파싱한다(파싱 실패 → “정리하지 못했어요” 스낵바). **최대 8개**(넘치면 앞 8개).
   본문의 `[[일기:id]]` 중 이 대화의 근거 id 가 아닌 것은 빼고 보인다(모델이 지어낸 id 방지). 없는 `[[id]]` 도 뺀다.
5. `WikiCandidatesSheet`: 후보마다 카드 — new 는 그대로, update 는 기존 본문과 나란히. [저장] · [고쳐서 저장] · [버림].
   다 처리하거나 시트를 닫으면 끝(남은 후보는 버림 — 보류 목록 없음).
6. 사용량은 `purpose = 'wikiDistill'` 로.

같은 대화에서 다시 누르면 다시 요청한다(이미 저장한 것은 색인에 있으므로 update 나 빈 목록이 나온다).

### 다음 대화에서 어떻게 참고하나(D7 · D8)

- 시스템 프롬프트 = **고정 규약**(지금 `_systemPrompt` 의 지시) + **위키 색인** + **오늘 날짜**(맨 뒤 — 캐시 앞부분을 덜 깨게).
  ```
  …(규약)…
  사용자가 정리해 둔 위키가 있다. 아래는 색인(id · 제목 · 한 줄 요약)이다.
  질문에 도움이 될 때만 read_wiki 로 본문을 열고, 본문의 [[id]] 링크를 따라 더 열 수 있다.
  위키와 기록 도구로 찾은 내용이 다르면 기록을 우선하고 다르다고 말한다.
  <wiki_index>
  [[3]] 출근 알람 — 평일 07:00 '출근' 라벨이 기상 알람이다.
  …
  </wiki_index>
  오늘은 …
  ```
- 도구 `read_wiki({ids: [3, 7]})` — 한 번에 최대 5개. 메모마다
  `{id, title, summary, body, links: [{id, title}], diary: [{entry_id, date}], updated}` 를 돌려준다.
  - 없는 메모 id 는 `{"id": 9, "error": "not_found"}` 항목. 본문에 남은 지워진 메모 링크는 `links` 에 `{id, missing: true}`.
  - 일기 링크는 기기에서 날짜를 찾아 `{entry_id, date}` 로 준다. 모델은 원본이 필요하면 그 날짜로 `search_diary` 를 부른다
    (`life_tools` 는 바꾸지 않는다). 휴지통 · 삭제된 일기는 `{entry_id, missing: true}`.
  - 한 질문의 `read_wiki` 호출도 기존 `maxRounds = 8` 안에서 센다.
- **색인 상한 · 정렬(D14)**: `updated_at` 최근 순, 설정값 상한(기본 **150개 · 6,000자**). 넘치면 오래된 것부터 색인에서 빠진다
  (메모는 남고, 다른 메모의 링크로는 여전히 열 수 있다). 빠진 개수는 색인 끝에 “(오래된 메모 n개 생략)”. 위키 화면에도
  “색인에 안 실린 메모” 표시. 상한을 자주 넘기면 후속으로 `search_wiki` 를 더한다.
- `WikiContextPolicy`:
  ```dart
  abstract interface class WikiContextPolicy {
    /// 이번 질문에 붙일 시스템 프롬프트 조각과 도구 정의.
    Future<WikiContext> build({required String question});
  }
  ```
  `IndexAndReadPolicy`(기본) · `NoWikiPolicy`(임시 대화 · 위키가 비었을 때). `ChatSession` 은 질문마다 정책을 부른다.
  `question` 을 받는 이유는 후속 “미리 골라 붙이기”가 같은 자리에 들어오게.
- **기록(D8)**: 요청마다 `chat_usage` 한 행에 색인 크기 · `read_wiki` 호출 수를 함께 쓴다([사용량](#사용량d16)).
  2단계 끝에 이 숫자로 후속을 판단한다.

### 색인 크기 설정

- 위치: 물어보기 설정 화면 **[위키 색인 크기]** 행(현재 값 표시) → 선택 시트. 위키 화면의 “색인에 안 실린 메모 n개” 안내에서도 연다.
- 선택지(개수 · 글자 수를 묶은 단계):

  | 단계 | 개수 | 글자 수 | 안내 |
  |---|---|---|---|
  | 작게 | 50 | 2,000 | 질문마다 보내는 양이 가장 적다 |
  | **기본** | **150** | **6,000** | |
  | 크게 | 300 | 12,000 | 메모가 많을 때. 질문마다 토큰이 는다 |
  | 모두 | 제한 없음 | 30,000 | 안전 상한. 그 이상은 잘린다 |

- 저장: `ChatHistorySettings.wikiIndexSize`(enum, prefs 한 값). 다음 질문부터 반영. 시트에 “지금 위키 n개 · 색인 약 m자” 를 보여
  고르는 근거를 준다.

### 위키 화면

- `WikiPage` — 진입: 물어보기 앱바 ⋮ [위키]. `pushDiaryRoute`(잠금 아래).
  - 목록 `AppListTile`(제목 · 한 줄 요약 · 수정일), 최근 순. 앱바 [추가] · 더보기 [위키 모두 지우기] — `AppConfirmDialog` 뒤에.
  - 빈 상태 `AppPlaceholder`(“대화에서 [위키로 정리]를 누르면 남길 내용을 골라 저장할 수 있어요”).
  - 상단 안내 한 줄: “위키 색인(제목 · 요약)은 질문할 때마다, 본문은 모델이 필요할 때 ○○(벤더)로 보내져요. 임시 대화에는
    보내지 않아요.”
- `WikiNotePage` — 보기(링크 칩, [이 메모를 가리키는 메모] 역링크 목록) · [편집] · [삭제] — `AppConfirmDialog` 뒤에.
  편집은 제목 · 요약 · 본문 칸 + 두 버튼:
  - [메모 링크] — 메모 고르기 시트(제목 검색) → `[[id]]` 삽입.
  - [일기 링크] — 일기 고르기 시트 → `[[일기:id]]` 삽입. 시트 위쪽은 출처 대화의 근거 일기, 아래는 날짜를 골라 그날의 기록
    목록(일기 저장소 `searchEntries` 재사용). 잠금 아래 화면이므로 일기를 보여도 된다.
  출처 대화가 남아 있으면 [대화 보기].

## 4. 무엇이 어디 남나

| 데이터 | 벤더로 전송 | 기기에 저장 | 임시 대화에서 |
|---|---|---|---|
| 질문 글 | ✅ 매 요청(문맥으로 반복) | ✅ `chat_turns` | 전송 ✅ · 저장 ❌ |
| 답 글 | ✅ 이어가는 요청의 문맥 | ✅ `chat_turns` | 전송 ✅ · 저장 ❌ |
| thinking · 도구 호출 · 도구 결과(일기 본문 · 걸음 · 기상) | ✅ 그 대화가 메모리에 있는 동안 | ❌ 메모리만 | 같음 |
| 사진(도구 결과 이미지) | ✅ 메모리 대화 동안, 최대 12장 | ❌ | 같음 |
| 멈춘 답 글 | ✅ 이어가는 요청의 문맥(멈춤 표시와 함께) | ✅ `chat_turns.stopped` | 전송 ✅ · 저장 ❌ |
| 진행 노트 · 단계 요약 | (진행 노트는 모델이 쓴 것) | ❌ 화면 상태만 | 같음 |
| 근거 일기 id | [위키로 정리] 때만(id · 날짜) | ✅ id 만 | 저장 ❌ |
| 위키 색인(제목 · 요약) | ✅ 모든 질문의 시스템 프롬프트 | ✅ `wiki_notes` | **전송 ❌** |
| 위키 본문 · 일기 링크(id · 날짜) | ✅ 모델이 `read_wiki` 로 열 때 · [위키로 정리] 때 | ✅ | **전송 ❌** |
| [위키로 정리] 후보 | ✅(모델이 만든 응답) | 사용자가 저장한 것만 | 기능 없음 |
| 대화 제목 · 보관 기간 · 색인 크기 설정 | ❌ | ✅ | — |
| 사용량 숫자 | ❌ | ✅ `chat_usage`(내용 · 대화 id 없음), 13개월 | ✅ 숫자만 |
| 벤더 쪽 보관 | 벤더 정책(앱이 통제 못 함) | — | 대화 상태는 안 남김(어댑터 원칙), 로그 보관은 배너로 안내 |
| 화면 캡처 · 최근 앱 썸네일 | — | (안드로이드가 남김) | **`FLAG_SECURE` 로 막음** |

## 5. 잠금

- 대화 목록 · 지난 대화 · 위키 화면은 모두 **잠금 아래**(`DiaryLockGate` 안 · `pushDiaryRoute`). 내용이 일기에서 나왔고,
  위키는 일기보다 더 압축된 개인 정보다. 잠금은 재구성 설계대로 일기 · 물어보기 공용 하나(“잠금”).
- **물어보기 설정 화면은 화면 전체가 잠금 아래**(재구성 설계 §6). 그래서 이 기획이 그 화면에 더하는 행 — 보관 기간 · 색인 크기 ·
  사용량 · 대화 / 위키 모두 지우기 — 과 거기서 여는 `ChatUsagePage` · 색인 크기 시트도 모두 잠금 아래다. 앞 판(내용이 없으니
  잠금 밖)보다 엄격한 쪽을 따른다. 잠긴 채 앱 설정 › 물어보기 설정 바로가기를 누르면 잠금 화면을 먼저 거친다.
- 다시 잠겨도 지금 대화(임시 포함)는 비우지 않는다 — 가려졌다가 풀면 그대로.
- 잠금이 꺼져 있으면 아무 잠금 없이 보인다(일기와 같은 수준). 채팅 전용 잠금은 두지 않는다.

## 6. 물어보기 설정 화면에 더할 것(재구성 · 키 입력 기획과 겹침)

물어보기 설정 화면은 [재구성 설계](2026-11-01-walk-nav-regroup-design.md)가 만든다 — 물어보기 ⋮ “물어보기 설정”, 키 없음
안내의 [설정 열기], 앱 설정의 바로가기로 들어오는 push 화면이고, 안에서 기존
[chat_settings_section.dart](../../../apps/walk/lib/presentation/settings/widget/chat_settings_section.dart)(키 · 벤더 · 모델 행)를
**고치지 않고 재사용**한다. 이 기획은 그 섹션을 건드리지 않고, 같은 화면에서 그 **아래**에 새 섹션
`ChatHistorySettingsSection`(`lib/presentation/settings/widget/chat_history_settings_section.dart`)을 붙인다:

- 대화 보관 기간(안 함 · 30일 · 90일) — 1단계
- 사용량(→ `ChatUsagePage`) — 1단계
- [대화 모두 지우기] — 1단계, `AppConfirmDialog`
- 위키 색인 크기(→ 선택 시트) — 2단계
- [위키 모두 지우기] — 2단계, `AppConfirmDialog`

> ⚠️ **겹침**: 물어보기 설정 화면 파일은 재구성 쪽이 만들고, `ChatSettingsSection` 내부 · [secure_chat_settings.dart](../../../apps/walk/lib/data/chat/secure_chat_settings.dart) ·
> 동의 문구는 [키 입력 · 멀티 벤더 기획](2026-11-01-walk-chat-key-input.md)이 고친다. 이 기획은 별도 섹션 위젯 하나와 그 화면에
> 한 줄(섹션 끼우기)만 더한다. 보관 기간 · 색인 크기는 `ChatSettings` 가 아닌 별도 `ChatHistorySettings`(prefs 값 둘)로 두어
> 인터페이스 충돌을 피한다.
> API 키를 지우거나 벤더를 바꿔도 대화 · 위키는 남는다.

## 7. 바꿀 · 더할 파일

`lib/` 와 `test/` 는 같은 구조. 생성 파일(`.g.dart` · `.freezed.dart` · `injection.config.dart`)은 build_runner 로.
중립 메시지 · 어댑터 파일은 키 입력 기획 소유라 여기 적지 않는다.

**domain**

- `lib/domain/chat/entity/conversation.dart` — `Conversation` · `ChatTurnRecord`(`stopped` 포함, Freezed primary constructor).
- `ChatUsageRecord` · `ChatUsageLog` 는 키 입력 기획이 만든다. 이 기획은 필드(`questionKey` · `temporary` · 위키 숫자)를 더하고
  읽기용 `lib/domain/chat/repository/chat_usage_repository.dart`(월 합계 · 모델별 · 오래된 행 지우기 · 모두 지우기)를 둔다.
- `lib/domain/chat/entity/wiki_note.dart` — `WikiNote` · `WikiCandidate`(union: `.create` / `.update`) · 링크 파서(`[[id]]` · `[[일기:id]]`).
- `lib/domain/chat/repository/chat_history_repository.dart` — `conversations()`(Stream) · `turns(id)` · `appendTurn` · `rename` ·
  `deleteTurn` · `delete` · `deleteAll` · `deleteOlderThan(DateTime)`.
- `lib/domain/chat/repository/wiki_repository.dart`.
- `lib/domain/chat/chat_history_settings.dart` — 보관 기간 · 색인 크기(`WikiIndexSize` enum).
- `lib/domain/chat/wiki/wiki_context_policy.dart` — 인터페이스 · `IndexAndReadPolicy` · `NoWikiPolicy`.
- `lib/domain/chat/tool/wiki_tools.dart` — `read_wiki` 정의 · 실행.
- `lib/domain/chat/usecase/wiki_distiller.dart`
- `lib/domain/chat/usecase/chat_history_pruner.dart` — 보관 기간 지난 대화 · 13개월 지난 사용량 지우기(앱 시작 · 복귀).
- `lib/domain/chat/usecase/chat_session.dart` — `resume(turns, temporary:)`(멈춘 턴 표시 줄 포함), 질문마다 `WikiContextPolicy` 호출,
  시스템 프롬프트에 색인 · 날짜 배치, 요청마다 `ChatUsageLog.record`(question_key · temporary · 위키 숫자), 멈춤에서 받은 글을
  남기는 규칙, `_photoLimitJson` 힌트 문구.

**data**

- `lib/data/chat/database/chat_database.dart`(+ `.g.dart`) — 1단계 `schemaVersion 1`(`conversations` · `chat_turns` · `chat_usage`),
  2단계 `2`(`wiki_notes`) + migration.
- `lib/data/chat/database/drift_chat_history_repository.dart` · `drift_wiki_repository.dart` ·
  `drift_chat_usage_log.dart`(`ChatUsageLog` + `ChatUsageRepository` 구현 — 키 입력 기획의 `NoopChatUsageLog` 를 대신한다).
- `lib/data/chat/prefs_chat_history_settings.dart`
- `lib/data/chat/secure_window.dart` — `MethodChannel` 로 `FLAG_SECURE` 켜고 끄기(domain 인터페이스 `SecureWindow`).
- `lib/core/di/register_module.dart` — `ChatDatabase(driftDatabase(name: 'chat'))` 등록 · dispose.
- 앱 시작 · 복귀 훅(기상 기록 보관을 부르는 곳)에서 `ChatHistoryPruner` 호출.
- 안드로이드 `MainActivity` — `setSecure` 채널 처리(`window.addFlags/clearFlags(FLAG_SECURE)`).

**presentation**

- `lib/presentation/chat/cubit/chat_cubit.dart` · `chat_state.dart` — `conversationId` · `temporary` 상태, `open(id)` · `startTemporary()` ·
  `deleteTurn(seq)`, 턴 끝 저장, 벤더 변경 시 글로 다시 채우기.
- `lib/presentation/chat/page/chat_tab.dart` — 앱바 액션 · 임시 배너 · `FLAG_SECURE` 켜고 끄기(탭 보임 · 임시 여부에 따라).
- `lib/presentation/chat/page/chat_history_page.dart` + `cubit/chat_history_cubit.dart`.
- `lib/presentation/chat/widget/bubble_actions_sheet.dart` · `chat_bubble_view.dart`(길게 누르기 · 복원된 ‘멈춤’ 표시).
- `lib/presentation/chat/wiki/page/wiki_page.dart` · `wiki_note_page.dart` · `cubit/wiki_cubit.dart` · `cubit/wiki_note_cubit.dart` ·
  `widget/wiki_candidates_sheet.dart` · `widget/wiki_link_text.dart`(메모 · 일기 링크 칩, 지워진 대상 흐리게) ·
  `widget/wiki_note_picker_sheet.dart` · `widget/diary_entry_picker_sheet.dart` · `cubit/wiki_distill_cubit.dart`.
- `lib/presentation/settings/widget/chat_history_settings_section.dart`(새) · `widget/wiki_index_size_sheet.dart` ·
  `lib/presentation/settings/page/chat_usage_page.dart` + `cubit/chat_usage_cubit.dart`.
- 재구성이 만든 물어보기 설정 화면(`lib/presentation/settings/page/` 아래, 이름은 재구성 쪽) — 섹션 한 줄 끼우기(**겹침**).
  `chat_settings_section.dart` 는 고치지 않는다.
- `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` — `walkChatHistory*` · `walkChatWiki*` · `walkChatTemporary*` · `walkChatUsage*`.

**테스트**

- `test/data/chat/database/*_test.dart` — 메모리 DB: cascade 삭제, 정렬, 제목 편집 보존, `stopped` 저장 · 복원, 대화 모두 지우기가
  위키 · 사용량을 안 지움, `deleteOlderThan` 이 위키의 `source_conversation_id` 를 null 로, 사용량 월 합계 · 모델별 집계, migration 1 → 2.
- `test/data/chat/secure_window_test.dart` — 채널 호출(mock `MethodChannel`).
- `test/domain/chat/usecase/chat_session_test.dart` — `resume` 이 글만으로 문맥을 만든다(`vendorState` · 이미지 없음), 멈춘 턴 표시 줄,
  20턴 자르기, 사진 수 0, 벤더 · 모델을 바꾼 뒤 이어가기, 멈춤에서 글이 있으면 남기고 없으면 되돌림, 임시 대화에 위키 색인 ·
  `read_wiki` 없음, 정책 결과가 시스템 프롬프트 · 도구에 들어감, 요청마다 사용량 기록(임시는 `temporary`).
- `test/domain/chat/wiki/wiki_context_policy_test.dart` — 색인 정렬 · 단계별 상한(작게 · 기본 · 크게 · 모두) · 생략 표시, 빈 위키면 도구 없음.
- `test/domain/chat/tool/wiki_tools_test.dart` — 5개 상한, not_found, 지워진 메모 링크 `missing`, 일기 링크 날짜 · 휴지통 `missing`.
- `test/domain/chat/usecase/wiki_distiller_test.dart` — 근거 일기 id 줄 포함, 후보 파싱 · 8개 상한 · 파싱 실패, 근거가 아닌 일기 링크 ·
  없는 메모 링크 제거, 일기 도구 미포함, 사용량 `wikiDistill`.
- `test/domain/chat/usecase/chat_history_pruner_test.dart` — 안 함 · 30 · 90일, 열린 대화 제외, 사용량 13개월.
- `test/domain/chat/entity/wiki_note_test.dart` — 링크 파서.
- `test/presentation/chat/cubit/*_test.dart` — 끝난 턴 · 글 있는 멈춘 턴만 저장, 임시 대화 저장 0, 열기 → 말풍선 · 멈춤 복원,
  턴 삭제 → resume, 후보 저장 / 고쳐 저장 / 버림, 위키 CRUD, 임시 대화 보임 여부에 따른 `SecureWindow` 켜고 끄기.
- `test/presentation/chat/page/chat_history_page_test.dart` · `chat_tab_test.dart`(앱바 · 임시 배너 · 잠금 시 숨김) ·
  `test/presentation/chat/wiki/page/*_test.dart` · `test/presentation/chat/wiki/widget/wiki_link_text_test.dart`(흐린 칩).
- `test/presentation/settings/widget/chat_history_settings_section_test.dart` — 보관 기간 · 색인 크기 · 두 모두 지우기 확인.
- `chat_tab_test.dart` 에 ⋮ 순서(대화 목록 · 위키 · 위키로 정리 · 임시 대화로 시작 · ─ · 물어보기 설정 · 앱 설정)와 잠긴 동안 “앱 설정”만.
- `test/presentation/settings/page/chat_usage_page_test.dart` · `cubit/chat_usage_cubit_test.dart` — 이번 달 · 지난 달 · 모델별 · 위키 정리 줄.

## 8. 단계

선행 ①: **화면 재구성**(하단 탭 3개 · 설정 탭 삭제 · 앱바 ⋮ 규칙 · 물어보기 설정 화면)이 먼저 들어간다. 이 기획은 그 앱바 ⋮ 와
물어보기 설정 화면에 항목을 끼운다.
선행 ②: 키 입력 기획의 **벤더 중립 계약**(§8 메시지 · 도구 형식, `TokenUsage`, §9 `ChatUsageLog` 계약)이 먼저 들어간다.
1단계는 그 계약 위에 짓는다(Claude 어댑터 하나로도 시작할 수 있다). 멈춤 저장은 체감 속도 기획의 [■ 멈춤]이 들어온 뒤에
켜진다 — 그 전에는 `stopped` 가 늘 false.

**1단계 — 대화 기록 · 임시 대화 · 사용량**
`chat` DB(`conversations` · `chat_turns` · `chat_usage`) · 턴 끝 저장(멈춘 턴 포함) · 목록(열기 · 이름 바꾸기 · 삭제 · 모두 지우기) ·
이어가기(`resume`, 벤더 · 모델 변경 포함) · 턴 지우기 · 임시 대화(배너 · `FLAG_SECURE` · 사용량 숫자만) · 보관 기간 자동 삭제 ·
`DriftChatUsageLog` + 사용량 화면 · 물어보기 설정 행(보관 기간 · 사용량 · 대화 모두 지우기) · 앱바 ⋮ 항목. 사용량은 위키 전 **기준선**을 재려고 1단계에 넣는다.

완료 조건
- [ ] 질문 → 답이 끝나면 목록에 대화가 생기고, 앱을 다시 켜도 남는다. 실패한 질문은 저장되지 않는다
- [ ] 글이 온 뒤 [■ 멈춤]한 답은 ‘멈춤’ 표시로 저장 · 복원되고 다음 질문 문맥에 들어간다. 글 없이 멈추면 질문까지 남지 않는다
- [ ] 지난 대화를 열면 말풍선 · 근거 칩이 복원되고, 이어 물으면 모델이 앞 대화를 안다(기기에서 실제 키로)
- [ ] 대화 중 모델을 바꾸거나 Claude ↔ GPT 를 바꾼 뒤에도 같은 대화를 이어 물을 수 있다
- [ ] 이어간 대화에서 사진 한도가 0부터 다시 센다
- [ ] 삭제 · 모두 지우기(목록 · 물어보기 설정)는 `AppConfirmDialog` 뒤에만
- [ ] 물어보기 ⋮ 에 [대화 목록] · [임시 대화로 시작]이 끝 두 항목(물어보기 설정 · 앱 설정) 위에 있고, 잠긴 동안엔 “앱 설정”만 보인다
- [ ] 물어보기 설정의 대화 행 · 사용량 화면은 잠금이 풀려야 보인다
- [ ] 임시 대화는 `conversations` · `chat_turns` 에 아무것도 남기지 않고, 배너에 전송 · 벤더 보관 안내가 보인다
- [ ] 임시 대화가 보이는 동안 스크린샷이 막히고 최근 앱 썸네일이 가려진다. 다른 탭 · 일반 대화에선 풀린다(기기)
- [ ] 보관 기간 30일이면 31일 지난 대화가 다음 시작 때 사라진다
- [ ] 목록 · 지난 대화는 일기 잠금 아래에서만 보인다
- [ ] 요청마다 `chat_usage` 한 행(임시는 숫자만), 사용량 화면에 이번 달 합계 · 모델별 표가 보인다

**2단계 — 위키**
`wiki_notes`(migration 2) · 위키 화면(목록 · 보기 · 편집 · 메모 · 일기 링크 넣기 · 역링크 · 흐린 링크 · 모두 지우기 세 곳 완성) ·
[위키에 추가] · `WikiContextPolicy` + 색인 주입 + `read_wiki` · 색인 크기 설정 · [위키로 정리] + 후보 시트 · 위키 안내 문구 ·
사용량에 위키 숫자.

완료 조건
- [ ] [위키로 정리]를 누르기 전에는 위키가 생기지 않고, 후보는 [저장] · [고쳐서 저장]한 것만 남는다
- [ ] 저장한 위키를 다음 대화에서 모델이 쓴다(“출근 알람 몇 시에 울렸어?”가 라벨 설명 없이 통한다) — `read_wiki` 기록으로 확인
- [ ] “안녕” 같은 일상 질문에는 `read_wiki` 를 부르지 않는다(사용량 기록으로 확인)
- [ ] 본문의 `[[id]]` · `[[일기:id]]` 가 칩으로 보이고 누르면 그 메모 · 일기가 열린다. 지워진 대상은 흐리게 남는다
- [ ] 모델이 링크를 따라 다른 메모를 열고, 일기 링크의 날짜로 원본을 다시 찾는다
- [ ] [위키로 정리] 후보는 8개를 넘지 않고, 근거 일기 링크를 달고 나온다
- [ ] 임시 대화 요청에는 색인 · `read_wiki` 가 없다(테스트로 요청 본문 확인)
- [ ] 색인이 설정한 상한(기본 150개 · 6,000자)을 넘으면 오래된 것이 빠지고 생략 표시가 붙는다. 설정을 바꾸면 다음 질문부터 반영된다
- [ ] 위키 화면은 잠금 아래, 모두 지우기 세 곳이 각각 동작한다

## 후속 후보(이번엔 안 함)

2단계의 사용량 숫자(질문당 토큰 · 색인 크기 · `read_wiki` 비율)를 보고 고른다.

- **위키 미리 골라 붙이기** — 싼 모델이 질문과 색인만 보고 관련 메모 id 를 고르면, 그 본문을 시스템 프롬프트에 붙여 큰 모델의
  `read_wiki` 라운드를 줄인다. `WikiContextPolicy` 의 새 구현으로 들어간다.
- **질문 난이도별 모델 라우팅** — 일상 · 짧은 질문은 싼 모델, 기간 요약 · 사진 질문은 큰 모델. 같은 벤더 안에서 고른다.
- `search_wiki(query)` — 색인 상한을 자주 넘길 때.
- 위키 태그 · 묶음 보기, 위키 내보내기.

## 문서 갱신(구현 때)

- [walk 계획](../../../apps/walk/docs/plan.md) — “범위 밖”에서 “대화 저장 · 여러 대화” 삭제(일기 쓰기 도구 · 이미지 첨부는 남김),
  물어보기 절의 “대화는 메모리에만 있고 저장하지 않는다” · 사진 한도 문장 고치기, “규약” 절의 “아직 안 함” 문단을 위키 색인 ·
  `read_wiki` · `WikiContextPolicy` 설명으로 바꾸기, 화면 표에 대화 목록 · 위키 · 사용량 행 추가.
- [물어보기 설계](2026-10-27-walk-life-chat-design.md) — “빌더에게 맡기는 것”의 대화 저장 방식 · “이후(위키로 가는 길)”에 이 문서 링크.
- `apps/walk/docs/status.md` · `history.md` · `testing.md` — 단계마다(CLAUDE.md 규칙).

## 열린 질문

없음. 이전 열린 질문 1~8 은 D4 · D5 · D6 · D14 · D15 와 임시 대화 절로 결정됐다(2026-11-01).

## 다른 기획과 겹치는 곳

- **[하단 탭 재구성 · 설정 분산](2026-11-01-walk-nav-regroup-design.md)** — **먼저 들어간다.** 겹치는 파일:
  - `lib/presentation/chat/page/chat_tab.dart` — 재구성이 앱바를 [새 대화] + ⋮(물어보기 설정 · 앱 설정)로 바꾸고, 이 기획이 ⋮ 위쪽에
    [대화 목록] · [위키] · [위키로 정리] · [임시 대화로 시작]과 임시 배너 · `FLAG_SECURE` 를 더한다.
  - `lib/presentation/shell/page/main_shell_page.dart` — 재구성이 탭 · ⋮ 콜백 · 설정 push 를 바꾼다. 이 기획은 셸을 직접 고치지
    않는 것을 목표로 하되, 셸이 `ChatTab` 에 넘기는 콜백(설정 열기 등)이 바뀌면 그대로 따른다. `FLAG_SECURE` 를 끄는 “다른 탭으로
    감” 신호는 지금처럼 `ChatTab.active` 로 받는다.
  - 물어보기 설정 화면 — 재구성이 만들고 `ChatSettingsSection` 을 내부 수정 없이 재사용한다. 이 기획은 그 아래 `ChatHistorySettingsSection` 만 끼운다.
- **[키 입력 · 멀티 벤더](2026-11-01-walk-chat-key-input.md)**: 벤더 중립 계약 · `ChatUsageLog` 계약(선행), 물어보기 설정 화면 행 배치,
  동의 문구 · 재동의. 이 기획 쪽에서 맞춰 달라고 할 것 — `ChatUsageRecord` 에 `questionKey` · `temporary` · 위키 숫자 필드 추가,
  `purpose` 값 `wiki` → `wikiDistill`, 후속 벤더 어댑터도 서버에 대화 상태를 남기지 않는 원칙, (선택) 시스템 프롬프트 고정/가변 분리.
  보관 기간 · 색인 크기는 별도 `ChatHistorySettings` 로 두어 `ChatSettings` 를 건드리지 않는다.
- **[체감 속도](2026-11-01-walk-chat-streaming-ux.md)**: [■ 멈춤]의 취소 · 이벤트는 그 기획 소유. 이 기획은 멈춘 턴의 세션 문맥 규칙
  (받은 글만 남김)과 저장(`stopped`)을 정한다 — 세션 쪽 규칙은 두 기획 중 먼저 구현하는 쪽이 넣는다. 진행 노트 · 단계 요약은
  저장하지 않는다.
