import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_avatar.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_overflow_menu.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../feed/domain/entity/feed_post.dart';
import '../../../feed/presentation/cubit/feed_cubit.dart';
import '../../../feed/presentation/cubit/feed_state.dart';
import '../../../post/domain/entity/post.dart';
import '../../../post/presentation/cubit/post_cubit.dart';
import '../../../post/presentation/widget/post_tile.dart';
import '../../../reaction/domain/entity/reaction_type.dart';
import '../../../safety/domain/entity/report_target.dart';
import '../../../safety/domain/usecase/safety_use_case.dart';
import '../../../safety/presentation/widget/report_sheet.dart';
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
          listener: (context, state) =>
              context.read<FeedCubit>().loadForAuthor(state.profile!.id),
        ),
        // 하단 내비게이션 셸이 이 화면을 살려 두므로, 설정에서 프로필을 고치고
        // 탭으로 돌아오면 옛 값이 그대로 남는다. 세션 스냅샷이 바뀌는 것을
        // 신호로 삼아 내 프로필만 다시 읽는다 — 편집 화면이 저장 직후
        // userRefreshRequested 를 보낸다.
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) => switch ((previous, current)) {
            (AuthAuthenticated(user: final before), AuthAuthenticated(
              user: final after,
            )) =>
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
              AppOverflowMenu<_ProfileAction>(
                tooltip: '프로필 메뉴',
                onSelected: (action) => switch (action) {
                  _ProfileAction.report => _report(
                    context,
                    ReportTarget.user(loadedProfile.id),
                  ),
                },
                items: const [
                  AppOverflowMenuItem(
                    value: _ProfileAction.report,
                    label: '신고',
                  ),
                ],
              ),
          ],
        ),
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state.isLoading && state.profile == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.failure != null && state.profile == null) {
              return _ProfileLoadError(
                message: state.failure?.message ?? '프로필을 불러오지 못했습니다',
                onRetry: () =>
                    context.read<ProfileCubit>().load(userId: requestedUserId),
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

enum _ProfileAction { report }

/// 게시물·사용자 신고 시트를 열고, 접수됐을 때만 스낵바를 띄운다.
///
/// 시트의 `BuildContext` 는 닫히면서 함께 사라지므로 스낵바는 호출한 화면의
/// context 로 띄운다. [_ProfileView] 의 AppBar 신고와 [_ProfilePostList] 의
/// 게시물 신고가 이 파일 안에서 같이 쓴다 — 다른 화면(피드)과는 공유하지
/// 않는다.
Future<void> _report(BuildContext context, ReportTarget target) async {
  final filed = await ReportSheet.show(context, target);
  if (!context.mounted) return;
  if (filed) {
    AppSnackBar.show(
      context,
      message: '신고가 접수되었습니다',
      type: AppSnackBarType.success,
    );
  }
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
            onTap: isMine ? () => _edit(context, post) : () {},
            onEdit: isMine ? () => _edit(context, post) : null,
            onDelete: isMine ? () => _confirmDelete(context, post) : null,
            onReport: isMine
                ? null
                : () => _report(context, ReportTarget.post(post.id)),
            onBlock: isMine
                ? null
                : () => _block(context, item.author.id),
            onReaction: (type) => _react(context, post.id, type),
            onComment: () => _openComments(context, item),
          );
        },
      ),
    },
  );

  /// 감정과 댓글 연결은 피드 화면과 같다. 두 화면 모두 목록을 [FeedCubit] 이
  /// 소유하므로 저장·복원도 같은 곳에서 한다.
  Future<void> _react(
    BuildContext context,
    String postId,
    ReactionType type,
  ) async {
    final result = await context.read<FeedCubit>().toggleReaction(postId, type);
    if (!context.mounted) return;

    result.when(
      ok: (_) {},
      err: (failure) => AppSnackBar.show(
        context,
        message: failure.message ?? '감정을 남기지 못했습니다.',
        type: AppSnackBarType.error,
      ),
    );
  }

  Future<void> _openComments(BuildContext context, FeedPost item) async {
    final feed = context.read<FeedCubit>();
    final count = await context.push<int>(
      Routes.postCommentsPath(item.id),
      extra: item.commentCount,
    );
    if (count != null) feed.applyCommentCount(item.id, count);
  }

  Future<void> _edit(BuildContext context, Post post) async {
    final feed = context.read<FeedCubit>();
    final updated = await context.push<Post>(
      Routes.postEditPath(post.id),
      extra: post,
    );
    if (updated != null) feed.replacePost(updated);
  }

  /// 차단은 되돌릴 수 없이 상대의 글을 통째로 지운다 — 삭제와 같은 무게로
  /// 확인을 받는다 (`account_settings_page` 의 탈퇴 확인과 같은 모양).
  /// 성공하면 이 작성자의 프로필 게시물 목록을 다시 읽는다 — 이제 비어야
  /// 한다. 상대가 나를 차단했는지 여부는 절대 드러내지 않는다.
  Future<void> _block(BuildContext context, String authorId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('이 사용자를 차단할까요?'),
        content: const Text(
          '차단하면 이 사용자의 게시물과 댓글이 더 이상 보이지 않습니다.',
        ),
        actions: [
          AppButton.text(
            label: '취소',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppButton.text(
            label: '차단',
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final feed = context.read<FeedCubit>();
    final result = await getIt<SafetyUseCase>().blockUser(authorId);
    if (!context.mounted) return;

    result.when(
      ok: (_) {
        feed.refresh();
        AppSnackBar.show(
          context,
          message: '차단했습니다.',
          type: AppSnackBarType.success,
        );
      },
      err: (failure) => AppSnackBar.show(
        context,
        message: failure.message ?? '차단하지 못했습니다.',
        type: AppSnackBarType.error,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('게시물을 삭제할까요?'),
        content: const Text('삭제한 게시물은 되돌릴 수 없습니다.'),
        actions: [
          AppButton.text(
            label: '취소',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppButton.text(
            label: '삭제',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final feed = context.read<FeedCubit>();
    final result = await context.read<PostCubit>().delete(post.id);
    if (!context.mounted) return;

    result.when(
      ok: (_) {
        feed.removePost(post.id);
        AppSnackBar.show(
          context,
          message: '게시물을 삭제했습니다.',
          type: AppSnackBarType.success,
        );
      },
      err: (failure) => AppSnackBar.show(
        context,
        message: failure.message ?? '게시물을 삭제하지 못했습니다.',
        type: AppSnackBarType.error,
      ),
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(label: '다시 시도', onPressed: onRetry),
        ],
      ),
    ),
  );
}
