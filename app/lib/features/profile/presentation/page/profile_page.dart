import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_avatar.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_list_tile.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ProfileCubit>()..load(),
    child: const _ProfileView(),
  );
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state.isLoading && state.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.failure != null && state.profile == null) {
            return _ProfileLoadError(
              message: state.failure?.message ?? '프로필을 불러오지 못했습니다',
              onRetry: context.read<ProfileCubit>().load,
            );
          }
          final profile = state.profile;
          if (profile == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: context.read<ProfileCubit>().load,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              children: [
                Center(
                  child: AppAvatar(
                    nickname: profile.nickname,
                    imageUrl: profile.avatarUrl,
                    radius: 52,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Text(
                    profile.nickname,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: profile.bio?.isNotEmpty == true
                          ? null
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('프로필 편집'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await context.push(Routes.profileEdit);
                    if (context.mounted) context.read<ProfileCubit>().load();
                  },
                ),
              ],
            ),
          );
        },
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
