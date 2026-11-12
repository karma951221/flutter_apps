import 'package:injectable/injectable.dart';

import '../../domain/chat/tool/chat_image_source.dart';
import '../../domain/chat/tool/tool_result.dart';
import '../../domain/diary/entity/entry_media.dart';
import '../../domain/diary/media/media_store.dart';
import 'chat_image_compress.dart';

/// 일기 사진을 긴 변 1024 안으로 줄여 JPEG 로 낸다. 플러그인이라 단위 테스트는 하지 않는다.
@LazySingleton(as: ChatImageSource)
class CompressedChatImageSource implements ChatImageSource {
  CompressedChatImageSource(this._store);

  final MediaStore _store;

  @override
  Future<ToolImage?> load(EntryMedia media) async {
    try {
      final file = _store.resolve(media.path);
      final bytes = await compressChatImage(file.path);
      if (bytes == null) return null;
      return ToolImage(mediaType: 'image/jpeg', bytes: bytes);
    } catch (_) {
      return null;
    }
  }
}
