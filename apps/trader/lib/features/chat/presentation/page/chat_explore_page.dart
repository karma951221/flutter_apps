import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';
import 'package:l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import '../../domain/entity/chat_room.dart';
import '../cubit/chat_explore_cubit.dart';
import '../cubit/chat_explore_state.dart';
import '../widget/join_room_sheet.dart';
import 'chat_room_page.dart';

/// 공개방 탐색.
///
/// 방을 고르면 입장 시트가 뜨고, 입장에 성공하면 그 방으로 들어간다. 뒤로
/// 나갈 때 "하나라도 들어갔는가"를 돌려줘서 목록 화면이 자기 목록을 다시 읽는다.
class ChatExplorePage extends StatelessWidget {
  const ChatExplorePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ChatExploreCubit>()..load(),
    child: const _ChatExploreView(),
  );
}

class _ChatExploreView extends StatefulWidget {
  const _ChatExploreView();

  @override
  State<_ChatExploreView> createState() => _ChatExploreViewState();
}

class _ChatExploreViewState extends State<_ChatExploreView> {
  final _controller = TextEditingController();

  /// 이 화면에 있는 동안 방에 하나라도 들어갔는지.
  bool _joinedAny = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_joinedAny);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.chatExploreTitle)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: l10n.chatSearchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) =>
                    context.read<ChatExploreCubit>().search(value),
              ),
            ),
            Expanded(
              child: BlocBuilder<ChatExploreCubit, ChatExploreState>(
                builder: (context, state) => switch (state.status) {
                  ChatExploreStatus.loading => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  ChatExploreStatus.failure => Center(
                    child: AppPlaceholder(
                      icon: Icons.cloud_off_outlined,
                      message:
                          state.failure?.localizedMessage(context) ??
                          l10n.chatExploreLoadFailed,
                      actionLabel: l10n.commonRetry,
                      onAction: () =>
                          context.read<ChatExploreCubit>().refresh(),
                    ),
                  ),
                  ChatExploreStatus.loaded when state.items.isEmpty => Center(
                    child: AppPlaceholder(
                      icon: Icons.forum_outlined,
                      message: state.query.isEmpty
                          ? l10n.chatExploreEmptyMessage
                          : l10n.chatExploreNoResult,
                      description: state.query.isEmpty
                          ? l10n.chatExploreEmptyDescription
                          : null,
                    ),
                  ),
                  ChatExploreStatus.loaded => _RoomList(
                    state: state,
                    onJoin: _join,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _join(BuildContext context, ChatRoom room) async {
    final joined = await JoinRoomSheet.show(context, room.id);
    if (!joined || !context.mounted) return;

    _joinedAny = true;
    await context.push(
      Routes.chatRoomPath(room.id),
      extra: ChatRoomPageArgs(title: room.title).toMap(),
    );
  }
}

class _RoomList extends StatelessWidget {
  const _RoomList({required this.state, required this.onJoin});

  final ChatExploreState state;
  final Future<void> Function(BuildContext context, ChatRoom room) onJoin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 240 &&
            !state.isLoadingMore &&
            state.canLoadMore) {
          context.read<ChatExploreCubit>().loadMore();
        }
        return false;
      },
      child: ListView.builder(
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final room = state.items[index];
          return AppListTile(
            onTap: () => onJoin(context, room),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.forum_outlined,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            title: Text(
              room.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              room.description?.isNotEmpty == true
                  ? room.description!
                  : l10n.chatMemberCount(room.memberCount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l10n.chatMemberCount(room.memberCount),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (room.lastMessageAt != null)
                  Text(
                    room.lastMessageAt!.displayShortDateTime(l10n.localeName),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
