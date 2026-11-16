import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/backup/area/dir_swap.dart';

void main() {
  late Directory tmp;
  late Directory current;
  late Directory incoming;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('dir_swap_test');
    current = Directory('${tmp.path}/media');
    incoming = Directory('${tmp.path}/staging/media');
    File('${incoming.path}/new.jpg')
      ..createSync(recursive: true)
      ..writeAsStringSync('new');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  void writeCurrent() => File('${current.path}/old.jpg')
    ..createSync(recursive: true)
    ..writeAsStringSync('old');

  test(
    'replaces current with incoming and leaves no .old on success',
    () async {
      writeCurrent();

      await swapDirectory(current, incoming, () async {});

      expect(File('${current.path}/new.jpg').readAsStringSync(), 'new');
      expect(File('${current.path}/old.jpg').existsSync(), isFalse);
      expect(Directory('${current.path}.old').existsSync(), isFalse);
      expect(incoming.existsSync(), isFalse);
    },
  );

  test('commit failure restores original dir', () async {
    writeCurrent();

    await expectLater(
      swapDirectory(current, incoming, () async => throw StateError('db')),
      throwsStateError,
    );

    expect(File('${current.path}/old.jpg').readAsStringSync(), 'old');
    expect(File('${current.path}/new.jpg').existsSync(), isFalse);
    expect(Directory('${current.path}.old').existsSync(), isFalse);
    // 받은 폴더도 제자리로 돌아가 다시 시도할 수 있다.
    expect(File('${incoming.path}/new.jpg').readAsStringSync(), 'new');
  });

  test('missing current dir ok', () async {
    await swapDirectory(current, incoming, () async {});

    expect(File('${current.path}/new.jpg').readAsStringSync(), 'new');
    expect(Directory('${current.path}.old').existsSync(), isFalse);
  });

  test('commit failure with missing current leaves no current dir', () async {
    await expectLater(
      swapDirectory(current, incoming, () async => throw StateError('db')),
      throwsStateError,
    );

    expect(current.existsSync(), isFalse);
    expect(File('${incoming.path}/new.jpg').existsSync(), isTrue);
  });

  test('stale .old from an earlier crash does not block the swap', () async {
    writeCurrent();
    File('${current.path}.old/stale.jpg').createSync(recursive: true);

    await swapDirectory(current, incoming, () async {});

    expect(File('${current.path}/new.jpg').existsSync(), isTrue);
    expect(Directory('${current.path}.old').existsSync(), isFalse);
  });
}
