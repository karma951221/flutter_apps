import '../draft/draft_style.dart';
import '../entity/trash_retention.dart';

/// 일기 화면 설정. 읽기는 동기, 저장된 값이 깨졌으면 기본값.
abstract interface class DiaryPreferences {
  /// 기본 [TrashRetention.fallback](7일).
  TrashRetention get trashRetention;
  Future<void> setTrashRetention(TrashRetention v);

  /// 자동 초안의 기본 문체. 기본 [DraftStyle.fallback](일기체).
  DraftStyle get draftStyle;
  Future<void> setDraftStyle(DraftStyle v);

  /// 사진 보여 주기(작성 화면 도구줄 · 일기 설정이 같이 쓴다). 마지막 선택을 기억한다. 기본 false.
  bool get draftIncludePhotos;
  Future<void> setDraftIncludePhotos(bool v);
}
