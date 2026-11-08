import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../data/location/background_location_access.dart';
import '../../../domain/location/entity/record_mode.dart';
import '../../../domain/location/entity/record_retention.dart';
import '../../../domain/location/recorder/recorder_status.dart';
import '../../map/cubit/map_record_cubit.dart';
import '../../map/cubit/map_record_state.dart';
import '../widget/settings_widgets.dart';

/// 지도 설정 — 위치 기록 켜기 · 촘촘 기록 · 보관 기간 · 권한 · 모두 지우기.
///
/// [MapRecordCubit] 은 셸이 제공한다(`openSettings`). 열릴 때 상태와 권한을 읽는다.
class MapSettingsPage extends StatefulWidget {
  const MapSettingsPage({super.key});

  @override
  State<MapSettingsPage> createState() => _MapSettingsPageState();
}

class _MapSettingsPageState extends State<MapSettingsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<MapRecordCubit>().load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 시스템 설정에서 권한을 바꾸고 돌아오면 다시 읽는다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<MapRecordCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkMapSettingsTitle)),
      body: BlocBuilder<MapRecordCubit, MapRecordState>(
        builder: (context, state) => ListView(
          children: [
            _RecordTile(state: state),
            _DenseTile(state: state),
            _RetentionTile(state: state),
            AppListTile(
              key: const Key('map-settings-battery'),
              leading: const Icon(Icons.battery_saver_outlined),
              title: Text(l10n.walkMapSettingsBattery),
              subtitle: Text(l10n.walkMapSettingsBatteryDescription),
              trailing: const Icon(Icons.chevron_right),
              onTap: context.read<MapRecordCubit>().openBatterySettings,
            ),
            SettingsSectionHeader(l10n.walkMapSettingsPermissions),
            _PermissionRows(state: state),
            const Divider(),
            _DeleteAllTile(state: state),
          ],
        ),
      ),
    );
  }
}

/// 위치 기록 스위치. 권한을 잃어 멈춘(blocked) 상태는 켜 둔 채로 설명을 바꿔 보인다.
class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.state});

  final MapRecordState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MapRecordCubit>();
    final blocked = state.status is RecorderBlocked;
    return AppListTile(
      key: const Key('map-settings-record'),
      leading: const Icon(Icons.my_location_outlined),
      title: Text(l10n.walkMapSettingsRecord),
      subtitle: Text(
        blocked
            ? l10n.walkMapSettingsBlocked
            : l10n.walkMapSettingsRecordDescription,
      ),
      trailing: Switch(
        key: const Key('map-settings-record-switch'),
        value: state.status is! RecorderOff,
        onChanged: state.busy ? null : (on) => _toggle(context, cubit, on),
      ),
      onTap: state.busy
          ? null
          : () => _toggle(context, cubit, state.status is RecorderOff),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    MapRecordCubit cubit,
    bool on,
  ) async {
    if (!on) return cubit.disable();
    final l10n = AppLocalizations.of(context);
    await cubit.enable();
    if (!context.mounted) return;
    if (cubit.state.access == AlwaysAccess.needsSettings) {
      AppSnackBar.show(context, message: l10n.walkMapSettingsNeedsAlways);
    }
  }
}

/// 촘촘 기록 스위치. 기록이 꺼져 있으면 비활성.
class _DenseTile extends StatelessWidget {
  const _DenseTile({required this.state});

  final MapRecordState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MapRecordCubit>();
    final dense = switch (state.status) {
      RecorderRunning(:final mode) ||
      RecorderBlocked(:final mode) => mode == RecordMode.dense,
      RecorderOff() => false,
    };
    final enabled = state.status is! RecorderOff && !state.busy;
    return AppListTile(
      key: const Key('map-settings-dense'),
      leading: const Icon(Icons.timeline),
      title: Text(l10n.walkMapSettingsDense),
      subtitle: Text(l10n.walkMapSettingsDenseDescription),
      enabled: enabled,
      trailing: Switch(
        key: const Key('map-settings-dense-switch'),
        value: dense,
        onChanged: enabled ? cubit.setDense : null,
      ),
      onTap: enabled ? () => cubit.setDense(!dense) : null,
    );
  }
}

/// 보관 기간 행. 누르면 3택 시트.
class _RetentionTile extends StatelessWidget {
  const _RetentionTile({required this.state});

  final MapRecordState state;

  static String label(AppLocalizations l10n, RecordRetention value) =>
      switch (value) {
        RecordRetention.threeMonths => l10n.walkMapSettingsRetentionThreeMonths,
        RecordRetention.oneYear => l10n.walkMapSettingsRetentionOneYear,
        RecordRetention.never => l10n.walkMapSettingsRetentionNever,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppListTile(
      key: const Key('map-settings-retention'),
      leading: const Icon(Icons.history),
      title: Text(l10n.walkMapSettingsRetention),
      trailing: Text(label(l10n, state.retention)),
      onTap: () async {
        final cubit = context.read<MapRecordCubit>();
        final result = await SettingsChoiceSheet.show<RecordRetention>(
          context,
          title: l10n.walkMapSettingsRetention,
          current: state.retention,
          options: [
            for (final value in RecordRetention.values)
              (value, label(l10n, value)),
          ],
        );
        if (result != null) await cubit.setRetention(result);
      },
    );
  }
}

/// 위치 항상 허용 · 신체 활동 · 알림. 누르면 앱 설정을 연다.
class _PermissionRows extends StatelessWidget {
  const _PermissionRows({required this.state});

  final MapRecordState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MapRecordCubit>();
    SettingsStatus? granted(bool? ok) => switch (ok) {
      null => null,
      true => (l10n.walkSettingsGranted, false),
      false => (l10n.walkSettingsNeedsPermission, true),
    };
    // 항상 허용은 서비스 상태에서 읽는다 — 권한을 잃으면 blocked.
    final SettingsStatus? always = switch (state.status) {
      RecorderBlocked() => (l10n.walkSettingsNeedsPermission, true),
      RecorderRunning() => (l10n.walkSettingsGranted, false),
      RecorderOff() => switch (state.access) {
        AlwaysAccess.granted => (l10n.walkSettingsGranted, false),
        AlwaysAccess.needsSettings ||
        AlwaysAccess.denied => (l10n.walkSettingsNeedsPermission, true),
        null => null,
      },
    };
    final SettingsStatus? activity = switch (state.activityRecognition) {
      null => null,
      true => (l10n.walkSettingsGranted, false),
      false => (l10n.walkMapSettingsStillOff, true),
    };
    return Column(
      children: [
        KeyedSubtree(
          key: const Key('map-settings-permission-always'),
          child: SettingsPermissionTile(
            title: l10n.walkMapSettingsLocationAlways,
            description: l10n.walkMapSettingsLocationAlwaysDescription,
            status: always,
            onTap: cubit.openAppSettings,
          ),
        ),
        KeyedSubtree(
          key: const Key('map-settings-permission-activity'),
          child: SettingsPermissionTile(
            title: l10n.walkMapSettingsActivity,
            description: l10n.walkMapSettingsActivityDescription,
            status: activity,
            onTap: cubit.openAppSettings,
          ),
        ),
        KeyedSubtree(
          key: const Key('map-settings-permission-notification'),
          child: SettingsPermissionTile(
            title: l10n.walkMapSettingsNotification,
            description: l10n.walkMapSettingsNotificationDescription,
            status: granted(state.notification),
            onTap: cubit.openAppSettings,
          ),
        ),
      ],
    );
  }
}

/// 위치 기록 모두 지우기. 확인 대화상자에서 확인해야 지운다.
class _DeleteAllTile extends StatelessWidget {
  const _DeleteAllTile({required this.state});

  final MapRecordState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AppListTile(
      key: const Key('map-settings-delete-all'),
      leading: Icon(Icons.delete_outline, color: scheme.error),
      title: Text(
        l10n.walkMapSettingsDeleteAll,
        style: TextStyle(color: scheme.error),
      ),
      subtitle: Text(l10n.walkMapSettingsDeleteAllDescription),
      enabled: !state.busy,
      onTap: () async {
        final cubit = context.read<MapRecordCubit>();
        final confirmed = await AppConfirmDialog.show(
          context,
          title: l10n.walkMapSettingsDeleteTitle,
          content: l10n.walkMapSettingsDeleteBody,
          confirmLabel: l10n.commonDelete,
        );
        if (!confirmed || cubit.isClosed) return;
        await cubit.deleteAll();
        if (!context.mounted) return;
        AppSnackBar.show(context, message: l10n.walkMapSettingsDeleted);
      },
    );
  }
}
