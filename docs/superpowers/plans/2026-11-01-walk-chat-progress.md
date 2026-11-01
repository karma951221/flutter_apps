# walk 물어보기 — 진행 표시 · 지연 줄이기 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 질문을 보낸 뒤 답이 끝날 때까지 답 말풍선 바로 위 **진행 줄**이 "보내는 중 → 생각하는 중 → (모델의 진행 노트) → 6월 1~7일 일기 찾는 중 → 일기 5개 찾음 → 답 쓰는 중"과 경과 초를 보이고, 끝나면 "기록 3번 찾아봄 · 9초" 한 줄로 접히게 한다(3초 미만이면 없음, 멈춤은 늘 남김). 같이 Claude 프롬프트 캐시를 켜고, 한 응답의 도구를 동시에 실행하고, 도구 이름을 `tool_use` 블록이 열리는 순간 알리며, 글 조각마다 화면 전체를 다시 그리지 않게 한다.

**Architecture:** 중립 `ModelEvent` 의 진행 이벤트 4종(`thinking` · `progress` · `toolCallStarted` · `toolCallReady` — core 계획이 정의만 해 둠)을 Anthropic 어댑터가 **실제로 내고**, 방출 규칙을 `chat_model.dart` doc 에 계약으로 적어 GPT 어댑터가 따르게 한다. `ChatSession` 은 이를 화면용 `ChatEvent`(`phase` · `progress` · `toolStarted(name, input)` · `toolFinished(name, summary)` · `roundStarted`)로 옮기고, 도구는 `Future.wait` 로 동시에 돌린 뒤 결과는 호출 순서로 정리한다. `ChatCubit` 은 말풍선마다 `ChatProgress`(단계 목록 · 경과 초 · 끝남/멈춤)를 들고 글 조각은 이벤트 루프 한 바퀴에 한 번만 emit 한다. 화면은 새 `ChatProgressView` 와 `BlocSelector` 로 쪼갠 `_ChatBody` 다. 도구 라벨 · 결과 문구는 domain 이 주는 값(`ToolInputSummary` · `ToolSummary`)으로 presentation 이 l10n 으로 만든다.

**Tech Stack:** Flutter · flutter_bloc · Freezed 3 · injectable/get_it · `package:http` 1.6 · gen-l10n(`packages/l10n`, 기준 `app_ko.arb`) · intl(`DateFormat`) · `fake_async`.

**Spec:** [체감 속도 기획](../specs/2026-11-01-walk-chat-streaming-ux.md) **3단계 진행 표시**(§3 · §5.1) · **4단계 지연 줄이기**(§4 · §4.1), 테스트 §8(이 계획 몫), 완료 조건 §10(코드로 닫을 수 있는 것), 결정 Q1 · Q2 · Q4 · Q6 · Q7 · Q8. **5단계 재측정**은 기기 작업이라 Task 8 의 체크리스트로만 남긴다.

**선행(이 계획을 실행할 때 끝나 있다고 본다 — 코드가 아직 없을 수 있다):**
- [하단 탭 재구성 계획](2026-11-01-walk-nav-regroup.md) — `chat_tab.dart` 앱바 = [새 대화] + `FeatureMenu`
- [중립 계약 · 계측 · 멈춤 계획](2026-11-01-walk-chat-core.md) 전체 — 중립 `ChatMessage` · `AssistantPart` · `ModelEvent`(진행 4종 **정의됨 · 안 냄**) · `ModelRequest` · `StopKind` · `TokenUsage`, `AnthropicChatModel(http.Client, ChatTrace)` · `withTimeouts` · `_run` + `StreamController` 취소, `sse_lines.dart`(`sseEvents` · `abortableSend`), `ChatTrace` · `ChatTraceMark` · `DevChatTrace` · `RecordingChatTrace`(test/support), `ChatSession(…, _usage, _ids, _trace)` · `_roundSub`/`_roundRelay` · `_turnText` · `stop()` · `ChatStopResult` · `stoppedNote` · `interimModel`, `ChatBubble.stopped` · `ChatState.restoredDraft` · `ChatCubit.stop()` · `ChatInput(busy:, onStop:, …)`, l10n `walkChatStop` · `walkChatStopped` · `walkChatStoppedSnack`
- [대화 기록 계획](2026-11-01-walk-chat-history.md) — `ChatBubble.seq` · `ChatState.conversationId/temporary/vendor`, `ChatSession.resume` · `ChatCubit` 저장(진행 정보는 저장하지 않는다 — Q4)
- [키 UX 계획](2026-11-01-walk-chat-key-ux.md) — `ChatCubit(…, this._verifier)` · `ChatKeyVerifier`, 실패 말풍선 [설정 열기]
- GPT 어댑터([모델 · GPT 계획](2026-11-01-walk-chat-models-gpt.md), 병렬로 들어올 수 있음) — 이 계획은 **Anthropic 만 구현**하고, GPT 어댑터가 따를 방출 규칙을 Task 1 의 계약 doc 으로 남긴다.

각 task 를 시작할 때 위 이름이 실제 코드와 같은지 먼저 `grep` 으로 맞춘다(`grep -n "ModelToolCallReady\|ChatStopResult\|_turnText\|restoredDraft\|ChatTraceMark" -r apps/walk/lib`). 다르면 실제 이름을 따르고 이 계획의 해당 줄을 고친다(인터페이스 모양은 그대로).

## Global Constraints

- 경로는 `apps/walk/` 기준. 테스트는 `test/` 아래 같은 구조(`lib/presentation/chat/widget/x.dart` ↔ `test/presentation/chat/widget/x_test.dart`).
- **저장소 전체 포맷 · 전체 build_runner 금지.** `dart format` 은 그 task 가 만든 · 고친 파일에만. 코드 생성은 `cd apps/walk && dart run build_runner build --delete-conflicting-outputs`(walk 패키지 안에서만 — 루트 · 다른 앱에서 돌리지 않는다).
- 생성 파일(`.freezed.dart` · `.g.dart` · `injection.config.dart`)은 손으로 고치지 않는다.
- Freezed(CLAUDE.md): 단일 모델은 Freezed 3 primary constructor(`@freezed class X with _$X { @override final …; const X({…}); }`), 변형은 `sealed class` + named factory. 분기는 `switch` 패턴 매칭(`when`/`map` 금지).
- UI 규칙(CLAUDE.md): `AppButton` · `AppSnackBar.show` 등 공통 위젯 우선. `Colors.*` · 숫자 여백 · `BorderRadius.circular(n)` 금지 — `AppSpacing` · `AppRadius` · `AppMotion` · `Theme.of(context)`. 전환 시간 · 곡선은 `AppMotion` 토큰만, `AppMotion.enabled(context) == false` 면 `Duration.zero` · 정지 아이콘 · 커서 고정.
- 진행 줄 · 접힌 요약 · [↓ 새 답]은 채팅 전용 — `lib/presentation/chat/widget/` 에 둔다(스펙 §3.6). `design_system` 으로 올리지 않는다.
- 문구는 l10n 만. 새 키는 `app_ko.arb`(+ `@키` description) · `app_en.arb` · `app_ja.arb` 셋 다, 그 뒤 `cd packages/l10n && flutter gen-l10n`. **domain 은 문구를 만들지 않는다** — 도구 라벨 · 결과 문구는 presentation 이 `ToolInputSummary` · `ToolSummary` 로 만든다.
- **질문 · 답 · 진행 노트 · 도구 입력값(검색어)은 로그 · 예외 · 계측 · `toString` 어디에도 남기지 않는다**(core 규칙). 새 타입(`ToolInputSummary` · `ChatProgressStep` 등) 중 글을 담는 것은 `toString` 을 override 하고 테스트로 고정한다.
- 진행 노트 · 단계 목록 · 접힌 요약은 **저장하지 않는다**(Q4). 대화 기록 계획의 저장 변환(`ChatTurnDraft`)에 `progress` 를 넣지 않는다.
- 모델 id · `effort` · `fallbacks` 는 바꾸지 않는다(기본 모델은 키 기획 소관, 스펙 Q3 · Q5).
- 매 task 끝: `cd apps/walk && flutter analyze && flutter test` 0 오류 · 전체 통과. 커밋은 task 마다 하나(`feat(walk): …`, 문서는 `docs(walk): …`).

## Review Focus

1. **진행 노트 0개가 정상 경로(Task 1 · 4 · 5, Q7)** — `display: updates` 를 끈 상수(대체 경로)에서도, 서버 fallback 으로 노트 없는 모델이 답해도, 진행 줄은 단계 · 도구 라벨 · 결과 · 경과 초로 끝까지 동작한다. 같은 테스트를 노트 있음/없음 두 번 돌린다.
2. **thinking 블록 원본 불변(Task 1)** — 노트를 읽어 이벤트로 내도 `AnthropicTurnState.content` 의 thinking 블록(글 · 서명)은 받은 그대로 다음 요청에 간다. `display` 는 상수라 대화 중에 바뀌지 않는다(바뀌면 캐시가 깨진다).
3. **도구 병렬 + 순서(Task 4)** — 두 도구가 **동시에** 시작되고(두 번째가 첫 번째 끝을 기다리지 않음), `ToolResultsMessage` 의 순서 · 사진 한도 판정은 **호출 순서**다. 멈춤 · 리셋 중 늦게 끝난 도구는 기록 · 이벤트에 없다.
4. **멈춤과 표시가 같은 글(Task 4 · 5)** — 라운드 경계 줄바꿈은 세션이 넣어 `ChatEvent.text` 로 흘린다 → cubit 이 보여 준 글 = 세션 `_turnText` = `ChatStopKept.text`. cubit 의 글 모으기 버퍼는 `stop()` · 끝 이벤트 앞에서 반드시 비운다.
5. **다시 그리기 범위(Task 5 · 7)** — 경과 초가 1초마다 바뀌어도 말풍선 목록 전체 · 입력칸은 다시 그리지 않는다(빌드 횟수 테스트). 한 이벤트 루프 바퀴 안의 글 조각 여럿은 emit 하나.
6. **접근성 · 줄이기 모드(Task 6 · 7)** — 진행 줄 문구는 `liveRegion` 이지만 경과 초 갱신은 알리지 않는다. 줄이기 모드면 스피너 · 깜빡임 · 전환이 없다.

## 구현 전 확인

live 문서 · 실제 키가 필요한 항목. 어느 것도 단위 테스트를 막지 않게 설계했다 — 결과는 Task 8 에서 walk `history.md` 에 남긴다. **V2 는 Task 1 의 상수를 정하는 게이트**다.

| # | 확인할 것 | 필요한 task | 막히지 않게 한 설계 |
|---|---|---|---|
| V1 | **beta 헤더 이름 · 요청 모양** — `anthropic-beta: thinking-display-updates-2026-08-18` 을 기존 `server-side-fallback-2026-07-01` 과 쉼표로 함께, 본문 `"thinking": {"type": "adaptive", "display": "updates"}`. API 버전 `2026-10-21` 에서 이름이 바뀌었거나 GA 가 됐는지(GA 면 헤더를 뺀다). 키 기획이 고를 수 있게 한 **다른 Claude 모델(Sonnet · Haiku 계열)이 이 파라미터를 받는지**(안 받으면 400) | Task 1 | 헤더 값 · thinking 맵은 어댑터 상수 하나(`_betaHeader` · `_thinkingParam`)로만 만든다. 모델별로 안 받으면 `_progressNoteModels`(접두사 목록)에 든 모델에만 보낸다 — 테스트는 "목록 밖 모델이면 `thinking` 키 없음"까지 |
| V2 | **청구(Q1)** — `display: omitted` → `updates` 가 `output_tokens` · 다음 라운드 `input_tokens` 를 늘리는가. live 문서(Extended thinking · progress updates 절) + 같은 질문을 각 설정으로 3회씩 보내 `usage` 중앙값 비교(±10% 이내면 "안 늘어남") — core 계측(`chat.trace` 의 `in` · `out`)으로 잰다 | Task 1 | **게이트**: 늘지 않으면 `AnthropicChatModel.progressNotesDefault = true`. 늘면 `false`(대체 경로) — `thinking` 파라미터 · beta 헤더 · 시스템 프롬프트 안내 줄을 보내지 않고, 진행 줄은 노트 없이 동작(Review 1). 확인 전에는 **`false` 로 시작**해 머지해도 청구가 바뀌지 않게 한다 |
| V3 | **노트의 SSE 모양** — 노트가 `thinking_delta` 로 오는지, 한 블록에 노트가 둘 이상 올 수 있는지, 노트 블록이 열린 채 오래 머무는지, 끊긴 응답의 마지막 블록 문구가 정확히 `This part of the response was interrupted before it finished.` 인지 | Task 1 | 블록마다 **누적 글**을 `progress` 로 낸다(화면은 마지막 것으로 바꿔 끼움 — 둘이어도 맞음). 누적 글이 중단 문구의 접두사인 동안은 내지 않고, 블록이 닫힐 때 중단 문구와 같으면 버린다 |
| V4 | **프롬프트 캐시** — 요청 top-level `cache_control: {"type": "ephemeral"}`(자동 캐시)가 이 API 버전 · 모델에서 받아지는지, 최소 캐시 길이(512 토큰 가정), 5분 TTL, 첫 쓰기 1.25배. `thinking` 파라미터를 상수로 두면 라운드 사이 캐시가 유지되는지 | Task 2 | 단위 테스트는 "요청 본문에 top-level `cache_control`". 효과는 계측의 `cacheRead`(라운드 2 > 0, 스펙 §10)로 기기에서. 400 이면 상수 `_promptCache = false` 로 끄고 history 에 적는다 |
| V5 | **안내 줄 비용** — 시스템 프롬프트 "도구를 쓰기 전에 무엇을 볼지 한 줄로 말해." 가 출력 토큰을 얼마나 늘리는지(줄 있음/없음 3회씩) | Task 2 | `ChatModel.progressNotes` 가 false 면 줄 자체를 넣지 않는다. 늘어난 양은 스펙 "측정 기록"에, 사용자가 원치 않으면 그 줄만 뺀다(상수 `ChatSession._noteHint`) |
| V6 | **GPT(Responses) 추론 요약의 청구** — GPT 어댑터 몫. 이 계획은 계약(Task 1 표)만 남긴다 | (GPT 계획) | 못 주거나 청구가 늘면 GPT 어댑터는 `progress` 를 내지 않는다 — 화면은 Review 1 경로 |

---

### Task 1: 진행 이벤트 계약 + Anthropic 어댑터 방출(`display: updates`)

스펙 §3.1 · §5.1. 진행 이벤트 4종을 Anthropic 어댑터가 실제로 낸다. 세션은 아직 무시한다(core Task 2 의 `case … : break;`) — 화면 변화 없음.

**Files:**
- Modify: `lib/domain/chat/chat_model.dart` — `ModelEvent` doc 에 **어댑터 방출 규칙**(아래 표) · `ChatModel.progressNotes` 게터
- Modify: `lib/data/chat/anthropic_chat_model.dart` — 상수 · 요청 본문 · 헤더 · 이벤트 방출 · 계측 표시
- Modify: `lib/domain/chat/chat_trace.dart` — `ChatTraceMark.progress`
- Modify: `lib/data/chat/dev_chat_trace.dart` — 라운드 요약에 `firstProgress=`
- Test: `test/data/chat/anthropic_chat_model_test.dart` · `test/data/chat/dev_chat_trace_test.dart` · 테스트의 `implements ChatModel` 가짜들(`grep -rn "implements ChatModel" test`) — `progressNotes => false` 한 줄

**Interfaces:**
- Produces (`chat_model.dart`):
  ```dart
  abstract interface class ChatModel {
    ChatVendor get vendor;
    /// 이 어댑터가 사용자에게 보일 진행 노트(ModelEvent.progress)를 낼 수 있게 설정됐는가.
    /// false 면 세션은 시스템 프롬프트의 "도구 전 한 줄 안내"를 넣지 않는다(체감 속도 §3.1 대체 경로).
    bool get progressNotes;
    Stream<ModelEvent> stream(ModelRequest request);
  }
  ```
  ⟂ 키 기획 §8.2 계약에 게터 하나를 더한다(core 계획이 만든 가짜 · GPT 어댑터도 구현). GPT 계획이 먼저 들어왔으면 그 어댑터에 `progressNotes => false`(노트를 아직 안 냄)를 함께 넣는다.
- **어댑터 방출 규칙**(`ModelEvent` doc 주석에 그대로 — GPT 어댑터가 따른다):

  | 이벤트 | 언제 · 몇 번 | Claude(이 task) | GPT(Responses, 그쪽 계획) |
  |---|---|---|---|
  | `thinking()` | 생각 구간이 열릴 때마다(라운드에 0~여러 번). 내용 없음 | `content_block_start` 의 `thinking` · `redacted_thinking` | reasoning 항목 추가 |
  | `progress(text)` | 사용자에게 보일 노트. **같은 블록이면 지금까지 모인 글 전체**(누적)를 다시 낸다 — 받는 쪽은 바꿔 끼운다. 앞뒤 공백 trim, 빈 글은 안 냄. **0번이 정상** | `progressNotes` 일 때 비어 있지 않은 `thinking_delta`. 중단 문구는 안 냄(V3) | 추론 요약 delta(청구 확인 뒤, V6). 못 주면 안 냄 |
  | `toolCallStarted(id, name)` | 도구 호출 블록이 열리는 순간, 입력 완성 전 | `content_block_start(tool_use)` | 함수 호출 항목 추가 |
  | `toolCallReady(id, name, input)` | 그 블록의 입력이 완성된 순간. `completed.message` 의 `ToolCallPart` 와 **중복으로** 낸다 | `content_block_stop`(tool_use) | 함수 인자 완료 |
  | `textDelta(text)` | 그대로 | 그대로 | 그대로 |

  순서 보장: 한 블록의 `toolCallStarted` 는 같은 id 의 `toolCallReady` 보다 먼저, 둘 다 `completed` 보다 먼저. 진행 이벤트는 기록(`completed.message` · `vendorState`)을 바꾸지 않는다.
- Produces (어댑터 상수 — V1 · V2 게이트):
  ```dart
  /// V2 청구 확인 전에는 false. true 면 thinking.display=updates + beta 헤더 + 노트 방출.
  static const progressNotesDefault = false;
  @override
  bool get progressNotes => _progressNotes;   // withTimeouts 인자가 없으면 progressNotesDefault
  // (static 과 인스턴스 멤버는 같은 이름을 못 쓴다 — 상수는 progressNotesDefault)
  static const _fallbackBeta = 'server-side-fallback-2026-07-01';
  static const _notesBeta = 'thinking-display-updates-2026-08-18';
  static const _thinkingParam = {'type': 'adaptive', 'display': 'updates'};
  /// V1: thinking.display 를 받는 모델 접두사. 밖이면 thinking 키를 보내지 않는다.
  static const _progressNoteModels = ['claude-opus-5', 'claude-sonnet-5'];
  ```
  테스트가 두 경로를 다 돌 수 있게 `withTimeouts(…, {bool? progressNotes})` 로 덮어쓸 수 있게 한다(기본은 상수). 요청 규칙: `notes = progressNotes && _progressNoteModels.any(request.model.startsWith)` 면 본문에 `'thinking': _thinkingParam`, 헤더 `anthropic-beta: '$_fallbackBeta,$_notesBeta'`. 아니면 지금 그대로(`thinking` 키 없음, 헤더는 fallback 하나).
- Produces (`chat_trace.dart`): `static const progress = 'progress';` — data `chars` 만. `DevChatTrace` 는 라운드의 첫 `progress` 시각을 `firstProgress=<ms>` 로 요약 줄 `rN{…}` 에 넣는다(스펙 §2.1 `rN.firstProgress`).
- 어댑터 파싱(지금 `content_block_*` 처리에 더함):
  - `content_block_start`: `thinking` · `redacted_thinking` → `yield ModelEvent.thinking()`. `tool_use` → `yield ModelEvent.toolCallStarted(id: block['id'], name: block['name'])`(문자열이 아니면 이벤트를 건너뛰고 블록은 지금처럼 모은다).
  - `thinking_delta`: 블록 글은 지금처럼 누적(원본 불변). `notes` 이고 누적 글 `trim()` 이 비어 있지 않으며 중단 문구(`_interruptedNote`)의 접두사가 아니면 `yield ModelEvent.progress(trimmed)` + trace `progress`(`chars`).
  - `content_block_stop`: thinking 블록이고 아직 낸 적 없는 누적 글이 있으며(접두사였던 경우) 중단 문구와 **같지 않으면** 그때 `progress` 를 낸다. `tool_use` 블록은 입력 파싱 뒤 `yield ModelEvent.toolCallReady(id, name, input)`.

- [ ] **Step 1: 실패하는 테스트** — `anthropic_chat_model_test.dart`(SSE 픽스처는 기존 도우미로):
  - `progressNotes 가 켜지면 thinking.display=updates 와 beta 헤더 둘을 보낸다` — `body['thinking'] == {'type':'adaptive','display':'updates'}`, `headers['anthropic-beta'] == 'server-side-fallback-2026-07-01,thinking-display-updates-2026-08-18'`.
  - `progressNotes 가 꺼지면 thinking 키가 없고 beta 헤더는 fallback 하나다`(지금 요청과 같음).
  - `노트를 받지 않는 모델이면 켜져 있어도 thinking 키를 보내지 않는다` — `model: 'claude-haiku-x'`.
  - `thinking 블록이 열리면 thinking() 을 낸다` — 빈 thinking 블록(서명만) → `[ModelThinking(), …, ModelCompleted]`, `progress` 없음.
  - `비어 있지 않은 thinking_delta 는 누적 글로 progress 를 낸다` — delta `'지난주 기상 '` · `'기록을 볼게요'` → `progress('지난주 기상')` · `progress('지난주 기상 기록을 볼게요')`.
  - `progressNotes 가 꺼지면 thinking_delta 에 글이 있어도 progress 를 내지 않는다`.
  - `중단 문구는 progress 로 내지 않는다` — 중단 문구를 세 조각으로 → `progress` 0개. 그리고 `중단 문구의 접두사로 시작했지만 다른 글이면 블록이 닫힐 때 낸다` — `'This part'` · `' of my plan'` → stop 때 `progress('This part of my plan')` 하나.
  - `tool_use 블록 시작에 toolCallStarted, 정지에 toolCallReady(input) 를 낸다` — 순서: `toolCallStarted(id: 'tu1', name: 'search_diary')` 가 `input_json_delta` 보다 먼저, `toolCallReady(..., input: {'from': …})` 가 `completed` 보다 먼저. `completed.message.parts` 의 `ToolCallPart` 도 그대로.
  - `노트를 내도 completed 의 vendorState thinking 블록(글 · 서명)은 받은 그대로다` — `AnthropicTurnState.content` 를 기대 JSON 과 `equals`.
  - `trace 에 progress(chars) 를 찍고 노트 글은 data 에 없다`(`RecordingChatTrace`).
  - `dev_chat_trace_test.dart`: `라운드 요약에 firstProgress 가 들어간다`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/data/chat` → FAIL.
- [ ] **Step 3: 구현** — 위 규칙. `ChatModel` 가짜들에 `progressNotes => false`. `ChatSession` 은 고치지 않는다(진행 이벤트는 여전히 `break`).
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 어댑터가 진행 이벤트(생각 · 노트 · 도구 열림)를 낸다`

### Task 2: 프롬프트 캐시 · 시스템 프롬프트(날짜 줄 끝으로 · 도구 전 한 줄 안내)

스펙 §4 표의 "프롬프트 캐시" · "도구 전 한 줄 안내 유도". 화면 변화 없음.

**Files:**
- Modify: `lib/data/chat/anthropic_chat_model.dart` — top-level `cache_control`
- Modify: `lib/domain/chat/usecase/chat_session.dart` — `_systemPrompt()`
- Test: `test/data/chat/anthropic_chat_model_test.dart` · `test/domain/chat/usecase/chat_session_test.dart`

**Interfaces:**
- 어댑터: `static const _promptCache = true;` 면 본문 top-level 에 `'cache_control': {'type': 'ephemeral'}`(V4). 블록 단위 `cache_control` 은 넣지 않는다. GPT 는 벤더 자동 캐시 — GPT 어댑터에 할 일 없음(계약 doc 에 한 줄).
- 세션 `_systemPrompt()`:
  ```
  너는 사용자의 개인 기록 앱 Life Tool 안의 도우미다.
  사용자의 일기 · 걸음 수 · 알람 기상 기록을 도구로 찾아보고, …(지금 문장 그대로, 순서 그대로)
  한국어로, 마크다운 없이 짧은 평문으로 답한다.
  [_model.progressNotes 일 때만] 도구를 쓰기 전에 무엇을 볼지 한 줄로 말해.
  오늘은 $today, 시간대는 ${tz} 이다.          ← 맨 끝
  ```
  `static const _noteHint = '도구를 쓰기 전에 무엇을 볼지 한 줄로 말해.';`(V5 결과로 빼기 쉽게 상수). 날짜 줄이 끝으로 가도 날짜 계산 · 형식은 그대로.

- [ ] **Step 1: 실패하는 테스트**
  - 어댑터: `요청 본문에 top-level cache_control ephemeral 이 있다` · `messages · system · tools 블록에는 cache_control 이 없다`.
  - 세션: 기존 `시스템 프롬프트에 오늘 날짜` 유지 + `오늘 날짜 줄은 시스템 프롬프트의 마지막 줄이다` · `progressNotes 인 모델이면 도구 전 한 줄 안내가 있고, 아니면 없다`(가짜 모델의 `progressNotes` 를 바꿔 두 번) · `같은 날 두 질문의 system 은 바이트까지 같다`(캐시 접두부 안정).
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/data/chat test/domain/chat` → FAIL.
- [ ] **Step 3: 구현.**
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 프롬프트 캐시를 켜고 날짜 줄을 시스템 끝으로 옮긴다`

### Task 3: 도구 입력 요약 · 결과 요약(개수만)

스펙 §3.2 도구 라벨 · §3.3(Q6). domain 은 값만, 문구는 Task 6.

**Files:**
- Create: `lib/domain/chat/tool/tool_summary.dart`
- Modify: `lib/domain/chat/tool/tool_result.dart` — `ToolResult.summary`
- Modify: `lib/domain/chat/tool/life_tools.dart` — 다섯 도구가 `summary` 를 채움 · `inputSummary(name, input)`
- Test: `test/domain/chat/tool/life_tools_test.dart` · `test/domain/chat/tool/tool_summary_test.dart`(새)

**Interfaces:**
- Produces (`tool_summary.dart`):
  ```dart
  /// 진행 줄 라벨에 쓰는 도구 종류. 알 수 없는 이름은 other.
  enum ChatToolKind { searchDiary, viewPhotos, diaryIndex, dailySteps, wakeRecords, other }

  ChatToolKind chatToolKindOf(String name);   // 'search_diary' → searchDiary …

  /// 도구 입력에서 라벨용으로 꺼낸 것만. 잘못된 날짜는 null.
  /// toString 은 kind · 날짜 유무만 — 검색어(query)는 찍지 않는다.
  @freezed
  class ToolInputSummary with _$ToolInputSummary {
    @override final ChatToolKind kind;
    @override final DateTime? from;
    @override final DateTime? to;
    @override final String? query;     // search_diary 의 query(앞뒤 trim, 20자 넘으면 20자 + '…')
    const ToolInputSummary({required this.kind, this.from, this.to, this.query});
    @override String toString() => 'ToolInputSummary($kind, range: ${from != null})';
  }

  /// 결과 개수(Q6 — 개수만). 오류 결과면 count 0 · isError.
  @freezed
  class ToolSummary with _$ToolSummary {
    @override final ChatToolKind kind;
    @override final int count;
    @override final bool isError;
    const ToolSummary({required this.kind, required this.count, this.isError = false});
  }
  ```
- `ToolResult` 에 `@override final ToolSummary? summary;`(기본 null — 기존 생성 코드 그대로 컴파일).
- `LifeTools`:
  - `ToolInputSummary inputSummary(String name, Map<String, Object?> input)` — `from`/`to` 는 지금 `_parse` 와 같은 규칙(`YYYY-MM-DD` 로컬), `query` 는 search_diary 에서만.
  - 결과 `summary.count`: search_diary = 찾은 일기 수(잘리기 전 `found.length` 아니라 **보낸 개수** `entries.length`), view_entry_photos = `images.length`, list_diary_index = 스토리 수, daily_steps = 날 수, wake_records = 회차 수. `_error(...)` 는 `ToolSummary(kind, count: 0, isError: true)`(이름을 모르면 `other`).

- [ ] **Step 1: 실패하는 테스트**
  - `tool_summary_test.dart`: `chatToolKindOf 는 다섯 이름과 그 밖을 나눈다` · `ToolInputSummary.toString 에 검색어가 없다`.
  - `life_tools_test.dart`(기존 픽스처로): 다섯 도구 각각 `summary.count`(예: 일기 5개 → 5, 걸음 7일 → 7, 기상 3회 → 3, 사진 2장 → 2, 스토리 4개 → 4) · `0개면 count 0 이고 isError 아님` · `잘못된 기간이면 isError` · `inputSummary 는 from · to 를 날짜로, query 를 trim 해 20자로 자른다` · `날짜가 잘못이면 from · to 가 null` · `search_diary 가 아니면 query 가 null`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/domain/chat/tool` → FAIL.
- [ ] **Step 3: 구현** — build_runner.
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 도구가 입력 · 결과 요약(개수)을 준다`

### Task 4: 세션 — 진행 `ChatEvent` · 도구 병렬 · 라운드 경계

스펙 §3.4 · §4(도구 병렬 · 알림 앞당기기) · §5.1 `ChatEvent`. cubit 은 아직 새 이벤트를 무시한다(Task 5) — 화면 변화는 라운드 경계 줄바꿈 하나.

**Files:**
- Modify: `lib/domain/chat/usecase/chat_session.dart`
- Modify: `lib/presentation/chat/cubit/chat_cubit.dart` — 새 `ChatEvent` 를 `switch` 에서 무시하는 `case` 만(컴파일용 · 동작 그대로)
- Test: `test/domain/chat/usecase/chat_session_test.dart` · `test/presentation/chat/cubit/chat_cubit_test.dart`(새 이벤트가 와도 지금 동작 그대로 — 기존 테스트 통과)

**Interfaces:**
- Produces (`chat_session.dart`):
  ```dart
  /// 진행 줄의 단계. 도구 단계는 toolStarted 로 알린다.
  enum ChatPhase { sending, thinking, writing }

  @freezed
  sealed class ChatEvent with _$ChatEvent {
    const factory ChatEvent.phase(ChatPhase phase) = ChatPhaseChanged;
    /// 모델의 진행 노트(누적 글 — 바꿔 끼운다). 0번이 정상.
    const factory ChatEvent.progress(String note) = ChatProgressNote;
    /// 도구 블록이 열림([input] null) → 입력 완성([input] 있음). 같은 [callId] 로 두 번 올 수 있다.
    const factory ChatEvent.toolStarted({required String callId, required String name,
        ToolInputSummary? input}) = ChatToolStarted;
    const factory ChatEvent.toolFinished({required String callId, required String name,
        required ToolSummary summary}) = ChatToolFinished;
    /// 2라운드부터. 1라운드는 phase(sending) 가 시작이다.
    const factory ChatEvent.roundStarted(int round) = ChatRoundStarted;
    const factory ChatEvent.text(String delta) = ChatText;
    const factory ChatEvent.finished({required List<String> citedEntryIds}) = ChatFinished;
    const factory ChatEvent.failed(ChatFailure failure) = ChatFailed;
  }
  ```
  `ChatToolStarted(String toolName)` 의 모양이 바뀐다 — 기존 사용처(`chat_cubit.dart` 의 `activeTool`)는 `name` 으로 옮긴다(Task 5 에서 `activeTool` 자체를 지움). `toString` 이 `ToolInputSummary.toString` 을 쓰므로 검색어가 안 찍힌다. `ChatProgressNote` 는 노트 글을 담으므로 `toString` override(`ChatEvent.progress(<n> chars)`).
- 매핑(`_run` 라운드 루프):
  | 모델 이벤트 | ChatEvent |
  |---|---|
  | (`ask` 직후, 키 읽기 전) | `phase(sending)` |
  | 라운드 n ≥ 2 요청 직전 | `roundStarted(n)` |
  | `ModelThinking` | `phase(thinking)` — 직전 단계가 이미 thinking 이면 내지 않음 |
  | `ModelProgress(:text)` | `progress(text)` |
  | `ModelToolCallStarted(:id, :name)` | `toolStarted(callId: id, name: name)` |
  | `ModelToolCallReady(:id, :name, :input)` | `toolStarted(callId: id, name: name, input: _tools.inputSummary(name, input))` |
  | `ModelTextDelta(:text)` — 라운드의 첫 조각 | `phase(writing)` 뒤 글. **이 질문에 이미 글이 있고(`_turnText` 비어 있지 않음) 새 라운드의 첫 조각이면 앞에 `'\n'` 를 붙여** `text('\n$text')` — `_turnText` 에도 같은 글을 덧붙인다 |
  | 도구 하나 끝남 | `toolFinished(callId, name, summary: result.summary ?? ToolSummary(kind, count: 0))` — **끝난 순서대로** |
- 도구 병렬(`StopKind.toolUse`):
  ```dart
  final calls = [for (final p in done.message.parts) if (p case ToolCallPart c) c];
  final futures = [for (final c in calls) _runTool(c)];   // 모두 바로 시작
  final results = List<ToolResult?>.filled(calls.length, null);
  await for (final (i, r) in _inCompletionOrder(futures)) {  // 끝나는 대로
    if (stale()) return;
    results[i] = r;
    trace tool.end(tool, n)
    yield ChatEvent.toolFinished(callId: calls[i].id, name: calls[i].name, summary: …);
  }
  // 정리는 호출 순서로: 사진 한도(_capped)도 이 순서로 판정
  final parts = [for (var i = 0; i < calls.length; i++) ToolResultPart(callId: calls[i].id, …_capped(results[i]!))];
  cited.addAll(… 호출 순서로 …);
  ```
  `_inCompletionOrder` 는 세션 안 private 헬퍼(`StreamController` + 각 Future 의 `then`; 하나가 던지면 그 자리 결과를 `ToolResult(json: '{"error":"tool_failed"}', isError: true)` — `LifeTools.run` 이 이미 잡지만 방어). trace `tool.start` 는 시작할 때 모두, `tool.end` 는 끝나는 대로.
- 사진 한도: 이미지를 불러오는 일 자체는 병렬로 하되(로컬 · 부작용 없음), **한도 판정 · `_imagesSent` 증가는 호출 순서로 한 번에** — 지금 "앞 도구가 한도를 다 쓰면 뒤 도구는 오류 결과"와 같은 결과.
- 멈춤 · 리셋: 기다리던 도구가 늦게 끝나도 `stale()` 이면 결과 · 이벤트가 없다(core 규칙 그대로).

- [ ] **Step 1: 실패하는 테스트** — `chat_session_test.dart`(가짜 모델이 진행 이벤트를 내는 라운드, `Completer` 로 붙잡는 가짜 도구):
  - `이벤트 순서` — 1라운드(thinking · progress · toolCallStarted · toolCallReady · completed(toolUse)) + 2라운드(text · completed) → `[phase(sending), phase(thinking), progress, toolStarted(input: null), toolStarted(input: 기간), toolFinished(count 5), roundStarted(2), phase(writing), text, finished]`.
  - `진행 노트가 0개여도 같은 순서에서 progress 만 빠진다`(Review 1).
  - `도구 둘은 동시에 시작한다` — 첫 도구의 `Completer` 를 끝내지 않은 채 두 번째 도구의 `run` 이 불림.
  - `toolFinished 는 끝난 순서, 다음 요청의 ToolResultsMessage 는 호출 순서다` — 두 번째를 먼저 끝냄.
  - `사진 한도는 호출 순서로 판정한다` — 남은 한도 2, 사진 2장 도구 둘을 거꾸로 끝내도 첫 호출이 사진, 둘째가 `photo_limit_reached`.
  - `도구 실행 중 stop 하면 늦게 끝난 도구의 toolFinished · 결과가 없다`(core (b) 와 짝 — 병렬에서도).
  - `라운드 경계의 첫 글 앞에 줄바꿈을 넣는다` — 1라운드 text `'볼게요.'`(toolUse) → 2라운드 `'지난주에는…'` → 흘린 글 이으면 `'볼게요.\n지난주에는…'`, 그리고 그 뒤 `stop()` 이면 `kept.text` 도 같은 문자열.
  - `1라운드에 글이 없으면 2라운드 첫 글 앞에 줄바꿈이 없다`.
  - `thinking 이 연달아 와도 phase(thinking) 는 한 번`.
  - `ChatEvent.progress · toolStarted 의 toString 에 노트 · 검색어가 없다`.
  - 기존 `진행 이벤트(…)는 ChatEvent 를 만들지 않는다`(core Task 2) 는 **지운다** — 이 task 가 뒤집는 동작.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/domain/chat/usecase/chat_session_test.dart` → FAIL.
- [ ] **Step 3: 구현** — build_runner. cubit 의 `switch` 에 `case ChatPhaseChanged() || ChatProgressNote() || ChatToolFinished() || ChatRoundStarted(): break;`, `ChatToolStarted(:final name)` → 지금처럼 `activeTool: name`.
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 세션이 진행 단계를 알리고 도구를 동시에 실행한다`

### Task 5: cubit — `ChatProgress` · 경과 초 · 접힌 요약 · 글 모아 emit

스펙 §3.2(상태 쪽) · §4.1 첫 줄 · §6.3 진행 줄 부분. 화면은 아직 옛 "기록을 찾는 중…" 줄을 쓴다(Task 7 에서 바꿈) — `activeTool` 은 이 task 에서 **`progress` 로 대신하고 지운다**, 옛 줄은 `progress.current is 도구 단계` 로 임시 연결.

**Files:**
- Create: `lib/presentation/chat/cubit/chat_progress.dart`
- Modify: `lib/presentation/chat/cubit/chat_state.dart` — `ChatBubble.progress`, `ChatState.activeTool` 삭제
- Modify: `lib/presentation/chat/cubit/chat_cubit.dart`
- Modify: `lib/presentation/chat/page/chat_tab.dart` — `ChatCubit(...)` 생성 인자에 `getIt<Clock>()` 한 줄, 옛 줄의 조건만 `state.activeTool != null` → 마지막 말풍선 `progress?.current` 가 도구 단계일 때(Task 7 에서 지움)
- Test: `test/presentation/chat/cubit/chat_cubit_test.dart` · `test/presentation/chat/cubit/chat_progress_test.dart`(새)

**Interfaces:**
- Produces (`chat_progress.dart`):
  ```dart
  /// 진행 줄 단계 하나. 문구는 화면이 l10n 으로 만든다.
  @freezed
  sealed class ChatProgressStep with _$ChatProgressStep {
    const factory ChatProgressStep.sending() = StepSending;
    const factory ChatProgressStep.thinking() = StepThinking;
    /// 모델의 진행 노트. toString 에 글 없음.
    const factory ChatProgressStep.note(String text) = StepNote;
    const factory ChatProgressStep.tool({required String callId, required ChatToolKind kind,
        ToolInputSummary? input, ToolSummary? result}) = StepTool;
    const factory ChatProgressStep.writing() = StepWriting;
    const factory ChatProgressStep.stopped() = StepStopped;
  }

  /// 답 말풍선 하나의 진행. 저장하지 않는다(Q4).
  @freezed
  class ChatProgress with _$ChatProgress {
    @override final List<ChatProgressStep> steps;   // 시간 순. 펼친 타임라인이 그대로 쓴다
    @override final DateTime startedAt;
    @override final int elapsedSeconds;              // 1초마다 cubit 이 올림, 끝나면 고정
    @override final bool running;
    const ChatProgress({required this.startedAt, this.steps = const [], this.elapsedSeconds = 0, this.running = true});

    ChatProgressStep? get current;                   // steps.lastOrNull
    int get toolCalls;                               // StepTool 개수(서로 다른 callId)
    bool get stopped;                                // steps.last is StepStopped
    /// 끝난 뒤 접힌 요약을 남길까 — 3초 이상이거나 멈췄으면(Q2).
    bool get keepSummary => stopped || elapsedSeconds >= ChatProgress.summaryMinSeconds;
    static const summaryMinSeconds = 3;
    /// 진행 중 경과 초를 보이기 시작하는 초(빠른 답에서 숫자가 깜빡이지 않게).
    static const elapsedVisibleFrom = 3;
  }
  ```
  단계 갱신 규칙(cubit 이 `ChatEvent` 로):
  | ChatEvent | steps |
  |---|---|
  | `send()` | `[sending]`, `startedAt = _clock.now()` |
  | `phase(thinking)` | 마지막이 thinking 이 아니면 `+thinking` |
  | `progress(note)` | 마지막이 `note` 면 **바꿔 끼움**(누적 글), 아니면 `+note` |
  | `toolStarted(callId, name, input)` | 같은 callId 의 `StepTool` 이 있으면 `input` 만 채워 그 자리에서 갱신하고 **맨 뒤로 옮김**(지금 단계), 없으면 `+tool(kind: chatToolKindOf(name), input)` |
  | `toolFinished(callId, summary)` | 그 `StepTool` 에 `result` 를 채우고 맨 뒤로 |
  | `roundStarted` | 변화 없음 |
  | `phase(writing)` | 마지막이 writing 이 아니면 `+writing` |
  | `finished` · `failed` | `running: false`, 경과 고정. `keepSummary` 가 아니면 말풍선 `progress: null`(실패라도 3초 넘으면 남김) |
  | `stop()`(core) | `+stopped`, `running: false` — 3초 미만이어도 남김 |
- Produces (`chat_state.dart`): `ChatBubble` 에 `@override final ChatProgress? progress;`(assistant 말풍선만). `ChatState.activeTool` 삭제.
- Produces (cubit):
  - 생성자에 `Clock` 을 더한다: `ChatCubit(this._session, this._settings, this._diary, this._trace, …, this._clock, {schedulePostFrame, Duration tick = const Duration(seconds: 1)})` — 실제 순서는 그때 코드(키 UX · 기록 계획 뒤)에 맞춘다.
  - **경과 초**: `send` 때 `Timer.periodic(tick)` 를 시작해 마지막 말풍선 `progress.elapsedSeconds = _clock.now().difference(startedAt).inSeconds` 로 emit(값이 바뀔 때만). 끝 · 실패 · 멈춤 · `newConversation` · `close` 에서 취소.
  - **글 모아 emit**(스펙 §4.1): `ChatText` 는 `_pendingText` 버퍼에 쌓고, 버퍼가 비어 있다 차면 `Timer(Duration.zero, _flushText)` 하나를 건다. 다른 모든 이벤트 · `stop()` · `newConversation()` · `close()` 는 **먼저 `_flushText()`** 를 동기로 부른 뒤 처리한다(순서 · 멈춤 글 일치 — Review 4). 첫 글이 그려진 프레임에 `firstGlyph`(core) 는 flush 의 emit 기준.
  - core `stop()` 의 `ChatStopKept` · `ChatStopDropped` 분기에 위 진행 규칙을 더한다(`Dropped` 면 말풍선이 사라지므로 progress 도 함께 사라짐).

- [ ] **Step 1: 실패하는 테스트**
  - `chat_progress_test.dart`: `toolCalls 는 서로 다른 callId 수` · `keepSummary — 2초 끝남 false · 3초 true · 1초 멈춤 true` · `StepNote.toString 에 글이 없다`.
  - `chat_cubit_test.dart`(가짜 세션 스트림을 `StreamController<ChatEvent>` 로 — 지금 파일 방식을 따른다, `MutableClock` · `fakeAsync`):
    - `send 직후 같은 emit 에 progress=[sending], running` — 스펙 §10 "0.3초 안에 보내는 중".
    - `단계 전이` — 위 표의 이벤트를 차례로 넣고 `steps` 를 기대 목록과 비교.
    - `같은 callId 의 toolStarted 두 번은 단계 하나로 합치고 input 을 채운다` · `toolFinished 는 result 를 채운다`.
    - `노트는 누적 글로 바꿔 끼운다`.
    - `경과 초는 1초마다 오르고 끝나면 멈춘다` — `elapse(3s)` → 3, finished 뒤 `elapse(5s)` → 그대로.
    - `한 바퀴 안의 글 조각 셋은 emit 하나` — 같은 동기 구간에 `text` 셋 → `flushMicrotasks` 뒤 상태 변화 1회, 글은 이어 붙음.
    - `글 버퍼는 다른 이벤트 앞에서 먼저 비운다` — `text('a')` 직후 `toolStarted` → 그 emit 에서 이미 글 `'a'`.
    - `stop 은 남은 글 버퍼를 먼저 반영한다` — 버퍼에 글이 있는 채 `stop()` → 말풍선 글 = `kept.text`.
    - `3초 미만으로 끝나면 progress 가 null` · `3초 이상이면 running false 로 남는다` · `실패해도 3초 이상이면 남는다`.
    - `멈추면 1초여도 마지막 단계 stopped 로 남는다`.
    - `newConversation · close 는 타이머를 멈춘다`(`fakeAsync` 의 `pendingTimers` 비어 있음).
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/presentation/chat/cubit` → FAIL.
- [ ] **Step 3: 구현** — build_runner. `chat_tab_test.dart` 의 옛 "기록을 찾는 중…" 테스트가 그대로 통과하게 옛 줄 조건만 옮긴다.
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 답마다 진행 단계 · 경과 초를 들고 글 조각을 모아 그린다`

### Task 6: 진행 줄 위젯 `ChatProgressView` · 흐르는 중 커서 · l10n

스펙 §3.2 · §3.5(위젯 몫) · §3.6. 아직 화면에 끼우지 않는다(Task 7).

**Files:**
- Create: `lib/presentation/chat/widget/chat_progress_view.dart`
- Create: `lib/presentation/chat/widget/chat_progress_text.dart` — `ChatProgressStep` · `ChatProgress` → 문구(l10n · intl)
- Modify: `lib/presentation/chat/widget/chat_bubble_view.dart` — `streaming` 이면 글 끝 커서 `▍`
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`
- Test: `test/presentation/chat/widget/chat_progress_view_test.dart`(새) · `test/presentation/chat/widget/chat_progress_text_test.dart`(새) · `test/presentation/chat/widget/chat_bubble_view_test.dart`

**Interfaces:**
- Produces:
  ```dart
  /// 지금 단계 문구. 도구는 "라벨(자세히)", 결과가 있으면 결과 문구.
  String chatProgressStepText(AppLocalizations l10n, String locale, ChatProgressStep step);
  /// 접힌 요약 — "기록 3번 찾아봄 · 9초" · "9초" · "멈춤 · 기록 1번 찾아봄 · 4초".
  String chatProgressSummaryText(AppLocalizations l10n, ChatProgress progress);

  class ChatProgressView extends StatefulWidget {
    const ChatProgressView({required this.progress, super.key});
    final ChatProgress progress;
  }
  ```
  - 도구 자세히: `from`·`to` 가 있으면 `DateFormat.MMMd(locale)` 두 개를 `walkChatToolRange`(같은 날이면 하나), `query` 가 있으면 `walkChatToolQuery`. 둘 다 없으면 라벨만. `daily_steps` 는 기간 대신 날 수 `walkChatToolDays`(스펙 예 "걸음 수 보는 중(7일)").
  - 결과: `ToolSummary.isError` 면 라벨 그대로(오류 문구 없음), `count == 0` 이면 `walkChatToolFoundNone`, 아니면 종류별 결과 문구.
- **진행 중**(`running`): `Row(작은 스피너 | 줄이기 모드면 Icon(Icons.more_horiz), SizedBox(width: AppSpacing.xs), Flexible(AnimatedSwitcher(AppMotion.short, AppMotion.standard, Text(지금 단계, maxLines: 1, ellipsis))), elapsedSeconds >= 3 이면 ' · N초')`. 글꼴 `bodySmall`, 색 `onSurfaceVariant`. 스피너 크기는 `bodySmall` 글자 크기에서(숫자 하드코딩 없이 `IconTheme`/`textTheme` 에서 유도).
  - 접근성: 단계 문구를 `Semantics(liveRegion: true, label: 단계 문구)` 로, 경과 초는 `ExcludeSemantics` — 숫자 갱신은 읽지 않는다. 같은 단계 안에서 문구가 바뀌는 노트 누적은 liveRegion 대상이지만 **도구 단계 · 답 쓰는 중 · 멈춤으로 바뀔 때만** 라벨을 바꾼다(노트 단계 라벨은 처음 한 번만 — 스펙 §3.5).
- **끝남**(`!running`): 접힌 요약 한 줄 `▸ 요약`(누르면 `▾` + 단계 목록, 화면 상태 — `State` 의 bool). 목록은 단계마다 `· 문구`(도구는 `라벨 — 결과`), 끝은 `· 답 쓰기`(writing) 또는 `· 멈춤`. 펼침 · 접힘 · 요약으로 바뀌는 순간은 `AnimatedSize(AppMotion.medium)`. 탭 영역은 `InkWell` + `borderRadius: AppRadius.smAll`. 멈춤이면 아이콘 `Icons.stop_circle_outlined`.
- 줄이기 모드(`AppMotion.enabled == false`): 모든 duration `Duration.zero`, 스피너 대신 정지 아이콘.
- `ChatBubbleView` 에 `final bool streaming;`(기본 false) — true 이고 글이 있으면 글 끝에 커서 `▍`(`_cursor` 상수). 깜빡임은 `AppMotion.long` 주기(`AnimationController.repeat(reverse: true)`), 줄이기 모드면 고정. 커서는 `SelectableText` 의 글에 넣지 않고 `Text.rich` 의 별도 span 으로 — 복사하면 커서가 안 딸려 온다.

**l10n 새 키**(ko / en / ja, `@` description 은 "채팅 탭 진행 줄: …"):
| 키 | ko | en | ja |
|---|---|---|---|
| `walkChatPhaseSending` | 보내는 중 | Sending | 送信中 |
| `walkChatPhaseThinking` | 생각하는 중 | Thinking | 考え中 |
| `walkChatPhaseWriting` | 답 쓰는 중 | Writing | 回答を作成中 |
| `walkChatPhaseWritingDone` | 답 쓰기 | Answer | 回答 |
| `walkChatToolSearchDiary` | 일기 찾는 중 | Searching diary | 日記を検索中 |
| `walkChatToolViewPhotos` | 사진 보는 중 | Viewing photos | 写真を確認中 |
| `walkChatToolDiaryIndex` | 일기 목록 보는 중 | Viewing diary index | 日記の一覧を確認中 |
| `walkChatToolDailySteps` | 걸음 수 보는 중 | Checking steps | 歩数を確認中 |
| `walkChatToolWakeRecords` | 알람 기록 보는 중 | Checking alarm log | アラーム記録を確認中 |
| `walkChatToolOther` | 기록 보는 중 | Checking records | 記録を確認中 |
| `walkChatToolDetail` | {label}({detail}) | {label} ({detail}) | {label}（{detail}） |
| `walkChatToolRange` | {from}~{to} | {from}–{to} | {from}〜{to} |
| `walkChatToolQuery` | '{query}' | "{query}" | 「{query}」 |
| `walkChatToolDays` | {count}일 | {count, plural, =1{1 day} other{{count} days}} | {count}日 |
| `walkChatToolFoundEntries` | 일기 {count}개 찾음 | {count, plural, =1{Found 1 entry} other{Found {count} entries}} | 日記{count}件 |
| `walkChatToolFoundSteps` | 걸음 {count}일치 | {count, plural, =1{1 day of steps} other{{count} days of steps}} | 歩数{count}日分 |
| `walkChatToolFoundWake` | 기상 기록 {count}회 | {count, plural, =1{1 wake record} other{{count} wake records}} | 起床記録{count}回 |
| `walkChatToolFoundPhotos` | 사진 {count}장 | {count, plural, =1{1 photo} other{{count} photos}} | 写真{count}枚 |
| `walkChatToolFoundIndex` | 스토리 {count}개 | {count, plural, =1{1 story} other{{count} stories}} | ストーリー{count}件 |
| `walkChatToolFoundNone` | 찾은 기록 없음 | No records found | 記録なし |
| `walkChatProgressElapsed` | {seconds}초 | {seconds}s | {seconds}秒 |
| `walkChatProgressLookups` | 기록 {count}번 찾아봄 | {count, plural, =1{Checked records once} other{Checked records {count} times}} | 記録を{count}回確認 |
| `walkChatProgressJoin` | {a} · {b} | {a} · {b} | {a}・{b} |
| `walkChatProgressExpand` | 진행 과정 펼치기 | Show steps | 経過を表示 |

`walkChatStopped`(core) 를 멈춤 단계 · 요약에 재사용한다. `walkChatSearching` 은 Task 7 에서 지운다. 숫자 자리 표시자는 `"placeholders": {"count": {"type": "int"}}` 를 ko 에 적는다.

- [ ] **Step 1: 실패하는 테스트**
  - `chat_progress_text_test.dart`(ko · en 로케일): `도구 단계는 라벨(기간)` — search_diary 6/1~6/7 → `일기 찾는 중(6월 1일~6월 7일)` · `검색어면 '바다'` · `걸음은 날 수` · `결과가 있으면 결과 문구, 0개면 찾은 기록 없음, 오류면 라벨` · `요약 — 도구 3번 9초 → '기록 3번 찾아봄 · 9초', 도구 0번 → '9초', 멈춤 → '멈춤 · 기록 1번 찾아봄 · 4초'`.
  - `chat_progress_view_test.dart`:
    - `진행 중이면 지금 단계 문구와 스피너`.
    - `경과 초는 3초부터 보인다` — 2초 · 3초.
    - `끝나면 접힌 요약, 누르면 단계 목록이 펼쳐지고 다시 누르면 접힌다`.
    - `멈춤이면 정지 아이콘과 '멈춤'`.
    - `줄이기 모드면 스피너가 없고 AnimatedSwitcher · AnimatedSize duration 이 0`(`MediaQuery(disableAnimations: true)`).
    - `단계 문구는 liveRegion, 경과 초는 시맨틱에 없다`(`tester.getSemantics` · `matchesSemantics(isLiveRegion: true)`).
    - `색은 onSurfaceVariant`(테마 값과 비교 — 하드코딩 없음).
  - `chat_bubble_view_test.dart`: `streaming 이면 커서가 보이고 SelectableText 글에는 없다` · `줄이기 모드면 커서가 깜빡이지 않는다`(`AnimationController` 없음 또는 pump 뒤 같은 불투명도) · `streaming 이 아니면 커서 없음`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/presentation/chat/widget` → FAIL.
- [ ] **Step 3: 구현.**
- [ ] **Step 4: l10n** — 세 arb 에 키, `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 6: 커밋** — `feat(walk): 물어보기 진행 줄 · 접힌 요약 위젯과 흐르는 중 커서`

### Task 7: 물어보기 화면 — 진행 줄 자리 · 다시 그리기 쪼개기 · [↓ 새 답]

스펙 §3.2 자리 · §3.5 스크롤 · §4.1 둘째 줄 · §7.1. 재구성 · core · 기록 · 키 UX 가 `chat_tab.dart` 를 이미 고친 뒤에 한다 — 앱바 · ⋮ · 배너 · 시트는 건드리지 않고 `_ChatBody` · `_BubbleList` 만.

**Files:**
- Create: `lib/presentation/chat/widget/chat_jump_to_latest.dart`
- Modify: `lib/presentation/chat/page/chat_tab.dart`
- Modify: `lib/presentation/chat/widget/chat_bubble_view.dart` — 답 말풍선 위에 `ChatProgressView`
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` — `walkChatSearching` 삭제 · `walkChatJumpToLatest` 추가
- Test: `test/presentation/chat/page/chat_tab_test.dart` · `test/presentation/chat/widget/chat_jump_to_latest_test.dart`(새)

**Interfaces:**
- Produces:
  ```dart
  /// 위로 올려 둔 채 답이 자랄 때 입력칸 위에 뜨는 [↓ 새 답]. AppButton.secondary 를 감싼다.
  class ChatJumpToLatest extends StatelessWidget {
    const ChatJumpToLatest({required this.onPressed, super.key});
    final VoidCallback onPressed;
  }
  ```
- `ChatBubbleView`: assistant 이고 `bubble.progress != null` 이면 말풍선 **위**에 `ChatProgressView(progress: bubble.progress!)` + `SizedBox(height: AppSpacing.xs)`. `streaming: pending && bubble.text.isNotEmpty`.
- `_ChatBody` 쪼개기(스펙 §4.1):
  - 바깥: `context.select((ChatCubit c) => c.state.access)` 로 분기만.
  - 목록: `context.select((c) => c.state.bubbles.length)` 로 `ListView.separated(itemCount)` 만 다시 그림. 항목은 `_BubbleItem(index)` — `context.select((c) => c.state.bubbles.elementAtOrNull(index))` + `busy && index == last` 로 `pending`. 비었으면 `ChatExamples`.
  - 입력칸: `context.select((c) => (c.state.busy, c.state.restoredDraft))` 의 `ChatInput`(core 모양 그대로).
  - 옛 "기록을 찾는 중…" `Padding` 블록을 지운다.
- [↓ 새 답] (스펙 §3.5, Q8): `_BubbleList` 를 `StatefulWidget` 으로, 자기 `ScrollController`. `reverse: true` 그대로. 마지막 말풍선이 바뀌는 `BlocListener`(`listenWhen: 마지막 말풍선 text 길이 변화 && busy`)에서 `controller.offset > position.viewportDimension / 4` 이면 `_showJump = true`. 스크롤이 `offset <= viewport/4` 로 돌아오면(스크롤 리스너) 또는 답이 끝나면 숨김. 버튼은 `Stack` 으로 목록 아래쪽 가운데(`Positioned(bottom: AppSpacing.sm)`), 누르면 `AppMotion.enabled` 면 `animateTo(0, duration: AppMotion.medium, curve: AppMotion.standard)`, 아니면 `jumpTo(0)`. 맨 아래면 아무것도 하지 않음(지금처럼 `reverse` 가 아래를 보여 줌).
- l10n: `walkChatJumpToLatest` — 새 답 / New reply / 新しい回答(`@` "채팅 탭: 위로 올려 둔 채 답이 자랄 때 맨 아래로 가는 버튼"). `walkChatSearching` 은 세 arb 에서 지운다(`grep -rn walkChatSearching apps/walk` 결과 0).

- [ ] **Step 1: 실패하는 테스트**
  - `chat_jump_to_latest_test.dart`: `라벨 '새 답'과 아래 화살표, 누르면 onPressed` · `AppButton 을 쓴다`(`find.byType(AppButton)`).
  - `chat_tab_test.dart`(가짜 세션 이벤트로; 재구성 · 기록 · 키 UX 쪽 테스트는 손대지 않는다):
    - `입력칸 위 옛 '기록을 찾는 중…' 줄이 없다`.
    - `보내면 답 말풍선 위에 '보내는 중'이 보인다` — 진행 줄의 y 가 답 말풍선 y 보다 작고 입력칸과 떨어져 있음.
    - `도구 단계에서 '일기 찾는 중(…)', 결과에서 '일기 5개 찾음'`.
    - `3초 넘게 끝나면 접힌 요약 한 줄이 남고, 2초면 없다`.
    - `멈추면 진행 줄이 '멈춤'으로, 부분 답에 '멈춤' 표시`(core 테스트와 겹치지 않게 진행 줄만 확인).
    - `위로 스크롤한 채 답이 자라면 [↓ 새 답]이 뜨고, 누르면 맨 아래로 가며 사라진다` · `맨 아래에 있으면 뜨지 않는다`.
    - `경과 초가 올라도 사용자 말풍선과 입력칸은 다시 그리지 않는다` — 테스트 전용 빌드 카운터(`ChatInput` 을 감싼 `Builder` 의 build 횟수, 또는 `debugOnRebuildDirtyWidget` 대신 첫 말풍선 `ChatBubbleView` 를 `Key` 로 찾아 `State` 없는 위젯이므로 부모 `_BubbleItem` 의 build 를 세는 카운터 훅)로 `elapse(2s)` 전후 같음.
    - `줄이기 모드면 [↓ 새 답]이 바로 jumpTo`(애니메이션 없이 한 pump 에 offset 0).
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/presentation/chat` → FAIL.
- [ ] **Step 3: 구현.** 빌드 카운터가 필요하면 `_BubbleItem` 에 `@visibleForTesting static int debugBuilds` 를 두고 테스트 끝에 0 으로 돌린다(릴리스 영향 없음 — `assert` 안에서만 올림).
- [ ] **Step 4: l10n** — 세 arb 수정, `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 6: 커밋** — `feat(walk): 물어보기 진행 줄을 답 말풍선 위에 두고 화면을 조각으로 다시 그린다`

### Task 8: 문서 · 5단계 재측정 체크리스트

CLAUDE.md "진행 상태는 status.md 에만" · feature 완료 시 history · testing 갱신. 스펙 §7 문서 행 · §9 5단계 · §10.

**Files:**
- Modify: `apps/walk/docs/status.md` · `apps/walk/docs/history.md` · `apps/walk/docs/testing.md` · `apps/walk/docs/plan.md`
- Modify: `docs/superpowers/specs/2026-11-01-walk-chat-streaming-ux.md` — 끝 "측정 기록" 절에 V2 · V5 결과 자리와 "5단계 재측정 대기" 한 줄(측정값은 기기에서). 상태 줄에 "3 · 4단계 구현됨"

- [ ] **Step 1: `status.md`** — "물어보기" 절 체크 항목:
  - `[x]` 진행 줄(단계 · 도구 라벨 · 결과 개수 · 경과 초) · 접힌 요약 · [↓ 새 답] · 흐르는 중 커서(체감 속도 3단계)
  - `[x]` 진행 노트(`display: updates`) — V2 결과에 따라 **켜짐 / 꺼짐(대체 경로)** 중 실제 상수 값을 적는다
  - `[x]` 프롬프트 캐시 · 도구 병렬 · 도구 알림 앞당기기 · 글 모아 그리기 · 화면 조각 다시 그리기(4단계)
  - `[ ]` **5단계 재측정**(아래 체크리스트) — 기기 작업
  - 검증 줄: `flutter analyze` 0 · `flutter test` N건 통과(실행해서 숫자를 적는다).
- [ ] **Step 2: 5단계 체크리스트** — `testing.md` "물어보기 기기 시나리오"에 "대기"로(스펙 §2.3 절차 · §10 기준, 실기기 · Wi-Fi · 프로필 빌드 · 기본 모델 · 질문 5개 × 3회 중앙값, `chat.trace` 로 판정):
  - `[ ]` P1 보낸 뒤 0.3초 안에 진행 줄 "보내는 중"
  - `[ ]` P2 첫 의미 있는 표시(노트 · 도구 라벨 · 본문 중 먼저 = `firstVisible`) 기준선 대비 절반 이하 그리고 3초 이하
  - `[ ]` P3 도구 질문에서 진행 줄이 3초 넘게 같은 문구인 구간 없음(경과 초 제외)
  - `[ ]` P4 2라운드 이상 질문에서 라운드 2 `cacheRead > 0`
  - `[ ]` P5 한 응답 도구 둘 이상이면 도구 구간 ≤ 가장 느린 도구 + 50ms
  - `[ ]` P6 라운드 사이 짧은 글과 최종 답이 붙어 보이지 않음
  - `[ ]` P7 '애니메이션 줄이기'에서 전환 · 깜빡임 없이 같은 정보
  - `[ ]` P8 V2 청구 비교(`omitted`/`updates` 각 3회 `out` 중앙값) · V5 안내 줄 비용 → 스펙 "측정 기록"
  - `[ ]` P9 GPT 어댑터가 들어왔으면 같은 세트를 GPT 로 한 번(노트 없이도 P1 · P3 · P7)
  - 단위 테스트 표("물어보기 — 채팅 · 기상 기록 보관")에 행 추가 · 수정: `domain/chat/tool/tool_summary_test` · `presentation/chat/cubit/chat_progress_test` · `presentation/chat/widget/chat_progress_view_test` · `chat_progress_text_test` · `chat_jump_to_latest_test`, `anthropic_chat_model_test`(진행 이벤트 · display · 캐시) · `chat_session_test`(진행 순서 · 병렬 · 라운드 경계) · `chat_cubit_test`(단계 · 경과 초 · 글 모으기) · `chat_tab_test`(자리 · [↓ 새 답] · 다시 그리기). 맨 위 건수 갱신.
- [ ] **Step 3: `history.md`** — 새 절 `## 2026-11-xx — 물어보기 진행 표시 · 지연 줄이기`: 아래 "결정" 표(이유 포함), 구현 전 확인 V1~V6 결과(날짜 · 출처, 못 한 것은 "대기"), V2 게이트로 정한 `progressNotesDefault` 값.
- [ ] **Step 4: `plan.md`** — "물어보기 (채팅)" 절 "Claude 와 주고받는 형식"에: `thinking: {adaptive, display: updates}` + beta 헤더(켜졌을 때만, 대화 중 바꾸지 않음), top-level `cache_control`, 날짜 줄은 시스템 끝, 도구는 동시에 실행하고 결과는 호출 순서. 진행 이벤트 방출 규칙은 `chat_model.dart` doc 이 기준이라는 한 줄. 진행 줄 · 접힌 요약은 저장하지 않는다는 한 줄.
- [ ] **Step 5: 링크 검사** — `cd apps/trader && flutter test test/convention` → PASS.
- [ ] **Step 6: 커밋** — `docs(walk): 물어보기 진행 표시 · 지연 줄이기 반영과 재측정 체크리스트`

---

## 결정

이 계획을 쓰며 정한 것(스펙끼리 어긋나거나 스펙이 비워 둔 곳). Task 8 이 `history.md` 로 옮긴다.

| # | 결정 | 이유 |
|---|---|---|
| R1 | `display: updates` 는 어댑터 상수 `progressNotesDefault` 로 켜고 끄며 **`false` 로 시작**, V2 청구 확인으로 `true` 로 바꾼다. 꺼지면 `thinking` 파라미터 · beta 헤더 · 시스템 안내 줄을 함께 뺀다 | Q1 "청구가 늘면 노트 없이". 확인 전에 머지돼도 청구가 바뀌지 않는다. 대화 중에 바뀌지 않아 캐시도 안 깨진다 |
| R2 | `ChatModel` 에 `bool get progressNotes` 를 더한다(⟂ 키 기획 §8.2) | 시스템 프롬프트의 안내 줄은 벤더 중립 세션이 만들지만 "노트를 받을 수 있을 때만" 넣어야 한다(스펙 §4 "대체 경로면 이 줄도 뺀다"). 벤더 · 설정별로 어댑터만 안다 |
| R3 | `progress(text)` 는 **블록 누적 글**을 매번 다시 낸다(받는 쪽은 바꿔 끼움). 중단 문구의 접두사인 동안은 보류, 블록이 닫힐 때 판정 | 노트가 여러 delta 로 와도 반쪽 문장이 깜빡이지 않고, 중단 문구(스펙 §3.1)를 한 글자도 보이지 않는다. GPT 요약 delta 도 같은 규칙으로 맞추기 쉽다 |
| R4 | `thinking.display` 를 받는 모델 접두사 목록(`_progressNoteModels`)에 든 모델에만 보낸다 | 기본 모델이 키 기획에서 Sonnet 계열로 바뀌고 모델 칩으로 다른 모델을 고를 수 있다 — 안 받는 모델에 보내면 400. 목록은 V1 으로 확정 |
| R5 | **라운드 경계 줄바꿈은 세션이 넣는다**(`text('\n…')`), cubit 은 받은 글을 그대로 잇는다. `roundStarted` 는 진행 표시용으로만 | 스펙 §3.4 는 cubit 이 넣는다고 했지만, core 의 멈춤 규칙(`_turnText` = "cubit 이 보여 준 것과 같은 문자열 — 줄바꿈 포함")을 지키려면 한 곳에서 만들어야 어긋나지 않는다 |
| R6 | `ChatPhase` 는 `sending · thinking · writing` 셋. 도구 단계는 `toolStarted` 로, 스펙의 "이벤트는 왔는데 아직 블록 없음 → 생각하는 중"은 두지 않는다 | `message_start` → 첫 블록은 수 ms 라 보이지 않는다. 어댑터가 `message_start` 용 이벤트를 따로 내지 않아도 된다(계약이 작다) |
| R7 | 도구 결과는 **끝나는 대로** `toolFinished` 를 내고, 기록 · 사진 한도 · 인용 정리는 **호출 순서로 한 번에** | 진행 줄이 "3초 넘게 같은 문구"가 되지 않게 하면서, 스펙 §4 "결과 정리는 원래 순서로"와 사진 한도의 순서 의존을 지킨다 |
| R8 | 경과 초는 cubit 이 `Timer.periodic(1s)` + 주입 `Clock` 으로 올리고 상태에 담는다(위젯 자체 타이머 아님) | 말풍선이 스크롤로 빠졌다 다시 그려져도 초가 0 으로 돌아가지 않고, `fakeAsync` + `MutableClock` 으로 테스트된다. 다시 그리기는 Task 7 의 select 로 마지막 항목만 |
| R9 | 글 모으기는 `Timer(Duration.zero)` 한 바퀴(스펙 그대로) — 프레임 콜백이 아님. 다른 이벤트 · 멈춤 앞에서 동기로 비운다 | 한 프레임 이상 모으지 않는다(스펙 §4.1 단서). 멈춘 글과 보인 글이 늘 같다 |
| R10 | `ChatState.activeTool` 을 지우고 `ChatBubble.progress` 로 대신한다. 진행 정보는 저장하지 않는다(대화 기록 계획의 `ChatTurnDraft` 에 넣지 않음) | Q4. 진행 줄이 그 답 말풍선과 한 덩어리로 스크롤되고(스펙 §3.2 자리), 접힌 요약이 말풍선마다 남는다 |
| R11 | 도구 라벨은 "라벨(자세히)" 한 모양(`walkChatToolDetail`)으로 통일 — 스펙 예 "6월 1~7일 일기 찾는 중"은 "일기 찾는 중(6월 1일~6월 7일)"이 된다. 기간은 `DateFormat.MMMd(locale)` | 다섯 도구 · 세 언어에서 어순을 각각 맞추는 키 조합을 피한다. ja · en 에서도 같은 모양으로 읽힌다 |
| R12 | `ToolInputSummary.query` 는 20자로 자르고 `toString` 에서 뺀다. 검색어는 화면에만 간다 | 진행 줄 한 줄에 맞추고, core 의 "도구 입력값은 로그 · 계측 · toString 에 없음" 규칙을 지킨다 |
| R13 | 진행 줄 시맨틱은 단계 종류가 바뀔 때만 라벨을 바꾼다(노트 누적 · 경과 초는 읽지 않음) | 스펙 §3.5 "도구 단계 · 답 쓰는 중 · 멈춤 전환에만". 노트가 글자 단위로 자라며 계속 읽히는 것을 막는다 |
| R14 | 5단계 재측정은 task 가 아니라 `testing.md` 기기 시나리오 P1~P9 "대기"로 | 실제 키 · 실기기가 필요한 수동 작업(core 계획 Task 4 의 측정과 같은 처리) |
