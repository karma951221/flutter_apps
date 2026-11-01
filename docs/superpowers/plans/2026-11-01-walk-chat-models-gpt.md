# walk 물어보기 — 모델 목록 · 칩 · 빠른 출력(키 입력 기획 ③) + GPT 어댑터 · 벤더 바꾸기 · 재동의(④) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 앱이 모델 id 를 고정하지 않게 한다 — 연결한 벤더의 모델 목록을 받아 채팅용만 남기고(도구 미지원 제외 · 사진 못 보는 모델 표시), 추천 계열의 최신을 기본으로, 물어보기 탭 상단 모델 칩 · 고르기 시트(최신순 · 추천 · NEW · 새 모델 점 · 빠른 출력 스위치)로 바꾸며, 하루 1회 갱신하고 사라진 모델은 추천으로 되돌린다(③). 그 위에 OpenAI Responses API 어댑터를 더하고, 물어보기 설정에서 Claude · GPT 중 하나로 연결 · 바꾸기(새 키 먼저 확인 → 한 확인 창 → 기존 키 교체)를 하며, 벤더를 바꾸면 다음 질문 전에 전송 동의를 다시 받고 대화는 이어 간다(④).

**Architecture:** 벤더별 "계열 규칙"(거르기 · 정렬 · 기본 고르기 · 이미지 · 생각 수준 · 빠른 출력 지원)은 domain 순수 함수(`chat_model_rules.dart`)에, 목록 캐시 · 본 id 는 domain 계약 `ChatModelCatalog` + data `PrefsChatModelCatalog` 에 둔다. 목록을 받아 오는 일은 원문 키를 읽는 기존 자리 `ChatKeyVerifier.fetchStored()` 하나로 모으고, 고른 모델 · 빠른 출력 · 갱신 시점 · 사라진 모델 복귀는 domain 유스케이스 `ChatModelChoice` 가 묶는다. 벤더 → 어댑터는 domain 계약 `ChatModelRegistry`(data `VendorChatModelRegistry`)로 고르고, `ChatSession.target` 이 설정의 벤더 + `ChatModelChoice.currentModel` 을 읽는다(`interimModel` 삭제). 모델만 바뀐 턴은 어댑터가 `vendorState` 를 버리고 parts 로 다시 만들고, 벤더가 바뀌면 세션이 문맥을 글로 접는다. 화면은 `ModelChip` · `ModelPickerSheet` · `VendorPickerSheet` 를 새로 두고 `ChatTab` 앱바 아래 · `ChatSettingsSection` 모델 행 · 연결 행에 끼운다.

**Tech Stack:** Flutter · flutter_bloc · Freezed 3 · injectable/get_it · `package:http`(`MockClient` · `AbortableRequest`) · shared_preferences · intl(`DateFormat`) · gen-l10n(`packages/l10n`, 기준 `app_ko.arb`).

**Spec:** [키 입력 · 멀티 벤더 기획](../specs/2026-11-01-walk-chat-key-input.md) §5(벤더 흐름) · §6.2~§6.4 · 결정 표(Q10 · Q11 · Q12 · Q14 · 모델 · 모델 칩 · 빠른 출력 모드 · 전송 동의 · 서버 저장) · §7.1~§7.4 의 ③ · ④ 몫 · §8.3 `OpenAiChatModel` · §8.4 넘김 규칙 · §10.1~§10.3 · §11~§14 의 ③ · ④ 행. [체감 속도 기획](../specs/2026-11-01-walk-chat-streaming-ux.md) §2.3 "모델별 비교" · §5 표 "모델 · fast mode" · Q5(빠른 출력은 모델 칩 선택지, 계측에 fast 여부만). Grok(⑤)은 범위 밖.

**선행(이 계획을 실행할 때 끝나 있다고 본다 — 코드는 아직 없을 수 있다. 각 task 첫 단계에서 `grep` 으로 실제 이름을 맞추고, 다르면 실제 이름을 따른다. 인터페이스 모양은 그대로):**
- [하단 탭 재구성](2026-11-01-walk-nav-regroup.md) — 코드에 들어가 있음: `openSettings(context, SettingsTarget)` · `ChatSettingsPage` · `ChatTab`(앱바 [새 대화] + `FeatureMenu(settings: SettingsTarget.chat)`, `RouteAware`).
- [중립 계약 · 계측 · 멈춤](2026-11-01-walk-chat-core.md) — `ChatVendor` · `ChatMessage`/`AssistantPart`/`ToolResultPart`/`ToolSpec`/`VendorTurnState`/`StopKind`/`TokenUsage`/`ModelEvent`/`ModelRequest`(손 클래스, `fastMode`) · `ChatModelErrorKind` · `AnthropicChatModel(http.Client, ChatTrace)` · `AnthropicTurnState` · `sseEvents` · `abortableSend` · `ChatTrace`/`ChatTraceMark` · `ChatUsageLog` · `ChatSession.interimModel` · `stop()`/`stoppedNote`.
- [키 UX(②)](2026-11-01-walk-chat-key-ux.md) — `ChatConnection`/`ChatKeyStatus`(`chat_connection.dart`) · `ChatSettings{connection, hasApiKey, apiKey, connect, disconnect, setKeyStatus, consented, setConsented}` · `SecureChatSettings`(`chat.apiKey` · `chat.vendor` · `chat.keyStatus`) · `maskApiKey`/`vendorOfKey`/`chatKeyPrefixHint` · `ChatModel.listModels` · `ModelInfo` · `ModelListResult` · `ChatKeyVerifier{verify, recheckIfUnverified}` · `ChatFailure{…quotaExceeded, modelUnavailable…}` · `ChatVendorIcon`(`confirmedLogos`) · `chatVendorName`/`chatVendorCompany` · `ChatSettingsCubit{check, connect, disconnect}` · `ChatKeyCheck` · `ChatKeyDialog.show(context, vendor:)` · `ChatSettingsSection(highlightConnection:)` · `RowHighlight` · `FakeChatKeyVerifier`.
- [대화 기록 1단계](2026-11-01-walk-chat-history.md) — `typedef ChatTarget = ({ChatVendor vendor, String model})` · `ChatSession.target` · `_contextTarget` · `_foldToText()` · `resume` · `reset({temporary})` · `ChatState.vendor` · `ChatTurnDraft.vendor/model` · `TemporaryChatBanner(vendor:)`. **③ 이 `target` getter 를 바꾸고 ④ 가 접기 조건을 좁힌다**(아래 결정 G3 · G16).

## Global Constraints

- 경로는 `apps/walk/` 기준. 테스트는 `test/` 아래 같은 구조(`lib/x/y.dart` ↔ `test/x/y_test.dart`).
- **저장소 전체 포맷 금지.** `dart format` 은 그 task 가 만든 · 고친 파일에만.
- **생성 파일**(`.freezed.dart` · `.g.dart` · `injection.config.dart`)은 손으로 고치지 않는다 — `cd apps/walk && dart run build_runner build --delete-conflicting-outputs`.
- Freezed(CLAUDE.md): 단일 모델은 Freezed 3 primary constructor, 변형은 `sealed class` + named factory. 분기는 `switch` 패턴 매칭(`when`/`map` 금지).
- UI 규칙(CLAUDE.md): `AppListTile` · `AppButton` · `AppSnackBar.show` · `AppConfirmDialog.show` · `AppPlaceholder` 우선. `Colors.*` · 숫자 여백 · `BorderRadius.circular(n)` 금지 — `AppSpacing` · `AppRadius` · `AppMotion` · `Theme.of(context)`. 요금 확인 창은 `isDestructive: false`.
- 문구는 l10n 만. 새 키는 `app_ko.arb` · `app_en.arb` · `app_ja.arb` 셋 다(ko 에는 `@키` description), 그 뒤 `cd packages/l10n && flutter gen-l10n`. 이미 있는 `commonCancel` · `commonRetry` 는 재사용.
- **원문 키는 예외 · 로그 · 상태 · `toString` · prefs · 계측 어디에도 남기지 않는다.** `apiKey()` 호출처는 `ChatSession` · `ChatKeyVerifier` 둘뿐 — 카탈로그 · `ChatModelChoice` · 화면은 키를 모른다(Task 3 · 6 끝에 `grep -rn "\.apiKey()" lib` 로 확인).
- **앱 코드에 모델 id 를 쓰지 않는다**(Q11 · 스펙 "모델"). 계열 정규식 · 제외 낱말만. 테스트 픽스처의 id 는 가짜 이름(`claude-sonnet-9-9` · `gpt-9` 등)으로 — 실제 출시 이름에 기대지 않는다.
- **벤더 문서 없이 단위 테스트가 돈다.** 벤더 응답은 `test/fixtures/chat/{anthropic,openai}/*.json|sse` — 손으로 만든 것. SSE 픽스처 첫 줄은 SSE 주석 `: hand-made — re-record (O7)` 처럼 다시 녹화할 확인 항목 번호를 단다(`sseEvents` 가 주석 줄을 버린다). JSON 픽스처는 `test/support/chat_fixtures.dart` 의 `handMadeFixtures` 목록에 경로 · 확인 항목을 적는다. 실제 응답을 녹화하면 키 · 계정 id 를 지우고 교체하며 목록에서 뺀다.
- 범위 밖: Grok(⑤) — 벤더 시트 · `ChatVendor` 에 xai 없음. 진행 줄 · 프롬프트 캐시(체감 속도 3 · 4단계). 위키(기록 2단계).
- 매 task 끝: `cd apps/walk && flutter analyze && flutter test` 0 오류 · 전체 통과. 커밋은 task 마다 하나(`feat(walk): …`, 문서는 `docs(walk): …`).

## Review Focus

1. **모델 id 가 코드에 없다(Task 1 · 4)** — `ChatSession.interimModel` 삭제, `lib/` 에 `claude-` · `gpt-` 로 시작하는 문자열 리터럴이 정규식 밖에 없다(`grep -rnE "'(claude|gpt)-" lib`). 요청 model 은 늘 `ChatModelChoice.currentModel`.
2. **목록이 없을 때 · 사라질 때(Task 3 · 6)** — 목록을 한 번도 못 받았으면 질문을 보내지 않고 `noModels`. 갱신한 목록에 고른 모델이 없으면 기본으로 되돌리고 탭이 보일 때 스낵바 한 번. 대화 중 `modelUnavailable` 이면 강제 갱신 뒤 "모델을 바꿨어요"(바뀐 경우만).
3. **넘김 규칙(Task 2 · 4 · 7)** — 같은 벤더 · 같은 모델 턴은 `vendorState` 원본 그대로(`identical`), 같은 벤더 · 다른 모델은 어댑터가 `vendorState` 를 버리고 text · 도구 호출 · 도구 결과로 다시 만든다, 벤더가 바뀌면 세션이 다음 `ask` 전에 글만으로 접는다. 사진 못 보는 모델이면 이전 도구 결과의 사진 · `view_photos` 정의가 요청에 없다.
4. **OpenAI 서버 저장 끄기(Task 7)** — 모든 Responses 요청에 `store: false` · `include: ["reasoning.encrypted_content"]`, `previous_response_id` 없음. Anthropic 쪽은 "보낼 옵션 없음" 주석 · 테스트가 그대로(core C2).
5. **벤더 바꾸기 원자성 · 재동의(Task 8)** — 새 키 확인이 끝날 때까지 기존 연결 그대로, 확인 창 [취소]면 아무것도 안 바뀜, [바꾸기] 뒤 쓰기 실패면 기존 연결 그대로. 바꾼 뒤 `consentedVendor ≠ vendor` → `needsConsent` 인데 말풍선은 남는다. 같은 벤더 키 교체 · 모델 변경 · 빠른 출력으로는 다시 묻지 않는다.
6. **빠른 출력은 지원 모델에서만(Task 1 · 5)** — 지원 표가 비어 있으면(확인 전) 스위치 · 번개가 어디에도 없고 요청 `fastMode` 는 늘 false. 처음 켤 때만 요금 확인 창.

## 구현 전 확인

live 벤더 문서 · 실기기가 필요한 "(확인 필요)" 항목(스펙 §10.3-1 · -2 · -4 의 ③ · ④ 몫). **어느 것도 단위 테스트를 막지 않게 설계했다** — 결과는 Task 9 에서 walk `history.md` 에 남긴다(날짜 · 출처, 못 한 것은 "대기").

| # | 확인할 것 | 필요한 task | 막히지 않게 한 설계 |
|---|---|---|---|
| A1 | Anthropic `GET /v1/models` — `limit` 상한, `has_more` · `last_id` 페이지 넘기기 파라미터(`after_id`), 날짜 없는 별칭이 목록에 오는지, `created_at` 형식 | Task 1 · 2 | 페이지 넘기기는 `has_more == true` 이고 `last_id` 가 String 일 때만(최대 5쪽). 필드가 다르면 첫 쪽만. 기본 고르기는 정렬 결과만 쓰므로 별칭 유무와 무관 |
| A2 | Anthropic **fast mode** — 요청 필드 · 베타 헤더 이름, 지원 모델(Sonnet 포함 여부), 가격 배수(체감 속도 기획 기준 2배) | Task 1 · 2 | 지원 표 `fastModeSpecs[anthropic]` 는 **빈 목록**으로 시작 → 스위치가 안 보이고 요청에 안 실린다. 필드는 어댑터 상수 `AnthropicChatModel.fastModeFields` · `fastModeBeta` 한 곳 — 확인 뒤 값과 지원 표 한 줄을 채운다. 테스트는 상수가 그대로 실리는지만 본다 |
| A3 | Anthropic `output_config.effort` 를 받지 않는 모델(옛 세대에 보내면 400) | Task 1 · 2 | 규칙 `supportsEffort(anthropic, id)` — 확인 전에는 `claude-(opus\|sonnet\|haiku)-\d` 중 메이저 4 이상(`claude-<계열>-4-…` 이후)만 true. 아니면 필드를 뺀다 |
| A4 | Anthropic: 다른 모델이 만든 thinking 블록을 **빼고**(text · tool_use · tool_result 만) 지난 턴을 보내도 400 이 없는지 | Task 2 | 단위 테스트는 변환까지. 기기에서 "모델 바꾸고 이어 묻기"(기록 계획 H3)로 확인. 400 이면 history 에 적고 사용자에게 묻는다(대안: 모델이 바뀌어도 세션이 글로 접기 — G3 를 되돌림) |
| O1 | OpenAI Responses — `store` 기본값(true 로 알려짐), `include: ["reasoning.encrypted_content"]` 가 `store: false` 에서만 · 비추론 모델에도 400 없이 받아지는지, reasoning 항목을 다음 요청 `input` 에 그대로 되돌리는 모양 | Task 7 | `store: false` · `include` 는 **늘** 넣는다(스펙). 비추론 모델이 400 이면 규칙 `supportsReasoning(openai, id)` 로 `include` 를 조건부로 바꾸는 한 줄(테스트 한 건 추가) |
| O2 | `function_call_output.output` 이 배열(`input_text` · `input_image`)을 받는지 | Task 7 | 생성자 인자 `imagesInToolOutput`(기본 **false** — 도구 결과는 글, 사진은 바로 뒤 `role: user` 입력의 `input_image`). 확인되면 기본값만 true 로. 두 경로 모두 테스트 |
| O3 | `reasoning.effort` 를 받지 않는 모델 | Task 1 · 7 | 규칙 `supportsEffort(openai, id)` — 확인 전에는 `^o\d` · `^gpt-(\d+)` 중 메이저 5 이상만 true |
| O4 | 목록 제외 낱말 최신화 · 도구 미지원 모델 · 이미지 미지원 모델 · 키 접두사 종류 | Task 1 | 제외 낱말 · 도구 미지원 · 이미지 미지원 패턴은 `chat_model_rules.dart` 의 `const` 표 세 개. 테스트는 표를 직접 쓰지 않고 표에 맞춘 가짜 id 로 |
| O5 | OpenAI 빠른 처리 등급 — 필드 이름(`service_tier: "priority"` 로 알려짐) · 지원 모델 · 가격 배수 | Task 1 · 7 | A2 와 같은 방식: `fastModeSpecs[openai]` 빈 목록 · 어댑터 상수 `OpenAiChatModel.fastModeFields` |
| O6 | OpenAI 오류 모양 — 401 `invalid_api_key`, 429 `insufficient_quota` vs `rate_limit_exceeded`, 404 `model_not_found`, 이미지 미지원 400 의 `error.code`, 스트림 중 `error` · `response.failed` 이벤트의 위치 | Task 7 | 매핑은 `error.code` → `error.type` → 상태 코드 순. 이미지 미지원 코드는 상수 `imageUnsupportedCodes`(확인 전 추정값 하나, 픽스처에 O6 표시) — 틀려도 `server` 로 떨어질 뿐 |
| O7 | Responses SSE 이벤트 이름 · 순서(`response.output_text.delta` · `response.output_item.added/done` · `response.function_call_arguments.delta/done` · `response.completed` · `response.incomplete` · `response.failed` · `error`), `usage` 위치 · 필드, 거절(`refusal` content) 모양 | Task 7 | 어댑터는 `response.output_text.delta`(글) 와 `response.completed/incomplete/failed`(마지막 `response` 객체 통째) 두 종류에만 기대고 결과는 `response.output` 에서 다시 읽는다 — 중간 이벤트 이름이 달라도 결과는 맞다. 픽스처 `stream_*.sse` 를 녹화로 교체 |
| O8 | OpenAI 브랜드 가이드(Q9 · §10.3-3) | Task 8 | key-ux K1 과 같은 방식 — `ChatVendorIcon.confirmedLogos` 에 넣기 전에는 모노그램 "G" |
| X1 | 벤더 공통 — 지금 5개 도구 스키마 키워드를 OpenAI 가 `strict: false` 에서 받는지, 다른 벤더 대화 이력을 글로만 넘길 때 문제없는지 | Task 7 · 8 | 도구는 `strict: false` 로 보낸다. 기기 확인은 testing.md "대기" |

---

### Task 1: 모델 계열 규칙 (domain 순수 함수)

스펙 §6.3 "거르기 · 기본값" · §6.4 · §10.1 · Q10 · Q11. Claude · GPT 규칙을 한 파일에 같이 둔다(순수 · 테스트 쉬움 — ④ 는 쓰기만). 화면 변화 없음.

**Files:**
- Create: `lib/domain/chat/chat_model_rules.dart`
- (`ModelInfo` 는 고치지 않는다 — 벤더가 준 값만 담고, 앱이 아는 능력은 이 파일의 규칙 함수로만 묻는다)
- Test: `test/domain/chat/chat_model_rules_test.dart`(새)

**Interfaces:**
- Produces:
  ```dart
  /// 빠른 출력을 지원하는 모델 묶음 하나. 구현 전 확인(A2 · O5) 전에는 표가 비어 있다.
  final class FastModeSpec {
    const FastModeSpec({required this.pattern, required this.priceFactor});
    final RegExp pattern;
    /// 요금 배수(안내 문구 "약 ○배"). 정수면 정수로 보인다.
    final double priceFactor;
  }

  /// 벤더별 빠른 출력 지원 표. 확인 뒤 한 줄씩 더한다.
  const Map<ChatVendor, List<FastModeSpec>> fastModeSpecs = {ChatVendor.anthropic: [], ChatVendor.openai: []};

  /// 채팅에 쓸 모델만 남기고 최신순으로 정렬한다(§6.3 거르기 1~3).
  /// - 벤더가 능력을 줬으면(supportsTools == false) 그걸로 뺀다.
  /// - anthropic: `^claude-` 전부. openai: `^gpt-\d` · `^o\d` 만, 제외 낱말 포함 id 와 도구 미지원 표에 맞는 id 는 뺀다.
  /// - 정렬: createdAt 내림차순, createdAt 이 없으면 입력 순서를 뒤에 그대로(안정 정렬).
  List<ModelInfo> chatModelsOf(ChatVendor vendor, List<ModelInfo> raw);

  /// 추천 계열의 최신(Q11). [models] 는 chatModelsOf 결과(최신순). 계열이 없으면 첫 항목, 비었으면 null.
  /// anthropic: `^claude-sonnet-` 첫 항목.
  /// openai: 플래그십 `^gpt-\d+(\.\d+)?(-\d{4}-\d{2}-\d{2})?$` 를 날짜 뺀 이름으로 묶어,
  ///   묶음 안 최대 createdAt 이 가장 늦은 묶음 → 그 안에서 날짜 없는 별칭, 없으면 가장 늦은 스냅샷.
  String? recommendedModelOf(ChatVendor vendor, List<ModelInfo> models);

  /// 이미지 입력 가능 여부. ModelInfo.supportsImages 가 있으면 그것, 없으면 이미지 미지원 표, 모르면 true(§6.4).
  bool supportsImagesOf(ChatVendor vendor, ModelInfo model);

  /// 생각 수준 파라미터를 받는가(A3 · O3). 아니면 어댑터가 필드를 뺀다.
  bool supportsEffortOf(ChatVendor vendor, String modelId);

  /// 빠른 출력 지원이면 그 spec, 아니면 null. [specs] 는 테스트 주입용.
  FastModeSpec? fastModeOf(ChatVendor vendor, String modelId, {Map<ChatVendor, List<FastModeSpec>> specs = fastModeSpecs});
  ```
  - 표(같은 파일 `const`, O4 · A3 · O3 확인 대상이라 한 곳): `_openAiExcludedWords = ['embedding','tts','whisper','transcribe','audio','realtime','image','dall-e','moderation','search','codex','instruct','babbage','davinci']`, `_openAiNoTools`(정규식 목록), `_openAiNoImages`(정규식 목록), effort 패턴.

- [ ] **Step 1: 실패하는 테스트** — `chat_model_rules_test.dart`(가짜 id 만):
  - `anthropic 목록은 claude- 전부 남기고 최신순` — createdAt 섞인 세 개 → 내림차순.
  - `openai 는 gpt-숫자 · o숫자만 남긴다` — `gpt-9` · `o9` 남고 `davinci-002` · `text-embedding-9` · `whisper-1` · `gpt-9-audio-preview` · `gpt-9-realtime` · `gpt-image-9` · `gpt-9-search-preview` · `gpt-9-codex` · `gpt-3.5-turbo-instruct` 빠짐.
  - `supportsTools 가 false 면 뺀다` · `도구 미지원 표에 맞으면 뺀다`(표에 맞춘 가짜 id).
  - `createdAt 이 없는 모델은 뒤로, 입력 순서 유지`.
  - `anthropic 추천은 최신 sonnet` — `claude-opus-9-9`(가장 새) · `claude-sonnet-9-8` · `claude-sonnet-9-7` → `claude-sonnet-9-8`.
  - `anthropic 에 sonnet 이 없으면 가장 최신` · `빈 목록이면 null`.
  - `openai 추천은 최신 플래그십 묶음의 별칭` — `gpt-9`(created 1) · `gpt-9-2026-10-01`(created 3) · `gpt-8`(created 2) · `gpt-9-mini`(created 4) · `gpt-9-pro`(5) → `gpt-9`.
  - `별칭이 없으면 그 묶음의 가장 늦은 스냅샷` · `gpt-9.5 는 gpt-9 와 다른 묶음` · `플래그십이 없으면 가장 최신`.
  - `supportsImagesOf: 벤더 값 우선 · 표 · 모르면 true`.
  - `supportsEffortOf` — 확인 전 규칙 대로 각 벤더 두 경우.
  - `fastModeOf: 기본 표는 비어 있어 null` · `specs 를 주면 패턴이 맞을 때 spec`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/domain/chat/chat_model_rules_test.dart` → 파일 없음으로 FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces.
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 모델 계열 규칙 — 채팅용 거르기 · 추천 · 능력`

### Task 2: Anthropic 어댑터 — 목록 페이지 · 모델별 필드 · 다른 모델 턴 · 레지스트리

스펙 §8.3 · §8.4(같은 벤더 다른 모델) · §10.1 · §11 "모델 id 고정 제거 · fast mode". 화면 변화 없음(모델은 아직 `interimModel`).

**Files:**
- Modify: `lib/domain/chat/chat_model.dart` — `ChatModelRegistry` 계약 · `ChatModelErrorKind.imagesUnsupported`
- Modify: `lib/data/chat/anthropic_chat_model.dart` — `@LazySingleton(as: ChatModel)` → `@lazySingleton`(구체 타입으로 등록), `listModels` 페이지 넘기기, effort · fast mode 조건부, 다른 모델의 `AnthropicTurnState` 는 parts 로
- Create: `lib/data/chat/chat_model_registry.dart`
- Modify: `lib/domain/chat/usecase/chat_session.dart` · `lib/domain/chat/usecase/chat_key_verifier.dart` — `ChatModel` 대신 `ChatModelRegistry` 를 받고 `of(vendor)`(세션은 아직 `_registry.of(ChatVendor.anthropic)` + `interimModel` — Task 4 에서 target)
- Create: `test/fixtures/chat/anthropic/models_page1.json` · `models_page2.json` · `test/support/chat_fixtures.dart`
- Modify: 테스트의 `implements ChatModel` 가짜를 쓰는 곳에 `FakeChatModelRegistry`(`test/support/fake_chat_model_registry.dart`, 새)
- Test: `test/data/chat/anthropic_chat_model_test.dart` · `test/data/chat/chat_model_registry_test.dart`(새) · `test/domain/chat/usecase/chat_key_verifier_test.dart`

**Interfaces:**
- Produces (`chat_model.dart`):
  ```dart
  /// 벤더 → 어댑터. domain 은 이 계약만 안다.
  abstract interface class ChatModelRegistry {
    ChatModel of(ChatVendor vendor);
  }
  // ChatModelErrorKind 에 더함: imagesUnsupported — 모델이 이미지 입력을 거절했다(§6.4). Anthropic 은 내지 않는다.
  ```
- Produces (`chat_model_registry.dart`):
  ```dart
  @LazySingleton(as: ChatModelRegistry)
  class VendorChatModelRegistry implements ChatModelRegistry {
    VendorChatModelRegistry(this._anthropic);   // ④ Task 7 에서 OpenAiChatModel 을 더한다
    @override ChatModel of(ChatVendor vendor) => switch (vendor) { anthropic => _anthropic, openai => throw UnsupportedError('④') };
  }
  ```
- Produces (`AnthropicChatModel`):
  ```dart
  /// fast mode 요청 필드 · 베타 헤더(A2). 확인 전 값은 문서 기억에 따른 자리표시이고 지원 표가 비어 있어 실리지 않는다.
  @visibleForTesting static const Map<String, Object?> fastModeFields = {/* A2 */};
  @visibleForTesting static const String? fastModeBeta = null; // A2
  ```
  - 요청 본문: `model: request.model`(core 그대로). `output_config: {effort: 'low'}` 는 `supportsEffortOf(anthropic, request.model)` 일 때만. `request.fastMode` 면 `fastModeFields` 를 본문에 펼치고, `fastModeBeta` 가 있으면 `anthropic-beta` 헤더에 쉼표로 덧붙인다(기존 `server-side-fallback-…` 유지). `fallbacks: 'default'` 그대로.
  - 메시지 변환(core 표에 한 줄 더함): `AssistantMessage` + `AnthropicTurnState` 인데 **`state.model != request.model`** → parts 로 다시 만든다(thinking 블록 없음, A4).
  - `listModels`: `GET /v1/models?limit=1000` → 응답 `has_more == true` 이고 `last_id` 가 String 이면 `&after_id=<last_id>` 로 다음 쪽(최대 5쪽, 쪽마다 `listTimeout`), 합친 목록. 둘째 쪽 이후가 실패하면 받은 쪽까지만 `ok`.
- `ChatKeyVerifier(this._registry, this._settings)` — `verify(vendor, key)` 는 `_registry.of(vendor).listModels(key)`(key-ux 의 "다른 벤더면 ArgumentError" 규칙은 없어진다).

- [ ] **Step 1: 실패하는 테스트**
  - `anthropic_chat_model_test.dart`:
    - `요청 model 은 ModelRequest.model 이다` — `claude-sonnet-9-9`.
    - `effort 는 supportsEffortOf 가 참일 때만 싣는다` — 참인 가짜 id · 거짓인 가짜 id(`claude-3-haiku-x`) 두 경우.
    - `fastMode 면 fastModeFields 를 싣고 아니면 싣지 않는다` — 상수 키가 본문에 있음/없음(상수가 비어 있으면 "본문이 fastMode false 때와 같다").
    - `다른 모델의 AnthropicTurnState 는 thinking 없이 text · tool_use 로 다시 만든다` · `같은 모델이면 원본 블록 그대로`(core 테스트 유지).
    - `listModels 는 has_more 면 after_id 로 다음 쪽을 받아 합친다` — `models_page1.json`(has_more true, last_id) · `models_page2.json`, 요청 URL 두 개 확인.
    - `둘째 쪽이 실패하면 첫 쪽만 ok` · `5쪽에서 멈춘다`.
  - `chat_model_registry_test.dart`: `anthropic 은 AnthropicChatModel` · `openai 는 아직 UnsupportedError`.
  - `chat_key_verifier_test.dart`: 기존 테스트를 레지스트리 가짜로 옮김. `verify 는 그 벤더 어댑터의 listModels 를 부른다`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/data/chat test/domain/chat` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces. 픽스처 JSON 두 개를 `handMadeFixtures` 에 `A1` 로 등록. `chat_session_test` 등 `_FakeModel` 을 쓰는 곳은 `FakeChatModelRegistry({anthropic: model})` 로 감싼다. build_runner(`injection.config.dart`).
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 Anthropic 어댑터가 모델별 필드 · 목록 페이지를 다루고 벤더 레지스트리를 둔다`

### Task 3: 모델 · 빠른 출력 저장 · 카탈로그 · `ChatModelChoice`

스펙 §6.3 전부 · §7.1(`selectedModel` · `fastMode`) · §7.2 · §4 "한 번 호출로 두 가지". 화면 변화 없음(아직 아무도 부르지 않음).

**Files:**
- Modify: `lib/domain/chat/chat_settings.dart` · `lib/data/chat/secure_chat_settings.dart`
- Create: `lib/domain/chat/chat_model_catalog.dart` · `lib/data/chat/prefs_chat_model_catalog.dart`
- Modify: `lib/domain/chat/usecase/chat_key_verifier.dart` — `fetchStored()`, `recheckIfUnverified` 삭제(호출처 `ChatCubit.refresh` 는 Task 6 에서 `ChatModelChoice.refresh` 로)
- Create: `lib/domain/chat/usecase/chat_model_choice.dart`
- Modify: `test/support/fake_chat_settings.dart` · `test/support/fake_chat_key_verifier.dart`; Create: `test/support/fake_chat_model_catalog.dart`
- Test: `test/data/chat/secure_chat_settings_test.dart` · `test/data/chat/prefs_chat_model_catalog_test.dart`(새) · `test/domain/chat/usecase/chat_key_verifier_test.dart` · `test/domain/chat/usecase/chat_model_choice_test.dart`(새)

**Interfaces:**
- Produces (`ChatSettings` 에 더함):
  ```dart
  /// 연결된 벤더(prefs, 동기). 미연결이면 null. ChatSession.target 이 쓴다 — 키 존재는 보장하지 않는다(hasApiKey 로 확인).
  ChatVendor? get connectedVendor;
  /// 고른 모델 id(`chat.model`). 없으면 null(= 추천).
  String? get selectedModel;
  Future<void> selectModel(String? id);
  /// 빠른 출력(`chat.fastMode`, 기본 false). 모델이 지원하지 않으면 값은 남고 요청에만 안 실린다.
  bool get fastMode;
  Future<void> setFastMode(bool on);
  /// 빠른 출력 요금 안내를 확인했는가(`chat.fastMode.ack`). 처음 켤 때 한 번만 묻는다.
  bool get fastModeAcknowledged;
  Future<void> acknowledgeFastMode();
  ```
  `connect` 가 **다른 벤더**로 바뀌면 `chat.model` 을 지운다(④ 대비, ③ 에서도 규칙으로 넣는다). `disconnect` 도 `chat.model` 을 지운다. `fastMode` · `ack` 는 남긴다.
- Produces (`chat_model_catalog.dart`):
  ```dart
  /// 받아 둔 모델 목록(채팅용만 · 최신순) · 갱신 시각 · 본 id. 원문 키를 모른다.
  abstract interface class ChatModelCatalog {
    /// 목록을 받은 벤더. 비어 있으면 null.
    ChatVendor? get vendor;
    List<ModelInfo> get models;
    DateTime? get fetchedAt;
    /// recommendedModelOf 결과.
    String? get recommended;
    ModelInfo? find(String id);
    /// [raw] 를 chatModelsOf 로 걸러 저장한다. 벤더가 바뀌었거나 처음이면 본 id = 전부(모두 NEW 가 되지 않게).
    Future<void> replace(ChatVendor vendor, List<ModelInfo> raw, DateTime at);
    Future<void> clear();
    /// 지금 목록의 id 를 모두 본 것으로.
    Future<void> markAllSeen();
    bool isNew(String id);
    /// [currentId] 보다 createdAt 이 늦고 아직 안 본 모델이 있는가(칩의 점).
    bool hasUnseenNewer(String? currentId);
    /// 400 이미지 거절을 받은 모델을 "사진 못 봄"으로 기록(§6.4). 다음 replace 에도 유지.
    Future<void> markNoImages(String id);
    bool supportsImages(String id);
  }
  ```
  `PrefsChatModelCatalog`(`@LazySingleton(as: ChatModelCatalog)`) — prefs `chat.models`(JSON 배열: `id` · `name` · `created`(ms) · `tools` · `images`), `chat.models.vendor`, `chat.models.fetchedAt`(ms), `chat.models.seen`(StringList), `chat.models.noImages`(StringList). JSON 이 깨졌으면 비어 있는 것으로.
- Produces (`ChatKeyVerifier`):
  ```dart
  /// 저장된 키 · 벤더로 목록을 받는다(원문 키를 읽는 두 곳 중 하나). 키 상태도 기록한다:
  /// ok → valid, invalidKey → invalid, unreachable → 그대로. 미연결이면 null. 동시에 불리면 하나를 같이 기다린다.
  Future<(ChatVendor, ModelListResult)?> fetchStored();
  ```
- Produces (`chat_model_choice.dart`):
  ```dart
  sealed class ModelsRefresh { // @freezed union
    const factory ModelsRefresh.skipped() = ModelsSkipped;          // 24시간 안 · 미연결
    const factory ModelsRefresh.updated({required bool replacedSelection}) = ModelsUpdated;
    const factory ModelsRefresh.invalidKey() = ModelsInvalidKey;
    const factory ModelsRefresh.unreachable() = ModelsUnreachable;
  }

  /// 고른 모델 · 빠른 출력 · 목록 갱신을 묶는다. 키를 모른다(ChatKeyVerifier 를 거친다).
  @lazySingleton
  class ChatModelChoice {
    ChatModelChoice(this._settings, this._catalog, this._verifier, this._clock);
    static const maxAge = Duration(hours: 24);

    /// 다음 질문에 쓸 모델: 고른 모델이 목록에 있으면 그것, 아니면 추천. 목록이 없거나 벤더가 다르면 null.
    String? get currentModel;
    ModelInfo? get currentInfo;
    bool get usingRecommended;
    /// 지금 모델이 빠른 출력을 지원하는가(fastModeOf != null).
    bool get fastModeAvailable;
    FastModeSpec? get fastModeSpec;
    /// 요청에 실을 값 = settings.fastMode && fastModeAvailable.
    bool get fastModeOn;
    bool get hasUnseenNewer;           // catalog.hasUnseenNewer(currentModel)
    bool get supportsImages;           // 지금 모델 기준

    /// force 거나 fetchedAt 이 maxAge 를 넘었거나 · 목록 벤더가 연결 벤더와 다르거나 · 키 상태가 unverified 면 받는다.
    /// 실패는 조용히(캐시 유지). 받은 목록에 selectedModel 이 없으면 selectModel(null) + 알림 표시를 세운다.
    Future<ModelsRefresh> refresh({bool force = false});
    /// 키 저장 직후 check 결과 목록을 그대로 넣는다(§4 한 번 호출로 두 가지).
    Future<void> adopt(ChatVendor vendor, List<ModelInfo> raw);
    Future<void> forget();             // 끊기 → catalog.clear
    Future<void> select(String id);    // 추천과 같으면 null 로 저장(추천을 따라가게)
    Future<void> setFastMode(bool on);
    /// 대화 중 modelUnavailable(§6.3 끝): 강제 갱신 뒤 지금 모델이 바뀌었으면 true.
    Future<bool> recoverFromUnavailable(String failedModel);
    Future<void> markNoImages(String id);

    /// "고른 모델이 없어져 추천으로 바꿨어요" 를 한 번 보일 차례인가. 메모리(앱을 다시 켜면 사라진다).
    bool get selectionReplacedNotice;
    void consumeSelectionReplacedNotice();
  }
  ```
  `select(id)` 에서 `id == recommended` 면 `selectModel(null)` — 추천이 새 모델로 바뀌면 따라간다(결정 G6).

- [ ] **Step 1: 실패하는 테스트**
  - `secure_chat_settings_test.dart`: `connectedVendor 는 prefs 벤더를 동기로 준다` · `selectModel · fastMode · acknowledgeFastMode 왕복` · `다른 벤더로 connect 하면 chat.model 을 지운다, 같은 벤더면 남긴다` · `disconnect 는 chat.model 을 지우고 fastMode 는 남긴다`.
  - `prefs_chat_model_catalog_test.dart`(`SharedPreferences.setMockInitialValues`):
    - `replace 는 거른 목록을 최신순으로 저장하고 다시 읽어도 같다`(새 인스턴스로 읽기).
    - `처음 replace 면 모두 본 것 · NEW 없음` · `다음 replace 에 새 id 는 NEW` · `벤더가 바뀌면 다시 모두 본 것`.
    - `hasUnseenNewer: 지금보다 늦게 만든 안 본 모델이 있을 때만` · `markAllSeen 뒤 false`.
    - `recommended 는 recommendedModelOf 결과` · `find`.
    - `markNoImages 는 replace 뒤에도 남는다` · `supportsImages 는 표 · 기록을 함께 본다`.
    - `chat.models JSON 이 깨졌으면 빈 목록` · `clear`.
  - `chat_key_verifier_test.dart`: `fetchStored: 미연결이면 null · 모델을 부르지 않음` · `ok → valid 기록하고 (vendor, ok)` · `invalidKey → invalid` · `unreachable → 상태 그대로` · `동시에 두 번이면 listModels 한 번`.
  - `chat_model_choice_test.dart`(가짜 settings · 실제 `PrefsChatModelCatalog` · 가짜 verifier · `MutableClock`):
    - `목록이 없으면 currentModel null` · `고른 모델이 없으면 추천` · `고른 모델이 있으면 그것`.
    - `select 가 추천과 같으면 null 로 저장한다`.
    - `refresh: 24시간 안이면 skipped, verifier 를 부르지 않음` · `넘었으면 받는다` · `force 면 받는다` · `unverified 면 24시간 안이어도 받는다` · `카탈로그 벤더가 연결 벤더와 다르면 받는다`.
    - `refresh 실패(unreachable)면 캐시 그대로` · `invalidKey 면 ModelsInvalidKey`.
    - `받은 목록에 고른 모델이 없으면 추천으로 되돌리고 알림을 한 번 세운다` — `selectionReplacedNotice` true → consume 뒤 false.
    - `fastModeOn 은 지원 모델 + 설정이 켜졌을 때만` — `fastModeOf` 지원 표를 주입할 수 있게 `ChatModelChoice` 에 `@visibleForTesting fastModeSpecs` 인자.
    - `recoverFromUnavailable: 갱신 뒤 모델이 바뀌면 true, 같으면 false`.
    - `adopt 는 목록을 넣고 fetchedAt 을 지금으로` · `forget 은 비운다`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/data/chat test/domain/chat` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces. `FakeChatSettings` 에 새 필드 · `FakeChatModelCatalog`(메모리). `grep -rn "recheckIfUnverified" lib test` 로 남은 호출을 Task 6 표시(TODO 아님 — 이 task 에서 `ChatCubit.refresh` 의 호출을 `fetchStored` 로 임시 바꿔 컴파일만 유지). build_runner.
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS. `grep -rn "\.apiKey()" lib` → `chat_session.dart` · `chat_key_verifier.dart` 둘.
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 모델 목록 캐시 · 고른 모델 · 빠른 출력을 저장하고 하루 한 번 갱신한다`

### Task 4: 세션 — 지금 모델 · 빠른 출력 · 사진 못 보는 모델 · 넘김 규칙

스펙 §8.4 · §6.4 · §6.3 끝(대화 중 모델 없음) · §7.3 `noModels` · Q14. 기록 계획 Task 4 의 `target` · 접기를 바꾼다. 화면 변화: 새 실패 문구 두 개.

**Files:**
- Modify: `lib/domain/chat/usecase/chat_session.dart`
- Modify: `lib/domain/chat/tool/life_tools.dart` — `definitionsFor({required bool images})`
- Modify: `lib/presentation/chat/widget/chat_failure_text.dart` · `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`
- Modify: `lib/presentation/chat/cubit/chat_cubit.dart` — `_session.target` 이 nullable 이 된 곳(기록 계획 `send` · `refresh`)만 맞춤
- Test: `test/domain/chat/usecase/chat_session_test.dart` · `test/domain/chat/tool/life_tools_test.dart` · `test/presentation/chat/widget/chat_failure_text_test.dart`

**Interfaces:**
- Produces:
  ```dart
  ChatSession(this._registry, this._tools, this._settings, this._choice, this._clock, this._usage, this._ids, this._trace);
  // interimModel 삭제.

  /// 다음 질문의 벤더 · 모델. 미연결이거나 모델 목록이 없으면 null.
  /// = (vendor: _settings.connectedVendor, model: _choice.currentModel)
  ChatTarget? get target;

  enum ChatFailure { noKey, noModels, invalidKey, quotaExceeded, modelUnavailable, modelReplaced, rateLimited, overloaded, network, refused, tooManySteps, unknown }
  ```
  `LifeTools.definitionsFor({required bool images})` — `images == false` 면 `view_photos` 를 뺀 4개. `definitions` 는 `definitionsFor(images: true)` 로 남긴다.
- 규칙:
  - `ask` 시작: 키 없음 → `noKey`(그대로). `target == null` → `ChatFailure.noModels`(요청 없음). 그 질문 동안 `t = target!` 고정.
  - 요청: `ModelRequest(model: t.model, fastMode: _choice.fastModeOn, tools: _tools.definitionsFor(images: _choice.supportsImages), messages: _requestMessages(images: _choice.supportsImages), …)`, 어댑터는 `_registry.of(t.vendor)`.
  - `_requestMessages(images: false)` → `ToolResultsMessage` 의 `images` 를 비운 **사본**(`_messages` 자체는 고치지 않는다 — 다시 사진 되는 모델로 바꾸면 원래대로). 사진 수 `_imagesSent` 는 실제로 보낸 것만 센다(사진 못 보는 모델이면 늘지 않는다).
  - 시스템 프롬프트(공통)에 한 줄: "사진 보기 도구가 없으면 사진은 볼 수 없다고 짧게 답한다"(§6.4).
  - **접기 조건 좁힘**(기록 계획 Task 4 의 `_contextTarget != t` → `_contextTarget?.vendor != t.vendor`): 벤더가 바뀔 때만 글로 접는다. 모델만 바뀌면 그대로 보내고 어댑터가 `vendorState.model != request.model` 인 턴을 parts 로 다시 만든다(Task 2 · 7).
  - 오류 `modelUnavailable` → `await _choice.recoverFromUnavailable(t.model)` 가 true 면 `ChatFailure.modelReplaced`, 아니면 `modelUnavailable`. 질문 메시지 되돌림 규칙은 그대로.
  - 오류 `imagesUnsupported` → `_choice.markNoImages(t.model)` 뒤 **같은 라운드를 한 번만** 사진 없이(`images: false` 경로) 다시 보낸다. 또 나면 `unknown`.
  - 사용량 기록 `vendor` · `model` · `fastMode` 는 그 요청 값(기록 계획 그대로).
- **l10n 새 키**(ko / en / ja):
  | 키 | ko | en | ja |
  |---|---|---|---|
  | `walkChatFailureNoModels` | 모델 목록을 받지 못했어요. 연결을 확인해 주세요 | Couldn't load the model list. Check your connection | モデル一覧を取得できませんでした。接続を確認してください |
  | `walkChatFailureModelReplaced` | 모델을 바꿨어요. 다시 물어봐 주세요 | We switched the model. Please ask again | モデルを切り替えました。もう一度質問してください |
  `walkChatFailureModelUnavailable` 은 그대로(key-ux D8 의 ③ 문구는 `modelReplaced` 로 나눔 — 결정 G7).

- [ ] **Step 1: 실패하는 테스트** — `chat_session_test.dart`(가짜 registry · `FakeChatModelChoice` 또는 실제 choice + 가짜 catalog):
  - `요청 model 은 choice.currentModel, 어댑터는 연결 벤더의 것` — openai 로 연결된 가짜면 openai 가짜 모델이 불림.
  - `고른 모델이 없으면 추천 모델로 보낸다`.
  - `목록이 없으면 요청 없이 noModels`.
  - `fastMode 는 choice.fastModeOn 그대로` — 설정 켜짐 + 지원 안 함 → false, 지원 → true.
  - `사진 못 보는 모델이면 tools 에 view_photos 가 없고 이전 사진이 요청에서 빠진다` — 1번 질문(사진 2장, 사진 되는 모델) → 모델 바꿈(사진 못 봄) → 2번 요청의 `ToolResultsMessage.images` 비어 있음, 그런데 다시 사진 되는 모델로 → 3번 요청에 사진 2장이 있다.
  - `사진 못 보는 모델에선 사진 수가 늘지 않는다`.
  - `모델만 바뀌면 문맥을 접지 않는다` — 2번 요청에 1번 `AssistantMessage`(vendorState 포함) `identical`, `ToolResultsMessage` 남음.
  - `벤더가 바뀌면 글로 접는다`(기록 계획 테스트 유지).
  - `modelUnavailable → 모델이 바뀌면 modelReplaced, 아니면 modelUnavailable`.
  - `imagesUnsupported 면 markNoImages 하고 사진 없이 한 번 다시 보낸다` · `또 나면 unknown`.
  - `target 은 연결 벤더 · currentModel, 목록이 없으면 null`.
  - `시스템 프롬프트에 사진 도구가 없을 때의 안내 줄이 있다`.
  - `life_tools_test.dart`: `definitionsFor(images: false) 에 view_photos 가 없고 나머지 넷은 같다`.
  - `chat_failure_text_test.dart`: 두 새 값의 ko 문구.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/domain/chat test/presentation/chat/widget` → FAIL.
- [ ] **Step 3: 구현** — 위 규칙. `grep -rn "interimModel" lib test` → 0. 기록 계획의 cubit 코드에서 `_session.target` 을 쓰는 곳은 `?.` 로(null 이면 저장 · 배너 벤더를 `connectedVendor ?? anthropic`).
- [ ] **Step 4: l10n** — 세 arb, `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 6: 커밋** — `feat(walk): 물어보기 세션이 고른 모델 · 빠른 출력으로 묻고 사진 못 보는 모델에선 사진을 뺀다`

### Task 5: 모델 칩 · 모델 고르기 시트(빠른 출력 스위치)

스펙 §6.2 · 결정 표 "모델 칩" · "빠른 출력 모드". 위젯만(끼우기는 Task 6). Task 1~4 와 파일이 겹치지 않아 Task 3 뒤 병렬 가능.

**Files:**
- Create: `lib/presentation/chat/widget/model_chip.dart` · `lib/presentation/chat/widget/model_picker_sheet.dart`
- Create: `lib/presentation/chat/cubit/model_picker_cubit.dart` · `model_picker_state.dart`
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`
- Test: `test/presentation/chat/widget/model_chip_test.dart` · `model_picker_sheet_test.dart` · `test/presentation/chat/cubit/model_picker_cubit_test.dart`(새)

**Interfaces:**
- Produces:
  ```dart
  /// 칩 하나에 필요한 값(ChatState · ChatSettingsState 가 같이 만든다).
  @freezed
  class ModelChipData with _$ModelChipData {
    @override final ChatVendor vendor;
    @override final String label;          // 표시 이름
    @override final bool fastMode;         // 번개
    @override final bool hasNewer;         // 점
    const ModelChipData({required this.vendor, required this.label, this.fastMode = false, this.hasNewer = false});
  }

  /// 앱바 아래 칩: ChatVendorIcon(작게) + 이름 + (빠른 출력이면 Icons.bolt) + ▾, 새 모델이면 오른쪽 위 점.
  class ModelChip extends StatelessWidget {
    const ModelChip({required this.data, required this.onPressed, super.key}); // Key('chat-model-chip')
    final ModelChipData data;
    final VoidCallback? onPressed;        // null 이면 비활성(busy)
  }

  @freezed
  class ModelPickerRow with _$ModelPickerRow { // id · label · createdAt? · recommended · isNew · inUse · noImages
  }
  @freezed
  class ModelPickerState with _$ModelPickerState { // rows · fastModeAvailable · fastMode · fastModeFactor(double?) · company(ChatVendor)
  }

  class ModelPickerCubit extends Cubit<ModelPickerState> {
    ModelPickerCubit(this._choice, this._catalog, this._settings);
    /// 행을 만들고 **그 뒤** catalog.markAllSeen() — 이번 시트에서는 NEW 가 보이고 다음부터 사라진다.
    Future<void> load();
    Future<void> select(String id);
    /// 처음 켤 때는 needsAck 를 돌려주고 켜지 않는다. 확인 뒤 confirmFastMode.
    Future<FastModeToggle> toggleFastMode(bool on);
    Future<void> confirmFastMode();       // acknowledgeFastMode + setFastMode(true)
  }
  enum FastModeToggle { done, needsAck }

  class ModelPickerSheet extends StatelessWidget {
    /// 고르면 저장하고 닫는다. 바뀐 게 있으면 true.
    static Future<bool> show(BuildContext context);
  }
  ```
  - 시트 모양: `showModalBottomSheet(useSafeArea: true, isScrollControlled: true)` · 제목 `walkChatModelPickerTitle` · `ListView` 행 = `AppListTile(key: Key('model-row-<id>'), title: label, subtitle: [날짜(DateFormat.yMMMd(locale))] + (noImages 면 ' · 사진은 못 봐요'), trailing: 배지들 + inUse 면 Icons.check)`. 배지는 작은 `Text` 를 `labelSmall` + `colorScheme.secondaryContainer` 둥근 상자(`AppRadius.sm`)로 — 시트 안에서만 쓰는 private 위젯 `_Badge`.
  - 빠른 출력: `fastModeAvailable` 일 때만 목록 아래 `SwitchListTile`(`Key('model-fast-mode')`, 제목 `walkChatFastMode`, 부제 `walkChatFastModeSubtitle(factor)`). 켤 때 `needsAck` 면 `AppConfirmDialog.show(title: walkChatFastModeConfirmTitle, content: walkChatFastModeConfirmBody(company, factor), confirmLabel: walkChatFastModeConfirmAction, isDestructive: false)` → 확인이면 `confirmFastMode`. 끄기는 묻지 않는다. 스위치는 시트를 닫지 않는다.
  - 배수 표시: `factor` 가 정수면 `'2'`, 아니면 소수 한 자리(`NumberFormat` 은 locale 따름).
- **l10n 새 키**(ko / en / ja):
  | 키 | ko | en | ja |
  |---|---|---|---|
  | `walkChatModelPickerTitle` | 모델 고르기 | Choose a model | モデルを選ぶ |
  | `walkChatModelChipTooltip` | 모델 바꾸기 | Change model | モデルを変更 |
  | `walkChatModelRecommended` | 추천 | Recommended | おすすめ |
  | `walkChatModelNew` | NEW | NEW | NEW |
  | `walkChatModelInUse` | 사용 중 | In use | 使用中 |
  | `walkChatModelNoImages` | 사진은 못 봐요 | Can't view photos | 写真は見られません |
  | `walkChatModelNewerAvailable` | 새 모델이 있어요 | A newer model is available | 新しいモデルがあります |
  | `walkChatFastMode` | 빠르게 답하기 | Faster answers | 速く答える |
  | `walkChatFastModeSubtitle` | 답이 더 빨리 나오지만 요금이 더 들어요(약 {factor}배) | Answers come faster but cost more (about {factor}×) | 回答は速くなりますが料金が上がります（約{factor}倍） |
  | `walkChatFastModeConfirmTitle` | 빠르게 답하기를 켤까요? | Turn on faster answers? | 速く答えるをオンにしますか？ |
  | `walkChatFastModeConfirmBody` | 이 모드로 답할 때마다 {company} 요금이 약 {factor}배 들어요. | Each answer in this mode costs about {factor}× from {company}. | このモードでは回答ごとに {company} の料金が約{factor}倍かかります。 |
  | `walkChatFastModeConfirmAction` | 켜기 | Turn on | オンにする |
  `factor` · `company` 는 String. `walkChatModelNewerAvailable` 은 점의 `Semantics` 라벨.

- [ ] **Step 1: 실패하는 테스트**
  - `model_chip_test.dart`: `이름 · 모노그램 · ▾ 가 보인다` · `fastMode 면 번개 아이콘` · `hasNewer 면 점(시맨틱 '새 모델이 있어요')` · `onPressed null 이면 눌러도 아무 일 없음`.
  - `model_picker_cubit_test.dart`: `행은 최신순이고 추천 · NEW · 사용 중 · 사진 못 봄이 맞다` · `load 뒤 markAllSeen 이 불린다(행의 isNew 는 load 때 값)` · `select 는 저장` · `처음 켜면 needsAck, 확인 뒤 켜짐` · `ack 가 있으면 바로 켜짐` · `끄기는 바로`.
  - `model_picker_sheet_test.dart`:
    - `최신순 행과 추천 · NEW · 사용 중 체크 · '사진은 못 봐요' 부제`.
    - `행을 누르면 저장하고 닫힌다(true)` · `다시 열면 NEW 가 없다`.
    - `지원 모델이면 빠르게 답하기 스위치와 '약 2배' 부제, 아니면 스위치 없음`.
    - `처음 켜면 요금 확인 창, [취소]면 꺼진 채` · `[켜기]면 켜지고 다음엔 묻지 않는다`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/presentation/chat` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces. build_runner.
- [ ] **Step 4: l10n** — 세 arb, `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 6: 커밋** — `feat(walk): 물어보기 모델 칩 · 모델 고르기 시트와 빠른 출력 스위치`

### Task 6: 물어보기 탭 · 설정 화면에 모델 끼우기 · `noModels` · 사라진 모델 안내

스펙 §6.1(모델 행) · §6.2 · §6.3(갱신 시점 · 사라진 모델 · 목록 없음) · §7.4. **③ 의 끝** — 이 task 뒤 모델 칩이 보인다.

**Files:**
- Modify: `lib/presentation/chat/cubit/chat_state.dart` · `chat_cubit.dart` · `lib/presentation/chat/page/chat_tab.dart`
- Modify: `lib/presentation/settings/cubit/chat_settings_cubit.dart` · `chat_settings_state.dart` · `lib/presentation/settings/widget/chat_settings_section.dart`
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`
- Modify: 하네스(`grep -rn "registerSingleton<ChatSettings>" test`)에 `ChatModelChoice` · `ChatModelCatalog` 가짜 등록
- Test: `test/presentation/chat/cubit/chat_cubit_test.dart` · `test/presentation/chat/page/chat_tab_test.dart` · `test/presentation/settings/cubit/chat_settings_cubit_test.dart` · `test/presentation/settings/widget/chat_settings_section_test.dart`

**Interfaces:**
- `ChatAccess { checking, noKey, needsConsent, noModels, ready }`. `ChatState` 에 더함: `ModelChipData? model` · `bool modelsInvalidKey`(noModels 에서 [설정 열기]를 보일지) · `bool selectionReplaced`(한 번 알림). 기록 계획의 `vendor` 는 그대로(`model?.vendor` 와 같음).
- `ChatCubit(…, this._choice)`(key-ux 의 `_verifier` 를 대신):
  - `refresh()`: `hasApiKey` → 없으면 `noKey`. 동의 → 없으면 `needsConsent`. `_choice.currentModel == null` 이면 `await _choice.refresh()` 뒤 그래도 null 이면 `noModels`(`modelsInvalidKey = result is ModelsInvalidKey`). 있으면 `ready` 를 바로 emit 하고 `unawaited(_choice.refresh().then((_) => _emitModel()))`(오류 삼킴). `_emitModel` 은 칩 데이터 · `selectionReplaced = _choice.selectionReplacedNotice` 를 갱신.
  - `retryModels()` → `_choice.refresh(force: true)` 뒤 `refresh()`.
  - `modelChanged()` → 시트가 닫힌 뒤 칩 다시 읽기. `consumeSelectionReplaced()` → `_choice.consumeSelectionReplacedNotice()` + 상태 false.
  - 질문이 `modelReplaced` 로 끝나면 `_emitModel()`.
- `chat_tab.dart`:
  - `ready` 본문 맨 위(대화 위)에 칩 줄: `Padding(horizontal: AppSpacing.md, vertical: AppSpacing.xs) + Align(left) + ModelChip(data: state.model!, onPressed: state.busy ? null : () async { if (await ModelPickerSheet.show(context)) cubit.modelChanged(); })`. 앱바 · ⋮ 는 건드리지 않는다.
  - `noModels` → `AppPlaceholder(title: walkChatNoModelsTitle, actionLabel: commonRetry, onAction: cubit.retryModels)`, `modelsInvalidKey` 면 행동을 `walkChatOpenSettings` · `onOpenSettings` 로.
  - `BlocListener(listenWhen: !a.selectionReplaced && b.selectionReplaced && widget.active)` → `AppSnackBar.show(walkChatModelReplacedNotice)` → `consumeSelectionReplaced()`. 탭이 안 보이는 동안 세워졌으면 `active` 가 참이 될 때(`didUpdateWidget`) 한 번 보인다.
- `ChatSettingsCubit(this._settings, this._verifier, this._choice)`:
  - 상태에 더함: `ModelChipData? model` · `bool fastMode` · `bool modelsUnavailable`(연결됐는데 currentModel null). 원문 없음.
  - `load()`: `connection()` 뒤 `_choice.refresh()`(24시간 규칙 — "설정 화면이 열릴 때") → 다시 emit.
  - `check(key)` 가 `ok(models)` 면 목록을 cubit 필드 `_checkedModels`(벤더 · 목록, 키 아님)에 둔다. `connect` 성공 뒤 있으면 `_choice.adopt(vendor, models)`, 없으면(unreachable) `_choice.refresh(force: true)` 를 기다리지 않고.
  - `disconnect` 성공 뒤 `_choice.forget()`.
  - `retryModels()` → `_choice.refresh(force: true)` 뒤 다시 읽기. `modelChanged()`.
- `ChatSettingsSection`: 연결됨 · 확인 전 · 잘못된 키일 때 연결 행 바로 아래 모델 행 `AppListTile(key: Key('settings-chat-model'), leading: Icons.tune, title: walkChatSettingsModel, subtitle: fastMode ? walkChatSettingsModelFast(label) : label, onTap: → ModelPickerSheet.show → cubit.modelChanged)`. `modelsUnavailable` 면 부제 `walkChatSettingsModelsUnavailable`, 탭 → `retryModels`. 빠른 출력 스위치는 여기 두지 않는다(스펙 §6.2 위치 메모).
- **l10n 새 키**(ko / en / ja):
  | 키 | ko | en | ja |
  |---|---|---|---|
  | `walkChatNoModelsTitle` | 모델 목록을 받지 못했어요 | Couldn't load the model list | モデル一覧を取得できませんでした |
  | `walkChatModelReplacedNotice` | 고른 모델이 없어져 추천 모델로 바꿨어요 | Your chosen model is gone, so we switched to the recommended one | 選んだモデルがなくなったため、おすすめのモデルに切り替えました |
  | `walkChatSettingsModel` | 모델 | Model | モデル |
  | `walkChatSettingsModelFast` | {model} · 빠르게 | {model} · Fast | {model} · 高速 |
  | `walkChatSettingsModelsUnavailable` | 목록을 받지 못했어요 · 다시 시도 | Couldn't load the list · Try again | 一覧を取得できませんでした・再試行 |

- [ ] **Step 1: 실패하는 테스트**
  - `chat_cubit_test.dart`: `목록이 있으면 ready 와 칩(이름 · 벤더 · 번개 · 점)` · `목록이 없고 받기 실패면 noModels` · `invalidKey 면 modelsInvalidKey` · `retryModels 가 성공하면 ready` · `ready 에서 갱신은 기다리지 않고 끝나면 칩을 바꾼다` · `동의 전이면 noModels 보다 needsConsent 가 먼저` · `selectionReplaced 를 한 번 세우고 consume 하면 내린다` · `modelReplaced 로 끝나면 칩이 새 모델`.
  - `chat_tab_test.dart`: `ready 면 앱바 아래 모델 칩` · `칩 → 시트 → 다른 모델을 고르면 칩 이름이 바뀐다` · `답하는 중엔 칩이 비활성` · `noModels 면 '모델 목록을 받지 못했어요' + [다시 시도]` · `잘못된 키면 [설정 열기]` · `고른 모델이 사라졌으면 탭이 보일 때 스낵바 한 번(보이지 않는 동안은 없음)`.
  - `chat_settings_cubit_test.dart`: `load 가 refresh 를 부른다` · `ok 확인 뒤 connect 하면 그 목록을 adopt(listModels 한 번)` · `unreachable 로 connect 하면 강제 갱신을 요청한다` · `disconnect 는 forget` · `상태 toString 에 원문 없음`(유지).
  - `chat_settings_section_test.dart`: `연결되면 모델 행에 지금 모델 이름` · `빠른 출력이면 '이름 · 빠르게'` · `목록이 없으면 '목록을 받지 못했어요 · 다시 시도', 누르면 다시 받음` · `미연결이면 모델 행 없음` · `모델 행 → 시트`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/presentation` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces. `grep -rn "recheckIfUnverified" lib test` → 0. build_runner.
- [ ] **Step 4: l10n** — 세 arb, `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS. `grep -rn "\.apiKey()" lib` → 둘.
- [ ] **Step 6: 커밋** — `feat(walk): 물어보기 탭에 모델 칩을 두고 목록이 없거나 고른 모델이 사라지면 알린다`

### Task 7: `OpenAiChatModel` — Responses API 어댑터

스펙 §8.3 · §8.4 · §9(OpenAI 사용량) · §10.1 GPT 열 · §10.2 · 결정 표 "서버 저장". 화면 변화 없음(벤더 시트는 Task 8). 픽스처로만 검증 — 실제 키 확인은 testing.md "대기".

**Files:**
- Create: `lib/data/chat/openai_chat_model.dart`
- Create: `lib/data/chat/vendor_error.dart` — 오류 본문에서 `error.type` · `error.code` 만(16KB · 2초), key-ux 의 Anthropic `_errorType` 을 여기로 옮겨 같이 쓴다
- Modify: `lib/data/chat/anthropic_chat_model.dart` — `readVendorError` 사용(동작 그대로)
- Modify: `lib/data/chat/chat_model_registry.dart` — `openai => _openai`
- Create: `test/fixtures/chat/openai/models.json` · `stream_text.sse` · `stream_tool_call.sse` · `stream_reasoning_tool.sse` · `stream_refusal.sse` · `stream_incomplete.sse` · `error_insufficient_quota.json` · `error_rate_limit.json` · `error_invalid_key.json` · `error_model_not_found.json` · `error_image.json`
- Test: `test/data/chat/openai_chat_model_test.dart`(새) · `test/data/chat/vendor_error_test.dart`(새) · `test/data/chat/chat_model_registry_test.dart` · `anthropic_chat_model_test.dart`(그대로 통과)

**Interfaces:**
- Produces:
  ```dart
  /// 그 턴의 원본 output 항목(reasoning 의 encrypted_content · message · function_call). toString 은 항목 개수만.
  final class OpenAiTurnState implements VendorTurnState {
    const OpenAiTurnState({required this.model, required this.items});
    @override ChatVendor get vendor => ChatVendor.openai;
    @override final String model;
    final List<Map<String, Object?>> items;
  }

  @lazySingleton
  class OpenAiChatModel implements ChatModel {
    OpenAiChatModel(http.Client client, ChatTrace trace) : this.withTimeouts(client, trace);
    OpenAiChatModel.withTimeouts(this._client, this._trace, {Duration connectTimeout, Duration idleTimeout, Duration listTimeout, bool imagesInToolOutput = false});
    static final base = Uri.parse('https://api.openai.com/v1/');
    /// 빠른 처리 필드(O5). 지원 표가 비어 있는 동안 실리지 않는다.
    @visibleForTesting static const Map<String, Object?> fastModeFields = {/* O5: 'service_tier': 'priority' 추정 */};
    /// 이미지 거절 오류 코드(O6, 추정).
    @visibleForTesting static const Set<String> imageUnsupportedCodes = {/* O6 */};
    @override ChatVendor get vendor => ChatVendor.openai;
    @override Stream<ModelEvent> stream(ModelRequest request);   // core 의 컨트롤러 + abortableSend 모양 그대로
    @override Future<ModelListResult> listModels(String apiKey);
  }
  ```
- **요청**(`POST /v1/responses`, `Authorization: Bearer <key>`, `Content-Type: application/json`):
  `{model, instructions: system, input: [...], tools: [...], stream: true, store: false, include: ['reasoning.encrypted_content'], max_output_tokens: <Anthropic max_tokens 와 같은 값>, if supportsEffortOf(openai, model): reasoning: {effort: 'low'}, if fastMode: ...fastModeFields}`. `previous_response_id` 를 넣지 않는다(서버 저장이 꺼져 있으므로 매번 전체).
- **변환**:
  | 중립 | Responses `input` |
  |---|---|
  | `UserMessage(text)` | `{role: 'user', content: text}` |
  | `AssistantMessage` + `OpenAiTurnState`(같은 model) | `state.items` 그대로 |
  | `AssistantMessage` + 없음 · 다른 model · 다른 타입 | `TextPart` → `{type: 'message', role: 'assistant', content: [{type: 'output_text', text}]}`, `ToolCallPart` → `{type: 'function_call', call_id: id, name, arguments: jsonEncode(input)}` |
  | `ToolResultsMessage` | 결과마다 `{type: 'function_call_output', call_id, output: json}`. 이미지: `imagesInToolOutput` 면 `output: [{type: 'input_text', text: json}, {type: 'input_image', image_url: 'data:<mime>;base64,…'}]`, 아니면 결과들 **뒤에** `{role: 'user', content: [{type: 'input_text', text: '(도구 결과 사진)'}, …input_image]}` 하나 |
  | `ToolSpec` | `{type: 'function', name, description, parameters, strict: false}` |
- **스트림**: `response.output_text.delta` → `textDelta(delta)`. `response.completed` · `response.incomplete` · `response.failed` 의 `response` 객체로 끝을 만든다 — `output` 배열에서 `message` 의 `output_text` → `TextPart`, `refusal` content → stop `refusal`(글은 parts 에 넣지 않음), `function_call` → `ToolCallPart(id: call_id, input: jsonDecode(arguments))`, `reasoning` 은 parts 에 넣지 않음. `vendorState = OpenAiTurnState(model: request.model, items: output 전부)`. stop: function_call 있음 → `toolUse`, refusal → `refusal`, `incomplete` + `incomplete_details.reason == 'max_output_tokens'` → `maxTokens`, completed → `endTurn`, 그 밖 → `other`. `response.failed` · `error` 이벤트 → `error.code`/`type` 로 매핑한 `ChatModelException`. 진행 이벤트는 내지 않는다(core P1).
- **사용량**: `response.usage` → `TokenUsage(inputTokens: input_tokens, outputTokens: output_tokens, cacheReadTokens: input_tokens_details.cached_tokens ?? 0, cacheWriteTokens: 0, reasoningTokens: output_tokens_details.reasoning_tokens)`. `is int` 로만, 어긋나면 null.
- **오류 매핑**(`readVendorError` → `(type, code)`): code `invalid_api_key` · 401 · 403 → `invalidKey`; code `insufficient_quota` → `quotaExceeded`; code `rate_limit_exceeded` · 그 밖 429 → `rateLimited`; code `model_not_found` · 404 → `modelUnavailable`; code ∈ `imageUnsupportedCodes` → `imagesUnsupported`; 503 → `overloaded`; 그 밖 → `server`. 메시지 문자열은 읽지 않는다.
- **listModels**: `GET /v1/models` → `data[].id`(String) · `created`(int 초 → `DateTime.fromMillisecondsSinceEpoch(*1000, isUtc: true)`) → `ModelInfo(id, displayName: id, createdAt)`(능력은 null — 규칙이 정함). 401 · 403 → `invalidKey`, 그 밖 → `unreachable`.
- **계측**: core 의 `ChatTraceMark` 그대로(`req` 에 vendor · model · fast, `head` · `first` · `textDelta` · `msgStop`). `block.start/stop` 은 `response.output_item.added/done` 이 오면 `kind`(reasoning → thinking · message → text · function_call → tool_use)로, 안 오면 생략(O7).

- [ ] **Step 1: 실패하는 테스트** — `openai_chat_model_test.dart`(`MockClient` 로 본문 · 헤더 잡기, 취소는 core 의 `_HangingClient` 방식):
  - `요청에 store false · include reasoning.encrypted_content 가 늘 있고 previous_response_id 가 없다` — 도구 · 사진 · fastMode 유무 네 조합 모두.
  - `Authorization Bearer 헤더 · POST /v1/responses · stream true`.
  - `instructions 는 system, user 는 문자열 content`.
  - `ToolSpec 은 type function · parameters · strict false`.
  - `effort 는 supportsEffortOf 가 참일 때만` · `fastMode 면 fastModeFields`.
  - `stream_text.sse → textDelta 들과 completed(endTurn, TextPart, usage in/out/cacheRead/reasoning)`.
  - `stream_tool_call.sse → toolUse, ToolCallPart(id=call_id, input 디코드)`.
  - `stream_reasoning_tool.sse → vendorState 의 items 에 encrypted_content 가 있고 다음 요청 input 에 그대로 돌아간다(같은 모델)` · `다른 모델이면 reasoning 없이 function_call · message 로 다시 만든다`.
  - `함수 결과는 function_call_output, 사진은 뒤따르는 user input_image` · `imagesInToolOutput 이면 output 배열에 input_image`.
  - `stream_refusal.sse → refusal` · `stream_incomplete.sse(max_output_tokens) → maxTokens`.
  - `usage 가 없거나 모양이 어긋나면 null`.
  - 오류: `429 insufficient_quota → quotaExceeded` · `429 rate_limit_exceeded → rateLimited` · `401 → invalidKey(본문 없이도)` · `404 model_not_found → modelUnavailable` · `이미지 코드 → imagesUnsupported` · `503 → overloaded` · `스트림 중 response.failed → 매핑된 예외`.
  - `오류 본문의 message 는 예외에 없다` · `toString 에 키 없음`(`ModelRequest` · `OpenAiTurnState`).
  - 취소: `상태 줄을 기다리는 중 취소하면 abortTrigger 가 바로 끝난다` · `SSE 중 취소하면 응답 구독이 끊기고 이후 이벤트가 없다`.
  - `listModels`: `models.json → id · createdAt(초)` · `401 · 403 → invalidKey` · `500 · 네트워크 · 시간 초과 → unreachable` · `Bearer 헤더`.
  - `vendor 는 openai`.
  - `vendor_error_test.dart`: `type · code 를 읽고 message 는 버린다` · `16KB 넘으면 null 둘` · `JSON 아니면 null 둘`.
  - `chat_model_registry_test.dart`: `openai 는 OpenAiChatModel`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/data/chat` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces. 픽스처마다 `: hand-made — re-record (O7)`(오류 JSON 은 `handMadeFixtures` 에 O6). build_runner.
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 GPT(OpenAI Responses) 어댑터 — 서버 저장 끔 · 추론 항목 왕복`

### Task 8: 벤더 고르기 · 바꾸기 · 벤더별 전송 동의

스펙 §5.1~§5.3 · §6.1(미연결 설명 · [다른 AI 로 바꾸기]) · 결정 표 "벤더 연결 · 전송 동의" · Q12 · Q14. **④ 의 끝** — GPT 를 고를 수 있다.

**Files:**
- Create: `lib/presentation/settings/widget/vendor_picker_sheet.dart`
- Modify: `lib/domain/chat/chat_settings.dart` · `lib/data/chat/secure_chat_settings.dart` — `consentedVendor` · `setConsented(vendor)` · 이전
- Modify: `lib/presentation/settings/cubit/chat_settings_cubit.dart` — `check` · `connect` 가 벤더를 받는다(`static const vendor` 삭제)
- Modify: `lib/presentation/settings/widget/chat_key_dialog.dart` — `switchingFrom: ChatVendor?` 면 요금 경고 대신 바꾸기 확인 창
- Modify: `lib/presentation/settings/widget/chat_settings_section.dart` — [AI 연결하기] → 시트 → 키, [다른 AI 로 바꾸기] 행
- Modify: `lib/presentation/chat/cubit/chat_cubit.dart` · `chat_state.dart` · `lib/presentation/chat/widget/chat_consent_view.dart` · `chat_tab.dart` — 동의 벤더 · 이어지는 대화 문구
- Modify: `lib/presentation/chat/widget/chat_vendor_icon.dart` — O8 이 확인됐으면 `confirmedLogos` 에 openai 한 줄 · 자산(아니면 모노그램 "G" 그대로)
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`
- Test: `test/presentation/settings/widget/vendor_picker_sheet_test.dart`(새) · `chat_key_dialog_test.dart` · `chat_settings_section_test.dart` · `test/presentation/settings/cubit/chat_settings_cubit_test.dart` · `test/data/chat/secure_chat_settings_test.dart` · `test/presentation/chat/cubit/chat_cubit_test.dart` · `test/presentation/chat/page/chat_tab_test.dart` · `test/presentation/chat/widget/chat_consent_view_test.dart`(없으면 새)

**Interfaces:**
- Produces (`ChatSettings` — `consented` · `setConsented()` 를 바꿈):
  ```dart
  /// 전송에 동의한 벤더(`chat.consentedVendor`). 연결 벤더와 다르면 needsConsent.
  ChatVendor? get consentedVendor;
  Future<void> setConsented(ChatVendor vendor);
  ```
  이전: `chat.consented == true` 이고 `chat.consentedVendor` 가 없으면 `anthropic` 으로 쓰고 `chat.consented` 삭제(첫 접근 때 한 번). `disconnect` 는 동의를 남긴다(같은 벤더로 다시 연결하면 묻지 않음).
- Produces (시트):
  ```dart
  /// MVP 벤더(Claude · GPT)만. Grok 없음(Q12).
  const chatVendorChoices = [ChatVendor.anthropic, ChatVendor.openai];

  class VendorPickerSheet extends StatelessWidget {
    /// 고른 벤더, 닫으면 null. [current] 는 체크 · 비활성.
    static Future<ChatVendor?> show(BuildContext context, {ChatVendor? current});
  }
  ```
  행 = `AppListTile(key: Key('vendor-row-<name>'), leading: ChatVendorIcon(vendor), title: chatVendorName, subtitle: chatVendorCompany, trailing: current 면 Icons.check, onTap: current 면 null)`.
- `ChatSettingsCubit`: `check(ChatVendor vendor, String key)` · `connect(ChatVendor vendor, String key, ChatKeyCheck check)`. 벤더가 바뀌면 `_settings.connect` 가 키를 덮어쓰고(같은 `chat.apiKey` — 쓰기가 끝난 뒤에만 벤더 · 상태가 바뀌므로 실패 시 기존 연결 그대로) `chat.model` 을 지우며(Task 3), 성공 뒤 `_choice.adopt(vendor, models)` 로 목록 캐시를 교체.
- `ChatKeyDialog.show(context, vendor:, switchingFrom:)`: `valid` · `unreachable` 뒤
  - `switchingFrom == null` → 지금 요금 경고(②) 그대로.
  - 아니면 `AppConfirmDialog.show(title: walkChatSwitchVendorTitle(new), content: walkChatSwitchVendorBody(company, old, new), confirmLabel: walkChatSwitchVendorAction, isDestructive: false)` 하나로 묶는다(스펙 §5.2). 결과 `ChatKeyDialogResult.switched` 를 더한다(`savedUnverified` 도 그대로 — 확인 못 함으로 바꾼 경우).
- 섹션: 미연결 [연결하기] → `VendorPickerSheet.show()` → `ChatKeyDialog.show(vendor:)`. 연결됨 아래 행에 `Key('settings-chat-switch-vendor')` "다른 AI 로 바꾸기" → `VendorPickerSheet.show(current:)` → `ChatKeyDialog.show(vendor: picked, switchingFrom: current)`. 결과 `switched` → `AppSnackBar`(success) `walkChatSwitchedVendor(new)` + 연결 행 glow(`_replay++`). [키 바꾸기]는 같은 벤더로 ② 그대로.
- 물어보기 탭: `ChatCubit.refresh()` 의 동의 판정 = `consentedVendor == connectedVendor`. `accept()` → `setConsented(connectedVendor!)`. 동의 화면이 떠도 `bubbles` 는 남기고(`needsConsent` 동안 본문은 동의 뷰, 동의 뒤 `ready` 에서 대화 그대로), `ChatConsentView({required ChatVendor vendor, required bool continuing, …})` — `continuing = state.bubbles.isNotEmpty` 면 문구 끝에 `walkChatConsentContinues(vendor)` 한 줄. 설정에서 돌아오면(`didPopNext`) 다시 읽는 key-ux 경로가 그대로 덮는다.
- **l10n**(ko / en / ja). 값 바꿈(자리표시자 `vendor` 생김 — 위키 낱말은 넣지 않는다, 결정 G12):
  | 키 | ko | en | ja |
  |---|---|---|---|
  | `walkChatConsentNotice` | 질문과, 답에 필요한 일기 · 사진 · 걸음 · 기상 기록이 연결한 AI({vendor})로 전송돼요. 키는 이 폰의 보안 저장소에만 있어요. | Your questions and the diary entries, photos, steps and wake-up records needed to answer are sent to the AI you connected ({vendor}). Your key stays only in this phone's secure storage. | 質問と、回答に必要な日記・写真・歩数・起床記録が接続した AI（{vendor}）に送信されます。キーはこの端末の安全な保管領域にだけ保存されます。 |
  | `walkChatSettingsNotice` | 위와 같은 문구 | 〃 | 〃 |
  | `walkChatConnectDescription` | Claude · GPT 중 하나의 키를 넣으면 물어보기를 쓸 수 있어요 | Add a Claude or GPT key to use Ask | Claude か GPT のキーを入れると質問を使えます |
  새 키:
  | 키 | ko | en | ja |
  |---|---|---|---|
  | `walkChatVendorSheetTitle` | AI 고르기 | Choose an AI | AI を選ぶ |
  | `walkChatSettingsSwitchVendor` | 다른 AI 로 바꾸기 | Switch to another AI | 別の AI に切り替える |
  | `walkChatSwitchVendorTitle` | {vendor} 로 바꿀까요? | Switch to {vendor}? | {vendor} に切り替えますか？ |
  | `walkChatSwitchVendorBody` | 이 API 를 쓰면 {company} 에 요금이 청구될 수 있어요. 지금 연결된 {oldVendor} 키는 이 폰에서 지워지고, 다음 질문 때 전송 동의를 다시 받아요. 지금 대화는 {vendor} 로 이어져요. | Using this API may incur charges from {company}. Your current {oldVendor} key will be removed from this phone, and we'll ask for your consent again before the next question. This conversation continues with {vendor}. | この API を使うと {company} から料金が請求されることがあります。今の {oldVendor} のキーはこの端末から削除され、次の質問の前に送信への同意をもう一度確認します。今の会話は {vendor} で続きます。 |
  | `walkChatSwitchVendorAction` | 바꾸기 | Switch | 切り替える |
  | `walkChatSwitchedVendor` | {vendor} 로 바꿨어요 | Switched to {vendor} | {vendor} に切り替えました |
  | `walkChatConsentContinues` | 지금 대화의 이전 내용도 {vendor} 로 보내져요. | Earlier messages in this conversation will also be sent to {vendor}. | この会話のこれまでの内容も {vendor} に送られます。 |

- [ ] **Step 1: 실패하는 테스트**
  - `vendor_picker_sheet_test.dart`: `Claude · GPT 두 행만, Grok 없음` · `지금 벤더는 체크이고 누를 수 없다` · `고르면 그 벤더로 닫힌다`.
  - `secure_chat_settings_test.dart`: `옛 chat.consented true 는 consentedVendor anthropic 으로 옮긴다` · `setConsented(openai) 왕복` · `disconnect 뒤에도 consentedVendor 는 남는다`.
  - `chat_settings_cubit_test.dart`: `check 는 고른 벤더의 verifier 로` · `다른 벤더로 connect 하면 벤더가 바뀌고 모델 캐시를 그 벤더 목록으로 바꾼다` · `쓰기 실패면 기존 벤더 · 키 미리보기 그대로`.
  - `chat_key_dialog_test.dart`: `switchingFrom 이 있으면 요금 경고 대신 '{GPT} 로 바꿀까요?' 한 창, 본문에 OpenAI · Claude · '이어져요'` · `[취소]면 아무것도 바뀌지 않고 입력 대화상자로` · `[바꾸기]면 switched 로 닫힌다` · `GPT 키 대화상자는 sk- 힌트, sk-ant- 키면 'Claude 키 같아요'`.
  - `chat_settings_section_test.dart`: `미연결 [연결하기] → 벤더 시트 → GPT → 'GPT API 키 넣기'` · `연결됨이면 '다른 AI 로 바꾸기' 행` · `바꾸면 'GPT 로 바꿨어요' 스낵바 · 연결 행 모노그램 G · 'GPT' · sk-proj-…•••• · glow` · `미연결 설명은 'Claude · GPT 중 하나의 키…'`.
  - `chat_cubit_test.dart`: `동의 벤더가 연결 벤더와 다르면 needsConsent, 말풍선은 남는다` · `accept 는 연결 벤더로 기록하고 ready, 대화 그대로` · `같은 벤더 키 교체 · 모델 변경 뒤엔 다시 묻지 않는다`.
  - `chat_tab_test.dart`: `벤더를 바꾸고 돌아오면 동의 화면, 동의하면 이전 말풍선이 그대로 보인다`.
  - `chat_consent_view_test.dart`: `문구에 벤더 이름` · `continuing 이면 '지금 대화의 이전 내용도 GPT 로 보내져요'`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/presentation test/data/chat` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces. `grep -rn "\.consented\b\|setConsented()" lib test` → 0. build_runner.
- [ ] **Step 4: l10n** — 값 바꿈 · 새 키, `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 6: 커밋** — `feat(walk): 물어보기 AI 를 Claude · GPT 중에서 고르고 바꾸면 전송 동의를 다시 받는다`

### Task 9: 문서

CLAUDE.md "진행 상태는 status.md 에만" · feature 완료 시 history · testing 갱신 · 스펙 §10.3 "확인 결과를 history 에".

**Files:**
- Modify: `apps/walk/docs/status.md` · `apps/walk/docs/history.md` · `apps/walk/docs/testing.md` · `apps/walk/docs/plan.md`
- Modify: `CLAUDE.md` — walk 소개의 "물어보기(Claude API)" → "물어보기(Claude · GPT API)"
- Modify: `docs/superpowers/specs/2026-11-01-walk-chat-key-input.md` — 머리 "상태" 한 줄만 "③ · ④ 구현됨(…)"(본문은 고치지 않는다 — 어긋남은 history 에)

- [ ] **Step 1: `status.md`** — "물어보기" 절:
  - `[x]` 모델 목록 · 칩(키 기획 ③): 채팅용 거르기 · 추천(Claude Sonnet 최신 · GPT 플래그십 별칭) · 최신순 · NEW · 새 모델 점 · 하루 1회 갱신 · 사라진 모델 → 추천 · 목록 없음 화면 · 사진 못 보는 모델 처리 · 모델 id 고정 제거
  - `[x]`/`[ ]` 빠른 출력 스위치(A2 · O5 지원 표가 비어 있으면 "코드만 — 지원 표 대기")
  - `[x]` GPT 어댑터 · 벤더 고르기 · 바꾸기 · 벤더별 재동의(키 기획 ④)
  - `[ ]` 기기 확인: Claude · GPT 실제 키로 연결 · 질문 → 도구 → 답 · 사진 보기 · 잘못된 키 · 요금 부족, 대화 중 모델 · 벤더 바꿔 이어 묻기(기록 계획 H3 · A4 · X1), OpenAI 로고(O8)
  - 검증 줄: `flutter analyze` 0 · `flutter test` N건 통과(실행해 숫자). "다음 할 일"에 Grok(⑤) · 녹화 안 된 픽스처 목록.
- [ ] **Step 2: `history.md`** — 새 절 `## 2026-11-xx — 물어보기 모델 칩 · GPT(키 기획 ③ · ④)`: 아래 "결정" 표(이유 포함), 구현 전 확인 A1~A4 · O1~O8 · X1 결과(날짜 · 출처 · 지원 표에 넣은 줄), 남은 손 픽스처 목록(`handMadeFixtures`), 막힌 것.
- [ ] **Step 3: `testing.md`** — "물어보기" 표에 행 추가 · 수정: `domain/chat/chat_model_rules_test` · `usecase/chat_model_choice_test` · `data/chat/prefs_chat_model_catalog_test` · `openai_chat_model_test`(store false · 추론 왕복 · 오류 code · 취소) · `vendor_error_test` · `chat_model_registry_test` · `anthropic_chat_model_test`(목록 페이지 · effort · fast · 다른 모델 턴) · `chat_session_test`(모델 · 빠른 출력 · 사진 못 봄 · 넘김 규칙 · 모델 바뀜) · `presentation/chat/widget/model_chip_test` · `model_picker_sheet_test` · `cubit/model_picker_cubit_test` · `settings/widget/vendor_picker_sheet_test` · `chat_consent_view_test`. 픽스처 절: `test/fixtures/chat/` 위치 · "손으로 만든 것은 SSE 주석 / `handMadeFixtures` 로 표시, 녹화하면 교체". 맨 위 건수. "물어보기 기기 시나리오"에 Step 1 의 기기 확인을 "대기"로.
- [ ] **Step 4: `plan.md`** — "물어보기 (채팅)" 절: 벤더는 Claude · GPT 중 하나(물어보기 설정에서 바꾸면 기존 키 교체 · 재동의, 대화는 이어 감) · 모델은 목록에서(앱은 id 를 고정하지 않음, 추천 계열 최신, 하루 1회 갱신) · 물어보기 탭 모델 칩 · 빠른 출력(지원 모델만, 요금 안내) · OpenAI 는 `store: false` 로 서버 저장 끔. "주고받는 형식"에 넘김 규칙 세 줄(같은 모델 원본 · 다른 모델 parts · 다른 벤더 글만).
- [ ] **Step 5: 링크 검사** — `cd apps/trader && flutter test test/convention` → PASS.
- [ ] **Step 6: 커밋** — `docs(walk): 물어보기 모델 칩 · GPT 연결 반영`

---

## 결정

이 계획을 쓰며 정한 것(스펙끼리 어긋나거나 스펙이 비워 둔 곳). Task 9 가 `history.md` 로 옮긴다.

| # | 결정 | 이유 |
|---|---|---|
| G1 | `ChatModelRegistry` 를 ④ 가 아니라 ③ Task 2 에서(Anthropic 하나로) 들인다. 계약은 domain, 구현 `VendorChatModelRegistry` 는 data | 스펙 §11 은 ④ 지만, ③ 에서 세션 · verifier · 카탈로그 배선을 바꾸므로 한 번에 바꿔야 ④ 에서 같은 곳을 다시 고치지 않는다. domain 의 세션이 data 를 모르게 계약을 domain 에 |
| G2 | `ChatSettings.connectedVendor` 동기 getter 를 더한다 | 기록 계획의 `ChatSession.target` 이 동기 getter 이고 cubit 이 동기로 읽는다. prefs 는 이미 동기(`consented` 와 같음). `connection()` 은 보안 저장소를 읽어 비동기 |
| G3 | 세션 접기는 **벤더가 바뀔 때만**(기록 계획 Task 4 의 "target 이 바뀌면" 을 좁힘). 모델만 바뀌면 어댑터가 `vendorState.model ≠ request.model` 인 턴을 parts(text · 도구 호출 · 도구 결과)로 다시 만든다 | 스펙 §8.4 가 같은 벤더 · 다른 모델은 도구 기록을 남기고 `vendorState` 만 빼라고 정했다. 기록 계획은 둘을 한데 접었다 — 스펙 우선. A4 가 실패하면 되돌린다 |
| G4 | 카탈로그는 키를 모르고, 목록 받기는 `ChatKeyVerifier.fetchStored()` 하나로. `recheckIfUnverified` 는 `ChatModelChoice.refresh`(unverified 면 24시간 무시)로 대신하고 지운다 | 스펙 §7.1 은 카탈로그에 `refresh()` 를 두지만 그러면 원문 키를 읽는 곳이 셋이 된다(key-ux D4 "둘"). 갱신 규칙은 domain 유스케이스 `ChatModelChoice` 가 묶는다 |
| G5 | 키 저장 직전 `check` 가 받은 목록을 cubit 이 들고 있다가(키는 아님) 연결 성공 뒤 `adopt` | 스펙 §4 "한 번 호출로 키 확인과 목록 두 가지". key-ux D5 가 ③ 으로 넘긴 몫 |
| G6 | 고른 모델이 추천과 같으면 `chat.model = null` 로 저장(추천을 따라감) | 추천을 고른 사람은 "최신 Sonnet" 을 원한 것 — 새 Sonnet 이 나오면 따라가는 게 맞다. 일부러 다른 모델을 고른 사람만 고정 |
| G7 | `ChatFailure.modelReplaced`(갱신으로 모델이 바뀜, "모델을 바꿨어요. 다시 물어봐 주세요") 와 `modelUnavailable`(바뀌지 않음, ② 문구 그대로)을 나눈다 | 스펙 §6.3 문구는 "바꿨다"는 사실이 있을 때만 맞다. 일시적 404 에 "바꿨어요"는 거짓 — key-ux D8 을 이렇게 마무리 |
| G8 | "고른 모델이 없어져…" 알림 플래그는 메모리(`ChatModelChoice`, lazySingleton) | 한 번 보이면 그만이고, 앱을 다시 켜기 전에 탭이 보일 일이 거의 늘 있다. prefs 키를 늘리지 않는다 |
| G9 | 빠른 출력 첫 켜기 확인은 `chat.fastMode.ack` 로 한 번만 | 스펙 §6.2 "처음 켤 때 한 번". 끄고 다시 켤 때 매번 묻지 않게 |
| G10 | 빠른 출력 지원 · 배수는 domain 표 `fastModeSpecs`, 요청 필드는 어댑터 상수 한 곳. **확인 전 표는 비어 있어** 스위치가 안 보인다 | 지원 모델 · 필드 · 배수가 모두 "(확인 필요)"(A2 · O5). 확인 안 된 필드를 보내 400 을 내느니 숨긴다. 단위 테스트는 표 주입으로 |
| G11 | Claude · GPT 계열 규칙(거르기 · 추천 · 이미지 · effort)은 ③ Task 1 에 함께 | 순수 함수라 한 곳이 읽기 쉽고, ③ 의 카탈로그 테스트가 두 벤더 정렬 규칙을 같이 고정한다. ④ 는 쓰기만 |
| G12 | 동의 문구에서 "위키" 낱말을 뺀다 | 스펙 §5.3 "두 기획이 같이 들어가지 않으면 이 낱말만 빼서 낸다" — 기록 1단계 계획에 위키가 없다(2단계) |
| G13 | OpenAI 도구 결과 사진은 확인 전 기본으로 **뒤따르는 user 입력**에 싣고, `function_call_output` 배열은 생성자 인자로 둔다 | 스펙 §8.3 "되면 거기, 아니면 뒤따르는 user 입력"(O2). 확실히 되는 쪽을 기본으로, 두 경로 모두 테스트 |
| G14 | OpenAI 어댑터는 `response.completed/incomplete/failed` 의 최종 `response.output` 으로 결과를 만들고, 중간 이벤트는 글 조각 · 계측에만 쓴다 | SSE 이벤트 이름이 확인 전(O7)이어도 결과 · `vendorState` 가 맞게. 손 픽스처를 녹화로 바꿔도 깨지는 곳이 적다 |
| G15 | 이미지 거절(400)은 새 `ChatModelErrorKind.imagesUnsupported` 로 받아 세션이 그 모델을 "사진 못 봄"으로 기록하고 한 번만 다시 보낸다 | 스펙 §6.4 마지막 줄. 벤더 오류 모양이 확인 전(O6)이라 코드 표가 틀려도 `server` 로 떨어질 뿐 |
| G16 | `ChatSession.target` 을 `ChatTarget?`(미연결 · 목록 없음이면 null)로 바꾼다 | ③ 에서 모델 id 를 고정하지 않으므로 "모델 없음"이 생긴다. 기록 계획의 cubit 사용처는 Task 4 에서 맞춘다 |
| G17 | 칩 · 시트 상태는 `ModelPickerCubit`(시트 전용)과 `ModelChipData`(탭 · 설정 공용)로 나누고, 시트는 탭 · 설정 어디서 열어도 같은 `ModelPickerSheet.show` | 스펙 §6.2 "설정 화면 모델 행도 같은 시트". 빠른 출력 스위치는 시트에만(설정 모델 행은 켜짐 여부만 — 재구성 설계의 "설정 화면" 제안보다 사용자 결정 우선) |
| G18 | 카탈로그에 `chat.models.vendor` · `chat.models.noImages` 두 prefs 키를 스펙 §7.2 에 더한다 | 백업 복원 · 벤더 바꾸기 뒤 다른 벤더 목록을 쓰지 않게, 이미지 거절 기록이 갱신에 지워지지 않게 |
