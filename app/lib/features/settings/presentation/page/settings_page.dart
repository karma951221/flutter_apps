import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';

import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_avatar.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_list_tile.dart';
import '../../../auth/domain/entity/app_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../theme/domain/entity/app_theme_mode.dart';
import '../../../theme/presentation/cubit/theme_cubit.dart';

/// 설정 화면.
///
/// 상태를 소유하지 않는다. 화면 위쪽 요약은 [AuthBloc] 의 세션 사용자를 그대로
/// 읽고, 목록은 다른 화면으로 보내기만 한다. 그래서 이 feature 에는
/// presentation 만 있고 domain·data 가 없다.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = switch (context.watch<AuthBloc>().state) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: SafeArea(
        child: ListView(
          children: [
            if (user != null) _AccountSummary(user: user),
            const Divider(height: 1),
            AppListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('프로필 편집'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.profileEdit),
            ),
            AppListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('계정 설정'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.accountSettings),
            ),
            AppListTile(
              leading: const Icon(Icons.brightness_6_outlined),
              title: const Text('화면 테마'),
              subtitle: Text(context.watch<ThemeCubit>().state.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectThemeMode(context),
            ),
            AppListTile(
              leading: const Icon(Icons.block_outlined),
              title: const Text('차단한 사용자'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.blockedUsers),
            ),
            AppListTile(
              leading: const Icon(Icons.logout),
              title: const Text('로그아웃'),
              onTap: () => _confirmSignOut(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 화면 테마를 고른다. 고르는 즉시 적용되고 다이얼로그가 닫힌다.
  ///
  /// 취소 버튼을 두지 않는다 — 바깥을 탭해 닫으면 아무것도 바뀌지 않는다.
  /// 테마 상태의 주인은 앱 루트의 [ThemeCubit] 이므로 여기서 새로 만들지 않고
  /// 읽어 쓰기만 한다 (규칙 ⑥).
  Future<void> _selectThemeMode(BuildContext context) async {
    final cubit = context.read<ThemeCubit>();
    final selected = await showDialog<AppThemeMode>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('화면 테마'),
        content: RadioGroup<AppThemeMode>(
          groupValue: cubit.state,
          onChanged: (value) => Navigator.of(dialogContext).pop(value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in AppThemeMode.values)
                RadioListTile<AppThemeMode>(
                  value: mode,
                  title: Text(mode.label),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;
    await cubit.setMode(selected);
  }

  /// 로그아웃은 되돌릴 수 없으니 한 번 묻는다.
  ///
  /// 실제 세션 정리와 로그인 화면 복귀는 [AuthBloc] 과 라우터 redirect 가 한다.
  /// 이 화면은 로그인 화면으로 직접 이동하지 않는다.
  Future<void> _confirmSignOut(BuildContext context) async {
    final authBloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('로그아웃할까요?'),
        content: const Text('다시 사용하려면 로그인해야 합니다.'),
        actions: [
          AppButton.text(
            label: '취소',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppButton.text(
            label: '로그아웃',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    authBloc.add(const AuthEvent.signOutRequested());
  }
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          AppAvatar(
            nickname: user.nickname,
            imageUrl: user.avatarUrl,
            radius: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.nickname, style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  user.email,
                  style: textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
