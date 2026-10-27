import '../../diary/entity/entry_media.dart';
import 'tool_result.dart';

/// 채팅에 보낼 이미지를 만든다(줄이고 JPEG 로 바꾼다).
abstract interface class ChatImageSource {
  /// 실패하면 null.
  Future<ToolImage?> load(EntryMedia media);
}
