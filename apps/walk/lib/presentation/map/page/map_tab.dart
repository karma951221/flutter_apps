import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart' hide DayPeriod;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:latlong2/latlong.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/location/entity/day_track.dart';
import '../../../domain/location/entity/map_period.dart';
import '../../../domain/location/recorder/recorder_status.dart';
import '../../diary/viewer/story_viewer_page.dart';
import '../../lock/widget/diary_lock_gate.dart';
import '../cubit/map_record_cubit.dart';
import '../cubit/map_record_state.dart';
import '../cubit/map_view_cubit.dart';
import '../cubit/map_view_state.dart';
import '../widget/frequent_sheet.dart';
import '../widget/period_header.dart';
import '../widget/enable_location_record.dart';
import '../widget/record_chip.dart';
import '../widget/story_picker_sheet.dart';
import '../widget/timeline_sheet.dart';
import '../widget/track_map.dart';

/// 도구 › 지도. 오늘 · 한 달 · 스토리 기간의 동선과 일기 핀.
///
/// 일기 잠금 아래다 — 잠긴 동안 지도 · 칩 · 시트는 트리에 없고, 다시 잠기면 이 탭에서 띄운
/// 팝업(스토리 고르기 · ⋮)을 닫는다. 가려진 탭([active] 거짓)이면 팝업은 다른 탭의 것이라 두고 간다.
///
/// 셸의 [MapRecordCubit] · [MapViewCubit] 아래에 둔다. 열릴 때(잠금이 풀려 처음 그려질 때 ·
/// 탭이 다시 보일 때) 기록 상태를 읽고 inbox 를 수거해 다시 읽는다. 앱이 앞에 올 때는 셸이 한다.
/// 기록이 꺼짐 · 막힘에서 켜짐으로 바뀌면(칩 · 처음 안내 · 설정에서 켬) 지도도 다시 읽는다.
class MapTab extends StatelessWidget {
  const MapTab({required this.active, super.key});

  /// 하단 탭이 도구이고 상단 탭이 지도다. 위에 얹힌 화면(시트 · 메뉴 · 설정)과는 무관하다 —
  /// 이 탭에서 띄운 팝업도 셸에는 "얹힌 화면"이라, 그것까지 섞으면 다시 잠길 때 팝업을 닫지
  /// 못한다(일기 · 물어보기 탭과 같은 규칙). 앱 복귀 때 다시 읽기는 셸이 가려졌는지까지 본다.
  final bool active;

  @override
  Widget build(BuildContext context) => DiaryLockGate(
    dismissPopups: active,
    child: _MapBody(active: active),
  );
}

MapPeriod _periodOf(MapViewState state) => switch (state) {
  MapViewLoading(:final period) ||
  MapViewEmpty(:final period) ||
  MapViewFailure(:final period) => period,
  MapViewReady(:final data) => data.period,
};

class _MapBody extends StatefulWidget {
  const _MapBody({required this.active});

  final bool active;

  @override
  State<_MapBody> createState() => _MapBodyState();
}

class _MapBodyState extends State<_MapBody> {
  final _map = GlobalKey<TrackMapState>();

  @override
  void initState() {
    super.initState();
    // 빌드 중에 cubit 이 상태를 내면 위의 BlocBuilder 가 빌드 중 setState 를 한다 — 프레임 뒤에.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final view = context.read<MapViewCubit>();
      unawaited(context.read<MapRecordCubit>().load());
      // 처음이면 지금 기간을 읽고, 이미 읽은 적이 있으면(다시 잠겼다 풀림) 수거 뒤 다시 읽는다.
      // cubit 의 첫 상태는 시각이 붙은 하루다 — 날짜만 남겨 세그먼트 · 머리가 만드는 기간과 같게 한다.
      final state = view.state;
      unawaited(switch (state) {
        MapViewLoading(period: DayPeriod(:final date)) => view.show(
          MapPeriod.day(DateTime(date.year, date.month, date.day)),
        ),
        MapViewLoading(:final period) => view.show(period),
        _ => view.refresh(),
      });
    });
  }

  @override
  void didUpdateWidget(_MapBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      unawaited(context.read<MapRecordCubit>().load());
      unawaited(context.read<MapViewCubit>().refresh());
    }
  }

  DateTime get _now => getIt<Clock>().now();

  Future<void> _selectKind(MapPeriodKind kind) async {
    final view = context.read<MapViewCubit>();
    final now = _now;
    switch (kind) {
      case MapPeriodKind.day:
        await view.show(MapPeriod.day(DateTime(now.year, now.month, now.day)));
      case MapPeriodKind.month:
        await view.show(MapPeriod.month(now.year, now.month));
      case MapPeriodKind.story:
        await _pickStory();
    }
  }

  Future<void> _pickStory() async {
    final view = context.read<MapViewCubit>();
    final story = await showStoryPicker(context);
    if (story == null || !mounted) return;
    await view.show(MapPeriod.story(story));
  }

  void _openEntry(MapViewData data, DiaryEntry entry) {
    final ids = [
      for (final e in [
        ...data.entries,
      ]..sort((a, b) => a.occurredAt.compareTo(b.occurredAt)))
        e.id,
    ];
    final title = mapPeriodLabel(AppLocalizations.of(context), data.period);
    unawaited(
      openStoryViewer(
        context,
        ViewerSource.entries(ids, title),
        entryId: entry.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = context.watch<MapViewCubit>().state;
    final record = context.watch<MapRecordCubit>().state;
    final period = _periodOf(view);
    return BlocListener<MapRecordCubit, MapRecordState>(
      // 첫 load 는 지도가 열리며 이미 읽는 중이라 건너뛴다.
      listenWhen: (previous, current) =>
          previous.loaded &&
          previous.status is! RecorderRunning &&
          current.status is RecorderRunning,
      listener: (context, _) =>
          unawaited(context.read<MapViewCubit>().refresh()),
      child: _layout(view, record, period),
    );
  }

  Widget _layout(MapViewState view, MapRecordState record, MapPeriod period) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: PeriodSegment(
            selected: mapPeriodKind(period),
            onSelected: (kind) => unawaited(_selectKind(kind)),
          ),
        ),
        PeriodHeader(
          period: period,
          now: _now,
          onChanged: (next) =>
              unawaited(context.read<MapViewCubit>().show(next)),
          onPickStory: () => unawaited(_pickStory()),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) =>
                _content(view, record, period, constraints.maxHeight),
          ),
        ),
      ],
    );
  }

  Widget _content(
    MapViewState view,
    MapRecordState record,
    MapPeriod period,
    double height,
  ) {
    final l10n = AppLocalizations.of(context);
    final data = switch (view) {
      MapViewReady(:final data) => data,
      _ => null,
    };
    // 처음 안내는 기록이 꺼져 있고 저장된 점이 하나도 없을 때만(읽기 전엔 띄우지 않는다).
    // 꺼져 있어도 예전 점이 있으면 빈 기간 안내 + "기록 꺼짐" 칩이다.
    final firstRun =
        record.hasPoints == false &&
        record.status is RecorderOff &&
        view is MapViewEmpty;
    final month = period is MonthPeriod;
    final spots = switch (data) {
      null => const <LatLng>[],
      _ when month => [for (final f in data.frequent) LatLng(f.lat, f.lng)],
      _ => [for (final s in data.track.stays) LatLng(s.lat, s.lng)],
    };
    final overlay = switch (view) {
      _ when firstRun => AppPlaceholder(
        icon: Icons.map_outlined,
        message: l10n.walkMapFirstRunTitle,
        description: l10n.walkMapFirstRunBody,
        actionLabel: l10n.walkMapEnable,
        onAction: record.busy
            ? null
            : () => unawaited(
                enableLocationRecord(context, context.read<MapRecordCubit>()),
              ),
      ),
      MapViewEmpty(:final period) => AppPlaceholder(
        message: switch (period) {
          DayPeriod() => l10n.walkMapEmptyDay,
          MonthPeriod() => l10n.walkMapEmptyMonth,
          StoryPeriod() => l10n.walkMapEmptyStory,
        },
      ),
      MapViewFailure() => AppPlaceholder(
        icon: Icons.error_outline,
        message: l10n.walkMapLoadFailed,
        actionLabel: l10n.walkMapRetry,
        // 로딩 표시를 보이며 그 기간을 다시 읽는다.
        onAction: () => unawaited(context.read<MapViewCubit>().show(period)),
      ),
      MapViewLoading() || MapViewReady() => null,
    };
    return Stack(
      children: [
        Positioned.fill(
          child: TrackMap(
            key: _map,
            track: data?.track ?? const DayTrack(segments: [], stays: []),
            spots: spots,
            entries: data?.entries ?? const [],
            fitKey: period,
            faint: month,
            bottomInset: data == null ? 0 : height * MapSheet.initialSize,
            onOpenEntry: (entry) {
              if (data != null) _openEntry(data, entry);
            },
          ),
        ),
        if (view is MapViewLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
        if (overlay != null)
          Center(
            child: Card(
              margin: const EdgeInsets.all(AppSpacing.md),
              child: overlay,
            ),
          ),
        if (record.loaded && !firstRun)
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: RecordChip(state: record),
          ),
        if (data != null)
          Positioned.fill(
            child: switch (data.period) {
              MonthPeriod() => FrequentSheet(
                places: data.frequent,
                names: data.stayNames,
                onTap: (p) => _map.currentState?.moveTo(p.lat, p.lng),
              ),
              DayPeriod() || StoryPeriod() => TimelineSheet(
                stays: data.track.stays,
                names: data.stayNames,
                showDate: data.period is StoryPeriod,
                onTap: (s) => _map.currentState?.moveTo(s.lat, s.lng),
              ),
            },
          ),
      ],
    );
  }
}
