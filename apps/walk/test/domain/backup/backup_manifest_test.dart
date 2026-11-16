import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/backup/backup_area_id.dart';
import 'package:walk/domain/backup/backup_manifest.dart';

void main() {
  test('manifest json round trip', () {
    final m = BackupManifest(
      format: BackupManifest.formatName,
      formatVersion: 1,
      appVersion: '1.0.0+1',
      createdAt: DateTime.utc(2026, 11, 16, 12, 30),
      areas: const {
        BackupAreaId.diary: AreaManifest(
          schema: {'diary': 1},
          counts: {'entries': 120},
        ),
        BackupAreaId.settings: AreaManifest(schema: {'prefs': 1}),
      },
      files: const [ManifestFile(path: 'a/b.json', bytes: 3, sha256: 'ab')],
    );
    final back = BackupManifest.fromJson(
      jsonDecode(jsonEncode(m.toJson())) as Map<String, dynamic>,
    );
    expect(back, m);
  });

  test('unknown area key ignored', () {
    final m = BackupManifest.fromJson({
      'format': 'lifelog.backup',
      'formatVersion': 1,
      'appVersion': '1',
      'createdAt': '2026-11-16T21:30:00+09:00',
      'areas': {
        'diary': {
          'schema': {'diary': 1},
        },
        'hologram': {
          'schema': {'x': 9},
        },
      },
      'files': [],
    });
    expect(m.areas.keys, [BackupAreaId.diary]);
  });

  test('location is the only area off by default', () {
    expect(
      BackupAreaId.values.where((a) => !a.defaultSelected),
      [BackupAreaId.location],
    );
  });
}
