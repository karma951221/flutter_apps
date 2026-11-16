import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/backup/backup_file_probe.dart';
import 'package:walk/domain/backup/backup_files.dart';
import 'package:walk/domain/backup/backup_preferences.dart';
import 'package:walk/domain/backup/backup_service.dart';

class MockBackupService extends Mock implements BackupService {}

class MockBackupFiles extends Mock implements BackupFiles {}

class MockBackupFileProbe extends Mock implements BackupFileProbe {}

class FakeBackupPreferences implements BackupPreferences {
  @override
  DateTime? lastAt;

  @override
  Future<void> setLastAt(DateTime at) async => lastAt = at;
}
