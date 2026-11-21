import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../../domain/chat/chat_model.dart';
import '../../domain/chat/tool/image_tools.dart';
import 'vendor_error.dart';

/// OpenAI Images API(`POST /v1/images/generations`)로 PNG 한 장을 만든다.
///
/// [models] 를 차례로 시도한다 — 앞 모델이 없거나(404 · model_not_found) 쓸 수 없으면 다음.
/// 품질은 medium(한 장 수 센트). 키 · 프롬프트 · 응답 본문은 로그에 남기지 않는다.
@LazySingleton(as: ImageGenerator)
class OpenAiImageGenerator implements ImageGenerator {
  OpenAiImageGenerator(this._client);

  final http.Client _client;

  static final endpoint = Uri.parse(
    'https://api.openai.com/v1/images/generations',
  );

  /// 시도 순서. 최신 → 예전(gpt-image-2 는 2026-04 출시).
  static const models = ['gpt-image-2', 'gpt-image-1'];

  static const quality = 'medium';

  /// 그림은 수십 초 걸릴 수 있다.
  static const timeout = Duration(seconds: 150);

  static String sizeOf(ImageShape shape) => switch (shape) {
    ImageShape.square => '1024x1024',
    ImageShape.portrait => '1024x1536',
    ImageShape.landscape => '1536x1024',
  };

  @override
  Future<GeneratedImage> generate({
    required String apiKey,
    required String prompt,
    required ImageShape shape,
  }) async {
    ImageGenerationException? last;
    for (final model in models) {
      try {
        return await _generate(apiKey, model, prompt, shape);
      } on ImageGenerationException catch (e) {
        if (e.failure != ImageFailure.modelUnavailable) rethrow;
        last = e;
      }
    }
    throw last ?? const ImageGenerationException(ImageFailure.unknown);
  }

  Future<GeneratedImage> _generate(
    String apiKey,
    String model,
    String prompt,
    ImageShape shape,
  ) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            endpoint,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'prompt': prompt,
              'size': sizeOf(shape),
              'quality': quality,
              'n': 1,
            }),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const ImageGenerationException(ImageFailure.network);
    } on http.ClientException {
      throw const ImageGenerationException(ImageFailure.network);
    }
    if (response.statusCode != 200) {
      throw ImageGenerationException(
        failureOf(response.statusCode, _errorOf(response.body)),
      );
    }
    return parse(response.body, model);
  }

  static VendorError _errorOf(String body) {
    try {
      return vendorErrorOf(jsonDecode(body));
    } on FormatException {
      return (type: null, code: null);
    }
  }

  /// 상태 코드 · 오류 코드 → 실패 종류.
  static ImageFailure failureOf(int status, VendorError error) {
    final code = error.code ?? '';
    final type = error.type ?? '';
    if (code == 'moderation_blocked' || code == 'content_policy_violation') {
      return ImageFailure.refused;
    }
    if (code == 'model_not_found') return ImageFailure.modelUnavailable;
    if (code == 'insufficient_quota' || code == 'billing_hard_limit_reached') {
      return ImageFailure.quotaExceeded;
    }
    return switch (status) {
      401 => ImageFailure.invalidKey,
      403 => ImageFailure.forbidden,
      404 => ImageFailure.modelUnavailable,
      429 => ImageFailure.rateLimited,
      400 when type.contains('user_error') => ImageFailure.refused,
      >= 500 => ImageFailure.network,
      _ => ImageFailure.unknown,
    };
  }

  /// 응답 `{data: [{b64_json}], usage: {input_tokens, output_tokens}}` → 그림.
  static GeneratedImage parse(String body, String model) {
    try {
      final json = jsonDecode(body);
      if (json case {'data': [{'b64_json': final String b64}, ...]}) {
        final Uint8List png = base64Decode(b64);
        TokenUsage? usage;
        if (json case {
          'usage': {
            'input_tokens': final int input,
            'output_tokens': final int output,
          },
        }) {
          usage = TokenUsage(inputTokens: input, outputTokens: output);
        }
        return (png: png, model: model, usage: usage);
      }
    } on FormatException {
      // 아래에서 unknown.
    }
    throw const ImageGenerationException(ImageFailure.unknown);
  }
}
