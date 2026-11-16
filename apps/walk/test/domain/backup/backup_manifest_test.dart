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
      createdAt: DateTime(2026, 11, 16, 21, 30),
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

  group('createdAt', () {
    Map<String, dynamic> json(String createdAt) => {
      'format': 'lifelog.backup',
      'formatVersion': 1,
      'appVersion': '1',
      'createdAt': createdAt,
      'areas': <String, dynamic>{},
      'files': <Object>[],
    };

    test('is written as UTC ISO-8601 with an offset', () {
      final at = DateTime(2026, 11, 16, 21, 30);
      final m = BackupManifest(
        format: BackupManifest.formatName,
        formatVersion: 1,
        appVersion: '1',
        createdAt: at,
        areas: const {},
        files: const [],
      );
      expect(m.toJson()['createdAt'], at.toUtc().toIso8601String());
      expect(m.toJson()['createdAt'], endsWith('Z'));
    });

    test('is read back as local time for display', () {
      final m = BackupManifest.fromJson(json('2026-11-16T12:30:00.000Z'));
      expect(m.createdAt.isUtc, isFalse);
      expect(m.createdAt, DateTime.utc(2026, 11, 16, 12, 30).toLocal());
    });

    test('old local strings without an offset still parse', () {
      final m = BackupManifest.fromJson(json('2026-11-16T21:30:00.000'));
      expect(m.createdAt, DateTime(2026, 11, 16, 21, 30));
    });
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
