import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_model.freezed.dart';

@freezed
sealed class ModelEvent with _$ModelEvent {
  const factory ModelEvent.textDelta(String text) = ModelTextDelta;

  /// 한 응답의 완성된 content 블록들(API JSON 그대로, thinking 서명 포함)과 stop_reason.
  const factory ModelEvent.completed({
    required List<Map<String, Object?>> content,
    required String stopReason,
  }) = ModelCompleted;
}

enum ChatModelErrorKind { invalidKey, rateLimited, overloaded, network, server }

/// 키나 응답 본문을 담지 않는다.
class ChatModelException implements Exception {
  const ChatModelException(this.kind);

  final ChatModelErrorKind kind;

  @override
  String toString() => 'ChatModelException($kind)';
}

abstract interface class ChatModel {
  /// 실패는 스트림 오류 [ChatModelException] 으로 낸다.
  Stream<ModelEvent> stream({
    required String apiKey,
    required String system,
    required List<Map<String, Object?>> messages,
    required List<Map<String, Object?>> tools,
  });
}
