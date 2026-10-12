import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_view_mode.dart';

/// [줄글 | 피드 | 릴스] 토글.
///
/// 디자인 시스템에 세그먼트 토글이 없어 Material `SegmentedButton` 을 쓴다(걷기 홈의 기간 토글과 같다).
class ViewModeSwitch extends StatelessWidget {
  const ViewModeSwitch({
    required this.mode,
    required this.onChanged,
    super.key,
  });

  final DiaryViewMode mode;
  final ValueChanged<DiaryViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<DiaryViewMode>(
      showSelectedIcon: false,
      segments: [
        for (final m in DiaryViewMode.values)
          ButtonSegment(
            value: m,
            label: Text(switch (m) {
              DiaryViewMode.prose => l10n.walkDiaryViewProse,
              DiaryViewMode.feed => l10n.walkDiaryViewFeed,
              DiaryViewMode.reels => l10n.walkDiaryViewReels,
            }),
          ),
      ],
      selected: {mode},
      onSelectionChanged: (s) => onChanged(s.single),
    );
  }
}
