import 'dart:async';
import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/attachment/answer_file.dart';
import '../../../domain/chat/attachment/attachment_loader.dart';
import '../../../domain/chat/attachment/attachment_rules.dart';
import '../../../domain/chat/attachment/chat_attachment.dart';
import '../../../domain/chat/chat_settings.dart';
import '../../../domain/chat/chat_trace.dart';
import '../../../domain/chat/chat_vendor.dart';
import '../../../domain/chat/entity/conversation.dart';
import '../../../domain/chat/repository/chat_history_repository.dart';
import '../../../domain/chat/tool/tool_summary.dart';
import '../../../domain/chat/usecase/chat_model_choice.dart';
import '../../../domain/chat/usecase/chat_session.dart';
import '../../../domain/chat/usecase/open_conversation.dart';
import '../../../domain/chat/workspace/workspace.dart';
import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../widget/model_chip.dart';
import 'chat_progress.dart';
import 'chat_state.dart';

/// 다음 프레임이 그려진 뒤 [callback] 을 부른다.
void _addPostFrame(VoidCallback callback) =>
    SchedulerBinding.instance.addPostFrameCallback((_) => callback());

/// 한 대화(새 대화 · 연 대화 · 임시 대화) 동안의 저장 위치. [ChatCubit.newConversation] ·
/// [ChatCubit.open] · [ChatCubit.startTemporary] 마다 새로 만든다 — 늦게 끝난 저장이 지난
/// 대화의 것인지 이 객체로 가린다. 지난 대화 몫으로 줄 선 저장은 [id] 로 그 대화에 이어 쓴다.
class _Thread {
  _Thread({required this.temporary});

  final bool temporary;
  String? id;
}

/// 채팅 탭 상태. 질문 하나에 user 말풍선과 흘러나오는 assistant 말풍선 하나를 붙인다.
///
/// 대화는 [ChatSession](싱글턴)이 들고, 이 cubit 은 화면에 보일 말풍선만 들고 있다.
/// 탭이 소유한다(잠금 게이트 바깥) — 다시 잠겼다 풀려도 대화가 남는다.
///
/// 답 말풍선마다 [ChatProgress](진행 단계 · 경과 초)를 든다 — 세션 이벤트로 단계를 갱신하고
/// [_tick] 마다 경과 초를 올린다. 글 조각은 한 바퀴(이벤트 루프) 동안 모아 한 번에 그린다.
///
/// 임시 대화가 아니면 턴이 끝날 때(답 끝 · 글이 있는 멈춤)마다 [ChatHistoryRepository] 에
/// 저장한다. 임시 대화는 저장소에 한 행도 쓰지 않는다.
///
/// 입력칸 첨부([ChatState.pendingAttachments])는 [addFiles] 가 읽어 담고 [send] 가 질문과 함께
/// 보낸다. 일반 대화면 보내기 전에 작업 폴더 inbox 에 사본을 넣는다(임시 대화는 넣지 않는다).
class ChatCubit extends Cubit<ChatState> {
  ChatCubit(
    this._session,
    this._settings,
    this._diary,
    this._trace,
    this._choice,
    this._history,
    this._open,
    this._clock,
    this._workspace,
    this._loader, {
    void Function(VoidCallback) schedulePostFrame = _addPostFrame,
    Duration tick = const Duration(seconds: 1),
  }) : _schedulePostFrame = schedulePostFrame,
       _tick = tick,
       super(const ChatState(access: ChatAccess.checking));

  final ChatSession _session;
  final ChatSettings _settings;
  final DiaryRepository _diary;
  final ChatTrace _trace;

  /// 칩에 보일 지금 모델 · 탭이 열릴 때의 목록 갱신(24시간이 지났거나 · 키가 확인 전
  /// (unverified)이거나 · 목록 벤더가 연결 벤더와 다를 때만) · 사라진 모델 알림.
  final ChatModelChoice _choice;

  final ChatHistoryRepository _history;

  /// 지금 열린 저장 대화 id. 보관 정리가 이 대화를 건너뛴다.
  final OpenConversation _open;

  /// 진행의 시작 시각 · 경과 초.
  final Clock _clock;

  /// 보낼 첨부의 inbox 사본.
  final Workspace _workspace;

  /// 고른 파일 → 첨부.
  final AttachmentLoader _loader;

  /// 보내기 전 inbox 사본을 넣는 중. 그동안 다른 send · removePending 은 무시한다.
  bool _preparing = false;

  /// 진행 중인 질문의 첨부(본문 포함) — 글 없이 멈추면 입력칸에 되돌린다.
  List<ChatAttachment> _turnAttachments = const [];

  /// 담긴 첨부(객체) → 고른 원본 파일 경로. inbox 사본은 줄인 본문이 아니라 원본으로 넣는다.
  final _sources = Expando<String>('attachment source');

  /// 경과 초를 다시 재는 간격.
  final Duration _tick;

  /// 답하는 동안 경과 초를 올린다. 끝 · 실패 · 멈춤 · 새 대화 · 닫기에서 멈춘다.
  Timer? _ticker;

  /// 아직 그리지 않은 글 조각. 비어 있다 차면 [_textTimer] 하나가 다음 바퀴에 비운다.
  final StringBuffer _pendingText = StringBuffer();
  Timer? _textTimer;

  /// 프레임 쪽 표시(firstVisible · firstGlyph)를 찍을 때 쓴다. 위젯은 계측을 모른다.
  final void Function(VoidCallback) _schedulePostFrame;

  // 계측 — 질문 하나 동안의 상태. trace 가 꺼져 있으면 쓰지 않는다.
  int _traceToken = 0;
  bool _tracing = false;
  bool _sawVisible = false;
  bool _sawGlyph = false;

  /// 아직 그려지지 않은 프레임 표시 수. 0 이 될 때까지 end 를 미룬다.
  int _pendingFrames = 0;

  StreamSubscription<ChatEvent>? _sub;
  Completer<void>? _running;

  /// 지금 질문의 끝(ChatFinished)을 받아 인용을 읽는 중.
  bool _finishing = false;

  /// [newConversation] · [stop] 마다 올린다. 끊긴 질문의 늦은 결과(이벤트 · 인용 읽기)를 버린다.
  int _generation = 0;

  /// 지금 대화의 저장 위치.
  _Thread _thread = _Thread(temporary: false);

  /// 저장을 한 줄로 세운다 — 첫 턴이 만든 대화 id 를 다음 턴이 쓰고, seq 순서가 지켜진다.
  Future<void> _saveTail = Future.value();

  /// 지금 열린 대화가 있는지 지켜본다. 밖에서 지워지면 빈 새 대화가 된다.
  StreamSubscription<bool>? _existsSub;

  /// 진행 중인 질문 — 끝나거나 멈출 때 저장에 쓴다. [_turnTarget] 이 null 이면(모델 목록
  /// 없음) 그 질문은 noModels 로 끝나 저장하지 않는다.
  String _turnQuestion = '';
  ChatTarget? _turnTarget;

  /// 모든 emit 에서 [ChatState.attachBlock] 을 다시 센다 — 세션의 남은 자리(질문 · 되돌림 ·
  /// 새 대화 · 이어 열기마다 바뀐다)와 담긴 첨부로.
  @override
  void emit(ChatState state) =>
      super.emit(state.copyWith(attachBlock: _attachBlockOf(state)));

  AttachBlock? _attachBlockOf(ChatState state) {
    final pending = state.pendingAttachments;
    if (pending.length >= AttachmentRules.maxPerQuestion) {
      return AttachBlock.perQuestion;
    }
    final (:images, :docs) = _roomLeft(pending);
    return images <= 0 && docs <= 0 ? AttachBlock.conversation : null;
  }

  /// 이 대화의 남은 사진 · 문서 자리에서 담긴 첨부를 뺀 것.
  ({int images, int docs}) _roomLeft(List<ChatAttachment> pending) {
    final room = _session.attachmentRoom;
    final images = pending.whereType<ImageAttachment>().length;
    return (
      images: room.images - images,
      docs: room.docs - (pending.length - images),
    );
  }

  /// [name] 을 더 담을 자리가 없으면 그 이유. 형식은 로더가 본다.
  AttachmentRejection? _noRoomFor(String name) {
    final pending = state.pendingAttachments;
    if (pending.length >= AttachmentRules.maxPerQuestion) {
      return AttachmentRejection.perQuestionLimit;
    }
    final kind = AttachmentRules.kindOf(name);
    if (kind == null) return null;
    final (:images, :docs) = _roomLeft(pending);
    return switch (kind) {
      AttachmentKind.image when images <= 0 =>
        AttachmentRejection.conversationImageLimit,
      AttachmentKind.pdf || AttachmentKind.text when docs <= 0 =>
        AttachmentRejection.conversationDocLimit,
      _ => null,
    };
  }

  /// 고른 파일을 차례로 읽어 입력칸 첨부에 담는다. 자리가 없거나 로더가 거절한 파일은
  /// 빼고, 처음 거절한 것 하나를 [ChatState.attachmentNotice] 로 알린다.
  Future<void> addFiles(List<PickedFile> files) async {
    var noticed = false;
    for (final file in files) {
      if (isClosed) return;
      var why = _noRoomFor(file.name);
      if (why == null) {
        final load = await _loader.load(file);
        if (isClosed) return;
        switch (load) {
          case AttachmentLoaded(:final attachment):
            // 읽는 사이 담긴 것이 바뀌었을 수 있다 — 자리를 다시 본다.
            why = _noRoomFor(file.name);
            if (why == null) {
              _sources[attachment] = file.path;
              emit(
                state.copyWith(
                  pendingAttachments: [...state.pendingAttachments, attachment],
                ),
              );
              continue;
            }
          case AttachmentRejected(why: final rejected):
            why = rejected;
        }
      }
      if (!noticed) {
        noticed = true;
        emit(
          state.copyWith(
            attachmentNotice: AttachmentNotice(name: file.name, reason: why),
          ),
        );
      }
    }
  }

  /// 입력칸의 [index] 첨부를 뺀다. 보내려고 사본을 넣는 중이면 무시한다.
  void removePending(int index) {
    final pending = state.pendingAttachments;
    if (_preparing || index < 0 || index >= pending.length) return;
    emit(
      state.copyWith(
        pendingAttachments: [
          ...pending.sublist(0, index),
          ...pending.sublist(index + 1),
        ],
      ),
    );
  }

  /// 화면이 [ChatState.attachmentNotice] 를 알렸다.
  void consumeAttachmentNotice() {
    if (state.attachmentNotice == null) return;
    emit(state.copyWith(attachmentNotice: null));
  }

  /// 키 · 동의 · 모델 상태를 다시 읽는다. 탭이 보이게 될 때 · 위에 얹힌 화면이 걷힐 때 부른다.
  /// 보안 저장소를 읽지 못하면 키가 없는 것으로 본다.
  ///
  /// 키 · 동의가 있으면 모델을 본다(`ChatModelChoice` — 24시간 · unverified · 벤더 다름일
  /// 때만 받고, 받으면 키 상태도 기록된다).
  /// - 지금 모델이 있으면 곧바로 ready 를 내고 갱신은 뒤에서 — 끝나면 칩을 다시 읽는다.
  /// - 없으면 갱신을 기다린 뒤에도 없을 때 noModels(인증 오류면 [ChatState.modelsInvalidKey]).
  ///
  /// [recheck] 가 false 면 목록을 받지 않는다(탭이 보이지 않을 때 — 앱 시작에 다른 탭이
  /// 열려 있는 등). 그때 모델이 없으면 noModels 로 두고, 보이게 될 때 다시 부른다.
  Future<void> refresh({bool recheck = true}) =>
      _read(recheck: recheck, fetched: null);

  /// noModels 의 [다시 시도] — 목록을 강제로 받은 뒤 다시 읽는다.
  Future<void> retryModels() async {
    final result = await _choice.refresh(force: true);
    if (isClosed) return;
    await _read(recheck: false, fetched: result);
  }

  /// 모델 고르기 시트가 바꾼 뒤 칩을 다시 읽는다.
  void modelChanged() => _emitModel();

  /// 화면이 "고른 모델이 없어져…" 알림을 보였다.
  void consumeSelectionReplaced() {
    _choice.consumeSelectionReplacedNotice();
    if (state.selectionReplaced) {
      emit(state.copyWith(selectionReplaced: false));
    }
  }

  /// [fetched] 는 방금 받은 결과(retryModels) — 모델이 없어도 다시 받지 않는다.
  Future<void> _read({
    required bool recheck,
    required ModelsRefresh? fetched,
  }) async {
    bool hasKey;
    try {
      hasKey = await _settings.hasApiKey();
    } on Object {
      hasKey = false;
    }
    if (isClosed) return;
    // 동의는 벤더별 — 연결 벤더가 동의한 벤더와 다르면(벤더를 바꿨으면) 다시 묻는다.
    // 같은 벤더 키 교체 · 모델 변경은 묻지 않는다.
    final connected = _settings.connectedVendor;
    final access = switch ((hasKey, _settings.consentedVendor)) {
      (false, _) => ChatAccess.noKey,
      (_, final consented) when consented == null || consented != connected =>
        ChatAccess.needsConsent,
      _ => ChatAccess.ready,
    };
    if (access != ChatAccess.ready) {
      // 말풍선은 그대로 둔다 — 동의 뒤 ready 에서 대화를 잇는다.
      emit(
        state.copyWith(
          access: access,
          vendor: access == ChatAccess.needsConsent
              ? connected ?? _vendor()
              : _vendor(),
          model: null,
        ),
      );
      return;
    }
    if (_choice.currentModel != null) {
      _emitReady();
      if (recheck) {
        unawaited(
          Future.sync(
            _choice.refresh,
          ).then<void>((_) => _emitModel(), onError: (Object _) {}),
        );
      }
      return;
    }
    var result = fetched;
    if (result == null && recheck) {
      // 처음 받는 동안 "목록을 받지 못했어요" 가 보이지 않게 — 확인 중으로 둔다.
      emit(
        state.copyWith(
          access: ChatAccess.checking,
          vendor: _vendor(),
          model: null,
        ),
      );
      try {
        result = await _choice.refresh();
      } on Object {
        result = const ModelsRefresh.unreachable();
      }
      if (isClosed) return;
    }
    if (_choice.currentModel != null) {
      _emitReady();
      return;
    }
    emit(
      state.copyWith(
        access: ChatAccess.noModels,
        vendor: _vendor(),
        model: null,
        modelsInvalidKey: result is ModelsInvalidKey,
      ),
    );
  }

  void _emitReady() => emit(
    state.copyWith(
      access: ChatAccess.ready,
      vendor: _vendor(),
      model: ModelChipData.of(_choice),
      modelsInvalidKey: false,
      selectionReplaced: _choice.selectionReplacedNotice,
    ),
  );

  /// 칩 · 알림 표시를 [ChatModelChoice] 에서 다시 읽는다. ready 가 아니면 칩은 두지 않는다.
  void _emitModel() {
    if (isClosed) return;
    emit(
      state.copyWith(
        vendor: _vendor(),
        model: state.access == ChatAccess.ready
            ? ModelChipData.of(_choice)
            : null,
        selectionReplaced: _choice.selectionReplacedNotice,
      ),
    );
  }

  /// 배너 벤더 — 모델 목록이 없어도(target null) 연결 벤더로.
  ChatVendor _vendor() =>
      _session.target?.vendor ??
      _settings.connectedVendor ??
      ChatVendor.anthropic;

  /// 전송 동의 — 지금 연결된 벤더로 기록한다. 미연결이면 기록하지 않는다.
  Future<void> consent() async {
    final vendor = _settings.connectedVendor;
    if (vendor != null) await _settings.setConsented(vendor);
    await refresh();
  }

  /// 질문을 보낸다. 쓸 수 있는 상태(ready)가 아니거나 글 · 첨부가 다 비었거나 답하는 중 ·
  /// 대화를 읽어 들이는 중([ChatState.loading])이면 무시한다.
  /// 돌려주는 Future 는 답이 끝나거나(성공 · 실패) [newConversation] 으로 끊길 때 끝난다.
  /// 답이 끝났으면 그 턴의 저장 시도까지 끝난 뒤다.
  ///
  /// 입력칸 첨부를 함께 보내고 비운다. 글 없이 첨부만이면 질문은 [AttachmentRules.emptyQuestion].
  /// 일반 대화면 작업 폴더에 없는 첨부를 먼저 inbox 에 넣는다 — 넣지 못해도 보내고, 그 첨부는
  /// 경로 없이 저장된다. 넣는 사이 대화가 바뀌면 보내지 않는다(첨부는 입력칸에 남는다).
  /// 세션이 한도로 거절하면 보내지 않고 이유를 알린다.
  Future<void> send(String question) {
    final text = question.trim();
    final attachments = state.pendingAttachments;
    if (state.access != ChatAccess.ready ||
        (text.isEmpty && attachments.isEmpty) ||
        state.busy ||
        state.loading ||
        _preparing) {
      return Future.value();
    }
    final asked = text.isEmpty ? AttachmentRules.emptyQuestion : text;
    final needsCopy =
        !_thread.temporary && attachments.any((a) => a.workspacePath == null);
    if (!needsCopy) {
      return _ask(asked, attachments, sent: attachments, draft: text);
    }
    return _copyThenAsk(asked, attachments, draft: text);
  }

  /// 사본을 넣는 사이 대화가 바뀌었으면 보내지 않는다 — 입력칸이 이미 비운 글은 [draft] 로
  /// 되돌리고, 넣은 사본 경로는 입력칸 첨부에 달아 둔다(다시 보낼 때 또 넣지 않게).
  Future<void> _copyThenAsk(
    String question,
    List<ChatAttachment> attachments, {
    required String draft,
  }) async {
    final thread = _thread;
    final generation = _generation;
    _preparing = true;
    final stored = <ChatAttachment>[];
    try {
      for (final a in attachments) {
        stored.add(await _copyToInbox(a));
      }
    } finally {
      _preparing = false;
    }
    if (isClosed) return;
    if (!identical(thread, _thread) ||
        generation != _generation ||
        state.access != ChatAccess.ready ||
        state.busy ||
        state.loading) {
      _abandon(sent: attachments, stored: stored, draft: draft);
      return;
    }
    await _ask(question, stored, sent: attachments, draft: draft);
  }

  /// inbox 에 원본 사본을 넣고 그 경로를 단다. 이미 경로가 있거나 넣지 못하면 그대로.
  /// 원본 경로를 모르면(고른 파일이 아닌 첨부) 지금 본문을 넣는다.
  Future<ChatAttachment> _copyToInbox(ChatAttachment attachment) async {
    if (attachment.workspacePath != null) return attachment;
    final source = _sources[attachment];
    try {
      final bytes = source != null
          ? await _loader.readOriginal(source)
          : switch (attachment) {
              ImageAttachment(:final bytes) ||
              PdfAttachment(:final bytes) => bytes,
              TextAttachment(:final text) => utf8.encode(text),
            };
      final path = await _workspace.importToInbox(attachment.name, bytes);
      return attachment.copyWith(workspacePath: path);
    } on Object {
      return attachment;
    }
  }

  /// 보내지 못한 질문 — [draft](글이 있으면)를 입력칸에 되돌리고, 입력칸 첨부 중 [sent] 를
  /// 사본 경로를 단 [stored] 로 바꾼다. [notice] 가 있으면 함께 알린다.
  void _abandon({
    required List<ChatAttachment> sent,
    required List<ChatAttachment> stored,
    required String draft,
    AttachmentNotice? notice,
  }) {
    emit(
      state.copyWith(
        restoredDraft: draft.isEmpty ? state.restoredDraft : draft,
        pendingAttachments: [
          for (final a in state.pendingAttachments)
            switch (sent.indexWhere((s) => identical(s, a))) {
              -1 => a,
              final i => stored[i],
            },
        ],
        attachmentNotice: notice ?? state.attachmentNotice,
      ),
    );
  }

  /// [sent] 는 입력칸에서 빼낼 원래 첨부(사본 경로를 달기 전, [attachments] 와 같은 순서).
  /// 그 사이 새로 담긴 것은 남는다. [draft] 는 입력칸에 쓴 글 — 보내지 못하면 되돌린다.
  Future<void> _ask(
    String question,
    List<ChatAttachment> attachments, {
    required List<ChatAttachment> sent,
    required String draft,
  }) {
    final Stream<ChatEvent> events;
    try {
      events = attachments.isEmpty
          ? _session.ask(question)
          : _session.ask(question, attachments: attachments);
    } on StateError {
      // 세션이 아직 이전 질문을 돌리는 중 — 이 cubit 이 모르는 질문이다. 보내지 않는다.
      return Future.value();
    } on ArgumentError {
      // 화면이 먼저 막지만 그 사이 자리가 줄었을 수 있다(이어 연 대화 등) — 이유를 알리고
      // 글 · 첨부는 입력칸에 남긴다.
      _abandon(
        sent: sent,
        stored: attachments,
        draft: draft,
        notice: AttachmentNotice(
          name: attachments.first.name,
          reason: _limitOf(attachments),
        ),
      );
      return Future.value();
    }
    final text = question;
    _turnQuestion = text;
    _turnAttachments = attachments;
    _turnTarget = _session.target;
    _traceBegin();
    final generation = _generation;
    final running = _running = Completer<void>();
    _finishing = false;
    emit(
      state.copyWith(
        bubbles: [
          ...state.bubbles,
          ChatBubble(
            role: ChatRole.user,
            text: text,
            attachments: [for (final a in attachments) a.ref],
          ),
          ChatBubble(
            role: ChatRole.assistant,
            text: '',
            progress: ChatProgress(
              startedAt: _clock.now(),
              steps: const [ChatProgressStep.sending()],
            ),
          ),
        ],
        busy: true,
        pendingAttachments: [
          for (final a in state.pendingAttachments)
            if (!sent.any((s) => identical(s, a))) a,
        ],
      ),
    );
    _startTicker();
    _sub = events.listen(
      (event) => unawaited(_onEvent(event, generation)),
      onError: (Object _) => _fail(ChatFailure.unknown, generation),
      onDone: () => _settle(generation),
    );
    return running.future;
  }

  /// 세션이 거절한 첨부 한도 — 개수 · 사진 · 문서 중 무엇에 걸렸나.
  AttachmentRejection _limitOf(List<ChatAttachment> attachments) {
    if (attachments.length > AttachmentRules.maxPerQuestion) {
      return AttachmentRejection.perQuestionLimit;
    }
    final images = attachments.whereType<ImageAttachment>().length;
    return images > _session.attachmentRoom.images
        ? AttachmentRejection.conversationImageLimit
        : AttachmentRejection.conversationDocLimit;
  }

  /// 대화를 비운다. 답하는 중이면 끊는다 — 세션은 그 질문의 이벤트를 더 내지 않는다.
  void newConversation() => _startFresh(temporary: false);

  /// 지금 대화를 닫고 빈 임시 대화를 연다. 임시 대화는 저장소에 아무것도 쓰지 않는다.
  void startTemporary() => _startFresh(temporary: true);

  /// 저장된 대화를 연다. 답하는 중이면 끊는다([newConversation] 과 같은 규칙). 임시 대화였으면
  /// 사라진다. 말풍선 · 근거 칩(휴지통 · 없는 기록 빼고) · stopped · seq 를 복원하고 세션을
  /// 그 턴들로 이어간다. 그 대화가 없으면(사이에 지워짐) 빈 새 대화.
  ///
  /// 읽는 동안 [ChatState.loading] — 그 사이 보낸 질문은 무시한다(곧 다시 그려 잃게 되므로).
  /// 읽는 동안에도 [OpenConversation.id] 는 [conversationId] 다 — 보관 정리가 건너뛰게.
  /// 줄 선 저장(지난 턴)이 끝난 뒤 읽는다 — 같은 대화를 다시 열어도 그 턴이 보이게.
  Future<void> open(String conversationId) async {
    _startFresh(temporary: false, loading: true, openId: conversationId);
    final thread = _thread;
    try {
      await _saveTail;
    } on Object {
      // 저장 실패는 _write 가 삼킨다. 여기선 읽기만 이어간다.
    }
    if (isClosed || !identical(thread, _thread)) return;
    await _load(conversationId, thread);
  }

  /// [assistantIndex] 의 답을 작업 폴더 out/ 에 `.md` 로 저장하고 상대 경로를 돌려준다.
  /// 글이 없는 말풍선 · 실패 · 쓰기 오류면 null. 임시 대화에서도 저장한다(사용자가 직접 고른 동작).
  /// 모델은 마지막으로 묻은 턴의 모델(없으면 지금 고른 모델) — 열어 본 옛 대화는 정확하지 않을 수 있다.
  Future<String?> saveAnswer(int assistantIndex) async {
    final answer = _bubbleAt(assistantIndex);
    if (answer == null ||
        answer.role != ChatRole.assistant ||
        answer.failure != null ||
        answer.text.trim().isEmpty) {
      return null;
    }
    final question = _bubbleAt(assistantIndex - 1);
    final questionText = question?.role == ChatRole.user ? question!.text : '';
    final at = _clock.now();
    try {
      return await _workspace.writeOut(
        AnswerFile.fileName(at, questionText),
        AnswerFile.markdown(
          question: questionText,
          answer: answer.text,
          model: _turnTarget?.model ?? _session.target?.model ?? '',
          at: at,
          attachmentNames: [
            for (final a in question?.attachments ?? const []) a.name,
          ],
        ),
      );
    } on Object {
      return null;
    }
  }

  /// [userIndex] 의 질문과 그 답 말풍선을 지운다. 답하는 중이면 무시한다.
  ///
  /// 저장된 턴이면 저장소에서 지우고 남은 턴으로 다시 연다(남은 턴이 없으면 빈 새 대화).
  /// 임시 대화 · 저장 전 턴은 화면에서 빼고 남은 쌍으로 세션을 이어간다. 실패한 쌍은
  /// 화면에서만 뺀다(세션은 그 질문을 이미 되돌렸다).
  ///
  /// 끝날 때까지 [ChatState.loading] — 그 사이 보낸 질문은 무시한다.
  Future<void> deleteTurn(int userIndex) async {
    if (state.busy || state.loading) return;
    final target = _bubbleAt(userIndex);
    if (target == null || target.role != ChatRole.user) return;
    final thread = _thread;
    emit(state.copyWith(loading: true));
    try {
      // 줄 선 저장이 끝나야 seq 가 붙는다 — 그 뒤 같은 말풍선을 다시 찾는다.
      await _saveTail;
      if (isClosed || !identical(thread, _thread)) return;
      final index = _indexOf(target, near: userIndex);
      if (index == null) return;
      final user = state.bubbles[index];
      final answer = _bubbleAt(index + 1);
      final pairEnd = answer?.role == ChatRole.assistant
          ? index + 2
          : index + 1;
      final seq = user.seq;
      final id = state.conversationId;

      if (seq != null && id != null && !thread.temporary) {
        try {
          await _history.deleteTurn(id, seq);
        } on Object {
          return;
        }
        if (isClosed || !identical(thread, _thread)) return;
        // 새 thread 가 loading 을 이어받고 _load 가 끝에 내린다.
        _startFresh(
          temporary: false,
          keepScreen: true,
          loading: true,
          openId: id,
        );
        await _load(id, _thread);
        return;
      }

      final bubbles = [
        ...state.bubbles.sublist(0, index),
        ...state.bubbles.sublist(pairEnd),
      ];
      emit(state.copyWith(bubbles: bubbles));
      if (answer?.failure != null) return;
      _session.resume(_turnsOf(bubbles), temporary: thread.temporary);
    } finally {
      // 대화가 바뀌었으면 loading 은 새 대화의 것이다.
      if (!isClosed && identical(thread, _thread) && state.loading) {
        emit(state.copyWith(loading: false));
      }
    }
  }

  /// 답하는 중이면 멈춘다. 같은 emit 에서 busy: false. 인용을 읽는 중(_finishing)이면
  /// 무시한다(답은 이미 끝났다).
  ///
  /// 받은 글이 있으면 그 말풍선을 [ChatBubble.stopped] 로 남기고 그때까지의 인용을 붙인다.
  /// 글이 없으면 질문 · 답 말풍선을 지우고 질문을 [ChatState.restoredDraft] 로 돌려준다.
  void stop() {
    if (!state.busy || _finishing) return;
    // 남은 글 조각을 먼저 — 멈춤 글과 화면 순서가 어긋나지 않게.
    _flushText();
    _generation++;
    // 세션을 먼저 멈춘다 — 구독 취소를 기다린 뒤 부르면 그 사이 질문이 스스로 되돌려져
    // 받은 글을 잃는다. 취소는 기다리지 않는다(세션 루프는 stop 으로 이미 끝났다).
    final result = _session.stop();
    unawaited(_sub?.cancel());
    _sub = null;
    if (_trace.enabled && _tracing) _trace.mark(ChatTraceMark.userStop);
    switch (result) {
      case ChatStopKept(:final text, :final citedEntryIds):
        // 세션이 남긴 글이 기준이다 — 다음 문맥에 들어가는 것과 화면이 같게.
        final bubbles = _settled(
          _withLast((b) => b.copyWith(text: text, stopped: true)),
          stopped: true,
        );
        emit(state.copyWith(bubbles: bubbles, busy: false));
        if (citedEntryIds.isNotEmpty && bubbles.isNotEmpty) {
          unawaited(
            _attachCited(
              citedEntryIds,
              bubbles.length - 1,
              bubbles.last,
              _thread,
            ),
          );
        }
        unawaited(_saveLastTurn(citedEntryIds, stopped: true));
      case ChatStopDropped():
        // 말풍선이 사라지므로 진행도 함께 사라진다.
        _stopTicker();
        final bubbles = state.bubbles;
        final user = bubbles.length >= 2 ? bubbles[bubbles.length - 2] : null;
        // 글 없이 첨부만 보낸 질문이면 채운 문구는 입력칸에 되돌리지 않는다.
        final question =
            user != null &&
                user.attachments.isNotEmpty &&
                user.text == AttachmentRules.emptyQuestion
            ? ''
            : user?.text;
        emit(
          state.copyWith(
            bubbles: bubbles.length >= 2
                ? bubbles.sublist(0, bubbles.length - 2)
                : const [],
            busy: false,
            restoredDraft: question,
            // 첨부도 입력칸에 되돌린다(넣은 사본 경로째 — 다시 넣지 않는다).
            pendingAttachments: [
              ..._turnAttachments,
              ...state.pendingAttachments,
            ].take(AttachmentRules.maxPerQuestion).toList(),
          ),
        );
      case ChatStopIdle():
        // 세션은 이미 끝났다 — 화면만 정리한다.
        _end(state.bubbles);
    }
    _traceDone();
    _complete();
  }

  /// 화면이 [ChatState.restoredDraft] 를 입력칸에 채웠다.
  void consumeRestoredDraft() {
    if (state.restoredDraft == null) return;
    emit(state.copyWith(restoredDraft: null));
  }

  /// 멈춘 말풍선([index] 의 [stopped])에 인용을 붙인다. 그 사이 다음 질문을 보냈어도
  /// 같은 말풍선이다. 대화를 바꿨거나([thread]) 비웠으면(그 자리에 다른 말풍선 · 없음) 버린다.
  Future<void> _attachCited(
    List<String> ids,
    int index,
    ChatBubble stopped,
    _Thread thread,
  ) async {
    final cited = await _resolve(ids);
    if (isClosed || !identical(thread, _thread)) return;
    final bubbles = state.bubbles;
    if (index >= bubbles.length || !_same(bubbles[index], stopped)) return;
    emit(
      state.copyWith(
        bubbles: [
          for (final (i, b) in bubbles.indexed)
            i == index ? b.copyWith(cited: cited) : b,
        ],
      ),
    );
  }

  Future<void> _onEvent(ChatEvent event, int generation) async {
    if (generation != _generation || isClosed) return;
    if (event case ChatText(:final delta)) {
      _bufferText(delta);
      return;
    }
    // 다른 이벤트 앞에서 모아 둔 글을 먼저 그린다 — 글과 진행 순서가 어긋나지 않게.
    _flushText();
    switch (event) {
      case ChatText():
        break;
      case ChatPhaseChanged(phase: ChatPhase.thinking):
        _updateProgress(
          (p) => p.current is StepThinking
              ? p
              : _push(p, const ChatProgressStep.thinking()),
        );
      case ChatPhaseChanged(phase: ChatPhase.writing):
        // 쓰기 단계는 한 번만 — 도구 뒤 다음 라운드에서 다시 쓰면 그 단계를 맨 뒤로 옮긴다.
        _updateProgress(
          (p) => p.current is StepWriting
              ? p
              : p.copyWith(
                  steps: [
                    for (final s in p.steps)
                      if (s is! StepWriting) s,
                    const ChatProgressStep.writing(),
                  ],
                ),
        );
      // 보내는 중은 send 가 이미 넣었다.
      case ChatPhaseChanged(phase: ChatPhase.sending):
        break;
      case ChatProgressNote(:final note):
        _updateProgress(
          (p) => p.current is StepNote
              ? p.copyWith(
                  steps: [
                    ...p.steps.sublist(0, p.steps.length - 1),
                    ChatProgressStep.note(note),
                  ],
                )
              : _push(p, ChatProgressStep.note(note)),
        );
        if (_trace.enabled) _traceVisible();
      case ChatToolStarted(:final callId, :final name, :final input):
        _updateProgress(
          (p) => _moveTool(
            p,
            callId,
            update: (t) => t.copyWith(input: input ?? t.input),
            create: () => ChatProgressStep.tool(
              callId: callId,
              kind: chatToolKindOf(name),
              input: input,
            ),
          ),
        );
        if (_trace.enabled) _traceVisible();
      case ChatToolFinished(:final callId, :final name, :final summary):
        _updateProgress(
          (p) => _moveTool(
            p,
            callId,
            update: (t) => t.copyWith(result: summary),
            create: () => ChatProgressStep.tool(
              callId: callId,
              kind: chatToolKindOf(name),
              result: summary,
            ),
          ),
        );
      case ChatRoundStarted():
        break;
      case ChatFinished(:final citedEntryIds):
        _finishing = true;
        // 경과 초는 답이 끝난 때로 고정한다(인용을 읽는 시간은 넣지 않는다).
        emit(state.copyWith(bubbles: _settled(state.bubbles)));
        final running = _running;
        // 인용을 읽기 전에 지금 대화(thread)로 저장을 줄 세운다 — 읽는 사이 [새 대화] · open 해도
        // 끝난 답은 저장된다(화면에 붙일지는 _write 가 thread 로 가린다).
        final saved = _saveLastTurn(citedEntryIds, stopped: false);
        final cited = await _resolve(citedEntryIds);
        if (generation != _generation || isClosed) return;
        _end(_withLast((b) => b.copyWith(cited: cited)), complete: false);
        // send 의 Future 는 저장 시도까지 끝난 뒤에 끝난다.
        await saved;
        if (running != null && !running.isCompleted) running.complete();
        if (identical(_running, running)) _running = null;
      case ChatFailed(:final failure):
        _fail(failure, generation);
    }
  }

  void _fail(ChatFailure failure, int generation) {
    if (generation != _generation || isClosed) return;
    _flushText();
    _end(_withLast((b) => b.copyWith(failure: failure)));
    // 세션이 목록을 다시 받아 지금 모델이 바뀌었다 — 칩도 새 모델로. 말풍선이 이미
    // 바뀐 것을 알리므로 "고른 모델이 없어져…" 알림은 함께 보이지 않게 지운다.
    if (failure == ChatFailure.modelReplaced) {
      _choice.consumeSelectionReplacedNotice();
      _emitModel();
    }
  }

  /// 끝 이벤트 없이 스트림이 닫혔다(세션이 조용히 멈춤). 인용을 읽는 중이면 그쪽이 끝낸다.
  void _settle(int generation) {
    if (generation != _generation || isClosed) return;
    _flushText();
    if (state.busy && !_finishing) _end(state.bubbles);
  }

  void _end(List<ChatBubble> bubbles, {bool complete = true}) {
    emit(state.copyWith(bubbles: _settled(bubbles), busy: false));
    _traceDone();
    if (complete) _complete();
  }

  /// 대화를 끊고 빈 새 대화(또는 임시 대화)로 둔다. [keepScreen] 이면 말풍선은 그대로 두고
  /// (곧 [_load] 가 다시 그린다) 세션 · 저장 위치만 바꾼다. [loading] 은 곧 [_load] 가 이어
  /// 읽을 때 true. [openId] 는 곧 [_load] 가 읽을 대화 — 읽는 동안 [OpenConversation.id] 를
  /// 그 id 로 둬서 보관 정리가 지우지 않게 한다(턴이 없으면 [_load] 가 비운다).
  void _startFresh({
    required bool temporary,
    bool keepScreen = false,
    bool loading = false,
    String? openId,
  }) {
    _flushText();
    _stopTicker();
    _generation++;
    _thread = _Thread(temporary: temporary);
    unawaited(_sub?.cancel());
    _sub = null;
    _session.reset(temporary: temporary);
    // reset 뒤에 닫는다 — 어댑터가 끊으며 찍는 abort 가 이번 질문 기록에 들어가게.
    if (state.busy) _traceDone();
    _complete();
    emit(
      state.copyWith(
        bubbles: keepScreen ? state.bubbles : const [],
        busy: false,
        temporary: temporary,
        loading: loading,
      ),
    );
    _setConversation(null);
    if (openId != null) _open.id = openId;
  }

  /// 저장된 [id] 의 턴으로 화면과 세션을 채운다. 그 사이 다른 대화로 바뀌었으면([thread]) 버린다.
  /// 턴이 없거나 읽지 못하면 빈 새 대화로 둔다. 끝나면(지금 대화일 때) loading 을 내린다.
  Future<void> _load(String id, _Thread thread) async {
    List<ChatTurnRecord> turns;
    try {
      turns = await _history.turns(id);
    } on Object {
      turns = const [];
    }
    if (isClosed || !identical(thread, _thread)) return;
    if (turns.isEmpty) {
      emit(state.copyWith(bubbles: const [], loading: false));
      _open.id = null;
      return;
    }
    final citedByTurn = await Future.wait([
      for (final turn in turns) _resolve(turn.citedEntryIds),
    ]);
    final bubbles = <ChatBubble>[];
    for (final (i, turn) in turns.indexed) {
      final cited = citedByTurn[i];
      bubbles
        ..add(
          ChatBubble(
            role: ChatRole.user,
            text: turn.question,
            seq: turn.seq,
            attachments: turn.attachments,
          ),
        )
        ..add(
          ChatBubble(
            role: ChatRole.assistant,
            text: turn.answer,
            cited: cited,
            stopped: turn.stopped,
            seq: turn.seq,
          ),
        );
    }
    if (isClosed || !identical(thread, _thread)) return;
    thread.id = id;
    _session.resume([for (final t in turns) t.text], temporary: false);
    emit(state.copyWith(bubbles: bubbles, loading: false));
    _setConversation(id);
  }

  /// 마지막 턴(질문 · 답 말풍선)을 저장한다. 임시 대화 · 빈 답 · 실패는 저장하지 않는다.
  /// 저장이 던지면 조용히 넘어간다 — 말풍선은 남고 다음 턴이 다시 시도한다.
  Future<void> _saveLastTurn(
    List<String> citedEntryIds, {
    required bool stopped,
  }) {
    final thread = _thread;
    final target = _turnTarget;
    final bubbles = state.bubbles;
    if (thread.temporary || target == null || bubbles.length < 2) {
      return Future.value();
    }
    final userIndex = bubbles.length - 2;
    final user = bubbles[userIndex];
    final answer = bubbles.last;
    if (answer.failure != null || answer.text.trim().isEmpty) {
      return Future.value();
    }
    final draft = ChatTurnDraft(
      question: _turnQuestion,
      answer: answer.text,
      citedEntryIds: citedEntryIds,
      stopped: stopped,
      vendor: target.vendor,
      model: target.model,
      attachments: user.attachments,
    );
    final saved = _saveTail.then(
      (_) => _write(thread, draft, userIndex, user, answer),
    );
    _saveTail = saved;
    return saved;
  }

  Future<void> _write(
    _Thread thread,
    ChatTurnDraft draft,
    int userIndex,
    ChatBubble user,
    ChatBubble answer,
  ) async {
    final ChatTurnRef ref;
    try {
      ref = await _history.appendTurn(conversationId: thread.id, turn: draft);
    } on Object {
      return;
    }
    thread.id = ref.conversationId;
    // 그 사이 새 대화 · 다른 대화 · 임시 대화로 바뀌었으면 화면에 붙이지 않는다(행은 목록에 있다).
    if (isClosed || !identical(thread, _thread)) return;
    final bubbles = state.bubbles;
    final matches =
        userIndex + 1 < bubbles.length &&
        _same(bubbles[userIndex], user) &&
        _same(bubbles[userIndex + 1], answer);
    if (matches) {
      emit(
        state.copyWith(
          bubbles: [
            for (final (i, b) in bubbles.indexed)
              i == userIndex || i == userIndex + 1
                  ? b.copyWith(seq: ref.seq)
                  : b,
          ],
        ),
      );
    }
    _setConversation(ref.conversationId);
  }

  /// 열린 대화를 바꾼다 — 상태 · [OpenConversation] · 지워짐 감시를 함께.
  void _setConversation(String? id) {
    if (isClosed) return;
    if (state.conversationId != id) emit(state.copyWith(conversationId: id));
    if (_open.id == id && (id == null || _existsSub != null)) return;
    _open.id = id;
    unawaited(_existsSub?.cancel());
    _existsSub = null;
    if (id == null) return;
    _existsSub = _history.watchExists(id).listen((exists) {
      if (!exists && !isClosed && state.conversationId == id) {
        newConversation();
      }
    }, onError: (Object _) {});
  }

  /// 남은 말풍선에서 세션에 넘길 턴. 실패한 쌍 · 답 없는 질문은 뺀다.
  List<ChatTurnText> _turnsOf(List<ChatBubble> bubbles) => [
    for (var i = 0; i + 1 < bubbles.length; i++)
      if (bubbles[i].role == ChatRole.user &&
          bubbles[i + 1].role == ChatRole.assistant &&
          bubbles[i + 1].failure == null)
        ChatTurnText(
          question: bubbles[i].text,
          answer: bubbles[i + 1].text,
          stopped: bubbles[i + 1].stopped,
          attachmentNames: [for (final a in bubbles[i].attachments) a.name],
        ),
  ];

  ChatBubble? _bubbleAt(int index) =>
      index >= 0 && index < state.bubbles.length ? state.bubbles[index] : null;

  /// [bubble] 이 아직 [near] 에 있으면 그 index(저장이 seq 를 붙였을 수 있다). 아니면 null.
  int? _indexOf(ChatBubble bubble, {required int near}) {
    final at = _bubbleAt(near);
    return at != null && _same(at, bubble) ? near : null;
  }

  /// 저장 · 인용 붙이기가 바꾸는 seq · cited 를 빼고 같은 말풍선인가.
  /// 진행(경과 초 · 끝맺음)도 빼고 본다 — 저장 뒤에 바뀐다.
  static bool _same(ChatBubble a, ChatBubble b) =>
      identical(a, b) ||
      a.copyWith(seq: null, cited: const [], progress: null) ==
          b.copyWith(seq: null, cited: const [], progress: null);

  void _traceBegin() {
    if (!_trace.enabled) return;
    _traceToken++;
    _tracing = true;
    _sawVisible = false;
    _sawGlyph = false;
    _pendingFrames = 0;
    _trace
      ..begin()
      ..mark(ChatTraceMark.send);
  }

  void _traceVisible() {
    if (_sawVisible) return;
    _sawVisible = true;
    _markAfterFrame(ChatTraceMark.firstVisible);
  }

  /// emit 이 그려진 프레임 뒤에 찍는다. 그 사이 질문이 끝났으면 end 는 이 표시 뒤로 미뤄져 있다.
  void _markAfterFrame(String label) {
    final token = _traceToken;
    _pendingFrames++;
    _schedulePostFrame(() {
      if (token != _traceToken) return;
      _pendingFrames--;
      _trace.mark(label);
      if (!_tracing && _pendingFrames == 0) _trace.end();
    });
  }

  /// done 을 찍고, 그려지지 않은 프레임 표시가 없으면 바로 요약을 낸다.
  void _traceDone() {
    if (!_trace.enabled || !_tracing) return;
    _tracing = false;
    _trace.mark(ChatTraceMark.done);
    if (_pendingFrames == 0) _trace.end();
  }

  /// 인용 id 를 기록으로. 휴지통 · 없는 기록 · 읽기 실패는 뺀다.
  Future<List<DiaryEntry>> _resolve(List<String> ids) async {
    final entries = <DiaryEntry>[];
    for (final id in ids) {
      try {
        if (await _diary.entry(id) case Ok(
          :final value,
        ) when !value.isTrashed) {
          entries.add(value);
        }
      } on Object {
        // 한 기록을 못 읽어도 답은 보인다.
      }
    }
    return entries;
  }

  /// 마지막(assistant) 말풍선만 바꾼 목록.
  List<ChatBubble> _withLast(ChatBubble Function(ChatBubble) update) {
    final bubbles = state.bubbles;
    if (bubbles.isEmpty) return bubbles;
    return [...bubbles.sublist(0, bubbles.length - 1), update(bubbles.last)];
  }

  /// 글 조각을 모은다. 버퍼가 비어 있다 차면 다음 바퀴에 비울 타이머 하나를 건다.
  void _bufferText(String delta) {
    if (delta.isEmpty) return;
    final wasEmpty = _pendingText.isEmpty;
    _pendingText.write(delta);
    if (wasEmpty) _textTimer = Timer(Duration.zero, _flushText);
  }

  /// 모은 글을 마지막 말풍선에 붙여 한 번 emit 한다. 첫 글이면 그 프레임 뒤에 firstGlyph.
  void _flushText() {
    _textTimer?.cancel();
    _textTimer = null;
    if (_pendingText.isEmpty) return;
    final delta = _pendingText.toString();
    _pendingText.clear();
    if (isClosed) return;
    emit(
      state.copyWith(
        bubbles: _withLast((b) => b.copyWith(text: b.text + delta)),
      ),
    );
    if (_trace.enabled) {
      _traceVisible();
      if (!_sawGlyph) {
        _sawGlyph = true;
        _markAfterFrame(ChatTraceMark.firstGlyph);
      }
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(_tick, (_) {
      if (isClosed) return;
      _updateProgress((p) => p.copyWith(elapsedSeconds: _elapsed(p)));
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  int _elapsed(ChatProgress progress) =>
      _clock.now().difference(progress.startedAt).inSeconds;

  /// 진행 중인 마지막 말풍선의 진행을 바꾼다. 같으면 emit 하지 않는다.
  void _updateProgress(ChatProgress Function(ChatProgress) update) {
    final progress = state.bubbles.lastOrNull?.progress;
    if (progress == null || !progress.running) return;
    final next = update(progress);
    if (next == progress) return;
    emit(state.copyWith(bubbles: _withLast((b) => b.copyWith(progress: next))));
  }

  static ChatProgress _push(ChatProgress progress, ChatProgressStep step) =>
      progress.copyWith(steps: [...progress.steps, step]);

  /// 같은 [callId] 의 도구 단계를 [update] 해 맨 뒤(지금 단계)로 옮긴다. 없으면 [create] 를 붙인다.
  static ChatProgress _moveTool(
    ChatProgress progress,
    String callId, {
    required StepTool Function(StepTool) update,
    required ChatProgressStep Function() create,
  }) {
    final steps = progress.steps;
    final index = steps.indexWhere((s) => s is StepTool && s.callId == callId);
    if (index < 0) return _push(progress, create());
    return progress.copyWith(
      steps: [
        ...steps.sublist(0, index),
        ...steps.sublist(index + 1),
        update(steps[index] as StepTool),
      ],
    );
  }

  /// 마지막 말풍선의 진행을 끝맺는다 — 경과 초를 고정하고, 요약을 남기지 않으면(3초 미만 ·
  /// 멈추지 않음) 지운다. [stopped] 면 멈춤 단계를 붙인다. 경과 초 타이머도 멈춘다.
  List<ChatBubble> _settled(List<ChatBubble> bubbles, {bool stopped = false}) {
    _stopTicker();
    final last = bubbles.lastOrNull;
    final progress = last?.progress;
    if (last == null || progress == null || !progress.running) return bubbles;
    final done = progress.copyWith(
      running: false,
      elapsedSeconds: _elapsed(progress),
      steps: stopped
          ? [...progress.steps, const ChatProgressStep.stopped()]
          : progress.steps,
    );
    return [
      ...bubbles.sublist(0, bubbles.length - 1),
      last.copyWith(progress: done.keepSummary ? done : null),
    ];
  }

  void _complete() {
    final running = _running;
    _running = null;
    if (running != null && !running.isCompleted) running.complete();
  }

  @override
  Future<void> close() async {
    _flushText();
    _stopTicker();
    _generation++;
    unawaited(_existsSub?.cancel());
    _existsSub = null;
    _open.id = null;
    // 기다리지 않는다 — 응답을 기다리는 중인 세션 스트림은 취소가 늦게 끝날 수 있다.
    unawaited(_sub?.cancel());
    // 세션은 싱글턴이다. 답하는 중에 닫혀도 다음 cubit 이 ask 할 수 있게 비운다.
    _session.reset();
    // reset 뒤에 닫는다 — 어댑터가 끊으며 찍는 abort 가 이번 질문 기록에 들어가게.
    if (state.busy) _traceDone();
    _complete();
    return super.close();
  }
}
