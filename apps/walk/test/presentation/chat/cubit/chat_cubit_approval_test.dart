import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/attachment/attachment_rules.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_trace.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/entity/conversation.dart';
import 'package:walk/domain/chat/repository/chat_history_repository.dart';
import 'package:walk/domain/chat/tool/life_tools.dart';
import 'package:walk/domain/chat/tool/tool_result.dart';
import 'package:walk/domain/chat/tool/tool_summary.dart';
import 'package:walk/domain/chat/tool/wiki_tools.dart';
import 'package:walk/domain/chat/tool/workspace_tools.dart';
import 'package:walk/domain/chat/tool/write_plan.dart';
import 'package:walk/domain/chat/usecase/chat_model_choice.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/chat/usecase/open_conversation.dart';
import 'package:walk/domain/chat/wiki/wiki_context_policy.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/presentation/chat/cubit/chat_cubit.dart';
import 'package:walk/presentation/chat/cubit/chat_progress.dart';
import 'package:walk/presentation/chat/cubit/chat_state.dart';

import '../../../support/fake_chat_key_verifier.dart';
import '../../../support/fake_chat_model_catalog.dart';
import '../../../support/fake_chat_model_registry.dart';
import '../../../support/fake_chat_settings.dart';
import '../../../support/fake_chat_usage_log.dart';
import '../../../support/unused_chat_attachments.dart';

class _MockSession extends Mock implements ChatSession {}

class _MockDiary extends Mock implements DiaryRepository {}

class _MockHistory extends Mock implements ChatHistoryRepository {}

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

/// 한 번 부를 때마다 준비된 라운드 하나를 흘린다.
class _FakeModel implements ChatModel {
  _FakeModel(this.rounds);

  @override
  bool progressNotes = false;

  final List<List<ModelEvent>> rounds;
  int calls = 0;

  @override
  Future<ModelListResult> listModels(String apiKey) async =>
      const ModelListResult.ok([]);

  @override
  var vendor = ChatVendor.anthropic;

  @override
  Stream<ModelEvent> stream(ModelRequest request) async* {
    final index = calls++;
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

List<ModelEvent> _writeCall(String id) => [
  _done([
    AssistantPart.toolCall(
      id: id,
      name: 'write_file',
      input: const {'path': 'out/a.md', 'content': '내용'},
    ),
  ], StopKind.toolUse),
];

const _target = (vendor: ChatVendor.anthropic, model: 'claude-sonnet-9-5');

const _create = WritePlan.create(path: 'out/a.md', name: 'a.md', content: '내용');
const _delete = WritePlan.delete(
  path: 'out/old.md',
  name: 'old.md',
  previous: '예전',
  sizeBytes: 6,
);

const _wrote = ToolSummary(kind: ChatToolKind.writeFile, count: 1);
const _declinedSummary = ToolSummary(
  kind: ChatToolKind.writeFile,
  count: 0,
  isError: true,
  declined: true,
);

void main() {
  late _MockDiary diary;
  late _MockHistory history;
  late FakeChatSettings settings;
  late ChatModelChoice choice;

  setUpAll(() async {
    await initializeDateFormatting('ko');
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(_create);
    registerFallbackValue(<ChatTurnText>[]);
    registerFallbackValue(
      const ChatTurnDraft(
        question: '',
        answer: '',
        citedEntryIds: [],
        vendor: ChatVendor.anthropic,
        model: '',
      ),
    );
  });

  setUp(() async {
    diary = _MockDiary();
    history = _MockHistory();
    when(
      () => history.watchExists(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(() => history.turns(any())).thenAnswer((_) async => const []);
    when(
      () => history.appendTurn(
        conversationId: any(named: 'conversationId'),
        turn: any(named: 'turn'),
      ),
    ).thenAnswer((_) async => (conversationId: 'c1', seq: 1));
    settings = FakeChatSettings('sk-ant-test')
      ..consentedVendor = ChatVendor.anthropic;
    final catalog = FakeChatModelCatalog();
    const sonnet = ModelInfo(id: 'claude-sonnet-9-5', displayName: 's');
    await catalog.replace(ChatVendor.anthropic, [sonnet], DateTime.now());
    final verifier = FakeChatKeyVerifier()
      ..stored = (ChatVendor.anthropic, const ModelListResult.ok([sonnet]));
    choice = ChatModelChoice(settings, catalog, verifier, const Clock());
  });

  ChatCubit cubitOf(ChatSession session) => ChatCubit(
    session,
    settings,
    diary,
    const NoopChatTrace(),
    choice,
    history,
    OpenConversation(),
    const Clock(),
    const UnusedWorkspace(),
    const UnusedAttachmentLoader(),
    FakePickedFileCache(),
  );

  group('가짜 세션', () {
    late _MockSession session;
    late ChatCubit cubit;
    late StreamController<ChatEvent> events;

    setUp(() async {
      session = _MockSession();
      when(() => session.target).thenReturn(_target);
      when(() => session.attachmentRoom).thenReturn((
        images: 12,
        docs: 5,
        docBytes: AttachmentRules.maxDocBytesPerConversation,
      ));
      events = StreamController<ChatEvent>();
      when(() => session.ask(any())).thenAnswer((_) => events.stream);
      when(() => session.stop()).thenReturn(const ChatStopResult.dropped());
      cubit = cubitOf(session);
      await cubit.refresh(recheck: false);
    });

    tearDown(() async {
      unawaited(events.close());
      await cubit.close();
    });

    StepTool? toolStep() => cubit.state.bubbles.lastOrNull?.progress?.steps
        .whereType<StepTool>()
        .lastOrNull;

    /// send 가 돌려준 Future.
    late Future<void> sent;

    /// 질문을 보내고 w1 쓰기의 승인 요청까지 흘린다.
    Future<void> askAndWait({WritePlan plan = _create}) async {
      sent = cubit.send('저장해 줘');
      events
        ..add(
          const ChatEvent.toolStarted(
            callId: 'w1',
            name: 'write_file',
            input: ToolInputSummary(kind: ChatToolKind.writeFile, name: 'a.md'),
          ),
        )
        ..add(ChatEvent.approvalRequested(callId: 'w1', plan: plan));
      await pumpEventQueue();
    }

    test('approvalRequested 면 pendingApproval 과 기다리는 진행 줄', () async {
      await askAndWait();

      expect(
        cubit.state.pendingApproval,
        const PendingApproval(callId: 'w1', plan: _create),
      );
      expect(toolStep()?.awaitingApproval, isTrue);
      expect(toolStep()?.callId, 'w1');
    });

    test('입력 이름이 없으면 계획의 이름을 진행 줄에 쓴다', () async {
      sent = cubit.send('저장해 줘');
      events
        ..add(const ChatEvent.toolStarted(callId: 'w1', name: 'write_file'))
        ..add(const ChatEvent.approvalRequested(callId: 'w1', plan: _create));
      await pumpEventQueue();

      expect(toolStep()?.input?.name, 'a.md');
      expect(toolStep()?.awaitingApproval, isTrue);
    });

    test('approve 는 decide(id, true) 를 한 번만 — 두 번 눌러도', () async {
      await askAndWait();

      cubit
        ..approve()
        ..approve();

      verify(() => session.decide('w1', true)).called(1);
      verifyNever(() => session.decide(any(), false));
      expect(cubit.state.pendingApproval, isNull);
    });

    test('decline 은 decide(id, false), 상태를 비운다', () async {
      await askAndWait();

      cubit
        ..decline()
        ..decline();

      verify(() => session.decide('w1', false)).called(1);
      expect(cubit.state.pendingApproval, isNull);
    });

    test('기다리는 것이 없으면 approve · decline 은 아무것도 하지 않는다', () {
      cubit
        ..approve()
        ..decline();

      verifyNever(() => session.decide(any(), any()));
    });

    test('approvalClosed 뒤 진행 줄은 실행 라벨(기다림 끝)', () async {
      await askAndWait();
      cubit.approve();

      events.add(const ChatEvent.approvalClosed(callId: 'w1'));
      await pumpEventQueue();

      expect(cubit.state.pendingApproval, isNull);
      expect(toolStep()?.awaitingApproval, isFalse);
      expect(toolStep()?.result, isNull);
    });

    test('거절하면 결과는 declined, 저장 신호 없음', () async {
      await askAndWait();
      cubit.decline();
      events
        ..add(const ChatEvent.approvalClosed(callId: 'w1'))
        ..add(
          const ChatEvent.toolFinished(
            callId: 'w1',
            name: 'write_file',
            summary: _declinedSummary,
          ),
        );
      await pumpEventQueue();

      expect(toolStep()?.result?.declined, isTrue);
      expect(cubit.state.savedFile, isNull);
    });

    test('쓰기 성공이면 savedFile(경로 · 이름) 한 번, consume 하면 비운다', () async {
      await askAndWait();
      cubit.approve();
      events
        ..add(const ChatEvent.approvalClosed(callId: 'w1'))
        ..add(
          const ChatEvent.toolFinished(
            callId: 'w1',
            name: 'write_file',
            summary: _wrote,
          ),
        );
      await pumpEventQueue();

      expect(
        cubit.state.savedFile,
        const SavedFileNotice(path: 'out/a.md', name: 'a.md', deleted: false),
      );
      cubit.consumeSavedFile();
      expect(cubit.state.savedFile, isNull);
    });

    test('지우기 성공이면 deleted: true', () async {
      await askAndWait(plan: _delete);
      cubit.approve();
      events
        ..add(const ChatEvent.approvalClosed(callId: 'w1'))
        ..add(
          const ChatEvent.toolFinished(
            callId: 'w1',
            name: 'delete_file',
            summary: ToolSummary(kind: ChatToolKind.deleteFile, count: 1),
          ),
        );
      await pumpEventQueue();

      expect(
        cubit.state.savedFile,
        const SavedFileNotice(
          path: 'out/old.md',
          name: 'old.md',
          deleted: true,
        ),
      );
    });

    test('쓰기 오류 결과면 저장 신호 없음', () async {
      await askAndWait();
      cubit.approve();
      events
        ..add(const ChatEvent.approvalClosed(callId: 'w1'))
        ..add(
          const ChatEvent.toolFinished(
            callId: 'w1',
            name: 'write_file',
            summary: ToolSummary(
              kind: ChatToolKind.writeFile,
              count: 0,
              isError: true,
            ),
          ),
        );
      await pumpEventQueue();

      expect(cubit.state.savedFile, isNull);
    });

    test('기다리는 중 stop 하면 pendingApproval 을 비운다', () async {
      await askAndWait();

      cubit.stop();

      expect(cubit.state.pendingApproval, isNull);
      expect(cubit.state.busy, isFalse);
    });

    test('기다리는 중 새 대화면 pendingApproval 을 비운다', () async {
      await askAndWait();

      cubit.newConversation();

      expect(cubit.state.pendingApproval, isNull);
      verify(() => session.reset()).called(1);
    });

    test('기다리는 중 다른 대화를 열면 pendingApproval 을 비운다', () async {
      await askAndWait();

      await cubit.open('c2');

      expect(cubit.state.pendingApproval, isNull);
    });

    test('기다리는 중 실패하면 pendingApproval 을 비운다', () async {
      await askAndWait();

      events.add(const ChatEvent.failed(ChatFailure.unknown));
      await pumpEventQueue();

      expect(cubit.state.pendingApproval, isNull);
    });

    test('끝나면 pendingApproval 을 비운다', () async {
      await askAndWait();

      events.add(const ChatEvent.finished(citedEntryIds: []));
      await events.close();
      await sent;

      expect(cubit.state.pendingApproval, isNull);
    });
  });

  group('실제 세션', () {
    late _MockLifeTools tools;
    late _MockWorkspaceTools workspace;

    setUp(() {
      tools = _MockLifeTools();
      when(
        () => tools.definitionsFor(images: any(named: 'images')),
      ).thenReturn(const []);
      when(() => tools.inputSummary(any(), any())).thenAnswer(
        (i) => ToolInputSummary(
          kind: chatToolKindOf(i.positionalArguments[0] as String),
          name: 'a.md',
        ),
      );
      workspace = _MockWorkspaceTools();
      when(() => workspace.definitions).thenReturn(const []);
      when(() => workspace.writeDefinitions).thenReturn(const [
        ToolSpec(name: 'write_file', description: 'd', parameters: {}),
      ]);
      when(
        () => workspace.prepareWrite(any(), any()),
      ).thenAnswer((_) async => _create);
      when(
        () => workspace.apply(any()),
      ).thenAnswer((_) async => const ToolResult(json: '{}', summary: _wrote));
    });

    ChatSession sessionOf(ChatModel model) => ChatSession(
      FakeChatModelRegistry({ChatVendor.anthropic: model}),
      tools,
      settings,
      choice,
      const Clock(),
      FakeChatUsageLog(),
      _SeqIds(),
      const NoopChatTrace(),
      _NoWiki(),
      _MockWikiTools(),
      workspace,
    );

    final switches = <String, Future<void> Function(ChatCubit)>{
      '새 대화': (cubit) async => cubit.newConversation(),
      '다른 대화 열기': (cubit) => cubit.open('c2'),
      '임시 대화': (cubit) async => cubit.startTemporary(),
      '멈춤': (cubit) async => cubit.stop(),
    };
    for (final MapEntry(key: name, value: change) in switches.entries) {
      test('승인 기다리는 중 $name → 쓰지 않고 다음 질문이 정상', () async {
        final model = _FakeModel([_writeCall('w1'), _answer('네')]);
        final cubit = cubitOf(sessionOf(model));
        addTearDown(cubit.close);
        await cubit.refresh(recheck: false);

        unawaited(cubit.send('저장해 줘'));
        await pumpEventQueue();
        expect(cubit.state.pendingApproval?.callId, 'w1');

        await change(cubit);
        await pumpEventQueue();
        expect(cubit.state.pendingApproval, isNull);
        expect(cubit.state.busy, isFalse);

        await cubit.send('안녕');
        await pumpEventQueue();

        expect(cubit.state.busy, isFalse);
        expect(cubit.state.bubbles.last.text, '네');
        expect(cubit.state.bubbles.last.failure, isNull);
        verifyNever(() => workspace.apply(any()));
      });
    }

    test('승인하면 쓰고 savedFile 이 온다', () async {
      final model = _FakeModel([_writeCall('w1'), _answer('저장했어요')]);
      final cubit = cubitOf(sessionOf(model));
      addTearDown(cubit.close);
      await cubit.refresh(recheck: false);

      final sent = cubit.send('저장해 줘');
      await pumpEventQueue();
      final notices = <SavedFileNotice>[];
      final sub = cubit.stream.listen((s) {
        if (s.savedFile case final n?) notices.add(n);
      });
      cubit.approve();
      await sent;
      await pumpEventQueue();
      await sub.cancel();

      verify(() => workspace.apply(_create)).called(1);
      expect(notices.toSet(), {
        const SavedFileNotice(path: 'out/a.md', name: 'a.md', deleted: false),
      });
      expect(cubit.state.bubbles.last.text, '저장했어요');
    });
  });
}
