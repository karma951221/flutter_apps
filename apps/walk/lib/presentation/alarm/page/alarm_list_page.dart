import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../../../domain/alarm/entity/repeat_preset.dart';
import '../cubit/alarm_list_cubit.dart';
import '../cubit/alarm_list_state.dart';
import '../format/alarm_format.dart';
import '../widget/alarm_kind_sheet.dart';
import '../widget/alarm_pause_banner.dart';
import '../widget/alarm_pause_sheet.dart';
import '../widget/alarm_permission_banner.dart';
import '../widget/alarm_menu_sheet.dart';
import '../widget/alarm_summary_card.dart';
import '../widget/alarm_tile.dart';
import 'alarm_edit_page.dart';
import 'alarm_history_page.dart';

/// 알람 탭. [AlarmListCubit] 은 셸이 제공한다.
///
/// 스낵바("N시간 M분 뒤에 울려요")는 이 탭의 `Scaffold` 에 띄운다 — 탭 `Scaffold` 가
/// 셸 `Scaffold` 안에 중첩돼 있어, 앱 전체 메신저로 띄우면 셸 쪽에 떠서 FAB 를 가린다.
class AlarmListPage extends StatefulWidget {
  const AlarmListPage({required this.onOpenSettings, super.key});

  /// 권한 경고를 눌렀을 때 — 설정 탭으로.
  final VoidCallback onOpenSettings;

  @override
  State<AlarmListPage> createState() => _AlarmListPageState();
}

class _AlarmListPageState extends State<AlarmListPage> {
  final _clock = getIt<Clock>();

  /// 남은 시간을 매분 0초에 새로 센다 — 다음 분 0초까지 [_align], 그 뒤 1분마다 [_ticker].
  Timer? _align;
  Timer? _ticker;

  /// 다른 탭에 가려져 있으면(IndexedStack 이 `TickerMode` 를 끈다) false.
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    final now = _clock.now();
    final nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    _align = Timer(nextMinute.difference(now), () {
      _tick();
      _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _visible) return;
    _visible = visible;
    // 가려진 동안 건너뛴 분을 탭이 다시 보이는 즉시 따라잡는다.
    if (visible) context.read<AlarmListCubit>().tick();
  }

  void _tick() {
    if (mounted && _visible) context.read<AlarmListCubit>().tick();
  }

  @override
  void dispose() {
    _align?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _open(BuildContext context, Alarm alarm) async {
    final untilRing = await Navigator.of(
      context,
    ).push<Duration>(MaterialPageRoute(builder: (_) => AlarmEditPage(initial: alarm)));
    if (untilRing != null && context.mounted) _showRingsIn(context, untilRing);
  }

  /// 종류 시트에서 고른 종류의 새 알람 편집을 연다. 반복은 평일로 시작한다.
  Future<void> _add(BuildContext context) async {
    final kind = await AlarmKindSheet.show(context);
    if (kind == null || !context.mounted) return;
    final draft = switch (kind) {
      AlarmKind.oneShot => Alarm.draft(),
      AlarmKind.repeating => Alarm.draft().copyWith(repeat: RepeatPreset.weekdays.days),
    };
    await _open(context, draft);
  }

  Future<void> _toggle(BuildContext context, Alarm alarm, bool enabled) async {
    final l10n = AppLocalizations.of(context);
    try {
      final untilRing = await context.read<AlarmListCubit>().toggle(alarm, enabled: enabled);
      if (untilRing != null && context.mounted) _showRingsIn(context, untilRing);
    } on Object {
      if (!context.mounted) return;
      AppSnackBar.show(context, message: l10n.walkAlarmSaveFailed, type: AppSnackBarType.error);
    }
  }

  /// 알람 행 길게 누르기 · "공휴일" 칩 — 알람 메뉴(복제 · 건너뛰기 · 삭제).
  Future<void> _menu(BuildContext context, Alarm alarm) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<AlarmListCubit>();
    final pause = switch (cubit.state) {
      AlarmListLoaded(:final pause) => pause,
      _ => null,
    };
    final action = await AlarmMenuSheet.show(
      context,
      alarm: alarm,
      now: _clock.now(),
      pause: pause,
    );
    if (action == null || !context.mounted) return;
    try {
      switch (action) {
        case AlarmMenuAction.duplicate:
          // 저장 전 알람으로 편집을 연다 — 저장해야 생긴다(같은 시각에 두 번 울리지 않게).
          await _open(context, alarm.duplicate());
        case AlarmMenuAction.skip:
          await cubit.skipNext(alarm.id);
        case AlarmMenuAction.unskip:
          await cubit.unskip(alarm.id);
        case AlarmMenuAction.delete:
          final confirmed = await AppConfirmDialog.show(
            context,
            title: l10n.walkAlarmDeleteTitle,
            content: l10n.walkAlarmDeleteContent,
            confirmLabel: l10n.commonDelete,
          );
          if (confirmed) await cubit.delete(alarm.id);
      }
    } on Object {
      if (!context.mounted) return;
      AppSnackBar.show(context, message: l10n.walkAlarmSaveFailed, type: AppSnackBarType.error);
    }
  }

  /// 앱바 [알람 쉬기] — 기간을 고르면 모든 알람을 그 기간 쉰다.
  Future<void> _pause(BuildContext context) async {
    final cubit = context.read<AlarmListCubit>();
    final pause = await AlarmPauseSheet.show(context, now: _clock.now());
    if (pause == null || !context.mounted) return;
    await _savePause(context, () => cubit.setPause(pause));
  }

  /// 쉬기 저장 · 그만 쉬기. 실패하면 오류 스낵바.
  Future<void> _savePause(BuildContext context, Future<void> Function() change) async {
    final l10n = AppLocalizations.of(context);
    try {
      await change();
    } on Object {
      if (!context.mounted) return;
      AppSnackBar.show(context, message: l10n.walkAlarmSaveFailed, type: AppSnackBarType.error);
    }
  }

  void _showRingsIn(BuildContext context, Duration untilRing) {
    final l10n = AppLocalizations.of(context);
    AppSnackBar.show(
      context,
      message: l10n.walkAlarmRingsIn(AlarmFormat.duration(l10n, untilRing)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ScaffoldMessenger(
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(l10n.walkAlarmListTitle),
            actions: [
              IconButton(
                tooltip: l10n.walkAlarmPause,
                icon: const Icon(Icons.bedtime_outlined),
                onPressed: () => _pause(context),
              ),
              IconButton(
                tooltip: l10n.walkAlarmHistory,
                icon: const Icon(Icons.history),
                onPressed: () => Navigator.of(
                  context,
                ).push<void>(MaterialPageRoute(builder: (_) => const AlarmHistoryPage())),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: l10n.walkAlarmAdd,
            onPressed: () => _add(context),
            child: const Icon(Icons.add),
          ),
          body: BlocBuilder<AlarmListCubit, AlarmListState>(
            builder: (context, state) => switch (state) {
              AlarmListLoading() => const Center(child: CircularProgressIndicator()),
              AlarmListFailure() => Center(
                child: AppPlaceholder(
                  icon: Icons.error_outline,
                  message: l10n.walkAlarmLoadFailed,
                  actionLabel: l10n.commonRetry,
                  onAction: context.read<AlarmListCubit>().load,
                ),
              ),
              AlarmListLoaded(
                :final alarms,
                :final nextAt,
                :final now,
                :final canRing,
                :final holidays,
                :final pause,
              ) =>
                ListView(
                  // FAB 가 마지막 행의 스위치를 가리지 않게.
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl * 2.5),
                  children: [
                    if (!canRing)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          0,
                        ),
                        child: AlarmPermissionBanner(onTap: widget.onOpenSettings),
                      ),
                    if (pause != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          0,
                        ),
                        child: AlarmPauseBanner(
                          pause: pause,
                          now: now,
                          onStop: () => _savePause(
                            context,
                            () => context.read<AlarmListCubit>().setPause(null),
                          ),
                        ),
                      ),
                    // 알람이 하나도 없으면 카드 대신 아래 빈 상태만.
                    if (alarms.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: AlarmSummaryCard(alarms: alarms, nextAt: nextAt, now: now),
                      ),
                    if (alarms.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xl),
                        child: AppPlaceholder(
                          icon: Icons.alarm_add,
                          message: l10n.walkAlarmEmpty,
                          description: l10n.walkAlarmEmptyDescription,
                        ),
                      )
                    else
                      for (final alarm in alarms)
                        Padding(
                          key: ValueKey(alarm.id),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            0,
                          ),
                          child: AlarmTile(
                            alarm: alarm,
                            untilRing: nextAt[alarm.id]?.difference(now),
                            onTap: () => _open(context, alarm),
                            onToggle: (enabled) => _toggle(context, alarm, enabled),
                            onLongPress: () => _menu(context, alarm),
                            holidayName: holidays[alarm.id],
                            onHolidayTap: () => _menu(context, alarm),
                          ),
                        ),
                  ],
                ),
            },
          ),
        ),
      ),
    );
  }
}
