import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/ring_log_entry.dart';
import '../../../domain/alarm/ring_log.dart';
import '../../../domain/alarm/ring_log/ring_log_source.dart';
import '../../../domain/alarm/usecase/alarm_use_case.dart';
import '../cubit/alarm_history_cubit.dart';
import '../cubit/alarm_history_state.dart';
import '../format/alarm_format.dart';

/// 울림 기록(웨이브 4 스펙 C4). 최근 30일 회차를 날짜별로, 한 회차를
/// "오전 7:00 · 출근 / 오전 7:00 울림 · 스누즈 2번 · 오전 7:12 끔" 한 줄로 보인다.
class AlarmHistoryPage extends StatefulWidget {
  const AlarmHistoryPage({super.key});

  @override
  State<AlarmHistoryPage> createState() => _AlarmHistoryPageState();
}

class _AlarmHistoryPageState extends State<AlarmHistoryPage> {
  late final _cubit = AlarmHistoryCubit(
    getIt<RingLogSource>(),
    getIt<AlarmUseCase>(),
    getIt<Clock>(),
  )..load();

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkAlarmHistory)),
      body: BlocBuilder<AlarmHistoryCubit, AlarmHistoryState>(
        bloc: _cubit,
        builder: (context, state) => switch (state) {
          AlarmHistoryLoading() => const Center(child: CircularProgressIndicator()),
          AlarmHistoryFailure() => Center(
            child: AppPlaceholder(
              icon: Icons.error_outline,
              message: l10n.walkAlarmHistoryLoadFailed,
              actionLabel: l10n.commonRetry,
              onAction: _cubit.load,
            ),
          ),
          AlarmHistoryLoaded(:final groups) when groups.isEmpty => Center(
            child: AppPlaceholder(
              icon: Icons.history,
              message: l10n.walkAlarmHistoryEmpty,
              description: l10n.walkAlarmHistoryEmptyHint,
            ),
          ),
          AlarmHistoryLoaded(:final groups, :final now) => ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: [
              for (final (index, group) in groups.indexed) ...[
                if (index == 0 || !_sameDay(groups[index - 1].at, group.at))
                  _DayHeader(AlarmFormat.day(l10n, group.at, now)),
                _GroupRow(group),
              ],
            ],
          ),
        },
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayHeader extends StatelessWidget {
  const _DayHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }
}

/// 회차 한 줄 — 제목 "시각 · 라벨"(지운 알람이면 "지운 알람"), 부제 울림 요약.
class _GroupRow extends StatelessWidget {
  const _GroupRow(this.group);

  final RingLogGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String time(DateTime at) => AlarmFormat.time(context, at.hour, at.minute);
    final alarm = group.alarm;
    final label = alarm == null ? l10n.walkAlarmHistoryDeleted : alarm.label;
    final title = [time(group.at), if (label.isNotEmpty) label].join(' · ');
    final rangAt = group.rangAt;
    final endedAt = group.endedAt;
    final summary = group.skipped
        ? l10n.walkAlarmSkipped
        : [
            if (rangAt != null) l10n.walkAlarmHistoryRang(time(rangAt)),
            if (group.snoozes > 0) l10n.walkAlarmHistorySnoozes(group.snoozes),
            if (endedAt != null)
              switch (group.end) {
                RingLogKind.autoStopped => l10n.walkAlarmHistoryAutoStopped(time(endedAt)),
                _ => l10n.walkAlarmHistoryStopped(time(endedAt)),
              },
          ].join(' · ');
    return AppListTile(
      leading: Icon(group.skipped ? Icons.event_busy_outlined : Icons.alarm),
      title: Text(title),
      subtitle: Text(summary),
    );
  }
}
