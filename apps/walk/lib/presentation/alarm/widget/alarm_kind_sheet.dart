import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 새 알람의 종류. 저장값이 아니다 — 저장된 알람은 `repeat` 가 비었는지로 가린다.
enum AlarmKind { oneShot, repeating }

/// `+` 를 누르면 뜨는 종류 시트 — 손잡이 · 제목 · [한 번] · [반복] 두 행.
/// 고르면 그 종류를, 그냥 닫으면 null 을 돌려준다.
class AlarmKindSheet extends StatelessWidget {
  const AlarmKindSheet({super.key});

  static Future<AlarmKind?> show(BuildContext context) => showModalBottomSheet<AlarmKind>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const AlarmKindSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(l10n.walkAlarmKindTitle, style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: AppSpacing.md),
            _KindRow(
              icon: Icons.hourglass_bottom,
              title: l10n.walkAlarmKindOneShot,
              description: l10n.walkAlarmKindOneShotHint,
              onTap: () => Navigator.of(context).pop(AlarmKind.oneShot),
            ),
            const SizedBox(height: AppSpacing.sm),
            _KindRow(
              icon: Icons.repeat,
              title: l10n.walkAlarmKindRepeat,
              description: l10n.walkAlarmKindRepeatHint,
              onTap: () => Navigator.of(context).pop(AlarmKind.repeating),
            ),
          ],
        ),
      ),
    );
  }
}

/// 둥근 카드 안의 한 행 — 아이콘 원 · 제목 · 한 줄 설명. 목록 행과 같은 둥근 카드 모양이라
/// `AppListTile` 을 그 안에 둔다.
class _KindRow extends StatelessWidget {
  const _KindRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: AppListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(description),
        onTap: onTap,
      ),
    );
  }
}
