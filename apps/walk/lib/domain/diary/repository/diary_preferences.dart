import '../entity/trash_retention.dart';

/// 일기 화면 설정. 읽기는 동기, 저장된 값이 깨졌으면 기본값.
abstract interface class DiaryPreferences {
  /// 기본 [TrashRetention.fallback](7일).
  TrashRetention get trashRetention;
  Future<void> setTrashRetention(TrashRetention v);
}
