import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/backup/prefs_backup_preferences.dart';

void main() {
  test('lastAt round trips and is null when missing or malformed', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backup = PrefsBackupPreferences(prefs);
    expect(backup.lastAt, isNull);

    await backup.setLastAt(DateTime(2026, 11, 16, 21, 30));
    expect(prefs.getString('walk.backup.lastAt'), '2026-11-16T21:30:00.000');
    expect(backup.lastAt, DateTime(2026, 11, 16, 21, 30));

    await prefs.setString('walk.backup.lastAt', 'oops');
    expect(backup.lastAt, isNull);
    await prefs.setInt('walk.backup.lastAt', 3);
    expect(backup.lastAt, isNull);
  });
}
