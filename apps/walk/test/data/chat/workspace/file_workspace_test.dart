import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:walk/data/chat/workspace/file_workspace.dart';
import 'package:walk/domain/chat/workspace/workspace.dart';

import '../../../support/diary_fixtures.dart' show MutableClock;

void main() {
  late Directory tmp;
  late Directory rootDir;
  late MutableClock clock;
  late FileWorkspace ws;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('ws_test');
    rootDir = Directory(p.join(tmp.path, 'workspace'));
    clock = MutableClock(DateTime(2026, 11, 13, 14, 5, 9));
    ws = FileWorkspace(() async => rootDir, clock);
  });

  tearDown(() => tmp.delete(recursive: true));

  Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

  group('importToInbox', () {
    test('시각 접두사를 붙이고 겹치면 -2', () async {
      expect(
        await ws.importToInbox('보고서.pdf', bytes('a')),
        'inbox/20261113-140509-보고서.pdf',
      );
      expect(
        await ws.importToInbox('보고서.pdf', bytes('b')),
        'inbox/20261113-140509-보고서-2.pdf',
      );
    });

    test('이름의 금지 문자를 _ 로', () async {
      final path = await ws.importToInbox('a/b:c.txt', bytes('x'));
      expect(path, endsWith('-a_b_c.txt'));
    });

    test('긴 이름은 시각 접두사 포함 200바이트(UTF-8) 안으로 자르고 확장자는 남긴다', () async {
      final path = await ws.importToInbox('${'가' * 150}.pdf', bytes('x'));
      final base = p.basename(path);

      expect(utf8.encode(base).length, lessThanOrEqualTo(200));
      expect(base, startsWith('20261113-140509-가가'));
      expect(base, endsWith('가.pdf'));
      expect(await ws.readBytes(path), bytes('x'));
    });

    test('sanitizeName 은 짧은 이름을 그대로 두고, 긴 확장자는 이름째 자른다', () {
      expect(FileWorkspace.sanitizeName('보고서.pdf'), '보고서.pdf');
      final long = FileWorkspace.sanitizeName('a.${'b' * 300}');
      expect(utf8.encode(long).length, FileWorkspace.maxNameBytes);
      final emoji = FileWorkspace.sanitizeName('${'😀' * 100}.md');
      expect(utf8.encode(emoji).length, lessThanOrEqualTo(184));
      expect(emoji, endsWith('😀.md'));
    });

    test('빈 이름은 file', () async {
      final path = await ws.importToInbox(' .. ', bytes('x'));
      expect(path, endsWith('-file'));
    });
  });

  group('writeOut', () {
    test('out 에 UTF-8 로 쓰고 겹치면 -2', () async {
      expect(await ws.writeOut('a.md', '내용'), 'out/a.md');
      expect(await ws.writeOut('a.md', '내용2'), 'out/a-2.md');
      expect(utf8.decode((await ws.readBytes('out/a.md'))!), '내용');
    });
  });

  group('writeText', () {
    Future<List<String>> outNames() async => Directory(
      p.join(rootDir.path, 'out'),
    ).listSync().map((e) => p.basename(e.path)).toList();

    test('정확히 그 경로에 UTF-8 로 새로 쓰고, 임시 파일이 남지 않는다', () async {
      await ws.writeText('out/표.csv', '날짜,금액\n', overwrite: false);
      expect(utf8.decode((await ws.readBytes('out/표.csv'))!), '날짜,금액\n');
      expect(await outNames(), ['표.csv']);
      expect((await ws.list(WorkspaceArea.out)).map((f) => f.path), [
        'out/표.csv',
      ]);
    });

    test('overwrite 면 덮어쓴다', () async {
      await ws.writeText('out/a.md', '처음', overwrite: false);
      await ws.writeText('out/a.md', '나중', overwrite: true);
      expect(utf8.decode((await ws.readBytes('out/a.md'))!), '나중');
      expect(await outNames(), ['a.md']);
    });

    test(
      'overwrite:false 인데 있으면 WorkspaceFileExistsException, 내용 그대로',
      () async {
        await ws.writeText('out/a.md', '처음', overwrite: false);
        await expectLater(
          ws.writeText('out/a.md', '나중', overwrite: false),
          throwsA(
            isA<WorkspaceFileExistsException>().having(
              (e) => e.path,
              'path',
              'out/a.md',
            ),
          ),
        );
        expect(utf8.decode((await ws.readBytes('out/a.md'))!), '처음');
        expect(await outNames(), ['a.md']);
      },
    );

    test('.. · 절대 경로는 WorkspacePathException', () async {
      for (final path in ['../x.md', 'out/../../x.md', '/tmp/x.md']) {
        await expectLater(
          ws.writeText(path, 'x', overwrite: true),
          throwsA(isA<WorkspacePathException>()),
          reason: path,
        );
      }
      expect(File(p.join(tmp.path, 'x.md')).existsSync(), isFalse);
    });

    test('밖을 가리키는 파일 링크 · 폴더 링크로는 쓰지 않는다', () async {
      final secret = File(p.join(tmp.path, 'secret.txt'))
        ..writeAsStringSync('비밀');
      final elsewhere = Directory(p.join(tmp.path, 'elsewhere'))..createSync();
      await Directory(p.join(rootDir.path, 'out')).create(recursive: true);
      Link(p.join(rootDir.path, 'out', 'link.md')).createSync(secret.path);
      Link(p.join(rootDir.path, 'out', 'dir')).createSync(elsewhere.path);

      await expectLater(
        ws.writeText('out/link.md', 'x', overwrite: true),
        throwsA(isA<WorkspacePathException>()),
      );
      await expectLater(
        ws.writeText('out/dir/x.md', 'x', overwrite: true),
        throwsA(isA<WorkspacePathException>()),
      );
      expect(secret.readAsStringSync(), '비밀');
      expect(elsewhere.listSync(), isEmpty);
    });

    test('out 이 밖을 가리키는 링크면 예외', () async {
      final elsewhere = Directory(p.join(tmp.path, 'elsewhere'))..createSync();
      await rootDir.create(recursive: true);
      Link(p.join(rootDir.path, 'out')).createSync(elsewhere.path);
      await expectLater(
        ws.writeText('out/a.md', 'x', overwrite: false),
        throwsA(isA<WorkspacePathException>()),
      );
      expect(elsewhere.listSync(), isEmpty);
    });

    test('쓰기에 실패하면(폴더 자리) 임시 파일을 지우고 던진다', () async {
      await Directory(
        p.join(rootDir.path, 'out', 'a.md'),
      ).create(recursive: true);
      await expectLater(
        ws.writeText('out/a.md', 'x', overwrite: true),
        throwsA(isA<FileSystemException>()),
      );
      expect(await outNames(), ['a.md']);
    });
  });

  group('list', () {
    test('최신순 · 크기 · 구역 분리 · 숨김 제외', () async {
      final first = await ws.importToInbox('one.txt', bytes('12345'));
      clock.advance(const Duration(seconds: 5));
      final second = await ws.importToInbox('two.txt', bytes('1'));
      await ws.writeOut('o.md', 'x');
      File(p.join(rootDir.path, 'inbox', '.hidden')).writeAsStringSync('h');
      // 수정 시각이 같은 초에 몰리지 않게 명시한다.
      File(
        p.join(rootDir.path, first),
      ).setLastModifiedSync(DateTime(2026, 1, 1));
      File(
        p.join(rootDir.path, second),
      ).setLastModifiedSync(DateTime(2026, 1, 2));

      final inbox = await ws.list(WorkspaceArea.inbox);
      expect(inbox.map((f) => f.path), [second, first]);
      expect(inbox.last.sizeBytes, 5);
      expect(inbox.every((f) => f.area == WorkspaceArea.inbox), isTrue);
      expect((await ws.list(WorkspaceArea.out)).single.path, 'out/o.md');
    });

    test('폴더가 없으면 빈 목록', () async {
      expect(await ws.list(WorkspaceArea.out), isEmpty);
    });

    test('inbox 가 밖을 가리키는 링크면 목록도 예외(쓰기와 같은 판정)', () async {
      final elsewhere = Directory(p.join(tmp.path, 'elsewhere'))..createSync();
      File(p.join(elsewhere.path, 'secret.txt')).writeAsStringSync('비밀');
      await rootDir.create(recursive: true);
      Link(p.join(rootDir.path, 'inbox')).createSync(elsewhere.path);

      await expectLater(
        ws.list(WorkspaceArea.inbox),
        throwsA(isA<WorkspacePathException>()),
      );
    });
  });

  group('readBytes · exists · delete', () {
    test('delete 뒤 exists false, 없는 파일은 null', () async {
      final path = await ws.writeOut('a.md', 'x');
      expect(await ws.exists(path), isTrue);
      expect(await ws.delete(path), isTrue);
      expect(await ws.exists(path), isFalse);
      expect(await ws.readBytes(path), isNull);
      expect(await ws.delete(path), isFalse);
    });
  });

  group('경계', () {
    test('.. · 절대 경로 · absolutePath 는 예외', () async {
      await expectLater(
        ws.readBytes('../x'),
        throwsA(isA<WorkspacePathException>()),
      );
      await expectLater(
        ws.readBytes('/etc/hosts'),
        throwsA(isA<WorkspacePathException>()),
      );
      await expectLater(
        ws.delete('inbox/../../x'),
        throwsA(isA<WorkspacePathException>()),
      );
      await expectLater(
        ws.absolutePath('out/../../x'),
        throwsA(isA<WorkspacePathException>()),
      );
    });

    test('처음 부르는 absolutePath 도 root 안 절대 경로', () async {
      final abs = await ws.absolutePath('out/a.md');
      expect(p.isWithin(await rootDir.resolveSymbolicLinks(), abs), isTrue);
      await expectLater(
        ws.absolutePath('../x'),
        throwsA(isA<WorkspacePathException>()),
      );
    });

    test('밖을 가리키는 심볼릭 링크의 absolutePath 는 예외', () async {
      final outside = File(p.join(tmp.path, 'secret.txt'))
        ..writeAsStringSync('비밀');
      await Directory(p.join(rootDir.path, 'inbox')).create(recursive: true);
      Link(p.join(rootDir.path, 'inbox', 'link')).createSync(outside.path);
      await expectLater(
        ws.absolutePath('inbox/link'),
        throwsA(isA<WorkspacePathException>()),
      );
    });

    test('inbox 가 밖을 가리키는 링크면 쓰기를 거부한다', () async {
      final elsewhere = Directory(p.join(tmp.path, 'elsewhere'))..createSync();
      await rootDir.create(recursive: true);
      Link(p.join(rootDir.path, 'inbox')).createSync(elsewhere.path);
      await expectLater(
        ws.importToInbox('a.txt', bytes('x')),
        throwsA(isA<WorkspacePathException>()),
      );
      expect(elsewhere.listSync(), isEmpty);
    });

    test('밖을 가리키는 심볼릭 링크는 예외', () async {
      final outside = File(p.join(tmp.path, 'secret.txt'))
        ..writeAsStringSync('비밀');
      await ws.writeOut('seed.md', 'x'); // root · out 생성
      await Directory(p.join(rootDir.path, 'inbox')).create();
      Link(p.join(rootDir.path, 'inbox', 'link')).createSync(outside.path);

      await expectLater(
        ws.readBytes('inbox/link'),
        throwsA(isA<WorkspacePathException>()),
      );
    });

    test('밖을 가리키는 폴더 링크 아래는 파일이 있든 없든 예외(존재 여부를 흘리지 않는다)', () async {
      final elsewhere = Directory(p.join(tmp.path, 'elsewhere'))..createSync();
      File(p.join(elsewhere.path, 'secret.txt')).writeAsStringSync('비밀');
      await Directory(p.join(rootDir.path, 'inbox')).create(recursive: true);
      Link(p.join(rootDir.path, 'inbox', 'dir')).createSync(elsewhere.path);

      for (final path in [
        'inbox/dir/secret.txt',
        'inbox/dir/missing.txt',
        'inbox/dir/sub/missing.txt',
      ]) {
        await expectLater(
          ws.absolutePath(path),
          throwsA(isA<WorkspacePathException>()),
          reason: path,
        );
        await expectLater(
          ws.exists(path),
          throwsA(isA<WorkspacePathException>()),
          reason: path,
        );
      }
    });

    test('안쪽의 없는 파일 · 없는 폴더 아래는 예외 없이 없음', () async {
      await ws.writeOut('seed.md', 'x');
      expect(await ws.exists('out/missing.md'), isFalse);
      expect(await ws.exists('inbox/sub/missing.md'), isFalse);
    });
  });
}
