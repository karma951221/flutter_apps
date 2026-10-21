import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 기록의 해시태그 칩. 태그가 없으면 아무것도 그리지 않는다. [onTap] 이 있으면 칩을 누를 수 있다.
class EntryTags extends StatelessWidget {
  const EntryTags({required this.tags, this.onTap, super.key});

  final List<String> tags;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final onTap = this.onTap;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final tag in tags)
          if (onTap == null)
            Chip(
              label: Text(l10n.walkDiaryTag(tag)),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          else
            ActionChip(
              label: Text(l10n.walkDiaryTag(tag)),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onPressed: () => onTap(tag),
            ),
      ],
    );
  }
}
