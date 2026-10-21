import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/commute/entity/place.dart';
import '../../../domain/commute/repository/address_search.dart';
import '../cubit/commute_cubit.dart';
import '../cubit/commute_state.dart';

/// 집 · 회사를 정하는 시트. 현재 위치를 쓰거나 주소를 검색해 고른다.
/// 저장하면 닫힌다. 호출한 쪽의 [CommuteCubit] 을 그대로 쓴다.
Future<void> showPlaceSetupSheet(BuildContext context, PlaceKind kind) {
  final cubit = context.read<CommuteCubit>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => BlocProvider<CommuteCubit>.value(
      value: cubit,
      child: PlaceSetupSheet(kind: kind),
    ),
  );
}

class PlaceSetupSheet extends StatefulWidget {
  const PlaceSetupSheet({required this.kind, super.key});

  final PlaceKind kind;

  @override
  State<PlaceSetupSheet> createState() => _PlaceSetupSheetState();
}

class _PlaceSetupSheetState extends State<PlaceSetupSheet> {
  final _controller = TextEditingController();
  List<PlaceCandidate>? _results;
  bool _searching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _useCurrent() async {
    final cubit = context.read<CommuteCubit>();
    final navigator = Navigator.of(context);
    final failed = AppLocalizations.of(context).walkCommutePlaceLocateFailed;
    final ok = await cubit.useCurrentLocation(widget.kind);
    if (!mounted) return;
    if (ok) {
      navigator.pop();
    } else {
      AppSnackBar.show(context, message: failed, type: AppSnackBarType.error);
    }
  }

  Future<void> _search(String query) async {
    if (_searching) return;
    final cubit = context.read<CommuteCubit>();
    setState(() => _searching = true);
    final found = await cubit.searchAddress(query);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _results = found;
    });
  }

  Future<void> _choose(PlaceCandidate candidate) async {
    final cubit = context.read<CommuteCubit>();
    final navigator = Navigator.of(context);
    await cubit.choosePlace(widget.kind, candidate);
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final kind = widget.kind;
    final title = switch (kind) {
      PlaceKind.home => l10n.walkCommutePlaceHome,
      PlaceKind.work => l10n.walkCommutePlaceWork,
    };
    final results = _results;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            BlocBuilder<CommuteCubit, CommuteState>(
              buildWhen: (a, b) => a.home != b.home || a.work != b.work,
              builder: (context, state) {
                final place = switch (kind) {
                  PlaceKind.home => state.home,
                  PlaceKind.work => state.work,
                };
                return Text(
                  place?.label ?? l10n.walkCommutePlaceUnset,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            BlocBuilder<CommuteCubit, CommuteState>(
              buildWhen: (a, b) => a.locating != b.locating,
              builder: (context, state) => AppButton.secondary(
                label: l10n.walkCommutePlaceCurrent,
                isLoading: state.locating,
                onPressed: _useCurrent,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.walkCommutePlaceSearchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onSubmitted: _search,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_searching)
              const Center(child: CircularProgressIndicator())
            else if (results != null && results.isEmpty)
              AppPlaceholder(
                icon: Icons.search_off,
                message: l10n.walkCommutePlaceNoResults,
              )
            else if (results != null)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in results)
                      AppListTile(
                        title: Text(c.label),
                        onTap: () => _choose(c),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
