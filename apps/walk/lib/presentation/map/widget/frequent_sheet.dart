import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/location/entity/frequent_place.dart';
import 'timeline_sheet.dart';

/// 한 달 보기의 자주 간 곳 순위(방문 횟수 · 머문 시간 합). 행을 누르면 [onTap].
class FrequentSheet extends StatelessWidget {
  const FrequentSheet({
    required this.places,
    required this.names,
    required this.onTap,
    super.key,
  });

  /// 이미 순위대로다.
  final List<FrequentPlace> places;

  /// `gridKey` → 이름. 없으면 순위로 부른다.
  final Map<String, String> names;
  final ValueChanged<FrequentPlace> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MapSheet(
      title: l10n.walkMapFrequentTitle,
      emptyMessage: l10n.walkMapTimelineEmpty,
      children: [
        for (final (index, place) in places.indexed)
          AppListTile(
            leading: Text('${index + 1}'),
            title: Text(
              names[place.gridKey] ?? l10n.walkMapFrequentRank(index + 1),
            ),
            subtitle: Text(
              l10n.walkMapFrequentVisits(
                place.visits,
                formatStayDuration(l10n, place.total),
              ),
            ),
            onTap: () => onTap(place),
          ),
      ],
    );
  }
}
