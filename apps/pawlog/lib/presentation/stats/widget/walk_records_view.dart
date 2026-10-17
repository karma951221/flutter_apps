import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/stats/entity/walk_records.dart';
import '../../../domain/walk/entity/walk.dart';
import '../../theme/pawlog_theme.dart';
import '../../walk/format/walk_format.dart';

/// 전체 기간의 기록 — 카드 없이 `rule` 선으로 나눈 줄글. 산책 두 줄은 탭하면 상세로 간다.
class WalkRecordsView extends StatelessWidget {
  const WalkRecordsView({
    required this.records,
    required this.onOpenWalk,
    super.key,
  });

  final WalkRecords records;
  final ValueChanged<String> onOpenWalk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final farthest = records.farthest;
    final longest = records.longest;
    String date(Walk walk) =>
        DateFormat.yMMMd(l10n.localeName).format(walk.startedAt.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.walkStatsRecordsTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: PawlogSpacing.sm),
        _RecordRow(
          key: const Key('stats-record-current-streak'),
          label: l10n.walkStatsCurrentStreak,
          value: l10n.walkStatsDays(records.currentStreakDays),
        ),
        _RecordRow(
          key: const Key('stats-record-longest-streak'),
          label: l10n.walkStatsLongestStreak,
          value: l10n.walkStatsDays(records.longestStreakDays),
        ),
        // 거리 없는 산책뿐이면 '가장 먼 산책 0 m' 는 의미가 없다.
        if (farthest != null && farthest.distanceMeters >= 1)
          _RecordRow(
            key: const Key('stats-record-farthest'),
            label: l10n.walkStatsFarthestWalk,
            detail: date(farthest),
            value: WalkFormat.distance(l10n, farthest.distanceMeters),
            onTap: () => onOpenWalk(farthest.id),
          ),
        if (longest != null)
          _RecordRow(
            key: const Key('stats-record-longest'),
            label: l10n.walkStatsLongestWalk,
            detail: date(longest),
            value: WalkFormat.duration(l10n, longest.duration),
            onTap: () => onOpenWalk(longest.id),
          ),
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.label,
    required this.value,
    this.detail,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final String? detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = PawlogColors.of(context);
    final styles = PawlogTextStyles.of(context);
    final theme = Theme.of(context);
    final detail = this.detail;

    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.rule)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: PawlogSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                    if (detail != null)
                      Text(detail, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Text(value, style: styles.number),
              // 화살표 없는 줄도 같은 폭을 비워 값 열의 오른쪽 끝을 맞춘다.
              Visibility(
                visible: onTap != null,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Icon(Icons.chevron_right, color: colors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
