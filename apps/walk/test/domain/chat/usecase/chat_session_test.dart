import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/tool/life_tools.dart';
import 'package:walk/domain/chat/tool/tool_result.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';

import '../../../presentation/settings/cubit/chat_settings_cubit_test.dart'
    show FakeChatSettings;

class _MockLifeTools extends Mock implements LifeTools {}

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
  final requests = <_Request>[];

  /// 준비된 라운드를 다 쓰면 이 라운드를 되풀이한다.
  List<Object>? repeat;

  @override
  Stream<ModelEvent> stream({
    required String apiKey,
    required String system,
    required List<Map<String, Object?>> messages,
    required List<Map<String, Object?>> tools,
  }) async* {
    final index = requests.length;
    requests.add(_Request(apiKey, system, messages, tools));
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

class _Request {
  _Request(this.apiKey, this.system, this.messages, this.tools);

  final String apiKey;
  final String system;
  final List<Map<String, Object?>> messages;
  final List<Map<String, Object?>> tools;
}

ModelEvent _done(List<Map<String, Object?>> content, String stop) =>
    ModelEvent.completed(content: content, stopReason: stop);

Map<String, Object?> _textBlock(String text) => {'type': 'text', 'text': text};

Map<String, Object?> _toolUse(String id, String name, [Map? input]) => {
  'type': 'tool_use',
  'id': id,
  'name': name,
  'input': input ?? <String, Object?>{},
};

List<Object> _answer(String text) => [
  ModelEvent.textDelta(text),
  _done([_textBlock(text)], 'end_turn'),
];

void main() {
  late _MockLifeTools tools;
  late FakeChatSettings settings;
  final clock = _FixedClock(DateTime(2026, 10, 27, 9));
  final definitions = [
    {'name': 'search_diary'},
  ];

  setUpAll(() async {
    await initializeDateFormatting('ko');
    registerFallbackValue(<String, Object?>{});
  });

  setUp(() {
    tools = _MockLifeTools();
    when(() => tools.definitions).thenReturn(definitions);
    settings = FakeChatSettings('sk-ant-test-key');
  });

  ChatSession session(_FakeModel model) =>
      ChatSession(model, tools, settings, clock);

  test('도구 없이 끝나면 text 를 흘리고 finished', () async {
    final model = _FakeModel([
      [
        const ModelEvent.textDelta('안'),
        const ModelEvent.textDelta('녕'),
        _done([_textBlock('안녕')], 'end_turn'),
      ],
    ]);

    final events = await session(model).ask('하이').toList();

    expect(events, const [
      ChatEvent.text('안'),
      ChatEvent.text('녕'),
      ChatEvent.finished(citedEntryIds: []),
    ]);
    expect(model.requests.single.messages, [
      {'role': 'user', 'content': '하이'},
    ]);
    expect(model.requests.single.apiKey, 'sk-ant-test-key');
    expect(model.requests.single.tools, definitions);
  });

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
          ], 'tool_use'),
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
      final last = model.requests[1].messages.last;
      expect(last['role'], 'user');
      final results = last['content']! as List;
      expect(results, [
        {
          'type': 'tool_result',
          'tool_use_id': 'tu_1',
          'is_error': false,
          'content': [
            {'type': 'text', 'text': '{"a":1}'},
          ],
        },
        {
          'type': 'tool_result',
          'tool_use_id': 'tu_2',
          'is_error': true,
          'content': [
            {'type': 'text', 'text': '{"error":"x"}'},
          ],
        },
      ]);
      expect(model.requests[1].messages, hasLength(3));
    },
  );

  test('이미지가 있는 결과는 base64 image 블록을 붙인다', () async {
    when(() => tools.run('view_entry_photos', any())).thenAnswer(
      (_) async => ToolResult(
        json: '{"photos":1}',
        images: [
          ToolImage(
            mediaType: 'image/jpeg',
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
        ],
      ),
    );
    final model = _FakeModel([
      [
        _done([_toolUse('tu_1', 'view_entry_photos')], 'tool_use'),
      ],
      _answer('사진'),
    ]);

    await session(model).ask('사진').toList();

    final result = (model.requests[1].messages.last['content']! as List).single;
    expect((result as Map)['content'], [
      {'type': 'text', 'text': '{"photos":1}'},
      {
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': 'image/jpeg',
          'data': 'AQID',
        },
      },
    ]);
  });

  test('assistant content(thinking 포함)를 바꾸지 않고 다음 요청에 보낸다', () async {
    when(
      () => tools.run(any(), any()),
    ).thenAnswer((_) async => const ToolResult(json: '{}'));
    final content = [
      {'type': 'thinking', 'thinking': '생각', 'signature': 'sig=='},
      _textBlock('찾아볼게요'),
      _toolUse('tu_1', 'search_diary'),
    ];
    final model = _FakeModel([
      [_done(content, 'tool_use')],
      _answer('끝'),
    ]);

    await session(model).ask('질문').toList();

    expect(model.requests[1].messages[1], {
      'role': 'assistant',
      'content': content,
    });
  });

  test('citedEntryIds 는 중복 없이 처음 나온 순서', () async {
    when(() => tools.run('a', any())).thenAnswer(
      (_) async => const ToolResult(json: '{}', entryIds: ['e2', 'e1']),
    );
    when(() => tools.run('b', any())).thenAnswer(
      (_) async => const ToolResult(json: '{}', entryIds: ['e1', 'e3']),
    );
    final model = _FakeModel([
      [
        _done([_toolUse('t1', 'a'), _toolUse('t2', 'b')], 'tool_use'),
      ],
      [
        _done([_toolUse('t3', 'a')], 'tool_use'),
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
          _done([_toolUse('t1', 'search_diary')], 'tool_use'),
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
        {'role': 'user', 'content': '첫 질문'},
        {
          'role': 'assistant',
          'content': [_textBlock('첫 답')],
        },
        {'role': 'user', 'content': '셋째 질문'},
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
      expect(model.requests.last.messages, [
        {'role': 'user', 'content': '다시 질문'},
      ]);
    },
  );

  test('server 오류는 unknown, 그 밖의 예외도 unknown', () async {
    final model = _FakeModel([
      [const ChatModelException(ChatModelErrorKind.server)],
      [StateError('boom')],
    ]);
    final chat = session(model);

    expect(
      (await chat.ask('a').toList()).last,
      const ChatEvent.failed(ChatFailure.unknown),
    );
    expect(
      (await chat.ask('b').toList()).last,
      const ChatEvent.failed(ChatFailure.unknown),
    );
  });

  test('refusal 은 refused', () async {
    final model = _FakeModel([
      [
        _done([_textBlock('')], 'refusal'),
      ],
      _answer('다음'),
    ]);
    final chat = session(model);

    final events = await chat.ask('질문').toList();
    await chat.ask('다음 질문').toList();

    expect(events.last, const ChatEvent.failed(ChatFailure.refused));
    expect(model.requests.last.messages, [
      {'role': 'user', 'content': '다음 질문'},
    ]);
  });

  test('8라운드를 넘기면 tooManySteps', () async {
    when(
      () => tools.run(any(), any()),
    ).thenAnswer((_) async => const ToolResult(json: '{}'));
    final model = _FakeModel([])
      ..repeat = [
        _done([_toolUse('t', 'search_diary')], 'tool_use'),
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
    final chat = ChatSession(model, tools, settings, clock);

    final first = chat.ask('첫').toList();
    expect(() => chat.ask('둘'), throwsStateError);
    gate.complete();
    await first;

    chat.reset();
    await chat.ask('셋').toList();
    expect(model.requests.last, [
      {'role': 'user', 'content': '셋'},
    ]);
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
  final requests = <List<Map<String, Object?>>>[];

  @override
  Stream<ModelEvent> stream({
    required String apiKey,
    required String system,
    required List<Map<String, Object?>> messages,
    required List<Map<String, Object?>> tools,
  }) async* {
    requests.add(messages);
    await gate;
    yield _done([_textBlock('ok')], 'end_turn');
  }
}
