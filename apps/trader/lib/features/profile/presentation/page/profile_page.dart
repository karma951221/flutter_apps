import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';
import 'package:l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/feature_auth.dart';
import '../../../chat/domain/usecase/chat_use_case.dart';
import '../../../chat/presentation/page/chat_room_page.dart';
import '../../../feed/presentation/cubit/feed_cubit.dart';
import '../../../follow/presentation/cubit/follow_action_cubit.dart';
import '../../../follow/presentation/cubit/follow_action_state.dart';
import '../../../feed/presentation/cubit/feed_state.dart';
import '../../../feed/presentation/widget/post_tile_actions.dart';
import '../../../post/domain/entity/post.dart';
import '../../../post/domain/entity/post_author.dart';
import '../../../post/presentation/cubit/post_cubit.dart';
import '../../../post/presentation/widget/post_tile.dart';
import '../../../safety/domain/entity/report_target.dart';
import '../../../safety/presentation/cubit/block_action_cubit.dart';
import '../../../safety/presentation/cubit/block_action_state.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widget/profile_completion_card.dart';

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
      BlocProvider(create: (_) => getIt<FollowActionCubit>()),
    ],
    child: _ProfileView(requestedUserId: userId),
  );
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({this.requestedUserId});

  final String? requestedUserId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        // 보고 있는 사람이 바뀌었을 때만 할 일 — 그 사람의 글을 읽고 차단
        // 여부를 묻는다. 당겨서 새로고침은 같은 id 를 다시 읽는 것이라 여기
        // 걸리지 않고, 목록은 새로고침이 feed.refresh() 로 따로 챙긴다.
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
        // 다른 화면에서 띄운 작성 화면(예: 매매 결과의 공유하기)이 만든 글도
        // 이 목록에 바로 올라오게 한다. 남의 프로필은 내 글이 낄 자리가
        // 아니므로 듣지 않는다.
        //
        // id 가 아니라 프로필 값이 바뀔 때마다 다시 심는다 — 목록에 붙일 때
        // 쓸 이름·사진을 여기서 넘기므로, 프로필을 고친 뒤에는 새 값으로
        // 들어야 한다.
        BlocListener<ProfileCubit, ProfileState>(
          listenWhen: (previous, current) =>
              isMine &&
              current.profile != null &&
              previous.profile != current.profile,
          listener: (context, state) {
            final profile = state.profile!;
            context.read<FeedCubit>().watchCreatedPosts(
              PostAuthor(
                id: profile.id,
                nickname: profile.nickname,
                avatarUrl: profile.avatarUrl,
              ),
            );
          },
        ),
        // 팔로우 버튼은 프로필 응답이 바뀔 때마다 다시 심는다.
        //
        // 관계와 팔로워 수는 프로필 조회가 함께 내려주므로 버튼이 따로 묻지
        // 않는다 (docs/features/follow/plan.md). 그래서 id 가 바뀔 때만
        // 심으면, 같은 사람을 다시 읽는 당겨서 새로고침에서는 값이 갱신되지
        // 않는다 — 그 사이 남이 팔로우해 팔로워가 늘거나 관계가 뒤집혔어도
        // 버튼과 팔로워 수만 옛 값으로 남고, 그 상태로 누르면 이미 있는 행을
        // 다시 넣으려다 실패한다. 프로필 값이 바뀌면(그 안에 관계·팔로워 수가
        // 들어 있다) 다시 심는 것이 맞다.
        BlocListener<ProfileCubit, ProfileState>(
          listenWhen: (previous, current) =>
              current.profile != null && previous.profile != current.profile,
          listener: (context, state) {
            final profile = state.profile!;
            final followCubit = context.read<FollowActionCubit>();
            // 낙관적 업데이트가 아직 떠 있으면 심지 않는다. 누른 직후의 값을
            // 서버가 아직 모르는 응답으로 덮으면 버튼이 되돌아갔다가 다시
            // 바뀐다.
            if (followCubit.state.isSubmitting) return;
            followCubit.seed(
              relation: profile.relation,
              followerCount: profile.followerCount,
            );
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
          title: Text(isMine ? l10n.profileTitle : l10n.profileUserTitle),
          actions: [
            if (!isMine && loadedProfile != null)
              BlocBuilder<BlockActionCubit, BlockActionState>(
                builder: (context, blockState) =>
                    AppOverflowMenu<_ProfileAction>(
                      tooltip: l10n.profileMenuTooltip,
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
                          AppOverflowMenuItem(
                            value: _ProfileAction.block,
                            label: l10n.safetyBlockConfirmAction,
                            isDestructive: true,
                          ),
                        if (!blockState.isLoadingStatus &&
                            blockState.isBlocked == true)
                          AppOverflowMenuItem(
                            value: _ProfileAction.unblock,
                            label: l10n.profileMenuUnblock,
                          ),
                        AppOverflowMenuItem(
                          value: _ProfileAction.report,
                          label: l10n.safetyReportTitle,
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
                  message:
                      state.failure?.localizedMessage(context) ??
                      l10n.profileLoadFailed,
                  actionLabel: l10n.commonRetry,
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
              child: AppLoadMoreListener(
                // 다음 페이지 요청은 스크롤 알림으로만 낸다. 목록을 만드는
                // 도중에 부르면 build 중 상태 변경이 되어 프레임이 깨진다.
                onLoadMore: () {
                  final feed = context.read<FeedCubit>();
                  final feedState = feed.state;
                  if (!feedState.isLoadingMore && feedState.canLoadMore) {
                    feed.loadMore();
                  }
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
                                    : l10n.profileBioEmpty,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _FollowStats(
                              userId: profile.id,
                              followingCount: profile.followingCount,
                            ),
                            if (!isMine)
                              _ProfileActions(
                                userId: profile.id,
                                nickname: profile.nickname,
                              ),
                            if (isMine) ...[
                              const SizedBox(height: AppSpacing.md),
                              AppButton.secondary(
                                label: l10n.profileEditAction,
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
                    // 내 프로필에만. 첫 게시물 여부는 목록을 소유한 FeedCubit 이
                    // 알고, 목록을 읽는 중에는 깜빡임을 피하려 그리지 않는다.
                    if (isMine)
                      SliverToBoxAdapter(
                        child: BlocBuilder<FeedCubit, FeedState>(
                          builder: (context, feedState) =>
                              feedState.status != FeedStatus.loaded
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.lg,
                                  ),
                                  child: ProfileCompletionCard(
                                    profile: profile,
                                    hasPost: feedState.items.isNotEmpty,
                                    onEditProfile: () async {
                                      await context.push(Routes.profileEdit);
                                      if (context.mounted) {
                                        context.read<ProfileCubit>().load();
                                      }
                                    },
                                    onWritePost: () async {
                                      final feed = context.read<FeedCubit>();
                                      final created = await context.push<Post>(
                                        Routes.postCompose,
                                      );
                                      if (created != null) await feed.refresh();
                                    },
                                  ),
                                ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Text(l10n.profilePostsTitle),
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

/// 팔로워 · 팔로잉 수. 눌러서 각 목록으로 들어간다.
///
/// 팔로워 수는 [FollowActionCubit] 이 든 값을 그린다 — 팔로우 버튼이 낙관적으로
/// 움직일 때 수도 함께 움직여야 한다. 팔로잉 수는 내 동작으로 바뀌지 않으므로
/// 프로필 조회값을 그대로 쓴다.
class _FollowStats extends StatelessWidget {
  const _FollowStats({required this.userId, required this.followingCount});

  final String userId;
  final int followingCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<FollowActionCubit, FollowActionState>(
      builder: (context, state) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FollowStat(
            label: l10n.followFollowersLabel,
            count: state.followerCount,
            onTap: () => context.push(Routes.userFollowersPath(userId)),
          ),
          const SizedBox(width: AppSpacing.lg),
          _FollowStat(
            label: l10n.followFollowingsLabel,
            count: followingCount,
            onTap: () => context.push(Routes.userFollowingsPath(userId)),
          ),
        ],
      ),
    );
  }
}

class _FollowStat extends StatelessWidget {
  const _FollowStat({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count', style: theme.textTheme.titleMedium),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 남의 프로필에서 할 수 있는 것 — 팔로우와 1:1 대화.
///
/// 차단한 사이에는 둘 다 그리지 않는다. 팔로우도 대화 시작도 어차피 거부되고,
/// 거부 문구로 관계를 설명하게 되면 차단 사실이 새는 자리가 된다.
class _ProfileActions extends StatelessWidget {
  const _ProfileActions({required this.userId, required this.nickname});

  final String userId;
  final String nickname;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<BlockActionCubit, BlockActionState>(
        builder: (context, blockState) {
          if (blockState.isBlocked != false) return const SizedBox.shrink();

          // 버튼의 공통 스타일이 가로를 꽉 채우므로(AppTheme 의
          // `Size.fromHeight`) 폭은 [Expanded] 로 반씩 나눈다.
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Row(
              children: [
                Expanded(child: _FollowButton(userId: userId)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MessageButton(userId: userId, nickname: nickname),
                ),
              ],
            ),
          );
        },
      );
}

/// 팔로우 버튼. 상태 셋(팔로우 · 팔로잉 · 맞팔로우)을 라벨과 종류로 나눈다.
///
/// 새 공용 위젯을 만들지 않는다 — [AppButton] 의 기존 인자로 해결된다
/// (UI 규칙 ④).
class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<FollowActionCubit, FollowActionState>(
      builder: (context, state) {
        final label = state.isMutual
            ? l10n.followMutualAction
            : state.isFollowing
            ? l10n.followFollowingAction
            : l10n.followAction;
        final onPressed = state.isSubmitting ? null : () => _toggle(context);

        return state.isFollowing
            ? AppButton.secondary(label: label, onPressed: onPressed)
            : AppButton.primary(label: label, onPressed: onPressed);
      },
    );
  }

  Future<void> _toggle(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<FollowActionCubit>();
    final wasFollowing = cubit.state.isFollowing;
    final succeeded = await cubit.toggle(userId);
    if (!context.mounted || succeeded) return;

    AppSnackBar.show(
      context,
      message:
          cubit.state.failure?.localizedMessage(context) ??
          (wasFollowing ? l10n.followUnfollowFailed : l10n.followFailed),
      type: AppSnackBarType.error,
    );
  }
}

/// 1:1 대화 진입점.
///
/// 방을 새로 만드는지 이미 있는 방을 여는지는 RPC 가 정한다 — 화면은 돌아온
/// 방 id 로 이동만 하고, 상대 닉네임을 제목으로 함께 넘겨 방 화면이 방 행을
/// 다시 읽지 않게 한다.
class _MessageButton extends StatefulWidget {
  const _MessageButton({required this.userId, required this.nickname});

  final String userId;
  final String nickname;

  @override
  State<_MessageButton> createState() => _MessageButtonState();
}

class _MessageButtonState extends State<_MessageButton> {
  /// 연타 방지. RPC 는 같은 방을 돌려주지만 그대로 두면 방 화면이 두 번
  /// 쌓인다.
  bool _opening = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppButton.secondary(
      label: l10n.profileMessageButton,
      onPressed: _opening ? null : _open,
    );
  }

  Future<void> _open() async {
    setState(() => _opening = true);
    final result = await getIt<ChatUseCase>().openDirectRoom(widget.userId);
    if (!mounted) return;
    setState(() => _opening = false);

    switch (result) {
      case Ok(value: final roomId):
        context.push(
          Routes.chatRoomPath(roomId),
          extra: ChatRoomPageArgs(
            title: widget.nickname,
            isDirect: true,
          ).toMap(),
        );
      case Err(:final failure):
        AppSnackBar.show(
          context,
          message: failure.localizedMessage(context),
          type: AppSnackBarType.error,
        );
    }
  }
}

/// 프로필 AppBar 메뉴와 게시물 목록(다른 사용자 글) 메뉴 두 진입점이 같은
/// 확인 다이얼로그 · 차단 호출 · 목록 새로고침 · 스낵바 흐름을 쓴다. 원래는
/// 두 곳에 같은 코드가 복제돼 있었고, 새로고침을 기다리는지(await) 여부도
/// 미묘하게 달랐다 — 이 헬퍼 하나로 합쳐 두 진입점의 동작을 일치시킨다
/// (2026-08-26 리뷰 반영).
Future<void> _confirmAndBlock(BuildContext context, String userId) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await AppConfirmDialog.show(
    context,
    title: l10n.safetyBlockConfirmTitle,
    content: l10n.safetyBlockConfirmMessage,
    confirmLabel: l10n.safetyBlockConfirmAction,
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
        ? l10n.safetyBlockSucceeded
        : action.state.failure?.localizedMessage(context) ??
              l10n.safetyBlockFailed,
    type: succeeded ? AppSnackBarType.success : AppSnackBarType.error,
  );
}

/// 차단 해제는 확인 없이 바로 실행한다 — 되돌리기 쉬운 동작이라는 스펙
/// 결정(`docs/features/safety/plan-block.md` "확인 절차")을 따른다. 목록
/// 화면(`blocked_users_page`)의 즉시 해제와 이 화면의 동작을 일치시킨다.
Future<void> _unblockProfile(BuildContext context, String userId) async {
  final l10n = AppLocalizations.of(context);
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
        ? l10n.safetyUnblockSucceeded
        : action.state.failure?.localizedMessage(context) ??
              l10n.safetyUnblockFailed,
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<FeedCubit, FeedState>(
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
              label: l10n.profilePostsReload,
              onPressed: () => context.read<FeedCubit>().refresh(),
            ),
          ),
        ),
        FeedStatus.loaded when state.items.isEmpty => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(child: Text(l10n.profilePostsEmpty)),
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
              onReaction: (type) =>
                  PostTileActions.react(context, post.id, type),
              onComment: () => PostTileActions.openComments(context, item),
              onTradeResultTap: (sessionId) =>
                  context.push(Routes.tradeResultPath(sessionId)),
            );
          },
        ),
      },
    );
  }
}
