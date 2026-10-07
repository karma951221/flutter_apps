import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm_pause.dart';
import '../format/alarm_format.dart';

/// 쉬는 중이면 알람 탭 다음 알람 카드 위에 뜨는 배너(웨이브 4 스펙 B4).
/// "10월 12일 (월)까지 알람을 쉬어요"(시작 날이 아직이면 "…부터 …까지") · [그만 쉬기].
class AlarmPauseBanner extends StatelessWidget {
  const AlarmPauseBanner({
    required this.pause,
    required this.now,
    required this.onStop,
    super.key,
  });

  final AlarmPause pause;

  /// 오늘/내일 표기 · 시작했는지의 기준 시각.
  final DateTime now;

  /// [그만 쉬기].
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final until = AlarmFormat.day(l10n, pause.until, now);
    final started = !DateTime(
      pause.from.year,
      pause.from.month,
      pause.from.day,
    ).isAfter(DateTime(now.year, now.month, now.day));
    return Material(
      color: scheme.secondaryContainer,
      borderRadius: AppRadius.smAll,
      clipBehavior: Clip.antiAlias,
      child: ListTileTheme.merge(
        textColor: scheme.onSecondaryContainer,
        iconColor: scheme.onSecondaryContainer,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppListTile(
              leading: const Icon(Icons.bedtime_outlined),
              title: Text(
                started
                    ? l10n.walkAlarmPausedUntil(until)
                    : l10n.walkAlarmPausedRange(
                        AlarmFormat.day(l10n, pause.from, now),
                        until,
                      ),
              ),
            ),
            AppButton.text(label: l10n.walkAlarmPauseStop, onPressed: onStop),
          ],
        ),
      ),
    );
  }
}
