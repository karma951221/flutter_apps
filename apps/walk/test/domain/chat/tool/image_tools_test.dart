import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/tool/image_tools.dart';
import 'package:walk/domain/chat/tool/tool_summary.dart';
import 'package:walk/domain/chat/workspace/workspace.dart';
import 'package:walk/domain/chat/workspace/workspace_changes.dart';

class _FakeGenerator implements ImageGenerator {
  Object? error;
  final calls = <(String, String, ImageShape)>[];

  @override
  Future<GeneratedImage> generate({
    required String apiKey,
    required String prompt,
    required ImageShape shape,
  }) async {
    calls.add((apiKey, prompt, shape));
    final e = error;
    if (e != null) throw e;
    return (
      png: Uint8List.fromList([1, 2, 3]),
      model: 'gpt-image-2',
      usage: const TokenUsage(inputTokens: 5, outputTokens: 50),
    );
  }
}

class _FakeWorkspace implements Workspace {
  final saved = <String, Uint8List>{};
  bool fail = false;

  @override
  Future<String> writeOutBytes(String fileName, Uint8List bytes) async {
    if (fail) throw const FileSystemExceptionLike();
    saved['out/$fileName'] = bytes;
    return 'out/$fileName';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FileSystemExceptionLike implements Exception {
  const FileSystemExceptionLike();
}

class _FixedClock extends Clock {
  @override
  DateTime now() => DateTime(2026, 11, 21, 9, 5, 7);
}

void main() {
  late _FakeGenerator generator;
  late _FakeWorkspace workspace;
  late WorkspaceChanges changes;
  late ImageTools tools;

  setUp(() {
    generator = _FakeGenerator();
    workspace = _FakeWorkspace();
    changes = WorkspaceChanges();
    tools = ImageTools(generator, workspace, _FixedClock(), changes: changes);
  });

  test('spec 은 prompt 필수 · shape 선택', () {
    expect(ImageTools.spec.name, 'generate_image');
    expect(ImageTools.spec.parameters['required'], ['prompt']);
    expect(chatToolKindOf('generate_image'), ChatToolKind.generateImage);
  });

  test('만들면 out/ 에 저장하고 그림 줄 · 사용량을 돌려주며 작업 폴더 변경을 알린다', () async {
    final notified = expectLater(changes.stream, emits(null));

    final outcome = await tools.run({
      'prompt': ' 노을 진 바다 ',
      'shape': 'landscape',
      'alt': '노을 바다',
    }, apiKey: 'sk-x');

    expect(generator.calls.single, ('sk-x', '노을 진 바다', ImageShape.landscape));
    const path = 'out/그림-20261121-090507.png';
    expect(workspace.saved[path], [1, 2, 3]);
    expect(outcome.result.isError, isFalse);
    expect(jsonDecode(outcome.result.json)['path'], path);
    expect(outcome.result.summary?.kind, ChatToolKind.generateImage);
    expect(outcome.markdown, '![노을 바다](${Uri.encodeFull(path)})');
    expect(outcome.model, 'gpt-image-2');
    expect(outcome.usage?.outputTokens, 50);
    await notified;
  });

  test('shape 가 없거나 모르면 square', () async {
    await tools.run({'prompt': 'a', 'shape': 'circle'}, apiKey: 'k');
    expect(generator.calls.single.$3, ImageShape.square);
  });

  test('prompt 가 비거나 너무 길면 생성하지 않고 오류', () async {
    final empty = await tools.run({'prompt': '  '}, apiKey: 'k');
    expect(empty.result.json, '{"error":"invalid_prompt"}');
    final long = await tools.run({
      'prompt': 'a' * (ImageTools.maxPromptChars + 1),
    }, apiKey: 'k');
    expect(long.result.json, '{"error":"prompt_too_long"}');
    expect(generator.calls, isEmpty);
    expect(empty.markdown, isNull);
  });

  test('생성 실패는 실패 코드, 저장 실패는 save_failed', () async {
    generator.error = const ImageGenerationException(ImageFailure.refused);
    final refused = await tools.run({'prompt': 'a'}, apiKey: 'k');
    expect(refused.result.json, '{"error":"refused"}');
    expect(refused.result.isError, isTrue);
    expect(refused.result.summary?.isError, isTrue);

    generator.error = StateError('boom');
    final boom = await tools.run({'prompt': 'a'}, apiKey: 'k');
    expect(boom.result.json, '{"error":"image_failed"}');

    generator.error = null;
    workspace.fail = true;
    final unsaved = await tools.run({'prompt': 'a'}, apiKey: 'k');
    expect(unsaved.result.json, '{"error":"save_failed"}');
    expect(unsaved.markdown, isNull);
  });

  group('altOf', () {
    test('alt 가 없으면 설명 앞부분, 대괄호 · 줄바꿈을 뺀다', () {
      expect(ImageTools.altOf(null, '[빨간]\n사과'), '빨간 사과');
      expect(ImageTools.altOf('  ', '배'), '배');
      expect(
        ImageTools.altOf('가' * 100, 'x').runes.length,
        ImageTools.maxAltChars,
      );
      expect(ImageTools.altOf('[]', ''), '그림');
    });
  });

  test('markdownOf 는 괄호 · 빈칸을 인코딩한다', () {
    expect(
      ImageTools.markdownOf('out/a b(1).png', '그림'),
      '![그림](out/a%20b%281%29.png)',
    );
  });
}
