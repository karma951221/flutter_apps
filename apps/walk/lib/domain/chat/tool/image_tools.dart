import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

import '../chat_model.dart';
import '../workspace/workspace.dart';
import '../workspace/workspace_changes.dart';
import 'tool_result.dart';
import 'tool_summary.dart';

/// 그림 비율. 크기는 생성기가 정한다(정사각 1024² · 세로 1024×1536 · 가로 1536×1024).
enum ImageShape { square, portrait, landscape }

/// 그림 만들기가 실패한 까닭. 도구 결과의 `error` 코드로 모델에 간다.
enum ImageFailure {
  invalidKey('invalid_key'),
  quotaExceeded('quota_exceeded'),
  rateLimited('rate_limited'),

  /// 벤더 안전 기준에 걸렸다.
  refused('refused'),

  /// 조직 인증 등 권한이 없다(OpenAI 는 gpt-image 에 조직 인증을 요구할 수 있다).
  forbidden('forbidden'),
  modelUnavailable('model_unavailable'),
  network('network'),
  unknown('image_failed');

  const ImageFailure(this.code);

  final String code;
}

class ImageGenerationException implements Exception {
  const ImageGenerationException(this.failure);

  final ImageFailure failure;

  @override
  String toString() => 'ImageGenerationException($failure)';
}

/// 만든 그림 한 장. [model] 은 실제로 쓴 모델, [usage] 는 벤더가 알려 줄 때만.
typedef GeneratedImage = ({Uint8List png, String model, TokenUsage? usage});

/// 그림 생성 API. 실패는 [ImageGenerationException] 으로 던진다.
abstract interface class ImageGenerator {
  Future<GeneratedImage> generate({
    required String apiKey,
    required String prompt,
    required ImageShape shape,
  });
}

/// generate_image 한 번의 결과. [markdown] 은 성공했을 때 답 끝에 붙일 그림 줄,
/// [model] · [usage] 는 사용량 기록용(성공했을 때만).
typedef ImageToolOutcome = ({
  ToolResult result,
  String? markdown,
  String? model,
  TokenUsage? usage,
});

/// 모델이 그림(사진풍 · 일러스트)을 만드는 도구 하나(generate_image). OpenAI 연결이고
/// 그림 만들기 스위치가 켜졌을 때만 세션이 싣는다. 결과 PNG 는 작업 폴더 out/ 에 저장하고,
/// 세션이 [ImageToolOutcome.markdown] 을 답 글에 붙여 말풍선이 그림으로 보인다.
/// [run] 은 던지지 않는다 — 실패는 `{"error": 코드}` 결과.
@lazySingleton
class ImageTools {
  ImageTools(
    this._generator,
    this._workspace,
    this._clock, {
    WorkspaceChanges? changes,
  }) : _changes = changes;

  final ImageGenerator _generator;
  final Workspace _workspace;
  final Clock _clock;
  final WorkspaceChanges? _changes;

  static const generateImageName = 'generate_image';

  /// 그림 설명(prompt) 최대 글자(코드 포인트) 수.
  static const maxPromptChars = 4000;

  /// 그림 대체 글(alt) 최대 글자 수.
  static const maxAltChars = 40;

  static const spec = ToolSpec(
    name: generateImageName,
    description:
        '설명대로 그림(사진풍 · 일러스트 · 아이콘 등) 한 장을 새로 만든다. 비용이 드니 사용자가 '
        '그림을 만들어 달라고 할 때만 쓴다. 도식 · 차트는 이 도구 대신 svg 코드 블록으로 그린다. '
        '만든 그림은 답에 자동으로 붙는다.',
    parameters: {
      'type': 'object',
      'properties': {
        'prompt': {
          'type': 'string',
          'description': '그릴 장면을 구체적으로(대상 · 구도 · 화풍 · 색). 최대 4000자',
        },
        'shape': {
          'type': 'string',
          'enum': ['square', 'portrait', 'landscape'],
          'description': '비율. 생략하면 square',
        },
        'alt': {
          'type': 'string',
          'description': '그림을 한국어로 짧게(40자 이내) 설명한 대체 글',
        },
      },
      'required': ['prompt'],
    },
  );

  static const _hint =
      '그림은 답에 자동으로 붙었다. 경로나 그림 마크다운을 다시 쓰지 말고, 무엇을 그렸는지 '
      '짧게만 말한다.';

  Future<ImageToolOutcome> run(
    Map<String, Object?> input, {
    required String apiKey,
  }) async {
    final prompt = switch (input['prompt']) {
      final String p when p.trim().isNotEmpty => p.trim(),
      _ => null,
    };
    if (prompt == null) return _failed('invalid_prompt');
    if (prompt.runes.length > maxPromptChars) return _failed('prompt_too_long');
    final shape =
        ImageShape.values.asNameMap()[input['shape']] ?? ImageShape.square;
    final GeneratedImage image;
    try {
      image = await _generator.generate(
        apiKey: apiKey,
        prompt: prompt,
        shape: shape,
      );
    } on ImageGenerationException catch (e) {
      return _failed(e.failure.code);
    } catch (_) {
      return _failed(ImageFailure.unknown.code);
    }
    final String path;
    try {
      path = await _workspace.writeOutBytes(fileName(_clock.now()), image.png);
    } catch (_) {
      return _failed('save_failed');
    }
    _changes?.notify();
    return (
      result: ToolResult(
        json: jsonEncode({'path': path, 'hint': _hint}),
        summary: const ToolSummary(kind: ChatToolKind.generateImage, count: 1),
      ),
      markdown: markdownOf(path, altOf(input['alt'], prompt)),
      model: image.model,
      usage: image.usage,
    );
  }

  /// `그림-YYYYMMDD-HHmmss.png` — 빈칸이 없어 마크다운 링크에 그대로 쓴다.
  static String fileName(DateTime at) =>
      '그림-${DateFormat('yyyyMMdd-HHmmss').format(at)}.png';

  /// 답에 붙일 그림 한 줄. 경로의 빈칸 · 괄호는 퍼센트 인코딩한다.
  static String markdownOf(String path, String alt) =>
      '![$alt](${Uri.encodeFull(path).replaceAll('(', '%28').replaceAll(')', '%29')})';

  /// alt 가 없으면 설명 앞부분. 줄바꿈 · 대괄호 · 백슬래시를 빼고 [maxAltChars] 까지.
  static String altOf(Object? alt, String prompt) {
    final raw = alt is String && alt.trim().isNotEmpty ? alt : prompt;
    final cleaned = raw
        .replaceAll(RegExp(r'[\[\]\\]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final runes = cleaned.runes;
    final short = runes.length <= maxAltChars
        ? cleaned
        : String.fromCharCodes(runes.take(maxAltChars)).trim();
    return short.isEmpty ? '그림' : short;
  }

  static ImageToolOutcome _failed(String code) => (
    result: ToolResult(
      json: '{"error":"$code"}',
      isError: true,
      summary: const ToolSummary(
        kind: ChatToolKind.generateImage,
        count: 0,
        isError: true,
      ),
    ),
    markdown: null,
    model: null,
    usage: null,
  );
}
