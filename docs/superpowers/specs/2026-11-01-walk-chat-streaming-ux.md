# walk 물어보기 — 답변 체감 속도 · 진행 표시 · 멈춤 (수정 기획)

- 날짜: 2026-11-01
- 범위: walk 앱 물어보기(채팅) 탭에서 질문을 보낸 뒤 답이 끝날 때까지 화면에 보이는 것, 그 시간 자체, 그리고 답하는 중에 멈추기
- 상태: 기획만. 코드는 아직 바꾸지 않았다. 사용자 결정 반영(2026-11-01) — 결정은 끝의 "결정" 표
- 관련: [물어보기 설계](2026-10-27-walk-life-chat-design.md) · [키 입력 · 멀티 벤더 기획](2026-11-01-walk-chat-key-input.md)(§8 중립 계약 · §9 사용량) · [대화 기록 · 위키 기획](2026-11-01-walk-chat-history-wiki.md) · [화면 재구성 설계](2026-11-01-walk-nav-regroup-design.md)(먼저 들어감, §7.1) · [walk 계획](../../../apps/walk/docs/plan.md) · [walk 상태](../../../apps/walk/docs/status.md)

사용자 불편: "요청을 보내고 결과가 다 올 때까지 기다렸다가 한 번에 출력하는 것 같다. 실시간 스트리밍으로 답이 오게 할 수 있나?"

사용자 관찰: 화면이 `…` → `기록을 찾는 중…` → 답이 한 번에 나온다. 사용자는 "답이 너무 빨라서 한 번에 나온 것처럼
느낀 것일 수도"라고 했고 **속도 자체에는 만족**한다. 그래서 이 기획의 무게는 "더 빠르게"보다 **"지금 무엇을 하는지 보이게"**와
**"원하면 멈출 수 있게"**에 있다.

경로는 모두 `apps/walk/` 기준이다.

---

## 0. 결론 먼저

**스트리밍은 이미 끝까지 연결돼 있다. 문제는 "흐르는 동안 보여 줄 것이 거의 없다"는 것이다.**
질문 하나의 대부분 시간은 (a) 모델이 생각하는 구간, (b) 도구를 부르고 결과를 다시 보내는 왕복 구간이고,
이 구간에 화면에는 `…` 한 글자와 "기록을 찾는 중…" 한 줄만 있다. 글자가 흐르는 건 마지막 라운드의 짧은 답뿐이라
"다 모았다가 한 번에" 처럼 보인다. 마지막 답이 실제로 몇 조각에 걸쳐 오는지는 §2 계측으로 확인한다.

가장 큰 원인은 **Claude Opus 5.5 의 API 동작**이다. Opus 5.5 는 도구 호출 사이에 쓰는 안내 문장("지난주 기상 기록을
볼게요")을 `text` 가 아니라 **progress-update `thinking` 블록**으로 돌려주고, 기본 `display: "omitted"` 에서는 그 글이
**빈 문자열**이다. 지금 코드는 thinking 을 화면에 그리지 않으므로, 모델이 중간에 무엇을 말해도 사용자에게 닿지 않는다.
(기본 모델은 키 입력 기획에서 Claude Sonnet 계열로 바뀐다 — Sonnet 5.5 도 한두 문장 넘는 노트는 같은 방식이다.)

결정된 묶음:

1. 먼저 **디버그 계측**을 넣어 기준선을 잰다(§2). 완료 조건은 그 수치로 판정한다(§10).
2. `thinking.display: "updates"`(beta)로 진행 노트를 받아 **말풍선 위 진행 줄**에 보인다 — 단, 청구가 늘지 않는지 구현 전에 문서로 확인하고, 늘면 노트 없이 단계 · 경과 초만 쓴다(§3.1).
3. 진행 줄은 단계(보내는 중 → 생각하는 중 → "6월 1~7일 일기 찾는 중" → 답 쓰는 중)와 **경과 초**를 보인다. 끝나면 "기록 3번 찾아봄 · 9초" 한 줄로 접힌다(3초 미만이면 없음).
4. 도구 이름은 **`tool_use` 블록이 열리는 순간** 알리고, 도구는 **동시에** 실행한다. 프롬프트 캐시를 켠다(§4).
5. 답하는 동안 전송 버튼이 **[■ 멈춤]**이 된다. 어느 단계에서든 즉시 멈추고, 받은 글은 '멈춤' 표시로 남아 기록 · 다음 문맥에 들어간다(§6).

---

## 1. 원인 확인 — 코드 근거

### 1.1 흐름 (지금)

```
ChatCubit.send ─▶ ChatSession.ask ─▶ (라운드 1..8) AnthropicChatModel.stream ─▶ SSE
  말풍선 '' 추가      apiKey 읽기          ModelEvent.textDelta / completed       text_delta 만 밖으로
  busy=true          라운드마다 HTTP 1회    tool_use 면 도구 순서대로 실행
```

| 사실 | 근거 |
|---|---|
| 요청은 `'stream': true`, 모델 `claude-opus-5-5`, `effort: low`, `max_tokens: 16000`, 서버 fallback. **`thinking` 파라미터는 보내지 않는다** → Opus 5.5 기본(adaptive, `display: "omitted"`) | `lib/data/chat/anthropic_chat_model.dart:46-55` |
| SSE 를 줄 단위로 읽어 빈 줄마다 이벤트를 처리한다 — 버퍼링 없이 흘린다 | `anthropic_chat_model.dart:93-96`, `:177-190` |
| 밖으로 내는 이벤트는 `text_delta` → `ModelEvent.textDelta` **하나뿐**. `thinking_delta` · `signature_delta` · `input_json_delta` 는 블록에 모으기만 한다 | `anthropic_chat_model.dart:124-139` |
| `ModelEvent` 는 `textDelta` · `completed` 두 가지 | `lib/domain/chat/chat_model.dart:6-14` |
| `tool_use` 는 **응답이 끝난 뒤**(`completed`) 블록을 훑으며 `ChatEvent.toolStarted` 를 낸다. 도구는 **하나씩 차례로** `await` | `lib/domain/chat/usecase/chat_session.dart:121-134` |
| 라운드는 최대 8, 라운드마다 `messages` 전체를 다시 보낸다(사진 base64 포함). 프롬프트 캐시는 쓰지 않는다 | `chat_session.dart:48`, `:99-106`, `:172-188` |
| 매 질문 시작에 보안 저장소에서 키를 읽는다 | `chat_session.dart:88` |
| 실패 · 구독 끊김이면 그 질문에서 덧붙인 메시지를 되돌린다(`completed` 가 아니면 `removeRange`) | `chat_session.dart:149-157` |
| 세대(`_generation`) — `reset()` 이 올리면 진행 중 질문은 이벤트를 더 내지 않고 조용히 끝난다 | `chat_session.dart:63-80`, `:83` |
| 답하는 중에 끊는 길은 [새 대화]뿐: 구독 취소 + `session.reset()` → 대화 전체가 비워진다 | `lib/presentation/chat/cubit/chat_cubit.dart:93-100` |
| `ChatEvent.text` 마다 마지막 말풍선 글에 이어 붙이고 `activeTool` 을 비운다 | `chat_cubit.dart:105-111` |
| 도구 표시는 이름을 쓰지 않고 고정 문구 "기록을 찾는 중…" 한 줄. 입력칸 바로 위 | `lib/presentation/chat/page/chat_tab.dart:141-153`, `app_ko.arb` `walkChatSearching` |
| 입력칸은 답하는 동안 꺼진다(`enabled: !state.busy`) — 멈춤 버튼 자리가 없다 | `chat_tab.dart:154-157` |
| 글이 오기 전 답 자리는 고정 `…` | `lib/presentation/chat/widget/chat_bubble_view.dart:33`, `:42` |
| 화면 전체가 `BlocBuilder<ChatCubit, ChatState>` 하나 — delta 마다 목록 · 진행 줄 · 입력칸까지 다시 그린다 | `chat_tab.dart:118-162` |
| HTTP 는 `http.Client()`(dart:io `IOClient`, `package:http` 1.6.0) — 응답 바이트를 받는 대로 흘린다. 요청 중단 수단은 쓰지 않는다 | `lib/core/di/register_module.dart:90`, 루트 `pubspec.lock` |

### 1.2 추정 원인 검증

| # | 추정 | 판정 | 설명 |
|---|---|---|---|
| ① | thinking 구간은 아무것도 안 그려 멈춘 듯 보인다 | **맞다(가장 큼)** | `thinking_delta` 는 밖으로 안 나간다(`:129-131`). 게다가 기본 `omitted` 라 글자도 비어 있다. 이 구간에 화면은 `…` 또는 "기록을 찾는 중…" 그대로 |
| ①′ | (새로 찾음) 도구 사이 안내 문장도 thinking 으로 사라진다 | **맞다** | Opus 5.5 · Sonnet 5.5 는 한두 문장 넘는 도구 사이 노트를 progress-update `thinking` 블록으로 돌려주고, `omitted` 에서는 비어 있다(Claude API 문서 · 모델 이전 안내). 이전 세대라면 `text` 로 흘렀을 글이다 |
| ② | 대부분 질문은 도구 왕복 뒤 마지막 라운드에서야 글을 쓴다 | **맞다** | 시스템 프롬프트가 "도구로 찾아보고 근거해서만 답한다"(`chat_session.dart:203`)라 거의 모든 질문이 1회 이상 도구를 쓴다. 라운드마다 새 HTTP 요청 → 새 첫 토큰 지연(TTFT) |
| ③ | 마지막 답이 짧으면 흐르는 시간이 짧다 | **맞다 — 사용자 관찰과도 맞는다** | "마크다운 없이 짧은 평문"(`:206`). 2~3문장이면 1초 안에 다 흐른다. 앞에서 기다린 뒤 짧게 쏟아지면 "한 번에"로 느낀다. 서버가 실제로 큰 덩어리로 보내는지는 §2.1 의 delta 수 · 간격으로 확인 |
| ④-a | 위젯이 delta 마다 다시 그리는가 | **그린다 — 그러나 지연 원인은 아니다** | 매 delta 에 새 목록 + 화면 전체 rebuild. 짧은 답에서는 프레임 안에 끝난다. 긴 답 · 저사양 기기에서 버벅임 요인이라 §4.1 에서 줄인다 |
| ④-b | 라운드 사이 지연 | **있다** | `completed` 를 받은 뒤에야 도구를 시작하고(`:121`), 도구를 하나씩 기다리고(`:129`), 다음 요청이 캐시 없이 전체 기록을 다시 보낸다. `daily_steps` 는 Health Connect 를 읽어 수백 ms 걸릴 수 있다 — §2 로 잰다 |
| ④-c | 모델 자체 지연 | **있다 — 재 봐야 안다** | 모델 · effort · 서버 fallback(거절 시 다른 모델로 재시도). 라운드별 TTFT 를 모델별로 잰다(§2.3) |
| ⑤ | (새로 찾음) 도구 이름을 늦게 알린다 | **맞다(작음)** | `tool_use` 블록은 응답 중간에 열리는데(`content_block_start`), 알림은 `message_stop` 뒤 |
| ⑥ | (새로 찾음) 라운드 사이 짧은 `text` 가 최종 답에 붙는다 | **버그성** | 한 문장 이하 노트는 여전히 `text` 로 올 수 있다. cubit 은 구분 없이 같은 말풍선에 이어 붙여(`chat_cubit.dart:108`) "볼게요.지난주에는…"처럼 붙는다. §3.4 |

> **API 사실 출처**: Claude API 스킬 문서(2026-10 판). 구현 직전에 live 문서로 다시 확인한다(§3.1 확인 항목).

---

## 2. 측정 — 디버그 빌드 계측

고치기 전에 기준선을 잰다. 같은 계측을 고친 뒤에도 돌려 §10 완료 조건을 판정한다.

### 2.1 무엇을 찍나 (질문 하나 = 트레이스 하나)

| 표시 | 언제 | 찍는 곳 |
|---|---|---|
| `t0 send` | [보내기] 눌러 `ChatCubit.send` 진입 | cubit |
| `key` | 보안 저장소에서 키 읽기 끝 | session |
| `rN.req` | 라운드 N HTTP 요청 보냄(벤더 · 모델 · fast 여부 함께) | model |
| `rN.head` | 상태 줄 받음(서버 접수) | model |
| `rN.first` | 첫 SSE 이벤트 | model |
| `rN.block[i].start/stop` + 종류 | `thinking` · `text` · `tool_use`(이름) 블록 열림/닫힘 | model |
| `rN.firstText` | 라운드 첫 `text_delta` | model |
| **`rN.textDeltas`** | **라운드의 `text_delta` 개수 · 첫~마지막 delta 사이 ms · 가장 큰 조각 글자 수 · 조각 간격 중앙값** | model |
| `rN.firstProgress` | 라운드 첫 비어 있지 않은 `thinking_delta`(§3 적용 뒤) | model |
| `rN.stop` | `message_stop` · stop 종류 · usage(입력 · 출력 · 캐시 읽기/쓰기 토큰) | model |
| `tool.<name>.start/end` | 도구 실행 시작 · 끝, 결과 개수 | session |
| `firstVisible` | 화면이 처음 `…` 이외의 것으로 바뀐 프레임(진행 노트 · 도구 라벨 · 본문) | presentation |
| `firstGlyph` | 말풍선에 첫 본문 글자가 그려진 프레임 | presentation |
| `stop` | [■ 멈춤] 누름 → 구독 취소 끝 → HTTP 연결 닫힘(§6) | cubit · model |
| `done` | `ChatFinished`/`ChatFailed`/`ChatStopped` 처리 끝 | cubit |

**명시적 확인 항목 — "덩어리 도착인가"**: 마지막 라운드의 `rN.textDeltas` 로 판정한다.

- delta 가 여러 개(예: 5개 이상)이고 첫~마지막 간격이 수백 ms 이상 → **실제로 흐른다**. "한 번에"는 짧은 답 + 앞의 침묵 탓(③). 이 경우 본문 쪽은 손대지 않고 진행 줄로 해결한다.
- delta 가 1~2개이거나 간격이 수십 ms 이내 → **덩어리로 온다**. 원인을 더 본다: 서버가 큰 조각으로 보내는지(SSE 원시 간격), 앱이 모아서 그리는지(`firstGlyph` 와 `rN.firstText` 차이). 서버 쪽이면 우리가 바꿀 수 없음을 기록하고, 앱 쪽이면 §4.1 에서 고친다.
- 두 경우 모두 결과를 "측정 기록"에 남긴다.

### 2.2 어떻게

- 도메인 계약 `ChatTrace`(`lib/domain/chat/chat_trace.dart`, 새): `mark(String label, {Map<String, Object?> data})` · `begin()` · `end()`. 기본 구현은 아무것도 안 하는 `NoopChatTrace`.
- 디버그 · 프로필 빌드에서만 `DevChatTrace`(`lib/data/chat/dev_chat_trace.dart`)를 끼운다. `register_module` 에서 `kReleaseMode` 면 `NoopChatTrace`.
- 시간은 `Stopwatch` 단조 시계로 `t0` 기준 ms. **본문 · 키 · 도구 입력값은 찍지 않는다** — 라벨, 도구 이름, 개수, 토큰 수, stop 종류, 조각 글자 수만.
- 출력: 질문이 끝나면 한 줄 요약을 `dart:developer` `log(name: 'chat.trace')` 로. `flutter logs` / `adb logcat` 로 본다. 같은 표시를 `Timeline.instantSync` 로도 남겨 DevTools 에서 프레임과 겹쳐 본다.

  ```
  chat.trace q=3 vendor=anthropic model=claude-sonnet-5-5 fast=0 rounds=2 key=12
             r1{head=610 first=640 think=640-3900 tool:search_diary=3950-4010 stop=4020 in=2310 out=180}
             tool:search_diary=4030-4090(n=5)
             r2{head=4400 first=4420 firstText=6100 deltas=23/1180ms max=18ch gap~45ms stop=7300 in=4870 out=240 cacheRead=2100}
             firstVisible=4040 firstGlyph=6120 done=7350
  ```
- 프레임 쪽 표시는 cubit 이 emit 할 때 `SchedulerBinding.instance.addPostFrameCallback` 으로 찍는다(위젯이 계측을 모르게).
- 표시 이름은 벤더 중립 이벤트(§5) 단위다 — GPT 어댑터도 같은 줄을 남겨 벤더 비교가 된다.

### 2.3 측정 절차

- 기기: 실기기 1대(주 사용 폰) + 에뮬레이터 1대. Wi-Fi, 프로필 빌드(`flutter run --profile`).
- 질문 세트 5개 × 3회 = 15 트레이스: 예시 칩 3개(`chat_examples.dart` — 어제 · 먹은 것 · 기상) + "지난주 걸음 평균은?" + "6월에 찍은 사진 중 바다 나온 거 보여줘"(사진 도구).
- **모델별 비교**: 같은 세트를 기본 모델(키 기획이 정한 Claude Sonnet 계열)과, 모델 칩에서 고를 수 있는 다른 모델 · fast mode(지원 모델에서만)로 한 번씩. 이 기획은 기본값을 바꾸지 않는다 — 결과는 키 기획의 모델 칩 설명 근거로 넘긴다.
- 표로 정리: 모델별 · 질문별 중앙값 `firstVisible` · `firstGlyph` · `done`, 라운드 수, 라운드별 TTFT(`rN.first - rN.req`) · thinking 시간, 도구 시간, 라운드 사이 틈(`rN.stop → r(N+1).req`), 마지막 라운드 delta 수 · 간격, 토큰.
- 결과는 이 문서 끝 "측정 기록" 절에 붙인다(구현 1단계 산출물).

---

## 3. 진행 표시

### 3.1 무엇을 받아 오나 (API)

| 선택지 | 보이는 것 | 장단점 |
|---|---|---|
| 지금(`omitted`) | 없음 | 조용하다 |
| **`display: "updates"` (결정)** | 도구 사이 진행 노트만 글로(한두 문장). 추론은 숨김 | 사용자 말투의 짧은 안내 — 진행 줄에 맞다. beta 헤더 필요. 0개일 수도 있다 |
| `display: "summarized"` | 진행 노트 + 추론 요약이 섞여서 | 양이 많고 말투가 들쭉날쭉 — 쓰지 않는다 |

- 요청: `"thinking": {"type": "adaptive", "display": "updates"}` + `anthropic-beta` 에 `thinking-display-updates-2026-08-18` 를 기존 `server-side-fallback-2026-07-01` 과 쉼표로 함께.
- **대화 중에 `display` 를 바꾸지 않는다** — thinking 파라미터 변경은 메시지 캐시를 깬다. 어댑터 상수로 고정.
- 파싱: `thinking_delta` 가 **비어 있지 않은 글**을 실으면 그 블록은 진행 노트 → 중립 이벤트 `progress(text)`. 빈 블록은 `thinking()` 만. 블록은 지금처럼 서명과 함께 그대로 기록에 남긴다.
- 끊긴 응답의 마지막 블록이 정확히 `This part of the response was interrupted before it finished.` 이면 진행 노트로 보이지 않는다.
- 서버 fallback 으로 다른 모델이 답하면 노트가 안 올 수 있다 → 0개도 정상 경로.

**구현 전 확인 항목 — 토큰 · 청구 (사용자 우려)**

| 확인할 것 | 지금 알고 있는 것(스킬 문서 기준, 가정) | 확인 방법 |
|---|---|---|
| `display` 를 `omitted` → `updates` 로 바꾸면 청구가 늘어나는가 | 늘지 않는다. "display 는 보이는 것만 바꾼다 — thinking 은 어느 설정에서나 똑같이 생성 · 청구된다", 진행 노트는 요약이 아니라 **생성된 전체 길이로** `output_tokens` 에 청구된다(= 이미 지금도 청구 중) | live 문서(Extended thinking · progress updates 절) 재확인 + 같은 질문을 `omitted` / `updates` 로 각 3회 보내 `usage.output_tokens` 중앙값 비교(차이 ±10% 이내면 "안 늘어남") |
| 노트를 돌려받으며 응답 바이트가 늘어 입력 토큰이 느는가 | 다음 요청에 되돌려 보내는 thinking 블록은 어느 설정이든 같은 블록(서명 포함)이다 — 입력 쪽 변화 없을 것 | 위 비교에서 2라운드 `input_tokens` 도 함께 비교 |
| 시스템 프롬프트에 "도구 쓰기 전에 한 줄로 말해"(§4)를 넣으면 늘어나는가 | **조금 는다**(노트당 수십 토큰). 이건 표시 옵션이 아니라 프롬프트 탓 | 프롬프트 줄 있음/없음 비교. 늘어난 양을 "측정 기록"에 적고, 사용자가 원치 않으면 그 줄만 뺀다 |
| GPT(Responses API)에서 노트에 해당하는 추론 요약을 받으면 청구가 느는가 | 모른다 — 벤더 문서 확인 필요 | OpenAI 문서 + 같은 방식의 usage 비교 |

**대체 경로 — 청구가 늘어나면**: `display` 를 지금처럼 두고(노트 없음), 진행 줄은 **단계(보내는 중 · 생각하는 중 · 도구 라벨 · 답 쓰는 중) + 도구 결과 개수 + 경과 초**만으로 동작한다. 이 정보는 모두 앱이 이미 가진 신호(블록 열림 · 도구 실행 · 시계)라 토큰이 들지 않는다. 화면 설계(§3.2)는 노트가 0개인 경우를 이미 정상 경로로 갖고 있으므로 위젯 변경 없이 어댑터 상수 하나로 바뀐다. 벤더별로도 같다 — GPT 에서 요약이 청구를 늘리면 GPT 어댑터만 노트를 끈다.

### 3.2 화면 — 진행 줄

**자리**: 답 말풍선 **바로 위**(지금은 입력칸 위 — 시선이 말풍선과 떨어져 있다). 답 말풍선과 한 덩어리로 스크롤된다.

**모양**(진행 중):

```
 ◌ 6월 1일~7일 일기 찾는 중 · 4초
 ┌──────────────────────────┐
 │ …                        │   ← 본문이 오기 전엔 지금처럼 자리 표시
 └──────────────────────────┘
```

- 한 줄 = 단계 아이콘(작은 `CircularProgressIndicator`, 줄이기 모드면 정지 아이콘) + 지금 단계 문구 + `· N초`(1초마다 갱신, 3초부터 보임 — 빠른 답에서 숫자가 깜빡이지 않게).
- 단계 문구 우선순위(가장 최근 것 하나):

| 단계 | 문구 예 | 신호 |
|---|---|---|
| 보내는 중 | "보내는 중" | `send` 직후 ~ 첫 이벤트 |
| 생각하는 중 | "생각하는 중" | `thinking()`, 또는 이벤트는 왔는데 아직 아무 블록 없음 |
| 진행 노트 | 모델이 쓴 문장 그대로("지난주 기상 기록을 볼게요") | `progress(text)` — §3.1 대체 경로면 없음 |
| 도구 실행 | "6월 1~7일 일기 찾는 중" · "걸음 수 보는 중(7일)" · "사진 보는 중" · "알람 기록 보는 중" · "일기 목록 보는 중" | `toolCallStarted` → 이름으로 먼저, 입력이 완성되면(`toolCallReady`) 기간 · 검색어를 붙여 갱신 |
| 도구 결과 | "일기 5개 찾음" | 도구 끝(§3.3) — 다음 단계가 오기 전까지 |
| 답 쓰는 중 | "답 쓰는 중" | 이번 라운드 첫 `textDelta` |
| 멈춤 | "멈춤 · 4초" | [■ 멈춤] (§6) |

- 도구 라벨은 **앱이 만든 문구**(l10n)다. 입력에서 날짜 · 검색어만 꺼내 붙인다(`from`/`to` → "6월 1~7일", `query` → "'바다'").
- 끝나면(완료 · 실패 · 멈춤) 진행 줄은 **접힌 요약 한 줄**로 남는다: "기록 3번 찾아봄 · 9초"(도구 0번이면 "9초"만, 멈췄으면 "멈춤 · 기록 1번 찾아봄 · 4초"). **3초 미만이면 줄 자체를 없앤다**(멈춤은 예외 — 멈춤 표시는 늘 남긴다, §6.3). 누르면 펼쳐져 단계 목록이 보인다:

```
 ▾ 기록 3번 찾아봄 · 9초
   · 지난주 기상 기록을 볼게요
   · 알람 기록 보는 중(10월 25~31일) — 7회
   · 걸음 수 보는 중(7일) — 7일
   · 답 쓰기
```

- 펼침 상태는 말풍선별 화면 상태. 진행 노트 · 단계 목록 · 접힌 요약은 **대화 기록에 저장하지 않는다** — 다시 연 대화에는 요약 줄이 없다(멈춤 표시는 예외, §6.3).

### 3.3 도구 결과 요약

- **개수만.** "일기 5개 찾음" · "걸음 7일치" · "기상 기록 7회" · "사진 4장". `ToolResult` 에 `summary`(종류 + 개수)를 더해 도구가 직접 채운다.
- 본문 · 일기 제목은 보이지 않는다 — 근거 일기는 이미 인용 칩이 보인다(`cited_entry_chip.dart`).
- 0개면 "찾은 기록 없음".

### 3.4 라운드 경계와 본문

- `ChatEvent.roundStarted(n)` 를 둔다. cubit 은 라운드가 바뀐 뒤 처음 오는 `text` 앞에, 그 말풍선에 이미 글이 있으면 줄바꿈 하나를 넣는다(§1.2 ⑥ 방지).

### 3.5 스크롤 · 애니메이션

- 목록은 지금처럼 `reverse: true`. 맨 아래(offset 0)에 있으면 글이 늘어도 아래가 계속 보인다.
- 사용자가 위로 올려 둔 상태(offset > 화면 높이의 ¼)에서 답이 자라면 끌어내리지 않는다. 입력칸 위에 작은 **[↓ 새 답]** 버튼(`AppButton.secondary` 를 감싼 채팅 전용 위젯)을 띄우고, 누르면 `animateTo(0)` — 줄이기 모드면 `jumpTo(0)`.
- 진행 줄 문구 바뀜: `AnimatedSwitcher`(`AppMotion.short`, `AppMotion.standard`) 페이드. 접힌 요약으로 바뀔 때 `AnimatedSize`(`AppMotion.medium`). 펼침/접힘도 같은 토큰.
- 본문 글자에는 효과를 넣지 않는다(타자기 효과 없음). 흐르는 동안 말풍선 끝에 커서 `▍`; 깜빡임은 `AppMotion.long` 주기, 줄이기 모드면 고정.
- `AppMotion.enabled(context) == false`: 전환을 모두 `Duration.zero` 로, 스피너 대신 정지 아이콘, 커서 고정. 경과 초는 그대로.
- 접근성: 진행 줄에 `Semantics(liveRegion: true)`, 문구 갱신은 도구 단계 · 답 쓰는 중 · 멈춤 전환에만(경과 초 갱신은 제외).

### 3.6 공통 위젯 규칙

- 진행 줄 · 접힌 요약 · 타임라인은 채팅 전용이라 `lib/presentation/chat/widget/chat_progress_view.dart`(새). 색 · 여백 · 글꼴은 `AppSpacing` · `AppRadius` · `AppMotion` · `Theme.of(context)` 만.
- [↓ 새 답] · [■ 멈춤]은 각각 기존 공통 버튼/아이콘 버튼 스타일을 감싼 채팅 전용 위젯. 다른 화면에서도 쓰이면 그때 `design_system` 으로 올린다.

---

## 4. 지연 자체 줄이기

사용자는 속도에 만족하므로 아래는 **비용이 작고 부작용 없는 것만** 한다.

| 수단 | 기대 효과 | 단점 · 위험 | 결정 |
|---|---|---|---|
| **프롬프트 캐시** — 요청 top-level `cache_control: {type: "ephemeral"}` | 라운드 2 이후 · 이어지는 질문의 입력 처리 시간과 비용 감소(사진 대화에서 특히). 최신 Claude 모델 최소 캐시 단위 512 토큰 — 도구 정의 + 시스템만으로도 넘는다 | 첫 쓰기 1.25배(5분 TTL). 시스템 맨 앞 날짜 때문에 날이 바뀌면 깨진다 | **한다.** 날짜 줄은 시스템 끝으로(위키 기획서와 같은 제안). 계측의 `cacheRead` 로 확인. GPT 는 벤더 자동 캐시 — 어댑터에서 할 일 없음 |
| **도구 병렬 실행** | 한 응답에 도구 여럿이면 가장 느린 하나만큼만 | 사진 한도 계산이 순서에 기대므로 결과 정리는 원래 순서로 | **한다.** `Future.wait`, 결과는 호출 순서대로 한 메시지에 |
| **도구 알림 앞당기기** | 블록 열림 순간 진행 줄 갱신 | 실행까지 앞당기면 복잡 | **알림만** |
| `eager_input_streaming` | 도구 입력이 버퍼링 없이 흐름 | 우리 입력은 날짜 두 개 — 효과 없음, 검증 부담 | 하지 않는다 |
| **도구 전 한 줄 안내 유도**(시스템 프롬프트) — "도구를 쓰기 전에 무엇을 볼지 한 줄로 말해." | 진행 노트가 거의 늘 1개 이상 → 첫 의미 있는 표시가 빨라진다 | 출력 토큰이 조금 는다(§3.1 확인 항목). `updates` 없이는 효과 없음 | **§3.1 과 함께 한다.** 대체 경로(노트 없음)로 가면 이 줄도 뺀다 |
| effort | 이미 "낮음"(키 기획 §8.3 이 벤더별로 맞춤) | — | 유지 |
| 모델 · fast mode | Sonnet · Haiku 계열은 더 빠르다. fast mode 는 지원 모델에서 출력 최대 2.5배, 가격 2배 | 기본값은 키 기획 소관 | **이 기획은 바꾸지 않는다.** fast mode 는 키 기획의 **모델 칩 선택지**(지원 벤더 · 모델에서만). 이 기획은 계측에 벤더 · 모델 · fast 여부를 찍어 비교만 가능하게(§2) |
| 도구 정의 · 시스템 프롬프트 줄이기 | 이미 작다 | — | 손대지 않는다 |
| 도구 결과 크기(`search_diary` 최대 50개) | 다음 라운드 입력 감소 | 답 품질 영향 | 계측의 입력 토큰 보고 판단(보류) |
| 키 읽기 캐시 | 수~수십 ms | 키 교체 반영 | 계측에서 `key` 가 50ms 넘을 때만 |

### 4.1 다시 그리기 줄이기

- `ChatCubit` 은 `text` delta 를 바로 emit 하지 않고 **한 프레임(약 16ms)에 한 번**만 모아 emit 한다(`Timer(Duration.zero)` 합치기 — `fakeAsync` 로 검증). 단, §2.1 에서 "덩어리 도착"이 앱 쪽 원인으로 나오면 이 합치기가 범인이 아닌지 함께 본다(한 프레임 이상 모으지 않는다).
- `_ChatBody` 의 `BlocBuilder` 를 쪼갠다: 목록은 `bubbles` 만, 진행 줄은 `progress` 만, 입력칸 · 멈춤 버튼은 `busy` 만 `select`.

---

## 5. 멀티 벤더 — 중립 이벤트에 담을 진행 · 취소 계약

[키 입력 · 멀티 벤더 기획 §8](2026-11-01-walk-chat-key-input.md)이 중립 형식(`ModelEvent` · `ChatMessage` · `AssistantPart` · `TokenUsage`)과 어댑터를 소유한다. **MVP 벤더는 Claude + GPT, Grok(xAI)은 후속.** 이 기획은 진행 표시 · 멈춤에 필요한 것만 제안하고, 이름 · 모양은 그쪽에 맞춘다. ⟂ = 맞출 지점.

### 5.1 진행 이벤트

키 기획 §8.2 의 `ModelEvent` 는 `textDelta` · `completed(message, stop, usage)` 두 가지다. 여기에 더할 것:

| 중립 이벤트(제안) | 뜻 | Claude (MVP) | GPT (MVP) | Grok (후속) | ⟂ |
|---|---|---|---|---|---|
| `textDelta(text)` | 본문 조각 | `text_delta` | Responses 텍스트 delta | 후속 | 이미 있음 |
| `thinking()` | 생각 구간 시작(내용 없음) | thinking 블록 열림 | reasoning 항목 시작 | 후속 | ⟂ 이름 |
| `progress(text)` | 사용자에게 보일 진행 노트 | `display: "updates"` 의 비어 있지 않은 `thinking_delta` | 추론 요약 스트림(요청 옵션 · 청구 확인 필요, §3.1) — 못 주면 내지 않는다 | 후속 | ⟂ 0개가 정상 |
| `toolCallStarted(id, name)` | 도구 호출 블록 열림 | `content_block_start(tool_use)` | 함수 호출 항목 추가 이벤트 | 후속 | ⟂ |
| `toolCallReady(id, name, input)` | 입력 완성 | `content_block_stop` | 함수 인자 완료 이벤트 | 후속 | ⟂ `completed.message` 의 `ToolCallPart` 와 중복 — 어댑터가 둘 다 낸다 |
| (사용량) | 토큰 | — | — | — | **별도 이벤트를 두지 않는다.** 키 기획대로 `completed.usage` 를 쓴다(§9). 계측도 거기서 읽는다 |

- `ChatEvent`(domain, 화면 쪽)는 벤더와 무관하게: `phase(ChatPhase)` · `progress(text)` · `toolStarted(name, inputSummary)` · `toolFinished(name, resultSummary)` · `roundStarted(n)` · `text` · `finished` · `failed` · **`stopped(partialText)`**(§6). `ChatPhase { sending, thinking, tool, writing }`.
- 진행 노트를 못 주는 벤더에서도 진행 줄은 단계 + 도구 라벨 + 경과 초로 동작한다.

### 5.2 취소 계약 (⟂ 키 기획 §8 에 더할 것)

- **규칙**: `ChatModel.stream(...)` 이 돌려준 스트림의 **구독을 취소하면, 어댑터는 진행 중인 HTTP 요청을 즉시 닫는다**(연결 끊김 → 서버 생성 중단). 취소 뒤에는 이벤트 · 오류를 내지 않는다.
- 이것만으로 충분하게 둔다 — `CancelToken` 같은 별도 인자를 중립 계약에 더하지 않는다(Dart 스트림 취소가 곧 취소 신호).
- 구현(어댑터 공통): `package:http` 1.6.0 의 `AbortableRequest`(1.5.0 부터)를 쓰고, `abortTrigger` 에 넘긴 `Completer` 를 구독 취소(`onCancel`) 때 완료한다. `async*` 생성기 안이면 `try/finally` 에서 abort 를 완료한다. 공용 헬퍼(키 기획의 `sse_lines.dart`)에 `abortableSend(client, request)` 를 함께 둔다.
- 확인 항목: dart:io `IOClient` 에서 abort 가 소켓을 실제로 닫는지(계측 `stop` 의 "연결 닫힘" 표시와 서버 쪽 usage 로 확인), OpenAI Responses 가 연결 끊김 때 생성을 멈추는지(벤더 문서).

---

## 6. 답변 멈춤 (새 범위)

### 6.1 지금

- 답하는 동안 입력칸 전체가 꺼지고(`chat_tab.dart:154-157`), 멈출 방법은 앱바 [새 대화]뿐 — 그건 대화 전체를 지운다(`chat_cubit.dart:93-100` → `session.reset()`).
- 세션은 이미 "세대가 바뀌면 조용히 멈춤"과 "완료되지 않은 질문은 되돌림"을 갖고 있다(`chat_session.dart:63-80`, `:149-157`). 멈춤은 이 둘을 **대화를 지우지 않는 형태로** 쓴다.
- HTTP 는 구독을 끊어도 요청을 닫지 않는다(§1.1 마지막 줄) — 지금 [새 대화]로 끊어도 서버는 끝까지 생성 · 청구할 수 있다.

### 6.2 동작

**버튼**: 답하는 동안 입력칸의 전송 버튼 자리가 **[■ 멈춤]**(정지 아이콘 + 툴팁 "멈추기")으로 바뀐다. 입력칸 글자 칸은 지금처럼 꺼 둔다(답하는 중엔 다음 질문을 못 보냄 — 한 번에 하나 규칙 유지). 확인 창 없이 바로 멈춘다(되돌리기 쉬움 — 다시 물으면 된다).

**누르면 — 어느 단계든 즉시**:

| 단계 | 하는 일 |
|---|---|
| 보내는 중 · 생각하는 중 · 답 쓰는 중 | 모델 스트림 구독 취소 → 어댑터가 HTTP 를 닫음(§5.2) → 생성 · 과금 중단 |
| 도구 실행 중 | 도구 `Future` 는 취소할 수 없으므로 **결과를 버린다**(끝나도 기록 · 이벤트 없음). 로컬 읽기라 부작용 없음 |
| 라운드 사이 | 다음 요청을 보내지 않음 |

- 화면은 버튼을 누른 **같은 프레임**에 멈춤 상태로 바뀐다(아래 이벤트를 기다리지 않음). 세션은 즉시 다음 `ask` 를 받는다.

**세션 쪽 — `ChatSession.stop()`** (새)

- `reset()` 처럼 세대를 올려 진행 중 질문이 더 덧붙이지도 이벤트를 내지도 않게 하고 `_busy = false`. 다른 점: **대화 기록을 비우지 않고**, 이번 질문 몫을 아래처럼 정리한다.
- 그동안 받은 **최종 표시 글**(cubit 이 보여 준 것과 같은 문자열 — 라운드 경계 줄바꿈 포함)을 세션도 질문마다 모아 둔다(`_partialText`).
- 정리 규칙 (원본 기록은 덧붙이기만 — thinking 서명을 고치지 않는다는 원칙 유지):
  1. 이번 질문에서 덧붙인 원본 메시지(완료된 라운드의 assistant · tool 결과 포함)를 **지운다** — 지금 실패 때 되돌리는 것과 같은 꼬리 제거라 이전 기록(접두부)은 그대로다.
  2. 받은 글이 **있으면**: `user(질문)` + `assistant(text: 받은 글 + "\n(사용자가 여기서 멈춤)")` 를 **글만으로** 덧붙인다(thinking · 도구 블록 없음). 다음 질문의 문맥에 부분 답이 들어가고, 모델은 그 답이 미완성임을 안다.
  3. 받은 글이 **없으면**: 아무것도 덧붙이지 않는다(질문까지 되돌림).
- 확인 항목(구현 전): Claude 에서 thinking 이 켜진 대화에 thinking 블록 없는 assistant 턴을 넣어도 되는지(이전 턴 thinking 생략 — 대화 기록 기획의 "글만으로 다시 만들기"와 같은 질문이라 그쪽 확인 결과를 따른다), GPT 어댑터에서 reasoning 없는 assistant 턴. 중립 형식으로는 `ChatMessage.assistant(parts: [TextPart], vendorState: null)` 하나로 표현된다(⟂ 키 기획 §8.2).
- 멈춘 질문의 사진 수(`_imagesSent`)는 되돌린다 — 도구 결과를 지웠으므로 다음 요청에 실리지 않는다.
- 사용량: 끊긴 요청은 `completed.usage` 를 못 받으므로 기록되지 않는다(키 기획 §9 의 "실패 요청은 기록 안 함"과 같음). 서버는 끊기 전까지 생성분을 청구하므로 기록이 실제 청구보다 조금 적을 수 있다 — 사용량 화면에 이 한 줄을 적는 건 대화 기록 · 위키 기획 쪽에 넘긴다.

**cubit 쪽 — `ChatCubit.stop()`** (새)

- 구독 취소 → `session.stop()` → 즉시 emit: 마지막 답 말풍선을 `stopped: true` 로, `busy: false`, 진행 줄은 "멈춤 · N초" 요약.
- **받은 글이 있으면**: 질문 말풍선 + 부분 답 말풍선이 남는다. 답 말풍선 끝에 "멈춤" 표시(작은 정지 아이콘 + "멈춤", `onSurfaceVariant` `bodySmall` — 실패 문구와 같은 자리, 오류 색은 아님). 인용 칩은 그때까지 도구가 찾은 일기로 보인다(지금 `finished` 때만 읽으므로, 멈출 때도 모인 id 로 `_resolve` 한다).
- **받은 글이 없으면**: 질문 · 답 말풍선 둘 다 지우고, **질문을 입력칸에 되돌린다**(커서 끝, 키보드는 열지 않음). `AppSnackBar` info "멈췄어요" 한 번. 질문을 고쳐 다시 보내기 쉽고, 빈 말풍선이 남지 않는다.
- 늦게 도착하는 이벤트는 지금처럼 세대 비교로 버린다.
- [새 대화] · 화면 닫힘(`close`)은 지금처럼 `reset()` — 멈춤과 별개. 이 둘도 HTTP 를 닫게 되는 건 §5.2 덕분이다.

### 6.3 기록 · 진행 줄

- **대화 기록 저장**: 멈춘 답은 저장한다 — 보이는 대화(질문 · 받은 글 · 인용 id)에 `stopped` 표시 하나를 더해서. 저장 스키마(열 · 필드)는 [대화 기록 · 위키 기획](2026-11-01-walk-chat-history-wiki.md)이 반영한다. 다시 연 대화에도 "멈춤" 표시가 보인다. 글이 없어 되돌린 질문은 저장하지 않는다.
- 다시 연 대화를 이어 갈 때(`resume`) 멈춘 턴은 §6.2-2 와 같은 글(`… (사용자가 여기서 멈춤)`)로 다시 만든다 — 기록 기획의 "글만으로 다시 만들기" 규칙과 한 줄로 맞출 지점.
- 진행 줄: 멈추면 스피너가 정지 아이콘으로, 문구 "멈춤 · 4초", 곧 접힌 요약 "멈춤 · 기록 1번 찾아봄 · 4초". 3초 미만이어도 남긴다(사용자가 한 행동의 흔적). 펼친 단계 목록 맨 끝에 "· 멈춤".

### 6.4 과금 안내

- **따로 띄우지 않는다.** 멈춤은 과금을 **줄이는** 동작이고, 요금 경고는 키 등록 때 한 번 받는다(키 기획 §1.2). 대신 멈춤 버튼 툴팁/접근성 라벨은 "답 멈추기" 그대로.
- 정확성 메모(문서 · 도움말용, 화면 문구 아님): 멈추기 전까지 생성된 부분은 청구된다. 구현 전 확인 항목 — Anthropic · OpenAI 모두 스트리밍 연결을 끊으면 생성이 멈추고 그때까지만 청구되는지 live 문서로 확인. 연결을 끊어도 서버가 끝까지 생성한다면 이 문단과 §5.2 를 고친다.

---

## 7. 바꿀 파일

| 파일 | 변경 |
|---|---|
| `lib/domain/chat/chat_model.dart` | (키 기획 §8.2 위에) `ModelEvent` 에 `thinking` · `progress` · `toolCallStarted` · `toolCallReady`. 취소 계약 doc 주석(§5.2) |
| `lib/data/chat/anthropic_chat_model.dart` | `thinking: {adaptive, display: updates}` + beta 헤더(§3.1 확인 결과에 따라 상수), 위 이벤트 방출, top-level `cache_control`, `AbortableRequest` 로 취소 시 연결 닫기, 계측 표시 |
| `lib/data/chat/openai_responses_chat_model.dart` (키 기획이 새로 만듦) | 같은 진행 이벤트 · 취소 계약 · 계측 표시 |
| `lib/data/chat/sse_lines.dart` (키 기획이 새로 만듦) | `abortableSend` 헬퍼 |
| `lib/domain/chat/chat_trace.dart` (새) · `lib/data/chat/dev_chat_trace.dart` (새) | 계측 계약 · 디버그 구현(§2) |
| `lib/core/di/register_module.dart` | 릴리스면 `NoopChatTrace`, 아니면 `DevChatTrace` |
| `lib/domain/chat/usecase/chat_session.dart` | 새 `ChatEvent`(phase · progress · toolStarted 입력 요약 · toolFinished · roundStarted · stopped), 도구 병렬 실행, `stop()` · `_partialText` · 멈춘 턴 글만으로 덧붙이기, 시스템 프롬프트 — 날짜 줄 끝으로 · 도구 전 한 줄 안내 |
| `lib/domain/chat/tool/tool_result.dart` · `life_tools.dart` | `ToolResult.summary`(종류 + 개수), 도구 입력 → 라벨용 요약 |
| `lib/presentation/chat/cubit/chat_state.dart` · `chat_cubit.dart` | `activeTool` 대신 `ChatProgress`(단계 · 문구 · 시작 시각 · 단계 목록), 말풍선 `stopped` · 접힌 요약, 라운드 경계 줄바꿈, 프레임당 한 번 emit, `stop()`, 되돌린 질문 텍스트(`restoredDraft`) |
| `lib/presentation/chat/widget/chat_progress_view.dart` (새) | 진행 줄 · 경과 초 · 접힌 요약 · 타임라인 · 멈춤 상태 |
| `lib/presentation/chat/widget/chat_bubble_view.dart` | 흐르는 중 커서, 멈춤 표시, 진행 줄 자리 |
| `lib/presentation/chat/widget/chat_input.dart` | 답하는 중 전송 → [■ 멈춤], `onStop`, 되돌린 질문 채우기 |
| `lib/presentation/chat/page/chat_tab.dart` | 입력칸 위 "기록을 찾는 중…" 제거, `BlocBuilder` 쪼개기, [↓ 새 답], 멈춤 연결 · "멈췄어요" 스낵바 |
| `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` | 단계 문구 · 도구 라벨 5종 · 결과 요약 · 접힌 요약 · 경과 초 · [↓ 새 답] · 멈추기 · 멈춤 · 멈췄어요. `walkChatSearching` 은 지움 |
| `apps/walk/docs/plan.md` · `history.md` · `testing.md` · `status.md` | 완료 때(진행 상태는 `status.md` 에만). plan 의 "Claude 와 주고받는 형식"에 `display: updates` · 캐시 · 멈춤 규칙 추가 |

생성 파일(`*.freezed.dart`, `injection.config.dart`)은 build_runner 로. 대화 저장 스키마의 `stopped` 는 대화 기록 기획 쪽 파일에서.

### 7.1 화면 재구성과 겹치는 곳

[화면 재구성 설계](2026-11-01-walk-nav-regroup-design.md)(하단 탭 일기 · 물어보기 · 도구, 설정 탭 없앰)가 **먼저 들어간다.** 이 기획은 그 위에서 한다.

- **설정 위치**: 이 기획에는 설정 탭을 전제한 서술이 없다. 물어보기 관련 설정이 생기면 **물어보기 설정 화면**(⋮ → 물어보기 설정, push)에 둔다. 지금 이 기획이 더하는 설정 항목은 없다.
- **빠른 출력(fast mode)**: 사용자 결정대로 **모델 칩의 선택지**(키 기획 소유, 지원 벤더 · 모델에서만). 재구성 설계는 설정 화면을 제안했으나 사용자 결정을 따른다. 이 기획은 계측에 fast 여부만 찍는다.
- **앱바**: 물어보기 앱바가 [새 대화] + ⋮(대화 목록 · 위키 · 물어보기 설정 · 앱 설정)로 바뀐다. 이 기획의 [■ 멈춤]은 **입력창 쪽**(`chat_input.dart`)이고 [↓ 새 답]도 입력창 위라 앱바 변경과 겹치지 않는다. [새 대화]는 지금처럼 `reset()`(대화 비움)이고 멈춤과 별개 — 재구성 뒤에도 같다.
- **`chat_tab.dart` 겹침**: 재구성이 앱바(actions → [새 대화] + `AppOverflowMenu`), `onOpenSettings` 의 행선지(물어보기 설정 화면), 잠긴 동안 ⋮ 에 "앱 설정"만 보이기를 바꾼다. 이 기획은 같은 파일의 **본문**(`_ChatBody` 의 `BlocBuilder` 쪼개기 · 옛 "기록을 찾는 중…" 줄 제거 · 진행 줄 · [↓ 새 답] · 멈춤 연결 · "멈췄어요" 스낵바)을 바꾼다. 영역은 다르지만 한 파일이므로 재구성이 병합된 뒤 그 위에서 고치고, `chat_tab_test.dart` 도 재구성 쪽 변경(앱바 · ⋮)을 받은 뒤 이 기획의 항목을 더한다.
- 잠금(`DiaryLockGate`)은 재구성 뒤에도 물어보기 본문을 감싼다 — 진행 줄 · 멈춤은 게이트 안쪽이라 영향 없음. 잠기면 위젯이 트리에서 빠지지만 cubit 은 게이트 바깥 소유라 진행 중 답은 계속된다(지금과 같음).

## 8. 테스트

`test/` 는 `lib/` 구조 그대로.

| 파일 | 추가 · 수정 |
|---|---|
| `test/data/chat/anthropic_chat_model_test.dart` | 요청에 `thinking.display: "updates"` · beta 헤더 두 개 · top-level `cache_control` · 비어 있지 않은 `thinking_delta` → `progress` · 빈 thinking → `thinking()` 만 · `tool_use` 블록 시작 → `toolCallStarted`(입력 완성 전) · 정지 → `toolCallReady` · 중단 문구는 progress 로 내지 않음 · **구독 취소 시 abort 트리거가 완료되고 이후 이벤트 · 오류 없음**(가짜 클라이언트가 `AbortableRequest.abortTrigger` 를 관찰) · 기존 "thinking 블록을 서명과 함께 그대로" 유지 |
| `test/data/chat/openai_responses_chat_model_test.dart` (키 기획이 만듦) | 같은 진행 이벤트 · 취소 시 abort |
| `test/domain/chat/usecase/chat_session_test.dart` | 이벤트 순서(sending → thinking → progress → toolStarted → toolFinished → roundStarted(2) → text → finished) · 도구 둘이 동시에 시작되고 결과는 원래 순서 · 사진 한도는 순서대로 · 시스템 프롬프트 끝에 날짜, 한 줄 안내 포함. **멈춤**: (a) 생각 중 멈춤 → 기록 변화 없음 · 바로 다음 `ask` 가능 (b) 도구 실행 중 멈춤 → 늦게 끝난 도구 결과가 기록 · 이벤트에 없음, 사진 수 되돌림 (c) 1라운드 도구 뒤 2라운드 글 중간에 멈춤 → 기록 꼬리가 `user(질문)` + `assistant(text: 부분 글 + 멈춤 표시)` 하나로 바뀌고 앞선 기록은 그대로(서명 블록 불변) (d) 그 다음 질문의 요청 `messages` 에 부분 답이 들어 있음 (e) 연속 질문 — 멈춤 → 질문 → 멈춤 → 질문이 매번 정상 · `StateError` 없음 (f) 멈춘 뒤 늦은 모델 이벤트가 새 질문에 섞이지 않음 |
| `test/domain/chat/tool/life_tools_test.dart` | `summary` 개수 · 0개 · 입력 요약(기간 · 검색어) |
| `test/data/chat/dev_chat_trace_test.dart` (새) | 요약 줄 모양(delta 수 · 간격 포함) · 본문 · 키 · 입력값이 들어가지 않음 |
| `test/presentation/chat/cubit/chat_cubit_test.dart` | 단계 전이 · 라운드 경계 줄바꿈 · 한 프레임 안 delta 여럿이 emit 하나로(`fakeAsync`) · 끝나면 접힌 요약 · 3초 미만이면 요약 없음 · 실패해도 요약 남음. **멈춤**: 단계별(보내는 중 · 생각 · 도구 · 글쓰기) `stop()` 이 같은 emit 에서 `busy: false` · 글 있으면 `stopped` 말풍선 유지 + 그때까지 인용 · 글 없으면 말풍선 둘 제거 + `restoredDraft` = 질문 · 멈춤 요약은 3초 미만이어도 남음 · 멈춘 뒤 늦은 이벤트 무시 · 바로 다음 `send` 성공 |
| `test/presentation/chat/widget/chat_progress_view_test.dart` (새) | 단계 문구 · 3초부터 경과 초 · 접힘/펼침 · 멈춤 상태(정지 아이콘 · "멈춤") · 줄이기 모드면 스피너 · 전환 없음 |
| `test/presentation/chat/widget/chat_input_test.dart` (새) | busy 면 [■ 멈춤], 누르면 `onStop` · 아니면 전송 · 되돌린 질문이 채워짐 |
| `test/presentation/chat/page/chat_tab_test.dart` | 입력칸 위 옛 문구 없음 · 진행 줄이 답 말풍선 위 · 위로 스크롤 중 답이 자라면 [↓ 새 답] · 멈춤 → 부분 답에 "멈춤" 표시 · 글 없을 때 멈춤 → 입력칸에 질문 · "멈췄어요" 스낵바 |

## 9. 단계

1. **계측만**(§2) — 기준선, "덩어리 도착인가" 판정, 모델별 비교. 동시에 §3.1 · §6.4 의 청구 확인 항목을 실측으로 닫는다.
2. **멈춤 + 취소 계약**(§5.2 · §6) — 진행 표시보다 먼저. 취소가 HTTP 를 닫지 않으면 진행 표시를 늘려도 "멈춰도 돈이 나간다"가 남는다.
3. **진행 표시**(§3 · §5.1) — 1단계 확인 결과에 따라 노트 포함 또는 대체 경로.
4. **지연 줄이기**(§4) — 캐시 · 도구 병렬 · 알림 앞당기기 · 다시 그리기 줄이기.
5. 다시 측정, 완료 조건 판정.

`chat_model.dart` · `anthropic_chat_model.dart` · 새 GPT 어댑터는 키 기획의 중립 계약 작업과 겹치므로, 2단계부터는 그 형식이 들어간 뒤에 한다. `chat_tab.dart` 를 고치는 2단계 · 3단계는 화면 재구성이 병합된 뒤에 한다(§7.1).

## 10. 완료 조건

측정값은 §2.3 질문 세트 15회의 **중앙값**, 실기기 · Wi-Fi · 프로필 빌드, 기본 모델.

- [ ] 계측이 디버그 · 프로필 빌드에서 질문마다 요약 한 줄(벤더 · 모델 · fast 여부, 마지막 라운드 delta 수 · 간격 포함)을 남기고, 릴리스 빌드에는 없다. 기준선 표와 "덩어리 도착인가" 판정을 "측정 기록"에 붙였다
- [ ] §3.1 청구 확인 결과를 적었고, 그에 따라 노트 포함 경로 또는 대체 경로가 들어갔다
- [ ] 보낸 뒤 **0.3초 안**에 진행 줄("보내는 중")이 보인다
- [ ] **첫 의미 있는 표시**(진행 노트 · 도구 라벨 · 본문 중 먼저 오는 것)가 기준선 대비 절반 이하, 그리고 **3초 이하**
- [ ] 도구를 쓰는 질문에서 진행 줄이 **3초 넘게 같은 문구로 멈춰 있는 구간이 없다**(경과 초는 예외)
- [ ] 2라운드 이상 질문에서 라운드 2의 캐시 읽기 토큰 > 0(Claude)
- [ ] 도구 둘 이상 한 응답이면 도구 구간이 가장 느린 도구 시간 + 50ms 이하
- [ ] 라운드 사이 짧은 글과 최종 답이 붙어 보이지 않는다
- [ ] **멈춤**: 네 단계(보내는 중 · 생각 · 도구 · 글쓰기) 각각에서 누른 프레임에 버튼이 전송으로 돌아오고, 계측의 "연결 닫힘"이 누른 뒤 **0.5초 안**
- [ ] 멈춘 부분 답이 "멈춤" 표시로 남고, 다음 질문 요청 문맥에 들어가며(계측 · 테스트), 대화 기록에 `stopped` 로 저장된다(기록 기획 반영 뒤). 글이 없으면 질문이 입력칸으로 돌아온다
- [ ] 멈춤 → 바로 다음 질문을 5번 연속 해도 오류 · 섞임 없음
- [ ] '애니메이션 줄이기'에서 전환 · 깜빡임 없이 같은 정보가 보인다
- [ ] `flutter analyze` 0 · walk 전체 테스트 통과 · 에뮬레이터와 실기기에서 눈으로 확인(사진 질문 · 멈춤 포함), Claude · GPT 둘 다
- [ ] walk `plan.md` · `history.md` · `testing.md` · `status.md` 갱신

---

## 결정 (2026-11-01)

| # | 질문 | 결정 |
|---|---|---|
| Q1 | 진행 노트를 보일까 | **진행 노트 + 단계 + 경과 초.** 노트 표시가 청구를 늘리지 않는지 구현 전 확인, 늘면 노트 빼고 단계 · 경과 초만(§3.1) |
| Q2 | 끝난 뒤 진행 줄 | **접힌 요약 한 줄**, 3초 미만이면 없음(멈춤은 예외) |
| Q3 | 기본 모델 | 키 기획에서 **Claude Sonnet 계열**로 정함. 이 기획은 바꾸지 않고 계측을 모델별 비교 가능하게 |
| Q4 | 노트 · 요약 저장 | **저장 안 함**(멈춤 표시만 저장) |
| Q5 | fast mode | **키 기획의 모델 칩 선택지로**(지원 벤더 · 모델에서만). 이 기획은 계측에서 비교만 |
| Q6 | 도구 결과 | **개수만** |
| Q7 | beta 의존 | 기대되 **노트 0개여도 동작**, 구현 직전 재확인 |
| Q8 | 위로 스크롤 중 답이 자람 | **[↓ 새 답] 버튼** |
| — | 벤더 범위 | MVP **Claude + GPT**, Grok 후속 |
| — | 멈춤 | [■ 멈춤], 어느 단계든 즉시 · HTTP 닫기 · 부분 답은 멈춤 표시로 남기고 저장 · 다음 문맥에 포함 · 글 없으면 질문 되돌림 + 입력칸 복원(§6) |

## 열린 질문

(없음)

## 측정 기록

(구현 1단계에서 채운다 — 모델별 · 질문별 `firstVisible` · `firstGlyph` · `done` 중앙값, 라운드 수, 라운드별 TTFT · thinking · 도구 · 틈, 마지막 라운드 delta 수 · 간격, 토큰, `omitted`/`updates` 청구 비교, 멈춤 후 연결 닫힘 시간.)
