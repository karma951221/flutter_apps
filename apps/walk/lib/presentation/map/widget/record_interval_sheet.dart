import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/location/entity/record_interval.dart';
import '../../../domain/location/recorder/recorder_status.dart';
import '../cubit/map_record_cubit.dart';

/// 주기 이름 — "평소" · "5초마다" · "1분마다".
String recordIntervalLabel(AppLocalizations l10n, RecordInterval interval) =>
    switch (interval.seconds) {
      null => l10n.walkRecordIntervalNormal,
      final s when s % 60 == 0 => l10n.walkRecordIntervalMinutes(s ~/ 60),
      final s => l10n.walkRecordIntervalSeconds(s),
    };

String _detail(AppLocalizations l10n, RecordInterval interval) =>
    switch (interval.seconds) {
      null => l10n.walkRecordIntervalNormalDetail,
      final s when s <= RecordInterval.detailedMaxSeconds =>
        l10n.walkRecordIntervalShortDetail,
      _ => l10n.walkRecordIntervalLongDetail,
    };

/// 기록 주기를 고르는 시트 — 지도의 기록 버튼과 지도 설정의 기록 주기 행이 연다. 고르면
/// [MapRecordCubit.setInterval] 을 부르고 닫는다. 떠 있는 동안 바뀐 상태를 따르고, 기록이 꺼져
/// 있거나 바꾸는 중이면 고를 수 없다.
Future<void> showRecordIntervalSheet(BuildContext context) {
  final cubit = context.read<MapRecordCubit>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _RecordIntervalSheet()),
  );
}

class _RecordIntervalSheet extends StatelessWidget {
  const _RecordIntervalSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cubit = context.read<MapRecordCubit>();
    final state = context.watch<MapRecordCubit>().state;
    final current = recordIntervalOf(state.status);
    final enabled = current != null && !state.busy;
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Text(
                l10n.walkRecordInterval,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.walkRecordIntervalHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final interval in RecordInterval.values)
              AppListTile(
                key: Key('record-interval-${interval.name}'),
                title: Text(recordIntervalLabel(l10n, interval)),
                subtitle: Text(_detail(l10n, interval)),
                enabled: enabled,
                trailing: interval == current
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : null,
                onTap: enabled
                    ? () {
                        if (interval != current) {
                          unawaited(cubit.setInterval(interval));
                        }
                        Navigator.pop(context);
                      }
                    : null,
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
