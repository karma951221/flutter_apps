import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../theme/pawlog_theme.dart';
import '../cubit/community_cubit.dart';
import '../cubit/community_state.dart';
import '../widget/community_post_entry.dart';

/// 모두의 산책(`/community`) — 공유된 산책을 최신순으로 둘러보고 하트를 누른다.
///
/// 라우팅은 모른다. 로그인이 필요하면(로그아웃 상태의 하트 · 더보기 "로그인") [onSignIn] 을
/// 부른다. 로그인하면 cubit 이 세션 변화를 듣고 목록을 다시 읽어 `liked_by_me` 를 맞춘다.
class CommunityPage extends StatelessWidget {
  const CommunityPage({required this.onSignIn, super.key});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<CommunityCubit>()..start(),
    child: _CommunityView(onSignIn: onSignIn),
  );
}

enum _CommunityMenuAction { signIn, signOut }

class _CommunityView extends StatelessWidget {
  const _CommunityView({required this.onSignIn});

  final VoidCallback onSignIn;

  Future<void> _like(BuildContext context, String postId) async {
    final result = await context.read<CommunityCubit>().toggleLike(postId);
    if (!context.mounted) return;
    switch (result) {
      case Err(:final failure)
          when failure.failureCode == FailureCode.authenticationRequired:
        onSignIn();
      case Err(:final failure):
        AppSnackBar.show(
          context,
          message: failure.localizedMessage(context),
          type: AppSnackBarType.error,
        );
      case Ok():
        break;
    }
  }

  Future<void> _onMenu(
    BuildContext context,
    _CommunityMenuAction action,
  ) async {
    switch (action) {
      case _CommunityMenuAction.signIn:
        onSignIn();
      case _CommunityMenuAction.signOut:
        final result = await context.read<CommunityCubit>().signOut();
        if (!context.mounted) return;
        if (result case Err(:final failure)) {
          AppSnackBar.show(
            context,
            message: failure.localizedMessage(context),
            type: AppSnackBarType.error,
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<CommunityCubit>();

    return BlocConsumer<CommunityCubit, CommunityState>(
      listenWhen: (previous, current) => switch (current) {
        CommunityLoaded(:final failure?) => switch (previous) {
          CommunityLoaded(failure: final before) => before != failure,
          _ => true,
        },
        _ => false,
      },
      listener: (context, state) {
        if (state case CommunityLoaded(:final failure?)) {
          AppSnackBar.show(
            context,
            message: failure.localizedMessage(context),
            type: AppSnackBarType.error,
          );
        }
      },
      builder: (context, state) {
        final isSignedIn = switch (state) {
          CommunityUnavailable() => null,
          CommunityLoading(:final isSignedIn) ||
          CommunityLoaded(:final isSignedIn) ||
          CommunityFailure(:final isSignedIn) => isSignedIn,
        };
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.walkSocialTitle),
            actions: [
              // Supabase 를 쓸 수 없으면 로그인도 할 수 없다.
              if (isSignedIn != null)
                AppOverflowMenu<_CommunityMenuAction>(
                  key: const Key('community-more'),
                  items: [
                    if (isSignedIn)
                      AppOverflowMenuItem(
                        key: const Key('community-sign-out'),
                        value: _CommunityMenuAction.signOut,
                        label: l10n.walkSocialSignOut,
                        icon: Icons.logout,
                      )
                    else
                      AppOverflowMenuItem(
                        key: const Key('community-sign-in'),
                        value: _CommunityMenuAction.signIn,
                        label: l10n.walkSocialSignIn,
                        icon: Icons.login,
                      ),
                  ],
                  onSelected: (action) => _onMenu(context, action),
                ),
            ],
          ),
          body: SafeArea(
            child: switch (state) {
              CommunityUnavailable() => Center(
                child: AppPlaceholder(message: l10n.walkSocialLoadFailed),
              ),
              CommunityLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              CommunityFailure() => Center(
                child: AppPlaceholder(
                  message: l10n.walkSocialLoadFailed,
                  actionLabel: l10n.commonRetry,
                  actionKey: const Key('community-retry'),
                  onAction: cubit.retry,
                ),
              ),
              CommunityLoaded(:final posts, :final isLoadingMore) =>
                RefreshIndicator(
                  onRefresh: cubit.refresh,
                  child: posts.isEmpty
                      // 빈 목록도 당겨서 새로고침할 수 있게 스크롤되는 자리에 둔다.
                      ? LayoutBuilder(
                          builder: (context, constraints) => ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: constraints.maxHeight,
                                child: Center(
                                  child: AppPlaceholder(
                                    message: l10n.walkSocialEmpty,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : AppLoadMoreListener(
                          onLoadMore: cubit.loadMore,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(
                              top: PawlogSpacing.lg,
                            ),
                            // 끝 안내는 두지 않는다 — 피드와 같다. 읽는 동안에만 스피너 한 줄.
                            itemCount: posts.length + (isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == posts.length) {
                                return const AppListFooter(
                                  isLoadingMore: true,
                                  canLoadMore: true,
                                );
                              }
                              final post = posts[index];
                              return CommunityPostEntry(
                                key: Key('community-post-${post.id}'),
                                post: post,
                                onLike: () => _like(context, post.id),
                              );
                            },
                          ),
                        ),
                ),
            },
          ),
        );
      },
    );
  }
}
