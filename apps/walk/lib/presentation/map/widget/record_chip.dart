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

/// 지도 위 기록 표시 — 지도 종류 버튼 아래에 쌓인다.
///
/// 기록 중이면 지도를 덜 가리도록 원형 아이콘 버튼 하나로 접는다. 평소 기록은 옅은 버튼 +
/// 위치 아이콘, 자세히 기록([RecordMode.dense], 5초마다)은 진한 버튼 + 경로 아이콘이다.
/// 누르면 자세히 기록 스위치가 든 시트([showRecordSheet])를 연다.
///
/// 꺼져 있으면 "기록 꺼짐", 권한을 잃었으면 "권한 필요" 칩 — 사용자가 켜야 하는 상태라 글자를
/// 보이고, 둘 다 누르면 켜기 흐름이다.
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
      RecorderRunning(mode: RecordMode.dense) => IconButton.filled(
        key: const Key('map-record-chip'),
        tooltip: l10n.walkMapRecordOnDense,
        icon: const Icon(Icons.route),
        onPressed: () => unawaited(showRecordSheet(context)),
      ),
      RecorderRunning() => IconButton.filledTonal(
        key: const Key('map-record-chip'),
        tooltip: l10n.walkMapRecordOn,
        icon: const Icon(Icons.my_location),
        onPressed: () => unawaited(showRecordSheet(context)),
      ),
      RecorderBlocked() => _ActionChip(
        icon: Icons.location_disabled_outlined,
        label: l10n.walkMapChipBlocked,
        tooltip: l10n.walkMapChipBlockedTooltip,
        onPressed: busy ? null : enable,
      ),
      RecorderOff() => _ActionChip(
        icon: Icons.location_off_outlined,
        label: l10n.walkMapChipOff,
        onPressed: busy ? null : enable,
      ),
    };
  }
}

/// 꺼짐 · 권한 필요 칩 — 촘촘한 크기로 지도를 덜 가린다.
class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ActionChip.elevated(
    key: const Key('map-record-chip'),
    visualDensity: VisualDensity.compact,
    avatar: Icon(icon),
    label: Text(label),
    tooltip: tooltip,
    onPressed: onPressed,
  );
}

/// 기록 중일 때 여는 시트 — 제목과 자세히 기록 스위치. 시트가 떠 있는 동안 바뀐 상태를 따른다.
Future<void> showRecordSheet(BuildContext context) {
  final cubit = context.read<MapRecordCubit>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _RecordSheet()),
  );
}

class _RecordSheet extends StatelessWidget {
  const _RecordSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cubit = context.read<MapRecordCubit>();
    final state = context.watch<MapRecordCubit>().state;
    final dense = switch (state.status) {
      RecorderRunning(:final mode) ||
      RecorderBlocked(:final mode) => mode == RecordMode.dense,
      RecorderOff() => false,
    };
    final enabled = state.status is RecorderRunning && !state.busy;
    void set(bool value) => unawaited(cubit.setDense(value));
    return SafeArea(
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
              l10n.walkMapRecordOn,
              style: theme.textTheme.titleMedium,
            ),
          ),
          AppListTile(
            key: const Key('map-record-dense'),
            leading: Icon(
              Icons.route_outlined,
              color: dense ? theme.colorScheme.primary : null,
            ),
            title: Text(l10n.walkMapChipDense),
            subtitle: Text(l10n.walkMapRecordDenseHint),
            enabled: enabled,
            trailing: Switch(
              key: const Key('map-record-dense-switch'),
              value: dense,
              onChanged: enabled ? set : null,
            ),
            onTap: enabled ? () => set(!dense) : null,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
