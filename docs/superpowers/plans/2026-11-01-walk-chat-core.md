# walk 물어보기 — 중립 계약 · 계측 · 멈춤 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 물어보기의 모델 계약을 벤더 중립 형식으로 바꾸고(Claude 어댑터 이전, 동작 그대로) 요청마다 토큰 사용량을 계약으로 넘기며, 디버그 · 프로필 빌드에서 질문 하나의 시간 흐름을 한 줄로 남기고, 답하는 중에 [■ 멈춤]으로 HTTP 까지 끊으면서 받은 글은 '멈춤' 표시로 남긴다.

**Architecture:** `lib/domain/chat/chat_model.dart` 를 중립 형식(`ChatMessage` · `AssistantPart` · `ToolSpec` · `ModelEvent` · `ModelRequest` · `TokenUsage`)으로 다시 쓰고, Anthropic JSON 은 `AnthropicChatModel` 안으로만 옮긴다(벤더 전용 턴 데이터는 불투명한 `VendorTurnState`). `ChatSession` 은 중립 메시지만 들고, 라운드마다 `ChatUsageLog` 에 사용량을 넘기며, 모델 구독을 직접 쥐고 있다가 `reset()` · `stop()` 때 끊는다. 어댑터는 구독이 취소되면 `AbortableRequest` 로 연결을 닫는다. 계측은 domain 계약 `ChatTrace` + data 구현 `DevChatTrace`(릴리스면 `NoopChatTrace`)를 model · session · cubit 이 같이 쓴다.

**Tech Stack:** Flutter · flutter_bloc · Freezed 3 · injectable/get_it · `package:http` 1.6(`AbortableRequest`) · gen-l10n(`packages/l10n`, 기준 `app_ko.arb`) · `dart:developer`.

**Spec:**
- [키 입력 · 멀티 벤더 기획](../specs/2026-11-01-walk-chat-key-input.md) §8 · §9 · §11 · §12 · §14 의 **① 단계**
- [체감 속도 기획](../specs/2026-11-01-walk-chat-streaming-ux.md) **1단계 계측**(§2) · **2단계 멈춤 + 취소 계약**(§5.2 · §6)
- [대화 기록 · 위키 기획](../specs/2026-11-01-walk-chat-history-wiki.md) "다른 기획과 겹치는 곳" 의 계약 요청(`ChatUsageRecord` 필드 · `wikiDistill` · 멈춘 턴 문맥 규칙)
- 선행: [하단 탭 재구성 계획](2026-11-01-walk-nav-regroup.md) — Task 7 은 재구성이 병합된 뒤에 한다

## Global Constraints

- 경로는 `apps/walk/` 기준. 테스트는 `test/` 아래 같은 구조(`lib/domain/chat/x` ↔ `test/domain/chat/x`).
- Freezed(CLAUDE.md): 단일 모델은 Freezed 3 primary constructor(`@freezed class X with _$X { @override final …; const X({…}); }` — 지금 `ToolResult` 모양), 변형은 `sealed class` + named factory. 분기는 `switch` 패턴 매칭(`when`/`map` 금지).
- 생성 파일(`.freezed.dart` · `injection.config.dart`)은 손으로 고치지 않는다 — `cd apps/walk && dart run build_runner build --delete-conflicting-outputs`.
- **저장소 전체 포맷 금지.** `dart format` 은 이 task 가 만든 · 고친 파일에만.
- UI 규칙(CLAUDE.md): 공통 위젯(`AppSnackBar.show` 등) 우선, `Colors.*` · 숫자 여백 · `BorderRadius.circular(n)` 금지 — `AppSpacing` · `AppRadius` · `Theme.of(context)`.
- 문구는 l10n 만. 새 키는 `app_ko.arb` · `app_en.arb` · `app_ja.arb` 셋 다, 그 뒤 `cd packages/l10n && flutter gen-l10n`.
- **키 · 질문 · 답 · 도구 입력값은 예외 · 로그 · 계측 · `toString` 어디에도 남기지 않는다.** 새 타입에도 "toString 에 키 없음" 테스트를 둔다.
- Task 1~6 은 화면을 바꾸지 않는다(사용자 눈에 동작 그대로). 모델 id 는 지금 값 `claude-opus-5-5` 그대로, `effort: low` · `fallbacks` · beta 헤더도 그대로.
- 범위 밖(이 계획에서 하지 않음): 키 UX · 마스킹 · glow(키 기획 ②), 모델 목록 · 칩 · 빠른 출력(③), GPT 어댑터(④), 대화 기록 DB · 위키, 진행 줄 UI · `display: updates` · 프롬프트 캐시 · 도구 병렬(체감 속도 3 · 4단계).
- 매 task 끝: `cd apps/walk && flutter analyze && flutter test` 0 오류 · 전체 통과. 커밋은 task 마다 하나.

## Review Focus

1. **동작 불변(Task 2)** — Anthropic 요청 본문이 전환 전과 같다: user 글은 문자열 content, 지난 assistant 턴은 thinking · 서명 블록까지 원본 그대로, `tool_result` 블록(`is_error` · text · base64 image) 모양 그대로. 어댑터 테스트가 전환 전 JSON 과 비교한다.
2. **취소가 실제로 빠르다(Task 5)** — `async*` 세션 스트림을 취소해도 생성기는 다음 `yield` 까지 멈추지 않는다. 그래서 세션이 모델 구독을 **직접** 끊어야 하고, 어댑터는 `send` 를 기다리는 중(상태 줄 전)에도 abort 를 즉시 건다. "이벤트를 하나도 안 받은 채 취소" 테스트가 있어야 한다.
3. **멈춤 뒤 기록 꼬리(Task 6)** — 앞선 기록(서명 블록 포함)은 한 바이트도 안 바뀌고, 꼬리만 `user(질문)` + `assistant(글 + 멈춤 표시, vendorState 없음)` 로 바뀐다. 글이 없으면 질문까지 사라진다. 사진 수도 되돌린다.
4. **경쟁(Task 6 · 7)** — 답이 막 끝나 인용을 읽는 중(`_finishing`)이나 세션이 이미 끝난 뒤의 `stop()` 은 아무것도 지우지 않는다(`ChatStopResult.idle`). 멈춘 직후 `send` 가 `StateError` 없이 된다.
5. **계측은 릴리스에 없다(Task 4)** — DI 가 `kReleaseMode` 면 `NoopChatTrace`, `enabled == false` 면 호출부가 데이터 맵조차 만들지 않는다. 기록 데이터는 허용 키만 남는다.

## 구현 전 확인

live 문서가 필요한 "(확인 필요)" 항목. 어느 것도 단위 테스트를 막지 않게 설계했다 — 결과는 Task 8 에서 walk `history.md` 에 남긴다.

| # | 확인할 것 | 필요한 task | 막히지 않게 한 설계 |
|---|---|---|---|
| C1 | Anthropic 사용량 위치 — `message_start.message.usage`(`input_tokens` · `cache_creation_input_tokens` · `cache_read_input_tokens`) + `message_delta.usage.output_tokens`(누적) | Task 2 | 필드가 없거나 타입이 다르면 `usage: null`(답은 실패시키지 않음). 사용량 기록은 null 이면 건너뜀 |
| C2 | Messages API 에 요청 단위 "서버 저장" 옵션이 새로 생겼는지(키 기획 §10.3-1) | Task 2 | 없음을 어댑터 주석 + "요청 본문에 `store` 류 필드 없음" 테스트로 명시. 생겼으면 그때 추가 |
| C3 | dart:io `IOClient` 에서 `AbortableRequest` abort 가 소켓을 실제로 닫는지, 연결을 끊으면 Anthropic 이 생성 · 청구를 멈추는지(체감 속도 §5.2 · §6.4) | Task 5 | 단위 테스트는 "abort 트리거 완료 · 이후 이벤트 없음"까지. 실제 닫힘은 Task 4 계측의 `abort` 표시 + 콘솔 usage 로 기기에서 확인 |
| C4 | thinking 이 기본(adaptive)인 Opus 5.5 대화에 thinking 블록 없는 글만의 assistant 턴을 넣어도 400 이 안 나는지(체감 속도 §6.2 확인 항목, 기록 기획 "글만으로 다시 만들기"와 같은 질문) | Task 6 | 단위 테스트는 중립 형식까지. 기기에서 "멈춤 → 다음 질문"으로 확인. 400 이 나면 history 에 적고 사용자에게 묻는다(대안: 멈춘 턴을 user 쪽 메모로 넣기) |
| C5 | `package:http` `MockClient` 가 `AbortableRequest` 를 그대로 넘기는지 | Task 5 | 쓰지 않는다 — 테스트는 `BaseClient` 를 상속한 손 가짜로 요청 객체를 직접 잡는다 |

---

### Task 1: SSE 줄 헬퍼 분리

순수 리팩터링. `AnthropicChatModel._parse` 의 줄 나누기 · 대기 시간 · `event:`/`data:` 모으기를 공용 헬퍼로 뺀다(④ 의 GPT 어댑터가 같은 헬퍼를 쓴다).

**Files:**
- Create: `lib/data/chat/sse_lines.dart`
- Modify: `lib/data/chat/anthropic_chat_model.dart` — `_parse` 가 `sseEvents(...)` 를 소비
- Test: `test/data/chat/sse_lines_test.dart`(새) · `test/data/chat/anthropic_chat_model_test.dart`(그대로 통과해야 함)

**Interfaces:**
- Produces:
  ```dart
  /// SSE 이벤트 하나. `event:` 가 없거나 data 가 없는 덩어리는 내지 않는다.
  @freezed
  class SseEvent with _$SseEvent {
    @override
    final String event;
    /// 여러 `data:` 줄은 '\n' 으로 잇는다. 앞 공백 하나는 뗀다.
    @override
    final String data;
    const SseEvent({required this.event, required this.data});
  }

  /// UTF-8 → 줄 → 빈 줄마다 이벤트. 줄 사이가 [idleTimeout] 을 넘으면 TimeoutException.
  /// 스트림 끝에 남은 덩어리도 낸다. `:` 로 시작하는 주석 줄은 버린다.
  Stream<SseEvent> sseEvents(Stream<List<int>> bytes, {required Duration idleTimeout});
  ```
- Consumes: 없음.

- [ ] **Step 1: 실패하는 테스트** — `sse_lines_test.dart`:
  - `한 이벤트의 event 와 data 를 낸다` — `event: a\ndata: {"x":1}\n\n` → `[SseEvent(event: 'a', data: '{"x":1}')]`.
  - `여러 data 줄은 줄바꿈으로 잇는다` — `data: 1` · `data: 2` → `'1\n2'`.
  - `event 가 없거나 data 가 없으면 내지 않는다`.
  - `UTF-8 이 바이트 중간에서 잘려도 복원한다` — `'한'` 의 3바이트를 두 덩어리로.
  - `끝에 빈 줄 없이 끝나도 남은 이벤트를 낸다`.
  - `주석 줄(:)은 버린다`.
  - `줄 사이가 idleTimeout 을 넘으면 TimeoutException` — `StreamController` 로 첫 줄 뒤 멈춤, `idleTimeout: 10ms`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/data/chat/sse_lines_test.dart` → `sse_lines.dart` 없음으로 FAIL.
- [ ] **Step 3: 구현** — 헬퍼를 만들고 어댑터의 `lines` · `dispatch()` 를 `await for (final e in sseEvents(bytes, idleTimeout: idleTimeout))` + JSON 처리로 바꾼다. 예외 매핑(`TimeoutException` · `SocketException` · `ClientException` → network, `TypeError` · `FormatException` → server)은 어댑터에 그대로. build_runner.
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → 기존 `anthropic_chat_model_test.dart` 15건 포함 PASS.
- [ ] **Step 5: 커밋** — `refactor(walk): 물어보기 SSE 줄 읽기를 공용 헬퍼로 뺀다`

### Task 2: 벤더 중립 채팅 계약 + Claude 어댑터 이전

키 기획 ①의 본체. 계약이 바뀌는 순간 어댑터 · 세션 · 도구가 함께 바뀌어야 컴파일되므로 한 task 다. 사용량은 `completed.usage` 로 **파싱만** 하고 기록은 Task 3.

**Files:**
- Create: `lib/domain/chat/chat_vendor.dart`
- Modify(다시 씀): `lib/domain/chat/chat_model.dart`
- Modify: `lib/domain/chat/tool/life_tools.dart` — `definitions` → `List<ToolSpec>`
- Modify: `lib/data/chat/anthropic_chat_model.dart` — 중립 ↔ Messages 변환, `AnthropicTurnState`, usage 파싱, `StopKind`
- Modify: `lib/domain/chat/usecase/chat_session.dart` — `_messages` 를 `List<ChatMessage>` 로, `_toolResult` Map 조립 삭제(어댑터로 이동), `StopKind` switch
- Test: `test/data/chat/anthropic_chat_model_test.dart` · `test/domain/chat/usecase/chat_session_test.dart` · `test/domain/chat/tool/life_tools_test.dart` · `test/domain/chat/chat_model_test.dart`(새)

**Interfaces:**
- Produces (`chat_vendor.dart`):
  ```dart
  /// 연결할 수 있는 AI 벤더. ⑤ 에서 xai 를 더한다.
  enum ChatVendor { anthropic, openai }
  ```
  키 기획 §7.1 은 이 enum 을 `chat_settings.dart` 에 두지만 ① 에서 이미 필요하므로 자기 파일에 둔다. ② 는 import 만 한다.
- Produces (`chat_model.dart`):
  ```dart
  @freezed
  sealed class ChatMessage with _$ChatMessage {
    const factory ChatMessage.user(String text) = UserMessage;
    /// [vendorState] 는 어댑터만 읽는 불투명 값. domain 은 만들지도 읽지도 않고 들고만 다닌다. 저장하지 않는다.
    const factory ChatMessage.assistant({
      required List<AssistantPart> parts,
      VendorTurnState? vendorState,
    }) = AssistantMessage;
    const factory ChatMessage.toolResults(List<ToolResultPart> results) = ToolResultsMessage;
  }

  @freezed
  sealed class AssistantPart with _$AssistantPart {
    const factory AssistantPart.text(String text) = TextPart;
    const factory AssistantPart.toolCall({
      required String id,
      required String name,
      required Map<String, Object?> input,
    }) = ToolCallPart;
  }

  @freezed
  class ToolResultPart with _$ToolResultPart {   // primary constructor: callId · json · isError=false · images=const []
    const ToolResultPart({required this.callId, required this.json, this.isError = false, this.images = const []});
  }

  /// JSON Schema 는 벤더 공통 부분집합(object · string · integer · enum · required)만.
  @freezed
  class ToolSpec with _$ToolSpec {               // name · description · parameters(Map<String, Object?>)
  }

  abstract interface class VendorTurnState {
    ChatVendor get vendor;
    String get model;
  }

  enum StopKind { endTurn, toolUse, refusal, maxTokens, other }

  @freezed
  class TokenUsage with _$TokenUsage {           // inputTokens · outputTokens · cacheReadTokens=0 · cacheWriteTokens=0 · int? reasoningTokens
  }

  @freezed
  sealed class ModelEvent with _$ModelEvent {
    const factory ModelEvent.textDelta(String text) = ModelTextDelta;
    // 진행 이벤트 — 이름 · 모양은 체감 속도 기획 §5.1. 이 계획의 어댑터는 아직 내지 않는다(진행 줄 단계에서 낸다).
    const factory ModelEvent.thinking() = ModelThinking;
    const factory ModelEvent.progress(String text) = ModelProgress;
    const factory ModelEvent.toolCallStarted({required String id, required String name}) = ModelToolCallStarted;
    const factory ModelEvent.toolCallReady({required String id, required String name,
        required Map<String, Object?> input}) = ModelToolCallReady;
    const factory ModelEvent.completed({
      required AssistantMessage message,
      required StopKind stop,
      required TokenUsage? usage,   // 사용량은 여기 한 곳. 별도 usage 이벤트 없음
    }) = ModelCompleted;
  }

  /// Freezed 아님 — 생성 toString 이 apiKey 를 찍기 때문. toString 은 키 · system · 메시지 본문 없이 모델 · 개수만.
  final class ModelRequest {
    const ModelRequest({required this.apiKey, required this.model, this.fastMode = false,
        required this.system, required this.messages, required this.tools});
    final String apiKey; final String model; final bool fastMode;
    final String system; final List<ChatMessage> messages; final List<ToolSpec> tools;
  }

  enum ChatModelErrorKind { invalidKey, rateLimited, overloaded, network, server, quotaExceeded, modelUnavailable }

  abstract interface class ChatModel {
    ChatVendor get vendor;
    /// 실패는 스트림 오류 ChatModelException.
    /// 취소 계약: 구독을 cancel 하면 어댑터는 진행 중인 HTTP 요청을 즉시 닫고, 그 뒤 이벤트 · 오류를 내지 않는다(Task 5 에서 구현).
    Stream<ModelEvent> stream(ModelRequest request);
  }
  ```
  `ChatModelException` 은 그대로. `quotaExceeded` · `modelUnavailable` 는 계약에만 더하고 **이 계획에서는 어댑터가 내지 않는다**(404 등 매핑은 지금 그대로 `server`). 세션 `_failureOf` 는 둘을 `ChatFailure.unknown` 으로 — `ChatFailure` 확장과 문구는 키 기획 ②.
  `listModels` · `ModelListResult` · `ModelInfo` 는 키 기획 ② 소관이라 이 계획에서 만들지 않는다.
- Produces (어댑터 안, `anthropic_chat_model.dart`):
  ```dart
  /// 그 턴의 원본 content 블록(thinking · 서명 포함). toString 은 블록 개수만.
  final class AnthropicTurnState implements VendorTurnState { … final List<Map<String, Object?>> content; }
  @override ChatVendor get vendor => ChatVendor.anthropic;
  ```
- Produces (`life_tools.dart`): `List<ToolSpec> get definitions` — 이름 · 설명 · 스키마 내용은 한 글자도 바꾸지 않고 키만 `input_schema` → `parameters`.
- Produces (`chat_session.dart`): 생성자 그대로(`ChatSession(this._model, this._tools, this._settings, this._clock)`). `static const interimModel = 'claude-opus-5-5'` — 요청마다 `ModelRequest.model` 로 넘긴다. 키 기획 ③ 이 카탈로그로 바꾸며 지운다(주석에 적는다). `fastMode` 는 false.

**변환 규칙(어댑터)** — 결과 JSON 이 전환 전과 같아야 한다:
| 중립 | Messages API |
|---|---|
| `UserMessage(text)` | `{'role':'user','content': text}`(문자열 그대로) |
| `AssistantMessage` + `AnthropicTurnState` | `{'role':'assistant','content': state.content}` — 원본 블록 그대로 |
| `AssistantMessage` + vendorState 가 null · 다른 타입 | parts 로 다시 만든다: `TextPart` → `{'type':'text','text'}`, `ToolCallPart` → `{'type':'tool_use','id','name','input'}`(thinking 없음 — Task 6 의 멈춘 턴이 이 길) |
| `ToolResultsMessage` | `{'role':'user','content':[{'type':'tool_result','tool_use_id','is_error','content':[{'type':'text','text': json}, …image base64 블록]}]}` — 지금 `ChatSession._toolResult` 를 그대로 옮김 |
| `ToolSpec` | `{'name','description','input_schema': parameters}` |
| `message_stop` | `completed(message: AssistantMessage(parts: text · tool_use 블록 순서대로, thinking · redacted_thinking 은 parts 에서 빼고 vendorState 에만), stop, usage)` |
| `stop_reason` | `end_turn`(또는 없음) → `endTurn` · `tool_use` → `toolUse` · `refusal` → `refusal` · `max_tokens` → `maxTokens` · 그 밖 → `other` |
| usage(C1) | `message_start.message.usage` 가 Map 이면 input · cacheWrite(`cache_creation_input_tokens`) · cacheRead(`cache_read_input_tokens`), output 은 마지막 `message_delta.usage.output_tokens`(없으면 `message_start` 의 값). `is int` 로만 읽고, `message_start` usage 가 없거나 어긋나면 `null` |

세션 분기: `toolUse` → 도구, `refusal` → `refused`, `endTurn` · `maxTokens` · `other` → `finished`(지금 `default:` 와 같음). 진행 이벤트 4종은 `case ModelThinking() || ModelProgress() || ModelToolCallStarted() || ModelToolCallReady(): break;`.

- [ ] **Step 1: 실패하는 테스트**
  - `chat_model_test.dart`(새): `ModelRequest.toString 에 키 · system · 메시지 글이 없다` · `AnthropicTurnState.toString 에 서명이 없다`(Task 2 에서 어댑터 테스트 쪽에 둬도 됨) · `ToolSpec 은 값이 같으면 같다`.
  - `life_tools_test.dart`: 기존 `definitions 에 다섯 도구가 있고 각자 input_schema 가 object 다` → `definitions 는 ToolSpec 다섯 개이고 parameters 가 object 다`(이름 순서 · `required` 그대로 확인).
  - `anthropic_chat_model_test.dart`(기존 테스트는 새 `stream(ModelRequest)` 호출로 고치고 아래를 더한다):
    - `요청 본문이 전환 전과 같다` — user 문자열 · `AnthropicTurnState` 원본 블록(thinking + signature) · `ToolResultsMessage`(이미지 하나) · `ToolSpec` 하나를 넣어 `body['messages']` · `body['tools']` 를 손으로 쓴 기대 JSON 과 `equals` 비교. `model` 은 `request.model`.
    - `vendorState 가 없는 assistant 턴은 text · tool_use 블록만으로 다시 만든다`.
    - `completed 는 parts(text · toolCall) 와 thinking 서명을 담은 vendorState 를 준다` — 기존 "thinking 블록을 서명과 함께 그대로 돌려준다"를 이 모양으로.
    - `stop_reason 을 StopKind 로 바꾼다` — 다섯 경우.
    - `usage 를 message_start 와 message_delta 에서 읽는다` — in 2310 · out 180 · cacheRead 2100 · cacheWrite 0.
    - `usage 가 없거나 모양이 어긋나면 null 이고 답은 끝난다`.
    - `요청 본문에 서버 저장 관련 필드가 없다` — `store` · `metadata` 키 없음(C2 주석과 짝).
    - `vendor 는 anthropic`.
  - `chat_session_test.dart` — `_FakeModel` 을 `stream(ModelRequest)` 로 바꾸고 `requests` 에 `ModelRequest` 를 모은다. 기존 테스트를 중립 형식으로 옮겨 **같은 동작**을 확인:
    - `도구 없이 끝나면 text 를 흘리고 finished` · `refusal 은 refused` · `8라운드를 넘기면 tooManySteps` · 오류 매핑 · `키가 없으면 noKey` · 진행 중 reset · `시스템 프롬프트에 오늘 날짜` — 그대로.
    - `이미지가 있는 결과는 base64 image 블록을 붙인다` → `이미지가 있는 결과는 ToolResultPart.images 로 다음 요청에 실린다`(base64 모양은 어댑터 테스트로 옮겨 감).
    - 사진 한도 그룹 — `is_error` · `photo_limit_reached` 를 `ToolResultPart.isError` · `json` 으로.
    - `assistant content(thinking 포함)를 바꾸지 않고 다음 요청에 보낸다` → `completed.message(vendorState 포함)를 identical 로 다음 요청 messages 에 넣는다`.
    - 새: `요청 model 은 interimModel, fastMode 는 false, tools 는 LifeTools.definitions 그대로`.
    - 새: `진행 이벤트(thinking · progress · toolCallStarted · toolCallReady)는 ChatEvent 를 만들지 않는다`.
    - 새: `maxTokens · other 로 끝나도 finished`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/data/chat test/domain/chat` → 컴파일 오류로 FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces · 변환 규칙대로. build_runner. `ChatSession` 클래스 doc 의 "assistant content 의 thinking 서명도 그대로"는 "assistant 턴의 vendorState 도 그대로"로.
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS. `chat_cubit_test` · `chat_tab_test` 는 고치지 않아도 통과해야 한다(`ChatEvent` 불변).
- [ ] **Step 5: 커밋** — `refactor(walk): 물어보기 모델 계약을 벤더 중립 형식으로 바꾼다`

### Task 3: 사용량 계약 · 라운드마다 기록

키 기획 §9 + 기록 기획 요청 필드. 저장 구현은 기록 기획 몫이라 지금은 아무것도 안 하는 구현으로 들어간다.

**Files:**
- Create: `lib/domain/chat/chat_usage_log.dart`
- Create: `lib/data/chat/noop_chat_usage_log.dart`
- Modify: `lib/domain/chat/usecase/chat_session.dart` — 생성자에 `ChatUsageLog` · `IdGenerator`, 라운드마다 기록
- Test: `test/domain/chat/usecase/chat_session_test.dart` · `test/domain/chat/chat_usage_log_test.dart`(새, toString 확인) · `test/support/fake_chat_usage_log.dart`(새, 받은 기록을 모으는 가짜)

**Interfaces:**
- Produces (`chat_usage_log.dart`):
  ```dart
  /// 사용량이 생긴 쓰임. 기록 기획의 위키 정리는 wikiDistill(키 기획 §9 의 `wiki` 를 이 이름으로 맞춤).
  enum ChatUsagePurpose { chat, wikiDistill }

  /// 요청(도구 라운드) 하나의 토큰 사용량. 질문 · 답 글 · 대화 id 는 담지 않는다.
  @freezed
  class ChatUsageRecord with _$ChatUsageRecord {
    // at · questionKey(한 질문의 라운드를 묶는 무작위 값) · vendor · model · fastMode · purpose · round(1부터) ·
    // temporary(임시 대화 — 지금은 늘 false) · inputTokens · outputTokens · cacheReadTokens · cacheWriteTokens ·
    // int? reasoningTokens · wikiIndexNotes=0 · wikiIndexChars=0 · readWikiCalls=0
  }

  abstract interface class ChatUsageLog {
    Future<void> record(ChatUsageRecord record);
  }
  ```
- Produces (`noop_chat_usage_log.dart`): `@LazySingleton(as: ChatUsageLog) class NoopChatUsageLog implements ChatUsageLog` — 아무것도 안 한다. 기록 기획이 `DriftChatUsageLog` 로 바꿔 끼운다.
- Produces (세션): `ChatSession(this._model, this._tools, this._settings, this._clock, this._usage, this._ids)`. `IdGenerator` 는 이미 `register_module.dart` 에 있다.
- Consumes: Task 2 의 `ModelCompleted.usage` · `ChatModel.vendor` · `ModelRequest.model/fastMode`.

**규칙:**
- `ask` 마다 `questionKey = _ids.newId()`.
- 라운드의 `completed.usage` 가 null 이 아니면 `ChatUsageRecord(at: _clock.now(), vendor: _model.vendor, model: request.model, fastMode: request.fastMode, purpose: chat, round: n, temporary: false, …tokens)` 를 넘긴다. 실패 · 취소 · usage 없음은 기록 안 함.
- **기다리지 않는다**: `unawaited(Future.sync(() => _usage.record(r)).catchError((Object _) {}))` — 기록이 느리거나 던져도 답은 그대로 흐른다.
- `stale()` 이면(리셋된 질문) 기록하지 않는다 — 단, 이미 끝난 라운드의 기록은 남는다(실제로 청구된 요청이다).

- [ ] **Step 1: 실패하는 테스트** — `chat_session_test.dart`:
  - `라운드마다 usage 를 하나씩 기록한다` — 도구 1회 + 답(2라운드) → 기록 2건, `round` 1 · 2, 같은 `questionKey`, `vendor`/`model`/`purpose: chat`/`temporary: false`/위키 숫자 0, 토큰 값 그대로.
  - `질문이 바뀌면 questionKey 가 바뀐다`.
  - `usage 가 null 인 라운드 · 실패한 라운드는 기록하지 않는다`.
  - `기록이 던져도 답은 finished` · `기록이 끝나지 않아도 답은 finished`(`Completer` 를 끝내지 않는 가짜).
  - `chat_usage_log_test.dart`: `ChatUsageRecord.toString 에 글 필드가 없다`(필드 목록이 숫자 · id · enum 뿐임을 고정).
- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/domain/chat` → FAIL.
- [ ] **Step 3: 구현** — 위 파일 · 규칙. build_runner(Freezed · `injection.config.dart`).
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 요청마다 토큰 사용량을 기록 계약으로 넘긴다`

### Task 4: 디버그 · 프로필 계측(`ChatTrace`)

체감 속도 기획 1단계(§2). 화면 변화 없음. 릴리스 빌드에는 아무것도 남지 않는다.

**Files:**
- Create: `lib/domain/chat/chat_trace.dart`
- Create: `lib/data/chat/dev_chat_trace.dart`
- Modify: `lib/core/di/register_module.dart` — `ChatTrace` 등록
- Modify: `lib/data/chat/anthropic_chat_model.dart` · `lib/domain/chat/usecase/chat_session.dart` · `lib/presentation/chat/cubit/chat_cubit.dart` — 표시 찍기
- Modify: `lib/presentation/chat/page/chat_tab.dart` — `ChatCubit(...)` 생성 인자에 `getIt<ChatTrace>()` **한 줄만**(앱바 · 본문은 건드리지 않는다)
- Test: `test/data/chat/dev_chat_trace_test.dart`(새) · `test/support/recording_chat_trace.dart`(새, 표시를 모으는 가짜) · 어댑터 · 세션 · cubit 테스트에 표시 확인 몇 건

**Interfaces:**
- Produces (`chat_trace.dart`):
  ```dart
  /// 질문 하나의 시간 흐름을 찍는다. 본문 · 키 · 도구 입력값은 찍지 않는다.
  abstract interface class ChatTrace {
    /// false 면 호출부는 data 맵도 만들지 않는다.
    bool get enabled;
    void begin();                                   // t0 — 새 질문
    void mark(String label, [Map<String, Object?> data = const {}]);
    void end();                                     // 요약 한 줄을 내고 비운다
  }

  final class NoopChatTrace implements ChatTrace { const NoopChatTrace(); … enabled => false }

  /// 표시 이름. 벤더 중립 — GPT 어댑터도 같은 이름을 쓴다.
  abstract final class ChatTraceMark {
    static const send = 'send', key = 'key', round = 'round',          // cubit · session
        req = 'req', head = 'head', first = 'first',                    // model
        blockStart = 'block.start', blockStop = 'block.stop',
        textDelta = 'textDelta', msgStop = 'msgStop',
        toolStart = 'tool.start', toolEnd = 'tool.end',                 // session
        firstVisible = 'firstVisible', firstGlyph = 'firstGlyph',       // cubit(프레임 뒤)
        userStop = 'userStop', abort = 'abort',                         // Task 5 · 7 에서 찍음
        done = 'done';
  }
  ```
- Produces (`dev_chat_trace.dart`): `class DevChatTrace implements ChatTrace { DevChatTrace({void Function(String line)? emit, Stopwatch Function()? stopwatch}); }` — 기본 `emit` 은 `developer.log(line, name: 'chat.trace')`, 표시마다 `Timeline.instantSync('chat.$label')`. 시간은 `begin()` 기준 단조 ms. `round` 표시(`data: {'n': 2}`)가 오면 이후 model 표시를 그 라운드(`r2`)에 묶는다.
  - **허용 data 키만 남긴다**: `vendor` · `model` · `fast` · `kind` · `tool` · `n` · `chars` · `stop` · `in` · `out` · `cacheRead` · `cacheWrite` · `reasoning`. 나머지 키는 버린다.
  - 요약 한 줄(스펙 §2.2 모양):
    ```
    chat.trace q=<질문 순번> vendor=anthropic model=claude-opus-5-5 fast=0 rounds=2 key=12
               r1{head=610 first=640 think=640-3900 tool:search_diary=3950-4010 stop=4020 in=2310 out=180}
               tool:search_diary=4030-4090(n=5)
               r2{head=4400 first=4420 firstText=6100 deltas=23/1180ms max=18ch gap~45ms stop=7300 in=4870 out=240 cacheRead=2100}
               firstVisible=4040 firstGlyph=6120 [userStop=… abort=…] done=7350
    ```
    `deltas=개수/첫~마지막 ms`, `max`=가장 큰 조각 글자 수, `gap~`=조각 간격 중앙값. 블록은 `kind` 가 thinking 이면 `think=시작-끝`, tool_use 면 `tool:<이름>=시작-끝`.
- Produces (DI): `register_module.dart` 에
  ```dart
  @lazySingleton
  ChatTrace get chatTrace => kReleaseMode ? const NoopChatTrace() : DevChatTrace();
  ```
- 생성자 변화: `AnthropicChatModel(http.Client client, ChatTrace trace)` · `withTimeouts(client, trace, {…})`, `ChatSession(…, this._usage, this._ids, this._trace)`, `ChatCubit(this._session, this._settings, this._diary, this._trace, {void Function(VoidCallback) schedulePostFrame = _addPostFrame})` — `_addPostFrame` 은 `SchedulerBinding.instance.addPostFrameCallback((_) => cb())`. 테스트는 `const NoopChatTrace()` 를 넘긴다.

**찍는 곳**(모두 `if (_trace.enabled)` 안):
| 표시 | 곳 | data |
|---|---|---|
| `send` + `begin()` | `ChatCubit.send` 진입 | — |
| `key` | 세션, 키 읽기 끝 | — |
| `round` | 세션, 라운드 요청 직전 | `n` |
| `req` · `head` · `first` | 어댑터: 요청 보냄 · 상태 줄 · 첫 SSE 이벤트 | `req` 에 `vendor` · `model` · `fast` |
| `block.start` · `block.stop` | 어댑터 `content_block_start/stop` | `kind`(thinking · text · tool_use), tool_use 면 `tool` |
| `textDelta` | 어댑터 `text_delta` 마다 | `chars` |
| `msgStop` | 어댑터 `message_stop` | `stop`(StopKind 이름) · 토큰(`in` · `out` · `cacheRead` · `cacheWrite`) |
| `tool.start` · `tool.end` | 세션 도구 실행 앞뒤 | `tool`, end 에 `n`(=`entryIds.length + images.length`, 개수만) |
| `firstVisible` · `firstGlyph` | cubit: 처음 `activeTool` 이나 글이 생긴 emit · 처음 글이 생긴 emit 뒤 프레임 | — |
| `done` + `end()` | cubit `_end` · `newConversation` · `close`(busy 였으면) | — |

- [ ] **Step 1: 실패하는 테스트**
  - `dev_chat_trace_test.dart`(가짜 `Stopwatch` 로 시간 고정):
    - `요약 한 줄에 라운드 · 블록 · 도구 · 프레임 표시가 들어간다` — 위 예시와 같은 순서로 표시를 넣고 `emit` 받은 줄이 기대 문자열과 같음.
    - `textDelta 개수 · 첫~마지막 간격 · 최대 조각 · 간격 중앙값을 계산한다` — 조각 3개(5 · 18 · 7자, 0 · 40 · 100ms) → `deltas=3/100ms max=18ch gap~50ms`.
    - `허용하지 않은 data 키는 버린다` — `mark('req', {'text': '비밀 질문', 'apiKey': 'sk-…'})` → 줄에 `비밀` · `sk-` 없음.
    - `end 뒤에는 비워져 다음 begin 이 새 질문이다` — `q=` 가 1 · 2.
    - `begin 없이 mark · end 해도 던지지 않는다`.
  - `anthropic_chat_model_test.dart`: `trace 가 켜져 있으면 req · head · first · block · textDelta · msgStop 을 차례로 찍는다`(`RecordingChatTrace`) · `trace 가 꺼져 있으면 mark 를 부르지 않는다`.
  - `chat_session_test.dart`: `key · round(n) · tool.start/end 를 찍고 도구 입력값은 data 에 없다`.
  - `chat_cubit_test.dart`: `send 는 begin · send, 끝나면 done · end` · `첫 글 emit 뒤 프레임에 firstGlyph 를 한 번만`(`schedulePostFrame` 을 즉시 실행하는 가짜).
- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/data/chat test/domain/chat test/presentation/chat` → FAIL.
- [ ] **Step 3: 구현** — 위 표대로. `kReleaseMode` 는 `package:flutter/foundation.dart`. build_runner.
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 질문 하나의 시간 흐름을 디버그 빌드에서 찍는다`

> 측정 자체(체감 속도 §2.3 — 실기기 · 질문 5개 × 3회 · 모델별)는 실제 키가 필요한 수동 작업이라 이 계획의 task 가 아니다. Task 8 이 `status.md` "다음 할 일"에 남긴다.

### Task 5: 취소 계약 — 구독 취소가 HTTP 를 닫는다

체감 속도 §5.2. 화면 변화 없음. 이것만으로 지금의 [새 대화] · 탭 닫힘도 HTTP 를 닫게 된다.

**Files:**
- Modify: `pubspec.yaml` — `http: ^1.5.0`(`AbortableRequest` 도입 판. 잠금 파일은 이미 1.6.0) → 루트에서 `flutter pub get`
- Modify: `lib/data/chat/sse_lines.dart` — `abortableSend` 추가
- Modify: `lib/data/chat/anthropic_chat_model.dart` — 컨트롤러 기반 스트림 + abort
- Modify: `lib/domain/chat/usecase/chat_session.dart` — 라운드의 모델 구독을 직접 쥐고 `reset()` 에서 끊음
- Test: `test/data/chat/sse_lines_test.dart` · `test/data/chat/anthropic_chat_model_test.dart` · `test/domain/chat/usecase/chat_session_test.dart`

**Interfaces:**
- Produces (`sse_lines.dart`):
  ```dart
  /// [abortTrigger] 가 끝나면 요청 · 응답 스트림을 닫는다(package:http AbortableRequest).
  Future<http.StreamedResponse> abortableSend(
    http.Client client, {
    required String method,
    required Uri url,
    required Map<String, String> headers,
    required String body,
    required Future<void> abortTrigger,
  });
  ```
- 어댑터 `stream(request)` 모양(스펙의 "`async*` 의 `finally` 에서 abort"는 쓰지 않는다 — `async*` 는 취소돼도 `send` 를 기다리는 동안 `finally` 에 닿지 않는다):
  ```dart
  Stream<ModelEvent> stream(ModelRequest request) {
    final abort = Completer<void>();
    var cancelled = false;
    StreamSubscription<ModelEvent>? inner;
    late final StreamController<ModelEvent> out;
    out = StreamController<ModelEvent>(
      onListen: () => inner = _run(request, abort.future).listen(
        (e) { if (!cancelled) out.add(e); },
        onError: (Object e, StackTrace s) { if (!cancelled) out.addError(e, s); },
        onDone: () { if (!cancelled) unawaited(out.close()); },
      ),
      onCancel: () {
        cancelled = true;
        if (!abort.isCompleted) { abort.complete(); /* trace: abort */ }
        unawaited(inner?.cancel());   // 기다리지 않는다 — 구독자 cancel 이 묶이지 않게
      },
    );
    return out.stream;
  }
  ```
  `_run` 은 지금 `async*` 본문(요청 · 상태 확인 · `_parse`)이고 `_client.send` 대신 `abortableSend(…, abortTrigger: abort)` 를 쓴다. abort 로 생긴 `RequestAbortedException`(= `ClientException`)은 `cancelled` 라 밖으로 안 나간다.
- 세션 쪽 — 라운드 소비를 직접 쥔다(`await for` 로 모델 스트림을 바로 돌면 세션 구독 취소가 다음 이벤트까지 모델에 닿지 않는다):
  ```dart
  StreamSubscription<ModelEvent>? _roundSub;
  StreamController<ModelEvent>? _roundRelay;

  /// 진행 중인 라운드의 모델 구독을 끊고 relay 를 닫아 _run 의 await for 를 끝낸다.
  void _cancelRound();
  ```
  `_run` 은 라운드마다 `relay = StreamController<ModelEvent>(sync: true)`, `_roundSub = _model.stream(req).listen(relay.add, onError: relay.addError, onDone: relay.close)` 뒤 `await for (event in relay.stream)`. `reset()` 이 `_cancelRound()` 를 부른다(세대를 올린 **뒤** — 닫힌 relay 로 루프가 끝나면 `stale()` 로 조용히 나간다).

- [ ] **Step 1: 실패하는 테스트**
  - `sse_lines_test.dart`: `abortableSend 는 AbortableRequest 에 trigger · 헤더 · 본문을 담는다`(손 가짜 `BaseClient` 가 받은 요청을 `http.Abortable` 로 확인).
  - `anthropic_chat_model_test.dart`(손 가짜 `_HangingClient extends http.BaseClient` — `send` 가 받은 요청을 잡아 두고, 응답은 테스트가 쥔 `StreamController<List<int>>`):
    - `상태 줄을 기다리는 중에 취소하면 abortTrigger 가 바로 끝난다` — `send` 가 끝나지 않는 Future, `listen` → `pumpEventQueue` → `cancel` → `(req as http.Abortable).abortTrigger` 가 1ms 안에 완료.
    - `SSE 를 받는 중에 취소하면 abortTrigger 가 끝나고 응답 바이트 구독이 끊긴다` — 응답 컨트롤러의 `onCancel` 이 불림.
    - `취소 뒤에는 이벤트도 오류도 내지 않는다` — 취소 뒤 응답 컨트롤러에 `text_delta` 를 넣고 `addError` 해도 리스너가 아무것도 받지 않음.
    - `정상 종료면 abortTrigger 는 끝나지 않는다`.
    - (Task 4 와 짝) `취소하면 trace 에 abort 를 찍는다`.
  - `chat_session_test.dart`(`_FakeModel` 에 `onCancel` 을 기록하는 컨트롤러 라운드 추가):
    - `라운드 중 reset 하면 모델 구독을 바로 취소한다` — 이벤트를 하나도 내지 않는 라운드 중 `reset()` → `pumpEventQueue` 뒤 `cancelled == true`, 세션 이벤트 없음.
    - `reset 뒤 바로 ask 하면 새 질문이 정상으로 끝난다`.
    - 기존 `진행 중 reset` 그룹 전부 그대로 통과.
- [ ] **Step 2: 실행해 실패 확인** — FAIL(`abortableSend` 없음, 취소가 전달되지 않음).
- [ ] **Step 3: 구현** — 위 모양. `pubspec.yaml` 바꾸고 `flutter pub get`.
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 구독을 끊으면 진행 중인 요청을 닫는다`

### Task 6: 세션 멈춤 — `ChatSession.stop()`

체감 속도 §6.2 "세션 쪽" + 기록 기획 D17(멈춘 턴 문맥 규칙). 이 계획이 먼저 들어가므로 세션 규칙을 여기서 넣는다. 화면 변화 없음(아직 아무도 부르지 않음).

**Files:**
- Modify: `lib/domain/chat/usecase/chat_session.dart`
- Test: `test/domain/chat/usecase/chat_session_test.dart`

**Interfaces:**
- Produces:
  ```dart
  @freezed
  sealed class ChatStopResult with _$ChatStopResult {
    /// 진행 중인 질문이 없었다(이미 끝났거나 리셋됨). 아무것도 바꾸지 않았다.
    const factory ChatStopResult.idle() = ChatStopIdle;
    /// 받은 글을 남겼다. [text] 는 화면에 흘린 글과 같은 문자열, [citedEntryIds] 는 그때까지 도구가 찾은 일기 id.
    const factory ChatStopResult.kept({required String text, required List<String> citedEntryIds}) = ChatStopKept;
    /// 받은 글이 없어 질문까지 되돌렸다.
    const factory ChatStopResult.dropped() = ChatStopDropped;
  }

  /// 멈춘 답 끝에 붙여 다음 문맥에 넣는 표시. 기록 기획의 resume 도 같은 상수를 쓴다.
  static const stoppedNote = '(사용자가 여기서 멈춤)';

  /// 진행 중인 질문을 멈춘다. reset 처럼 세대를 올리고 _busy = false 지만 대화는 비우지 않는다.
  ChatStopResult stop();
  ```
  `ChatEvent` 에 `stopped` 를 더하지 않는다 — 멈춤은 cubit 이 구독을 먼저 끊고 부르므로 이벤트가 닿을 곳이 없다. 결과는 반환값으로.
- 상태 필드(질문마다 `ask()` 에서 **동기로** 채운다 — `_run` 본문은 listen 뒤에야 돌므로): `_turnStart`(= `_messages.length`) · `_turnImagesAtStart` · `_turnQuestion` · `_turnText`(StringBuffer, `ModelTextDelta` 를 yield 하기 전에 덧붙임) · `_turnCited`(지금 지역 변수 `cited` 를 필드로).
- `stop()` 규칙:
  1. `_busy` 가 아니면 `idle()`.
  2. `_generation++` · `_cancelRound()`(Task 5) · `_busy = false`. 도구 실행 중이면 그 결과는 `stale()` 로 버려진다.
  3. `_messages.removeRange(_turnStart, length)` · `_imagesSent = _turnImagesAtStart` — 이번 질문 몫(완료된 라운드의 assistant · 도구 결과 포함)을 지운다. 앞선 기록은 그대로.
  4. `_turnText` 가 trim 해서 비었으면 `dropped()`.
  5. 아니면 `ChatMessage.user(_turnQuestion)` + `ChatMessage.assistant(parts: [AssistantPart.text('$text\n$stoppedNote')])`(vendorState 없음 — 어댑터가 글만의 text 블록으로 보냄, Task 2 규칙) 를 덧붙이고 `kept(text: text, citedEntryIds: [..._turnCited])`. `text` 는 표시를 붙이기 **전** 글.
- 사용량: 끊긴 라운드는 `completed` 가 없으므로 기록되지 않는다(Task 3 규칙 그대로) — 따로 할 일 없음.

- [ ] **Step 1: 실패하는 테스트** — 스펙 §8 의 (a)~(f) 를 이름으로:
  - `(a) 생각 중(이벤트 전) 멈추면 dropped 이고 기록이 그대로이며 바로 다음 ask 를 받는다`.
  - `(b) 도구 실행 중 멈추면 늦게 끝난 도구 결과가 기록 · 이벤트에 없고 사진 수가 되돌아간다` — `Completer` 로 도구를 붙잡고 `stop()` 뒤 완료, 이후 질문에서 사진 한도가 처음부터.
  - `(c) 1라운드 도구 뒤 2라운드 글 중간에 멈추면 꼬리가 user + assistant(글 + 표시) 하나로 바뀐다` — 앞선 질문의 `AssistantMessage`(vendorState 포함)는 `identical`, 꼬리 `AssistantMessage.vendorState == null`, parts 는 `TextPart('부분 글\n(사용자가 여기서 멈춤)')`, 반환 `kept(text: '부분 글', citedEntryIds: [1라운드 id])`.
  - `(d) 그 다음 질문의 요청 messages 에 부분 답이 들어 있다`.
  - `(e) 멈춤 → 질문 → 멈춤 → 질문이 매번 정상이고 StateError 가 없다`.
  - `(f) 멈춘 뒤 늦게 오는 모델 이벤트가 새 질문에 섞이지 않는다` — 멈춘 라운드의 컨트롤러에 늦게 `textDelta` 를 넣어도 새 질문 이벤트에 없음, 그리고 모델 구독이 취소됨.
  - `진행 중이 아니면 stop 은 idle 이고 아무것도 바꾸지 않는다` — 끝난 질문 뒤 `stop()`.
  - `글이 공백뿐이면 dropped`.
  - `kept.text 는 흘린 ChatEvent.text 를 이은 것과 같다`(라운드를 넘는 글 포함).
- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/domain/chat/usecase/chat_session_test.dart` → FAIL.
- [ ] **Step 3: 구현** — 위 규칙. 클래스 doc 에 "멈춤은 꼬리만 글로 바꾼다 — 앞선 기록은 고치지 않는다" 한 줄. build_runner.
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 세션에 멈춤을 더한다 — 받은 글만 문맥에 남긴다`

### Task 7: [■ 멈춤] 버튼 · 멈춤 표시 · 질문 되돌리기

체감 속도 §6.2 "cubit 쪽" · §6.3 의 표시 부분. **하단 탭 재구성이 병합된 뒤** 그 위에서 한다. `chat_tab.dart` 는 본문(`_ChatBody`)만 고치고 앱바([새 대화] + `FeatureMenu`)는 건드리지 않는다. 진행 줄 · 접힌 요약("멈춤 · 4초")은 진행 표시 단계라 범위 밖 — 이 task 는 말풍선의 '멈춤' 표시만.

**Files:**
- Modify: `lib/presentation/chat/cubit/chat_state.dart` — `ChatBubble.stopped` · `ChatState.restoredDraft`
- Modify: `lib/presentation/chat/cubit/chat_cubit.dart` — `stop()` · `consumeRestoredDraft()`
- Modify: `lib/presentation/chat/widget/chat_input.dart` — `busy` 면 [■ 멈춤], 되돌린 질문 채우기
- Modify: `lib/presentation/chat/widget/chat_bubble_view.dart` — '멈춤' 표시
- Modify: `lib/presentation/chat/page/chat_tab.dart` — `_ChatBody` 의 `ChatInput` 연결 · "멈췄어요" 스낵바(`BlocListener`)
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`
- Test: `test/presentation/chat/cubit/chat_cubit_test.dart` · `test/presentation/chat/widget/chat_input_test.dart`(새) · `test/presentation/chat/widget/chat_bubble_view_test.dart`(없으면 새) · `test/presentation/chat/page/chat_tab_test.dart`

**Interfaces:**
- Produces (상태):
  ```dart
  // ChatBubble 에 더함
  /// [■ 멈춤]으로 끊긴 답. 받은 [text] 는 그대로 남는다.
  @override final bool stopped;          // 기본 false

  // ChatState 에 더함
  /// 글 없이 멈춰 입력칸에 되돌릴 질문. 화면이 채운 뒤 consumeRestoredDraft 로 비운다.
  @override final String? restoredDraft;
  ```
- Produces (cubit):
  ```dart
  /// 답하는 중이면 멈춘다. 같은 emit 에서 busy: false. 인용을 읽는 중(_finishing)이면 무시(답은 이미 끝났다).
  void stop();
  void consumeRestoredDraft();
  ```
  `stop()` 순서: `busy` 아님 · `_finishing` 이면 return → `_generation++` → `_sub` cancel(기다리지 않음) → `_session.stop()` → trace `userStop`(Task 4) → switch:
  - `ChatStopKept(:citedEntryIds)` → 마지막 말풍선 `copyWith(stopped: true)`, `busy: false`, `activeTool: null` 을 **즉시** emit. 그다음 `_resolve(citedEntryIds)` 가 끝나고 세대가 같으면 그 말풍선에 `cited` 를 붙여 다시 emit.
  - `ChatStopDropped()` → 질문 · 답 말풍선 둘을 지우고 `restoredDraft: <질문 말풍선 text>`, `busy: false`.
  - `ChatStopIdle()` → `_end(state.bubbles)`(세션은 이미 끝났다 — 화면만 정리).
  그 뒤 `_complete()` · trace `done` + `end()`. `newConversation` · `close` 는 지금처럼 `reset()`.
- Produces (위젯):
  ```dart
  ChatInput({
    required bool busy,                  // 이름 바꿈(지금 enabled == !busy)
    required ValueChanged<String> onSend,
    required VoidCallback onStop,
    String? restoredDraft,
    VoidCallback? onDraftRestored,
  })
  ```
  - `busy` 면 전송 자리에 `IconButton(icon: Icons.stop_rounded, tooltip: l10n.walkChatStop, onPressed: onStop)`, 아니면 지금 전송 버튼. 글자 칸은 **지금처럼 답하는 중에도 입력 가능**(아래 결정).
  - `didUpdateWidget` 에서 `restoredDraft` 가 새로 non-null 이면: 입력칸이 비어 있을 때만 그 글로 채우고 커서를 끝에(키보드는 열지 않음 — focus 요청 없음), 그 뒤 `onDraftRestored` 를 post-frame 으로 부른다. 비어 있지 않으면(답하는 중에 다음 질문을 쓰고 있었으면) 덮어쓰지 않고 `onDraftRestored` 만.
  - `ChatBubbleView`: `bubble.stopped` 면 글 아래(실패 문구와 같은 자리, `AppSpacing.xs` 간격) `Row(Icon(Icons.stop_circle_outlined, size: <bodySmall 글자 크기>), SizedBox(width: AppSpacing.xs), Text(l10n.walkChatStopped))` — 색 `onSurfaceVariant`, 글꼴 `textTheme.bodySmall`. 오류 색 아님.
  - `chat_tab.dart` `_ChatBody`: `ChatInput(busy: state.busy, onSend: …, onStop: cubit.stop, restoredDraft: state.restoredDraft, onDraftRestored: cubit.consumeRestoredDraft)`. `BlocListener<ChatCubit, ChatState>(listenWhen: (a, b) => a.restoredDraft == null && b.restoredDraft != null, listener: (c, _) => AppSnackBar.show(c, message: l10n.walkChatStoppedSnack))`.

**l10n 새 키**(ko / en / ja):
| 키 | ko | en | ja |
|---|---|---|---|
| `walkChatStop` | 답 멈추기 | Stop answer | 回答を止める |
| `walkChatStopped` | 멈춤 | Stopped | 停止 |
| `walkChatStoppedSnack` | 멈췄어요 | Stopped | 停止しました |

`@` description: 각각 "채팅 탭: 답하는 중 전송 자리의 멈춤 버튼 툴팁" · "채팅 탭: 멈춘 답 말풍선 끝 표시" · "채팅 탭: 글 없이 멈춰 질문을 입력칸에 되돌렸을 때 스낵바". `walkChatSearching` 은 그대로 둔다(진행 표시 단계에서 지움).

- [ ] **Step 1: 실패하는 테스트**
  - `chat_cubit_test.dart`(가짜 세션 또는 실제 `ChatSession` + 가짜 모델 — 지금 파일 방식을 따른다):
    - `보내는 중 · 생각 중 · 도구 중 · 글 쓰는 중 각각 stop 하면 같은 emit 에서 busy false`.
    - `글이 있으면 stopped 말풍선이 남고 그때까지의 인용이 붙는다`.
    - `글이 없으면 말풍선 둘이 사라지고 restoredDraft 가 질문이다` · `consumeRestoredDraft 는 null 로`.
    - `멈춘 뒤 늦은 이벤트는 무시한다`.
    - `멈춘 직후 send 가 성공한다`(`StateError` 없음, 새 말풍선 두 개).
    - `인용을 읽는 중(finished 뒤) stop 은 아무것도 바꾸지 않는다`.
    - `stop 하면 send 가 돌려준 Future 가 끝난다`.
  - `chat_input_test.dart`(새): `busy 가 아니면 전송 버튼, 누르면 onSend` · `busy 면 멈춤 버튼(툴팁 '답 멈추기'), 누르면 onStop` · `restoredDraft 가 오면 빈 입력칸을 채우고 커서가 끝, onDraftRestored 를 부른다` · `입력칸에 글이 있으면 덮어쓰지 않는다` · `busy 여도 글자 칸은 입력할 수 있다`.
  - `chat_bubble_view_test.dart`: `stopped 면 글 아래에 '멈춤'과 정지 아이콘, 오류 색이 아니다` · `stopped 가 아니면 없다`.
  - `chat_tab_test.dart`: 기존 `답하는 중이면 전송 버튼이 꺼진다`(현재 `Icons.send` 의 `onPressed == null` 확인)를 `답하는 중이면 멈춤 버튼이 보이고 전송 버튼이 없다`로 바꾼다. 더함: `멈춤을 누르면 부분 답에 '멈춤' 표시가 남고 전송 버튼이 돌아온다` · `글 없이 멈추면 입력칸에 질문이 돌아오고 '멈췄어요' 스낵바가 한 번 뜬다`. 재구성이 바꾼 앱바 · ⋮ 테스트는 손대지 않는다.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/presentation/chat` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces. build_runner(`chat_state.freezed.dart`).
- [ ] **Step 4: l10n** — 세 arb 에 키 추가, `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 6: 커밋** — `feat(walk): 물어보기 답하는 중 [■ 멈춤] — 받은 글은 남기고 글이 없으면 질문을 되돌린다`

### Task 8: 문서

키 기획 §11 · 체감 속도 §7 의 문서 행, CLAUDE.md "진행 상태는 status.md 에만".

**Files:**
- Modify: `apps/walk/docs/status.md` · `apps/walk/docs/history.md` · `apps/walk/docs/testing.md` · `apps/walk/docs/plan.md`
- Modify: `docs/superpowers/specs/2026-11-01-walk-chat-streaming-ux.md` — 끝 "측정 기록" 절에 "기기 측정 대기 — 계측은 들어감" 한 줄만(측정값은 기기에서)

- [ ] **Step 1: `status.md`** — "물어보기" 절에 체크 항목:
  - `[x]` 벤더 중립 채팅 계약 + Claude 어댑터 이전(키 기획 ①, 동작 그대로) · 사용량 계약(`NoopChatUsageLog`)
  - `[x]` 디버그 · 프로필 계측 `chat.trace`(체감 속도 1단계 — 코드)
  - `[x]` [■ 멈춤] · 취소 시 HTTP 닫기 · 부분 답 '멈춤' 표시 · 글 없으면 질문 되돌림(체감 속도 2단계)
  - `[ ]` 계측 기준선 측정(실기기 · 15 트레이스 · 모델별)과 "덩어리 도착인가" 판정, C3 · C4 기기 확인
  - 검증 줄: `flutter analyze` 0 · `flutter test` N건 통과(실행해서 숫자를 적는다). "다음 할 일"에 측정 · 키 기획 ② 를 더한다.
- [ ] **Step 2: `history.md`** — 새 절 `## 2026-11-xx — 물어보기 중립 계약 · 계측 · 멈춤`: 아래 "결정" 표의 항목(이유 포함), 구현 전 확인 C1~C5 의 결과(확인한 날짜 · 출처, 못 한 것은 "대기"), 막힌 것.
- [ ] **Step 3: `testing.md`** — "물어보기 — 채팅 · 기상 기록 보관" 표에 행 추가 · 수정: `data/chat/sse_lines_test`(SSE 줄 · 대기 시간 · abortableSend) · `data/chat/dev_chat_trace_test`(요약 줄 · 허용 키) · `anthropic_chat_model_test` 설명에 "중립 ↔ Messages 변환 · usage · 취소 시 abort" · `chat_session_test` 에 "사용량 기록 · 멈춤 (a)~(f)" · `presentation/chat/widget/chat_input_test` · `chat_bubble_view_test`. 맨 위 건수 갱신. "물어보기 기기 시나리오"에 Q8(답하는 중 멈춤 — 네 단계, 부분 답 '멈춤' · 다음 질문이 이어짐) · Q9(`flutter logs` 에 `chat.trace` 한 줄, 릴리스 빌드에는 없음)를 "대기"로.
- [ ] **Step 4: `plan.md`** — "물어보기 (채팅)" 절: 모델 계약이 벤더 중립(`ChatMessage` · `ModelEvent` · `VendorTurnState`)이고 Anthropic 모양은 어댑터 안에만 있다는 한 줄. "Claude 와 주고받는 형식"에 (1) 멈춤 규칙 — 구독 취소 = HTTP 닫기, 멈춘 턴은 `받은 글 + "\n(사용자가 여기서 멈춤)"` 글만으로 다음 문맥에, 글이 없으면 질문까지 되돌림 (2) 요청마다 사용량을 `ChatUsageLog` 로(저장은 아직 안 함). `display: updates` · 캐시는 진행 표시 단계에서 적는다.
- [ ] **Step 5: 링크 검사** — `cd apps/trader && flutter test test/convention` → PASS.
- [ ] **Step 6: 커밋** — `docs(walk): 물어보기 중립 계약 · 계측 · 멈춤 반영`

---

## 결정

이 계획을 쓰며 정한 것(스펙끼리 어긋나거나 스펙이 비워 둔 곳). Task 8 이 `history.md` 로 옮긴다.

| # | 결정 | 이유 |
|---|---|---|
| P1 | 진행 이벤트 4종(`thinking` · `progress` · `toolCallStarted` · `toolCallReady`)을 Task 2 에서 **정의만** 하고 어댑터는 내지 않는다 | 계약이 진행 표시 단계에서 다시 흔들리지 않게 하면서, 아무도 쓰지 않는 방출 코드 · 테스트를 미리 만들지 않는다 |
| P2 | 멈춤 결과는 `ChatEvent.stopped` 가 아니라 `ChatSession.stop()` 의 반환값 `ChatStopResult`(idle · kept · dropped) | cubit 이 구독을 먼저 끊으므로 이벤트가 닿을 곳이 없다. `idle` 은 "이미 끝난 답을 지우는" 경쟁을 막는다 |
| P3 | 멈춘 턴 문맥 표시는 상수 `ChatSession.stoppedNote = '(사용자가 여기서 멈춤)'` 하나 | 체감 속도 기획은 "(사용자가 여기서 멈춤)", 기록 기획은 "(사용자가 답을 중간에 멈춤)"로 어긋났다. 호출 지시대로 앞의 것으로 맞추고, 기록 기획의 `resume` 이 같은 상수를 쓰게 한다 |
| P4 | 취소는 어댑터의 `StreamController.onCancel` 에서 abort, 세션은 라운드 구독을 직접 쥐고 `reset()`/`stop()` 에서 끊는다 | 스펙의 "`async*` 의 `try/finally`" 는 `send` 를 기다리는 동안 · 다음 이벤트 전에는 실행되지 않아 "0.5초 안에 연결 닫힘"을 못 지킨다 |
| P5 | `ModelRequest` 는 Freezed 가 아닌 손 클래스, toString 에 키 없음 | Freezed 가 만드는 toString 이 apiKey 를 찍는다 |
| P6 | 모델 id 는 ① 동안 `ChatSession.interimModel = 'claude-opus-5-5'` 로 세션이 넘긴다 | 키 기획 ① "모델 id 그대로" + ③ "어댑터는 `ModelRequest.model` 을 쓴다"를 둘 다 지키는 가장 작은 자리. ③ 이 카탈로그로 바꾸며 지운다 |
| P7 | `ChatVendor` 는 `lib/domain/chat/chat_vendor.dart` 에 따로 | 키 기획 §7.1 은 `chat_settings.dart` 에 두지만 ① 에서 이미 `ChatModel.vendor` · 사용량이 쓴다 |
| P8 | `ChatModelErrorKind.quotaExceeded` · `modelUnavailable` 는 계약에만 더하고 어댑터 매핑 · `ChatFailure` · 문구는 ② | ① 은 "화면 변화 없음"이 조건이다. 새 실패 문구 없이 매핑만 바꾸면 사용자에게는 똑같이 "알 수 없는 오류"다 |
| P9 | 답하는 중에도 입력칸 글자는 쓸 수 있게 둔다(전송 자리만 [■ 멈춤]) · 되돌린 질문은 입력칸이 비었을 때만 채운다 | 체감 속도 §6.2 는 "지금처럼 꺼 둔다"고 썼지만 지금 코드(`chat_input.dart`)는 전송만 끈다. 동작을 바꾸지 않고, 쓰던 글을 덮지 않는다 |
| P10 | 사용량 기록은 기다리지 않고(fire-and-forget) 오류를 삼킨다 | 기록이 느리거나 실패해도 답 흐름 · 라운드 사이 지연이 늘지 않게 |
| P11 | `ChatUsageRecord` 는 기록 기획의 요청(`questionKey` · `temporary` · `wikiIndexNotes` · `wikiIndexChars` · `readWikiCalls`, `purpose` 는 `chat` · `wikiDistill`)을 ① 에서 다 넣는다 | 계약을 한 번만 바꾼다. 지금은 `temporary=false`, 위키 숫자 0 |
| P12 | 계측 `ChatTrace` 에 `enabled` 를 두고 data 는 허용 키만 남긴다 · 사용자 멈춤은 `userStop`, 연결 닫힘은 `abort` 로 이름을 나눈다 | 릴리스에서 delta 마다 맵을 만들지 않게. 스펙의 `stop` 표시는 `message_stop` 과 겹친다 |
