import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../../../domain/alarm/entity/alarm_options.dart';

/// 편집 화면 아래의 접히는 "울림 설정" 영역(웨이브 3 스펙 §5). 접힌 상태는 한 줄 요약
/// (`볼륨 80% · 스누즈 5분 · 자동 멈춤 없음`), 펼치면 볼륨 슬라이더 · 점점 커지기 ·
/// 스누즈 간격 · 스누즈 횟수 · 자동 멈춤 세그먼트와 "30분 전에 알려 주기" 스위치.
///
/// 선택지는 [AlarmOptions] 그대로다. 세그먼트는 선택지의 index 로 고른다(무제한 · 안 함이 null).
class RingSettingsSection extends StatelessWidget {
  const RingSettingsSection({
    required this.alarm,
    required this.onVolumePercent,
    required this.onFadeSeconds,
    required this.onSnoozeMinutes,
    required this.onSnoozeLimit,
    required this.onAutoStopMinutes,
    required this.onRemindBefore,
    this.enabled = true,
    super.key,
  });

  final Alarm alarm;
  final ValueChanged<int> onVolumePercent;
  final ValueChanged<int> onFadeSeconds;
  final ValueChanged<int> onSnoozeMinutes;
  final ValueChanged<int?> onSnoozeLimit;
  final ValueChanged<int?> onAutoStopMinutes;
  final ValueChanged<bool> onRemindBefore;

  /// 저장 · 삭제 중이면 false — 값을 바꿀 수 없다.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final autoStop = alarm.autoStopMinutes;
    final volume = AlarmOptions.volumePercents;
    return ExpansionTile(
      // 펼쳐도 위아래 선을 긋지 않는다 — 편집 화면의 다른 행처럼 보이게.
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      childrenPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      title: Text(l10n.walkAlarmRingSettings),
      subtitle: Text(
        l10n.walkAlarmRingSummary(
          alarm.volumePercent,
          l10n.walkAlarmMinutes(alarm.snoozeMinutes),
          autoStop == null ? l10n.walkAlarmAutoStopNone : l10n.walkAlarmMinutes(autoStop),
        ),
      ),
      children: [
        Row(
          children: [
            Expanded(child: Text(l10n.walkAlarmVolume, style: theme.textTheme.titleSmall)),
            Text(l10n.walkAlarmPercent(alarm.volumePercent)),
          ],
        ),
        Slider(
          key: const Key('ring-volume'),
          min: volume.first.toDouble(),
          max: volume.last.toDouble(),
          divisions: volume.length - 1,
          value: alarm.volumePercent.toDouble(),
          label: l10n.walkAlarmPercent(alarm.volumePercent),
          onChanged: enabled ? (value) => onVolumePercent(value.round()) : null,
        ),
        _Choice<int>(
          key: const Key('ring-fade'),
          title: l10n.walkAlarmFade,
          options: AlarmOptions.fadeSeconds,
          value: alarm.fadeSeconds,
          labelOf: (s) => s == 0 ? l10n.walkAlarmFadeOff : l10n.walkAlarmSeconds(s),
          onChanged: enabled ? onFadeSeconds : null,
        ),
        _Choice<int>(
          key: const Key('ring-snooze-interval'),
          title: l10n.walkAlarmSnoozeInterval,
          options: AlarmOptions.snoozeMinutes,
          value: alarm.snoozeMinutes,
          labelOf: l10n.walkAlarmMinutes,
          onChanged: enabled ? onSnoozeMinutes : null,
        ),
        _Choice<int?>(
          key: const Key('ring-snooze-limit'),
          title: l10n.walkAlarmSnoozeLimit,
          options: AlarmOptions.snoozeLimits,
          value: alarm.snoozeLimit,
          labelOf: (n) => n == null ? l10n.walkAlarmSnoozeUnlimited : l10n.walkAlarmTimes(n),
          onChanged: enabled ? onSnoozeLimit : null,
        ),
        _Choice<int?>(
          key: const Key('ring-auto-stop'),
          title: l10n.walkAlarmAutoStop,
          options: AlarmOptions.autoStopMinutes,
          value: alarm.autoStopMinutes,
          labelOf: (m) => m == null ? l10n.walkAlarmAutoStopNever : l10n.walkAlarmMinutes(m),
          onChanged: enabled ? onAutoStopMinutes : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppListTile(
          title: Text(l10n.walkAlarmRemindBefore),
          subtitle: Text(l10n.walkAlarmRemindBeforeHint),
          trailing: Switch(
            value: alarm.remindBefore,
            onChanged: enabled ? onRemindBefore : null,
          ),
          onTap: enabled ? () => onRemindBefore(!alarm.remindBefore) : null,
        ),
      ],
    );
  }
}

/// 제목 + 꽉 찬 폭의 세그먼트 하나. [options] 의 index 를 세그먼트 값으로 쓴다(null 선택지 때문).
class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.title,
    required this.options,
    required this.value,
    required this.labelOf,
    required this.onChanged,
    super.key,
  });

  final String title;
  final List<T> options;
  final T value;
  final String Function(T) labelOf;

  /// null 이면 잠근다.
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onChanged = this.onChanged;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<int>(
            segments: [
              for (final (index, option) in options.indexed)
                ButtonSegment(
                  value: index,
                  label: Text(labelOf(option), maxLines: 1, softWrap: false),
                ),
            ],
            selected: {options.indexOf(value)},
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: AppSpacing.xs)),
            ),
            onSelectionChanged: onChanged == null
                ? null
                : (selected) => onChanged(options[selected.single]),
          ),
        ],
      ),
    );
  }
}
