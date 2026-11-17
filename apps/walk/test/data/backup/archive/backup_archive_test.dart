import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/backup/archive/backup_archive.dart';
import 'package:walk/domain/backup/backup_area_id.dart';
import 'package:walk/domain/backup/backup_failure.dart';
import 'package:walk/domain/backup/backup_manifest.dart';

BackupManifest _manifest({int formatVersion = 1}) => BackupManifest(
  format: BackupManifest.formatName,
  formatVersion: formatVersion,
  appVersion: '1.0.0+1',
  createdAt: DateTime.utc(2026, 11, 16),
  areas: const {
    BackupAreaId.diary: AreaManifest(schema: {'diary': 1}),
  },
  files: const [],
);

Future<BackupFailure?> _failureOf(Future<void> Function() body) async {
  try {
    await body();
  } on BackupException catch (e) {
    return e.failure;
  }
  return null;
}

String _hex(List<int> b) => sha256.convert(b).toString();

void main() {
  late Directory tmp;
  late Directory staging;
  late File zip;
  const archive = BackupArchive();

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('backup_archive_test');
    staging = Directory('${tmp.path}/staging')..createSync();
    zip = File('${tmp.path}/out.zip');
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  void put(String rel, List<int> bytes) {
    final f = File('${staging.path}/$rel')..createSync(recursive: true);
    f.writeAsBytesSync(bytes);
  }

  /// 손으로 만든 zip(manifest 는 호출자가 준 그대로).
  void handZip(Map<String, List<int>> entries) {
    final a = Archive();
    entries.forEach((n, b) => a.add(ArchiveFile.bytes(n, b)));
    zip.writeAsBytesSync(ZipEncoder().encode(a));
  }

  Map<String, dynamic> manifestJson(
    List<Map<String, Object>> files, {
    int formatVersion = 1,
    String format = 'lifelog.backup',
  }) => {
    'format': format,
    'formatVersion': formatVersion,
    'appVersion': '1',
    'createdAt': '2026-11-16T00:00:00Z',
    'areas': <String, dynamic>{},
    'files': files,
  };

  List<int> enc(Map<String, dynamic> m) => utf8.encode(jsonEncode(m));

  test('pack and unpack report per-file progress up to 1', () async {
    put('diary/a.json', [1]);
    put('diary/b.json', [2]);
    put('diary/c.json', [3]);
    final packing = <double>[];
    await archive.pack(staging, _manifest(), zip, onProgress: packing.add);
    final unpacking = <double>[];
    await archive.unpack(
      zip,
      Directory('${tmp.path}/out'),
      onProgress: unpacking.add,
    );

    for (final steps in [packing, unpacking]) {
      expect(steps.length, greaterThanOrEqualTo(3));
      expect(steps, orderedEquals([...steps]..sort()));
      expect(steps.last, 1.0);
    }
  });

  test('pack then unpack restores files byte-equal', () async {
    final json = utf8.encode('{"a":"가나다"}');
    final media = List<int>.generate(5000, (i) => i % 251);
    put('diary/data.json', json);
    put('diary/media/x.jpg', media);
    await archive.pack(staging, _manifest(), zip);

    final into = Directory('${tmp.path}/restored');
    final m = await archive.unpack(zip, into);

    expect(File('${into.path}/diary/data.json').readAsBytesSync(), json);
    expect(File('${into.path}/diary/media/x.jpg').readAsBytesSync(), media);
    expect(m.files.map((f) => f.path).toSet(), {
      'diary/data.json',
      'diary/media/x.jpg',
    });
    final jpg = m.files.firstWhere((f) => f.path == 'diary/media/x.jpg');
    expect(jpg.bytes, media.length);
    expect(jpg.sha256, _hex(media));
    expect(m.areas.keys, [BackupAreaId.diary]);
  });

  test('manifest is first entry; media stored, json deflated', () async {
    put('diary/data.json', utf8.encode('x' * 2000));
    put('diary/media/x.jpg', List<int>.filled(2000, 7));
    await archive.pack(staging, _manifest(), zip);

    final entries = ZipDecoder().decodeBytes(zip.readAsBytesSync());
    expect(entries.first.name, 'manifest.json');
    final byName = {for (final e in entries) e.name: e};
    expect(byName['diary/media/x.jpg']!.compression, CompressionType.none);
    expect(byName['diary/data.json']!.compression, CompressionType.deflate);
  });

  test('tampered file -> integrity and no leftover dir', () async {
    put('diary/data.json', utf8.encode('hello'));
    await archive.pack(staging, _manifest(), zip);
    final m = await archive.unpack(zip, Directory('${tmp.path}/ok'));
    final f = m.files.single;
    handZip({
      'manifest.json': enc(
        manifestJson([
          {'path': f.path, 'bytes': 5, 'sha256': f.sha256},
        ]),
      ),
      'diary/data.json': utf8.encode('HELLO'),
    });
    final into = Directory('${tmp.path}/bad');
    expect(
      await _failureOf(() => archive.unpack(zip, into)),
      BackupFailure.integrity,
    );
    expect(into.existsSync(), isFalse);
  });

  test('zip-slip entry -> integrity', () async {
    final evil = utf8.encode('evil');
    handZip({
      'manifest.json': enc(
        manifestJson([
          {'path': '../evil.txt', 'bytes': 4, 'sha256': _hex(evil)},
        ]),
      ),
      '../evil.txt': evil,
    });
    final into = Directory('${tmp.path}/slip/inner');
    expect(
      await _failureOf(() => archive.unpack(zip, into)),
      BackupFailure.integrity,
    );
    expect(File('${tmp.path}/slip/evil.txt').existsSync(), isFalse);
    expect(into.existsSync(), isFalse);
  });

  test('absolute path entry -> integrity', () async {
    final b = utf8.encode('x');
    handZip({
      'manifest.json': enc(
        manifestJson([
          {'path': '/abs.txt', 'bytes': 1, 'sha256': _hex(b)},
        ]),
      ),
      '/abs.txt': b,
    });
    expect(
      await _failureOf(() => archive.unpack(zip, Directory('${tmp.path}/a'))),
      BackupFailure.integrity,
    );
  });

  test('file not listed in manifest -> integrity', () async {
    handZip({
      'manifest.json': enc(manifestJson([])),
      'extra.json': utf8.encode('{}'),
    });
    expect(
      await _failureOf(() => archive.unpack(zip, Directory('${tmp.path}/e'))),
      BackupFailure.integrity,
    );
  });

  test('file listed but missing from zip -> integrity', () async {
    handZip({
      'manifest.json': enc(
        manifestJson([
          {
            'path': 'gone.json',
            'bytes': 1,
            'sha256': _hex([1]),
          },
        ]),
      ),
    });
    expect(
      await _failureOf(() => archive.unpack(zip, Directory('${tmp.path}/m'))),
      BackupFailure.integrity,
    );
  });

  test('formatVersion 2 -> newerFormat', () async {
    handZip({'manifest.json': enc(manifestJson([], formatVersion: 2))});
    expect(
      await _failureOf(() => archive.unpack(zip, Directory('${tmp.path}/n'))),
      BackupFailure.newerFormat,
    );
  });

  test('not a lifelog zip -> notBackup', () async {
    handZip({'hello.txt': utf8.encode('hi')});
    expect(
      await _failureOf(() => archive.unpack(zip, Directory('${tmp.path}/o'))),
      BackupFailure.notBackup,
    );
    handZip({'manifest.json': enc(manifestJson([], format: 'other'))});
    expect(
      await _failureOf(() => archive.unpack(zip, Directory('${tmp.path}/p'))),
      BackupFailure.notBackup,
    );
    zip.writeAsBytesSync(utf8.encode('plain text, not a zip at all'));
    expect(
      await _failureOf(() => archive.unpack(zip, Directory('${tmp.path}/q'))),
      BackupFailure.notBackup,
    );
  });

  test('failed unpack leaves no staging dir', () async {
    handZip({
      'manifest.json': enc(manifestJson([])),
      'extra.json': utf8.encode('{}'),
    });
    final into = Directory('${tmp.path}/leftover');
    await _failureOf(() => archive.unpack(zip, into));
    expect(into.existsSync(), isFalse);
  });
}
