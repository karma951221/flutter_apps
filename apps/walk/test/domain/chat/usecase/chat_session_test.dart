import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_trace.dart';
import 'package:walk/domain/chat/chat_usage_log.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/tool/life_tools.dart';
import 'package:walk/domain/chat/tool/tool_result.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';

import '../../../support/fake_chat_settings.dart';
import '../../../support/fake_chat_usage_log.dart';
import '../../../support/recording_chat_trace.dart';

class _MockLifeTools extends Mock implements LifeTools {}

class _SeqIds implements IdGenerator {
  int _n = 0;

  @override
  String newId() => 'id-${++_n}';
}

class _FixedClock extends Clock {
  _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

/// 한 번 부를 때마다 준비된 라운드 하나를 흘리고, 받은 요청을 기록한다.
class _FakeModel implements ChatModel {
  _FakeModel(this.rounds);

  /// 라운드별 이벤트. Exception 이 들어 있으면 그 자리에서 스트림 오류를 낸다.
  final List<List<Object>> rounds;
  final requests = <ModelRequest>[];

  /// 준비된 라운드를 다 쓰면 이 라운드를 되풀이한다.
  List<Object>? repeat;

  @override
  ChatVendor get vendor => ChatVendor.anthropic;

  @override
  Stream<ModelEvent> stream(ModelRequest request) async* {
    final index = requests.length;
    requests.add(request);
    final round = index < rounds.length ? rounds[index] : repeat!;
    for (final item in round) {
      if (item is ModelEvent) {
        yield item;
      } else {
        throw item;
      }
    }
  }
}

/// 어댑터가 만드는 불투명 상태 흉내. 세션은 들고만 다녀야 한다.
class _FakeState implements VendorTurnState {
  @override
  ChatVendor get vendor => ChatVendor.anthropic;
  @override
  String get model => 'fake';
}

ModelEvent _done(
  List<AssistantPart> parts,
  StopKind stop, {
  VendorTurnState? state,
  TokenUsage? usage,
}) => ModelEvent.completed(
  message: AssistantMessage(parts: parts, vendorState: state),
  stop: stop,
  usage: usage,
);

AssistantPart _text(String text) => AssistantPart.text(text);

AssistantPart _toolUse(
  String id,
  String name, [
  Map<String, Object?> input = const {},
]) => AssistantPart.toolCall(id: id, name: name, input: input);

ChatMessage _assistant(String text) =>
    ChatMessage.assistant(parts: [_text(text)]);

List<Object> _answer(String text) => [
  ModelEvent.textDelta(text),
  _done([_text(text)], StopKind.endTurn),
];

List<Object> _answerWith(TokenUsage usage) => [
  ModelEvent.textDelta('네'),
  _done([_text('네')], StopKind.endTurn, usage: usage),
];

void main() {
  late _MockLifeTools tools;
  late FakeChatSettings settings;
  late FakeChatUsageLog usage;
  late _SeqIds ids;
  final clock = _FixedClock(DateTime(2026, 10, 27, 9));
  const definitions = [
    ToolSpec(name: 'search_diary', description: 'd', parameters: {}),
  ];

  setUpAll(() async {
    await initializeDateFormatting('ko');
    registerFallbackValue(<String, Object?>{});
  });

  setUp(() {
    tools = _MockLifeTools();
    when(() => tools.definitions).thenReturn(definitions);
    settings = FakeChatSettings('sk-ant-test-key');
    usage = FakeChatUsageLog();
    ids = _SeqIds();
  });

  ChatSession session(_FakeModel model) => ChatSession(
    model,
    tools,
    settings,
    clock,
    usage,
    ids,
    const NoopChatTrace(),
  );

  group('사용량 기록', () {
    const u1 = TokenUsage(
      inputTokens: 100,
      outputTokens: 20,
      cacheReadTokens: 7,
      cacheWriteTokens: 3,
      reasoningTokens: 4,
    );
    const u2 = TokenUsage(inputTokens: 150, outputTokens: 30);

    List<List<Object>> twoRounds() => [
      [
        _done([_toolUse('t1', 'search_diary')], StopKind.toolUse, usage: u1),
      ],
      [
        const ModelEvent.textDelta('네'),
        _done([_text('네')], StopKind.endTurn, usage: u2),
      ],
    ];

    setUp(() {
      when(
        () => tools.run('search_diary', any()),
      ).thenAnswer((_) async => const ToolResult(json: '{}'));
    });

    test('라운드마다 usage 를 하나씩 기록한다', () async {
      final model = _FakeModel(twoRounds());

      await session(model).ask('질문').toList();

      expect(usage.records, hasLength(2));
      final [a, b] = usage.records;
      expect([a.round, b.round], [1, 2]);
      expect(a.questionKey, b.questionKey);
      for (final r in usage.records) {
        expect(r.vendor, ChatVendor.anthropic);
        expect(r.model, ChatSession.interimModel);
        expect(r.fastMode, isFalse);
        expect(r.purpose, ChatUsagePurpose.chat);
        expect(r.temporary, isFalse);
        expect(r.at, clock.value);
        expect(
          [r.wikiIndexNotes, r.wikiIndexChars, r.readWikiCalls],
          [0, 0, 0],
        );
      }
      expect(
        [a.inputTokens, a.outputTokens, a.cacheReadTokens, a.cacheWriteTokens],
        [100, 20, 7, 3],
      );
      expect(a.reasoningTokens, 4);
      expect([b.inputTokens, b.outputTokens], [150, 30]);
      expect(b.reasoningTokens, isNull);
    });

    test('질문이 바뀌면 questionKey 가 바뀐다', () async {
      final model = _FakeModel(twoRounds())..repeat = _answerWith(u2);
      final chat = session(model);

      await chat.ask('하나').toList();
      await chat.ask('둘').toList();

      final keys = usage.records.map((r) => r.questionKey).toList();
      expect(keys, hasLength(3));
      expect(keys[0], keys[1]);
      expect(keys[2], isNot(keys[0]));
    });

    test('usage 가 null 인 라운드 · 실패한 라운드는 기록하지 않는다', () async {
      final nullUsage = _FakeModel([_answer('네')]);
      await session(nullUsage).ask('질문').toList();
      expect(usage.records, isEmpty);

      final failing = _FakeModel([
        [const ChatModelException(ChatModelErrorKind.network)],
      ]);
      final events = await session(failing).ask('질문').toList();
      expect(events, const [ChatEvent.failed(ChatFailure.network)]);
      expect(usage.records, isEmpty);
    });

    test('기록이 던져도 답은 finished', () async {
      usage.failWith = StateError('디스크 가득');
      final model = _FakeModel(twoRounds());

      final events = await session(model).ask('질문').toList();

      expect(events.last, const ChatEvent.finished(citedEntryIds: []));
      expect(usage.records, hasLength(2));
    });

    test('기록이 끝나지 않아도 답은 finished', () async {
      usage.hangOn = Completer<void>().future;
      final model = _FakeModel(twoRounds());

      final events = await session(model).ask('질문').toList();

      expect(events.last, const ChatEvent.finished(citedEntryIds: []));
    });
  });

  test('도구 없이 끝나면 text 를 흘리고 finished', () async {
    final model = _FakeModel([
      [
        const ModelEvent.textDelta('안'),
        const ModelEvent.textDelta('녕'),
        _done([_text('안녕')], StopKind.endTurn),
      ],
    ]);

    final events = await session(model).ask('하이').toList();

    expect(events, const [
      ChatEvent.text('안'),
      ChatEvent.text('녕'),
      ChatEvent.finished(citedEntryIds: []),
    ]);
    expect(model.requests.single.messages, const [ChatMessage.user('하이')]);
    expect(model.requests.single.apiKey, 'sk-ant-test-key');
  });

  test(
    '요청 model 은 interimModel, fastMode 는 false, tools 는 LifeTools.definitions 그대로',
    () async {
      final model = _FakeModel([_answer('네')]);

      await session(model).ask('하이').toList();

      final request = model.requests.single;
      expect(ChatSession.interimModel, 'claude-opus-5-5');
      expect(request.model, ChatSession.interimModel);
      expect(request.fastMode, isFalse);
      expect(identical(request.tools, definitions), isTrue);
    },
  );

  test(
    '진행 이벤트(thinking · progress · toolCallStarted · toolCallReady)는 ChatEvent 를 만들지 않는다',
    () async {
      final model = _FakeModel([
        [
          const ModelEvent.thinking(),
          const ModelEvent.progress('찾는 중'),
          const ModelEvent.toolCallStarted(id: 't', name: 'search_diary'),
          const ModelEvent.toolCallReady(
            id: 't',
            name: 'search_diary',
            input: {},
          ),
          const ModelEvent.textDelta('네'),
          _done([_text('네')], StopKind.endTurn),
        ],
      ]);

      final events = await session(model).ask('하이').toList();

      expect(events, const [
        ChatEvent.text('네'),
        ChatEvent.finished(citedEntryIds: []),
      ]);
    },
  );

  for (final stop in [StopKind.maxTokens, StopKind.other]) {
    test('${stop.name} 로 끝나도 finished', () async {
      final model = _FakeModel([
        [
          _done([_text('잘린 답')], stop),
        ],
        _answer('다음'),
      ]);
      final chat = session(model);

      final events = await chat.ask('질문').toList();
      await chat.ask('다음 질문').toList();

      expect(events, const [ChatEvent.finished(citedEntryIds: [])]);
      expect(model.requests.last.messages, [
        const ChatMessage.user('질문'),
        _assistant('잘린 답'),
        const ChatMessage.user('다음 질문'),
      ]);
    });
  }

  test(
    'tool_use 면 도구를 실행해 tool_result 를 user 메시지 하나로 보내고 다음 라운드로 간다',
    () async {
      when(
        () => tools.run('search_diary', {'query': '산책'}),
      ).thenAnswer((_) async => const ToolResult(json: '{"a":1}'));
      when(() => tools.run('list_diary_index', {})).thenAnswer(
        (_) async => const ToolResult(json: '{"error":"x"}', isError: true),
      );
      final model = _FakeModel([
        [
          _done([
            _toolUse('tu_1', 'search_diary', {'query': '산책'}),
            _toolUse('tu_2', 'list_diary_index'),
          ], StopKind.toolUse),
        ],
        _answer('끝'),
      ]);

      final events = await session(model).ask('산책 기록').toList();

      expect(events, const [
        ChatEvent.toolStarted('search_diary'),
        ChatEvent.toolStarted('list_diary_index'),
        ChatEvent.text('끝'),
        ChatEvent.finished(citedEntryIds: []),
      ]);
      expect(model.requests, hasLength(2));
      expect(
        model.requests[1].messages.last,
        const ChatMessage.toolResults([
          ToolResultPart(callId: 'tu_1', json: '{"a":1}'),
          ToolResultPart(callId: 'tu_2', json: '{"error":"x"}', isError: true),
        ]),
      );
      expect(model.requests[1].messages, hasLength(3));
    },
  );

  test('key · round(n) · tool.start/end 를 찍고 도구 입력값은 data 에 없다', () async {
    final image = ToolImage(
      mediaType: 'image/jpeg',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    when(() => tools.run('search_diary', any())).thenAnswer(
      (_) async => ToolResult(
        json: '{"a":1}',
        entryIds: const ['e1', 'e2'],
        images: [image],
      ),
    );
    final model = _FakeModel([
      [
        _done([
          _toolUse('tu_1', 'search_diary', {'query': '비밀 검색어'}),
        ], StopKind.toolUse),
      ],
      _answer('답'),
    ]);
    final trace = RecordingChatTrace();

    await ChatSession(
      model,
      tools,
      settings,
      clock,
      usage,
      ids,
      trace,
    ).ask('질문').toList();

    expect(trace.labels, [
      ChatTraceMark.key,
      ChatTraceMark.round,
      ChatTraceMark.toolStart,
      ChatTraceMark.toolEnd,
      ChatTraceMark.round,
    ]);
    expect(trace.dataOf(ChatTraceMark.round), [
      {'n': 1},
      {'n': 2},
    ]);
    expect(trace.dataOf(ChatTraceMark.toolStart).single, {
      'tool': 'search_diary',
    });
    expect(trace.dataOf(ChatTraceMark.toolEnd).single, {
      'tool': 'search_diary',
      'n': 3,
    });
    expect(trace.marks.map((m) => '${m.$2}').join(), isNot(contains('비밀')));
  });

  test('trace 가 꺼져 있으면 세션은 mark 를 부르지 않는다', () async {
    final trace = RecordingChatTrace(enabled: false);
    await ChatSession(
      _FakeModel([_answer('답')]),
      tools,
      settings,
      clock,
      usage,
      ids,
      trace,
    ).ask('질문').toList();
    expect(trace.marks, isEmpty);
  });

  test('이미지가 있는 결과는 ToolResultPart.images 로 다음 요청에 실린다', () async {
    final image = ToolImage(
      mediaType: 'image/jpeg',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    when(() => tools.run('view_entry_photos', any())).thenAnswer(
      (_) async => ToolResult(json: '{"photos":1}', images: [image]),
    );
    final model = _FakeModel([
      [
        _done([_toolUse('tu_1', 'view_entry_photos')], StopKind.toolUse),
      ],
      _answer('사진'),
    ]);

    await session(model).ask('사진').toList();

    expect(
      model.requests[1].messages.last,
      ChatMessage.toolResults([
        ToolResultPart(callId: 'tu_1', json: '{"photos":1}', images: [image]),
      ]),
    );
  });

  group('사진 한도(대화당 ${ChatSession.maxImagesPerConversation}장)', () {
    ToolResult photos(int count) => ToolResult(
      json: '{"photos":$count}',
      images: [
        for (var i = 0; i < count; i++)
          ToolImage(mediaType: 'image/jpeg', bytes: Uint8List.fromList([i])),
      ],
    );

    List<Object> photoRound(String id) => [
      _done([_toolUse(id, 'view_entry_photos')], StopKind.toolUse),
    ];

    ToolResultPart resultOf(ModelRequest request) =>
        (request.messages.last as ToolResultsMessage).results.single;

    int imageCount(ToolResultPart result) => result.images.length;

    setUp(() {
      when(
        () => tools.run('view_entry_photos', any()),
      ).thenAnswer((_) async => photos(5));
    });

    test('한도 안이면 이미지를 붙인다', () async {
      final model = _FakeModel([
        photoRound('t1'),
        photoRound('t2'),
        _answer('끝'),
      ]);

      await session(model).ask('사진').toList();

      expect(imageCount(resultOf(model.requests[1])), 5);
      expect(imageCount(resultOf(model.requests[2])), 5);
      expect(resultOf(model.requests[2]).isError, false);
    });

    test('한도를 넘기면 이미지 없이 is_error 와 photo_limit_reached 를 보낸다', () async {
      final model = _FakeModel([
        photoRound('t1'),
        photoRound('t2'),
        photoRound('t3'),
        _answer('끝'),
      ]);

      await session(model).ask('사진').toList();

      final over = resultOf(model.requests[3]);
      expect(over.isError, true);
      expect(imageCount(over), 0);
      expect(
        over.json,
        '{"error":"photo_limit_reached","hint":"새 대화를 시작하면 다시 사진을 볼 수 있어요"}',
      );
    });

    test('한도는 질문을 넘어 대화 전체에 걸린다', () async {
      final model = _FakeModel([
        photoRound('t1'),
        photoRound('t2'),
        _answer('첫 답'),
        photoRound('t3'),
        _answer('둘째 답'),
      ]);
      final chat = session(model);

      await chat.ask('첫').toList();
      await chat.ask('둘').toList();

      expect(imageCount(resultOf(model.requests[4])), 0);
      expect(resultOf(model.requests[4]).isError, true);
    });

    test('reset 하면 한도가 다시 찬다', () async {
      final model = _FakeModel([
        photoRound('t1'),
        photoRound('t2'),
        _answer('첫 답'),
        photoRound('t3'),
        _answer('둘째 답'),
      ]);
      final chat = session(model);

      await chat.ask('첫').toList();
      chat.reset();
      await chat.ask('둘').toList();

      expect(imageCount(resultOf(model.requests[4])), 5);
      expect(resultOf(model.requests[4]).isError, false);
    });

    test('되돌린 질문의 사진은 세지 않는다', () async {
      final model = _FakeModel([
        photoRound('t1'),
        photoRound('t2'),
        [const ChatModelException(ChatModelErrorKind.network)],
        photoRound('t3'),
        _answer('둘째 답'),
      ]);
      final chat = session(model);

      await chat.ask('첫').toList();
      await chat.ask('둘').toList();

      expect(imageCount(resultOf(model.requests[4])), 5);
    });
  });

  test(
    'completed.message(vendorState 포함)를 identical 로 다음 요청 messages 에 넣는다',
    () async {
      when(
        () => tools.run(any(), any()),
      ).thenAnswer((_) async => const ToolResult(json: '{}'));
      final state = _FakeState();
      final done =
          _done(
                [_text('찾아볼게요'), _toolUse('tu_1', 'search_diary')],
                StopKind.toolUse,
                state: state,
              )
              as ModelCompleted;
      final model = _FakeModel([
        [done],
        _answer('끝'),
      ]);

      await session(model).ask('질문').toList();

      final sent = model.requests[1].messages[1];
      expect(identical(sent, done.message), isTrue);
      expect(identical((sent as AssistantMessage).vendorState, state), isTrue);
    },
  );

  test('citedEntryIds 는 중복 없이 처음 나온 순서', () async {
    when(() => tools.run('a', any())).thenAnswer(
      (_) async => const ToolResult(json: '{}', entryIds: ['e2', 'e1']),
    );
    when(() => tools.run('b', any())).thenAnswer(
      (_) async => const ToolResult(json: '{}', entryIds: ['e1', 'e3']),
    );
    final model = _FakeModel([
      [
        _done([_toolUse('t1', 'a'), _toolUse('t2', 'b')], StopKind.toolUse),
      ],
      [
        _done([_toolUse('t3', 'a')], StopKind.toolUse),
      ],
      _answer('끝'),
    ]);

    final events = await session(model).ask('질문').toList();

    expect(
      events.last,
      const ChatEvent.finished(citedEntryIds: ['e2', 'e1', 'e3']),
    );
  });

  test('키가 없으면 noKey 이고 모델을 부르지 않는다', () async {
    settings.key = null;
    final model = _FakeModel([]);

    final events = await session(model).ask('질문').toList();

    expect(events, const [ChatEvent.failed(ChatFailure.noKey)]);
    expect(model.requests, isEmpty);
  });

  test(
    '401 이면 invalidKey 이고 대화가 질문 전으로 돌아간다. 키를 고친 다음 질문의 messages 는 [이전 대화…, 새 질문] 이다',
    () async {
      when(
        () => tools.run(any(), any()),
      ).thenAnswer((_) async => const ToolResult(json: '{}'));
      final model = _FakeModel([
        _answer('첫 답'),
        [
          _done([_toolUse('t1', 'search_diary')], StopKind.toolUse),
        ],
        [const ChatModelException(ChatModelErrorKind.invalidKey)],
        _answer('둘째 답'),
      ]);
      final chat = session(model);

      await chat.ask('첫 질문').toList();
      final failed = await chat.ask('둘째 질문').toList();
      settings.key = 'sk-ant-new-key';
      await chat.ask('셋째 질문').toList();

      expect(failed.last, const ChatEvent.failed(ChatFailure.invalidKey));
      expect(model.requests.last.apiKey, 'sk-ant-new-key');
      expect(model.requests.last.messages, [
        const ChatMessage.user('첫 질문'),
        _assistant('첫 답'),
        const ChatMessage.user('셋째 질문'),
      ]);
    },
  );

  test(
    '스트림 중간에 network 오류면 failed(network) 이고 messages 가 질문 전으로 돌아간다',
    () async {
      final model = _FakeModel([
        [
          const ModelEvent.textDelta('반쯤'),
          const ChatModelException(ChatModelErrorKind.network),
        ],
        _answer('다시'),
      ]);
      final chat = session(model);

      final events = await chat.ask('질문').toList();
      await chat.ask('다시 질문').toList();

      expect(events, const [
        ChatEvent.text('반쯤'),
        ChatEvent.failed(ChatFailure.network),
      ]);
      expect(model.requests.last.messages, const [ChatMessage.user('다시 질문')]);
    },
  );

  test(
    'server · quotaExceeded · modelUnavailable 오류는 unknown, 그 밖의 예외도 unknown',
    () async {
      final model = _FakeModel([
        [const ChatModelException(ChatModelErrorKind.server)],
        [const ChatModelException(ChatModelErrorKind.quotaExceeded)],
        [const ChatModelException(ChatModelErrorKind.modelUnavailable)],
        [StateError('boom')],
      ]);
      final chat = session(model);

      for (final q in ['a', 'b', 'c', 'd']) {
        expect(
          (await chat.ask(q).toList()).last,
          const ChatEvent.failed(ChatFailure.unknown),
          reason: q,
        );
      }
    },
  );

  test('오류 종류를 ChatFailure 로 옮긴다', () async {
    final model = _FakeModel([
      [const ChatModelException(ChatModelErrorKind.rateLimited)],
      [const ChatModelException(ChatModelErrorKind.overloaded)],
    ]);
    final chat = session(model);

    expect(
      (await chat.ask('a').toList()).last,
      const ChatEvent.failed(ChatFailure.rateLimited),
    );
    expect(
      (await chat.ask('b').toList()).last,
      const ChatEvent.failed(ChatFailure.overloaded),
    );
  });

  test('refusal 은 refused', () async {
    final model = _FakeModel([
      [
        _done([_text('')], StopKind.refusal),
      ],
      _answer('다음'),
    ]);
    final chat = session(model);

    final events = await chat.ask('질문').toList();
    await chat.ask('다음 질문').toList();

    expect(events.last, const ChatEvent.failed(ChatFailure.refused));
    expect(model.requests.last.messages, const [ChatMessage.user('다음 질문')]);
  });

  test('8라운드를 넘기면 tooManySteps', () async {
    when(
      () => tools.run(any(), any()),
    ).thenAnswer((_) async => const ToolResult(json: '{}'));
    final model = _FakeModel([])
      ..repeat = [
        _done([_toolUse('t', 'search_diary')], StopKind.toolUse),
      ];

    final events = await session(model).ask('질문').toList();

    expect(events.last, const ChatEvent.failed(ChatFailure.tooManySteps));
    expect(model.requests, hasLength(ChatSession.maxRounds));
  });

  test('시스템 프롬프트에 오늘 날짜가 들어간다', () async {
    final model = _FakeModel([_answer('네')]);

    await session(model).ask('오늘').toList();

    final system = model.requests.single.system;
    expect(system, contains('2026-10-27'));
    expect(system, contains('2026-10-27 (화)'));
    expect(system, contains(clock.value.timeZoneName));
    expect(system, startsWith('너는 사용자의 개인 기록 앱 Life Tool 안의 도우미다.'));
  });

  test('진행 중에 다시 부르면 StateError, reset 은 대화를 비운다', () async {
    final gate = Completer<void>();
    final model = _GatedModel(gate.future);
    final chat = ChatSession(
      model,
      tools,
      settings,
      clock,
      usage,
      ids,
      const NoopChatTrace(),
    );

    final first = chat.ask('첫').toList();
    expect(() => chat.ask('둘'), throwsStateError);
    gate.complete();
    await first;

    chat.reset();
    await chat.ask('셋').toList();
    expect(model.requests.last, const [ChatMessage.user('셋')]);
  });

  group('진행 중 reset', () {
    for (final outcome in ['성공', '실패']) {
      test(
        '라운드가 $outcome 으로 끝나도 이벤트 없이 멈추고, 다음 질문의 messages 는 [새 질문] 뿐이다',
        () async {
          final model = _CompleterModel();
          final chat = ChatSession(
            model,
            tools,
            settings,
            clock,
            usage,
            ids,
            const NoopChatTrace(),
          );

          final firstEvents = <ChatEvent>[];
          final first = chat.ask('첫').listen(firstEvents.add).asFuture<void>();
          await pumpEventQueue();
          expect(model.calls, hasLength(1));

          chat.reset();
          final second = chat.ask('둘').toList();
          await pumpEventQueue();

          if (outcome == '성공') {
            model.calls[0].complete(_done([_text('늦은 답')], StopKind.endTurn));
          } else {
            model.calls[0].completeError(
              const ChatModelException(ChatModelErrorKind.network),
            );
          }
          await first;
          model.calls[1].complete(_done([_text('새 답')], StopKind.endTurn));

          expect(firstEvents, isEmpty);
          expect(await second, const [ChatEvent.finished(citedEntryIds: [])]);
          expect(model.requests[1], const [ChatMessage.user('둘')]);

          unawaited(chat.ask('셋').toList());
          await pumpEventQueue();
          expect(model.requests[2], [
            const ChatMessage.user('둘'),
            _assistant('새 답'),
            const ChatMessage.user('셋'),
          ]);
        },
      );
    }
  });

  group('라운드 취소', () {
    ChatSession hanging(_HangingModel model) => ChatSession(
      model,
      tools,
      settings,
      clock,
      usage,
      ids,
      const NoopChatTrace(),
    );

    test('라운드 중 reset 하면 모델 구독을 바로 취소한다', () async {
      final model = _HangingModel();
      final chat = hanging(model);
      final events = <ChatEvent>[];
      var done = false;
      chat.ask('첫').listen(events.add, onDone: () => done = true);
      await pumpEventQueue();
      expect(model.rounds, hasLength(1));
      expect(model.cancelled.single, isFalse);

      chat.reset();
      await pumpEventQueue();

      expect(model.cancelled.single, isTrue);
      expect(events, isEmpty);
      expect(done, isTrue);
    });

    test('질문 구독을 끊으면 모델 구독도 끊는다', () async {
      final model = _HangingModel();
      final chat = hanging(model);
      late StreamSubscription<ChatEvent> sub;
      sub = chat.ask('첫').listen((_) => unawaited(sub.cancel()));
      await pumpEventQueue();
      model.rounds[0].add(const ModelEvent.textDelta('a'));
      await pumpEventQueue();

      expect(model.cancelled.single, isTrue);
    });

    test('reset 뒤 바로 ask 하면 새 질문이 정상으로 끝난다', () async {
      final model = _HangingModel();
      final chat = hanging(model);
      final firstEvents = <ChatEvent>[];
      chat.ask('첫').listen(firstEvents.add);
      await pumpEventQueue();

      chat.reset();
      final second = chat.ask('둘').toList();
      await pumpEventQueue();
      expect(model.rounds, hasLength(2));
      model.rounds[1]
        ..add(const ModelEvent.textDelta('새 답'))
        ..add(_done([_text('새 답')], StopKind.endTurn));
      unawaited(model.rounds[1].close());

      expect(await second, const [
        ChatEvent.text('새 답'),
        ChatEvent.finished(citedEntryIds: []),
      ]);
      expect(firstEvents, isEmpty);
      expect(model.cancelled, [isTrue, isFalse]);
      expect(model.requests[1], const [ChatMessage.user('둘')]);
    });
  });

  group('멈춤', () {
    late _HangingModel model;
    late ChatSession chat;

    setUp(() {
      model = _HangingModel();
      chat = ChatSession(
        model,
        tools,
        settings,
        clock,
        usage,
        ids,
        const NoopChatTrace(),
      );
    });

    /// 지금 열린 라운드를 [events] 로 끝낸다.
    void finishRound(int index, List<ModelEvent> events) {
      for (final e in events) {
        model.rounds[index].add(e);
      }
      unawaited(model.rounds[index].close());
    }

    /// 한 질문을 처음부터 끝까지 정상으로 마친다.
    Future<void> answered(
      String question,
      String answer, {
      VendorTurnState? state,
    }) async {
      final done = chat.ask(question).toList();
      await pumpEventQueue();
      finishRound(model.rounds.length - 1, [
        ModelEvent.textDelta(answer),
        _done([_text(answer)], StopKind.endTurn, state: state),
      ]);
      await done;
    }

    test('(a) 생각 중(이벤트 전) 멈추면 dropped 이고 기록이 그대로이며 바로 다음 ask 를 받는다', () async {
      await answered('앞', '앞 답');
      final events = <ChatEvent>[];
      chat.ask('첫').listen(events.add);
      await pumpEventQueue();

      expect(chat.stop(), const ChatStopResult.dropped());
      await pumpEventQueue();
      expect(events, isEmpty);
      expect(model.cancelled[1], isTrue);

      final next = chat.ask('둘').toList();
      await pumpEventQueue();
      finishRound(2, [
        _done([_text('네')], StopKind.endTurn),
      ]);
      await next;
      expect(model.requests[2], [
        const ChatMessage.user('앞'),
        _assistant('앞 답'),
        const ChatMessage.user('둘'),
      ]);
    });

    test('(b) 도구 실행 중 멈추면 늦게 끝난 도구 결과가 기록 · 이벤트에 없고 사진 수가 되돌아간다', () async {
      ToolResult photos(int count) => ToolResult(
        json: '{"photos":$count}',
        entryIds: ['late-$count'],
        images: [
          for (var i = 0; i < count; i++)
            ToolImage(mediaType: 'image/jpeg', bytes: Uint8List.fromList([i])),
        ],
      );
      final hold = Completer<ToolResult>();
      final answers = <Future<ToolResult>>[
        Future.value(photos(5)),
        hold.future,
        Future.value(photos(10)),
      ];
      var call = 0;
      when(
        () => tools.run('view_entry_photos', any()),
      ).thenAnswer((_) => answers[call++]);

      final events = <ChatEvent>[];
      chat.ask('첫').listen(events.add);
      await pumpEventQueue();
      finishRound(0, [
        _done([_toolUse('t1', 'view_entry_photos')], StopKind.toolUse),
      ]);
      await pumpEventQueue();
      finishRound(1, [
        _done([_toolUse('t2', 'view_entry_photos')], StopKind.toolUse),
      ]);
      await pumpEventQueue();
      expect(call, 2);

      expect(chat.stop(), const ChatStopResult.dropped());
      hold.complete(photos(3));
      await pumpEventQueue();
      expect(events, const [
        ChatEvent.toolStarted('view_entry_photos'),
        ChatEvent.toolStarted('view_entry_photos'),
      ]);
      expect(model.rounds, hasLength(2));

      final next = chat.ask('둘').toList();
      await pumpEventQueue();
      expect(model.requests[2], const [ChatMessage.user('둘')]);
      finishRound(2, [
        _done([_toolUse('t3', 'view_entry_photos')], StopKind.toolUse),
      ]);
      await pumpEventQueue();
      // 멈춘 질문은 1라운드에서 사진 5장을 셌다. 되돌리지 않으면 5 + 10 > 12 로
      // photo_limit 오류가 되므로, 10장이 그대로 실리면 수가 0 으로 돌아간 것이다.
      final result =
          (model.requests[3].last as ToolResultsMessage).results.single;
      expect(result.isError, isFalse);
      expect(result.images, hasLength(10));
      finishRound(3, [
        _done([_text('네')], StopKind.endTurn),
      ]);
      await next;
    });

    test(
      '(c) 1라운드 도구 뒤 2라운드 글 중간에 멈추면 꼬리가 user + assistant(글 + 표시) 하나로 바뀐다 · (d) 그 다음 질문의 요청 messages 에 부분 답이 들어 있다',
      () async {
        when(() => tools.run('search_diary', any())).thenAnswer(
          (_) async => const ToolResult(json: '{}', entryIds: ['e1']),
        );
        await answered('앞', '앞 답', state: _FakeState());

        chat.ask('질문').listen((_) {});
        await pumpEventQueue();
        finishRound(1, [
          _done(
            [_toolUse('t1', 'search_diary')],
            StopKind.toolUse,
            state: _FakeState(),
          ),
        ]);
        await pumpEventQueue();
        model.rounds[2]
          ..add(const ModelEvent.textDelta('부분 '))
          ..add(const ModelEvent.textDelta('글'));
        await pumpEventQueue();

        expect(
          chat.stop(),
          const ChatStopResult.kept(text: '부분 글', citedEntryIds: ['e1']),
        );

        final next = chat.ask('다음').toList();
        await pumpEventQueue();
        final sent = model.requests[3];
        expect(sent, hasLength(5));
        expect(sent[0], const ChatMessage.user('앞'));
        expect(identical(sent[1], model.requests[1][1]), isTrue);
        expect((sent[1] as AssistantMessage).vendorState, isA<_FakeState>());
        expect(sent[2], const ChatMessage.user('질문'));
        final tail = sent[3] as AssistantMessage;
        expect(tail.vendorState, isNull);
        expect(tail.parts, const [
          AssistantPart.text('부분 글\n${ChatSession.stoppedNote}'),
        ]);
        expect(sent[4], const ChatMessage.user('다음'));
        finishRound(3, [
          _done([_text('네')], StopKind.endTurn),
        ]);
        await next;
      },
    );

    test('(e) 멈춤 → 질문 → 멈춤 → 질문이 매번 정상이고 StateError 가 없다', () async {
      for (var i = 0; i < 2; i++) {
        chat.ask('멈출 $i').listen((_) {});
        await pumpEventQueue();
        model.rounds.last.add(ModelEvent.textDelta('글 $i'));
        await pumpEventQueue();
        expect(
          chat.stop(),
          ChatStopResult.kept(text: '글 $i', citedEntryIds: const []),
        );

        final events = chat.ask('질문 $i').toList();
        await pumpEventQueue();
        finishRound(model.rounds.length - 1, [
          ModelEvent.textDelta('답 $i'),
          _done([_text('답 $i')], StopKind.endTurn),
        ]);
        expect(await events, [
          ChatEvent.text('답 $i'),
          const ChatEvent.finished(citedEntryIds: []),
        ]);
      }
      expect(model.requests.last, [
        const ChatMessage.user('멈출 0'),
        _assistant('글 0\n${ChatSession.stoppedNote}'),
        const ChatMessage.user('질문 0'),
        _assistant('답 0'),
        const ChatMessage.user('멈출 1'),
        _assistant('글 1\n${ChatSession.stoppedNote}'),
        const ChatMessage.user('질문 1'),
      ]);
    });

    test('(f) 멈춘 뒤 늦게 오는 모델 이벤트가 새 질문에 섞이지 않는다', () async {
      final firstEvents = <ChatEvent>[];
      chat.ask('첫').listen(firstEvents.add);
      await pumpEventQueue();
      model.rounds[0].add(const ModelEvent.textDelta('앞'));
      await pumpEventQueue();

      chat.stop();
      final second = chat.ask('둘').toList();
      await pumpEventQueue();
      expect(model.cancelled[0], isTrue);

      model.rounds[0]
        ..add(const ModelEvent.textDelta('늦은 글'))
        ..add(_done([_text('앞늦은 글')], StopKind.endTurn));
      finishRound(1, [
        const ModelEvent.textDelta('새 답'),
        _done([_text('새 답')], StopKind.endTurn),
      ]);

      expect(await second, const [
        ChatEvent.text('새 답'),
        ChatEvent.finished(citedEntryIds: []),
      ]);
      expect(firstEvents, const [ChatEvent.text('앞')]);
    });

    test('진행 중이 아니면 stop 은 idle 이고 아무것도 바꾸지 않는다', () async {
      expect(chat.stop(), const ChatStopResult.idle());
      await answered('앞', '앞 답');

      expect(chat.stop(), const ChatStopResult.idle());

      unawaited(chat.ask('다음').toList());
      await pumpEventQueue();
      expect(model.requests.last, [
        const ChatMessage.user('앞'),
        _assistant('앞 답'),
        const ChatMessage.user('다음'),
      ]);
    });

    test('글이 공백뿐이면 dropped', () async {
      chat.ask('첫').listen((_) {});
      await pumpEventQueue();
      model.rounds[0].add(const ModelEvent.textDelta(' \n '));
      await pumpEventQueue();

      expect(chat.stop(), const ChatStopResult.dropped());

      unawaited(chat.ask('둘').toList());
      await pumpEventQueue();
      expect(model.requests.last, const [ChatMessage.user('둘')]);
    });

    test('kept.text 는 흘린 ChatEvent.text 를 이은 것과 같다', () async {
      when(
        () => tools.run('search_diary', any()),
      ).thenAnswer((_) async => const ToolResult(json: '{}'));
      final events = <ChatEvent>[];
      chat.ask('첫').listen(events.add);
      await pumpEventQueue();
      finishRound(0, [
        const ModelEvent.textDelta('찾아볼게요. '),
        _done([
          _text('찾아볼게요. '),
          _toolUse('t1', 'search_diary'),
        ], StopKind.toolUse),
      ]);
      await pumpEventQueue();
      model.rounds[1]
        ..add(const ModelEvent.textDelta('어제는 '))
        ..add(const ModelEvent.textDelta('걸었어요'));
      await pumpEventQueue();

      final result = chat.stop() as ChatStopKept;

      final streamed = [
        for (final e in events)
          if (e case ChatText(:final delta)) delta,
      ].join();
      expect(result.text, streamed);
      expect(result.text, '찾아볼게요. 어제는 걸었어요');
    });
  });

  group('멈춤 호출 순서', () {
    late _HangingModel model;
    late ChatSession chat;

    setUp(() {
      model = _HangingModel();
      chat = ChatSession(
        model,
        tools,
        settings,
        clock,
        usage,
        ids,
        const NoopChatTrace(),
      );
    });

    test('구독을 끊고 기다리지 않은 채 stop 하면 받은 글을 남긴다', () async {
      final sub = chat.ask('첫').listen((_) {});
      await pumpEventQueue();
      model.rounds[0].add(const ModelEvent.textDelta('부분'));
      await pumpEventQueue();

      unawaited(sub.cancel());
      expect(
        chat.stop(),
        const ChatStopResult.kept(text: '부분', citedEntryIds: []),
      );
    });

    test('stop 뒤 await cancel 은 더 이벤트 없이 끝난다', () async {
      final events = <ChatEvent>[];
      final sub = chat.ask('첫').listen(events.add);
      await pumpEventQueue();
      model.rounds[0].add(const ModelEvent.textDelta('부분'));
      await pumpEventQueue();

      expect(
        chat.stop(),
        const ChatStopResult.kept(text: '부분', citedEntryIds: []),
      );
      await sub.cancel().timeout(const Duration(seconds: 1));
      model.rounds[0].add(const ModelEvent.textDelta('늦은 글'));
      await pumpEventQueue();

      expect(events, const [ChatEvent.text('부분')]);
    });

    test('finished 를 받은 리스너가 바로 stop 해도 끝난 답을 지우지 않는다', () async {
      ChatStopResult? result;
      chat.ask('첫').listen((e) {
        if (e is ChatFinished) result = chat.stop();
      });
      await pumpEventQueue();
      model.rounds[0]
        ..add(const ModelEvent.textDelta('답'))
        ..add(_done([_text('답')], StopKind.endTurn));
      unawaited(model.rounds[0].close());
      await pumpEventQueue();

      expect(result, const ChatStopResult.idle());
      unawaited(chat.ask('다음').toList());
      await pumpEventQueue();
      expect(model.requests.last, [
        const ChatMessage.user('첫'),
        _assistant('답'),
        const ChatMessage.user('다음'),
      ]);
    });
  });

  test('이벤트와 실패에 API 키가 나오지 않는다', () async {
    final model = _FakeModel([
      [const ChatModelException(ChatModelErrorKind.invalidKey)],
    ]);

    final events = await session(model).ask('질문').toList();

    expect(events.toString(), isNot(contains('sk-ant')));
  });
}

class _GatedModel implements ChatModel {
  _GatedModel(this.gate);

  final Future<void> gate;
  final requests = <List<ChatMessage>>[];

  @override
  ChatVendor get vendor => ChatVendor.anthropic;

  @override
  Stream<ModelEvent> stream(ModelRequest request) async* {
    requests.add(request.messages);
    await gate;
    yield _done([_text('ok')], StopKind.endTurn);
  }
}

/// 부를 때마다 Completer 하나를 만들고, 테스트가 그걸 끝낸다.
class _CompleterModel implements ChatModel {
  final calls = <Completer<ModelEvent>>[];
  final requests = <List<ChatMessage>>[];

  @override
  ChatVendor get vendor => ChatVendor.anthropic;

  @override
  Stream<ModelEvent> stream(ModelRequest request) {
    requests.add(request.messages);
    final call = Completer<ModelEvent>();
    calls.add(call);
    return call.future.asStream();
  }
}

/// 부를 때마다 테스트가 쥐는 컨트롤러 라운드를 만들고, 끝나기 전의 구독 취소를 기록한다.
class _HangingModel implements ChatModel {
  final rounds = <StreamController<ModelEvent>>[];
  final cancelled = <bool>[];
  final requests = <List<ChatMessage>>[];

  @override
  ChatVendor get vendor => ChatVendor.anthropic;

  @override
  Stream<ModelEvent> stream(ModelRequest request) {
    requests.add(request.messages);
    final index = rounds.length;
    cancelled.add(false);
    late final StreamController<ModelEvent> round;
    // 닫은 뒤의 onCancel(정상 종료)은 취소로 세지 않는다.
    round = StreamController<ModelEvent>(
      onCancel: () {
        if (!round.isClosed) cancelled[index] = true;
      },
    );
    rounds.add(round);
    return round.stream;
  }
}
