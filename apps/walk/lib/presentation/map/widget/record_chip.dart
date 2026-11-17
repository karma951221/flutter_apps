import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/location/entity/record_mode.dart';
import '../../../domain/location/recorder/recorder_status.dart';
import '../cubit/map_record_cubit.dart';
import '../cubit/map_record_state.dart';
import 'enable_location_record.dart';

/// 지도 위에 떠 있는 기록 칩.
///
/// 기록 중이면 "자세히 기록" 스위치(위치를 5초마다 찍는 [RecordMode.dense]) 카드,
/// 꺼져 있으면 "기록 꺼짐", 권한을 잃었으면 "기록 꺼짐 · 권한 필요" 칩 — 둘 다 누르면 켜기 흐름이다.
class RecordChip extends StatelessWidget {
  const RecordChip({required this.state, super.key});

  final MapRecordState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MapRecordCubit>();
    final busy = state.busy;
    void enable() => unawaited(enableLocationRecord(context, cubit));
    return switch (state.status) {
      RecorderRunning(:final mode) => _DenseToggle(
        key: const Key('map-record-chip'),
        dense: mode == RecordMode.dense,
        onChanged: busy ? null : (dense) => unawaited(cubit.setDense(dense)),
      ),
      RecorderBlocked() => ActionChip.elevated(
        key: const Key('map-record-chip'),
        avatar: const Icon(Icons.location_disabled_outlined),
        label: Text(l10n.walkMapChipBlocked),
        onPressed: busy ? null : enable,
      ),
      RecorderOff() => ActionChip.elevated(
        key: const Key('map-record-chip'),
        avatar: const Icon(Icons.location_off_outlined),
        label: Text(l10n.walkMapChipOff),
        onPressed: busy ? null : enable,
      ),
    };
  }
}

/// 지도 위 "자세히 기록" 토글 — 제목 · 한 줄 설명 · 스위치. 행 어디를 눌러도 바뀐다.
class _DenseToggle extends StatelessWidget {
  const _DenseToggle({required this.dense, required this.onChanged, super.key});

  final bool dense;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final onChanged = this.onChanged;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged(!dense),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.md,
            end: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.route_outlined,
                color: dense ? theme.colorScheme.primary : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.walkMapChipDense,
                    style: theme.textTheme.labelLarge,
                  ),
                  Text(
                    l10n.walkMapChipDenseHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.xs),
              Switch(
                key: const Key('map-record-dense-switch'),
                value: dense,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
