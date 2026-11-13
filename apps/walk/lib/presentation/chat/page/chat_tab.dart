import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/attachment/attachment_loader.dart';
import '../../../domain/chat/attachment/chat_attachment.dart';
import '../../../domain/chat/chat_settings.dart';
import '../../../domain/chat/chat_trace.dart';
import '../../../domain/chat/chat_vendor.dart';
import '../../../domain/chat/repository/chat_history_repository.dart';
import '../../../domain/chat/secure_window.dart';
import '../../../domain/chat/usecase/chat_model_choice.dart';
import '../../../domain/chat/usecase/chat_session.dart';
import '../../../domain/chat/usecase/open_conversation.dart';
import '../../../domain/chat/workspace/workspace.dart';
import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../diary/page/diary_route.dart';
import '../../diary/viewer/story_viewer_page.dart';
import '../../lock/cubit/diary_lock_cubit.dart';
import '../../lock/cubit/diary_lock_state.dart';
import '../../lock/widget/diary_lock_gate.dart';
import '../../settings/open_settings.dart';
import '../attachment/attachment_notice_text.dart';
import '../attachment/chat_file_picker.dart';
import '../../shell/widget/feature_menu.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_progress.dart';
import '../cubit/chat_state.dart';
import '../widget/bubble_actions_sheet.dart';
import '../widget/chat_bubble_view.dart';
import '../widget/chat_consent_view.dart';
import '../widget/chat_examples.dart';
import '../widget/chat_input.dart';
import '../widget/chat_jump_to_latest.dart';
import '../widget/model_chip.dart';
import '../widget/model_picker_sheet.dart';
import '../widget/temporary_chat_banner.dart';
import '../wiki/cubit/wiki_edit_state.dart';
import '../wiki/open_wiki.dart';
import '../workspace/open_workspace.dart';
import '../wiki/widget/wiki_candidates_sheet.dart';
import 'chat_history_page.dart';

/// 셸의 물어보기 탭: 내 일기 · 걸음 · 기상 기록에 묻는 채팅.
///
/// 대화 내용은 일기에서 나오므로 [DiaryLockGate] 안쪽에 둔다 — 잠긴 동안 트리에 없다.
/// cubit 은 게이트 바깥(이 State)이 소유해 다시 잠겼다 풀려도 대화가 남는다.
/// 위에서 `DiaryLockCubit` 를 받는다(셸이 소유). 앱바 ⋮ 는 대화 목록 · 위키 · 위키로 정리(저장된
/// 대화가 열려 있고 답하는 중이 아닐 때) · 임시 대화로 시작(키가 있을 때) · 물어보기 설정 ·
/// 앱 설정(잠긴 동안은 앱 설정만)이고, 셸의 설정 cubit 아래에서 연다([openSettings]).
///
/// 임시 대화가 열려 있고 탭이 보이는 동안 창 캡처를 막는다([SecureWindow]). 잠겨 있어도 ·
/// 위에 화면이 얹혀도 켠 채 둔다(스펙 §2).
///
/// 키 · 동의는 탭이 보이게 될 때와 위에 얹힌 화면(물어보기 설정 등)이 걷힐 때 다시 읽는다.
class ChatTab extends StatefulWidget {
  const ChatTab({
    required this.active,
    required this.onOpenSettings,
    super.key,
  });

  /// 셸에서 이 탭이 보이는지. 보이게 될 때 키 · 동의를 다시 읽는다.
  final bool active;

  /// 키가 없을 때 · 키 문제로 답이 실패했을 때 [설정 열기] — 셸이 물어보기 설정 화면을 연다.
  final VoidCallback onOpenSettings;

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> with RouteAware {
  late final _cubit = ChatCubit(
    getIt<ChatSession>(),
    getIt<ChatSettings>(),
    getIt<DiaryRepository>(),
    getIt<ChatTrace>(),
    getIt<ChatModelChoice>(),
    getIt<ChatHistoryRepository>(),
    getIt<OpenConversation>(),
    getIt<Clock>(),
    getIt<Workspace>(),
    getIt<AttachmentLoader>(),
    getIt<ChatFilePicker>(),
  );

  late final _secure = getIt<SecureWindow>();

  /// 마지막으로 [SecureWindow] 에 보낸 값. 같은 값은 다시 보내지 않는다.
  bool _secureOn = false;

  /// 탭이 보이고 임시 대화일 때만 창 캡처를 막는다.
  void _syncSecure() {
    final want = widget.active && _cubit.state.temporary;
    if (want == _secureOn) return;
    _secureOn = want;
    unawaited(_secure.setSecure(want));
  }

  /// ⋮ [대화 목록]. 행을 고르면 그 대화를 연다. 잠금 아래 화면이다.
  Future<void> _openHistory() async {
    final id = await pushDiaryRoute<String>(
      context,
      page: (_) => const ChatHistoryPage(),
    );
    if (id != null && mounted) await _cubit.open(id);
  }

  /// ⋮ [위키]. 메모에서 [대화 보기]를 고르면 그 대화를 연다. 잠금 아래 화면이다.
  Future<void> _openWiki() async {
    final id = await openWikiPage(context);
    if (id != null && mounted) await _cubit.open(id);
  }

  /// ⋮ [작업 폴더]. [물어보기에 첨부]로 고른 파일은 다시 넣지 않게 상대 경로를 달아 입력칸에 담는다.
  /// 잠금 아래 화면이다.
  Future<void> _openWorkspace() async {
    final file = await openWorkspace(context);
    if (file == null || !mounted) return;
    final String absolute;
    try {
      absolute = await getIt<Workspace>().absolutePath(file.path);
    } on Object {
      // 그 사이 지워졌거나 경계 밖 — 조용히 사라지지 않게 알린다.
      if (mounted) {
        AppSnackBar.show(
          context,
          message: AppLocalizations.of(context).walkWorkspaceFileMissing,
        );
      }
      return;
    }
    if (!mounted) return;
    await _cubit.addFiles([
      PickedFile(
        name: file.name,
        path: absolute,
        sizeBytes: file.sizeBytes,
        workspacePath: file.path,
      ),
    ]);
  }

  /// 저장 스낵바의 [보기]. 말풍선은 목록에서 스크롤로 빠질 수 있어 탭의 context 로 연다.
  void _openSaved(String path) {
    if (mounted) unawaited(openWorkspaceFile(context, path));
  }

  /// ⋮ [위키로 정리]. 후보 시트는 잠기면 스스로 닫힌다.
  Future<void> _distill() async {
    final id = _cubit.state.conversationId;
    if (id == null || _cubit.state.temporary) return;
    await showWikiCandidatesSheet(
      context,
      conversationId: id,
      target: getIt<ChatSession>().target,
    );
  }

  @override
  void initState() {
    super.initState();
    // 보이지 않는 탭은 상태만 읽는다 — 키 확인(네트워크)은 탭이 보일 때.
    unawaited(_cubit.refresh(recheck: widget.active));
  }

  ModalRoute<void>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _route) {
      if (_route != null) appRouteObserver.unsubscribe(this);
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didUpdateWidget(ChatTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      unawaited(_cubit.refresh());
      // 보이지 않는 동안 세워진 "고른 모델이 없어져…" 알림은 보이게 될 때 한 번.
      // 빌드 중이라 다음 프레임에 띄운다.
      if (_cubit.state.selectionReplaced) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _showSelectionReplaced(),
        );
      }
    }
    if (oldWidget.active != widget.active) _syncSecure();
  }

  /// "고른 모델이 없어져 추천 모델로 바꿨어요"(스펙 §6.3) — 탭이 보일 때만, 한 번.
  void _showSelectionReplaced() {
    if (!mounted || !widget.active || !_cubit.state.selectionReplaced) return;
    AppSnackBar.show(
      context,
      message: AppLocalizations.of(context).walkChatModelReplacedNotice,
    );
    _cubit.consumeSelectionReplaced();
  }

  /// 물어보기 설정(⋮ · [설정 열기] · 실패 말풍선 · 앱 설정)에서 키를 넣거나 지우고 돌아왔을 수 있다.
  /// 탭이 가려져 있으면 읽지 않는다 — 보이게 될 때 [didUpdateWidget] 이 읽는다.
  @override
  void didPopNext() {
    if (widget.active) unawaited(_cubit.refresh());
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    if (_secureOn) unawaited(_secure.setSecure(false));
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unlocked = context.select<DiaryLockCubit, bool>(
      (c) => c.state is LockUnlocked,
    );
    return BlocProvider.value(
      value: _cubit,
      // 게이트 바깥 — 잠겨 있어도 임시 대화가 바뀌면 창 보안을 맞춘다.
      child: MultiBlocListener(
        listeners: [
          BlocListener<ChatCubit, ChatState>(
            listenWhen: (a, b) => a.temporary != b.temporary,
            listener: (_, _) => _syncSecure(),
          ),
          BlocListener<ChatCubit, ChatState>(
            listenWhen: (a, b) =>
                !a.selectionReplaced && b.selectionReplaced && widget.active,
            listener: (_, _) => _showSelectionReplaced(),
          ),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.walkShellTabChat),
            actions: [
              if (unlocked) ...[
                const _NewConversationAction(),
                _ChatMenu(
                  onHistory: () => unawaited(_openHistory()),
                  onWiki: () => unawaited(_openWiki()),
                  onWorkspace: () => unawaited(_openWorkspace()),
                  onDistill: () => unawaited(_distill()),
                  onTemporary: _cubit.startTemporary,
                ),
              ] else
                const FeatureMenu(
                  settings: SettingsTarget.chat,
                  showFeatureSettings: false,
                ),
            ],
          ),
          body: DiaryLockGate(
            dismissPopups: widget.active,
            child: _ChatBody(onOpenSettings: widget.onOpenSettings),
          ),
        ),
      ),
    );
  }
}

/// 풀린 동안의 ⋮ — 대화 목록 · 위키 · 작업 폴더 · 위키로 정리 · 임시 대화로 시작(쓸 수 있을 때) 아래에
/// 물어보기 설정 · 앱 설정.
class _ChatMenu extends StatelessWidget {
  const _ChatMenu({
    required this.onHistory,
    required this.onWiki,
    required this.onWorkspace,
    required this.onDistill,
    required this.onTemporary,
  });

  final VoidCallback onHistory;
  final VoidCallback onWiki;
  final VoidCallback onWorkspace;
  final VoidCallback onDistill;
  final VoidCallback onTemporary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (ready, distillable) = context.select<ChatCubit, (bool, bool)>(
      (c) => (
        c.state.access == ChatAccess.ready,
        // 저장된 대화(턴이 있는 것)만 — 임시 대화 · 빈 대화 · 답하는 중엔 없다.
        c.state.conversationId != null && !c.state.temporary && !c.state.busy,
      ),
    );
    return FeatureMenu(
      settings: SettingsTarget.chat,
      entries: [
        // 키 · 동의 전엔 고른 대화를 열어도 보이지 않는다 — 임시 대화처럼 숨긴다.
        if (ready)
          FeatureMenuEntry(
            key: const Key('chat-menu-history'),
            label: l10n.walkChatHistoryTitle,
            icon: Icons.history,
            onTap: onHistory,
          ),
        if (ready)
          FeatureMenuEntry(
            key: const Key('chat-menu-wiki'),
            label: l10n.walkChatWikiTitle,
            icon: Icons.menu_book_outlined,
            onTap: onWiki,
          ),
        if (ready)
          FeatureMenuEntry(
            key: const Key('chat-menu-workspace'),
            label: l10n.walkWorkspaceTitle,
            icon: Icons.folder_outlined,
            onTap: onWorkspace,
          ),
        if (ready && distillable)
          FeatureMenuEntry(
            key: const Key('chat-menu-distill'),
            label: l10n.walkChatWikiDistill,
            icon: Icons.auto_awesome_outlined,
            onTap: onDistill,
          ),
        if (ready)
          FeatureMenuEntry(
            key: const Key('chat-menu-temporary'),
            label: l10n.walkChatTemporaryStart,
            icon: Icons.visibility_off_outlined,
            onTap: onTemporary,
          ),
      ],
    );
  }
}

/// 앱바 [새 대화]. 대화가 있거나 임시 대화일 때만.
class _NewConversationAction extends StatelessWidget {
  const _NewConversationAction();

  @override
  Widget build(BuildContext context) {
    final show = context.select<ChatCubit, bool>(
      (c) =>
          c.state.access == ChatAccess.ready &&
          (c.state.bubbles.isNotEmpty || c.state.temporary),
    );
    if (!show) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.add_comment_outlined),
      tooltip: AppLocalizations.of(context).walkChatNewConversation,
      onPressed: context.read<ChatCubit>().newConversation,
    );
  }
}

/// 테스트 전용 build 횟수. `assert` 안에서만 올린다 — 릴리스에서는 늘 0.
@visibleForTesting
abstract final class ChatTabDebug {
  /// 말풍선 항목(index → build 횟수).
  static final bubbleBuilds = <int, int>{};

  /// 입력칸 자리 build 횟수.
  static int inputBuilds = 0;

  static void reset() {
    bubbleBuilds.clear();
    inputBuilds = 0;
  }
}

/// 물어보기 본문. 한 [BlocBuilder] 로 다 그리지 않고 조각마다 필요한 값만 고른다(스펙 §4.1) —
/// 경과 초가 오를 때는 마지막 답 말풍선만, 글이 자랄 때도 그 말풍선만 다시 그린다.
class _ChatBody extends StatelessWidget {
  const _ChatBody({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<ChatCubit, ChatState>(
        // 글 없이 멈춰 질문을 입력칸에 되돌렸다(답하는 중이던 것만 — 보내지 못한 질문을
        // 되돌릴 때는 알리지 않는다).
        listenWhen: (a, b) =>
            a.busy && a.restoredDraft == null && b.restoredDraft != null,
        listener: (context, _) => AppSnackBar.show(
          context,
          message: AppLocalizations.of(context).walkChatStoppedSnack,
        ),
      ),
      BlocListener<ChatCubit, ChatState>(
        // 첨부하지 못한 파일 — 알리고 비운다.
        listenWhen: (a, b) =>
            b.attachmentNotice != null &&
            a.attachmentNotice != b.attachmentNotice,
        listener: (context, state) {
          AppSnackBar.show(
            context,
            message: attachmentNoticeText(
              AppLocalizations.of(context),
              state.attachmentNotice!,
            ),
          );
          context.read<ChatCubit>().consumeAttachmentNotice();
        },
      ),
    ],
    child: _AccessSwitch(onOpenSettings: onOpenSettings),
  );
}

/// 키 · 동의 · 모델 목록 상태로 갈래만 고른다.
class _AccessSwitch extends StatelessWidget {
  const _AccessSwitch({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final access = context.select<ChatCubit, ChatAccess>((c) => c.state.access);
    return switch (access) {
      ChatAccess.checking => const Center(child: CircularProgressIndicator()),
      ChatAccess.noKey => AppPlaceholder(
        icon: Icons.key_outlined,
        message: l10n.walkChatNoKey,
        actionLabel: l10n.walkChatOpenSettings,
        onAction: onOpenSettings,
      ),
      ChatAccess.needsConsent => const _ConsentBody(),
      ChatAccess.noModels => _NoModelsBody(onOpenSettings: onOpenSettings),
      ChatAccess.ready => _ReadyBody(onOpenSettings: onOpenSettings),
    };
  }
}

class _ConsentBody extends StatelessWidget {
  const _ConsentBody();

  @override
  Widget build(BuildContext context) {
    final (vendor, continuing) = context.select<ChatCubit, (ChatVendor, bool)>(
      (c) => (c.state.vendor, c.state.bubbles.isNotEmpty),
    );
    return ChatConsentView(
      vendor: vendor,
      continuing: continuing,
      onAccept: () => unawaited(context.read<ChatCubit>().consent()),
    );
  }
}

/// 키가 잘못됐으면 다시 받아도 같다 — 설정에서 키를 고치게 한다.
class _NoModelsBody extends StatelessWidget {
  const _NoModelsBody({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final invalidKey = context.select<ChatCubit, bool>(
      (c) => c.state.modelsInvalidKey,
    );
    return AppPlaceholder(
      icon: Icons.cloud_off_outlined,
      message: l10n.walkChatNoModelsTitle,
      actionLabel: invalidKey ? l10n.walkChatOpenSettings : l10n.commonRetry,
      onAction: invalidKey
          ? onOpenSettings
          : () => unawaited(context.read<ChatCubit>().retryModels()),
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _ModelChipRow(),
      Expanded(child: _Conversation(onOpenSettings: onOpenSettings)),
      const _TemporaryBanner(),
      const _InputArea(),
    ],
  );
}

/// 본문 맨 위 모델 칩. 답하는 중엔 꺼진다.
class _ModelChipRow extends StatelessWidget {
  const _ModelChipRow();

  /// 칩 → 모델 고르기 시트. 바뀐 게 있으면 칩을 다시 읽는다.
  static Future<void> _pickModel(BuildContext context) async {
    final cubit = context.read<ChatCubit>();
    if (await ModelPickerSheet.show(context)) cubit.modelChanged();
  }

  @override
  Widget build(BuildContext context) {
    final (model, busy) = context.select<ChatCubit, (ModelChipData?, bool)>(
      (c) => (c.state.model, c.state.busy),
    );
    if (model == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ModelChip(
          data: model,
          onPressed: busy ? null : () => unawaited(_pickModel(context)),
        ),
      ),
    );
  }
}

class _TemporaryBanner extends StatelessWidget {
  const _TemporaryBanner();

  @override
  Widget build(BuildContext context) {
    final (temporary, vendor) = context.select<ChatCubit, (bool, ChatVendor)>(
      (c) => (c.state.temporary, c.state.vendor),
    );
    return temporary
        ? TemporaryChatBanner(vendor: vendor)
        : const SizedBox.shrink();
  }
}

class _InputArea extends StatelessWidget {
  const _InputArea();

  @override
  Widget build(BuildContext context) {
    assert(() {
      ChatTabDebug.inputBuilds++;
      return true;
    }());
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ChatCubit>();
    final (busy, loading, restoredDraft) = context
        .select<ChatCubit, (bool, bool, String?)>(
          (c) => (c.state.busy, c.state.loading, c.state.restoredDraft),
        );
    final (
      pending,
      block,
      preparing,
    ) = context.select<ChatCubit, (List<ChatAttachment>, AttachBlock?, bool)>(
      (c) =>
          (c.state.pendingAttachments, c.state.attachBlock, c.state.preparing),
    );
    return ChatInput(
      busy: busy,
      // 저장된 대화를 읽는 동안 보낸 질문은 cubit 이 버린다 — 꺼져 보이게 한다.
      enabled: !loading,
      // 첨부 사본을 넣는 동안 보낸 질문은 cubit 이 버린다 — 전송을 꺼 둔다.
      preparing: preparing,
      onSend: (q) => unawaited(cubit.send(q)),
      onStop: cubit.stop,
      restoredDraft: restoredDraft,
      onDraftRestored: cubit.consumeRestoredDraft,
      attachments: [for (final a in pending) a.ref],
      onRemoveAttachment: cubit.removePending,
      onAttach: () => unawaited(_pick(cubit)),
      canAttach: block == null,
      attachBlockedReason: block == null ? null : attachBlockText(l10n, block),
    );
  }

  /// 시스템 파일 선택기 → 고른 파일을 읽어 담는다. 선택기를 열지 못하면 조용히 넘어간다.
  static Future<void> _pick(ChatCubit cubit) async {
    final List<PickedFile> files;
    try {
      files = await getIt<ChatFilePicker>().pick();
    } on Object {
      return;
    }
    if (files.isEmpty || cubit.isClosed) return;
    await cubit.addFiles(files);
  }
}

/// 대화가 비었으면 예시 질문, 아니면 말풍선 목록.
class _Conversation extends StatelessWidget {
  const _Conversation({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final empty = context.select<ChatCubit, bool>(
      (c) => c.state.bubbles.isEmpty,
    );
    if (empty) {
      final cubit = context.read<ChatCubit>();
      return ChatExamples(onAsk: (q) => unawaited(cubit.send(q)));
    }
    return _BubbleList(onOpenSettings: onOpenSettings);
  }
}

/// 말풍선 목록. 아래부터 쌓는다(`reverse`) — 새 말풍선 · 흘러나오는 글이 늘 아래에 보인다.
///
/// 위로 올려 둔 채(화면 높이의 ¼ 넘게) 답이 자라면 끌어내리지 않고 [ChatJumpToLatest] 를
/// 띄운다(스펙 §3.5, Q8). 맨 아래로 돌아오거나 답이 끝나면 숨긴다.
///
/// 읽던 자리 지키기: `reverse` 목록에서 마지막 말풍선이 자라면 앞 말풍선이 위로 밀린다. 위로
/// 올려 둔 동안엔 마지막 말풍선의 높이 변화([_HeightReporter])만큼 같은 레이아웃 안에서
/// 스크롤 위치를 옮겨([_KeepReadingPhysics]) 읽던 말풍선이 그 자리에 있게 한다. 답하는 중에
/// 올려 둔 뒤로 맨 아래로 돌아올 때까지 지킨다 — 끝난 뒤 진행 줄이 요약으로 접히는 것도 포함.
///
/// 말풍선 항목은 말풍선 번호로 키를 둔다 — 새 말풍선이 붙어도 펼친 요약 같은 화면 상태가
/// 제 말풍선에 남는다.
class _BubbleList extends StatefulWidget {
  const _BubbleList({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  State<_BubbleList> createState() => _BubbleListState();
}

class _BubbleListState extends State<_BubbleList> {
  final _controller = ScrollController();

  late final _growth = _Growth(onGrew: _onGrew);

  late final _physics = _KeepReadingPhysics(_growth);

  bool _showJump = false;

  /// 답하는 중에 위로 올려 둔 뒤 맨 아래로 돌아오기 전까지 — 마지막 말풍선의 높이 변화를 막는다.
  bool _keep = false;

  /// 맨 아래에서 이만큼(화면 높이 대비) 넘게 올라가 있으면 "위로 올려 둔" 것으로 본다.
  static const _awayFraction = 4;

  bool get _away =>
      _controller.hasClients &&
      _controller.offset >
          _controller.position.viewportDimension / _awayFraction;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _growth.onGrew = null;
    _controller.dispose();
    super.dispose();
  }

  /// [_Growth.armed] 를 맞춘다. 레이아웃 전에(스크롤 · 상태가 바뀔 때) 부른다.
  void _syncArm() {
    final away = _away;
    final busy = context.read<ChatCubit>().state.busy;
    if (busy && away) _keep = true;
    if (!away) _keep = false;
    _growth.armed = _keep && away;
  }

  void _onScroll() {
    _syncArm();
    if (_showJump && !_away) setState(() => _showJump = false);
  }

  void _onGrew() {
    if (!mounted) return;
    if (!_showJump && _away && context.read<ChatCubit>().state.busy) {
      setState(() => _showJump = true);
    }
  }

  void _hide() {
    if (_showJump) setState(() => _showJump = false);
  }

  void _jump() {
    _hide();
    if (!_controller.hasClients) return;
    if (AppMotion.enabled(context)) {
      unawaited(
        _controller.animateTo(
          0,
          duration: AppMotion.medium,
          curve: AppMotion.standard,
        ),
      );
    } else {
      _controller.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = context.select<ChatCubit, int>((c) => c.state.bubbles.length);
    return MultiBlocListener(
      listeners: [
        BlocListener<ChatCubit, ChatState>(
          listenWhen: (a, b) => a.busy != b.busy,
          listener: (_, _) => _syncArm(),
        ),
        // 글이 자랐다 — 마지막 말풍선이 그려지지 않을 만큼 올라가 있어도 알린다.
        // 진행 줄처럼 글 없이 자라는 것은 [_HeightReporter] 가 알린다.
        BlocListener<ChatCubit, ChatState>(
          listenWhen: (a, b) =>
              b.busy &&
              a.bubbles.lastOrNull?.text.length !=
                  b.bubbles.lastOrNull?.text.length,
          listener: (_, _) => _onGrew(),
        ),
        BlocListener<ChatCubit, ChatState>(
          listenWhen: (a, b) => a.busy && !b.busy,
          listener: (_, _) => _hide(),
        ),
      ],
      child: Stack(
        children: [
          ListView.separated(
            controller: _controller,
            physics: _physics,
            reverse: true,
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: count,
            findItemIndexCallback: (key) =>
                count - 1 - (key as ValueKey<int>).value,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final index = count - 1 - i;
              return _HeightReporter(
                key: ValueKey(index),
                growth: _growth,
                index: index,
                tracked: i == 0,
                child: _BubbleItem(
                  index: index,
                  onOpenSettings: widget.onOpenSettings,
                ),
              );
            },
          ),
          if (_showJump)
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: AppSpacing.sm,
              child: Center(child: ChatJumpToLatest(onPressed: _jump)),
            ),
        ],
      ),
    );
  }
}

/// 마지막 말풍선의 높이 변화를 모아 두는 곳. [_HeightReporter] 가 레이아웃 중에 쌓고,
/// 같은 레이아웃의 [_KeepReadingPhysics] 가 꺼내 스크롤 위치에 더한다.
class _Growth {
  _Growth({this.onGrew});

  /// 쌓을까 — 위로 올려 둔 동안만([_BubbleListState._syncArm]).
  bool armed = false;

  /// 아직 스크롤 위치에 더하지 않은 높이 변화.
  double _pending = 0;

  /// 자랐을 때(프레임 뒤에 한 번).
  VoidCallback? onGrew;

  bool _scheduled = false;
  bool _grew = false;

  void report(double delta) {
    if (armed) _pending += delta;
    if (delta > 0) _grew = true;
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      // 이 프레임에 쓰이지 않은 변화는 버린다 — 나중 레이아웃에 엉뚱하게 더하지 않게.
      _pending = 0;
      final grew = _grew;
      _grew = false;
      if (grew) onGrew?.call();
    });
  }

  double take() {
    final pending = _pending;
    _pending = 0;
    return pending;
  }
}

/// 자식 높이가 바뀌면 [_Growth] 에 알린다. [tracked](마지막 말풍선)일 때만, 그리고 같은 말풍선
/// ([index])의 두 번째 레이아웃부터 — 처음 그려지거나 다른 말풍선이 되면 기준만 잡는다.
class _HeightReporter extends SingleChildRenderObjectWidget {
  const _HeightReporter({
    required this.growth,
    required this.index,
    required this.tracked,
    required super.child,
    super.key,
  });

  final _Growth growth;
  final int index;
  final bool tracked;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHeightReporter(growth, index: index, tracked: tracked);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHeightReporter renderObject,
  ) {
    renderObject
      ..growth = growth
      ..index = index
      ..tracked = tracked;
  }
}

class _RenderHeightReporter extends RenderProxyBox {
  _RenderHeightReporter(
    this.growth, {
    required int index,
    required bool tracked,
  }) : _index = index,
       _tracked = tracked;

  _Growth growth;

  int _index;
  set index(int value) {
    if (value == _index) return;
    _index = value;
    _last = null;
  }

  bool _tracked;
  set tracked(bool value) {
    if (value == _tracked) return;
    _tracked = value;
    _last = null;
  }

  /// 지난 레이아웃의 높이. null 이면 기준이 없다.
  double? _last;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    final last = _last;
    _last = height;
    if (_tracked && last != null && height != last) {
      growth.report(height - last);
    }
  }
}

/// 같은 레이아웃 안에서 [_Growth] 에 쌓인 높이 변화만큼 스크롤 위치를 옮긴다 — `reverse`
/// 목록에서 마지막 말풍선이 자라도 앞 말풍선이 화면에서 움직이지 않는다. 쌓인 게 없으면 부모 그대로.
class _KeepReadingPhysics extends ScrollPhysics {
  const _KeepReadingPhysics(this.growth, {super.parent});

  final _Growth growth;

  @override
  _KeepReadingPhysics applyTo(ScrollPhysics? ancestor) =>
      _KeepReadingPhysics(growth, parent: buildParent(ancestor));

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    final pending = growth.take();
    if (pending != 0) {
      return (newPosition.pixels + pending).clamp(
        newPosition.minScrollExtent,
        newPosition.maxScrollExtent,
      );
    }
    return super.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: isScrolling,
      velocity: velocity,
    );
  }
}

/// 말풍선 하나. 자기 말풍선 · 답하는 중인지만 골라 다시 그린다 — 마지막 답의 경과 초 · 글이
/// 바뀌어도 앞의 말풍선은 그대로다.
class _BubbleItem extends StatelessWidget {
  const _BubbleItem({required this.index, required this.onOpenSettings});

  final int index;
  final VoidCallback onOpenSettings;

  void _open(BuildContext context, List<DiaryEntry> cited, DiaryEntry entry) {
    final source = ViewerSource.entries([
      for (final e in cited) e.id,
    ], AppLocalizations.of(context).walkChatCitedTitle);
    unawaited(openStoryViewer(context, source, entryId: entry.id));
  }

  /// 말풍선 길게 누르기 → 시트. [위키에 추가]는 그 턴으로 편집 화면을 연다(요청 없음),
  /// [파일로 저장]은 답을 작업 폴더에 쓴다, [지우기]는 확인 뒤에 그 턴(질문 · 답)을 지운다.
  Future<void> _actions(BuildContext context, ChatBubble bubble) async {
    final cubit = context.read<ChatCubit>();
    final role = bubble.role;
    final canAddToWiki =
        !cubit.state.temporary &&
        bubble.failure == null &&
        bubble.text.trim().isNotEmpty;
    final canSaveToFile =
        role == ChatRole.assistant &&
        bubble.failure == null &&
        bubble.text.trim().isNotEmpty;
    final action = await showBubbleActions(
      context,
      canAddToWiki: canAddToWiki,
      canSaveToFile: canSaveToFile,
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case BubbleAction.saveToFile:
        final l10n = AppLocalizations.of(context);
        final tab = context.findAncestorStateOfType<_ChatTabState>();
        final path = await cubit.saveAnswer(index);
        if (!context.mounted) return;
        if (path == null) {
          AppSnackBar.show(context, message: l10n.walkChatSaveFailed);
          return;
        }
        AppSnackBar.show(
          context,
          message: l10n.walkChatSavedToWorkspace,
          actionLabel: l10n.walkWorkspaceView,
          onAction: () => tab?._openSaved(path),
        );
      case BubbleAction.addToWiki:
        await openWikiEditor(context, _seed(cubit.state, bubble));
      case BubbleAction.deleteTurn:
        final l10n = AppLocalizations.of(context);
        final confirmed = await AppConfirmDialog.show(
          context,
          title: l10n.walkChatTurnDeleteTitle,
          content: l10n.walkChatTurnDeleteBody,
          confirmLabel: l10n.commonDelete,
        );
        if (!confirmed) return;
        await cubit.deleteTurn(role == ChatRole.user ? index : index - 1);
    }
  }

  /// 그 턴(질문 · 답 말풍선 쌍)으로 [위키에 추가] 편집 값을 만든다. 글은 누른 말풍선의 글.
  WikiEditSeed _seed(ChatState state, ChatBubble bubble) {
    final user = bubble.role == ChatRole.user;
    final question = user ? bubble : state.bubbles.elementAtOrNull(index - 1);
    final answer = user ? state.bubbles.elementAtOrNull(index + 1) : bubble;
    return WikiEditSeed.fromBubble(
      question: question?.text ?? bubble.text,
      text: bubble.text,
      conversationId: state.conversationId,
      citedEntryIds: [for (final e in answer?.cited ?? const []) e.id],
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      ChatTabDebug.bubbleBuilds.update(index, (n) => n + 1, ifAbsent: () => 1);
      return true;
    }());
    final (bubble, busy, last) = context
        .select<ChatCubit, (ChatBubble?, bool, bool)>(
          (c) => (
            c.state.bubbles.elementAtOrNull(index),
            c.state.busy,
            index == c.state.bubbles.length - 1,
          ),
        );
    if (bubble == null) return const SizedBox.shrink();
    final pending = busy && last;
    // 커서는 답을 쓰는 단계에서만 — 글 뒤에 도구를 부르는 동안엔 깜빡이지 않는다.
    final writing = switch (bubble.progress) {
      null => true,
      final p => p.current is StepWriting,
    };
    return ChatBubbleView(
      bubble: bubble,
      pending: pending,
      streaming: pending && bubble.text.isNotEmpty && writing,
      onOpenCited: (cited, entry) => _open(context, cited, entry),
      onOpenSettings: onOpenSettings,
      attachmentExists: getIt<Workspace>().exists,
      onOpenAttachment: (path) => unawaited(openWorkspaceFile(context, path)),
      // 답하는 중엔 턴을 지우지 않는다.
      onLongPress: busy ? null : () => unawaited(_actions(context, bubble)),
    );
  }
}
