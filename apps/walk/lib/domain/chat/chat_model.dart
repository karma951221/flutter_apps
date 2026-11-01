import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_vendor.dart';
import 'tool/tool_result.dart';

part 'chat_model.freezed.dart';

/// 대화 한 칸. 벤더 형식(Messages API 등)으로의 변환은 어댑터가 한다.
///
/// 본문을 담는 타입(여기 · [AssistantPart] · [ToolResultPart] · [ModelEvent])은
/// 생성 toString 을 끈다 — 질문 · 답 · 도구 입력값이 로그에 찍히지 않게.
@Freezed(toStringOverride: false)
sealed class ChatMessage with _$ChatMessage {
  const factory ChatMessage.user(String text) = UserMessage;

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
  @override
  final bool isError;
  @override
  final List<ToolImage> images;

  const ToolResultPart({
    required this.callId,
    required this.json,
    this.isError = false,
    this.images = const [],
  });
}

/// 모델에 알려 줄 도구 하나.
/// JSON Schema 는 벤더 공통 부분집합(object · string · integer · enum · required)만.
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

enum StopKind { endTurn, toolUse, refusal, maxTokens, other }

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

@Freezed(toStringOverride: false)
sealed class ModelEvent with _$ModelEvent {
  const factory ModelEvent.textDelta(String text) = ModelTextDelta;

  // 진행 이벤트 — 이름 · 모양은 체감 속도 기획 §5.1. 지금 어댑터는 아직 내지
  // 않는다(진행 줄 단계에서 낸다).
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
  });

  final String apiKey;
  final String model;
  final bool fastMode;
  final String system;
  final List<ChatMessage> messages;
  final List<ToolSpec> tools;

  @override
  String toString() =>
      'ModelRequest(model: $model, fastMode: $fastMode, '
      'messages: ${messages.length}, tools: ${tools.length})';
}

enum ChatModelErrorKind {
  invalidKey,
  rateLimited,
  overloaded,
  network,
  server,
  quotaExceeded,
  modelUnavailable,
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

  /// 키 확인 겸 목록(§4 · §6.3). 예외를 던지지 않는다 — 실패는 결과 값.
  Future<ModelListResult> listModels(String apiKey);

  /// 실패는 스트림 오류 [ChatModelException] 으로 낸다.
  ///
  /// 취소 계약: 구독을 cancel 하면 어댑터는 진행 중인 HTTP 요청을 즉시 닫고, 그 뒤
  /// 이벤트 · 오류를 내지 않는다.
  Stream<ModelEvent> stream(ModelRequest request);
}
