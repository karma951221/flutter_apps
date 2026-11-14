import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/chat/workspace/file_workspace.dart';
import 'package:walk/domain/chat/attachment/attachment_loader.dart';
import 'package:walk/domain/chat/tool/tool_result.dart';
import 'package:walk/domain/chat/tool/tool_summary.dart';
import 'package:walk/domain/chat/tool/workspace_tools.dart';
import 'package:walk/domain/chat/tool/write_plan.dart';

import '../../../presentation/chat/workspace/workspace_fakes.dart';

/// 쓰기 도구는 로더를 쓰지 않는다.
class _NoLoader implements AttachmentLoader {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Map<String, dynamic> _json(String s) => jsonDecode(s) as Map<String, dynamic>;

void main() {
  late MemoryWorkspace ws;
  late WorkspaceTools tools;

  setUp(() {
    ws = MemoryWorkspace();
    tools = WorkspaceTools(ws, _NoLoader());
  });

  Uint8List b(String s) => Uint8List.fromList(utf8.encode(s));
  void put(String path, String text) => ws.add(workspaceFile(path), b(text));
  String read(Map<String, List<int>> snap, String path) =>
      utf8.decode(snap[path]!);

  /// prepareWrite 가 오류 결과이고 디스크가 그대로인지.
  Future<void> expectError(
    String name,
    Map<String, Object?> input,
    String code,
  ) async {
    final before = ws.snapshot;
    final r = await tools.prepareWrite(name, input);
    expect(r, isA<ToolResult>(), reason: '$input');
    final result = r as ToolResult;
    expect(_json(result.json), {'error': code}, reason: '$input');
    expect(result.isError, isTrue);
    expect(result.summary!.isError, isTrue);
    expect(result.summary!.kind, chatToolKindOf(name));
    expect(ws.snapshot, before, reason: '$input');
    expect(ws.written, isEmpty);
    expect(ws.deleted, isEmpty);
  }

  test('writeDefinitions 는 write_file · edit_file · delete_file', () {
    expect(tools.writeDefinitions.map((d) => d.name), [
      'write_file',
      'edit_file',
      'delete_file',
    ]);
    expect(WorkspaceTools.writeNames, {
      'write_file',
      'edit_file',
      'delete_file',
    });
    expect(WorkspaceTools.maxWriteChars, 100000);
    // 읽기 도구 목록은 그대로.
    expect(tools.definitions.map((d) => d.name), ['list_files', 'read_file']);
  });

  test('chatToolKindOf 매핑', () {
    expect(chatToolKindOf('write_file'), ChatToolKind.writeFile);
    expect(chatToolKindOf('edit_file'), ChatToolKind.editFile);
    expect(chatToolKindOf('delete_file'), ChatToolKind.deleteFile);
  });

  group('prepareWrite — 경로 규칙', () {
    for (final path in [
      'out/a/b.md',
      'out/.x.md',
      'out/x.pdf',
      'out/x',
      'out/a:b.md',
      'out/a\u0001b.md',
      'out/${'가' * 118}.md', // 121자
      'out/',
      'out',
      'x.md',
      '',
    ]) {
      test('"$path" 는 invalid_path', () async {
        await expectError('write_file', {
          'path': path,
          'content': 'x',
        }, 'invalid_path');
      });
    }

    test('120자 이름 · 대문자 확장자는 된다', () async {
      final ok = 'out/${'가' * 117}.md';
      expect(
        await tools.prepareWrite('write_file', {'path': ok, 'content': 'x'}),
        isA<WriteCreate>(),
      );
      expect(
        await tools.prepareWrite('write_file', {
          'path': 'out/A.JSON',
          'content': '{}',
        }),
        isA<WriteCreate>(),
      );
      for (final ext in ['md', 'txt', 'csv', 'json']) {
        expect(
          await tools.prepareWrite('write_file', {
            'path': 'out/a.$ext',
            'content': 'x',
          }),
          isA<WriteCreate>(),
          reason: ext,
        );
      }
    });

    test('path 가 문자열이 아니면 invalid_path', () async {
      await expectError('write_file', {
        'path': 3,
        'content': 'x',
      }, 'invalid_path');
      await expectError('delete_file', {}, 'invalid_path');
    });

    test('inbox 는 세 도구 모두 read_only', () async {
      put('inbox/x.md', '원본');
      await expectError('write_file', {
        'path': 'inbox/x.md',
        'content': 'x',
        'overwrite': true,
      }, 'read_only');
      await expectError('edit_file', {
        'path': 'inbox/x.md',
        'old_text': '원',
        'new_text': '새',
      }, 'read_only');
      await expectError('delete_file', {'path': 'inbox/x.md'}, 'read_only');
    });
  });

  group('prepareWrite — write_file', () {
    test('없으면 WriteCreate', () async {
      final plan = await tools.prepareWrite('write_file', {
        'path': 'out/표.csv',
        'content': 'a,b',
      });
      expect(
        plan,
        const WritePlan.create(
          path: 'out/표.csv',
          name: '표.csv',
          content: 'a,b',
        ),
      );
      expect(ws.snapshot, isEmpty);
    });

    test('100,000자는 되고 100,001자는 too_large(코드 포인트)', () async {
      expect(
        await tools.prepareWrite('write_file', {
          'path': 'out/a.txt',
          'content': '😀' * 100000,
        }),
        isA<WriteCreate>(),
      );
      await expectError('write_file', {
        'path': 'out/a.txt',
        'content': 'a' * 100001,
      }, 'too_large');
    });

    test('content 가 문자열이 아니면 invalid_input', () async {
      await expectError('write_file', {'path': 'out/a.md'}, 'invalid_input');
      await expectError('write_file', {
        'path': 'out/a.md',
        'content': 3,
      }, 'invalid_input');
    });

    test('있는데 overwrite 가 true 가 아니면 exists', () async {
      put('out/a.md', '지금');
      await expectError('write_file', {
        'path': 'out/a.md',
        'content': 'x',
      }, 'exists');
      await expectError('write_file', {
        'path': 'out/a.md',
        'content': 'x',
        'overwrite': 'true',
      }, 'exists');
    });

    test('overwrite 면 WriteOverwrite 에 지금 내용', () async {
      put('out/a.md', '지금');
      final before = ws.snapshot;
      final plan = await tools.prepareWrite('write_file', {
        'path': 'out/a.md',
        'content': '새',
        'overwrite': true,
      });
      expect(
        plan,
        const WritePlan.overwrite(
          path: 'out/a.md',
          name: 'a.md',
          content: '새',
          previous: '지금',
        ),
      );
      expect(ws.snapshot, before);
    });

    test('overwrite 인데 지금 파일이 UTF-8 이 아니면 not_text', () async {
      ws.add(workspaceFile('out/a.txt'), Uint8List.fromList([0xff, 0xfe]));
      await expectError('write_file', {
        'path': 'out/a.txt',
        'content': 'x',
        'overwrite': true,
      }, 'not_text');
    });
  });

  group('prepareWrite — edit_file', () {
    test('한 번 나오면 WriteEdit, content 는 바꾼 결과', () async {
      put('out/a.md', '하나 둘 셋');
      final before = ws.snapshot;
      final plan = await tools.prepareWrite('edit_file', {
        'path': 'out/a.md',
        'old_text': '둘',
        'new_text': '두울',
      });
      expect(
        plan,
        const WritePlan.edit(
          path: 'out/a.md',
          name: 'a.md',
          oldText: '둘',
          newText: '두울',
          previous: '하나 둘 셋',
          content: '하나 두울 셋',
        ),
      );
      expect(ws.snapshot, before);
    });

    test('빈 new_text 는 지우기로 된다', () async {
      put('out/a.md', 'ab');
      final plan = await tools.prepareWrite('edit_file', {
        'path': 'out/a.md',
        'old_text': 'a',
        'new_text': '',
      });
      expect((plan as WriteEdit).content, 'b');
    });

    test('0번 no_match · 2번 not_unique(겹쳐 나와도)', () async {
      put('out/a.md', '둘 둘 aaa');
      await expectError('edit_file', {
        'path': 'out/a.md',
        'old_text': '셋',
        'new_text': 'x',
      }, 'no_match');
      await expectError('edit_file', {
        'path': 'out/a.md',
        'old_text': '둘',
        'new_text': 'x',
      }, 'not_unique');
      await expectError('edit_file', {
        'path': 'out/a.md',
        'old_text': 'aa',
        'new_text': 'x',
      }, 'not_unique');
    });

    test('빈 old_text · 문자열 아닌 입력은 invalid_input', () async {
      put('out/a.md', 'ab');
      await expectError('edit_file', {
        'path': 'out/a.md',
        'old_text': '',
        'new_text': 'x',
      }, 'invalid_input');
      await expectError('edit_file', {
        'path': 'out/a.md',
        'old_text': 'a',
      }, 'invalid_input');
      await expectError('edit_file', {
        'path': 'out/a.md',
        'old_text': 1,
        'new_text': 'x',
      }, 'invalid_input');
    });

    test('없는 파일 not_found · UTF-8 아니면 not_text', () async {
      await expectError('edit_file', {
        'path': 'out/none.md',
        'old_text': 'a',
        'new_text': 'b',
      }, 'not_found');
      ws.add(workspaceFile('out/bin.txt'), Uint8List.fromList([0xc3, 0x28]));
      await expectError('edit_file', {
        'path': 'out/bin.txt',
        'old_text': 'a',
        'new_text': 'b',
      }, 'not_text');
    });

    test('고친 결과가 100,000자를 넘으면 too_large', () async {
      put('out/a.md', '${'a' * 99999}X');
      await expectError('edit_file', {
        'path': 'out/a.md',
        'old_text': 'X',
        'new_text': 'YY',
      }, 'too_large');
    });
  });

  group('prepareWrite — delete_file', () {
    test('있으면 WriteDelete(previous · 크기)', () async {
      put('out/a.md', '지울 것');
      final plan = await tools.prepareWrite('delete_file', {
        'path': 'out/a.md',
      });
      expect(
        plan,
        WritePlan.delete(
          path: 'out/a.md',
          name: 'a.md',
          previous: '지울 것',
          sizeBytes: utf8.encode('지울 것').length,
        ),
      );
      expect(ws.deleted, isEmpty);
      expect(ws.snapshot.keys, ['out/a.md']);
    });

    test('없으면 not_found · UTF-8 아니면 not_text', () async {
      await expectError('delete_file', {'path': 'out/none.md'}, 'not_found');
      ws.add(workspaceFile('out/bin.txt'), Uint8List.fromList([0xff]));
      await expectError('delete_file', {'path': 'out/bin.txt'}, 'not_text');
    });
  });

  test('prepareWrite 는 모르는 이름 · Workspace 예외에도 던지지 않는다', () async {
    final unknown = await tools.prepareWrite('nope', {'path': 'out/a.md'});
    expect(unknown, isA<ToolResult>());
    expect((unknown as ToolResult).isError, isTrue);

    put('out/a.md', 'x');
    ws.failAbsolute = true;
    // MemoryWorkspace 의 failAbsolute 는 경계 예외 — outside_workspace.
    await expectError('delete_file', {'path': 'out/a.md'}, 'outside_workspace');
  });

  group('apply', () {
    Future<WritePlan> prepare(String name, Map<String, Object?> input) async =>
        (await tools.prepareWrite(name, input)) as WritePlan;

    test('create 성공 json · 디스크', () async {
      final plan = await prepare('write_file', {
        'path': 'out/표.csv',
        'content': 'a,b😀',
      });
      final r = await tools.apply(plan);
      expect(_json(r.json), {
        'path': 'out/표.csv',
        'name': '표.csv',
        'chars': 4,
        'created': true,
      });
      expect(r.isError, isFalse);
      expect(
        r.summary,
        const ToolSummary(kind: ChatToolKind.writeFile, count: 1),
      );
      expect(read(ws.snapshot, 'out/표.csv'), 'a,b😀');
    });

    test('create 준비 뒤 파일이 생기면 exists, 생긴 파일 그대로', () async {
      final plan = await prepare('write_file', {
        'path': 'out/a.md',
        'content': '새',
      });
      put('out/a.md', '끼어든 것');
      final r = await tools.apply(plan);
      expect(_json(r.json), {'error': 'exists'});
      expect(r.isError, isTrue);
      expect(read(ws.snapshot, 'out/a.md'), '끼어든 것');
    });

    test('overwrite 성공 json(created false)', () async {
      put('out/a.md', '지금');
      final plan = await prepare('write_file', {
        'path': 'out/a.md',
        'content': '새 내용',
        'overwrite': true,
      });
      final r = await tools.apply(plan);
      expect(_json(r.json), {
        'path': 'out/a.md',
        'name': 'a.md',
        'chars': 4,
        'created': false,
      });
      expect(read(ws.snapshot, 'out/a.md'), '새 내용');
    });

    test('edit 성공 json', () async {
      put('out/a.md', '하나 둘');
      final plan = await prepare('edit_file', {
        'path': 'out/a.md',
        'old_text': '둘',
        'new_text': '셋넷',
      });
      final r = await tools.apply(plan);
      expect(_json(r.json), {'path': 'out/a.md', 'name': 'a.md', 'chars': 5});
      expect(
        r.summary,
        const ToolSummary(kind: ChatToolKind.editFile, count: 1),
      );
      expect(read(ws.snapshot, 'out/a.md'), '하나 셋넷');
    });

    test('delete 성공 json', () async {
      put('out/a.md', 'x');
      final plan = await prepare('delete_file', {'path': 'out/a.md'});
      final r = await tools.apply(plan);
      expect(_json(r.json), {
        'path': 'out/a.md',
        'name': 'a.md',
        'deleted': true,
      });
      expect(
        r.summary,
        const ToolSummary(kind: ChatToolKind.deleteFile, count: 1),
      );
      expect(ws.snapshot, isEmpty);
    });

    group('준비 뒤 바뀌면 changed · 디스크 그대로', () {
      for (final (label, name, input) in [
        (
          'overwrite',
          'write_file',
          <String, Object?>{
            'path': 'out/a.md',
            'content': '새',
            'overwrite': true,
          },
        ),
        (
          'edit',
          'edit_file',
          <String, Object?>{
            'path': 'out/a.md',
            'old_text': '처음',
            'new_text': '새',
          },
        ),
        ('delete', 'delete_file', <String, Object?>{'path': 'out/a.md'}),
      ]) {
        test('$label — 내용이 바뀜', () async {
          put('out/a.md', '처음');
          final plan = await prepare(name, input);
          put('out/a.md', '처음 바뀜');
          final r = await tools.apply(plan);
          expect(_json(r.json), {'error': 'changed'});
          expect(r.isError, isTrue);
          expect(r.summary!.kind, chatToolKindOf(name));
          expect(read(ws.snapshot, 'out/a.md'), '처음 바뀜');
          expect(ws.written, isEmpty);
          expect(ws.deleted, isEmpty);
        });

        test('$label — 지워짐', () async {
          put('out/a.md', '처음');
          final plan = await prepare(name, input);
          await ws.delete('out/a.md');
          ws.deleted.clear();
          final r = await tools.apply(plan);
          expect(_json(r.json), {'error': 'changed'});
          expect(ws.snapshot, isEmpty);
          expect(ws.written, isEmpty);
          expect(ws.deleted, isEmpty);
        });
      }
    });

    test('Workspace 가 던져도 apply 는 던지지 않는다(tool_failed)', () async {
      put('out/a.md', 'x');
      final create = await prepare('write_file', {
        'path': 'out/b.md',
        'content': 'y',
      });
      final delete = await prepare('delete_file', {'path': 'out/a.md'});
      ws.failWrite = true;
      ws.failDelete = true;
      final r1 = await tools.apply(create);
      expect(_json(r1.json), {'error': 'tool_failed'});
      expect(r1.isError, isTrue);
      expect(r1.summary!.kind, ChatToolKind.writeFile);
      final r2 = await tools.apply(delete);
      expect(_json(r2.json), {'error': 'tool_failed'});
      expect(r2.summary!.kind, ChatToolKind.deleteFile);
    });
  });

  test('declined 는 user_declined 오류 · declined 표시', () {
    final r = tools.declined('edit_file');
    expect(_json(r.json), {'error': 'user_declined'});
    expect(r.isError, isTrue);
    expect(
      r.summary,
      const ToolSummary(
        kind: ChatToolKind.editFile,
        count: 0,
        isError: true,
        declined: true,
      ),
    );
  });

  test('WritePlan.toString 에 경로 · 내용이 없다', () {
    const plans = [
      WritePlan.create(
        path: 'out/비밀경로.md',
        name: '비밀경로.md',
        content: 'CONTENT',
      ),
      WritePlan.overwrite(
        path: 'out/비밀경로.md',
        name: '비밀경로.md',
        content: 'CONTENT',
        previous: 'PREVIOUS',
      ),
      WritePlan.edit(
        path: 'out/비밀경로.md',
        name: '비밀경로.md',
        oldText: 'OLDTEXT',
        newText: 'NEWTEXT',
        previous: 'PREVIOUS',
        content: 'CONTENT',
      ),
      WritePlan.delete(
        path: 'out/비밀경로.md',
        name: '비밀경로.md',
        previous: 'PREVIOUS',
        sizeBytes: 8,
      ),
    ];
    for (final plan in plans) {
      final s = plan.toString();
      for (final secret in [
        '비밀경로',
        'CONTENT',
        'PREVIOUS',
        'OLDTEXT',
        'NEWTEXT',
      ]) {
        expect(s, isNot(contains(secret)), reason: s);
      }
    }
    expect(plans[0].toString(), 'WritePlan.create(contentChars: 7)');
  });

  group('경계 (실제 폴더)', () {
    late Directory tmp;
    late Directory outside;
    late WorkspaceTools real;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('ws_write_');
      outside = await Directory.systemTemp.createTemp('ws_write_outside_');
      await File('${outside.path}/secret.md').writeAsString('SECRET');
      final workspace = FileWorkspace(
        () async => Directory('${tmp.path}/workspace'),
        const Clock(),
      );
      await workspace.writeOut('ok.md', 'hi');
      await Link(
        '${tmp.path}/workspace/out/link.md',
      ).create('${outside.path}/secret.md');
      real = WorkspaceTools(workspace, _NoLoader());
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
      await outside.delete(recursive: true);
    });

    for (final path in [
      '../x.md',
      'out/../../x.md',
      '/tmp/x.md',
      'out/link.md',
    ]) {
      test('$path 는 outside_workspace · 밖 그대로', () async {
        for (final (name, input) in [
          ('write_file', {'path': path, 'content': 'x', 'overwrite': true}),
          ('edit_file', {'path': path, 'old_text': 'S', 'new_text': 'x'}),
          ('delete_file', {'path': path}),
        ]) {
          final r = await real.prepareWrite(name, input);
          expect(_json((r as ToolResult).json), {
            'error': 'outside_workspace',
          }, reason: name);
          expect(r.json, isNot(contains('SECRET')));
        }
        expect(File('${outside.path}/secret.md').readAsStringSync(), 'SECRET');
      });
    }

    test('실제 폴더에서 create → apply → edit → delete', () async {
      final create =
          await real.prepareWrite('write_file', {
                'path': 'out/new.md',
                'content': 'abc',
              })
              as WritePlan;
      expect(File('${tmp.path}/workspace/out/new.md').existsSync(), isFalse);
      expect((await real.apply(create)).isError, isFalse);
      final edit =
          await real.prepareWrite('edit_file', {
                'path': 'out/new.md',
                'old_text': 'b',
                'new_text': 'B',
              })
              as WritePlan;
      expect((await real.apply(edit)).isError, isFalse);
      expect(
        File('${tmp.path}/workspace/out/new.md').readAsStringSync(),
        'aBc',
      );
      final delete =
          await real.prepareWrite('delete_file', {'path': 'out/new.md'})
              as WritePlan;
      expect((await real.apply(delete)).isError, isFalse);
      expect(File('${tmp.path}/workspace/out/new.md').existsSync(), isFalse);
    });
  });
}
