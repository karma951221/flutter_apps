import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_trace.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/tool/life_tools.dart';
import 'package:walk/domain/chat/tool/tool_result.dart';
import 'package:walk/domain/chat/tool/tool_summary.dart';
import 'package:walk/domain/chat/tool/wiki_tools.dart';
import 'package:walk/domain/chat/tool/workspace_tools.dart';
import 'package:walk/domain/chat/tool/write_plan.dart';
import 'package:walk/domain/chat/usecase/chat_model_choice.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/chat/wiki/wiki_context_policy.dart';

import '../../../support/fake_chat_key_verifier.dart';
import '../../../support/fake_chat_model_catalog.dart';
import '../../../support/fake_chat_model_registry.dart';
import '../../../support/fake_chat_settings.dart';
import '../../../support/fake_chat_usage_log.dart';
import '../../../support/recording_chat_trace.dart';

// 가짜 모델 · 도구 준비는 chat_session_workspace_tools_test.dart 와 같다.

class _MockLifeTools extends Mock implements LifeTools {}

class _MockWikiTools extends Mock implements WikiTools {}

class _MockWorkspaceTools extends Mock implements WorkspaceTools {}

class _NoWiki implements WikiContextPolicy {
  @override
  Future<WikiContext> build({required String question}) async =>
      WikiContext.none;
}

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

  @override
  bool progressNotes = false;

  final List<List<ModelEvent>> rounds;
  final requests = <ModelRequest>[];

  @override
  Future<ModelListResult> listModels(String apiKey) async =>
      const ModelListResult.ok([]);

  @override
  var vendor = ChatVendor.anthropic;

  @override
  Stream<ModelEvent> stream(ModelRequest request) async* {
    final index = requests.length;
    requests.add(request);
    for (final item in rounds[index]) {
      yield item;
    }
  }
}

ModelEvent _done(List<AssistantPart> parts, StopKind stop) =>
    ModelEvent.completed(
      message: AssistantMessage(parts: parts),
      stop: stop,
      usage: null,
    );

List<ModelEvent> _answer(String text) => [
  ModelEvent.textDelta(text),
  _done([AssistantPart.text(text)], StopKind.endTurn),
];

AssistantPart _write(String id, [String path = 'out/a.md']) =>
    AssistantPart.toolCall(
      id: id,
      name: 'write_file',
      input: {'path': path, 'content': '내용'},
    );

AssistantPart _read(String id) => AssistantPart.toolCall(
  id: id,
  name: 'read_file',
  input: const {'path': 'inbox/a.md'},
);

List<ModelEvent> _calls(List<AssistantPart> parts) => [
  _done(parts, StopKind.toolUse),
];

ModelInfo _info(String id, int day) =>
    ModelInfo(id: id, displayName: id, createdAt: DateTime.utc(2026, 1, day));

const _rec = 'claude-sonnet-9-5';

const _workspaceLine =
    '작업 폴더(inbox: 사용자가 첨부한 파일, out: 저장한 답)에 있는 파일은 list_files 로 '
    '찾고 read_file 로 읽는다. 사용자가 파일을 말하면 먼저 list_files 로 경로를 확인한다. '
    '이번 질문에 첨부된 파일은 이미 보고 있으니 다시 읽지 않는다.';

const _writeLine =
    'out 에 파일을 만들거나(write_file) 고치거나(edit_file) 지울(delete_file) 수 있다. '
    '사용자가 질문에서 요청했을 때만 쓰고, 쓰기마다 사용자가 승인한다. 거절되면 같은 쓰기를 '
    '다시 시도하지 말고 답에서 알린다. inbox 의 원본은 바꾸지 않고, 고친 판은 out 에 새로 만든다.';

const _planA = WritePlan.create(path: 'out/a.md', name: 'a.md', content: '내용');
const _planB = WritePlan.create(path: 'out/b.md', name: 'b.md', content: '내용');

const _okJson = '{"path":"out/a.md","name":"a.md","chars":2,"created":true}';
const _ok = ToolResult(
  json: _okJson,
  summary: ToolSummary(kind: ChatToolKind.writeFile, count: 1),
);
const _declinedJson = '{"error":"user_declined"}';
const _declined = ToolResult(
  json: _declinedJson,
  isError: true,
  summary: ToolSummary(
    kind: ChatToolKind.writeFile,
    count: 0,
    isError: true,
    declined: true,
  ),
);

/// 마지막 요청의 마지막 도구 결과들.
List<ToolResultPart> _lastResults(ModelRequest request) =>
    (request.messages.last as ToolResultsMessage).results;

void main() {
  late _MockLifeTools tools;
  late _MockWorkspaceTools workspace;
  late FakeChatSettings settings;
  late ChatModelChoice choice;
  final clock = _FixedClock(DateTime(2026, 11, 14, 9));
  const definitions = [
    ToolSpec(name: 'search_diary', description: 'd', parameters: {}),
  ];
  const readDefinitions = [
    ToolSpec(name: 'list_files', description: 'd', parameters: {}),
    ToolSpec(name: 'read_file', description: 'd', parameters: {}),
  ];
  const writeDefinitions = [
    ToolSpec(name: 'write_file', description: 'd', parameters: {}),
    ToolSpec(name: 'edit_file', description: 'd', parameters: {}),
    ToolSpec(name: 'delete_file', description: 'd', parameters: {}),
  ];

  setUpAll(() async {
    await initializeDateFormatting('ko');
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(_planA);
  });

  setUp(() async {
    tools = _MockLifeTools();
    when(
      () => tools.definitionsFor(images: any(named: 'images')),
    ).thenReturn(definitions);
    when(() => tools.inputSummary(any(), any())).thenAnswer(
      (i) => ToolInputSummary(
        kind: chatToolKindOf(i.positionalArguments[0] as String),
      ),
    );
    workspace = _MockWorkspaceTools();
    when(() => workspace.definitions).thenReturn(readDefinitions);
    when(() => workspace.writeDefinitions).thenReturn(writeDefinitions);
    when(
      () => workspace.prepareWrite(any(), any()),
    ).thenAnswer((_) async => _planA);
    when(() => workspace.apply(any())).thenAnswer((_) async => _ok);
    when(() => workspace.declined(any())).thenReturn(_declined);
    when(() => workspace.run('read_file', any())).thenAnswer(
      (_) async => const ToolResult(
        json: '{"path":"inbox/a.md","name":"a.md","text":"x"}',
        summary: ToolSummary(kind: ChatToolKind.readFile, count: 1),
      ),
    );
    settings = FakeChatSettings('sk-ant-test-key');
    final catalog = FakeChatModelCatalog();
    final models = [_info(_rec, 5)];
    await catalog.replace(ChatVendor.anthropic, models, clock.value);
    final verifier = FakeChatKeyVerifier()
      ..stored = (ChatVendor.anthropic, ModelListResult.ok(models));
    choice = ChatModelChoice(settings, catalog, verifier, clock);
  });

  ChatSession session(ChatModel model, {ChatTrace? trace}) => ChatSession(
    FakeChatModelRegistry({ChatVendor.anthropic: model}),
    tools,
    settings,
    choice,
    clock,
    FakeChatUsageLog(),
    _SeqIds(),
    trace ?? const NoopChatTrace(),
    _NoWiki(),
    _MockWikiTools(),
    workspace,
  );

  /// 질문을 듣기 시작한다. events 는 받은 차례, done 은 스트림이 끝나면 끝난다.
  ({List<ChatEvent> events, Future<void> done}) listen(
    ChatSession chat,
    String question,
  ) {
    final events = <ChatEvent>[];
    final done = Completer<void>();
    chat.ask(question).listen(events.add, onDone: done.complete);
    return (events: events, done: done.future);
  }

  group('도구 목록', () {
    test('기록 켜짐이면 읽기 둘 뒤에 write_file · edit_file · delete_file', () async {
      final model = _FakeModel([_answer('네')]);

      await session(model).ask('질문').toList();

      expect(model.requests.single.tools.map((t) => t.name), [
        'search_diary',
        'list_files',
        'read_file',
        'write_file',
        'edit_file',
        'delete_file',
      ]);
    });

    test('기록 꺼짐이면 없고, 지난 턴을 보고 불러도 준비하지 않는다', () async {
      final model = _FakeModel([
        _calls([_write('w1')]),
        _answer('못 써요'),
      ]);
      final chat = session(model)..useRecords = false;

      final events = await chat.ask('저장해').toList();

      expect(model.requests.first.tools, isEmpty);
      verifyNever(() => workspace.prepareWrite(any(), any()));
      verifyNever(() => workspace.apply(any()));
      expect(events.whereType<ChatApprovalRequested>(), isEmpty);
      final result = _lastResults(model.requests[1]).single;
      expect(result.isError, isTrue);
      expect(result.json, contains('records_off'));
    });
  });

  group('승인', () {
    test(
      '승인하면 approvalRequested → approvalClosed → apply → toolFinished',
      () async {
        final model = _FakeModel([
          _calls([_write('w1')]),
          _answer('저장했어요'),
        ]);
        final chat = session(model);

        final run = listen(chat, '저장해');
        await pumpEventQueue();

        expect(
          run.events.last,
          const ChatEvent.approvalRequested(callId: 'w1', plan: _planA),
        );
        verify(() => workspace.prepareWrite('write_file', any())).called(1);
        verifyNever(() => workspace.apply(any()));
        expect(model.requests, hasLength(1));

        chat.decide('w1', true);
        await run.done;

        verify(() => workspace.apply(_planA)).called(1);
        final tail = run.events
            .skipWhile((e) => e is! ChatApprovalRequested)
            .where((e) => e is! ChatText && e is! ChatPhaseChanged)
            .take(3)
            .toList();
        expect(tail, [
          const ChatEvent.approvalRequested(callId: 'w1', plan: _planA),
          const ChatEvent.approvalClosed(callId: 'w1'),
          ChatEvent.toolFinished(
            callId: 'w1',
            name: 'write_file',
            summary: _ok.summary!,
          ),
        ]);
        final result = _lastResults(model.requests[1]).single;
        expect(result.callId, 'w1');
        expect(result.isError, isFalse);
        expect(result.json, _okJson);
        expect(run.events.last, isA<ChatFinished>());
      },
    );

    test('거절하면 apply 하지 않고 user_declined', () async {
      final model = _FakeModel([
        _calls([_write('w1')]),
        _answer('알겠어요'),
      ]);
      final chat = session(model);

      final run = listen(chat, '저장해');
      await pumpEventQueue();
      chat.decide('w1', false);
      await run.done;

      verifyNever(() => workspace.apply(any()));
      verify(() => workspace.declined('write_file')).called(1);
      final result = _lastResults(model.requests[1]).single;
      expect(result.isError, isTrue);
      expect(result.json, _declinedJson);
      expect(
        run.events,
        contains(
          ChatEvent.toolFinished(
            callId: 'w1',
            name: 'write_file',
            summary: _declined.summary!,
          ),
        ),
      );
    });

    test('엉뚱한 callId 로 decide 하면 무시하고 계속 기다린다', () async {
      final model = _FakeModel([
        _calls([_write('w1')]),
        _answer('네'),
      ]);
      final chat = session(model);

      final run = listen(chat, '저장해');
      await pumpEventQueue();
      chat.decide('other', true);
      await pumpEventQueue();

      verifyNever(() => workspace.apply(any()));
      expect(run.events.whereType<ChatApprovalClosed>(), isEmpty);
      expect(model.requests, hasLength(1));

      chat.decide('w1', true);
      await run.done;
      verify(() => workspace.apply(_planA)).called(1);
    });

    test('prepare 오류는 승인 이벤트 없이 바로 결과', () async {
      const invalid = ToolResult(
        json: '{"error":"invalid_path"}',
        isError: true,
        summary: ToolSummary(
          kind: ChatToolKind.writeFile,
          count: 0,
          isError: true,
        ),
      );
      when(
        () => workspace.prepareWrite(any(), any()),
      ).thenAnswer((_) async => invalid);
      final model = _FakeModel([
        _calls([_write('w1', 'out/x.exe')]),
        _answer('못 써요'),
      ]);

      final events = await session(model).ask('저장해').toList();

      expect(events.whereType<ChatApprovalRequested>(), isEmpty);
      expect(events.whereType<ChatApprovalClosed>(), isEmpty);
      verifyNever(() => workspace.apply(any()));
      final result = _lastResults(model.requests[1]).single;
      expect(result.isError, isTrue);
      expect(result.json, '{"error":"invalid_path"}');
    });

    test('트레이스 toolEnd 에 쓰기는 이름과 승인 여부만', () async {
      final trace = RecordingChatTrace();
      final model = _FakeModel([
        _calls([_write('w1'), _write('w2', 'out/b.md')]),
        _answer('네'),
      ]);
      when(
        () => workspace.prepareWrite('write_file', {
          'path': 'out/b.md',
          'content': '내용',
        }),
      ).thenAnswer((_) async => _planB);
      final chat = session(model, trace: trace);

      final run = listen(chat, '저장해');
      await pumpEventQueue();
      chat.decide('w1', true);
      await pumpEventQueue();
      chat.decide('w2', false);
      await run.done;

      expect(trace.dataOf(ChatTraceMark.toolEnd), [
        {'tool': 'write_file', 'approved': true},
        {'tool': 'write_file', 'approved': false},
      ]);
    });
  });

  group('기다리는 중 세대가 바뀌면', () {
    test('stop() → apply 하지 않고 스트림이 끝나며 다음 ask 는 정상', () async {
      final model = _FakeModel([
        _calls([_write('w1')]),
        _answer('다음 답'),
      ]);
      final chat = session(model);

      final run = listen(chat, '저장해');
      await pumpEventQueue();
      expect(run.events.last, isA<ChatApprovalRequested>());

      expect(chat.stop(), const ChatStopResult.dropped());
      await run.done;

      verifyNever(() => workspace.apply(any()));
      verifyNever(() => workspace.declined(any()));
      expect(model.requests, hasLength(1));
      // 끝난 기다림에 늦게 온 decide 는 무시된다.
      chat.decide('w1', true);
      await pumpEventQueue();
      verifyNever(() => workspace.apply(any()));

      final next = await chat.ask('다음').toList();
      expect(next.last, isA<ChatFinished>());
      expect(model.requests, hasLength(2));
    });

    test('reset() → apply 하지 않고 스트림이 끝나며 다음 ask 는 정상', () async {
      final model = _FakeModel([
        _calls([_write('w1')]),
        _answer('새 대화'),
      ]);
      final chat = session(model);

      final run = listen(chat, '저장해');
      await pumpEventQueue();
      expect(run.events.last, isA<ChatApprovalRequested>());

      chat.reset();
      await run.done;

      verifyNever(() => workspace.apply(any()));
      final next = await chat.ask('다음').toList();
      expect(next.last, isA<ChatFinished>());
    });

    test('decide(id, true) 와 같은 틱에 stop() → apply 하지 않는다', () async {
      final model = _FakeModel([
        _calls([_write('w1')]),
        _answer('네'),
      ]);
      final chat = session(model);

      final run = listen(chat, '저장해');
      await pumpEventQueue();
      chat.decide('w1', true);
      chat.stop();
      await run.done;

      verifyNever(() => workspace.apply(any()));
      expect(model.requests, hasLength(1));
    });
  });

  test('쓰기 둘 + 읽기 하나: 읽기는 먼저 끝나고 승인은 하나씩, 결과는 호출 순서', () async {
    when(
      () => workspace.prepareWrite('write_file', {
        'path': 'out/b.md',
        'content': '내용',
      }),
    ).thenAnswer((_) async => _planB);
    final model = _FakeModel([
      _calls([_write('w1'), _read('r1'), _write('w2', 'out/b.md')]),
      _answer('네'),
    ]);
    final chat = session(model);

    final run = listen(chat, '둘 다 저장해');
    await pumpEventQueue();

    final firstApproval = run.events.indexWhere(
      (e) => e is ChatApprovalRequested,
    );
    final readDone = run.events.indexWhere(
      (e) => e is ChatToolFinished && e.callId == 'r1',
    );
    expect(readDone, isNonNegative);
    expect(readDone, lessThan(firstApproval));
    expect(run.events.whereType<ChatApprovalRequested>().map((e) => e.callId), [
      'w1',
    ]);

    chat.decide('w1', true);
    await pumpEventQueue();
    expect(run.events.whereType<ChatApprovalRequested>().map((e) => e.callId), [
      'w1',
      'w2',
    ]);
    final w1Done = run.events.indexWhere(
      (e) => e is ChatToolFinished && e.callId == 'w1',
    );
    final secondApproval = run.events.lastIndexWhere(
      (e) => e is ChatApprovalRequested,
    );
    expect(w1Done, lessThan(secondApproval));

    chat.decide('w2', false);
    await run.done;

    final results = _lastResults(model.requests[1]);
    expect(results.map((r) => r.callId), ['w1', 'r1', 'w2']);
    expect(results[0].json, _okJson);
    expect(results[2].json, _declinedJson);
    verify(() => workspace.apply(_planA)).called(1);
    verifyNever(() => workspace.apply(_planB));
  });

  group('시스템 프롬프트', () {
    test('쓰기 줄이 작업 폴더 줄 바로 뒤', () async {
      final model = _FakeModel([_answer('네')]);

      await session(model).ask('질문').toList();

      expect(
        model.requests.single.system,
        contains('$_workspaceLine\n$_writeLine\n'),
      );
    });

    test('기록 꺼짐이면 쓰기 줄이 없다', () async {
      final model = _FakeModel([_answer('네')]);
      final chat = session(model)..useRecords = false;

      await chat.ask('질문').toList();

      expect(model.requests.single.system, isNot(contains('write_file')));
    });
  });
}
