import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/l10n/failure_localizations.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_placeholder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entity/chat_room_summary.dart';
import '../cubit/chat_room_list_cubit.dart';
import '../cubit/chat_room_list_state.dart';
import '../widget/chat_room_tile.dart';
import 'chat_room_page.dart';

/// 채팅 탭. 내가 참여 중인 방 목록.
///
/// 하단 내비게이션 셸의 탭 본문이라 화면 밖으로 나가는 동작을 AppBar 에 두지
/// 않는다 — 탐색과 방 만들기만 있다.
///
/// [ChatRoomListCubit] 을 **스스로 만들지 않는다.** 탭 배지가 다른 탭에 있을
/// 때도 숫자를 알아야 해서 셸(`HomeShellPage`)이 소유하고, 이 화면은 그것을
/// 읽어 쓴다 (규칙 ⑥ 의 "소유자가 명확한 쪽").
class ChatRoomListPage extends StatelessWidget {
  const ChatRoomListPage({super.key});

  @override
  Widget build(BuildContext context) => const _ChatRoomListView();
}

class _ChatRoomListView extends StatelessWidget {
  const _ChatRoomListView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chatTitle),
        actions: [
          IconButton(
            tooltip: l10n.chatExploreTooltip,
            icon: const Icon(Icons.search),
            onPressed: () => _explore(context),
          ),
        ],
      ),
      body: BlocBuilder<ChatRoomListCubit, ChatRoomListState>(
        builder: (context, state) => switch (state.status) {
          ChatRoomListStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          ChatRoomListStatus.failure => Center(
            child: AppPlaceholder(
              icon: Icons.cloud_off_outlined,
              message:
                  state.failure?.localizedMessage(context) ??
                  l10n.chatLoadFailed,
              actionLabel: l10n.commonRetry,
              onAction: () => context.read<ChatRoomListCubit>().load(),
            ),
          ),
          ChatRoomListStatus.loaded when state.items.isEmpty =>
            RefreshIndicator(
              onRefresh: () => context.read<ChatRoomListCubit>().load(),
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: AppPlaceholder(
                        icon: Icons.forum_outlined,
                        message: l10n.chatEmptyMessage,
                        description: l10n.chatEmptyDescription,
                        actionLabel: l10n.chatEmptyAction,
                        onAction: () => _explore(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ChatRoomListStatus.loaded => RefreshIndicator(
            onRefresh: () => context.read<ChatRoomListCubit>().load(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl * 3),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final room = state.items[index];
                return ChatRoomTile(
                  room: room,
                  onTap: () => _openRoom(context, room),
                );
              },
            ),
          ),
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('chatList.create'),
        // 홈 셸이 탭 본문을 IndexedStack 으로 동시에 살려 두므로, 피드 탭의
        // FAB 과 기본 태그가 겹치면 라우트 전환에서 hero 충돌 단언이 난다.
        heroTag: 'chat-create',
        onPressed: () => _create(context),
        icon: const Icon(Icons.add_comment_outlined),
        label: Text(l10n.chatCreateRoomLabel),
      ),
    );
  }

  /// 방을 보고 나오면 그 줄의 안읽음만 0 으로 만든다. 목록을 다시 읽지 않는다.
  Future<void> _openRoom(BuildContext context, ChatRoomSummary room) async {
    final cubit = context.read<ChatRoomListCubit>();
    final roomId = room.id;
    // 보일 이름과 direct 여부를 함께 넘긴다. 이름이 없으면 AppBar 가 방 이름
    // 대신 '채팅' 으로 뜨고, direct 여부를 모르면 참여자 메뉴가 남는다.
    final left = await context.push<bool>(
      Routes.chatRoomPath(roomId),
      extra: ChatRoomPageArgs(
        title: room.displayTitle,
        isDirect: room.isDirect,
      ),
    );
    if (left == true) {
      cubit.removeRoom(roomId);
    } else {
      cubit.markRoomRead(roomId);
    }
  }

  /// 탐색에서 방에 들어갔으면 목록을 다시 읽는다 — 새 줄이 생겼기 때문이다.
  Future<void> _explore(BuildContext context) async {
    final cubit = context.read<ChatRoomListCubit>();
    final joined = await context.push<bool>(Routes.chatExplore);
    if (joined == true) await cubit.load();
  }

  Future<void> _create(BuildContext context) async {
    final cubit = context.read<ChatRoomListCubit>();
    final created = await context.push<bool>(Routes.chatCreate);
    if (created == true) await cubit.load();
  }
}
