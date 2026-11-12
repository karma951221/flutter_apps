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
      expect(
        () => ws.absolutePath('out/../../x'),
        throwsA(isA<WorkspacePathException>()),
      );
    });

    test('열린 뒤 absolutePath 는 root 안 절대 경로', () async {
      final path = await ws.writeOut('a.md', 'x');
      final abs = ws.absolutePath(path);
      expect(File(abs).existsSync(), isTrue);
      expect(
        () => ws.absolutePath('../x'),
        throwsA(isA<WorkspacePathException>()),
      );
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
  });
}
