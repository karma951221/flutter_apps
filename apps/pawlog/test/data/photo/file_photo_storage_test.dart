import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/data/photo/file_photo_storage.dart';

import '../../support/fakes.dart';

void main() {
  late Directory root;
  late FilePhotoStorage storage;

  setUp(() async {
    final temp = await Directory.systemTemp.createTemp('walk_photos_test');
    addTearDown(() => temp.delete(recursive: true));
    // 아직 없는 하위 폴더여야 store 가 폴더를 만드는지 확인된다.
    root = Directory('${temp.path}/photos');
    final ids = MockIdGenerator();
    when(ids.newId).thenReturn('photo-1');
    storage = FilePhotoStorage(root, ids);
  });

  test('상대 경로를 돌려주고 파일을 쓴다', () async {
    final result = await storage.store(
      bytes: Uint8List.fromList([1, 2, 3]),
      extension: 'jpg',
    );

    final path = (result as Ok<String>).value;
    expect(path, 'photo-1.jpg');
    expect(path, isNot(contains('/')));
    expect(storage.resolve(path).readAsBytesSync(), [1, 2, 3]);
  });

  test('resolve 는 root 아래 파일을 가리킨다', () {
    expect(storage.resolve('a.jpg').path, '${root.path}/a.jpg');
  });

  test('remove 는 없는 파일에도 조용하다', () async {
    final path =
        ((await storage.store(bytes: Uint8List(1), extension: 'png'))
                as Ok<String>)
            .value;

    await storage.remove(path);
    await storage.remove(path);

    expect(storage.resolve(path).existsSync(), isFalse);
  });

  group('write', () {
    test('없던 파일을 root 아래 상대 경로로 쓴다', () async {
      final result = await storage.write('b.jpg', Uint8List.fromList([4, 5]));

      expect(result, isA<Ok<void>>());
      expect(storage.resolve('b.jpg').readAsBytesSync(), [4, 5]);
    });

    test('이미 있으면 덮어쓰지 않고 Ok', () async {
      await storage.write('b.jpg', Uint8List.fromList([1]));

      final result = await storage.write('b.jpg', Uint8List.fromList([9, 9]));

      expect(result, isA<Ok<void>>());
      expect(storage.resolve('b.jpg').readAsBytesSync(), [1]);
    });

    for (final path in ['../evil.jpg', 'a/../../evil.jpg', '/abs.jpg', '']) {
      test('"$path" 는 쓰지 않고 Err', () async {
        final result = await storage.write(path, Uint8List.fromList([1]));

        expect(result, isA<Err<void>>());
        expect(File('${root.parent.path}/evil.jpg').existsSync(), isFalse);
      });
    }
  });
}
