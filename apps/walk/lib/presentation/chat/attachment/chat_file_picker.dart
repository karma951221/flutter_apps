import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/chat/attachment/attachment_loader.dart';
import '../../lock/media_pick_guard.dart';

/// 물어보기 [📎] 의 시스템 파일 선택기(여러 개). 나가 있는 동안 [MediaPickGuard] 를 켜
/// 돌아왔을 때 일기가 다시 잠기지 않는다.
///
/// 형식은 거르지 않는다 — 받지 않는 형식은 로더가 거절하고 화면이 이유를 알린다.
/// 로컬 경로가 없는 항목(드문 content URI)은 뺀다. 플러그인이라 단위 테스트는 하지 않는다.
@injectable
class ChatFilePicker {
  ChatFilePicker(this._guard);

  final MediaPickGuard _guard;

  /// 취소하면 빈 목록.
  Future<List<PickedFile>> pick() async {
    final files = await _guard.run(FilePicker.pickFiles);
    final picked = <PickedFile>[];
    for (final f in files) {
      final path = f.path;
      if (path == null) continue;
      picked.add(
        PickedFile(
          name: f.name,
          path: path,
          sizeBytes: f.lengthSync() ?? await f.length() ?? 0,
        ),
      );
    }
    return picked;
  }
}
