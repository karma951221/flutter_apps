import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/diary/entity/trash_retention.dart';
import '../../domain/diary/repository/diary_preferences.dart';

/// 값은 enum 이름 문자열로 둔다. 타입이 다르거나 모르는 이름이면 기본값.
/// 예전 버전이 저장한 보기 모드 · 마지막 스토리 키는 읽지 않을 뿐 지우지 않는다.
@LazySingleton(as: DiaryPreferences)
class PrefsDiaryPreferences implements DiaryPreferences {
  PrefsDiaryPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const trashRetentionKey = 'walk.diary.trashRetention';

  // getString 은 문자열이 아닌 값에서 던지므로 get 으로 읽고 타입을 확인한다.
  String? _string(String key) => switch (_prefs.get(key)) {
    final String value => value,
    _ => null,
  };

  @override
  TrashRetention get trashRetention =>
      TrashRetention.values.asNameMap()[_string(trashRetentionKey)] ??
      TrashRetention.fallback;

  @override
  Future<void> setTrashRetention(TrashRetention v) =>
      _prefs.setString(trashRetentionKey, v.name);
}
