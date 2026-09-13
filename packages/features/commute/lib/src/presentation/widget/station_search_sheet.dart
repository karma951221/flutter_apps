import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:l10n/l10n.dart';
import '../../domain/entity/station.dart';
import '../cubit/station_search_cubit.dart';
import '../cubit/station_search_state.dart';

class StationSearchSheet extends StatelessWidget {
  const StationSearchSheet({super.key});

  static Future<Station?> show(BuildContext context) =>
      showModalBottomSheet<Station>(
        context: context,
        isScrollControlled: true,
        builder: (_) => BlocProvider(
          create: (_) => getIt<StationSearchCubit>(),
          child: const StationSearchSheet(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FractionallySizedBox(
      heightFactor: 0.8,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            top: AppSpacing.md,
            right: AppSpacing.md,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.commuteStationSearchTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('commute-station-search-field'),
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.commuteStationSearchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: context.read<StationSearchCubit>().search,
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: BlocBuilder<StationSearchCubit, StationSearchState>(
                  builder: (context, state) => switch (state) {
                    StationSearchIdle() => Center(
                      child: AppPlaceholder(
                        icon: Icons.train_outlined,
                        message: l10n.commuteStationSearchPrompt,
                      ),
                    ),
                    StationSearchSearching() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    StationSearchResults(:final stations)
                        when stations.isEmpty =>
                      Center(
                        child: AppPlaceholder(
                          icon: Icons.search_off,
                          message: l10n.commuteStationSearchEmpty,
                        ),
                      ),
                    StationSearchResults(:final stations) => ListView.builder(
                      itemCount: stations.length,
                      itemBuilder: (context, index) {
                        final station = stations[index];
                        return AppListTile(
                          key: Key('commute-station-result-${station.id}'),
                          title: Text(station.name),
                          subtitle: station.lines.isEmpty
                              ? null
                              : Text(station.lines.join(' · ')),
                          leading: const Icon(Icons.train_outlined),
                          onTap: () => Navigator.of(context).pop(station),
                        );
                      },
                    ),
                    StationSearchFailure(:final failure) => Center(
                      child: AppPlaceholder(
                        message: failure.localizedMessage(context),
                      ),
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
