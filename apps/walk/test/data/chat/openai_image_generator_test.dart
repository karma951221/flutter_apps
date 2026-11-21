import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:walk/data/chat/openai_image_generator.dart';
import 'package:walk/domain/chat/tool/image_tools.dart';

void main() {
  final png = base64Encode([137, 80, 78, 71]);

  String ok() => jsonEncode({
    'data': [
      {'b64_json': png},
    ],
    'usage': {'input_tokens': 12, 'output_tokens': 4160},
  });

  test('요청 모양 — 모델 · 크기 · 품질 · 키 헤더, 응답 PNG · 사용량', () async {
    late http.Request sent;
    final generator = OpenAiImageGenerator(
      MockClient((request) async {
        sent = request;
        return http.Response(ok(), 200);
      }),
    );

    final image = await generator.generate(
      apiKey: 'sk-test',
      prompt: '고양이',
      shape: ImageShape.portrait,
    );

    expect(sent.url, OpenAiImageGenerator.endpoint);
    expect(sent.headers['Authorization'], 'Bearer sk-test');
    final body = jsonDecode(sent.body) as Map<String, Object?>;
    expect(body['model'], OpenAiImageGenerator.models.first);
    expect(body['size'], '1024x1536');
    expect(body['quality'], 'medium');
    expect(body['prompt'], '고양이');
    expect(image.png, [137, 80, 78, 71]);
    expect(image.model, OpenAiImageGenerator.models.first);
    expect(image.usage?.inputTokens, 12);
    expect(image.usage?.outputTokens, 4160);
  });

  test('첫 모델이 없으면(404) 다음 모델로', () async {
    final models = <Object?>[];
    final generator = OpenAiImageGenerator(
      MockClient((request) async {
        final model = (jsonDecode(request.body) as Map)['model'];
        models.add(model);
        if (model == OpenAiImageGenerator.models.first) {
          return http.Response(
            '{"error":{"type":"invalid_request_error","code":"model_not_found"}}',
            404,
          );
        }
        return http.Response(ok(), 200);
      }),
    );

    final image = await generator.generate(
      apiKey: 'k',
      prompt: 'p',
      shape: ImageShape.square,
    );

    expect(models, OpenAiImageGenerator.models);
    expect(image.model, OpenAiImageGenerator.models[1]);
  });

  test('모델 말고 다른 실패는 다음 모델로 넘기지 않는다', () async {
    var calls = 0;
    final generator = OpenAiImageGenerator(
      MockClient((request) async {
        calls++;
        return http.Response('{}', 401);
      }),
    );
    await expectLater(
      generator.generate(apiKey: 'k', prompt: 'p', shape: ImageShape.square),
      throwsA(
        isA<ImageGenerationException>().having(
          (e) => e.failure,
          'failure',
          ImageFailure.invalidKey,
        ),
      ),
    );
    expect(calls, 1);
  });

  test('네트워크 오류는 network', () async {
    final generator = OpenAiImageGenerator(
      MockClient((request) async => throw http.ClientException('down')),
    );
    await expectLater(
      generator.generate(apiKey: 'k', prompt: 'p', shape: ImageShape.square),
      throwsA(
        isA<ImageGenerationException>().having(
          (e) => e.failure,
          'failure',
          ImageFailure.network,
        ),
      ),
    );
  });

  group('failureOf', () {
    test('오류 코드가 상태 코드보다 먼저', () {
      expect(
        OpenAiImageGenerator.failureOf(400, (
          type: 'image_generation_user_error',
          code: 'moderation_blocked',
        )),
        ImageFailure.refused,
      );
      expect(
        OpenAiImageGenerator.failureOf(429, (
          type: null,
          code: 'insufficient_quota',
        )),
        ImageFailure.quotaExceeded,
      );
    });

    test('상태 코드', () {
      const none = (type: null, code: null);
      expect(
        OpenAiImageGenerator.failureOf(401, none),
        ImageFailure.invalidKey,
      );
      expect(OpenAiImageGenerator.failureOf(403, none), ImageFailure.forbidden);
      expect(
        OpenAiImageGenerator.failureOf(404, none),
        ImageFailure.modelUnavailable,
      );
      expect(
        OpenAiImageGenerator.failureOf(429, none),
        ImageFailure.rateLimited,
      );
      expect(OpenAiImageGenerator.failureOf(503, none), ImageFailure.network);
      expect(OpenAiImageGenerator.failureOf(400, none), ImageFailure.unknown);
    });
  });

  test('응답에 그림이 없으면 unknown', () {
    expect(
      () => OpenAiImageGenerator.parse('{"data":[]}', 'm'),
      throwsA(isA<ImageGenerationException>()),
    );
    expect(
      () => OpenAiImageGenerator.parse('not json', 'm'),
      throwsA(isA<ImageGenerationException>()),
    );
  });
}
