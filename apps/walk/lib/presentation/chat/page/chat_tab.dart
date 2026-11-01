import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/chat_settings.dart';
import '../../../domain/chat/chat_trace.dart';
import '../../../domain/chat/usecase/chat_key_verifier.dart';
import '../../../domain/chat/usecase/chat_session.dart';
import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../diary/viewer/story_viewer_page.dart';
import '../../lock/cubit/diary_lock_cubit.dart';
import '../../lock/cubit/diary_lock_state.dart';
import '../../lock/widget/diary_lock_gate.dart';
import '../../settings/open_settings.dart';
import '../../shell/widget/feature_menu.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widget/chat_bubble_view.dart';
import '../widget/chat_consent_view.dart';
import '../widget/chat_examples.dart';
import '../widget/chat_input.dart';

/// 셸의 물어보기 탭: 내 일기 · 걸음 · 기상 기록에 묻는 채팅.
///
/// 대화 내용은 일기에서 나오므로 [DiaryLockGate] 안쪽에 둔다 — 잠긴 동안 트리에 없다.
/// cubit 은 게이트 바깥(이 State)이 소유해 다시 잠겼다 풀려도 대화가 남는다.
/// 위에서 `DiaryLockCubit` 를 받는다(셸이 소유). 앱바 ⋮ 는 물어보기 설정 · 앱 설정(잠긴 동안은
/// 앱 설정만)이고, 셸의 설정 cubit 아래에서 연다([openSettings]).
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
    getIt<ChatKeyVerifier>(),
  );

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
    if (!oldWidget.active && widget.active) unawaited(_cubit.refresh());
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
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.walkShellTabChat),
          actions: [
            if (unlocked) ...[
              const _NewConversationAction(),
              const FeatureMenu(settings: SettingsTarget.chat),
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
    );
  }
}

/// 앱바 [새 대화]. 대화가 있을 때만.
class _NewConversationAction extends StatelessWidget {
  const _NewConversationAction();

  @override
  Widget build(BuildContext context) {
    final show = context.select<ChatCubit, bool>(
      (c) => c.state.access == ChatAccess.ready && c.state.bubbles.isNotEmpty,
    );
    if (!show) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.add_comment_outlined),
      tooltip: AppLocalizations.of(context).walkChatNewConversation,
      onPressed: context.read<ChatCubit>().newConversation,
    );
  }
}

class _ChatBody extends StatelessWidget {
  const _ChatBody({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => BlocListener<ChatCubit, ChatState>(
    // 글 없이 멈춰 질문을 입력칸에 되돌렸다.
    listenWhen: (a, b) => a.restoredDraft == null && b.restoredDraft != null,
    listener: (context, _) => AppSnackBar.show(
      context,
      message: AppLocalizations.of(context).walkChatStoppedSnack,
    ),
    child: BlocBuilder<ChatCubit, ChatState>(builder: _build),
  );

  Widget _build(BuildContext context, ChatState state) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ChatCubit>();
    return switch (state.access) {
      ChatAccess.checking => const Center(child: CircularProgressIndicator()),
      ChatAccess.noKey => AppPlaceholder(
        icon: Icons.key_outlined,
        message: l10n.walkChatNoKey,
        actionLabel: l10n.walkChatOpenSettings,
        onAction: onOpenSettings,
      ),
      ChatAccess.needsConsent => ChatConsentView(
        onAccept: () => unawaited(cubit.consent()),
      ),
      ChatAccess.ready => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: state.bubbles.isEmpty
                ? ChatExamples(onAsk: (q) => unawaited(cubit.send(q)))
                : _BubbleList(state: state, onOpenSettings: onOpenSettings),
          ),
          if (state.activeTool != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                l10n.walkChatSearching,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ChatInput(
            busy: state.busy,
            onSend: (q) => unawaited(cubit.send(q)),
            onStop: cubit.stop,
            restoredDraft: state.restoredDraft,
            onDraftRestored: cubit.consumeRestoredDraft,
          ),
        ],
      ),
    };
  }
}

/// 말풍선 목록. 아래부터 쌓는다(`reverse`) — 새 말풍선 · 흘러나오는 글이 늘 아래에 보인다.
class _BubbleList extends StatelessWidget {
  const _BubbleList({required this.state, required this.onOpenSettings});

  final ChatState state;
  final VoidCallback onOpenSettings;

  void _open(BuildContext context, List<DiaryEntry> cited, DiaryEntry entry) {
    final source = ViewerSource.entries([
      for (final e in cited) e.id,
    ], AppLocalizations.of(context).walkChatCitedTitle);
    unawaited(openStoryViewer(context, source, entryId: entry.id));
  }

  @override
  Widget build(BuildContext context) {
    final bubbles = state.bubbles;
    return ListView.separated(
      reverse: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: bubbles.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final index = bubbles.length - 1 - i;
        return ChatBubbleView(
          bubble: bubbles[index],
          pending: state.busy && i == 0,
          onOpenCited: (cited, entry) => _open(context, cited, entry),
          onOpenSettings: onOpenSettings,
        );
      },
    );
  }
}
