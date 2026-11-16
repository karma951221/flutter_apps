import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/backup/backup_preferences.dart';

/// 시각은 ISO-8601 문자열로 둔다. 타입이 다르거나 읽을 수 없으면 null.
@LazySingleton(as: BackupPreferences)
class PrefsBackupPreferences implements BackupPreferences {
  PrefsBackupPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const lastAtKey = 'walk.backup.lastAt';

  @override
  DateTime? get lastAt => switch (_prefs.get(lastAtKey)) {
    final String raw => DateTime.tryParse(raw),
    _ => null,
  };

  @override
  Future<void> setLastAt(DateTime at) =>
      _prefs.setString(lastAtKey, at.toIso8601String());
}
