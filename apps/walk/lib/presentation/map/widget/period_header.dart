import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart' hide DayPeriod;
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/location/entity/map_period.dart';
import '../../diary/widget/story_avatar.dart';

/// 지도 기간의 종류 — 상단 세그먼트 순서.
enum MapPeriodKind { day, month, story }

MapPeriodKind mapPeriodKind(MapPeriod period) => switch (period) {
  DayPeriod() => MapPeriodKind.day,
  MonthPeriod() => MapPeriodKind.month,
  StoryPeriod() => MapPeriodKind.story,
};

/// 기간 이름 — 머리 가운데 · 스토리 뷰어 제목.
String mapPeriodLabel(AppLocalizations l10n, MapPeriod period) =>
    switch (period) {
      DayPeriod(:final date) => DateFormat.MMMEd(l10n.localeName).format(date),
      MonthPeriod(:final year, :final month) => DateFormat.yMMMM(
        l10n.localeName,
      ).format(DateTime(year, month)),
      StoryPeriod(:final story) => storyDisplayTitle(l10n, story),
    };

/// 상단 세그먼트 [오늘 · 한 달 · 스토리]. 이미 고른 칸을 다시 눌러도 알리지 않는다.
class PeriodSegment extends StatelessWidget {
  const PeriodSegment({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final MapPeriodKind selected;
  final ValueChanged<MapPeriodKind> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<MapPeriodKind>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: MapPeriodKind.day,
          label: Text(l10n.walkMapSegmentDay),
        ),
        ButtonSegment(
          value: MapPeriodKind.month,
          label: Text(l10n.walkMapSegmentMonth),
        ),
        ButtonSegment(
          value: MapPeriodKind.story,
          label: Text(l10n.walkMapSegmentStory),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (values) => onSelected(values.single),
    );
  }
}

/// ‹ 기간 › — 하루 · 한 달은 한 칸씩 넘기고 미래로는 못 간다. 스토리는 제목을 누르면
/// 다시 고른다([onPickStory]).
class PeriodHeader extends StatelessWidget {
  const PeriodHeader({
    required this.period,
    required this.now,
    required this.onChanged,
    required this.onPickStory,
    super.key,
  });

  final MapPeriod period;
  final DateTime now;
  final ValueChanged<MapPeriod> onChanged;
  final VoidCallback onPickStory;

  /// 이전 · 다음 기간. 다음이 미래면 null.
  static ({MapPeriod? previous, MapPeriod? next}) neighbors(
    MapPeriod period,
    DateTime now,
  ) => switch (period) {
    DayPeriod(:final date) => (
      previous: MapPeriod.day(DateTime(date.year, date.month, date.day - 1)),
      next:
          DateTime(
            date.year,
            date.month,
            date.day,
          ).isBefore(DateTime(now.year, now.month, now.day))
          ? MapPeriod.day(DateTime(date.year, date.month, date.day + 1))
          : null,
    ),
    MonthPeriod(:final year, :final month) => (
      previous: _month(DateTime(year, month - 1)),
      next: DateTime(year, month).isBefore(DateTime(now.year, now.month))
          ? _month(DateTime(year, month + 1))
          : null,
    ),
    StoryPeriod() => (previous: null, next: null),
  };

  static MapPeriod _month(DateTime d) => MapPeriod.month(d.year, d.month);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = mapPeriodLabel(l10n, period);
    if (period is StoryPeriod) {
      return Center(
        child: AppButton.text(label: label, onPressed: onPickStory),
      );
    }
    final (:previous, :next) = neighbors(period, now);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            key: const Key('map-period-previous'),
            icon: const Icon(Icons.chevron_left),
            tooltip: l10n.walkMapPrevious,
            onPressed: previous == null ? null : () => onChanged(previous),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            key: const Key('map-period-next'),
            icon: const Icon(Icons.chevron_right),
            tooltip: l10n.walkMapNext,
            onPressed: next == null ? null : () => onChanged(next),
          ),
        ],
      ),
    );
  }
}
