import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:l10n/l10n.dart';
import '../../domain/entity/station.dart';
import '../cubit/commute_settings_cubit.dart';
import '../cubit/commute_settings_state.dart';
import '../widget/station_search_sheet.dart';

class CommuteSettingsPage extends StatelessWidget {
  const CommuteSettingsPage({this.onDone, super.key});

  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<CommuteSettingsCubit>()..load(),
    child: _CommuteSettingsView(onDone: onDone),
  );
}

class _CommuteSettingsView extends StatelessWidget {
  const _CommuteSettingsView({this.onDone});

  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.commuteSettingsTitle)),
      body: SafeArea(
        child: BlocConsumer<CommuteSettingsCubit, CommuteSettingsState>(
          listenWhen: (previous, current) => switch ((previous, current)) {
            (
              CommuteSettingsLoaded(settings: final before),
              CommuteSettingsLoaded(settings: final after),
            ) =>
              !before.isComplete && after.isComplete,
            _ => false,
          },
          listener: (_, _) => onDone?.call(),
          builder: (context, state) => switch (state) {
            CommuteSettingsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            CommuteSettingsFailure(:final failure) => Center(
              child: AppPlaceholder(
                message: failure.localizedMessage(context),
                actionLabel: l10n.commonRetry,
                onAction: context.read<CommuteSettingsCubit>().load,
              ),
            ),
            CommuteSettingsLoaded(:final settings) => ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    l10n.commuteSettingsDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                AppListTile(
                  key: const Key('commute-home-station-tile'),
                  title: Text(l10n.commuteHomeStation),
                  subtitle: Text(
                    settings.home?.name ?? l10n.commuteStationNotSet,
                  ),
                  leading: const Icon(Icons.home_outlined),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickStation(
                    context,
                    context.read<CommuteSettingsCubit>().setHome,
                  ),
                ),
                AppListTile(
                  key: const Key('commute-work-station-tile'),
                  title: Text(l10n.commuteWorkStation),
                  subtitle: Text(
                    settings.work?.name ?? l10n.commuteStationNotSet,
                  ),
                  leading: const Icon(Icons.business_outlined),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickStation(
                    context,
                    context.read<CommuteSettingsCubit>().setWork,
                  ),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }

  Future<void> _pickStation(
    BuildContext context,
    Future<void> Function(Station station) save,
  ) async {
    final station = await StationSearchSheet.show(context);
    if (station == null || !context.mounted) return;
    await save(station);
  }
}
