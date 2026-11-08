import 'dart:async';

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
/// 기록 중이면 촘촘 기록 토글(켜지면 강조색 + "촘촘 기록 중"), 꺼져 있으면 "기록 꺼짐",
/// 권한을 잃었으면 "기록 꺼짐 · 권한 필요" — 둘 다 누르면 켜기 흐름이다.
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
      RecorderRunning(:final mode) => FilterChip.elevated(
        key: const Key('map-record-chip'),
        selected: mode == RecordMode.dense,
        showCheckmark: false,
        avatar: const Icon(Icons.route_outlined),
        label: Text(
          mode == RecordMode.dense
              ? l10n.walkMapChipDenseOn
              : l10n.walkMapChipDense,
        ),
        onSelected: busy ? null : (dense) => unawaited(cubit.setDense(dense)),
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
