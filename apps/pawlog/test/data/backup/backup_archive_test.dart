import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/data/backup/backup_archive.dart';

Uint8List _zip(Map<String, List<int>> entries) {
  final archive = Archive();
  for (final MapEntry(:key, :value) in entries.entries) {
    archive.addFile(ArchiveFile.bytes(key, value));
  }
  return ZipEncoder().encodeBytes(archive);
}

void main() {
  const codec = BackupArchive();

  test('pack 한 것을 unpack 하면 json 과 사진 바이트가 그대로다', () {
    final photos = {
      'a.jpg': Uint8List.fromList([1, 2, 3]),
      'b.png': Uint8List.fromList(List.generate(300, (i) => i % 256)),
    };

    final bytes = codec.pack(
      json: '{"format":"pawlog-backup"}',
      photos: photos,
    );
    final result = codec.unpack(bytes);

    final value =
        (result as Ok<({String json, Map<String, Uint8List> photos})>).value;
    expect(value.json, '{"format":"pawlog-backup"}');
    expect(value.photos.keys, unorderedEquals(['a.jpg', 'b.png']));
    expect(value.photos['a.jpg'], photos['a.jpg']);
    expect(value.photos['b.png'], photos['b.png']);
  });

  test('항목 이름은 backup.json 과 photos/<상대 경로> 다', () {
    final bytes = codec.pack(
      json: '{}',
      photos: {
        'a.jpg': Uint8List.fromList([1]),
      },
    );

    final names = ZipDecoder().decodeBytes(bytes).files.map((f) => f.name);
    expect(names, unorderedEquals(['backup.json', 'photos/a.jpg']));
  });

  test('zip 이 아니면 Err', () {
    final result = codec.unpack(Uint8List.fromList(utf8.encode('not a zip')));

    expect(result, isA<Err<Object?>>());
  });

  test('backup.json 이 없으면 Err', () {
    final result = codec.unpack(
      _zip({
        'photos/a.jpg': [1],
      }),
    );

    expect(result, isA<Err<Object?>>());
  });

  for (final name in [
    'photos/../evil',
    'photos/../../x.jpg',
    'photos/sub/../../x.jpg',
    'photos//etc/passwd',
    r'photos/..\..\x.jpg',
  ]) {
    test('사진 경로 $name 은 Err', () {
      final result = codec.unpack(
        _zip({
          'backup.json': utf8.encode('{}'),
          name: [1],
        }),
      );

      expect(result, isA<Err<Object?>>());
    });
  }

  test('photos/ 밖의 다른 항목은 무시한다', () {
    final result = codec.unpack(
      _zip({
        'backup.json': utf8.encode('{}'),
        'readme.txt': [1],
      }),
    );

    final value =
        (result as Ok<({String json, Map<String, Uint8List> photos})>).value;
    expect(value.photos, isEmpty);
  });

  test('잘린 zip 은 던지지 않고 Err', () {
    final bytes = codec.pack(
      json: '{"format":"pawlog-backup"}',
      photos: {'a.jpg': Uint8List.fromList(List.generate(500, (i) => i % 7))},
    );
    final truncated = Uint8List.sublistView(bytes, 0, bytes.length ~/ 2);

    expect(() => codec.unpack(truncated), returnsNormally);
    expect(codec.unpack(truncated), isA<Err<Object?>>());
  });
}
