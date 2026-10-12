import '../entity/diary_view_mode.dart';
import '../entity/trash_retention.dart';

/// 일기 화면 설정. 읽기는 동기, 저장된 값이 깨졌으면 기본값.
abstract interface class DiaryPreferences {
  /// 기본 [TrashRetention.fallback](7일).
  TrashRetention get trashRetention;
  Future<void> setTrashRetention(TrashRetention v);

  /// 마지막으로 보던 스토리. null 이면 '전체'.
  String? get lastViewedStoryId;
  Future<void> setLastViewedStoryId(String? id);

  /// 기본 [DiaryViewMode.prose](줄글).
  DiaryViewMode get viewMode;
  Future<void> setViewMode(DiaryViewMode v);
}
