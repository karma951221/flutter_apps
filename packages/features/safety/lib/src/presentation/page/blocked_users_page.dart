import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:core/core.dart';
import 'package:l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import '../../domain/entity/blocked_user.dart';
import '../cubit/blocked_users_cubit.dart';
import '../cubit/blocked_users_state.dart';

/// 내가 차단한 사용자 목록 화면.
///
/// 커서를 쓰지 않는다 — 차단 목록이 페이지가 필요할 만큼 커지는 사용자는
/// 이 앱의 대상이 아니다 (docs/features/safety/plan-block.md).
class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<BlockedUsersCubit>()..load(),
    child: const _BlockedUsersView(),
  );
}

class _BlockedUsersView extends StatelessWidget {
  const _BlockedUsersView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.safetyBlockedUsersTitle)),
      body: SafeArea(
        child: BlocBuilder<BlockedUsersCubit, BlockedUsersState>(
          builder: (context, state) => switch (state.status) {
            BlockedUsersStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            BlockedUsersStatus.failure => Center(
              child: AppPlaceholder(
                message:
                    state.failure?.localizedMessage(context) ??
                    l10n.safetyBlockedUsersLoadFailed,
                actionLabel: l10n.commonRetry,
                onAction: () => context.read<BlockedUsersCubit>().load(),
              ),
            ),
            BlockedUsersStatus.loaded => _BlockedUsersList(items: state.items),
          },
        ),
      ),
    );
  }
}

class _BlockedUsersList extends StatelessWidget {
  const _BlockedUsersList({required this.items});

  final List<BlockedUser> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (items.isEmpty) {
      return Center(child: Text(l10n.safetyBlockedUsersEmpty));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final user = items[index];
        return AppListTile(
          leading: AppAvatar(
            nickname: user.nickname,
            imageUrl: user.avatarUrl,
            radius: 20,
          ),
          title: Text(user.nickname),
          trailing: IntrinsicWidth(
            child: AppButton.text(
              label: l10n.safetyUnblockAction,
              onPressed: () => _unblock(context, user),
            ),
          ),
        );
      },
    );
  }

  Future<void> _unblock(BuildContext context, BlockedUser user) async {
    final l10n = AppLocalizations.of(context);
    final succeeded = await context.read<BlockedUsersCubit>().unblock(user.id);
    if (!context.mounted) return;

    AppSnackBar.show(
      context,
      message: succeeded
          ? l10n.safetyUnblockSucceeded
          : l10n.safetyUnblockFailed,
      type: succeeded ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }
}
