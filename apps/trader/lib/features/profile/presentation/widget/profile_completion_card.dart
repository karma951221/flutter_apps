import 'package:flutter/material.dart';

import 'package:design_system/design_system.dart';
import 'package:l10n/l10n.dart';
import '../../domain/entity/profile.dart';

/// 내 프로필 상단의 완성도 카드.
///
/// 닉네임은 가입 때 이미 정했으므로 언제나 첫 칸이 채워진 채로 시작한다 —
/// 0% 에서 시작하는 진행률은 동기가 되지 않는다 (목표 구배,
/// ux-psychology-review.md 1번). 근거 없는 칸은 채우지 않는다: 다섯 항목
/// 모두 앱이 이미 아는 값으로 판정한다.
///
/// 목록에는 **남은 항목만** 그린다. 끝난 일은 진행바와 퍼센트가 이미 말하고
/// 있으므로 줄을 하나 더 쓸 이유가 없고, 다섯 줄을 전부 세우면 정작 이 화면의
/// 주인공인 내 게시물이 첫 화면에서 밀려난다. 남은 줄만 보이면 카드는
/// 진행할수록 짧아지고, 목록은 "다음에 할 일" 하나로 읽힌다.
///
/// 다섯 항목이 전부 끝나면 아무것도 그리지 않는다.
class ProfileCompletionCard extends StatelessWidget {
  const ProfileCompletionCard({
    required this.profile,
    required this.hasPost,
    required this.onEditProfile,
    required this.onWritePost,
    super.key,
  });

  final Profile profile;

  /// 게시물 목록 첫 페이지가 비어 있지 않은가. 목록을 소유한 화면이 준다.
  final bool hasPost;

  final VoidCallback onEditProfile;
  final VoidCallback onWritePost;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = <_CompletionStep>[
      _CompletionStep(label: l10n.profileCompletionNickname, isDone: true),
      _CompletionStep(
        label: l10n.profileCompletionAvatar,
        isDone: profile.avatarUrl != null,
        onTap: onEditProfile,
      ),
      _CompletionStep(
        label: l10n.profileCompletionBio,
        isDone: profile.bio?.trim().isNotEmpty ?? false,
        onTap: onEditProfile,
      ),
      _CompletionStep(
        label: l10n.profileCompletionFirstPost,
        isDone: hasPost,
        onTap: onWritePost,
      ),
      _CompletionStep(
        label: l10n.profileCompletionFirstFollow,
        isDone: profile.followingCount > 0,
      ),
    ];
    final done = steps.where((step) => step.isDone).length;
    if (done == steps.length) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progress = done / steps.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: AppRadius.lgAll,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileCompletionTitle((progress * 100).round()),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    LinearProgressIndicator(value: progress),
                  ],
                ),
              ),
              for (final step in steps.where((step) => !step.isDone))
                AppListTile(
                  leading: Icon(
                    Icons.radio_button_unchecked,
                    color: scheme.outline,
                  ),
                  title: Text(step.label),
                  trailing: step.onTap == null
                      ? null
                      : const Icon(Icons.chevron_right),
                  onTap: step.onTap,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionStep {
  const _CompletionStep({
    required this.label,
    required this.isDone,
    this.onTap,
  });

  final String label;
  final bool isDone;

  /// 없으면 이 화면에서 할 수 있는 일이 아니다 (팔로우는 홈 피드에서 한다).
  final VoidCallback? onTap;
}
