import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/chat_connection.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_trace.dart';
import 'package:walk/domain/chat/chat_usage_log.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/entity/conversation.dart';
import 'package:walk/domain/chat/tool/life_tools.dart';
import 'package:walk/domain/chat/tool/tool_result.dart';
import 'package:walk/domain/chat/tool/tool_summary.dart';
import 'package:walk/domain/chat/chat_model_rules.dart';
import 'package:walk/domain/chat/usecase/chat_model_choice.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';

import '../../../support/fake_chat_key_verifier.dart';
import '../../../support/fake_chat_model_catalog.dart';
import '../../../support/fake_chat_model_registry.dart';
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

  DateTime value;

  @override
  DateTime now() => value;
}

/// 한 번 부를 때마다 준비된 라운드 하나를 흘리고, 받은 요청을 기록한다.
class _FakeModel implements ChatModel {
  @override
  bool progressNotes = false;

  _FakeModel(this.rounds);

  /// 라운드별 이벤트. Exception 이 들어 있으면 그 자리에서 스트림 오류를 낸다.
  final List<List<Object>> rounds;
  final requests = <ModelRequest>[];

  /// 준비된 라운드를 다 쓰면 이 라운드를 되풀이한다.
  List<Object>? repeat;

  @override
  Future<ModelListResult> listModels(String apiKey) async =>
      const ModelListResult.ok([]);

  @override
  var vendor = ChatVendor.anthropic;

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

ModelInfo _info(String id, int day, {bool? images}) => ModelInfo(
  id: id,
  displayName: id,
  createdAt: DateTime.utc(2026, 1, day),
  supportsImages: images,
);

/// 추천(지금 목록의 sonnet). 사진 · 빠른 출력 둘 다 안 됨.
const _rec = 'claude-sonnet-9-5';

/// 빠른 출력 지원(테스트 표).
const _opus = 'claude-opus-9-9';

/// 사진을 못 보는 모델.
const _haiku = 'claude-haiku-9-1';

const _gpt = 'gpt-9';

final _anthropicModels = [
  _info(_opus, 9),
  _info(_rec, 5),
  _info(_haiku, 1, images: false),
];

final _fastSpecs = {
  ChatVendor.anthropic: [
    FastModeSpec(pattern: RegExp(r'^claude-opus-'), priceFactor: 6),
  ],
};

void main() {
  late _MockLifeTools tools;
  late FakeChatSettings settings;
  late FakeChatUsageLog usage;
  late _SeqIds ids;
  late FakeChatModelCatalog catalog;
  late FakeChatKeyVerifier verifier;
  late ChatModelChoice choice;
  final clock = _FixedClock(DateTime(2026, 10, 27, 9));
  const definitions = [
    ToolSpec(name: 'search_diary', description: 'd', parameters: {}),
    ToolSpec(name: 'view_entry_photos', description: 'd', parameters: {}),
  ];
  const noImageDefinitions = [
    ToolSpec(name: 'search_diary', description: 'd', parameters: {}),
  ];

  setUpAll(() async {
    await initializeDateFormatting('ko');
    registerFallbackValue(<String, Object?>{});
  });

  setUp(() async {
    tools = _MockLifeTools();
    when(() => tools.definitions).thenReturn(definitions);
    when(() => tools.definitionsFor(images: true)).thenReturn(definitions);
    when(
      () => tools.definitionsFor(images: false),
    ).thenReturn(noImageDefinitions);
    when(() => tools.inputSummary(any(), any())).thenAnswer(
      (i) => ToolInputSummary(
        kind: chatToolKindOf(i.positionalArguments[0] as String),
      ),
    );
    settings = FakeChatSettings('sk-ant-test-key');
    usage = FakeChatUsageLog();
    ids = _SeqIds();
    catalog = FakeChatModelCatalog();
    await catalog.replace(ChatVendor.anthropic, _anthropicModels, clock.value);
    verifier = FakeChatKeyVerifier()
      ..stored = (ChatVendor.anthropic, ModelListResult.ok(_anthropicModels));
    choice = ChatModelChoice(
      settings,
      catalog,
      verifier,
      clock,
      fastModeSpecs: _fastSpecs,
    );
  });

  ChatSession sessionOf(Map<ChatVendor, ChatModel> models) => ChatSession(
    FakeChatModelRegistry(models),
    tools,
    settings,
    choice,
    clock,
    usage,
    ids,
    const NoopChatTrace(),
  );

  ChatSession session(_FakeModel model) => ChatSession(
    FakeChatModelRegistry({ChatVendor.anthropic: model}),
    tools,
    settings,
    choice,
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
        expect(r.model, _rec);
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
      expect(events, const [
        ChatEvent.phase(ChatPhase.sending),
        ChatEvent.failed(ChatFailure.network),
      ]);
      expect(usage.records, isEmpty);
    });

    test('1라운드를 기록한 뒤 2라운드가 실패해도 1라운드 기록은 남는다', () async {
      final model = _FakeModel([
        [
          _done([_toolUse('t1', 'search_diary')], StopKind.toolUse, usage: u1),
        ],
        [const ChatModelException(ChatModelErrorKind.network)],
      ]);

      final events = await session(model).ask('질문').toList();

      expect(events.last, const ChatEvent.failed(ChatFailure.network));
      expect(usage.records.single.round, 1);
      expect(usage.records.single.inputTokens, 100);
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
      ChatEvent.phase(ChatPhase.sending),
      ChatEvent.phase(ChatPhase.writing),
      ChatEvent.text('안'),
      ChatEvent.text('녕'),
      ChatEvent.finished(citedEntryIds: []),
    ]);
    expect(model.requests.single.messages, const [ChatMessage.user('하이')]);
    expect(model.requests.single.apiKey, 'sk-ant-test-key');
  });

  test('요청 model 은 추천, fastMode 는 false, tools 는 사진 되는 모델의 정의 그대로', () async {
    final model = _FakeModel([_answer('네')]);

    await session(model).ask('하이').toList();

    final request = model.requests.single;
    expect(request.model, _rec);
    expect(request.fastMode, isFalse);
    expect(identical(request.tools, definitions), isTrue);
  });

  group('진행 ChatEvent', () {
    const range = {'from': '2026-10-19', 'to': '2026-10-25'};
    final rangeSummary = ToolInputSummary(
      kind: ChatToolKind.searchDiary,
      from: DateTime(2026, 10, 19),
      to: DateTime(2026, 10, 25),
    );
    const found = ToolResult(
      json: '{}',
      summary: ToolSummary(kind: ChatToolKind.searchDiary, count: 5),
    );

    setUp(() {
      when(
        () => tools.inputSummary('search_diary', range),
      ).thenReturn(rangeSummary);
      when(
        () => tools.run('search_diary', any()),
      ).thenAnswer((_) async => found);
    });

    List<Object> toolRound({bool note = true}) => [
      const ModelEvent.thinking(),
      if (note) const ModelEvent.progress('지난주 일기를 볼게요'),
      const ModelEvent.toolCallStarted(id: 't1', name: 'search_diary'),
      const ModelEvent.toolCallReady(
        id: 't1',
        name: 'search_diary',
        input: range,
      ),
      _done([_toolUse('t1', 'search_diary', range)], StopKind.toolUse),
    ];

    test('이벤트 순서', () async {
      final model = _FakeModel([toolRound(), _answer('지난주에는')]);

      final events = await session(model).ask('지난주').toList();

      expect(events, [
        const ChatEvent.phase(ChatPhase.sending),
        const ChatEvent.phase(ChatPhase.thinking),
        const ChatEvent.progress('지난주 일기를 볼게요'),
        const ChatEvent.toolStarted(callId: 't1', name: 'search_diary'),
        ChatEvent.toolStarted(
          callId: 't1',
          name: 'search_diary',
          input: rangeSummary,
        ),
        const ChatEvent.toolFinished(
          callId: 't1',
          name: 'search_diary',
          summary: ToolSummary(kind: ChatToolKind.searchDiary, count: 5),
        ),
        const ChatEvent.roundStarted(2),
        const ChatEvent.phase(ChatPhase.writing),
        const ChatEvent.text('지난주에는'),
        const ChatEvent.finished(citedEntryIds: []),
      ]);
    });

    test('진행 노트가 0개여도 같은 순서에서 progress 만 빠진다', () async {
      final model = _FakeModel([toolRound(note: false), _answer('지난주에는')]);

      final events = await session(model).ask('지난주').toList();

      expect(events, [
        const ChatEvent.phase(ChatPhase.sending),
        const ChatEvent.phase(ChatPhase.thinking),
        const ChatEvent.toolStarted(callId: 't1', name: 'search_diary'),
        ChatEvent.toolStarted(
          callId: 't1',
          name: 'search_diary',
          input: rangeSummary,
        ),
        const ChatEvent.toolFinished(
          callId: 't1',
          name: 'search_diary',
          summary: ToolSummary(kind: ChatToolKind.searchDiary, count: 5),
        ),
        const ChatEvent.roundStarted(2),
        const ChatEvent.phase(ChatPhase.writing),
        const ChatEvent.text('지난주에는'),
        const ChatEvent.finished(citedEntryIds: []),
      ]);
    });

    test('모델이 알리지 않은 도구 호출은 실행 전에 세션이 toolStarted 를 낸다', () async {
      final model = _FakeModel([
        [
          _done([
            _toolUse('t1', 'search_diary', range),
            _toolUse('t2', 'list_diary_index'),
          ], StopKind.toolUse),
        ],
        _answer('네'),
      ]);
      when(
        () => tools.run('list_diary_index', any()),
      ).thenAnswer((_) async => const ToolResult(json: '{}'));

      final events = await session(model).ask('지난주').toList();

      expect(events.take(3).toList(), [
        const ChatEvent.phase(ChatPhase.sending),
        ChatEvent.toolStarted(
          callId: 't1',
          name: 'search_diary',
          input: rangeSummary,
        ),
        const ChatEvent.toolStarted(
          callId: 't2',
          name: 'list_diary_index',
          input: ToolInputSummary(kind: ChatToolKind.diaryIndex),
        ),
      ]);
    });

    test('모델이 알린 호출은 세션이 다시 알리지 않는다', () async {
      final model = _FakeModel([toolRound(), _answer('네')]);

      final events = await session(model).ask('지난주').toList();

      expect(events.whereType<ChatToolStarted>(), hasLength(2));
    });

    test('결과에 요약이 없으면 toolFinished 는 그 종류의 0개', () async {
      when(
        () => tools.run('search_diary', any()),
      ).thenAnswer((_) async => const ToolResult(json: '{}'));
      final model = _FakeModel([toolRound(), _answer('네')]);

      final events = await session(model).ask('지난주').toList();

      expect(
        events.whereType<ChatToolFinished>().single.summary,
        const ToolSummary(kind: ChatToolKind.searchDiary, count: 0),
      );
    });

    test('thinking 이 연달아 와도 phase(thinking) 는 한 번', () async {
      final model = _FakeModel([
        [
          const ModelEvent.thinking(),
          const ModelEvent.thinking(),
          const ModelEvent.textDelta('네'),
          _done([_text('네')], StopKind.endTurn),
        ],
      ]);

      final events = await session(model).ask('하이').toList();

      expect(events, const [
        ChatEvent.phase(ChatPhase.sending),
        ChatEvent.phase(ChatPhase.thinking),
        ChatEvent.phase(ChatPhase.writing),
        ChatEvent.text('네'),
        ChatEvent.finished(citedEntryIds: []),
      ]);
    });

    test('ChatEvent.progress · toolStarted 의 toString 에 노트 · 검색어가 없다', () {
      expect(
        const ChatEvent.progress('비밀 노트').toString(),
        isNot(contains('비밀')),
      );
      expect(
        const ChatEvent.toolStarted(
          callId: 't1',
          name: 'search_diary',
          input: ToolInputSummary(
            kind: ChatToolKind.searchDiary,
            query: '비밀 검색어',
          ),
        ).toString(),
        isNot(contains('비밀')),
      );
    });
  });

  group('도구 병렬', () {
    List<Object> twoTools() => [
      _done([_toolUse('t1', 'a'), _toolUse('t2', 'b')], StopKind.toolUse),
    ];

    test('도구 둘은 동시에 시작한다', () async {
      final holdA = Completer<ToolResult>();
      final holdB = Completer<ToolResult>();
      when(() => tools.run('a', any())).thenAnswer((_) => holdA.future);
      when(() => tools.run('b', any())).thenAnswer((_) => holdB.future);
      final model = _FakeModel([twoTools(), _answer('끝')]);

      final done = session(model).ask('질문').toList();
      await pumpEventQueue();

      verify(() => tools.run('a', any())).called(1);
      verify(() => tools.run('b', any())).called(1);
      holdA.complete(const ToolResult(json: '{}'));
      holdB.complete(const ToolResult(json: '{}'));
      await done;
    });

    test('toolFinished 는 끝난 순서, 다음 요청의 ToolResultsMessage 는 호출 순서다', () async {
      final holdA = Completer<ToolResult>();
      final holdB = Completer<ToolResult>();
      when(() => tools.run('a', any())).thenAnswer((_) => holdA.future);
      when(() => tools.run('b', any())).thenAnswer((_) => holdB.future);
      final model = _FakeModel([twoTools(), _answer('끝')]);

      final done = session(model).ask('질문').toList();
      await pumpEventQueue();
      holdB.complete(const ToolResult(json: '{"b":1}'));
      await pumpEventQueue();
      holdA.complete(const ToolResult(json: '{"a":1}'));
      final events = await done;

      expect(
        [for (final e in events.whereType<ChatToolFinished>()) e.callId],
        ['t2', 't1'],
      );
      expect(
        model.requests[1].messages.last,
        const ChatMessage.toolResults([
          ToolResultPart(callId: 't1', json: '{"a":1}'),
          ToolResultPart(callId: 't2', json: '{"b":1}'),
        ]),
      );
    });

    test('사진 한도는 호출 순서로 판정한다', () async {
      ToolResult photos(int count) => ToolResult(
        json: '{"photos":$count}',
        images: [
          for (var i = 0; i < count; i++)
            ToolImage(mediaType: 'image/jpeg', bytes: Uint8List.fromList([i])),
        ],
      );
      final holdA = Completer<ToolResult>();
      final holdB = Completer<ToolResult>();
      when(
        () => tools.run('view_entry_photos', {'id': 'p0'}),
      ).thenAnswer((_) async => photos(10));
      when(
        () => tools.run('view_entry_photos', {'id': 'p1'}),
      ).thenAnswer((_) => holdA.future);
      when(
        () => tools.run('view_entry_photos', {'id': 'p2'}),
      ).thenAnswer((_) => holdB.future);
      final model = _FakeModel([
        [
          _done([
            _toolUse('t0', 'view_entry_photos', {'id': 'p0'}),
          ], StopKind.toolUse),
        ],
        [
          _done([
            _toolUse('t1', 'view_entry_photos', {'id': 'p1'}),
            _toolUse('t2', 'view_entry_photos', {'id': 'p2'}),
          ], StopKind.toolUse),
        ],
        _answer('끝'),
      ]);

      final done = session(model).ask('사진').toList();
      await pumpEventQueue();
      holdB.complete(photos(2));
      await pumpEventQueue();
      holdA.complete(photos(2));
      await done;

      final [first, second] =
          (model.requests[2].messages.last as ToolResultsMessage).results;
      expect(first.callId, 't1');
      expect(first.images, hasLength(2));
      expect(first.isError, isFalse);
      expect(second.callId, 't2');
      expect(second.images, isEmpty);
      expect(second.isError, isTrue);
      expect(second.json, contains('photo_limit_reached'));
    });

    test('도구 실행 중 stop 하면 늦게 끝난 도구의 toolFinished · 결과가 없다', () async {
      final holdA = Completer<ToolResult>();
      when(() => tools.run('a', any())).thenAnswer((_) => holdA.future);
      when(
        () => tools.run('b', any()),
      ).thenAnswer((_) async => const ToolResult(json: '{}'));
      final model = _FakeModel([twoTools(), _answer('새 답')]);
      final chat = session(model);

      final events = <ChatEvent>[];
      chat.ask('첫').listen(events.add);
      await pumpEventQueue();
      expect(chat.stop(), const ChatStopResult.dropped());
      holdA.complete(const ToolResult(json: '{"late":1}'));
      await pumpEventQueue();

      expect(events, const [
        ChatEvent.phase(ChatPhase.sending),
        ChatEvent.toolStarted(
          callId: 't1',
          name: 'a',
          input: ToolInputSummary(kind: ChatToolKind.other),
        ),
        ChatEvent.toolStarted(
          callId: 't2',
          name: 'b',
          input: ToolInputSummary(kind: ChatToolKind.other),
        ),
        ChatEvent.toolFinished(
          callId: 't2',
          name: 'b',
          summary: ToolSummary(kind: ChatToolKind.other, count: 0),
        ),
      ]);
      expect(model.requests, hasLength(1));

      await chat.ask('둘').toList();
      expect(model.requests[1].messages, const [ChatMessage.user('둘')]);
    });
  });

  group('라운드 경계 줄바꿈', () {
    setUp(() {
      when(
        () => tools.run('search_diary', any()),
      ).thenAnswer((_) async => const ToolResult(json: '{}'));
    });

    test('라운드 경계의 첫 글 앞에 줄바꿈을 넣는다', () async {
      final model = _HangingModel();
      final chat = ChatSession(
        FakeChatModelRegistry({ChatVendor.anthropic: model}),
        tools,
        settings,
        choice,
        clock,
        usage,
        ids,
        const NoopChatTrace(),
      );
      final events = <ChatEvent>[];
      chat.ask('지난주').listen(events.add);
      await pumpEventQueue();
      model.rounds[0]
        ..add(const ModelEvent.textDelta('볼게요.'))
        ..add(
          _done([
            _text('볼게요.'),
            _toolUse('t1', 'search_diary'),
          ], StopKind.toolUse),
        );
      unawaited(model.rounds[0].close());
      await pumpEventQueue();
      model.rounds[1]
        ..add(const ModelEvent.textDelta('지난주에는'))
        ..add(const ModelEvent.textDelta('…'));
      await pumpEventQueue();

      final streamed = [
        for (final e in events)
          if (e case ChatText(:final delta)) delta,
      ].join();
      expect(streamed, '볼게요.\n지난주에는…');
      final result = chat.stop() as ChatStopKept;
      expect(result.text, '볼게요.\n지난주에는…');
    });

    test('빈 첫 조각은 줄바꿈을 쓰지 않고 다음 조각 앞에 넣는다', () async {
      final model = _FakeModel([
        [
          const ModelEvent.textDelta('볼게요.'),
          _done([
            _text('볼게요.'),
            _toolUse('t1', 'search_diary'),
          ], StopKind.toolUse),
        ],
        [
          const ModelEvent.textDelta(''),
          const ModelEvent.textDelta('지난주에는'),
          _done([_text('지난주에는')], StopKind.endTurn),
        ],
      ]);

      final events = await session(model).ask('지난주').toList();

      expect(events.whereType<ChatText>().toList(), const [
        ChatEvent.text('볼게요.'),
        ChatEvent.text(''),
        ChatEvent.text('\n지난주에는'),
      ]);
    });

    test('1라운드에 글이 없으면 2라운드 첫 글 앞에 줄바꿈이 없다', () async {
      final model = _FakeModel([
        [
          _done([_toolUse('t1', 'search_diary')], StopKind.toolUse),
        ],
        [
          const ModelEvent.textDelta('지난주에는'),
          const ModelEvent.textDelta('…'),
          _done([_text('지난주에는…')], StopKind.endTurn),
        ],
      ]);

      final events = await session(model).ask('지난주').toList();

      expect(events.whereType<ChatText>().toList(), const [
        ChatEvent.text('지난주에는'),
        ChatEvent.text('…'),
      ]);
    });
  });

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

      expect(events, const [
        ChatEvent.phase(ChatPhase.sending),
        ChatEvent.finished(citedEntryIds: []),
      ]);
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
        ChatEvent.phase(ChatPhase.sending),
        ChatEvent.toolStarted(
          callId: 'tu_1',
          name: 'search_diary',
          input: ToolInputSummary(kind: ChatToolKind.searchDiary),
        ),
        ChatEvent.toolStarted(
          callId: 'tu_2',
          name: 'list_diary_index',
          input: ToolInputSummary(kind: ChatToolKind.diaryIndex),
        ),
        ChatEvent.toolFinished(
          callId: 'tu_1',
          name: 'search_diary',
          summary: ToolSummary(kind: ChatToolKind.searchDiary, count: 0),
        ),
        ChatEvent.toolFinished(
          callId: 'tu_2',
          name: 'list_diary_index',
          summary: ToolSummary(kind: ChatToolKind.diaryIndex, count: 0),
        ),
        ChatEvent.roundStarted(2),
        ChatEvent.phase(ChatPhase.writing),
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
      FakeChatModelRegistry({ChatVendor.anthropic: model}),
      tools,
      settings,
      choice,
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
      FakeChatModelRegistry({
        ChatVendor.anthropic: _FakeModel([_answer('답')]),
      }),
      tools,
      settings,
      choice,
      clock,
      usage,
      ids,
      trace,
    ).ask('질문').toList();
    expect(trace.marks, isEmpty);
  });

  group('trace 표시는 stale() 뒤에 찍는다', () {
    test('키를 읽는 중 reset 하면 늦게 끝난 지난 질문은 key 를 찍지 않는다', () async {
      final slow = _GatedKeySettings('sk-ant-test-key');
      final gate = Completer<void>();
      slow.gate = gate.future;
      final trace = RecordingChatTrace();
      final chat = ChatSession(
        FakeChatModelRegistry({
          ChatVendor.anthropic: _FakeModel([_answer('답')]),
        }),
        tools,
        slow,
        choice,
        clock,
        usage,
        ids,
        trace,
      );

      chat.ask('첫').listen((_) {});
      await pumpEventQueue();
      chat.reset();
      slow.gate = null;
      await chat.ask('둘').toList();
      expect(trace.labels, [ChatTraceMark.key, ChatTraceMark.round]);

      gate.complete();
      await pumpEventQueue();
      expect(trace.labels, [ChatTraceMark.key, ChatTraceMark.round]);
    });

    test('도구 실행 중 reset 하면 늦게 끝난 도구는 tool.end 를 찍지 않는다', () async {
      final hold = Completer<ToolResult>();
      when(
        () => tools.run('search_diary', any()),
      ).thenAnswer((_) => hold.future);
      final trace = RecordingChatTrace();
      final chat = ChatSession(
        FakeChatModelRegistry({
          ChatVendor.anthropic: _FakeModel([
            [
              _done([_toolUse('t1', 'search_diary')], StopKind.toolUse),
            ],
          ]),
        }),
        tools,
        settings,
        choice,
        clock,
        usage,
        ids,
        trace,
      );

      chat.ask('첫').listen((_) {});
      await pumpEventQueue();
      expect(trace.labels.last, ChatTraceMark.toolStart);

      chat.reset();
      hold.complete(const ToolResult(json: '{}'));
      await pumpEventQueue();

      expect(trace.labels, isNot(contains(ChatTraceMark.toolEnd)));
    });
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
        '{"error":"photo_limit_reached","hint":"대화를 다시 열거나 새 대화를 시작하면 다시 사진을 볼 수 있어요"}',
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

    expect(events, const [
      ChatEvent.phase(ChatPhase.sending),
      ChatEvent.failed(ChatFailure.noKey),
    ]);
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
        ChatEvent.phase(ChatPhase.sending),
        ChatEvent.phase(ChatPhase.writing),
        ChatEvent.text('반쯤'),
        ChatEvent.failed(ChatFailure.network),
      ]);
      expect(model.requests.last.messages, const [ChatMessage.user('다시 질문')]);
    },
  );

  test('server 오류는 unknown, 그 밖의 예외도 unknown', () async {
    final model = _FakeModel([
      [const ChatModelException(ChatModelErrorKind.server)],
      [StateError('boom')],
    ]);
    final chat = session(model);

    for (final q in ['a', 'b']) {
      expect(
        (await chat.ask(q).toList()).last,
        const ChatEvent.failed(ChatFailure.unknown),
        reason: q,
      );
    }
  });

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

  test('quotaExceeded · modelUnavailable 예외는 같은 이름의 ChatFailure', () async {
    final model = _FakeModel([
      [const ChatModelException(ChatModelErrorKind.quotaExceeded)],
      [const ChatModelException(ChatModelErrorKind.modelUnavailable)],
    ]);
    final chat = session(model);

    expect(
      (await chat.ask('a').toList()).last,
      const ChatEvent.failed(ChatFailure.quotaExceeded),
    );
    expect(
      (await chat.ask('b').toList()).last,
      const ChatEvent.failed(ChatFailure.modelUnavailable),
    );
  });

  group('키 상태 기록', () {
    test('invalidKey 로 실패하면 키 상태를 invalid 로 기록한다', () async {
      final model = _FakeModel([
        [const ChatModelException(ChatModelErrorKind.invalidKey)],
      ]);

      final events = await session(model).ask('질문').toList();
      await pumpEventQueue();

      expect(events.last, const ChatEvent.failed(ChatFailure.invalidKey));
      expect(settings.statusWrites, [ChatKeyStatus.invalid]);
      expect(settings.status, ChatKeyStatus.invalid);
    });

    test('질문이 끝나면 valid 로 기록한다', () async {
      settings.status = ChatKeyStatus.unverified;
      final model = _FakeModel([_answer('네')]);

      await session(model).ask('질문').toList();
      await pumpEventQueue();

      expect(settings.statusWrites, [ChatKeyStatus.valid]);
      expect(settings.status, ChatKeyStatus.valid);
    });

    test('그 밖의 실패는 기록하지 않는다', () async {
      final model = _FakeModel([
        [const ChatModelException(ChatModelErrorKind.network)],
        [const ChatModelException(ChatModelErrorKind.quotaExceeded)],
      ]);
      final chat = session(model);

      await chat.ask('a').toList();
      await chat.ask('b').toList();
      await pumpEventQueue();

      expect(settings.statusWrites, isEmpty);
    });

    test('상태 기록이 던져도 답은 그대로', () async {
      settings.failSetKeyStatusWith = StateError('저장소');
      final chat = session(
        _FakeModel([
          _answer('네'),
          [const ChatModelException(ChatModelErrorKind.invalidKey)],
        ]),
      );

      expect(
        (await chat.ask('a').toList()).last,
        const ChatEvent.finished(citedEntryIds: []),
      );
      expect(
        (await chat.ask('b').toList()).last,
        const ChatEvent.failed(ChatFailure.invalidKey),
      );
      await pumpEventQueue();
      expect(settings.statusWrites, [
        ChatKeyStatus.valid,
        ChatKeyStatus.invalid,
      ]);
    });

    test('질문 동안 키를 바꾸거나 끊으면 기록하지 않는다', () async {
      for (final change in ['바꿈', '끊음']) {
        for (final outcome in ['성공', 'invalidKey']) {
          settings
            ..key = 'sk-ant-test-key'
            ..statusWrites.clear();
          final model = _CompleterModel();
          final chat = ChatSession(
            FakeChatModelRegistry({ChatVendor.anthropic: model}),
            tools,
            settings,
            choice,
            clock,
            usage,
            ids,
            const NoopChatTrace(),
          );
          final events = chat.ask('질문').toList();
          await pumpEventQueue();

          if (change == '바꿈') {
            settings.key = 'sk-ant-other-key';
          } else {
            settings.key = null;
          }
          if (outcome == '성공') {
            model.calls[0].complete(_done([_text('답')], StopKind.endTurn));
          } else {
            model.calls[0].completeError(
              const ChatModelException(ChatModelErrorKind.invalidKey),
            );
          }
          await events;
          await pumpEventQueue();

          expect(settings.statusWrites, isEmpty, reason: '$change · $outcome');
        }
      }
    });

    test('리셋된 질문은 기록하지 않는다', () async {
      for (final outcome in ['성공', 'invalidKey']) {
        settings.statusWrites.clear();
        final model = _CompleterModel();
        final chat = ChatSession(
          FakeChatModelRegistry({ChatVendor.anthropic: model}),
          tools,
          settings,
          choice,
          clock,
          usage,
          ids,
          const NoopChatTrace(),
        );
        final first = chat.ask('첫').toList();
        await pumpEventQueue();

        chat.reset();
        if (outcome == '성공') {
          model.calls[0].complete(_done([_text('늦은 답')], StopKind.endTurn));
        } else {
          model.calls[0].completeError(
            const ChatModelException(ChatModelErrorKind.invalidKey),
          );
        }
        await first;
        await pumpEventQueue();

        expect(settings.statusWrites, isEmpty, reason: outcome);
      }
    });
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

  test('오늘 날짜 줄은 시스템 프롬프트의 마지막 줄이다', () async {
    final model = _FakeModel([_answer('네')]);

    await session(model).ask('오늘').toList();

    final lines = model.requests.single.system.split('\n');
    expect(
      lines.last,
      '오늘은 2026-10-27 (화), 시간대는 ${clock.value.timeZoneName} 이다.',
    );
    expect(lines.where((l) => l.contains('2026-10-27')), hasLength(1));
  });

  test('progressNotes 인 모델이면 도구 전 한 줄 안내가 있고, 아니면 없다', () async {
    const hint = '도구를 쓰기 전에 무엇을 볼지 한 줄로 말해.';
    final off = _FakeModel([_answer('네')]);
    await session(off).ask('오늘').toList();
    expect(off.requests.single.system, isNot(contains(hint)));

    final on = _FakeModel([_answer('네')])..progressNotes = true;
    await session(on).ask('오늘').toList();
    final lines = on.requests.single.system.split('\n');
    expect(lines, contains(hint));
    // 안내는 날짜 줄 바로 앞 — 날짜 줄이 마지막이다.
    expect(lines[lines.length - 2], hint);
    expect(lines.last, startsWith('오늘은 '));
  });

  test('같은 날 두 질문의 system 은 바이트까지 같다', () async {
    final model = _FakeModel([_answer('네'), _answer('또')]);
    final dayClock = _FixedClock(DateTime(2026, 10, 27, 9));
    final chat = ChatSession(
      FakeChatModelRegistry({ChatVendor.anthropic: model}),
      tools,
      settings,
      choice,
      dayClock,
      usage,
      ids,
      const NoopChatTrace(),
    );

    await chat.ask('하나').toList();
    dayClock.value = DateTime(2026, 10, 27, 21, 30);
    await chat.ask('둘').toList();

    expect(model.requests, hasLength(2));
    expect(
      utf8.encode(model.requests[1].system),
      utf8.encode(model.requests[0].system),
    );
  });

  test('진행 중에 다시 부르면 StateError, reset 은 대화를 비운다', () async {
    final gate = Completer<void>();
    final model = _GatedModel(gate.future);
    final chat = ChatSession(
      FakeChatModelRegistry({ChatVendor.anthropic: model}),
      tools,
      settings,
      choice,
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
            FakeChatModelRegistry({ChatVendor.anthropic: model}),
            tools,
            settings,
            choice,
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

          expect(firstEvents, const [ChatEvent.phase(ChatPhase.sending)]);
          expect(await second, const [
            ChatEvent.phase(ChatPhase.sending),
            ChatEvent.finished(citedEntryIds: []),
          ]);
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
      FakeChatModelRegistry({ChatVendor.anthropic: model}),
      tools,
      settings,
      choice,
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
      expect(events, const [ChatEvent.phase(ChatPhase.sending)]);
      expect(done, isTrue);
    });

    test('질문 구독을 첫 이벤트에서 끊어도 세션이 풀려 다음 ask 를 받는다', () async {
      final model = _HangingModel();
      final chat = hanging(model);
      late StreamSubscription<ChatEvent> sub;
      sub = chat.ask('첫').listen((_) => unawaited(sub.cancel()));
      await pumpEventQueue();

      final next = chat.ask('둘').toList();
      await pumpEventQueue();
      final round = model.rounds.last;
      round
        ..add(const ModelEvent.textDelta('네'))
        ..add(_done([_text('네')], StopKind.endTurn));
      unawaited(round.close());
      expect((await next).last, const ChatEvent.finished(citedEntryIds: []));
      expect(model.requests.last.last, const ChatMessage.user('둘'));
    });

    test('질문 구독을 글 도중에 끊으면 모델 구독도 끊는다', () async {
      final model = _HangingModel();
      final chat = hanging(model);
      late StreamSubscription<ChatEvent> sub;
      sub = chat.ask('첫').listen((e) {
        if (e is ChatText) unawaited(sub.cancel());
      });
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
        ChatEvent.phase(ChatPhase.sending),
        ChatEvent.phase(ChatPhase.writing),
        ChatEvent.text('새 답'),
        ChatEvent.finished(citedEntryIds: []),
      ]);
      expect(firstEvents, const [ChatEvent.phase(ChatPhase.sending)]);
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
        FakeChatModelRegistry({ChatVendor.anthropic: model}),
        tools,
        settings,
        choice,
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
      expect(events, const [ChatEvent.phase(ChatPhase.sending)]);
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
        ChatEvent.phase(ChatPhase.sending),
        ChatEvent.toolStarted(
          callId: 't1',
          name: 'view_entry_photos',
          input: ToolInputSummary(kind: ChatToolKind.viewPhotos),
        ),
        ChatEvent.toolFinished(
          callId: 't1',
          name: 'view_entry_photos',
          summary: ToolSummary(kind: ChatToolKind.viewPhotos, count: 0),
        ),
        ChatEvent.roundStarted(2),
        ChatEvent.toolStarted(
          callId: 't2',
          name: 'view_entry_photos',
          input: ToolInputSummary(kind: ChatToolKind.viewPhotos),
        ),
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
          const ChatEvent.phase(ChatPhase.sending),
          const ChatEvent.phase(ChatPhase.writing),
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
        ChatEvent.phase(ChatPhase.sending),
        ChatEvent.phase(ChatPhase.writing),
        ChatEvent.text('새 답'),
        ChatEvent.finished(citedEntryIds: []),
      ]);
      expect(firstEvents, const [
        ChatEvent.phase(ChatPhase.sending),
        ChatEvent.phase(ChatPhase.writing),
        ChatEvent.text('앞'),
      ]);
    });

    test('completed 를 받고 스트림이 닫히기 전에 멈춰도 그 라운드 사용량은 기록한다', () async {
      chat.ask('첫').listen((_) {});
      await pumpEventQueue();
      model.rounds[0]
        ..add(const ModelEvent.textDelta('글'))
        ..add(
          _done(
            [_text('글')],
            StopKind.endTurn,
            usage: const TokenUsage(inputTokens: 40, outputTokens: 5),
          ),
        );
      await pumpEventQueue();

      expect(
        chat.stop(),
        const ChatStopResult.kept(text: '글', citedEntryIds: []),
      );
      expect(usage.records.single.inputTokens, 40);
      expect(usage.records.single.round, 1);
    });

    test('kept 결과의 toString 에 받은 글이 없다', () {
      const result = ChatStopResult.kept(text: '비밀 답', citedEntryIds: ['e1']);
      expect(result.toString(), isNot(contains('비밀')));
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
      expect(result.text, '찾아볼게요. \n어제는 걸었어요');
    });
  });

  group('멈춤 호출 순서', () {
    late _HangingModel model;
    late ChatSession chat;

    setUp(() {
      model = _HangingModel();
      chat = ChatSession(
        FakeChatModelRegistry({ChatVendor.anthropic: model}),
        tools,
        settings,
        choice,
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

      expect(events, const [
        ChatEvent.phase(ChatPhase.sending),
        ChatEvent.phase(ChatPhase.writing),
        ChatEvent.text('부분'),
      ]);
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

  group('이어가기(resume)', () {
    ChatTurnText turn(String q, String a, {bool stopped = false}) =>
        ChatTurnText(question: q, answer: a, stopped: stopped);

    void expectTextOnly(List<ChatMessage> messages) {
      for (final m in messages) {
        switch (m) {
          case UserMessage():
            break;
          case AssistantMessage(:final parts, :final vendorState):
            expect(vendorState, isNull);
            expect(parts, hasLength(1));
            expect(parts.single, isA<TextPart>());
          case ToolResultsMessage():
            fail('도구 결과가 실리면 안 된다');
        }
      }
    }

    test('resume 뒤 첫 요청의 messages 는 user · assistant 글만이고 그 뒤 새 질문', () async {
      final model = _FakeModel([_answer('셋 답')]);
      final chat = session(model)
        ..resume([turn('하나', '하나 답'), turn('둘', '둘 답')], temporary: false);

      await chat.ask('셋').toList();

      final messages = model.requests.single.messages;
      expect(messages, [
        const ChatMessage.user('하나'),
        _assistant('하나 답'),
        const ChatMessage.user('둘'),
        _assistant('둘 답'),
        const ChatMessage.user('셋'),
      ]);
      expectTextOnly(messages);
    });

    test('멈춘 턴은 답 뒤에 stoppedNote 줄을 붙인다', () async {
      final model = _FakeModel([_answer('네')]);
      final chat = session(model)
        ..resume([turn('하나', '받은 글', stopped: true)], temporary: false);

      await chat.ask('둘').toList();

      expect(model.requests.single.messages, [
        const ChatMessage.user('하나'),
        _assistant('받은 글\n${ChatSession.stoppedNote}'),
        const ChatMessage.user('둘'),
      ]);
    });

    test('25턴을 넘기면 마지막 20턴만 싣는다', () async {
      expect(ChatSession.resumeTurns, 20);
      final model = _FakeModel([_answer('네')]);
      final chat = session(model)
        ..resume([
          for (var i = 0; i < 25; i++) turn('q$i', 'a$i'),
        ], temporary: false);

      await chat.ask('새').toList();

      final messages = model.requests.single.messages;
      expect(messages, hasLength(41));
      expect(messages.first, const ChatMessage.user('q5'));
      expect(messages[39], _assistant('a24'));
    });

    test('답이 빈 턴은 싣지 않는다', () async {
      final model = _FakeModel([_answer('네')]);
      final chat = session(model)
        ..resume([turn('하나', '  \n'), turn('둘', '둘 답')], temporary: false);

      await chat.ask('셋').toList();

      expect(model.requests.single.messages, [
        const ChatMessage.user('둘'),
        _assistant('둘 답'),
        const ChatMessage.user('셋'),
      ]);
    });

    test('resume 뒤 사진 수는 0부터 센다', () async {
      when(() => tools.run('view_entry_photos', any())).thenAnswer(
        (_) async => ToolResult(
          json: '{"photos":6}',
          images: [
            for (var i = 0; i < 6; i++)
              ToolImage(
                mediaType: 'image/jpeg',
                bytes: Uint8List.fromList([i]),
              ),
          ],
        ),
      );
      List<Object> photoRound(String id) => [
        _done([_toolUse(id, 'view_entry_photos')], StopKind.toolUse),
      ];
      final model = _FakeModel([
        photoRound('t1'),
        photoRound('t2'),
        _answer('첫 답'),
        photoRound('t3'),
        photoRound('t4'),
        _answer('둘째 답'),
      ]);
      final chat = session(model);

      await chat.ask('첫').toList();
      chat.resume([turn('첫', '첫 답')], temporary: false);
      await chat.ask('둘').toList();

      for (final i in [4, 5]) {
        final result = (model.requests[i].messages.last as ToolResultsMessage)
            .results
            .single;
        expect(result.isError, isFalse);
        expect(result.images, hasLength(6));
      }
    });

    test('답하는 중 resume 하면 그 질문은 조용히 멈추고 모델 구독이 취소된다', () async {
      final model = _HangingModel();
      final chat = ChatSession(
        FakeChatModelRegistry({ChatVendor.anthropic: model}),
        tools,
        settings,
        choice,
        clock,
        usage,
        ids,
        const NoopChatTrace(),
      );
      final events = <ChatEvent>[];
      var done = false;
      chat.ask('첫').listen(events.add, onDone: () => done = true);
      await pumpEventQueue();
      model.rounds[0].add(const ModelEvent.textDelta('늦은'));
      await pumpEventQueue();
      events.clear();

      chat.resume([turn('예전', '예전 답')], temporary: false);
      await pumpEventQueue();

      expect(model.cancelled.single, isTrue);
      expect(events, isEmpty);
      expect(done, isTrue);
      expect(chat.stop(), const ChatStopResult.idle());

      final second = chat.ask('둘').toList();
      await pumpEventQueue();
      model.rounds[1].add(_done([_text('새 답')], StopKind.endTurn));
      unawaited(model.rounds[1].close());
      expect(await second, const [
        ChatEvent.phase(ChatPhase.sending),
        ChatEvent.finished(citedEntryIds: []),
      ]);
      expect(model.requests[1], [
        const ChatMessage.user('예전'),
        _assistant('예전 답'),
        const ChatMessage.user('둘'),
      ]);
    });

    test(
      'resume(temporary: true) · reset(temporary: true) 뒤 사용량 기록은 temporary true · reset() 뒤엔 false',
      () async {
        const u = TokenUsage(inputTokens: 1, outputTokens: 1);
        final model = _FakeModel([])..repeat = _answerWith(u);
        final chat = session(model);

        expect(chat.temporary, isFalse);
        chat.resume([turn('하나', '답')], temporary: true);
        expect(chat.temporary, isTrue);
        await chat.ask('a').toList();
        chat.reset();
        expect(chat.temporary, isFalse);
        await chat.ask('b').toList();
        chat.reset(temporary: true);
        expect(chat.temporary, isTrue);
        await chat.ask('c').toList();
        chat.resume([turn('하나', '답')], temporary: false);
        await chat.ask('d').toList();

        expect(usage.records.map((r) => r.temporary), [
          true,
          false,
          true,
          false,
        ]);
      },
    );
  });

  group('벤더 · 모델 변경', () {
    /// openai 로 연결하고 openai 목록을 받아 둔 상태로 바꾼다.
    Future<void> switchToOpenAi() async {
      settings.vendor = ChatVendor.openai;
      await catalog.replace(ChatVendor.openai, [_info(_gpt, 3)], clock.value);
    }

    test('target 은 연결 벤더 · currentModel, 목록이 없으면 null', () async {
      final chat = session(_FakeModel([]));

      expect(chat.target, (vendor: ChatVendor.anthropic, model: _rec));
      settings.selectedModel = _opus;
      expect(chat.target, (vendor: ChatVendor.anthropic, model: _opus));

      await switchToOpenAi();
      expect(chat.target, (vendor: ChatVendor.openai, model: _gpt));

      await catalog.clear();
      expect(chat.target, isNull);

      settings.key = null;
      expect(chat.target, isNull);
    });

    test('요청 model 은 choice.currentModel, 어댑터는 연결 벤더의 것', () async {
      const u = TokenUsage(inputTokens: 1, outputTokens: 1);
      final claude = _FakeModel([]);
      final gpt = _FakeModel([_answerWith(u)])..vendor = ChatVendor.openai;
      await switchToOpenAi();

      await sessionOf({
        ChatVendor.anthropic: claude,
        ChatVendor.openai: gpt,
      }).ask('하이').toList();

      expect(claude.requests, isEmpty);
      expect(gpt.requests.single.model, _gpt);
      expect(usage.records.single.vendor, ChatVendor.openai);
      expect(usage.records.single.model, _gpt);
    });

    test('고른 모델이 없으면 추천 모델로 보낸다', () async {
      final model = _FakeModel([])..repeat = _answer('네');
      final chat = session(model);

      await chat.ask('하나').toList();
      settings.selectedModel = _opus;
      await chat.ask('둘').toList();
      // 목록에 없는 고른 모델 → 추천.
      settings.selectedModel = 'claude-gone-1';
      await chat.ask('셋').toList();

      expect(model.requests.map((r) => r.model), [_rec, _opus, _rec]);
    });

    test('목록이 없으면 요청 없이 noModels, 키가 없으면 noKey 가 먼저', () async {
      await catalog.clear();
      final model = _FakeModel([])..repeat = _answer('네');
      final chat = session(model);

      expect(await chat.ask('하이').toList(), const [
        ChatEvent.phase(ChatPhase.sending),
        ChatEvent.failed(ChatFailure.noModels),
      ]);
      expect(model.requests, isEmpty);

      settings.key = null;
      expect(await chat.ask('하이').toList(), const [
        ChatEvent.phase(ChatPhase.sending),
        ChatEvent.failed(ChatFailure.noKey),
      ]);

      // 질문은 문맥에 남지 않는다.
      settings.key = 'sk-ant-test-key';
      await catalog.replace(
        ChatVendor.anthropic,
        _anthropicModels,
        clock.value,
      );
      await chat.ask('다음').toList();
      expect(model.requests.single.messages, const [ChatMessage.user('다음')]);
    });

    test('fastMode 는 choice.fastModeOn 그대로', () async {
      const u = TokenUsage(inputTokens: 1, outputTokens: 1);
      final model = _FakeModel([])..repeat = _answerWith(u);
      final chat = session(model);
      settings.fastMode = true;

      // 켜짐 + 지원 안 함(추천 sonnet) → false.
      await chat.ask('하나').toList();
      // 켜짐 + 지원(opus) → true.
      settings.selectedModel = _opus;
      await chat.ask('둘').toList();
      // 꺼짐 + 지원 → false.
      settings.fastMode = false;
      await chat.ask('셋').toList();

      expect(model.requests.map((r) => r.fastMode), [false, true, false]);
      expect(usage.records.map((r) => r.fastMode), [false, true, false]);
    });

    group('사진 못 보는 모델', () {
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

      List<ToolResultsMessage> resultsOf(ModelRequest request) =>
          request.messages.whereType<ToolResultsMessage>().toList();

      test(
        'tools 에 view_entry_photos 가 없고 이전 사진이 요청에서 빠졌다가, 사진 되는 모델로 돌아오면 다시 실린다',
        () async {
          when(
            () => tools.run('view_entry_photos', any()),
          ).thenAnswer((_) async => photos(2));
          final model = _FakeModel([photoRound('t1'), _answer('사진 답')])
            ..repeat = _answer('네');
          final chat = session(model);

          await chat.ask('하나').toList();
          settings.selectedModel = _haiku;
          await chat.ask('둘').toList();
          settings.selectedModel = null;
          await chat.ask('셋').toList();

          expect(
            resultsOf(model.requests[1]).single.results.single.images,
            hasLength(2),
          );

          final second = model.requests[2];
          expect(second.model, _haiku);
          expect(identical(second.tools, noImageDefinitions), isTrue);
          final stripped = resultsOf(second).single.results.single;
          expect(stripped.images, isEmpty);
          expect(stripped.json, '{"photos":2}');
          expect(stripped.callId, 't1');

          final third = model.requests[3];
          expect(third.model, _rec);
          expect(identical(third.tools, definitions), isTrue);
          expect(resultsOf(third).single.results.single.images, hasLength(2));
        },
      );

      test('사진 못 보는 모델에선 사진 수가 늘지 않는다', () async {
        when(
          () => tools.run('view_entry_photos', any()),
        ).thenAnswer((_) async => photos(6));
        settings.selectedModel = _haiku;
        final model = _FakeModel([
          // 못 보는 모델이 그래도 부른 사진(18장) — 세지도, 싣지도 않는다.
          photoRound('a1'),
          photoRound('a2'),
          photoRound('a3'),
          _answer('하나 답'),
          // 사진 되는 모델로 12장 — 한도 안.
          photoRound('b1'),
          photoRound('b2'),
          _answer('둘 답'),
        ]);
        final chat = session(model);

        await chat.ask('하나').toList();
        for (final i in [1, 2, 3]) {
          final result = resultsOf(model.requests[i]).last.results.single;
          expect(result.isError, isFalse);
          expect(result.images, isEmpty);
        }

        settings.selectedModel = null;
        await chat.ask('둘').toList();
        for (final i in [5, 6]) {
          final result = resultsOf(model.requests[i]).last.results.single;
          expect(result.isError, isFalse, reason: '$i');
          expect(result.images, hasLength(6));
        }
      });

      test('imagesUnsupported 면 markNoImages 하고 사진 없이 한 번 다시 보낸다', () async {
        when(
          () => tools.run('view_entry_photos', any()),
        ).thenAnswer((_) async => photos(2));
        final model = _FakeModel([
          photoRound('t1'),
          [const ChatModelException(ChatModelErrorKind.imagesUnsupported)],
          _answer('사진 없이 답'),
        ]);

        final events = await session(model).ask('사진').toList();

        expect(events.last, const ChatEvent.finished(citedEntryIds: []));
        expect(catalog.noImages, {_rec});
        expect(model.requests, hasLength(3));
        expect(
          resultsOf(model.requests[1]).single.results.single.images,
          hasLength(2),
        );
        final retry = model.requests[2];
        expect(retry.model, _rec);
        expect(identical(retry.tools, noImageDefinitions), isTrue);
        expect(resultsOf(retry).single.results.single.images, isEmpty);
      });

      test('다시 보낸 것도 imagesUnsupported 면 unknown', () async {
        when(
          () => tools.run('view_entry_photos', any()),
        ).thenAnswer((_) async => photos(2));
        final model = _FakeModel([
          photoRound('t1'),
          [const ChatModelException(ChatModelErrorKind.imagesUnsupported)],
          [const ChatModelException(ChatModelErrorKind.imagesUnsupported)],
          _answer('안 옴'),
        ]);

        final events = await session(model).ask('사진').toList();

        expect(events.last, const ChatEvent.failed(ChatFailure.unknown));
        expect(model.requests, hasLength(3));
      });
    });

    group('modelUnavailable', () {
      test('목록을 다시 받아 모델이 바뀌면 modelReplaced', () async {
        settings.selectedModel = _opus;
        verifier.stored = (
          ChatVendor.anthropic,
          ModelListResult.ok([_info(_rec, 5), _info(_haiku, 1)]),
        );
        final model = _FakeModel([
          [const ChatModelException(ChatModelErrorKind.modelUnavailable)],
          _answer('네'),
        ]);
        final chat = session(model);

        expect(await chat.ask('하나').toList(), const [
          ChatEvent.phase(ChatPhase.sending),
          ChatEvent.failed(ChatFailure.modelReplaced),
        ]);
        expect(verifier.fetchStoredCalls, 1);
        expect(chat.target?.model, _rec);

        await chat.ask('둘').toList();
        expect(model.requests[1].model, _rec);
        expect(model.requests[1].messages, const [ChatMessage.user('둘')]);
      });

      test('다시 받아도 같은 모델이면 modelUnavailable', () async {
        settings.selectedModel = _opus;
        final model = _FakeModel([
          [const ChatModelException(ChatModelErrorKind.modelUnavailable)],
        ]);

        expect(await session(model).ask('하나').toList(), const [
          ChatEvent.phase(ChatPhase.sending),
          ChatEvent.failed(ChatFailure.modelUnavailable),
        ]);
        expect(verifier.fetchStoredCalls, 1);
      });

      test('다시 받지 못하면 modelUnavailable', () async {
        verifier.stored = (
          ChatVendor.anthropic,
          const ModelListResult.unreachable(),
        );
        final model = _FakeModel([
          [const ChatModelException(ChatModelErrorKind.modelUnavailable)],
        ]);

        expect(await session(model).ask('하나').toList(), const [
          ChatEvent.phase(ChatPhase.sending),
          ChatEvent.failed(ChatFailure.modelUnavailable),
        ]);
      });
    });

    test('시스템 프롬프트에 사진 도구가 없을 때의 안내 줄이 있다', () async {
      final model = _FakeModel([_answer('네')]);

      await session(model).ask('하이').toList();

      expect(
        model.requests.single.system,
        contains('사진 보기 도구가 없으면 사진은 볼 수 없다고 짧게 답한다'),
      );
    });

    test('벤더가 바뀌면 다음 ask 전에 메모리 문맥을 글로 접는다', () async {
      when(
        () => tools.run('search_diary', any()),
      ).thenAnswer((_) async => const ToolResult(json: '{}'));
      const u = TokenUsage(inputTokens: 1, outputTokens: 1);
      final claude = _FakeModel([
        [
          const ModelEvent.textDelta('찾아볼게요.'),
          _done(
            [_text('찾아볼게요.'), _toolUse('t1', 'search_diary')],
            StopKind.toolUse,
            state: _FakeState(),
          ),
        ],
        [
          const ModelEvent.textDelta('답'),
          _done([_text('답')], StopKind.endTurn, state: _FakeState()),
        ],
      ]);
      final gpt = _FakeModel([_answerWith(u)])..vendor = ChatVendor.openai;
      final chat = sessionOf({
        ChatVendor.anthropic: claude,
        ChatVendor.openai: gpt,
      });

      await chat.ask('q1').toList();
      await switchToOpenAi();
      await chat.ask('q2').toList();

      expect(gpt.requests.single.messages, [
        const ChatMessage.user('q1'),
        _assistant('찾아볼게요.\n\n답'),
        const ChatMessage.user('q2'),
      ]);
      expect(usage.records.single.vendor, ChatVendor.openai);
    });

    test('벤더 · 모델이 그대로면 문맥을 접지 않는다', () async {
      final completed =
          _done([_text('답')], StopKind.endTurn, state: _FakeState())
              as ModelCompleted;
      final model = _FakeModel([
        [const ModelEvent.textDelta('답'), completed],
        _answer('둘 답'),
      ]);
      final chat = session(model);

      await chat.ask('q1').toList();
      await chat.ask('q2').toList();

      expect(
        identical(model.requests[1].messages[1], completed.message),
        isTrue,
      );
    });

    test('모델만 바뀌면 문맥을 접지 않는다', () async {
      when(
        () => tools.run('search_diary', any()),
      ).thenAnswer((_) async => const ToolResult(json: '{}'));
      final toolTurn =
          _done(
                [_text('찾아볼게요.'), _toolUse('t1', 'search_diary')],
                StopKind.toolUse,
                state: _FakeState(),
              )
              as ModelCompleted;
      final answer =
          _done([_text('답')], StopKind.endTurn, state: _FakeState())
              as ModelCompleted;
      final model = _FakeModel([
        [toolTurn],
        [const ModelEvent.textDelta('답'), answer],
        _answer('둘 답'),
      ]);
      final chat = session(model);

      await chat.ask('q1').toList();
      settings.selectedModel = _opus;
      await chat.ask('q2').toList();

      final second = model.requests[2];
      expect(second.model, _opus);
      expect(second.messages, hasLength(5));
      expect(identical(second.messages[1], toolTurn.message), isTrue);
      expect(second.messages[2], isA<ToolResultsMessage>());
      expect(identical(second.messages[3], answer.message), isTrue);
    });

    test('멈춘 턴이 있는 문맥을 접어도 멈춤 표시가 남는다', () async {
      final model = _HangingModel();
      final gpt = _FakeModel([_answer('셋 답')])..vendor = ChatVendor.openai;
      final chat = ChatSession(
        FakeChatModelRegistry({
          ChatVendor.anthropic: model,
          ChatVendor.openai: gpt,
        }),
        tools,
        settings,
        choice,
        clock,
        usage,
        ids,
        const NoopChatTrace(),
      );

      // 1: 멈춘 턴
      chat.ask('q1').listen((_) {});
      await pumpEventQueue();
      model.rounds[0].add(const ModelEvent.textDelta('받은 글'));
      await pumpEventQueue();
      expect(chat.stop(), isA<ChatStopKept>());

      // 2: 끝난 턴(vendorState 있음)
      final second = chat.ask('q2').toList();
      await pumpEventQueue();
      model.rounds[1]
        ..add(const ModelEvent.textDelta('둘 답'))
        ..add(_done([_text('둘 답')], StopKind.endTurn, state: _FakeState()));
      unawaited(model.rounds[1].close());
      await second;

      await switchToOpenAi();
      await chat.ask('q3').toList();

      expect(gpt.requests.single.messages, [
        const ChatMessage.user('q1'),
        _assistant('받은 글\n${ChatSession.stoppedNote}'),
        const ChatMessage.user('q2'),
        _assistant('둘 답'),
        const ChatMessage.user('q3'),
      ]);
    });
  });
}

/// [gate] 가 있으면 키 읽기가 그 future 를 기다린다.
class _GatedKeySettings extends FakeChatSettings {
  _GatedKeySettings(super.key);

  Future<void>? gate;

  @override
  Future<String?> apiKey() async {
    final wait = gate;
    if (wait != null) await wait;
    return super.apiKey();
  }
}

class _GatedModel implements ChatModel {
  @override
  bool get progressNotes => false;

  _GatedModel(this.gate);

  final Future<void> gate;
  final requests = <List<ChatMessage>>[];

  @override
  Future<ModelListResult> listModels(String apiKey) async =>
      const ModelListResult.ok([]);

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
  @override
  bool get progressNotes => false;

  final calls = <Completer<ModelEvent>>[];
  final requests = <List<ChatMessage>>[];

  @override
  Future<ModelListResult> listModels(String apiKey) async =>
      const ModelListResult.ok([]);

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
  @override
  bool get progressNotes => false;

  final rounds = <StreamController<ModelEvent>>[];
  final cancelled = <bool>[];
  final requests = <List<ChatMessage>>[];

  @override
  Future<ModelListResult> listModels(String apiKey) async =>
      const ModelListResult.ok([]);

  @override
  var vendor = ChatVendor.anthropic;

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
