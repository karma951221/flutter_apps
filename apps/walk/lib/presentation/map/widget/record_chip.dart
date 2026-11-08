import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../data/location/background_location_access.dart';
import '../../../domain/location/entity/record_mode.dart';
import '../../../domain/location/recorder/recorder_status.dart';
import '../cubit/map_record_cubit.dart';
import '../cubit/map_record_state.dart';

/// 권한 흐름을 거쳐 위치 기록을 켠다. "항상 허용"을 대화상자로 못 받았으면 설정으로 보내는
/// 스낵바, 거부했으면 오류 스낵바를 띄운다. 지도 탭(칩 · 처음 안내)과 지도 설정이 함께 쓴다.
Future<void> enableLocationRecord(
  BuildContext context,
  MapRecordCubit cubit,
) async {
  final l10n = AppLocalizations.of(context);
  await cubit.enable();
  if (!context.mounted) return;
  switch (cubit.state.access) {
    case AlwaysAccess.needsSettings:
      AppSnackBar.show(
        context,
        message: l10n.walkMapSettingsNeedsAlways,
        actionLabel: l10n.walkMapSettingsOpenSettings,
        onAction: cubit.openAppSettings,
      );
    case AlwaysAccess.denied:
      AppSnackBar.show(
        context,
        message: l10n.walkMapSettingsDenied,
        type: AppSnackBarType.error,
      );
    case AlwaysAccess.granted || null:
      break;
  }
}

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
