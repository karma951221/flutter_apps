import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/location/entity/record_interval.dart';
import '../../../domain/location/recorder/recorder_status.dart';
import '../cubit/map_record_cubit.dart';
import '../cubit/map_record_state.dart';
import 'enable_location_record.dart';
import 'record_interval_sheet.dart';

/// 지도 위 기록 표시 — 지도 종류 버튼 아래에 쌓인다.
///
/// 기록 중이면 지도를 덜 가리도록 원형 아이콘 버튼 하나로 접는다. 평소 기록은 옅은 버튼 +
/// 기록 중 점 아이콘, 고정 주기 기록(5초 · 10초 · 30초 · 1분)은 진한 버튼 + 타이머 아이콘이다.
/// (위치 조준 아이콘은 지도에서 '내 위치로'로 읽혀 쓰지 않는다.)
/// 누르면 기록 주기 시트([showRecordIntervalSheet])를 연다.
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
    void open() => unawaited(showRecordIntervalSheet(context));
    final status = state.status;
    return switch (status) {
      RecorderRunning() => switch (recordIntervalOf(status)!) {
        RecordInterval.normal => IconButton.filledTonal(
          key: const Key('map-record-chip'),
          tooltip: l10n.walkMapRecordOnInterval(l10n.walkRecordIntervalNormal),
          icon: const Icon(Icons.radio_button_checked),
          onPressed: open,
        ),
        final interval => IconButton.filled(
          key: const Key('map-record-chip'),
          tooltip: l10n.walkMapRecordOnInterval(
            recordIntervalLabel(l10n, interval),
          ),
          icon: const Icon(Icons.timer_outlined),
          onPressed: open,
        ),
      },
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
