import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// 스토리 바의 한 칸: 원(이니셜 또는 [icon]) + 아래 이름. 고른 칸은 테두리로 표시한다.
///
/// `AppAvatar` 는 '프로필 사진' 으로 읽히고 아이콘 칸(전체 · 보관함)을 그리지 못해 따로 둔다.
class StoryAvatar extends StatelessWidget {
  const StoryAvatar({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// 있으면 이니셜 대신 그린다.
  final IconData? icon;

  /// 원 반지름 · 칸 너비. 시각 토큰이 아니라 이 위젯의 크기다.
  static const _radius = 28.0;
  static const _width = 72.0;
  static const _ring = 2.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.characters.first;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: SizedBox(
          width: _width,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? colors.primary
                          : colors.primary.withValues(alpha: 0),
                      width: _ring,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(_ring),
                    child: CircleAvatar(
                      radius: _radius,
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.onPrimaryContainer,
                      child: icon == null
                          ? Text(initial, style: theme.textTheme.titleMedium)
                          : Icon(icon),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected ? colors.primary : null,
                    fontWeight: selected ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
