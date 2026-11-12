import 'package:freezed_annotation/freezed_annotation.dart';

import 'attachment_rules.dart';
import 'chat_attachment.dart';

part 'attachment_loader.freezed.dart';

/// 고른 파일 하나. [path] 는 로더가 읽을 절대 경로.
/// [workspacePath] 는 이미 작업 폴더 안에 있는 파일의 상대 경로 — 있으면 inbox 에 다시 넣지 않는다.
@freezed
class PickedFile with _$PickedFile {
  @override
  final String name;
  @override
  final String path;
  @override
  final int sizeBytes;
  @override
  final String? workspacePath;

  const PickedFile({
    required this.name,
    required this.path,
    required this.sizeBytes,
    this.workspacePath,
  });
}

/// 파일 하나를 첨부로 읽은 결과.
@freezed
sealed class AttachmentLoad with _$AttachmentLoad {
  const factory AttachmentLoad.ok(ChatAttachment attachment) = AttachmentLoaded;
  const factory AttachmentLoad.rejected(String name, AttachmentRejection why) =
      AttachmentRejected;
}

/// 고른 파일을 형식 · 크기 규칙대로 읽어 첨부로 만든다(사진은 줄인다).
abstract interface class AttachmentLoader {
  Future<AttachmentLoad> load(PickedFile file);
}
