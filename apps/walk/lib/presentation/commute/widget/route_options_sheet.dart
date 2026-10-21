import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/commute/entity/commute_result.dart';
import '../../../domain/commute/entity/transit_route.dart';
import '../cubit/commute_cubit.dart';
import 'route_summary.dart';

/// 경로 후보를 총 시간 순으로 보여주고, 고르면 그 경로로 다시 계산한다.
/// 호출한 쪽의 [CommuteCubit] 을 그대로 쓴다.
Future<void> showRouteOptionsSheet(BuildContext context, CommuteResult result) {
  final cubit = context.read<CommuteCubit>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => BlocProvider<CommuteCubit>.value(
      value: cubit,
      child: RouteOptionsSheet(result: result),
    ),
  );
}

class RouteOptionsSheet extends StatelessWidget {
  const RouteOptionsSheet({required this.result, super.key});

  final CommuteResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final routes = <TransitRoute>[
      result.route,
      for (final r in result.alternatives)
        if (r != result.route) r,
    ]..sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.walkCommuteRoutesTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final route in routes)
                    AppListTile(
                      title: Text(
                        l10n.walkCommuteSummary(
                          route.totalMinutes,
                          route.transferCount,
                        ),
                      ),
                      subtitle: Text(RouteSummary.legsLine(l10n, route)),
                      trailing: route == result.route
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                      onTap: () {
                        final cubit = context.read<CommuteCubit>();
                        Navigator.of(context).pop();
                        cubit.selectRoute(route);
                      },
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
