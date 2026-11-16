import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/attachment/chat_attachment.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_usage_log.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/tool/chat_image_source.dart';
import 'package:walk/domain/chat/tool/tool_result.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/chat/chat_connection.dart';
import 'package:walk/domain/diary/draft/draft_context.dart';
import 'package:walk/domain/diary/draft/draft_length.dart';
import 'package:walk/domain/diary/draft/draft_prompt.dart';
import 'package:walk/domain/diary/draft/draft_style.dart';
import 'package:walk/domain/diary/draft/draft_writer.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_chat_model_catalog.dart';
import '../../../support/fake_chat_model_registry.dart';
import '../../../support/fake_chat_settings.dart';
import '../../../support/fake_chat_usage_log.dart';

class _FixedClock extends Clock {
  _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

class _Ids implements IdGenerator {
  @override
  String newId() => 'q1';
}

/// 준비된 이벤트(또는 던질 오류)를 흘리고 받은 요청을 모은다.
class _FakeModel implements ChatModel {
  _FakeModel(this.items);

  final List<Object> items;
  final requests = <ModelRequest>[];

  @override
  bool get progressNotes => false;

  @override
  ChatVendor get vendor => ChatVendor.anthropic;

  @override
  Future<ModelListResult> listModels(String apiKey) async =>
      const ModelListResult.ok([]);

  @override
  Stream<ModelEvent> stream(ModelRequest request) async* {
    requests.add(request);
    for (final item in items) {
      if (item is ModelEvent) {
        yield item;
      } else {
        throw item;
      }
    }
  }
}

class _HangingModel implements ChatModel {
  var cancelled = false;
  var listened = false;

  @override
  bool get progressNotes => false;

  @override
  ChatVendor get vendor => ChatVendor.anthropic;

  @override
  Future<ModelListResult> listModels(String apiKey) async =>
      const ModelListResult.ok([]);

  @override
  Stream<ModelEvent> stream(ModelRequest request) {
    late StreamController<ModelEvent> c;
    c = StreamController<ModelEvent>(
      onListen: () => listened = true,
      onCancel: () => cancelled = true,
    );
    return c.stream;
  }
}

class _Images implements ChatImageSource {
  final loaded = <String>[];

  /// 이 id 는 null(읽기 실패).
  final failing = <String>{};

  @override
  Future<ToolImage?> load(EntryMedia media) async {
    loaded.add(media.id);
    if (failing.contains(media.id)) return null;
    return ToolImage(
      mediaType: 'image/jpeg',
      bytes: Uint8List.fromList([loaded.length]),
    );
  }
}

const _usage = TokenUsage(inputTokens: 120, outputTokens: 40);

List<Object> _answer(String text, {StopKind stop = StopKind.endTurn}) => [
  ModelEvent.textDelta(text),
  ModelEvent.completed(
    message: AssistantMessage(parts: [AssistantPart.text(text)]),
    stop: stop,
    usage: _usage,
  ),
];

const _haiku = 'claude-haiku-9-5';
const _sonnet = 'claude-sonnet-9-9';

final _models = [
  ModelInfo(
    id: _sonnet,
    displayName: _sonnet,
    createdAt: DateTime.utc(2026, 1, 9),
  ),
  ModelInfo(
    id: _haiku,
    displayName: _haiku,
    createdAt: DateTime.utc(2026, 1, 5),
  ),
];

final _context = DraftContext(
  memo: '성수동 카페에서 책',
  occurredAt: DateTime(2026, 11, 15, 14, 30),
  placeName: '성수동',
  photoCount: 2,
  locale: 'ko',
);

void main() {
  final clock = _FixedClock(DateTime(2026, 11, 15, 15));
  late FakeChatSettings settings;
  late FakeChatModelCatalog catalog;
  late _Images images;
  late FakeChatUsageLog usage;

  setUp(() async {
    settings = FakeChatSettings('sk-ant-test-key')
      ..consentedVendor = ChatVendor.anthropic
      ..selectedModel = _sonnet;
    catalog = FakeChatModelCatalog();
    await catalog.replace(ChatVendor.anthropic, _models, clock.value);
    images = _Images();
    usage = FakeChatUsageLog();
  });

  DraftWriter writerOf(ChatModel model) => DraftWriter(
    FakeChatModelRegistry({ChatVendor.anthropic: model}),
    settings,
    catalog,
    images,
    usage,
    _Ids(),
    clock,
  );

  Future<List<DraftEvent>> write(
    ChatModel model, {
    DraftStyle style = DraftStyle.diary,
    List<EntryMedia> photos = const [],
    bool includePhotos = false,
    bool polish = false,
  }) => writerOf(model)
      .write(
        _context,
        style: style,
        photos: photos,
        includePhotos: includePhotos,
        polish: polish,
      )
      .toList();

  group('availability', () {
    test('키가 없으면 noKey', () async {
      settings.key = null;

      expect(
        await writerOf(_FakeModel([])).availability(),
        const DraftAvailability.noKey(),
      );
    });

    test('동의한 벤더가 없거나 다르면 needsConsent(연결 벤더)', () async {
      settings.consentedVendor = null;
      expect(
        await writerOf(_FakeModel([])).availability(),
        const DraftAvailability.needsConsent(ChatVendor.anthropic),
      );

      settings.consentedVendor = ChatVendor.openai;
      expect(
        await writerOf(_FakeModel([])).availability(),
        const DraftAvailability.needsConsent(ChatVendor.anthropic),
      );
    });

    test('초안 범위 동의만 있어도 쓴다(채팅 동의는 위치까지라 따로)', () async {
      settings
        ..consentedVendor = null
        ..draftConsentedVendor = ChatVendor.anthropic;
      expect(
        await writerOf(_FakeModel([])).availability(),
        isNot(const DraftAvailability.needsConsent(ChatVendor.anthropic)),
      );
    });

    test('키와 동의가 있으면 ready(연결 벤더)', () async {
      expect(
        await writerOf(_FakeModel([])).availability(),
        const DraftAvailability.ready(ChatVendor.anthropic),
      );
    });

    test('키 저장소를 읽지 못하면 noKey', () async {
      settings.failWith = StateError('secure storage');

      expect(
        await writerOf(_FakeModel([])).availability(),
        const DraftAvailability.noKey(),
      );
    });
  });

  group('초안 모델(R-A7)', () {
    test('물어보기에서 고른 모델이 아니라 목록의 최신 Haiku', () {
      expect(writerOf(_FakeModel([])).draftModel, _haiku);
    });

    test('목록이 다른 벤더 것이면 상수', () async {
      settings.vendor = ChatVendor.openai;

      expect(writerOf(_FakeModel([])).draftModel, 'gpt-5-mini');
    });

    test('연결 벤더가 없으면 null', () {
      settings.key = null;

      expect(writerOf(_FakeModel([])).draftModel, isNull);
    });

    test('canSeePhotos 는 초안 모델이 이미지를 받는지', () async {
      expect(writerOf(_FakeModel([])).canSeePhotos, isTrue);

      await catalog.markNoImages(_haiku);

      expect(writerOf(_FakeModel([])).canSeePhotos, isFalse);
    });
  });

  group('write', () {
    test('키가 없으면 failed(noKey) — 요청하지 않는다', () async {
      settings.key = null;
      final model = _FakeModel(_answer('x'));

      expect(await write(model), [const DraftEvent.failed(ChatFailure.noKey)]);
      expect(model.requests, isEmpty);
    });

    test('동의가 없으면 needsConsent — 요청하지 않는다', () async {
      settings.consentedVendor = null;
      final model = _FakeModel(_answer('x'));

      expect(await write(model), [const DraftEvent.needsConsent()]);
      expect(model.requests, isEmpty);
    });

    test('글 조각을 흘린 뒤 다듬은 전체 글로 끝난다', () async {
      final model = _FakeModel([
        const ModelEvent.textDelta('  성수동 카페에서 '),
        const ModelEvent.textDelta('책을 읽었다.\n'),
        const ModelEvent.completed(
          message: AssistantMessage(
            parts: [AssistantPart.text('  성수동 카페에서 책을 읽었다.\n')],
          ),
          stop: StopKind.endTurn,
          usage: _usage,
        ),
      ]);

      expect(await write(model), [
        const DraftEvent.delta('  성수동 카페에서 '),
        const DraftEvent.delta('책을 읽었다.\n'),
        const DraftEvent.done('성수동 카페에서 책을 읽었다.'),
      ]);
    });

    test('요청: 초안 모델 · 출력 상한 · 생각 끔 · 도구 · 웹 검색 없음 · 프롬프트 빌더의 글', () async {
      final model = _FakeModel(_answer('글'));

      await write(model, style: DraftStyle.sns);

      final r = model.requests.single;
      expect(r.apiKey, 'sk-ant-test-key');
      expect(r.model, _haiku);
      expect(r.maxOutputTokens, DraftWriter.maxOutputTokens);
      expect(DraftWriter.maxOutputTokens, 600);
      expect(r.thinking, isFalse);
      expect(r.fastMode, isFalse);
      expect(r.tools, isEmpty);
      expect(r.webSearch, isFalse);
      expect(
        r.system,
        DraftPrompt.system(
          style: DraftStyle.sns,
          length: DraftLength.of(memo: _context.memo, photoCount: 2),
          memo: _context.memo,
          locale: 'ko',
        ),
      );
      final message = r.messages.single as UserMessage;
      expect(message.text, DraftPrompt.user(_context));
      expect(message.attachments, isEmpty);
    });

    test('polish 면 다듬기 지시를 싣는다', () async {
      final model = _FakeModel(_answer('글'));

      await write(model, polish: true);

      expect(model.requests.single.system, contains('새 사실을 더하지 말고'));
    });

    test('빈 글이면 failed(unknown)', () async {
      final model = _FakeModel(_answer('  \n '));

      expect(
        (await write(model)).last,
        const DraftEvent.failed(ChatFailure.unknown),
      );
    });

    test('거절이면 failed(refused)', () async {
      final model = _FakeModel(_answer('', stop: StopKind.refusal));

      expect(
        (await write(model)).last,
        const DraftEvent.failed(ChatFailure.refused),
      );
    });

    test('완료 없이 스트림이 끝나면 failed(network)', () async {
      final model = _FakeModel([const ModelEvent.textDelta('반쯤')]);

      expect(await write(model), [
        const DraftEvent.delta('반쯤'),
        const DraftEvent.failed(ChatFailure.network),
      ]);
    });

    test('모델 오류는 물어보기와 같은 실패 종류로', () async {
      final model = _FakeModel([
        const ChatModelException(ChatModelErrorKind.rateLimited),
      ]);

      expect(await write(model), [
        const DraftEvent.failed(ChatFailure.rateLimited),
      ]);
    });

    test('잘못된 키면 failed(invalidKey) 이고 키 상태를 invalid 로 남긴다', () async {
      final model = _FakeModel([
        const ChatModelException(ChatModelErrorKind.invalidKey),
      ]);

      expect(await write(model), [
        const DraftEvent.failed(ChatFailure.invalidKey),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(settings.statusWrites, [ChatKeyStatus.invalid]);
    });

    test('알 수 없는 예외는 failed(unknown)', () async {
      final model = _FakeModel([StateError('boom')]);

      expect(await write(model), [
        const DraftEvent.failed(ChatFailure.unknown),
      ]);
    });

    test('구독을 끊으면 모델 스트림 구독도 끊는다(HTTP 닫기)', () async {
      final model = _HangingModel();
      final sub = writerOf(
        model,
      ).write(_context, style: DraftStyle.diary).listen((_) {});
      for (var i = 0; i < 5 && !model.listened; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(model.listened, isTrue);
      await sub.cancel();

      expect(model.cancelled, isTrue);
    });

    test('사용량을 diaryDraft 쓰임 · 초안 모델로 남긴다', () async {
      final model = _FakeModel(_answer('글'));

      await write(model);

      final record = usage.records.single;
      expect(record.purpose, ChatUsagePurpose.diaryDraft);
      expect(record.vendor, ChatVendor.anthropic);
      expect(record.model, _haiku);
      expect(record.fastMode, isFalse);
      expect(record.round, 1);
      expect(record.inputTokens, 120);
      expect(record.outputTokens, 40);
      expect(record.at, clock.value);
    });
  });

  group('사진', () {
    final media = [
      photoMedia('p1'),
      videoMedia('v1'),
      photoMedia('p2'),
      photoMedia('p3'),
      photoMedia('p4'),
      photoMedia('p5'),
    ];

    test('끄면 사진을 읽지도 붙이지도 않는다', () async {
      final model = _FakeModel(_answer('글'));

      await write(model, photos: media);

      expect(images.loaded, isEmpty);
      final message = model.requests.single.messages.single as UserMessage;
      expect(message.attachments, isEmpty);
      expect(model.requests.single.system, isNot(contains('붙인 사진')));
    });

    test('켜면 영상은 빼고 앞의 사진 최대 4장을 이미지로 붙인다', () async {
      final model = _FakeModel(_answer('글'));

      await write(model, photos: media, includePhotos: true);

      expect(images.loaded, ['p1', 'p2', 'p3', 'p4']);
      final message = model.requests.single.messages.single as UserMessage;
      expect(message.attachments, hasLength(4));
      expect(message.attachments, everyElement(isA<ImageAttachment>()));
      expect(
        (message.attachments.first as ImageAttachment).mediaType,
        'image/jpeg',
      );
      expect(model.requests.single.system, contains('붙인 사진'));
    });

    test('읽지 못한 사진은 건너뛴다', () async {
      images.failing.add('p2');
      final model = _FakeModel(_answer('글'));

      await write(model, photos: media, includePhotos: true);

      final message = model.requests.single.messages.single as UserMessage;
      expect(message.attachments, hasLength(3));
    });

    test('켜도 사진을 하나도 못 읽으면 사진 지시를 싣지 않는다', () async {
      images.failing.addAll(['p1', 'p2', 'p3', 'p4']);
      final model = _FakeModel(_answer('글'));

      await write(model, photos: media, includePhotos: true);

      expect(model.requests.single.system, isNot(contains('붙인 사진')));
    });

    test('초안 모델이 이미지를 못 받으면 켜도 사진을 읽지 않는다', () async {
      await catalog.markNoImages(_haiku);
      final model = _FakeModel(_answer('글'));

      await write(model, photos: media, includePhotos: true);

      expect(images.loaded, isEmpty);
      final message = model.requests.single.messages.single as UserMessage;
      expect(message.attachments, isEmpty);
    });
  });
}
