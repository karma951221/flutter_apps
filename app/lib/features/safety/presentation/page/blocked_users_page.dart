import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_avatar.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_list_tile.dart';
import '../../../../design_system/widget/app_placeholder.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('차단한 사용자')),
    body: SafeArea(
      child: BlocBuilder<BlockedUsersCubit, BlockedUsersState>(
        builder: (context, state) => switch (state.status) {
          BlockedUsersStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          BlockedUsersStatus.failure => Center(
            child: AppPlaceholder(
              message: state.failure?.message ?? '차단 목록을 불러오지 못했습니다',
              actionLabel: '다시 시도',
              onAction: () => context.read<BlockedUsersCubit>().load(),
            ),
          ),
          BlockedUsersStatus.loaded => _BlockedUsersList(items: state.items),
        },
      ),
    ),
  );
}

class _BlockedUsersList extends StatelessWidget {
  const _BlockedUsersList({required this.items});

  final List<BlockedUser> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('차단한 사용자가 없습니다'));
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
              label: '차단 해제',
              onPressed: () => _unblock(context, user),
            ),
          ),
        );
      },
    );
  }

  Future<void> _unblock(BuildContext context, BlockedUser user) async {
    final succeeded = await context.read<BlockedUsersCubit>().unblock(
      user.id,
    );
    if (!context.mounted) return;

    AppSnackBar.show(
      context,
      message: succeeded ? '차단을 해제했습니다.' : '차단을 해제하지 못했습니다.',
      type: succeeded ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }
}

