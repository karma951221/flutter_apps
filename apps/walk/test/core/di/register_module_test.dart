import 'dart:io';

import 'package:core/core.dart' hide RegisterModule;
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/core/di/register_module.dart';
import 'package:walk/domain/backup/backup_area_id.dart';
import 'package:walk/domain/backup/backup_area_source.dart';
import 'package:walk/domain/backup/backup_failure.dart';
import 'package:walk/domain/backup/backup_files.dart';
import 'package:walk/domain/backup/restore_notice.dart';

import '../../support/diary_fixtures.dart';

class _Module extends RegisterModule {}

class _TinyDisk implements BackupFiles {
  @override
  Future<int?> freeBytes() async => 1;

  @override
  Future<File?> open() async => null;

  @override
  Future<void> restartApp() async {}

  @override
  Future<bool> saveAs(File source, String suggestedName) async => false;
}

class _Area implements BackupAreaSource {
  @override
  BackupAreaId get id => BackupAreaId.settings;

  @override
  Map<String, int> get schema => const {'prefs': 1};

  @override
  Future<Map<String, int>> counts() async => const {};

  @override
  Future<int> estimatedBytes() async => 1000;

  @override
  Future<Map<String, int>> export(Directory root) async => const {};

  @override
  Future<void> validate(Directory root) async {}

  @override
  Future<void> replace(Directory root) async {}

  @override
  Future<Set<RestoreNotice>> afterRestore() async => const {};
}

void main() {
  test('backup service checks free space through BackupFiles', () async {
    final tmp = Directory.systemTemp.createTempSync('register_module_test');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final service = _Module().backupService(
      [_Area()],
      Directory('${tmp.path}/docs'),
      Directory('${tmp.path}/cache'),
      MutableClock(DateTime(2026, 11, 17)),
      _TinyDisk(),
    );

    final result = await service.export({BackupAreaId.settings});
    expect(
      result,
      isA<Err<File>>().having(
        (e) => e.failure,
        'failure',
        BackupFailure.noSpace.toFailure(),
      ),
    );
  });
}
