import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/attachment/attachment_loader.dart';
import 'package:walk/domain/chat/attachment/attachment_rules.dart';
import 'package:walk/domain/chat/attachment/chat_attachment.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_trace.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/entity/conversation.dart';
import 'package:walk/domain/chat/repository/chat_history_repository.dart';
import 'package:walk/domain/chat/usecase/chat_model_choice.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/chat/usecase/open_conversation.dart';
import 'package:walk/domain/chat/workspace/workspace.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/presentation/chat/cubit/chat_cubit.dart';
import 'package:walk/presentation/chat/cubit/chat_state.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_chat_key_verifier.dart';
import '../../../support/fake_chat_model_catalog.dart';
import '../../../support/fake_chat_settings.dart';

class _MockSession extends Mock implements ChatSession {}

class _MockDiary extends Mock implements DiaryRepository {}

class _MockHistory extends Mock implements ChatHistoryRepository {}

/// inbox 에 넣은 (이름, 바이트)를 적는다. [fail] 이면 던진다.
class _FakeWorkspace implements Workspace {
  final imported = <(String, Uint8List)>[];
  bool fail = false;

  @override
  Future<String> importToInbox(String name, Uint8List bytes) async {
    if (fail) throw const FileSystemExceptionLike();
    imported.add((name, bytes));
    return 'inbox/20261113-120000-$name';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FileSystemExceptionLike implements Exception {
  const FileSystemExceptionLike();
}

/// 이름으로 결과를 정한다 — `.docx` 면 unsupportedType, 나머지는 종류대로 받는다.
class _FakeLoader implements AttachmentLoader {
  final loaded = <String>[];

  @override
  Future<AttachmentLoad> load(PickedFile file) async {
    loaded.add(file.name);
    final kind = AttachmentRules.kindOf(file.name);
    final bytes = Uint8List.fromList([1, 2, 3]);
    return switch (kind) {
      null => AttachmentLoad.rejected(
        file.name,
        AttachmentRejection.unsupportedType,
      ),
      AttachmentKind.image => AttachmentLoad.ok(
        ChatAttachment.image(
          name: file.name,
          mediaType: 'image/jpeg',
          bytes: bytes,
          workspacePath: file.workspacePath,
        ),
      ),
      AttachmentKind.pdf => AttachmentLoad.ok(
        ChatAttachment.pdf(
          name: file.name,
          bytes: bytes,
          workspacePath: file.workspacePath,
        ),
      ),
      AttachmentKind.text => AttachmentLoad.ok(
        ChatAttachment.text(
          name: file.name,
          text: 'hi',
          workspacePath: file.workspacePath,
        ),
      ),
    };
  }
}

const _target = (vendor: ChatVendor.anthropic, model: 'claude-x');

const _sonnet = ModelInfo(
  id: 'claude-sonnet-9-5',
  displayName: 'Claude Sonnet 9.5',
);

PickedFile _picked(String name, {String? workspacePath}) => PickedFile(
  name: name,
  path: '/picked/$name',
  sizeBytes: 3,
  workspacePath: workspacePath,
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      const ChatTurnDraft(
        question: '',
        answer: '',
        citedEntryIds: [],
        vendor: ChatVendor.anthropic,
        model: '',
      ),
    );
    registerFallbackValue(<ChatAttachment>[]);
    registerFallbackValue(<ChatTurnText>[]);
  });

  late _MockSession session;
  late _MockHistory history;
  late _FakeWorkspace workspace;
  late _FakeLoader loader;
  late ChatCubit cubit;
  late StreamController<ChatEvent> events;
  late ({int images, int docs}) room;

  /// ask 가 받은 (질문, 첨부).
  late List<(String, List<ChatAttachment>)> asked;
  late List<ChatTurnDraft> appended;

  setUp(() async {
    session = _MockSession();
    history = _MockHistory();
    workspace = _FakeWorkspace();
    loader = _FakeLoader();
    events = StreamController<ChatEvent>();
    room = (images: 12, docs: 5);
    asked = [];
    appended = [];
    final settings = FakeChatSettings('sk-ant-test')
      ..consentedVendor = ChatVendor.anthropic;
    final verifier = FakeChatKeyVerifier()
      ..stored = (ChatVendor.anthropic, const ModelListResult.ok([_sonnet]));
    final choice = ChatModelChoice(
      settings,
      FakeChatModelCatalog(),
      verifier,
      const Clock(),
    );
    when(() => session.target).thenReturn(_target);
    when(() => session.attachmentRoom).thenAnswer((_) => room);
    Stream<ChatEvent> record(Invocation invocation) {
      asked.add((
        invocation.positionalArguments.first as String,
        (invocation.namedArguments[#attachments] as List<ChatAttachment>?) ??
            const [],
      ));
      return events.stream;
    }

    when(() => session.ask(any())).thenAnswer(record);
    when(
      () => session.ask(any(), attachments: any(named: 'attachments')),
    ).thenAnswer(record);
    when(
      () => history.watchExists(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => history.appendTurn(
        conversationId: any(named: 'conversationId'),
        turn: any(named: 'turn'),
      ),
    ).thenAnswer((invocation) async {
      appended.add(invocation.namedArguments[#turn] as ChatTurnDraft);
      return (conversationId: 'c1', seq: appended.length);
    });
    cubit = ChatCubit(
      session,
      settings,
      _MockDiary(),
      const NoopChatTrace(),
      choice,
      history,
      OpenConversation(),
      const Clock(),
      workspace,
      loader,
    );
    await cubit.refresh();
    expect(cubit.state.access, ChatAccess.ready);
  });

  tearDown(() => cubit.close());

  Future<void> finish(Future<void> sent) async {
    events
      ..add(const ChatEvent.text('봤어요'))
      ..add(const ChatEvent.finished(citedEntryIds: []));
    await events.close();
    await sent;
  }

  group('addFiles', () {
    test('4개를 고르면 3개만 담고 perQuestionLimit 알림', () async {
      await cubit.addFiles([
        _picked('a.pdf'),
        _picked('b.txt'),
        _picked('c.jpg'),
        _picked('d.md'),
      ]);

      expect(cubit.state.pendingAttachments.map((a) => a.name), [
        'a.pdf',
        'b.txt',
        'c.jpg',
      ]);
      expect(
        cubit.state.attachmentNotice,
        const AttachmentNotice(
          name: 'd.md',
          reason: AttachmentRejection.perQuestionLimit,
        ),
      );
      expect(cubit.state.canAttach, isFalse);
      expect(cubit.state.attachBlock, AttachBlock.perQuestion);
    });

    test('로더가 거절하면 담지 않고 그 이유를 알린다', () async {
      await cubit.addFiles([_picked('x.docx'), _picked('a.pdf')]);

      expect(cubit.state.pendingAttachments.map((a) => a.name), ['a.pdf']);
      expect(
        cubit.state.attachmentNotice,
        const AttachmentNotice(
          name: 'x.docx',
          reason: AttachmentRejection.unsupportedType,
        ),
      );

      cubit.consumeAttachmentNotice();
      expect(cubit.state.attachmentNotice, isNull);
    });

    test('대화의 문서 자리가 담긴 것만큼 줄어 차면 conversationDocLimit — 읽지 않는다', () async {
      room = (images: 12, docs: 1);
      await cubit.addFiles([_picked('a.pdf'), _picked('b.txt')]);

      expect(cubit.state.pendingAttachments.map((a) => a.name), ['a.pdf']);
      expect(
        cubit.state.attachmentNotice?.reason,
        AttachmentRejection.conversationDocLimit,
      );
      expect(loader.loaded, ['a.pdf']);
    });

    test('사진 자리가 없으면 conversationImageLimit', () async {
      room = (images: 0, docs: 5);
      await cubit.addFiles([_picked('c.jpg')]);

      expect(cubit.state.pendingAttachments, isEmpty);
      expect(
        cubit.state.attachmentNotice?.reason,
        AttachmentRejection.conversationImageLimit,
      );
    });

    test('사진 · 문서 자리가 모두 없으면 canAttach false (대화 한도)', () async {
      room = (images: 0, docs: 0);
      cubit.newConversation();

      expect(cubit.state.canAttach, isFalse);
      expect(cubit.state.attachBlock, AttachBlock.conversation);
    });

    test('removePending 은 그 첨부를 빼고 다시 붙일 수 있게 한다', () async {
      await cubit.addFiles([
        _picked('a.pdf'),
        _picked('b.txt'),
        _picked('c.jpg'),
      ]);
      expect(cubit.state.canAttach, isFalse);

      cubit.removePending(0);

      expect(cubit.state.pendingAttachments.map((a) => a.name), [
        'b.txt',
        'c.jpg',
      ]);
      expect(cubit.state.canAttach, isTrue);
    });
  });

  group('send', () {
    test('글 없이 첨부만 — inbox 에 넣고 빈 질문 문구로 묻고, 경로째 저장하고 비운다', () async {
      await cubit.addFiles([_picked('a.pdf'), _picked('b.txt')]);

      final sent = cubit.send('');
      await pumpEventQueue();

      expect(workspace.imported.map((e) => e.$1), ['a.pdf', 'b.txt']);
      expect(asked, hasLength(1));
      expect(asked.single.$1, AttachmentRules.emptyQuestion);
      expect(asked.single.$2.map((a) => a.workspacePath), [
        'inbox/20261113-120000-a.pdf',
        'inbox/20261113-120000-b.txt',
      ]);
      expect(cubit.state.pendingAttachments, isEmpty);
      final user = cubit.state.bubbles.first;
      expect(user.text, AttachmentRules.emptyQuestion);
      expect(user.attachments.map((a) => a.name), ['a.pdf', 'b.txt']);

      await finish(sent);

      expect(appended.single.question, AttachmentRules.emptyQuestion);
      expect(appended.single.attachments, [
        const ChatAttachmentRef(
          name: 'a.pdf',
          kind: AttachmentKind.pdf,
          workspacePath: 'inbox/20261113-120000-a.pdf',
        ),
        const ChatAttachmentRef(
          name: 'b.txt',
          kind: AttachmentKind.text,
          workspacePath: 'inbox/20261113-120000-b.txt',
        ),
      ]);
    });

    test('이미 작업 폴더에 있는 첨부는 다시 넣지 않는다', () async {
      await cubit.addFiles([
        _picked('a.pdf', workspacePath: 'inbox/a.pdf'),
        _picked('b.txt'),
      ]);

      final sent = cubit.send('봐 줘');
      await pumpEventQueue();

      expect(workspace.imported.map((e) => e.$1), ['b.txt']);
      expect(asked.single.$1, '봐 줘');
      expect(asked.single.$2.first.workspacePath, 'inbox/a.pdf');
      await finish(sent);
    });

    test('임시 대화는 inbox 에 넣지 않는다', () async {
      cubit.startTemporary();
      await cubit.addFiles([_picked('a.pdf'), _picked('b.txt')]);

      final sent = cubit.send('');
      await pumpEventQueue();

      expect(workspace.imported, isEmpty);
      expect(asked.single.$2.map((a) => a.workspacePath), [null, null]);
      await finish(sent);
      expect(appended, isEmpty);
    });

    test('inbox 넣기가 던져도 보낸다 — 그 첨부는 경로 없이', () async {
      workspace.fail = true;
      await cubit.addFiles([_picked('a.pdf')]);

      final sent = cubit.send('봐 줘');
      await pumpEventQueue();

      expect(asked, hasLength(1));
      expect(asked.single.$2.single.workspacePath, isNull);
      await finish(sent);
      expect(appended.single.attachments.single.workspacePath, isNull);
    });

    test('글도 첨부도 없으면 보내지 않는다', () async {
      await cubit.send('  ');

      expect(asked, isEmpty);
    });

    test('세션이 한도로 거절하면 보내지 않고 첨부를 남긴 채 알린다', () async {
      await cubit.addFiles([_picked('a.pdf')]);
      when(
        () => session.ask(any(), attachments: any(named: 'attachments')),
      ).thenThrow(ArgumentError('document limit reached'));

      await cubit.send('봐 줘');

      expect(cubit.state.bubbles, isEmpty);
      expect(cubit.state.busy, isFalse);
      expect(cubit.state.pendingAttachments, hasLength(1));
      expect(
        cubit.state.attachmentNotice?.reason,
        AttachmentRejection.conversationDocLimit,
      );
    });
  });

  test('연 대화의 질문 말풍선은 저장된 첨부를 든다', () async {
    const ref = ChatAttachmentRef(
      name: 'a.pdf',
      kind: AttachmentKind.pdf,
      workspacePath: 'inbox/a.pdf',
    );
    when(() => history.turns('c9')).thenAnswer(
      (_) async => [
        ChatTurnRecord(
          conversationId: 'c9',
          seq: 1,
          question: '봐 줘',
          answer: '봤어요',
          citedEntryIds: const [],
          stopped: false,
          vendor: ChatVendor.anthropic,
          model: 'm',
          askedAt: diaryT0,
          attachments: const [ref],
        ),
      ],
    );
    when(() => session.resume(any(), temporary: false)).thenReturn(null);

    await cubit.open('c9');

    expect(cubit.state.bubbles.first.attachments, [ref]);
  });
}
