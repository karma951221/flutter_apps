import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/diary/draft/draft_style.dart';
import 'package:walk/domain/diary/entity/trash_retention.dart';
import 'package:walk/domain/diary/repository/diary_preferences.dart';

/// 메모리 위 [DiaryPreferences]. 값을 테스트가 직접 바꾼다.
class FakeDiaryPreferences implements DiaryPreferences {
  @override
  TrashRetention trashRetention = TrashRetention.fallback;

  @override
  Future<void> setTrashRetention(TrashRetention v) async => trashRetention = v;

  @override
  DraftStyle draftStyle = DraftStyle.fallback;

  @override
  Future<void> setDraftStyle(DraftStyle v) async => draftStyle = v;

  @override
  bool draftIncludePhotos = false;

  @override
  Future<void> setDraftIncludePhotos(bool v) async => draftIncludePhotos = v;

  @override
  bool storyAiOff = false;

  @override
  Future<void> setStoryAiOff(bool v) async => storyAiOff = v;

  @override
  ChatVendor? storyAiVendor;

  @override
  Future<void> setStoryAiVendor(ChatVendor v) async => storyAiVendor = v;
}
