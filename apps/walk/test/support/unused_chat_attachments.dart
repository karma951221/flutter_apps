import 'dart:typed_data';

import 'package:walk/domain/chat/attachment/attachment_loader.dart';
import 'package:walk/domain/chat/workspace/workspace.dart';

/// 첨부를 다루지 않는 채팅 테스트용 — 불리면 [UnimplementedError] 로 드러난다.
class UnusedWorkspace implements Workspace {
  const UnusedWorkspace();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Workspace.${invocation.memberName}');
}

class UnusedAttachmentLoader implements AttachmentLoader {
  const UnusedAttachmentLoader();

  @override
  Future<AttachmentLoad> load(PickedFile file) =>
      throw UnimplementedError('AttachmentLoader.load');

  @override
  Future<Uint8List> readOriginal(String path) =>
      throw UnimplementedError('AttachmentLoader.readOriginal');
}
