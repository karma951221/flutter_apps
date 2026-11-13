import 'dart:typed_data';

import 'package:walk/domain/chat/attachment/attachment_loader.dart';
import 'package:walk/domain/chat/workspace/workspace.dart';
import 'package:walk/presentation/chat/attachment/chat_file_picker.dart';

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

/// 선택기 캐시를 지우지 않는다 — 부른 경로만 적는다.
class FakePickedFileCache implements PickedFileCache {
  final released = <String>[];
  var cleared = 0;

  @override
  Future<void> release(String path) async => released.add(path);

  @override
  Future<void> clearAll() async => cleared++;
}

/// 선택기를 열지 않는 [ChatFilePicker] — 탭 테스트의 getIt 용. 캐시도 건드리지 않는다.
class NoopChatFilePicker implements ChatFilePicker {
  const NoopChatFilePicker();

  @override
  Future<List<PickedFile>> pick() async => const [];

  @override
  Future<void> release(String path) async {}

  @override
  Future<void> clearAll() async {}
}
