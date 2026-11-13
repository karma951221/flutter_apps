import 'package:freezed_annotation/freezed_annotation.dart';

import 'attachment/chat_attachment.dart';
import 'chat_vendor.dart';
import 'tool/tool_result.dart';

part 'chat_model.freezed.dart';

/// 대화 한 칸. 벤더 형식(Messages API 등)으로의 변환은 어댑터가 한다.
///
/// 본문을 담는 타입(여기 · [AssistantPart] · [ToolResultPart] · [ModelEvent])은
/// 생성 toString 을 끈다 — 질문 · 답 · 도구 입력값이 로그에 찍히지 않게.
@Freezed(toStringOverride: false)
sealed class ChatMessage with _$ChatMessage {
  /// [attachments] 는 이 질문에 붙은 파일(본문 포함). 어댑터가 벤더 형식으로 바꾼다.
  const factory ChatMessage.user(
    String text, {
    @Default(<ChatAttachment>[]) List<ChatAttachment> attachments,
  }) = UserMessage;

  /// [vendorState] 는 어댑터만 읽는 불투명 값. domain 은 만들지도 읽지도 않고
  /// 들고만 다닌다. 저장하지 않는다.
  const factory ChatMessage.assistant({
    required List<AssistantPart> parts,
    VendorTurnState? vendorState,
  }) = AssistantMessage;

  const factory ChatMessage.toolResults(List<ToolResultPart> results) =
      ToolResultsMessage;
}

@Freezed(toStringOverride: false)
sealed class AssistantPart with _$AssistantPart {
  const factory AssistantPart.text(String text) = TextPart;
  const factory AssistantPart.toolCall({
    required String id,
    required String name,
    required Map<String, Object?> input,
  }) = ToolCallPart;
}

/// 도구 호출 [callId] 하나의 결과.
@Freezed(toStringOverride: false)
class ToolResultPart with _$ToolResultPart {
  @override
  final String callId;

  /// 결과 본문(JSON 글).
  @override
  final String json;

  /// 실패한 결과. 참이면 [json] 에 `error` 키가 있어야 한다 — 오류 표시가 없는
  /// 벤더(OpenAI `function_call_output`)는 [json] 만 보낸다.
  @override
  final bool isError;
  @override
  final List<ToolImage> images;

  /// tool_result 에 붙는 PDF.
  @override
  final List<ToolDocument> documents;

  const ToolResultPart({
    required this.callId,
    required this.json,
    this.isError = false,
    this.images = const [],
    this.documents = const [],
  });
}

/// 모델에 알려 줄 도구 하나.
/// JSON Schema 는 벤더 공통 부분집합(object · string · integer · enum · required ·
/// array(items 하나))만. 어댑터는 parameters 를 고치지 않고 그대로 싣는다.
@freezed
class ToolSpec with _$ToolSpec {
  @override
  final String name;
  @override
  final String description;

  /// 입력 JSON Schema(최상위 type 은 object).
  @override
  final Map<String, Object?> parameters;

  const ToolSpec({
    required this.name,
    required this.description,
    required this.parameters,
  });
}

/// 한 assistant 턴에 딸린 벤더 전용 원본(서명 등). 어댑터만 만들고 읽는다.
abstract interface class VendorTurnState {
  ChatVendor get vendor;
  String get model;
}

/// [pauseTurn] — 벤더 서버 쪽 도구(웹 검색) 루프가 한 응답 안에서 끝나지 않아 멈췄다.
/// 세션은 그 턴을 덧붙여 사용자 메시지 없이 다시 보낸다 — 벤더가 이어서 답한다.
enum StopKind { endTurn, toolUse, pauseTurn, refusal, maxTokens, other }

@freezed
class TokenUsage with _$TokenUsage {
  @override
  final int inputTokens;
  @override
  final int outputTokens;
  @override
  final int cacheReadTokens;
  @override
  final int cacheWriteTokens;

  /// 벤더가 따로 알려 줄 때만.
  @override
  final int? reasoningTokens;

  const TokenUsage({
    required this.inputTokens,
    required this.outputTokens,
    this.cacheReadTokens = 0,
    this.cacheWriteTokens = 0,
    this.reasoningTokens,
  });
}

/// 어댑터가 내는 스트림 이벤트.
///
/// **어댑터 방출 규칙**(체감 속도 기획 §5.1 — 모든 어댑터가 따른다):
///
/// | 이벤트 | 언제 · 몇 번 | Claude | GPT(Responses) |
/// |---|---|---|---|
/// | `thinking()` | 생각 구간이 열릴 때마다(라운드에 0~여러 번). 내용 없음 | `content_block_start` 의 `thinking` · `redacted_thinking` | reasoning 항목 추가 |
/// | `progress(text)` | 사용자에게 보일 노트. **같은 블록이면 지금까지 모인 글 전체**(누적)를 다시 낸다 — 받는 쪽은 바꿔 끼운다. 앞뒤 공백 trim, 빈 글은 안 냄. **0번이 정상** | `progressNotes` 일 때 비어 있지 않은 `thinking_delta`. 중단 문구는 안 냄(V3) | 추론 요약 delta(청구 확인 뒤, V6). 못 주면 안 냄 |
/// | `toolCallStarted(id, name)` | 도구 호출 블록이 열리는 순간, 입력 완성 전 | `content_block_start(tool_use)` | 함수 호출 항목 추가 |
/// | `toolCallReady(id, name, input)` | 그 블록의 입력이 완성된 순간. `completed.message` 의 `ToolCallPart` 와 **중복으로** 낸다 | `content_block_stop`(tool_use) | 함수 인자 완료 |
/// | `textDelta(text)` | 그대로 | 그대로 | 그대로 |
/// | `webSearch(id, query)` | 벤더 서버의 웹 검색이 열릴 때(query null) · 검색어를 알게 될 때(같은 id 로 다시) | `server_tool_use(web_search)` 시작 · 끝 | `web_search_call` 항목 추가 · 완료 |
///
/// 웹 검색은 벤더 서버가 실행한다 — 세션이 실행할 도구 호출(`toolCall*` · `ToolCallPart`)이
/// 아니다. 그 블록 · 항목은 `vendorState` 에만 남아 같은 모델에 그대로 돌려보낸다.
///
/// 순서 보장: 한 블록의 `toolCallStarted` 는 같은 id 의 `toolCallReady` 보다
/// 먼저, 둘 다 `completed` 보다 먼저. 진행 이벤트는 기록(`completed.message` ·
/// `vendorState`)을 바꾸지 않는다.
///
/// **프롬프트 캐시**: Claude 는 본문 top-level `cache_control: ephemeral` 로 켠다.
/// GPT 는 벤더가 자동으로 캐시한다 — 요청에 더할 필드가 없다. 둘 다 세션의 system ·
/// tools 접두부가 같은 날 바이트까지 같아야 맞는다(날짜 줄은 system 끝).
@Freezed(toStringOverride: false)
sealed class ModelEvent with _$ModelEvent {
  const factory ModelEvent.textDelta(String text) = ModelTextDelta;

  // 진행 이벤트 — 이름 · 모양은 체감 속도 기획 §5.1, 방출 규칙은 위 표.
  const factory ModelEvent.thinking() = ModelThinking;
  const factory ModelEvent.progress(String text) = ModelProgress;
  const factory ModelEvent.toolCallStarted({
    required String id,
    required String name,
  }) = ModelToolCallStarted;
  const factory ModelEvent.toolCallReady({
    required String id,
    required String name,
    required Map<String, Object?> input,
  }) = ModelToolCallReady;

  /// 벤더 서버의 웹 검색 하나(진행 표시만). [query] 는 알게 됐을 때만 — 같은 [id] 로
  /// 먼저 null, 뒤에 검색어가 올 수 있다(받는 쪽은 바꿔 끼운다).
  const factory ModelEvent.webSearch({required String id, String? query}) =
      ModelWebSearch;

  /// 한 응답이 끝났다. 사용량은 여기 한 곳(별도 usage 이벤트 없음). 못 읽으면 null.
  const factory ModelEvent.completed({
    required AssistantMessage message,
    required StopKind stop,
    required TokenUsage? usage,
  }) = ModelCompleted;
}

/// 모델 한 번 부르기.
///
/// Freezed 아님 — 생성 toString 이 [apiKey] 를 찍기 때문. toString 은 키 · system ·
/// 메시지 본문 없이 모델 · 개수만.
final class ModelRequest {
  const ModelRequest({
    required this.apiKey,
    required this.model,
    this.fastMode = false,
    required this.system,
    required this.messages,
    required this.tools,
    this.webSearch = false,
  });

  final String apiKey;
  final String model;
  final bool fastMode;
  final String system;
  final List<ChatMessage> messages;
  final List<ToolSpec> tools;

  /// 벤더가 호스팅하는 웹 검색 도구를 붙일까. 붙이는 모양(도구 종류 · 버전)은 어댑터
  /// 몫이고, 그 모델이 받지 않으면 어댑터가 뺀다(`chat_model_rules.dart`).
  final bool webSearch;

  @override
  String toString() =>
      'ModelRequest(model: $model, fastMode: $fastMode, '
      'messages: ${messages.length}, tools: ${tools.length}, '
      'webSearch: $webSearch)';
}

enum ChatModelErrorKind {
  invalidKey,
  rateLimited,
  overloaded,
  network,
  server,
  quotaExceeded,
  modelUnavailable,

  /// 모델이 이미지 입력을 거절했다(§6.4). Anthropic 은 내지 않는다.
  imagesUnsupported,
}

/// 키나 응답 본문을 담지 않는다.
class ChatModelException implements Exception {
  const ChatModelException(this.kind);

  final ChatModelErrorKind kind;

  @override
  String toString() => 'ChatModelException($kind)';
}

/// 벤더 모델 목록의 한 항목. 모르는 능력은 null.
@freezed
class ModelInfo with _$ModelInfo {
  @override
  final String id;

  /// 벤더가 주지 않으면 [id].
  @override
  final String displayName;
  @override
  final DateTime? createdAt;
  @override
  final bool? supportsTools;
  @override
  final bool? supportsImages;

  /// 키 기획 ② 에서는 늘 false(③ 에서 채운다).
  @override
  final bool supportsFastMode;
  @override
  final List<String> aliases;

  const ModelInfo({
    required this.id,
    required this.displayName,
    this.createdAt,
    this.supportsTools,
    this.supportsImages,
    this.supportsFastMode = false,
    this.aliases = const [],
  });
}

/// [ChatModel.listModels] 의 결과. 키 확인 겸 목록.
@freezed
sealed class ModelListResult with _$ModelListResult {
  const factory ModelListResult.ok(List<ModelInfo> models) = ModelListOk;
  const factory ModelListResult.invalidKey() = ModelListInvalidKey;

  /// 네트워크 · 시간 초과 · 그 밖의 상태 코드. 키가 맞는지 모른다.
  const factory ModelListResult.unreachable() = ModelListUnreachable;
}

abstract interface class ChatModel {
  ChatVendor get vendor;

  /// 이 어댑터가 사용자에게 보일 진행 노트([ModelProgress])를 낼 수 있게 설정됐는가.
  /// false 면 세션은 시스템 프롬프트의 "도구 전 한 줄 안내"를 넣지 않는다(체감 속도 §3.1 대체 경로).
  bool get progressNotes;

  /// 키 확인 겸 목록(§4 · §6.3). 예외를 던지지 않는다 — 실패는 결과 값.
  Future<ModelListResult> listModels(String apiKey);

  /// 실패는 스트림 오류 [ChatModelException] 으로 낸다.
  ///
  /// 취소 계약: 구독을 cancel 하면 어댑터는 진행 중인 HTTP 요청을 즉시 닫고, 그 뒤
  /// 이벤트 · 오류를 내지 않는다.
  Stream<ModelEvent> stream(ModelRequest request);
}

/// 벤더 → 어댑터. domain 은 이 계약만 안다.
abstract interface class ChatModelRegistry {
  ChatModel of(ChatVendor vendor);
}
