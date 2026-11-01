import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../walk/cubit/step_goal_cubit.dart';
import '../../walk/format/walk_format.dart';
import '../cubit/settings_permissions_cubit.dart';
import '../cubit/settings_permissions_state.dart';
import '../widget/settings_widgets.dart';
import '../widget/step_goal_sheet.dart';

/// 걷기 설정 — 하루 걸음 목표, Health Connect 권한.
///
/// [SettingsPermissionsCubit] 은 셸이(`openSettings`), [StepGoalCubit] 은 앱이 제공한다.
/// 열릴 때 권한을 다시 읽는다.
class WalkSettingsPage extends StatefulWidget {
  const WalkSettingsPage({super.key});

  @override
  State<WalkSettingsPage> createState() => _WalkSettingsPageState();
}

class _WalkSettingsPageState extends State<WalkSettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsPermissionsCubit>().check();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkWalkSettingsTitle)),
      body: ListView(
        children: [
          const _StepGoalTile(),
          SettingsSectionHeader(l10n.walkSettingsPermissions),
          const _HealthPermissionTile(),
        ],
      ),
    );
  }
}

/// 하루 걸음 목표 행. 누르면 [StepGoalSheet].
class _StepGoalTile extends StatelessWidget {
  const _StepGoalTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<StepGoalCubit, int>(
      builder: (context, goal) => AppListTile(
        key: const Key('settings-step-goal'),
        leading: const Icon(Icons.flag_outlined),
        title: Text(l10n.walkSettingsStepGoal),
        trailing: Text(
          l10n.walkStepsCount(WalkFormat.steps(l10n.localeName, goal)),
        ),
        onTap: () async {
          final cubit = context.read<StepGoalCubit>();
          final result = await StepGoalSheet.show(context, initial: goal);
          if (result != null) await cubit.select(result);
        },
      ),
    );
  }
}

/// Health Connect 권한 행.
class _HealthPermissionTile extends StatelessWidget {
  const _HealthPermissionTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final permissions = context.read<SettingsPermissionsCubit>();
    return BlocBuilder<SettingsPermissionsCubit, SettingsPermissionsState>(
      builder: (context, state) => SettingsPermissionTile(
        title: l10n.walkSettingsHealthConnect,
        description: l10n.walkSettingsHealthConnectDescription,
        status: settingsHealthLabel(l10n, state.health),
        onTap: permissions.openHealth,
      ),
    );
  }
}
