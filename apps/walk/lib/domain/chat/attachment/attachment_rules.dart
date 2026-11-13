import 'dart:convert';

import 'chat_attachment.dart';

/// 첨부를 거절하는 이유.
enum AttachmentRejection {
  unsupportedType,
  tooLarge,
  notUtf8,
  perQuestionLimit,
  conversationDocLimit,
  conversationImageLimit,

  /// 이 대화의 PDF · 텍스트 바이트 합계([AttachmentRules.maxDocBytesPerConversation])를 넘는다.
  conversationSizeLimit,
}

/// 첨부 형식 · 크기 · 개수 규칙.
abstract final class AttachmentRules {
  static const maxImageBytes = 30 * 1024 * 1024;
  static const maxPdfBytes = 10 * 1024 * 1024;
  static const maxTextBytes = 200 * 1024;

  /// 한 질문에 붙일 수 있는 개수.
  static const maxPerQuestion = 3;

  /// 한 대화의 PDF + 텍스트 개수(사진은 세션의 사진 한도를 쓴다).
  static const maxDocsPerConversation = 5;

  /// 한 대화의 PDF + 텍스트 원본 바이트 합계. 보낸 첨부는 매 요청에 다시 실린다 —
  /// base64 로 늘어도 벤더 요청 한도(Anthropic 32MB) 안에 들게 둔다.
  static const maxDocBytesPerConversation = 18 * 1024 * 1024;

  /// 글 없이 첨부만 보낼 때의 질문.
  static const emptyQuestion = '첨부한 파일을 봐 줘.';

  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic'};
  static const _textExtensions = {'txt', 'md', 'csv', 'json', 'log'};

  /// 확장자(소문자 비교)로 종류를 가른다. 받지 않는 형식이면 null.
  static AttachmentKind? kindOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0) return null;
    final ext = fileName.substring(dot + 1).toLowerCase();
    if (_imageExtensions.contains(ext)) return AttachmentKind.image;
    if (ext == 'pdf') return AttachmentKind.pdf;
    if (_textExtensions.contains(ext)) return AttachmentKind.text;
    return null;
  }

  static AttachmentRejection? checkSize(AttachmentKind kind, int sizeBytes) {
    final max = switch (kind) {
      AttachmentKind.image => maxImageBytes,
      AttachmentKind.pdf => maxPdfBytes,
      AttachmentKind.text => maxTextBytes,
    };
    return sizeBytes > max ? AttachmentRejection.tooLarge : null;
  }

  /// [attachments] 중 PDF · 텍스트의 바이트 합계(텍스트는 UTF-8). 사진은 세지 않는다.
  static int docBytesOf(Iterable<ChatAttachment> attachments) {
    var total = 0;
    for (final a in attachments) {
      total += switch (a) {
        ImageAttachment() => 0,
        PdfAttachment(:final bytes) => bytes.length,
        TextAttachment(:final text) => utf8.encode(text).length,
      };
    }
    return total;
  }

  /// 이어 간 대화에 다시 채울 질문 — 끝 줄에 첨부 이름을 붙인다.
  static String questionWithNames(String question, List<String> names) =>
      names.isEmpty ? question : '$question\n(첨부: ${names.join(', ')})';
}
