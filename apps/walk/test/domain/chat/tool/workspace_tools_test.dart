import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/chat/workspace/file_workspace.dart';
import 'package:walk/domain/chat/attachment/attachment_loader.dart';
import 'package:walk/domain/chat/attachment/attachment_rules.dart';
import 'package:walk/domain/chat/attachment/chat_attachment.dart';
import 'package:walk/domain/chat/tool/tool_summary.dart';
import 'package:walk/domain/chat/tool/workspace_tools.dart';

import '../../../presentation/chat/workspace/workspace_fakes.dart';

/// 파일 이름 확장자로 첨부를 만든다. 던지게 · 거절하게 설정할 수 있다.
class _Loader implements AttachmentLoader {
  AttachmentRejection? reject;
  bool throws = false;
  final Map<String, String> texts = {};
  final loaded = <String>[];

  @override
  Future<AttachmentLoad> load(PickedFile file) async {
    loaded.add(file.path);
    if (throws) throw StateError('io');
    if (reject case final why?) return AttachmentLoad.rejected(file.name, why);
    return AttachmentLoad.ok(switch (AttachmentRules.kindOf(file.name)!) {
      AttachmentKind.image => ChatAttachment.image(
        name: file.name,
        mediaType: 'image/jpeg',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
      AttachmentKind.pdf => ChatAttachment.pdf(
        name: file.name,
        bytes: Uint8List.fromList([4, 5]),
      ),
      AttachmentKind.text => ChatAttachment.text(
        name: file.name,
        text: texts[file.path] ?? '',
      ),
    });
  }

  @override
  Future<Uint8List> readOriginal(String path) => throw UnimplementedError();
}

Map<String, dynamic> _json(String s) => jsonDecode(s) as Map<String, dynamic>;

void main() {
  late MemoryWorkspace ws;
  late _Loader loader;
  late WorkspaceTools tools;

  setUp(() {
    ws = MemoryWorkspace();
    loader = _Loader();
    tools = WorkspaceTools(ws, loader);
  });

  Uint8List b(String s) => Uint8List.fromList(utf8.encode(s));

  test('definitions 는 list_files · read_file 두 개', () {
    expect(tools.definitions.map((d) => d.name), ['list_files', 'read_file']);
  });

  group('list_files', () {
    test('inbox · out 을 섞어 최신순으로, 필드와 kind · modified 형식', () async {
      ws.add(
        workspaceFile(
          'inbox/a.png',
          sizeBytes: 5,
          modifiedAt: DateTime(2026, 11, 10, 9, 3),
        ),
        b('x'),
      );
      ws.add(
        workspaceFile('out/b.md', modifiedAt: DateTime(2026, 11, 12, 8, 0)),
        b('x'),
      );
      ws.add(
        workspaceFile('inbox/c.pdf', modifiedAt: DateTime(2026, 11, 11)),
        b('x'),
      );
      ws.add(
        workspaceFile('inbox/d.docx', modifiedAt: DateTime(2026, 11, 9)),
        b('x'),
      );
      final r = await tools.run('list_files', {});
      final j = _json(r.json);
      final files = (j['files'] as List).cast<Map<String, dynamic>>();
      expect(files.map((f) => f['path']), [
        'out/b.md',
        'inbox/c.pdf',
        'inbox/a.png',
        'inbox/d.docx',
      ]);
      expect(files[0], {
        'path': 'out/b.md',
        'name': 'b.md',
        'area': 'out',
        'kind': 'text',
        'size': 10,
        'modified': '2026-11-12T08:00',
      });
      expect(files.map((f) => f['kind']), ['text', 'pdf', 'image', 'other']);
      expect(files[2]['modified'], '2026-11-10T09:03');
      expect(j['truncated'], false);
      expect(r.isError, isFalse);
      expect(r.summary!.kind, ChatToolKind.listFiles);
      expect(r.summary!.count, 4);
    });

    test('101개면 100개 + truncated', () async {
      for (var i = 0; i < 101; i++) {
        ws.add(
          workspaceFile(
            'inbox/f$i.txt',
            modifiedAt: DateTime(2026, 1, 1).add(Duration(minutes: i)),
          ),
          b('x'),
        );
      }
      final r = await tools.run('list_files', {'area': 'all'});
      final j = _json(r.json);
      expect((j['files'] as List).length, 100);
      expect(j['truncated'], true);
      expect(r.summary!.count, 100);
    });

    test('area out 만', () async {
      ws.add(workspaceFile('inbox/a.txt'), b('x'));
      ws.add(workspaceFile('out/b.txt'), b('x'));
      final j = _json((await tools.run('list_files', {'area': 'out'})).json);
      expect((j['files'] as List).map((f) => (f as Map)['path']), [
        'out/b.txt',
      ]);
    });

    test('모르는 area 값은 all 로 본다', () async {
      ws.add(workspaceFile('inbox/a.txt'), b('x'));
      ws.add(workspaceFile('out/b.txt'), b('x'));
      for (final area in ['wiki', 3, null]) {
        final r = await tools.run('list_files', {'area': area});
        expect(r.isError, isFalse, reason: '$area');
        final files = _json(r.json)['files'] as List;
        expect(files.map((f) => (f as Map)['path']).toSet(), {
          'inbox/a.txt',
          'out/b.txt',
        }, reason: '$area');
      }
    });

    test('Workspace 가 던져도 던지지 않는다', () async {
      ws.failList = true;
      final r = await tools.run('list_files', {});
      expect(r.isError, isTrue);
      expect(_json(r.json)['error'], isNotEmpty);
      expect(r.summary!.isError, isTrue);
    });
  });

  group('read_file 글', () {
    test('25,000자: 20,000자 + next_offset, 이어 읽으면 나머지', () async {
      ws.add(workspaceFile('inbox/n.md'), b('x'));
      loader.texts['/ws/inbox/n.md'] = 'a' * 25000;
      var j = _json(
        (await tools.run('read_file', {'path': 'inbox/n.md'})).json,
      );
      expect((j['text'] as String).length, 20000);
      expect(j['next_offset'], 20000);
      expect(j['total_chars'], 25000);
      expect(j['offset'], 0);
      expect(j['path'], 'inbox/n.md');
      expect(j['name'], 'n.md');

      final r = await tools.run('read_file', {
        'path': 'inbox/n.md',
        'offset': 20000,
      });
      j = _json(r.json);
      expect((j['text'] as String).length, 5000);
      expect(j['next_offset'], isNull);
      expect(j['offset'], 20000);
      expect(r.summary!.kind, ChatToolKind.readFile);
      expect(r.summary!.count, 1);
    });

    test('서로게이트 쌍이 경계에 걸려도 깨지지 않는다', () async {
      ws.add(workspaceFile('inbox/e.txt'), b('x'));
      // 이모지(코드 유닛 2, 코드 포인트 1) 20,001개.
      loader.texts['/ws/inbox/e.txt'] = '😀' * 20001;
      final first = _json(
        (await tools.run('read_file', {'path': 'inbox/e.txt'})).json,
      );
      expect((first['text'] as String).runes.length, 20000);
      expect(first['total_chars'], 20001);
      expect(first['next_offset'], 20000);
      final rest = _json(
        (await tools.run('read_file', {
          'path': 'inbox/e.txt',
          'offset': 20000,
        })).json,
      );
      expect(rest['text'], '😀');
    });

    test('offset 이 범위 밖이면 빈 text · next_offset null', () async {
      ws.add(workspaceFile('inbox/n.txt'), b('x'));
      loader.texts['/ws/inbox/n.txt'] = 'abc';
      final r = await tools.run('read_file', {
        'path': 'inbox/n.txt',
        'offset': 99,
      });
      final j = _json(r.json);
      expect(r.isError, isFalse);
      expect(j['text'], '');
      expect(j['next_offset'], isNull);
    });

    test('offset 이 정수가 아니면 0', () async {
      ws.add(workspaceFile('inbox/n.txt'), b('x'));
      loader.texts['/ws/inbox/n.txt'] = 'abc';
      final j = _json(
        (await tools.run('read_file', {
          'path': 'inbox/n.txt',
          'offset': 'zz',
        })).json,
      );
      expect(j['offset'], 0);
      expect(j['text'], 'abc');
    });

    test('json 파일도 글', () async {
      ws.add(workspaceFile('out/a.json'), b('x'));
      loader.texts['/ws/out/a.json'] = '{}';
      final j = _json(
        (await tools.run('read_file', {'path': 'out/a.json'})).json,
      );
      expect(j['text'], '{}');
    });
  });

  group('read_file 사진 · PDF', () {
    test('사진은 images 한 장', () async {
      ws.add(workspaceFile('inbox/p.PNG'), b('x'));
      final r = await tools.run('read_file', {'path': 'inbox/p.PNG'});
      expect(r.images.length, 1);
      expect(r.images.single.mediaType, 'image/jpeg');
      expect(r.images.single.bytes, [1, 2, 3]);
      expect(r.documents, isEmpty);
      expect(_json(r.json), {
        'path': 'inbox/p.PNG',
        'name': 'p.PNG',
        'kind': 'image',
      });
      expect(r.summary!.kind, ChatToolKind.readFile);
    });

    test('PDF 는 documents 한 개', () async {
      ws.add(workspaceFile('inbox/d.pdf'), b('x'));
      final r = await tools.run('read_file', {'path': 'inbox/d.pdf'});
      expect(r.documents.length, 1);
      expect(r.documents.single.name, 'd.pdf');
      expect(r.documents.single.bytes, [4, 5]);
      expect(r.images, isEmpty);
      expect(_json(r.json)['kind'], 'pdf');
    });
  });

  group('read_file 오류', () {
    Future<void> expectError(Map<String, Object?> input, String code) async {
      final r = await tools.run('read_file', input);
      expect(r.isError, isTrue, reason: r.json);
      expect(_json(r.json), {'error': code});
      expect(r.summary!.isError, isTrue);
      expect(r.summary!.kind, ChatToolKind.readFile);
      expect(r.images, isEmpty);
      expect(r.documents, isEmpty);
    }

    test('없는 파일은 not_found', () async {
      await expectError({'path': 'inbox/none.txt'}, 'not_found');
    });

    test('path 없음 · 문자열 아님 · 빈 문자열은 invalid_path', () async {
      await expectError({}, 'invalid_path');
      await expectError({'path': 3}, 'invalid_path');
      await expectError({'path': '  '}, 'invalid_path');
    });

    test('inbox/ · out/ 아래의 숨김 아닌 경로만 — 나머지는 invalid_path', () async {
      ws.add(workspaceFile('inbox/.x.md'), b('x'));
      ws.add(workspaceFile('x.md'), b('x'));
      ws.add(workspaceFile('out/.hidden/a.md'), b('x'));
      ws.add(workspaceFile('out/a.md'), b('ok'));
      await expectError({'path': 'inbox/.x.md'}, 'invalid_path');
      await expectError({'path': 'x.md'}, 'invalid_path');
      await expectError({'path': 'out/.hidden/a.md'}, 'invalid_path');
      await expectError({'path': 'wiki/a.md'}, 'invalid_path');
      // 구역 이름만은 파일이 아니다.
      await expectError({'path': 'inbox'}, 'invalid_path');
      await expectError({'path': 'inbox/'}, 'invalid_path');
      expect(loader.loaded, isEmpty);

      final ok = await tools.run('read_file', {'path': 'out/a.md'});
      expect(ok.isError, isFalse, reason: ok.json);
    });

    test('받지 않는 확장자는 unsupported_type', () async {
      ws.add(workspaceFile('inbox/a.docx'), b('x'));
      await expectError({'path': 'inbox/a.docx'}, 'unsupported_type');
      expect(loader.loaded, isEmpty);
    });

    test('로더 거절을 코드로 옮긴다', () async {
      ws.add(workspaceFile('inbox/a.txt'), b('x'));
      loader.reject = AttachmentRejection.notUtf8;
      await expectError({'path': 'inbox/a.txt'}, 'not_text');
      loader.reject = AttachmentRejection.tooLarge;
      await expectError({'path': 'inbox/a.txt'}, 'too_large');
      loader.reject = AttachmentRejection.unsupportedType;
      await expectError({'path': 'inbox/a.txt'}, 'unsupported_type');
    });

    test('로더 · Workspace 가 던져도 던지지 않는다', () async {
      ws.add(workspaceFile('inbox/a.txt'), b('x'));
      loader.throws = true;
      final r = await tools.run('read_file', {'path': 'inbox/a.txt'});
      expect(r.isError, isTrue);
      loader.throws = false;
      ws.failAbsolute = true;
      expect(
        (await tools.run('read_file', {'path': 'inbox/a.txt'})).isError,
        isTrue,
      );
    });

    test('모르는 도구 이름도 던지지 않는다', () async {
      final r = await tools.run('nope', {});
      expect(r.isError, isTrue);
    });
  });

  group('경계 (실제 폴더)', () {
    late Directory tmp;
    late Directory outside;
    late WorkspaceTools real;
    late _Loader realLoader;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('ws_tools_');
      outside = await Directory.systemTemp.createTemp('ws_outside_');
      await File('${outside.path}/secret.txt').writeAsString('SECRET');
      final workspace = FileWorkspace(
        () async => Directory('${tmp.path}/workspace'),
        const Clock(),
      );
      await workspace.writeOut('ok.txt', 'hi');
      await Link(
        '${tmp.path}/workspace/inbox/link.txt',
      ).create('${outside.path}/secret.txt', recursive: true);
      realLoader = _Loader();
      real = WorkspaceTools(workspace, realLoader);
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
      await outside.delete(recursive: true);
    });

    for (final path in ['../x', 'inbox/../../x.txt', '/etc/hosts']) {
      test('$path 는 outside_workspace', () async {
        final r = await real.run('read_file', {'path': path});
        expect(_json(r.json), {'error': 'outside_workspace'});
        expect(r.isError, isTrue);
        expect(r.json, isNot(contains('SECRET')));
        expect(realLoader.loaded, isEmpty);
      });
    }

    test('밖을 가리키는 링크는 outside_workspace · 내용 없음', () async {
      final r = await real.run('read_file', {'path': 'inbox/link.txt'});
      expect(_json(r.json), {'error': 'outside_workspace'});
      expect(r.json, isNot(contains('SECRET')));
      expect(realLoader.loaded, isEmpty);
    });

    test('폴더 경로는 not_found — 로더까지 가지 않는다', () async {
      await Directory(
        '${tmp.path}/workspace/inbox/sub.txt',
      ).create(recursive: true);
      final r = await real.run('read_file', {'path': 'inbox/sub.txt'});
      expect(_json(r.json), {'error': 'not_found'});
      expect(realLoader.loaded, isEmpty);
    });

    test('밖을 가리키는 폴더 링크 아래는 있든 없든 outside_workspace', () async {
      await Link(
        '${tmp.path}/workspace/inbox/dir',
      ).create(outside.path, recursive: true);
      for (final path in ['inbox/dir/secret.txt', 'inbox/dir/missing.txt']) {
        final r = await real.run('read_file', {'path': path});
        expect(_json(r.json), {'error': 'outside_workspace'}, reason: path);
        expect(r.json, isNot(contains('SECRET')));
      }
      expect(realLoader.loaded, isEmpty);
    });

    test('안쪽 파일은 로더까지 간다', () async {
      final r = await real.run('read_file', {'path': 'out/ok.txt'});
      expect(r.isError, isFalse, reason: r.json);
      expect(realLoader.loaded.single, endsWith('out/ok.txt'));
    });
  });
}
