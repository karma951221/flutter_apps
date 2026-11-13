import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:walk/presentation/chat/attachment/chat_file_picker.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';

void main() {
  late Directory tmp;
  late Directory cache;
  late ChatFilePicker picker;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('picker_test');
    cache = Directory(p.join(tmp.path, 'file_picker'))..createSync();
    picker = ChatFilePicker.withCacheRoot(MediaPickGuard(), () async => cache);
  });

  tearDown(() => tmp.delete(recursive: true));

  File cached(String relative) => File(p.join(cache.path, relative))
    ..createSync(recursive: true)
    ..writeAsStringSync('x');

  test('release 는 캐시 사본과 비게 된 uuid 폴더를 지우고 캐시 폴더는 남긴다', () async {
    final file = cached('uuid-1/photos/a.jpg');
    final other = cached('uuid-2/b.pdf');

    await picker.release(file.path);

    expect(file.existsSync(), isFalse);
    expect(Directory(p.join(cache.path, 'uuid-1')).existsSync(), isFalse);
    expect(other.existsSync(), isTrue);
    expect(cache.existsSync(), isTrue);
  });

  test('release 는 캐시 밖 파일 · 캐시 밖을 가리키는 링크의 대상을 지우지 않는다', () async {
    final outside = File(p.join(tmp.path, 'workspace', 'inbox', 'a.pdf'))
      ..createSync(recursive: true)
      ..writeAsStringSync('원본');
    Directory(p.join(cache.path, 'uuid-3')).createSync();
    final link = Link(p.join(cache.path, 'uuid-3', 'link.pdf'))
      ..createSync(outside.path);

    await picker.release(outside.path);
    await picker.release(link.path);
    await picker.release(
      p.join(cache.path, '..', 'workspace', 'inbox', 'a.pdf'),
    );

    expect(outside.existsSync(), isTrue);
  });

  test('없는 파일 · 캐시 폴더가 없을 때도 던지지 않는다', () async {
    await picker.release(p.join(cache.path, 'nope', 'a.pdf'));
    cache.deleteSync(recursive: true);
    await picker.release(p.join(cache.path, 'uuid', 'a.pdf'));
  });
}
