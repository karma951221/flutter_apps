import 'dart:typed_data';

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

/// 파일 선택기가 고른 파일을 앱 캐시에 복사해 둔 사본([PickedFile.path])의 수명.
/// 첨부를 다 쓰면(거절 · 빼기 · 사본을 넣었거나 보냄) 지운다 — 임시 대화의 원본이 기기에
/// 남지 않게. 선택기 캐시 안의 경로만 지우고, 작업 폴더 파일은 건드리지 않는다.
abstract interface class PickedFileCache {
  /// [path] 의 캐시 사본(과 비게 된 상위 폴더)을 지운다. 캐시 밖이거나 없으면 아무것도 하지
  /// 않는다. 던지지 않는다.
  Future<void> release(String path);

  /// 선택기 캐시를 모두 비운다. 던지지 않는다.
  Future<void> clearAll();
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

  /// 고른 원본 파일([PickedFile.path])의 바이트 그대로 — 작업 폴더 inbox 사본용. 읽지 못하면 던진다.
  Future<Uint8List> readOriginal(String path);
}
