import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_model_rules.dart';
import 'package:walk/domain/chat/chat_vendor.dart';

ModelInfo _m(String id, {int? created, bool? tools, bool? images}) => ModelInfo(
  id: id,
  displayName: id,
  createdAt: created == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(created * 1000, isUtc: true),
  supportsTools: tools,
  supportsImages: images,
);

List<String> _ids(List<ModelInfo> models) => [for (final m in models) m.id];

void main() {
  group('chatModelsOf', () {
    test('anthropic 목록은 claude- 전부 남기고 최신순', () {
      final result = chatModelsOf(ChatVendor.anthropic, [
        _m('claude-haiku-9-1', created: 2),
        _m('claude-opus-9-9', created: 3),
        _m('claude-sonnet-9-8', created: 1),
        _m('not-claude-9', created: 4),
      ]);

      expect(_ids(result), [
        'claude-opus-9-9',
        'claude-haiku-9-1',
        'claude-sonnet-9-8',
      ]);
    });

    test('openai 는 gpt-숫자 · o숫자만 남긴다', () {
      final result = chatModelsOf(ChatVendor.openai, [
        _m('gpt-9'),
        _m('o9'),
        _m('davinci-002'),
        _m('text-embedding-9'),
        _m('whisper-1'),
        _m('gpt-9-audio-preview'),
        _m('gpt-9-realtime'),
        _m('gpt-image-9'),
        _m('gpt-9-search-preview'),
        _m('gpt-9-codex'),
        _m('gpt-3.5-turbo-instruct'),
      ]);

      expect(_ids(result), ['gpt-9', 'o9']);
    });

    test('supportsTools 가 false 면 뺀다', () {
      final anthropic = chatModelsOf(ChatVendor.anthropic, [
        _m('claude-sonnet-9-8', tools: false),
        _m('claude-sonnet-9-7'),
      ]);
      final openai = chatModelsOf(ChatVendor.openai, [
        _m('gpt-9', tools: false),
        _m('gpt-8', tools: true),
      ]);

      expect(_ids(anthropic), ['claude-sonnet-9-7']);
      expect(_ids(openai), ['gpt-8']);
    });

    test('도구 미지원 표에 맞으면 뺀다', () {
      final result = chatModelsOf(ChatVendor.openai, [
        _m('o1-mini-9'),
        _m('o1-preview-9'),
        _m('o9-mini'),
      ]);

      expect(_ids(result), ['o9-mini']);
    });

    test('createdAt 이 없는 모델은 뒤로, 입력 순서 유지', () {
      final result = chatModelsOf(ChatVendor.openai, [
        _m('gpt-7'),
        _m('gpt-8', created: 1),
        _m('o8'),
        _m('gpt-9', created: 2),
        _m('o7'),
      ]);

      expect(_ids(result), ['gpt-9', 'gpt-8', 'gpt-7', 'o8', 'o7']);
    });
  });

  group('recommendedModelOf', () {
    test('anthropic 추천은 최신 sonnet', () {
      final models = chatModelsOf(ChatVendor.anthropic, [
        _m('claude-sonnet-9-7', created: 1),
        _m('claude-opus-9-9', created: 3),
        _m('claude-sonnet-9-8', created: 2),
      ]);

      expect(
        recommendedModelOf(ChatVendor.anthropic, models),
        'claude-sonnet-9-8',
      );
    });

    test('anthropic 에 sonnet 이 없으면 가장 최신', () {
      final models = chatModelsOf(ChatVendor.anthropic, [
        _m('claude-haiku-9-1', created: 1),
        _m('claude-opus-9-9', created: 2),
      ]);

      expect(
        recommendedModelOf(ChatVendor.anthropic, models),
        'claude-opus-9-9',
      );
    });

    test('빈 목록이면 null', () {
      expect(recommendedModelOf(ChatVendor.anthropic, const []), isNull);
      expect(recommendedModelOf(ChatVendor.openai, const []), isNull);
    });

    test('openai 추천은 최신 플래그십 묶음의 별칭', () {
      final models = chatModelsOf(ChatVendor.openai, [
        _m('gpt-9', created: 1),
        _m('gpt-9-2026-10-01', created: 3),
        _m('gpt-8', created: 2),
        _m('gpt-9-mini', created: 4),
        _m('gpt-9-pro', created: 5),
      ]);

      expect(recommendedModelOf(ChatVendor.openai, models), 'gpt-9');
    });

    test('별칭이 없으면 그 묶음의 가장 늦은 스냅샷', () {
      final models = chatModelsOf(ChatVendor.openai, [
        _m('gpt-9-2026-09-01', created: 3),
        _m('gpt-9-2026-10-01', created: 4),
        _m('gpt-8', created: 2),
      ]);

      expect(recommendedModelOf(ChatVendor.openai, models), 'gpt-9-2026-10-01');
    });

    test('gpt-9.5 는 gpt-9 와 다른 묶음', () {
      final models = chatModelsOf(ChatVendor.openai, [
        _m('gpt-9', created: 1),
        _m('gpt-9-2026-10-01', created: 2),
        _m('gpt-9.5-2026-11-01', created: 3),
      ]);

      expect(
        recommendedModelOf(ChatVendor.openai, models),
        'gpt-9.5-2026-11-01',
      );
    });

    test('플래그십이 없으면 가장 최신', () {
      final models = chatModelsOf(ChatVendor.openai, [
        _m('gpt-9-mini', created: 1),
        _m('o9', created: 2),
      ]);

      expect(recommendedModelOf(ChatVendor.openai, models), 'o9');
    });
  });

  test('supportsImagesOf: 벤더 값 우선 · 표 · 모르면 true', () {
    // 벤더 값 우선 — 표에 맞아도 벤더가 true 라 하면 true.
    expect(
      supportsImagesOf(ChatVendor.openai, _m('o1-mini-9', images: true)),
      isTrue,
    );
    expect(
      supportsImagesOf(
        ChatVendor.anthropic,
        _m('claude-sonnet-9-8', images: false),
      ),
      isFalse,
    );
    // 표.
    expect(supportsImagesOf(ChatVendor.openai, _m('gpt-3.5-turbo-9')), isFalse);
    expect(supportsImagesOf(ChatVendor.openai, _m('o1-mini-9')), isFalse);
    // 모르면 true.
    expect(supportsImagesOf(ChatVendor.openai, _m('gpt-9')), isTrue);
    expect(
      supportsImagesOf(ChatVendor.anthropic, _m('claude-sonnet-9-8')),
      isTrue,
    );
  });

  group('supportsEffortOf', () {
    test('anthropic 은 5.x 이상 · 4.6 이상 · Opus 4.5 만(A3)', () {
      for (final (id, expected) in const [
        ('claude-sonnet-9-8', true),
        ('claude-sonnet-5-5', true),
        ('claude-opus-5', true),
        ('claude-haiku-5-5', true),
        ('claude-fable-5-1', true),
        ('claude-opus-4-8', true),
        ('claude-sonnet-4-6', true),
        ('claude-opus-4-6-20260101', true),
        ('claude-opus-4-5', true),
        ('claude-opus-4-5-20251101', true),
        ('claude-sonnet-4-5-20250929', false),
        ('claude-sonnet-4-5', false),
        ('claude-haiku-4-5', false),
        ('claude-haiku-4-5-20251001', false),
        ('claude-opus-4-1', false),
        ('claude-opus-4-1-20250805', false),
        // 날짜만 붙은 4.0 — 날짜를 마이너로 읽지 않는다.
        ('claude-sonnet-4-20250514', false),
        ('claude-opus-4', false),
        ('claude-haiku-3-9', false),
        ('claude-3-haiku-x', false),
        ('claude-3-5-sonnet-20241022', false),
      ]) {
        expect(
          supportsEffortOf(ChatVendor.anthropic, id),
          expected,
          reason: id,
        );
      }
    });

    test('openai 는 o숫자 · gpt 메이저 5 이상만', () {
      expect(supportsEffortOf(ChatVendor.openai, 'o9'), isTrue);
      expect(supportsEffortOf(ChatVendor.openai, 'gpt-9'), isTrue);
      expect(supportsEffortOf(ChatVendor.openai, 'gpt-5.5-mini'), isTrue);
      expect(supportsEffortOf(ChatVendor.openai, 'gpt-4.9'), isFalse);
      expect(supportsEffortOf(ChatVendor.openai, 'chat-9'), isFalse);
    });
  });

  group('supportsFallbacksOf', () {
    test('Fable 5.1 · Opus 5 / 5.5 · Sonnet 5.5 과 그 뒤만', () {
      for (final (id, expected) in const [
        ('claude-fable-5-1', true),
        ('claude-opus-5', true),
        ('claude-opus-5-5', true),
        ('claude-sonnet-5-5', true),
        ('claude-opus-9-9', true),
        ('claude-sonnet-9-9', true),
        ('claude-fable-5', false),
        ('claude-sonnet-5', false),
        ('claude-haiku-5-5', false),
        ('claude-haiku-x', false),
        ('claude-opus-4-8', false),
        ('claude-opus-4-5-20251101', false),
        ('claude-sonnet-4-5-20250929', false),
        ('claude-sonnet-4-20250514', false),
        ('claude-3-5-sonnet-20241022', false),
        ('gpt-5', false),
      ]) {
        expect(supportsFallbacksOf(id), expected, reason: id);
      }
    });
  });

  group('fastModeOf', () {
    test('기본 표는 비어 있어 null', () {
      expect(fastModeOf(ChatVendor.anthropic, 'claude-opus-9-9'), isNull);
      expect(fastModeOf(ChatVendor.openai, 'gpt-9'), isNull);
    });

    test('specs 를 주면 패턴이 맞을 때 spec', () {
      final spec = FastModeSpec(
        pattern: RegExp(r'^claude-opus-'),
        priceFactor: 2,
      );
      final specs = {
        ChatVendor.anthropic: [spec],
        ChatVendor.openai: <FastModeSpec>[],
      };

      expect(
        fastModeOf(ChatVendor.anthropic, 'claude-opus-9-9', specs: specs),
        same(spec),
      );
      expect(
        fastModeOf(ChatVendor.anthropic, 'claude-sonnet-9-8', specs: specs),
        isNull,
      );
      expect(fastModeOf(ChatVendor.openai, 'gpt-9', specs: specs), isNull);
    });
  });
}
