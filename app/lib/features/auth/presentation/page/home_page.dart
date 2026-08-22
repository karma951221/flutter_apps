import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_avatar.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// 인증 후 진입 화면. F3(post) / F4(feed) 가 들어오면 교체된다.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('daylog'),
        actions: [
          IconButton(
            tooltip: '프로필',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(Routes.profile),
          ),
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(
              const AuthEvent.signOutRequested(),
            ),
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = state.user;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppAvatar(nickname: user.nickname, imageUrl: user.avatarUrl),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    user.nickname,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton.primary(
                    label: '내 프로필 보기',
                    onPressed: () => context.push(Routes.profile),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
