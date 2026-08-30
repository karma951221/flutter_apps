import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/media/image_picker_service.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_confirm_dialog.dart';
import '../../../../design_system/widget/app_overflow_menu.dart';
import '../../../../design_system/widget/app_placeholder.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../safety/domain/entity/report_target.dart';
import '../../../safety/presentation/widget/report_sheet.dart';
import '../../domain/chat_policy.dart';
import '../../domain/entity/chat_image_draft.dart';
import '../../domain/entity/chat_message.dart';
import '../../domain/usecase/chat_use_case.dart';
import '../bloc/chat_room_bloc.dart';
import '../bloc/chat_room_event.dart';
import '../bloc/chat_room_state.dart';
import '../widget/chat_message_bubble.dart';

/// 한 방의 대화 화면.
///
/// 나갈 때 "방에서 나갔는가"를 돌려준다 — 목록 화면이 그 값으로 줄을 지울지
/// 안읽음만 0 으로 만들지 정한다.
class ChatRoomPage extends StatelessWidget {
  const ChatRoomPage({required this.roomId, this.title, super.key});

  final String roomId;

  /// 목록에서 들어왔으면 제목을 이미 안다. 없으면 AppBar 가 잠시 비어 있다가
  /// 채워지는 대신 기본 문구를 쓴다.
  final String? title;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<ChatRoomBloc>()..add(ChatRoomEvent.started(roomId)),
    child: _ChatRoomView(roomId: roomId, title: title),
  );
}

class _ChatRoomView extends StatefulWidget {
  const _ChatRoomView({required this.roomId, this.title});

  final String roomId;
  final String? title;

  @override
  State<_ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<_ChatRoomView> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();

  bool _left = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _composer.dispose();
    super.dispose();
  }

  /// 목록이 `reverse: true` 라 위로 갈수록 extentAfter 가 는다.
  void _onScroll() {
    if (_scroll.position.extentAfter < 400) {
      context.read<ChatRoomBloc>().add(const ChatRoomEvent.moreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final myId = switch (context.watch<AuthBloc>().state) {
      AuthAuthenticated(:final user) => user.id,
      _ => '',
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // 나가면서 읽음을 확정한다. 디바운스가 아직 안 터졌을 수 있다.
        context.read<ChatRoomBloc>().add(const ChatRoomEvent.readConfirmed());
        Navigator.of(context).pop(_left);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title ?? l10n.chatTitle),
          actions: [
            AppOverflowMenu<_RoomAction>(
              tooltip: l10n.chatRoomMenuTooltip,
              onSelected: (action) => switch (action) {
                _RoomAction.participants => _showParticipants(context),
                _RoomAction.leave => _confirmLeave(context),
              },
              items: [
                AppOverflowMenuItem(
                  value: _RoomAction.participants,
                  label: l10n.chatMenuParticipants,
                  icon: Icons.people_outline,
                ),
                AppOverflowMenuItem(
                  value: _RoomAction.leave,
                  label: l10n.chatMenuLeave,
                  icon: Icons.logout,
                  isDestructive: true,
                ),
              ],
            ),
          ],
        ),
        body: BlocConsumer<ChatRoomBloc, ChatRoomState>(
          listenWhen: (previous, current) =>
              previous.actionFailure != current.actionFailure &&
              current.actionFailure != null,
          listener: (context, state) => AppSnackBar.show(
            context,
            message: state.actionFailure?.message ?? l10n.chatSendFailed,
            type: AppSnackBarType.error,
          ),
          builder: (context, state) => switch (state.status) {
            ChatRoomStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            ChatRoomStatus.failure => Center(
              child: AppPlaceholder(
                icon: Icons.cloud_off_outlined,
                message: state.failure?.message ?? l10n.chatRoomLoadFailed,
                actionLabel: l10n.commonRetry,
                onAction: () => context.read<ChatRoomBloc>().add(
                  ChatRoomEvent.started(widget.roomId),
                ),
              ),
            ),
            ChatRoomStatus.loaded => Column(
              children: [
                Expanded(child: _messageList(context, state, myId)),
                _Composer(
                  controller: _composer,
                  onSend: _send,
                  onAttach: _attach,
                ),
              ],
            ),
          },
        ),
      ),
    );
  }

  Widget _messageList(
    BuildContext context,
    ChatRoomState state,
    String myId,
  ) {
    final l10n = AppLocalizations.of(context);
    if (state.messages.isEmpty) {
      return Center(child: AppPlaceholder(message: l10n.chatRoomEmptyMessage));
    }

    return ListView.builder(
      // 최신이 아래다. 목록이 최신순이라 reverse 로 그리면 새 메시지가
      // 아래에 쌓이고 스크롤 위치를 건드릴 필요가 없다.
      reverse: true,
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.messages.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final message = state.messages[index];
        // 목록이 최신순이므로 "바로 앞 메시지"는 인덱스가 하나 큰 쪽이다.
        final previous = index + 1 < state.messages.length
            ? state.messages[index + 1]
            : null;
        final isMine = message.isMine(myId);

        return ChatMessageBubble(
          message: message,
          isMine: isMine,
          showSender:
              previous == null ||
              previous.senderId != message.senderId ||
              previous.isSystem,
          onRetry: message.isFailed
              ? () => context.read<ChatRoomBloc>().add(
                  ChatRoomEvent.retryRequested(message.id),
                )
              : null,
          onLongPress: message.isSystem || message.isPending
              ? null
              : () => _messageActions(context, message, isMine),
        );
      },
    );
  }

  void _send() {
    final text = _composer.text;
    if (text.trim().isEmpty) return;
    context.read<ChatRoomBloc>().add(ChatRoomEvent.sendRequested(text));
    _composer.clear();
  }

  Future<void> _attach() async {
    final bloc = context.read<ChatRoomBloc>();
    final l10n = AppLocalizations.of(context);
    try {
      final picked = await getIt<ImagePickerService>().pickImages(limit: 1);
      if (picked.isEmpty || !mounted) return;

      final image = picked.first;
      bloc.add(
        ChatRoomEvent.imageSendRequested(
          ChatImageDraft(
            bytes: image.bytes,
            contentType: image.contentType,
            extension: image.extension,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: l10n.chatImagePrepareFailed,
        type: AppSnackBarType.error,
      );
    }
  }

  /// 말풍선을 길게 누르면 뜨는 동작.
  ///
  /// 내 메시지는 삭제, 남의 메시지는 신고다. 신고 대상은 방별 닉네임이 아니라
  /// 메시지이고, `reports` 는 이미 폴리모픽이라 새 테이블이 없다.
  Future<void> _messageActions(
    BuildContext context,
    ChatMessage message,
    bool isMine,
  ) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<ChatRoomBloc>();

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            if (isMine)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
                title: Text(l10n.chatMessageDelete),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmDelete(context, bloc, message.id);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(l10n.chatMessageReport),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _report(context, message.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ChatRoomBloc bloc,
    String messageId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.chatDeleteConfirmTitle,
      content: l10n.chatDeleteConfirmMessage,
      confirmLabel: l10n.commonDelete,
    );
    if (!confirmed) return;
    bloc.add(ChatRoomEvent.deleteRequested(messageId));
  }

  Future<void> _report(BuildContext context, String messageId) async {
    final l10n = AppLocalizations.of(context);
    final filed = await ReportSheet.show(
      context,
      ReportTarget.chatMessage(messageId),
    );
    if (!filed || !context.mounted) return;
    AppSnackBar.show(
      context,
      message: l10n.safetyReportSubmitted,
      type: AppSnackBarType.success,
    );
  }

  Future<void> _showParticipants(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final nicknames = context
        .read<ChatRoomBloc>()
        .state
        .participantNicknames
        .values
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.chatParticipantsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final nickname in nicknames)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(nickname),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.chatLeaveConfirmTitle,
      content: l10n.chatLeaveConfirmMessage,
      confirmLabel: l10n.chatLeaveConfirmAction,
    );
    if (!confirmed || !context.mounted) return;

    final result = await getIt<ChatUseCase>().leaveRoom(widget.roomId);
    if (!context.mounted) return;

    result.when(
      ok: (_) {
        _left = true;
        Navigator.of(context).pop(true);
      },
      err: (failure) => AppSnackBar.show(
        context,
        message: failure.message ?? l10n.chatLeaveFailed,
        type: AppSnackBarType.error,
      ),
    );
  }
}

enum _RoomAction { participants, leave }

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final Future<void> Function() onAttach;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: l10n.chatAttachTooltip,
              icon: const Icon(Icons.photo_outlined),
              onPressed: onAttach,
            ),
            Expanded(
              child: TextField(
                key: const Key('chatRoom.composer'),
                controller: controller,
                maxLength: ChatPolicy.messageMaxLength,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: l10n.chatComposerHint,
                  // 1000자 상한을 늘 보여줄 필요는 없다. 근처에 가면 TextField
                  // 가 스스로 알린다.
                  counterText: '',
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            IconButton(
              key: const Key('chatRoom.send'),
              tooltip: l10n.chatSendTooltip,
              icon: const Icon(Icons.send),
              onPressed: onSend,
            ),
          ],
        ),
      ),
    );
  }
}
