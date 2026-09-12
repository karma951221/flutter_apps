import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';
import 'package:l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import '../../domain/entity/follow_user.dart';
import '../cubit/follow_list_cubit.dart';
import '../cubit/follow_list_state.dart';

/// 팔로워 · 팔로잉 목록 화면. 방향만 다르고 나머지는 같다.
///
/// 차단 목록([BlockedUsersPage])과 달리 커서를 쓴다 — 팔로워는 한 화면에
/// 담기지 않을 만큼 늘어날 수 있다.
class FollowListPage extends StatelessWidget {
  const FollowListPage({
    required this.userId,
    required this.direction,
    super.key,
  });

  final String userId;
  final FollowDirection direction;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<FollowListCubit>()..load(userId: userId, direction: direction),
    child: _FollowListView(direction: direction),
  );
}

class _FollowListView extends StatefulWidget {
  const _FollowListView({required this.direction});

  final FollowDirection direction;

  @override
  State<_FollowListView> createState() => _FollowListViewState();
}

class _FollowListViewState extends State<_FollowListView> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    // 바닥에 닿기 한 화면 전에 미리 읽어 둔다.
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<FollowListCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = switch (widget.direction) {
      FollowDirection.followers => l10n.followFollowersTitle,
      FollowDirection.followings => l10n.followFollowingsTitle,
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: BlocBuilder<FollowListCubit, FollowListState>(
          builder: (context, state) => switch (state.status) {
            FollowListStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            FollowListStatus.failure => Center(
              child: AppPlaceholder(
                message:
                    state.failure?.localizedMessage(context) ??
                    l10n.followListLoadFailed,
                actionLabel: l10n.commonRetry,
                onAction: () => context.read<FollowListCubit>().refresh(),
              ),
            ),
            FollowListStatus.loaded => RefreshIndicator(
              onRefresh: () => context.read<FollowListCubit>().refresh(),
              child: _FollowList(
                controller: _controller,
                state: state,
                direction: widget.direction,
              ),
            ),
          },
        ),
      ),
    );
  }
}

class _FollowList extends StatelessWidget {
  const _FollowList({
    required this.controller,
    required this.state,
    required this.direction,
  });

  final ScrollController controller;
  final FollowListState state;
  final FollowDirection direction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (state.items.isEmpty) {
      // 비어 있어도 스크롤은 살려 둔다 — 당겨서 새로고침이 동작해야 한다.
      return ListView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
          AppPlaceholder(
            icon: Icons.people_outline,
            message: switch (direction) {
              FollowDirection.followers => l10n.followFollowersEmpty,
              FollowDirection.followings => l10n.followFollowingsEmpty,
            },
          ),
        ],
      );
    }

    return ListView.builder(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      itemCount: state.items.length + 1,
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          return AppListFooter(
            isLoadingMore: state.isLoadingMore,
            canLoadMore: state.canLoadMore,
          );
        }

        final user = state.items[index];
        return _FollowListRow(user: user);
      },
    );
  }
}

class _FollowListRow extends StatelessWidget {
  const _FollowListRow({required this.user});

  final FollowUser user;

  @override
  Widget build(BuildContext context) => AppListTile(
    leading: AppAvatar(
      nickname: user.nickname,
      imageUrl: user.avatarUrl,
      radius: 20,
    ),
    title: Text(user.nickname),
    onTap: () => context.push(Routes.userProfilePath(user.id)),
  );
}
