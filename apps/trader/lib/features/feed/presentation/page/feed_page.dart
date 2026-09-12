import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';
import 'package:l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_post/feature_post.dart';
import 'package:feature_safety/feature_safety.dart';
import '../../domain/entity/feed_post.dart';
import '../cubit/feed_cubit.dart';
import '../cubit/feed_state.dart';
import '../widget/post_tile_actions.dart';

/// 피드 목록 화면.
///
/// 목록은 [FeedCubit] 이, 게시물 변경은 [PostCubit] 이 소유한다. 변경 결과를
/// 목록 상태에 반영해 전체 재조회 없이 화면을 맞춘다.
///
/// 하단 내비게이션 셸의 탭 본문으로도 쓰이므로 화면 밖으로 나가는 동작(로그아웃
/// 등)을 AppBar 에 두지 않는다. 새로고침도 당겨서 새로고침 하나로 모았다 —
/// 같은 일을 하는 입구가 둘이면 AppBar 만 붐빈다.
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => getIt<FeedCubit>()..load()),
      BlocProvider(create: (_) => getIt<PostCubit>()),
      BlocProvider(create: (_) => getIt<BlockActionCubit>()),
    ],
    child: const _FeedView(),
  );
}

/// 방금 쓴 글을 목록에 넣을 때 쓸 작성자. 본인이므로 세션 값으로 충분하다.
PostAuthor? _currentAuthor(AuthState state) => switch (state) {
  AuthAuthenticated(:final user) => PostAuthor(
    id: user.id,
    nickname: user.nickname,
    avatarUrl: user.avatarUrl,
  ),
  _ => null,
};

class _FeedView extends StatefulWidget {
  const _FeedView();

  @override
  State<_FeedView> createState() => _FeedViewState();
}

/// 탭 둘(전체 · 팔로잉)을 하나의 [FeedCubit] 이 번갈아 채운다.
///
/// 탭마다 cubit 을 따로 두지 않는 이유: 게시물 작성·수정·삭제·차단의 결과를
/// 목록에 반영하는 배선이 한 벌뿐이고, 두 벌이 되면 어느 쪽을 갱신할지
/// 화면이 매번 정해야 한다. 대가는 탭을 옮길 때 다시 읽는 것이다 — 스크롤
/// 위치가 초기화된다.
class _FeedViewState extends State<_FeedView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  )..addListener(_onTabChanged);

  @override
  void initState() {
    super.initState();
    _watchCreatedPosts(_currentAuthor(context.read<AuthBloc>().state));
  }

  /// 다른 화면에서 띄운 작성 화면(예: 매매 결과의 공유하기)이 만든 글도 이
  /// 목록에 바로 올라오게 한다. `_compose` 의 prependPost 는 그대로 둔다 —
  /// `prependPost` 가 멱등이라 두 경로가 겹쳐도 한 번만 붙는다.
  void _watchCreatedPosts(PostAuthor? author) {
    if (author == null) return;
    context.read<FeedCubit>().watchCreatedPosts(author);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // 드래그 중에는 두 번 불린다. 애니메이션이 끝난 뒤 한 번만 읽는다.
    if (_tabController.indexIsChanging) return;
    final feed = context.read<FeedCubit>();
    if (_tabController.index == 0) {
      feed.load();
    } else {
      feed.loadFollowing();
    }
  }

  bool get _isFollowingTab => _tabController.index == 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentAuthor = _currentAuthor(context.watch<AuthBloc>().state);

    return BlocListener<AuthBloc, AuthState>(
      // 로그인한 사람(또는 그 이름·사진)이 바뀌면 새 값으로 다시 듣는다.
      listenWhen: (previous, current) =>
          _currentAuthor(previous) != _currentAuthor(current),
      listener: (context, state) => _watchCreatedPosts(_currentAuthor(state)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('daylog'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n.feedTabAll),
              Tab(text: l10n.feedTabFollowing),
            ],
          ),
        ),
        body: BlocBuilder<FeedCubit, FeedState>(
          builder: (context, state) => switch (state.status) {
            FeedStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            FeedStatus.failure => Center(
              child: AppPlaceholder(
                icon: Icons.cloud_off_outlined,
                message:
                    state.failure?.localizedMessage(context) ??
                    l10n.feedLoadFailed,
                description: l10n.feedLoadFailedDescription,
                actionLabel: l10n.commonRetry,
                // load() 가 아니라 refresh() 다 — load() 는 소스를 전체로
                // 되돌리므로, 팔로잉 탭에서 실패한 뒤 다시 시도를 누르면 탭은
                // 팔로잉인 채로 전체 피드가 그려진다.
                onAction: () => context.read<FeedCubit>().refresh(),
              ),
            ),
            FeedStatus.loaded => _FeedList(
              items: state.items,
              currentUserId: currentAuthor?.id ?? '',
              isLoadingMore: state.isLoadingMore,
              canLoadMore: state.canLoadMore,
              isFollowingTab: _isFollowingTab,
              onCompose: () => _compose(context, currentAuthor),
              // 탭을 옮기면 리스너가 load() 를 부른다 — 여기서 다시 읽지 않는다.
              onBrowseAll: () => _tabController.animateTo(0),
            ),
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          // 홈 셸이 탭 본문을 IndexedStack 으로 동시에 살려 두므로, 채팅 탭의
          // FAB 과 기본 태그가 겹치면 라우트 전환에서 hero 충돌 단언이 난다.
          heroTag: 'feed-compose',
          tooltip: l10n.feedComposeTooltip,
          onPressed: () => _compose(context, currentAuthor),
          icon: const Icon(Icons.edit),
          label: Text(l10n.feedComposeLabel),
        ),
      ),
    );
  }

  Future<void> _compose(BuildContext context, PostAuthor? author) async {
    final feed = context.read<FeedCubit>();
    final created = await context.push<Post>(Routes.postCompose);
    if (created == null) return;

    // 세션이 없는데 작성에 성공하는 경로는 없다. 그래도 작성자를 지어내지
    // 않고 재조회로 물러선다 — 잘못된 이름이 목록에 남는 것보다 낫다.
    if (author == null) {
      await feed.refresh();
      return;
    }
    feed.prependPost(FeedPost(post: created, author: author));
  }
}

class _FeedList extends StatelessWidget {
  const _FeedList({
    required this.items,
    required this.currentUserId,
    required this.isLoadingMore,
    required this.canLoadMore,
    required this.isFollowingTab,
    required this.onCompose,
    required this.onBrowseAll,
  });

  /// 목록 맨 아래가 확장 FAB 에 가리지 않도록 두는 여백.
  static const _fabClearance = AppSpacing.xl * 3;

  final List<FeedPost> items;
  final String currentUserId;
  final bool isLoadingMore;
  final bool canLoadMore;

  /// 팔로잉 탭이면 비어 있음 안내가 달라진다 — 글이 없는 것이 아니라
  /// 팔로우한 사람이 없는 것이다.
  final bool isFollowingTab;
  final VoidCallback onCompose;

  /// 팔로잉 탭이 비어 있을 때 전체 탭으로 보내는 행동. 빈 화면이 막다른 길이
  /// 되지 않게 한다 (ux-psychology-review.md 2번).
  final VoidCallback onBrowseAll;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _empty(context);

    return RefreshIndicator(
      onRefresh: () => context.read<FeedCubit>().refresh(),
      child: AppLoadMoreListener(
        onLoadMore: () {
          if (!isLoadingMore && canLoadMore) {
            context.read<FeedCubit>().loadMore();
          }
        },
        child: ListView.builder(
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: _fabClearance,
          ),
          // 마지막 한 칸은 항상 꼬리표 자리다. 더 읽는 중인지 끝까지 읽었는지를
          // 그 자리에서 구분해 알린다.
          itemCount: items.length + 1,
          itemBuilder: (context, index) {
            if (index == items.length) {
              return AppListFooter(
                isLoadingMore: isLoadingMore,
                canLoadMore: canLoadMore,
              );
            }

            final item = items[index];
            final post = item.post;
            final isMine = post.authorId == currentUserId;
            return PostTile(
              post: post,
              author: item.author,
              isMine: isMine,
              reactions: item.reactions,
              commentCount: item.commentCount,
              onTap: isMine
                  ? () => PostTileActions.edit(context, post)
                  : () => context.push(Routes.userProfilePath(item.author.id)),
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
              onBlock: isMine ? null : () => _block(context, item.author.id),
              onReaction: (type) =>
                  PostTileActions.react(context, post.id, type),
              onComment: () => PostTileActions.openComments(context, item),
              onTradeResultTap: (sessionId) =>
                  context.push(Routes.tradeResultPath(sessionId)),
            );
          },
        ),
      ),
    );
  }

  /// 비어 있는 화면에서도 당겨서 새로고침이 되어야 하므로 안내를 스크롤 뷰
  /// 안에 넣는다. 화면 높이만큼 최소 높이를 줘서 가운데에 놓는다.
  Widget _empty(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: () => context.read<FeedCubit>().refresh(),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: isFollowingTab
                  ? AppPlaceholder(
                      icon: Icons.people_outline,
                      message: l10n.feedFollowingEmptyMessage,
                      description: l10n.feedFollowingEmptyDescription,
                      actionLabel: l10n.feedFollowingEmptyAction,
                      onAction: onBrowseAll,
                    )
                  : AppPlaceholder(
                      icon: Icons.edit_note_outlined,
                      message: l10n.feedEmptyMessage,
                      description: l10n.feedEmptyDescription,
                      actionLabel: l10n.feedEmptyAction,
                      onAction: onCompose,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// 차단은 되돌릴 수 없이 상대의 글을 통째로 지운다 — 삭제와 같은 무게로
  /// 확인을 받는다 (`account_settings_page` 의 탈퇴 확인과 같은 모양).
  /// 성공해도 상대가 나를 차단했는지 여부는 절대 드러내지 않는다.
  ///
  /// 실제 차단 호출은 [BlockActionCubit] 이 한다 — 화면은 확인 다이얼로그와
  /// 성공 후 목록 반영(`removeAuthor`), 스낵바만 소유한다.
  Future<void> _block(BuildContext context, String authorId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.safetyBlockConfirmTitle,
      content: l10n.safetyBlockConfirmMessage,
      confirmLabel: l10n.safetyBlockConfirmAction,
    );
    if (!confirmed || !context.mounted) return;

    final feed = context.read<FeedCubit>();
    final blockAction = context.read<BlockActionCubit>();
    final succeeded = await blockAction.block(authorId);
    if (!context.mounted) return;

    if (succeeded) {
      feed.removeAuthor(authorId);
      AppSnackBar.show(
        context,
        message: l10n.safetyBlockSucceeded,
        type: AppSnackBarType.success,
      );
    } else {
      AppSnackBar.show(
        context,
        message:
            blockAction.state.failure?.localizedMessage(context) ??
            l10n.safetyBlockFailed,
        type: AppSnackBarType.error,
      );
    }
  }
}
