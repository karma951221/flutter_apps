import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/chat/attachment/attachment_loader.dart';
import '../../../domain/chat/attachment/attachment_rules.dart';
import '../../../domain/chat/attachment/chat_attachment.dart';
import '../chat_image_compress.dart';

/// 고른 파일을 디스크에서 읽어 첨부로 만든다.
///
/// 형식(확장자) → 크기(알려 준 크기와 실제 크기 중 큰 쪽) → 종류별 읽기 순서로 본다.
/// 사진은 일기 사진 도구와 같은 설정으로 줄인 JPEG, PDF 는 바이트 그대로, 텍스트는 엄격한 UTF-8.
/// 읽지 못한 파일(없음 · 권한 · 줄이기 실패)은 [AttachmentRejection.unsupportedType].
@LazySingleton(as: AttachmentLoader)
class FileAttachmentLoader implements AttachmentLoader {
  FileAttachmentLoader() : this.withCompressor(compressChatImage);

  @visibleForTesting
  FileAttachmentLoader.withCompressor(this._compress);

  /// 사진 경로 → 줄인 JPEG. 못 줄이면 null.
  final Future<Uint8List?> Function(String path) _compress;

  @override
  Future<AttachmentLoad> load(PickedFile file) async {
    final name = file.name;
    AttachmentLoad reject(AttachmentRejection why) =>
        AttachmentLoad.rejected(name, why);

    final kind = AttachmentRules.kindOf(name);
    if (kind == null) return reject(AttachmentRejection.unsupportedType);
    if (AttachmentRules.checkSize(kind, file.sizeBytes) case final why?) {
      return reject(why);
    }
    try {
      final source = File(file.path);
      if (AttachmentRules.checkSize(kind, await source.length())
          case final why?) {
        return reject(why);
      }
      final ChatAttachment attachment;
      switch (kind) {
        case AttachmentKind.image:
          final jpeg = await _compress(file.path);
          if (jpeg == null) return reject(AttachmentRejection.unsupportedType);
          attachment = ChatAttachment.image(
            name: name,
            mediaType: 'image/jpeg',
            bytes: jpeg,
            workspacePath: file.workspacePath,
          );
        case AttachmentKind.pdf:
          attachment = ChatAttachment.pdf(
            name: name,
            bytes: await source.readAsBytes(),
            workspacePath: file.workspacePath,
          );
        case AttachmentKind.text:
          final String text;
          try {
            text = utf8.decode(await source.readAsBytes());
          } on FormatException {
            return reject(AttachmentRejection.notUtf8);
          }
          attachment = ChatAttachment.text(
            name: name,
            text: text,
            workspacePath: file.workspacePath,
          );
      }
      return AttachmentLoad.ok(attachment);
    } on FileSystemException {
      return reject(AttachmentRejection.unsupportedType);
    } on Exception {
      // 플러그인(사진 줄이기) 오류 등.
      return reject(AttachmentRejection.unsupportedType);
    }
  }
}
