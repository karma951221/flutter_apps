import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../cubit/alarm_list_cubit.dart';
import '../cubit/alarm_list_state.dart';
import '../format/alarm_format.dart';
import '../widget/alarm_permission_banner.dart';
import '../widget/alarm_tile.dart';
import 'alarm_edit_page.dart';

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
  /// "다음 알람까지"를 매분 새로 센다.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      // 다른 탭에 가려져 있을 땐(IndexedStack) 건너뛴다.
      if (mounted && TickerMode.valuesOf(context).enabled) {
        context.read<AlarmListCubit>().load();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _open(BuildContext context, Alarm alarm) async {
    final untilRing = await Navigator.of(context).push<Duration>(
      MaterialPageRoute(builder: (_) => AlarmEditPage(initial: alarm)),
    );
    if (untilRing != null && context.mounted) _showRingsIn(context, untilRing);
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
          appBar: AppBar(title: Text(l10n.walkAlarmListTitle)),
          floatingActionButton: FloatingActionButton(
            tooltip: l10n.walkAlarmAdd,
            onPressed: () => _open(context, Alarm.draft()),
            child: const Icon(Icons.add),
          ),
          body: BlocBuilder<AlarmListCubit, AlarmListState>(
            builder: (context, state) => switch (state) {
              AlarmListLoading() => const Center(child: CircularProgressIndicator()),
              AlarmListLoaded(:final alarms, :final untilNext, :final canRing) => ListView(
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
                  if (untilNext != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Text(
                        l10n.walkAlarmNextIn(AlarmFormat.duration(l10n, untilNext)),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
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
                      AlarmTile(
                        key: ValueKey(alarm.id),
                        alarm: alarm,
                        onTap: () => _open(context, alarm),
                        onToggle: (enabled) => _toggle(context, alarm, enabled),
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
