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
import '../../../support/unused_chat_attachments.dart';

class _MockSession extends Mock implements ChatSession {}

class _MockDiary extends Mock implements DiaryRepository {}

class _MockHistory extends Mock implements ChatHistoryRepository {}

/// inbox 에 넣은 (이름, 바이트)를 적는다. [fail] 이면 던진다.
class _FakeWorkspace implements Workspace {
  final imported = <(String, Uint8List)>[];
  final written = <(String, String)>[];
  bool fail = false;

  /// 있으면 넣기 전에 기다린다(넣는 사이 대화를 바꾸는 테스트).
  Completer<void>? gate;

  @override
  Future<String> importToInbox(String name, Uint8List bytes) async {
    await gate?.future;
    if (fail) throw const FileSystemExceptionLike();
    imported.add((name, bytes));
    return 'inbox/20261113-120000-$name';
  }

  @override
  Future<String> writeOut(String fileName, String content) async {
    if (fail) throw const FileSystemExceptionLike();
    written.add((fileName, content));
    return 'out/$fileName';
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

  /// 원본은 줄인 본문([1, 2, 3])과 다르다 — 경로를 담은 바이트.
  @override
  Future<Uint8List> readOriginal(String path) async =>
      Uint8List.fromList([9, ...path.codeUnits]);
}

Uint8List _original(String name) =>
    Uint8List.fromList([9, ...'/picked/$name'.codeUnits]);

const _docBudget = AttachmentRules.maxDocBytesPerConversation;

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
  late FakePickedFileCache cache;
  late ChatCubit cubit;
  late StreamController<ChatEvent> events;
  late ({int images, int docs, int docBytes}) room;

  /// ask 가 받은 (질문, 첨부).
  late List<(String, List<ChatAttachment>)> asked;
  late List<ChatTurnDraft> appended;

  setUp(() async {
    session = _MockSession();
    history = _MockHistory();
    workspace = _FakeWorkspace();
    loader = _FakeLoader();
    cache = FakePickedFileCache();
    events = StreamController<ChatEvent>();
    room = (images: 12, docs: 5, docBytes: _docBudget);
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
      cache,
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
      room = (images: 12, docs: 1, docBytes: _docBudget);
      await cubit.addFiles([_picked('a.pdf'), _picked('b.txt')]);

      expect(cubit.state.pendingAttachments.map((a) => a.name), ['a.pdf']);
      expect(
        cubit.state.attachmentNotice?.reason,
        AttachmentRejection.conversationDocLimit,
      );
      expect(loader.loaded, ['a.pdf']);
    });

    test('사진 자리가 없으면 conversationImageLimit', () async {
      room = (images: 0, docs: 5, docBytes: _docBudget);
      await cubit.addFiles([_picked('c.jpg')]);

      expect(cubit.state.pendingAttachments, isEmpty);
      expect(
        cubit.state.attachmentNotice?.reason,
        AttachmentRejection.conversationImageLimit,
      );
    });

    test('사진 · 문서 자리가 모두 없으면 canAttach false (대화 한도)', () async {
      room = (images: 0, docs: 0, docBytes: _docBudget);
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

  group('saveAnswer', () {
    test('답을 질문 · 모델 · 첨부와 함께 out 에 쓰고 상대 경로를 돌려준다', () async {
      await cubit.addFiles([_picked('a.pdf')]);
      await finish(cubit.send('봐 줘'));

      final path = await cubit.saveAnswer(1);

      final (name, content) = workspace.written.single;
      expect(name, matches(RegExp(r'^\d{8}-\d{4}-봐-줘\.md$')));
      expect(path, 'out/$name');
      expect(content, startsWith('# 봐 줘\n'));
      expect(content, contains('- 모델: claude-x\n'));
      expect(content, contains('- 첨부: a.pdf\n'));
      expect(content, endsWith('---\n\n봤어요\n'));
    });

    test('질문 말풍선이나 없는 자리는 null — 쓰지 않는다', () async {
      await finish(cubit.send('봐 줘'));

      expect(await cubit.saveAnswer(0), isNull);
      expect(await cubit.saveAnswer(5), isNull);
      expect(workspace.written, isEmpty);
    });

    test('연 대화의 답은 저장된 턴의 모델로 쓴다', () async {
      await finish(cubit.send('봐 줘'));
      when(() => history.turns('c9')).thenAnswer(
        (_) async => [
          ChatTurnRecord(
            conversationId: 'c9',
            seq: 1,
            question: '옛 질문',
            answer: '옛 답',
            citedEntryIds: const [],
            stopped: false,
            vendor: ChatVendor.openai,
            model: 'stored-model',
            askedAt: diaryT0,
          ),
        ],
      );
      when(() => session.resume(any(), temporary: false)).thenReturn(null);
      await cubit.open('c9');

      await cubit.saveAnswer(1);

      expect(workspace.written.single.$2, contains('- 모델: stored-model\n'));
      expect(workspace.written.single.$2, isNot(contains('claude-x')));
    });

    test('새 대화에서 받은 답은 앞 대화의 모델이 아니라 제 모델로 쓴다', () async {
      await finish(cubit.send('봐 줘'));
      cubit.newConversation();
      when(
        () => session.target,
      ).thenReturn((vendor: ChatVendor.openai, model: 'gpt-z'));
      events = StreamController<ChatEvent>();
      await finish(cubit.send('다시'));

      await cubit.saveAnswer(1);

      expect(workspace.written.single.$2, contains('- 모델: gpt-z\n'));
      expect(workspace.written.single.$2, isNot(contains('claude-x')));
    });

    test('쓰기가 던지면 null', () async {
      await finish(cubit.send('봐 줘'));
      workspace.fail = true;

      expect(await cubit.saveAnswer(1), isNull);
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

    test('inbox 에는 줄인 본문이 아니라 원본 파일을 원래 이름으로 넣는다', () async {
      await cubit.addFiles([_picked('c.jpg'), _picked('a.pdf')]);

      final sent = cubit.send('봐 줘');
      await pumpEventQueue();

      expect(workspace.imported.map((e) => e.$1), ['c.jpg', 'a.pdf']);
      expect(workspace.imported[0].$2, _original('c.jpg'));
      expect(workspace.imported[1].$2, _original('a.pdf'));
      // 모델에는 줄인 본문을 보낸다.
      expect((asked.single.$2.first as ImageAttachment).bytes, [1, 2, 3]);
      await finish(sent);
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
      // 입력칸이 비운 글을 되돌리고, 넣은 사본 경로를 달아 둔다.
      expect(cubit.state.restoredDraft, '봐 줘');
      expect(
        cubit.state.pendingAttachments.single.workspacePath,
        'inbox/20261113-120000-a.pdf',
      );

      // 다시 보내도 사본을 또 넣지 않는다.
      cubit.consumeRestoredDraft();
      await cubit.send('봐 줘');
      expect(workspace.imported, hasLength(1));
    });

    test('글 없이 첨부만 보내다 한도로 거절되면 되돌릴 글은 없다', () async {
      await cubit.addFiles([_picked('a.pdf')]);
      when(
        () => session.ask(any(), attachments: any(named: 'attachments')),
      ).thenThrow(ArgumentError('document limit reached'));

      await cubit.send('');

      expect(cubit.state.restoredDraft, isNull);
      expect(cubit.state.pendingAttachments, hasLength(1));
    });

    test('사본을 넣는 사이 새 대화로 바뀌면 보내지 않고 글 · 경로 단 첨부를 남긴다', () async {
      await cubit.addFiles([_picked('a.pdf')]);
      workspace.gate = Completer<void>();

      final sent = cubit.send('봐 줘');
      await pumpEventQueue();
      cubit.newConversation();
      workspace.gate!.complete();
      await sent;

      expect(asked, isEmpty);
      expect(cubit.state.bubbles, isEmpty);
      expect(cubit.state.restoredDraft, '봐 줘');
      expect(
        cubit.state.pendingAttachments.single.workspacePath,
        'inbox/20261113-120000-a.pdf',
      );
    });
  });

  group('문서 바이트 합계', () {
    test('남은 바이트보다 큰 PDF · 텍스트는 읽지 않고 conversationSizeLimit', () async {
      room = (images: 12, docs: 5, docBytes: 4);
      await cubit.addFiles([_picked('a.pdf'), _picked('b.txt')]);

      // a.pdf(3바이트)는 담기고, 남은 1바이트에 b.txt(3바이트)는 들지 않는다.
      expect(cubit.state.pendingAttachments.map((a) => a.name), ['a.pdf']);
      expect(
        cubit.state.attachmentNotice?.reason,
        AttachmentRejection.conversationSizeLimit,
      );
      expect(loader.loaded, ['a.pdf']);
    });

    test('사진 자리도 문서 바이트도 없으면 대화 한도로 막힌다', () async {
      room = (images: 0, docs: 5, docBytes: 0);
      cubit.newConversation();

      expect(cubit.state.attachBlock, AttachBlock.conversation);
    });

    test('세션이 바이트 한도로 거절하면 conversationSizeLimit 을 알린다', () async {
      await cubit.addFiles([_picked('a.pdf')]);
      room = (images: 12, docs: 5, docBytes: 2);
      when(
        () => session.ask(any(), attachments: any(named: 'attachments')),
      ).thenThrow(ArgumentError('document size limit reached'));

      await cubit.send('봐 줘');

      expect(
        cubit.state.attachmentNotice?.reason,
        AttachmentRejection.conversationSizeLimit,
      );
    });
  });

  group('선택기 캐시 사본', () {
    test('로더 · 자리 때문에 뺀 파일은 바로 지운다', () async {
      room = (images: 0, docs: 5, docBytes: _docBudget);
      await cubit.addFiles([_picked('x.docx'), _picked('c.jpg')]);

      expect(cache.released, ['/picked/x.docx', '/picked/c.jpg']);
    });

    test('작업 폴더에서 고른 파일은 뺄 때도 지우지 않는다', () async {
      await cubit.addFiles([
        _picked('a.pdf', workspacePath: 'inbox/a.pdf'),
        _picked('x.docx', workspacePath: 'inbox/x.docx'),
      ]);
      cubit.removePending(0);

      expect(cache.released, isEmpty);
    });

    test('입력칸에서 빼면 지운다', () async {
      await cubit.addFiles([_picked('a.pdf'), _picked('b.txt')]);
      expect(cache.released, isEmpty);

      cubit.removePending(1);

      expect(cache.released, ['/picked/b.txt']);
    });

    test('일반 대화는 inbox 사본을 넣은 뒤에 지운다', () async {
      await cubit.addFiles([_picked('a.pdf')]);
      workspace.gate = Completer<void>();

      final sent = cubit.send('봐 줘');
      await pumpEventQueue();
      expect(cache.released, isEmpty);

      workspace.gate!.complete();
      await pumpEventQueue();
      expect(workspace.imported, hasLength(1));
      expect(cache.released, ['/picked/a.pdf']);
      await finish(sent);
      expect(cache.released, ['/picked/a.pdf']);
    });

    test('임시 대화는 보내면 지운다', () async {
      cubit.startTemporary();
      await cubit.addFiles([_picked('a.pdf')]);
      expect(cache.released, isEmpty);

      final sent = cubit.send('봐 줘');
      await pumpEventQueue();

      expect(cache.released, ['/picked/a.pdf']);
      await finish(sent);
    });

    test('inbox 사본을 못 넣은 첨부는 답이 끝날 때까지 원본을 남긴다', () async {
      workspace.fail = true;
      await cubit.addFiles([_picked('a.pdf')]);

      final sent = cubit.send('봐 줘');
      await pumpEventQueue();
      expect(cubit.state.busy, isTrue);
      expect(cache.released, isEmpty);

      await finish(sent);
      expect(cache.released, ['/picked/a.pdf']);
    });

    test('inbox 사본을 못 넣은 채 실패하면 입력칸에 돌아오고 원본도 남는다', () async {
      workspace.fail = true;
      await cubit.addFiles([_picked('a.pdf')]);

      final sent = cubit.send('봐 줘');
      await pumpEventQueue();
      events.add(const ChatEvent.failed(ChatFailure.network));
      await pumpEventQueue();

      expect(cubit.state.pendingAttachments.single.workspacePath, isNull);
      expect(cache.released, isEmpty);

      // 다시 보내면 그 원본으로 사본을 넣는다.
      workspace.fail = false;
      unawaited(events.close());
      await sent;
      events = StreamController<ChatEvent>();
      final again = cubit.send('봐 줘');
      await pumpEventQueue();
      expect(workspace.imported.single.$2, _original('a.pdf'));
      expect(cache.released, ['/picked/a.pdf']);
      await finish(again);
    });

    test('새 대화 · 임시 대화 · 닫기는 원본이 필요 없으면 캐시를 통째로 비운다', () async {
      cubit.newConversation();
      expect(cache.cleared, 1);

      await cubit.addFiles([_picked('a.pdf')]);
      cubit.startTemporary();
      // 입력칸 첨부가 아직 원본을 쓴다.
      expect(cache.cleared, 1);

      cubit.removePending(0);
      cubit.newConversation();
      expect(cache.cleared, 2);

      await cubit.close();
      expect(cache.cleared, 3);
    });
  });

  group('실패한 질문', () {
    test('첨부를 사본 경로째 입력칸에 되돌린다 — 다시 보내도 또 넣지 않는다', () async {
      await cubit.addFiles([_picked('a.pdf'), _picked('b.txt')]);

      final sent = cubit.send('봐 줘');
      await pumpEventQueue();
      events.add(const ChatEvent.failed(ChatFailure.network));
      await pumpEventQueue();

      expect(cubit.state.busy, isFalse);
      expect(cubit.state.bubbles.last.failure, ChatFailure.network);
      expect(cubit.state.pendingAttachments.map((a) => a.workspacePath), [
        'inbox/20261113-120000-a.pdf',
        'inbox/20261113-120000-b.txt',
      ]);
      // 실패는 '멈췄어요' 와 달리 글을 되돌리지 않는다.
      expect(cubit.state.restoredDraft, isNull);

      unawaited(events.close());
      await sent;
      events = StreamController<ChatEvent>();
      final again = cubit.send('봐 줘');
      await pumpEventQueue();

      expect(workspace.imported, hasLength(2));
      expect(asked.last.$2.map((a) => a.workspacePath), [
        'inbox/20261113-120000-a.pdf',
        'inbox/20261113-120000-b.txt',
      ]);
      await finish(again);
    });
  });

  group('글 없이 멈춤(dropped)', () {
    setUp(() {
      when(() => session.stop()).thenReturn(const ChatStopResult.dropped());
    });

    test('첨부만 보낸 질문은 빈 글과 첨부(사본 경로째)를 되돌리고 멈춤 알림 조건이 선다', () async {
      final states = <ChatState>[];
      final sub = cubit.stream.listen(states.add);
      await cubit.addFiles([_picked('a.pdf')]);
      final sent = cubit.send('');
      await pumpEventQueue();
      final before = cubit.state;

      cubit.stop();
      await sent;
      await pumpEventQueue();
      await sub.cancel();

      final after = cubit.state;
      expect(after.bubbles, isEmpty);
      expect(after.restoredDraft, '');
      expect(
        after.pendingAttachments.single.workspacePath,
        'inbox/20261113-120000-a.pdf',
      );
      // 탭의 '멈췄어요' 스낵바 조건(답하던 중 · 되돌린 글 없음 → 있음).
      expect(before.busy, isTrue);
      expect(before.restoredDraft, isNull);
      expect(states.last.restoredDraft, isNotNull);
      unawaited(events.close());
    });

    test('답하는 사이 담은 첨부와 합쳐 한 질문 한도(3)까지만 되돌린다', () async {
      await cubit.addFiles([_picked('a.pdf'), _picked('b.txt')]);
      final sent = cubit.send('봐 줘');
      await pumpEventQueue();
      await cubit.addFiles([_picked('c.jpg'), _picked('d.md')]);
      expect(cubit.state.pendingAttachments, hasLength(2));

      cubit.stop();
      await sent;

      expect(cubit.state.restoredDraft, '봐 줘');
      expect(cubit.state.pendingAttachments.map((a) => a.name), [
        'a.pdf',
        'b.txt',
        'c.jpg',
      ]);
      // 넘쳐 빠진 d.md 의 원본은 지우고, 되돌린 c.jpg 의 원본은 남긴다(a · b 는 사본을
      // 넣을 때 이미 지웠다).
      expect(cache.released, [
        '/picked/a.pdf',
        '/picked/b.txt',
        '/picked/d.md',
      ]);
      unawaited(events.close());
    });
  });

  group('사본을 넣는 동안', () {
    test('preparing 이 켜지고 그동안 send · removePending 은 무시한다', () async {
      await cubit.addFiles([_picked('a.pdf')]);
      workspace.gate = Completer<void>();

      final sent = cubit.send('봐 줘');
      await pumpEventQueue();
      expect(cubit.state.preparing, isTrue);

      await cubit.send('또');
      cubit.removePending(0);
      expect(cubit.state.pendingAttachments, hasLength(1));

      workspace.gate!.complete();
      await pumpEventQueue();
      expect(cubit.state.preparing, isFalse);
      expect(asked.map((a) => a.$1), ['봐 줘']);
      await finish(sent);
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
