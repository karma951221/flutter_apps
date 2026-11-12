import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_attachment.freezed.dart';

enum AttachmentKind { image, pdf, text }

/// 한 질문에 붙는 파일 하나(본문 포함 — 모델에 보낼 때만 쓴다).
///
/// 파일 내용을 담으므로 생성 toString 을 끈다(ChatMessage 와 같은 이유).
/// [workspacePath] 는 작업 폴더 상대 경로(`inbox/…`). 임시 대화는 null.
@Freezed(toStringOverride: false)
sealed class ChatAttachment with _$ChatAttachment {
  const factory ChatAttachment.image({
    required String name,
    required String mediaType,
    required Uint8List bytes,
    String? workspacePath,
  }) = ImageAttachment;

  const factory ChatAttachment.pdf({
    required String name,
    required Uint8List bytes,
    String? workspacePath,
  }) = PdfAttachment;

  const factory ChatAttachment.text({
    required String name,
    required String text,
    String? workspacePath,
  }) = TextAttachment;
}

extension ChatAttachmentX on ChatAttachment {
  AttachmentKind get kind => switch (this) {
    ImageAttachment() => AttachmentKind.image,
    PdfAttachment() => AttachmentKind.pdf,
    TextAttachment() => AttachmentKind.text,
  };

  /// 저장 · 말풍선용. 본문은 버린다.
  ChatAttachmentRef get ref =>
      ChatAttachmentRef(name: name, kind: kind, workspacePath: workspacePath);
}

/// 텍스트 파일을 모델에 보낼 때의 본문 블록. 두 벤더가 같은 모양을 쓴다.
String textAttachmentBlock(TextAttachment attachment) =>
    '<file name="${attachment.name}">\n${attachment.text}\n</file>';

/// 저장 · 말풍선용 첨부(본문 없음).
@freezed
class ChatAttachmentRef with _$ChatAttachmentRef {
  @override
  final String name;
  @override
  final AttachmentKind kind;

  /// 작업 폴더 상대 경로. 임시 대화 · 사본 없음이면 null.
  @override
  final String? workspacePath;

  const ChatAttachmentRef({
    required this.name,
    required this.kind,
    this.workspacePath,
  });

  factory ChatAttachmentRef.fromJson(Map<String, Object?> json) =>
      ChatAttachmentRef(
        name: json['name']! as String,
        kind: AttachmentKind.values.byName(json['kind']! as String),
        workspacePath: json['workspacePath'] as String?,
      );

  Map<String, Object?> toJson() => {
    'name': name,
    'kind': kind.name,
    'workspacePath': workspacePath,
  };
}
