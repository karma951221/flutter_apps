import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_avatar.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_confirm_dialog.dart';
import '../../../../design_system/widget/app_overflow_menu.dart';
import '../../../../design_system/widget/app_placeholder.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../feed/presentation/cubit/feed_cubit.dart';
import '../../../feed/presentation/cubit/feed_state.dart';
import '../../../feed/presentation/widget/post_tile_actions.dart';
import '../../../post/presentation/cubit/post_cubit.dart';
import '../../../post/presentation/widget/post_tile.dart';
import '../../../safety/domain/entity/report_target.dart';
import '../../../safety/presentation/cubit/block_action_cubit.dart';
import '../../../safety/presentation/cubit/block_action_state.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

/// Own and other-user profile screen. [userId] is omitted for the session user.
///
/// 게시물 목록은 [FeedCubit] 이, 게시물 변경은 [PostCubit] 이 소유한다. 피드
/// 화면과 같은 구성이라 본인 프로필에서도 같은 수정·삭제 흐름을 쓴다.
class ProfilePage extends StatelessWidget {
  const ProfilePage({this.userId, super.key});

  final String? userId;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => getIt<ProfileCubit>()..load(userId: userId)),
      BlocProvider(create: (_) => getIt<FeedCubit>()),
      BlocProvider(create: (_) => getIt<PostCubit>()),
      BlocProvider(create: (_) => getIt<BlockActionCubit>()),
    ],
    child: _ProfileView(requestedUserId: userId),
  );
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({this.requestedUserId});

  final String? requestedUserId;

  @override
  Widget build(BuildContext context) {
    final isMine = switch (context.watch<AuthBloc>().state) {
      AuthAuthenticated(:final user) =>
        requestedUserId == null || user.id == requestedUserId,
      _ => false,
    };
    // AppBar 의 신고 메뉴는 실제로 화면에 로드된 프로필의 id 를 써야 한다
    // (라우트 파라미터는 신뢰 경계 밖이다). body 의 BlocBuilder 와 별개로
    // watch 해도 body 의 로딩·오류 표시 흐름은 그대로다.
    final loadedProfile = context.watch<ProfileCubit>().state.profile;
    return MultiBlocListener(
      listeners: [
        BlocListener<ProfileCubit, ProfileState>(
          listenWhen: (previous, current) =>
              previous.profile?.id != current.profile?.id &&
              current.profile != null,
          listener: (context, state) {
            final profile = state.profile!;
            context.read<FeedCubit>().loadForAuthor(profile.id);
            if (!isMine) {
              context.read<BlockActionCubit>().loadStatus(profile.id);
            }
          },
        ),
        // 하단 내비게이션 셸이 이 화면을 살려 두므로, 설정에서 프로필을 고치고
        // 탭으로 돌아오면 옛 값이 그대로 남는다. 세션 스냅샷이 바뀌는 것을
        // 신호로 삼아 내 프로필만 다시 읽는다 — 편집 화면이 저장 직후
        // userRefreshRequested 를 보낸다.
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) => switch ((previous, current)) {
            (
              AuthAuthenticated(user: final before),
              AuthAuthenticated(user: final after),
            ) =>
              before.id == after.id &&
                  (before.nickname != after.nickname ||
                      before.avatarUrl != after.avatarUrl),
            _ => false,
          },
          listener: (context, _) {
            if (isMine) context.read<ProfileCubit>().load(userId: null);
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(isMine ? '프로필' : '사용자 프로필'),
          actions: [
            if (!isMine && loadedProfile != null)
              BlocBuilder<BlockActionCubit, BlockActionState>(
                builder: (context, blockState) =>
                    AppOverflowMenu<_ProfileAction>(
                      tooltip: '프로필 메뉴',
                      enabled: !blockState.isBlocking,
                      onSelected: (action) => switch (action) {
                        _ProfileAction.block => _confirmAndBlock(
                          context,
                          loadedProfile.id,
                        ),
                        _ProfileAction.unblock => _unblockProfile(
                          context,
                          loadedProfile.id,
                        ),
                        _ProfileAction.report => PostTileActions.report(
                          context,
                          ReportTarget.user(loadedProfile.id),
                        ),
                      },
                      items: [
                        // 조회 실패 또는 조회 전에는 메뉴를 숨긴다. 이미 차단한
                        // 사용자에게 '차단'을 권하는 것보다 잘못된 동작을 막는다.
                        if (!blockState.isLoadingStatus &&
                            blockState.isBlocked == false)
                          const AppOverflowMenuItem(
                            value: _ProfileAction.block,
                            label: '차단',
                            isDestructive: true,
                          ),
                        if (!blockState.isLoadingStatus &&
                            blockState.isBlocked == true)
                          const AppOverflowMenuItem(
                            value: _ProfileAction.unblock,
                            label: '차단 해제',
                          ),
                        const AppOverflowMenuItem(
                          value: _ProfileAction.report,
                          label: '신고',
                        ),
                      ],
                    ),
              ),
          ],
        ),
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state.isLoading && state.profile == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.failure != null && state.profile == null) {
              return Center(
                child: AppPlaceholder(
                  message: state.failure?.message ?? '프로필을 불러오지 못했습니다',
                  actionLabel: '다시 시도',
                  onAction: () => context.read<ProfileCubit>().load(
                    userId: requestedUserId,
                  ),
                ),
              );
            }
            final profile = state.profile;
            if (profile == null) return const SizedBox.shrink();
            return RefreshIndicator(
              onRefresh: () async {
                final feed = context.read<FeedCubit>();
                await context.read<ProfileCubit>().load(
                  userId: requestedUserId,
                );
                await feed.refresh();
              },
              child: NotificationListener<ScrollNotification>(
                // 다음 페이지 요청은 스크롤 알림으로만 낸다. 목록을 만드는
                // 도중에 부르면 build 중 상태 변경이 되어 프레임이 깨진다.
                onNotification: (notification) {
                  final feed = context.read<FeedCubit>();
                  final feedState = feed.state;
                  if (notification.metrics.extentAfter < 240 &&
                      !feedState.isLoadingMore &&
                      feedState.canLoadMore) {
                    feed.loadMore();
                  }
                  return false;
                },
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: Column(
                          children: [
                            AppAvatar(
                              nickname: profile.nickname,
                              imageUrl: profile.avatarUrl,
                              radius: 52,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              profile.nickname,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: Text(
                                profile.bio?.isNotEmpty == true
                                    ? profile.bio!
                                    : '소개를 작성해보세요.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (isMine) ...[
                              const SizedBox(height: AppSpacing.md),
                              AppButton.secondary(
                                label: '프로필 편집',
                                onPressed: () async {
                                  await context.push(Routes.profileEdit);
                                  if (context.mounted) {
                                    context.read<ProfileCubit>().load();
                                  }
                                },
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Text('게시물'),
                      ),
                    ),
                    _ProfilePostList(isMine: isMine),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _ProfileAction { block, unblock, report }

/// 프로필 AppBar 메뉴와 게시물 목록(다른 사용자 글) 메뉴 두 진입점이 같은
/// 확인 다이얼로그 · 차단 호출 · 목록 새로고침 · 스낵바 흐름을 쓴다. 원래는
/// 두 곳에 같은 코드가 복제돼 있었고, 새로고침을 기다리는지(await) 여부도
/// 미묘하게 달랐다 — 이 헬퍼 하나로 합쳐 두 진입점의 동작을 일치시킨다
/// (2026-08-26 리뷰 반영).
Future<void> _confirmAndBlock(BuildContext context, String userId) async {
  final confirmed = await AppConfirmDialog.show(
    context,
    title: '이 사용자를 차단할까요?',
    content: '차단하면 이 사용자의 게시물과 댓글이 더 이상 보이지 않습니다.',
    confirmLabel: '차단',
  );
  if (!confirmed || !context.mounted) return;

  final feed = context.read<FeedCubit>();
  final action = context.read<BlockActionCubit>();
  final succeeded = await action.block(userId);
  if (!context.mounted) return;

  if (succeeded) {
    await feed.refresh();
    if (!context.mounted) return;
  }
  AppSnackBar.show(
    context,
    message: succeeded
        ? '차단했습니다.'
        : action.state.failure?.message ?? '차단하지 못했습니다.',
    type: succeeded ? AppSnackBarType.success : AppSnackBarType.error,
  );
}

/// 차단 해제는 확인 없이 바로 실행한다 — 되돌리기 쉬운 동작이라는 스펙
/// 결정(`docs/features/safety/plan-block.md` "확인 절차")을 따른다. 목록
/// 화면(`blocked_users_page`)의 즉시 해제와 이 화면의 동작을 일치시킨다.
Future<void> _unblockProfile(BuildContext context, String userId) async {
  final feed = context.read<FeedCubit>();
  final action = context.read<BlockActionCubit>();
  final succeeded = await action.unblock(userId);
  if (!context.mounted) return;

  if (succeeded) {
    await feed.refresh();
    if (!context.mounted) return;
  }
  AppSnackBar.show(
    context,
    message: succeeded
        ? '차단을 해제했습니다.'
        : action.state.failure?.message ?? '차단을 해제하지 못했습니다.',
    type: succeeded ? AppSnackBarType.success : AppSnackBarType.error,
  );
}

/// 프로필 주인이 쓴 게시물 목록.
///
/// [isMine] 이면 피드와 같은 수정·삭제 흐름을 붙인다. 다른 사람의 프로필은
/// 조회 전용이다 — 이미 그 작성자의 화면이라 작성자로 다시 이동할 곳이 없다.
class _ProfilePostList extends StatelessWidget {
  const _ProfilePostList({required this.isMine});
  final bool isMine;

  @override
  Widget build(BuildContext context) => BlocBuilder<FeedCubit, FeedState>(
    builder: (context, state) => switch (state.status) {
      FeedStatus.loading => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      FeedStatus.failure => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppButton.secondary(
            label: '게시물을 다시 불러오기',
            onPressed: () => context.read<FeedCubit>().refresh(),
          ),
        ),
      ),
      FeedStatus.loaded when state.items.isEmpty => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: Text('아직 게시물이 없습니다')),
        ),
      ),
      FeedStatus.loaded => SliverList.builder(
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = state.items[index];
          final post = item.post;
          return PostTile(
            post: post,
            author: item.author,
            isMine: isMine,
            reactions: item.reactions,
            commentCount: item.commentCount,
            // 이미 이 작성자의 프로필이므로 남의 글은 눌러도 갈 곳이 없다.
            onTap: isMine ? () => PostTileActions.edit(context, post) : () {},
            onEdit: isMine ? () => PostTileActions.edit(context, post) : null,
            onDelete: isMine
                ? () => PostTileActions.confirmDelete(context, post)
                : null,
            onReport: isMine
                ? null
                : () => PostTileActions.report(
                    context,
                    ReportTarget.post(post.id),
                  ),
            // 차단만 화면이 직접 잇는다. 성공 뒤 이 작성자의 목록을 통째로 다시
            // 읽는 것은 프로필 화면에만 맞는 반영이다 (피드는 항목만 걷어낸다).
            onBlock: isMine
                ? null
                : () => _confirmAndBlock(context, item.author.id),
            onReaction: (type) => PostTileActions.react(context, post.id, type),
            onComment: () => PostTileActions.openComments(context, item),
          );
        },
      ),
    },
  );
}
