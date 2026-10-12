import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../alarm/widget/alarm_time_wheel.dart';
import '../format/diary_format.dart';

/// 작성 화면의 시각 행(스펙 §6.2). 누르면 날짜(오늘까지) → 시각(알람 휠) 순으로 고른다.
/// 새 기록이 처음 시각 그대로면 `지금 · 10월 10일 (토) 오후 3:24`, 바꿨으면 날짜 문구 +
/// '올린 시각으로 되돌리기'.
class TimeRow extends StatelessWidget {
  const TimeRow({
    required this.occurredAt,
    required this.edited,
    required this.isEditing,
    required this.now,
    required this.onPick,
    required this.onRevert,
    super.key,
  });

  final DateTime occurredAt;

  /// 처음 시각(새 기록은 연 시각, 수정은 기록의 createdAt)과 분 단위로 다른지.
  final bool edited;
  final bool isEditing;
  final DateTime now;

  /// 미래 검사는 받는 쪽(cubit)이 한다.
  final ValueChanged<DateTime> onPick;
  final VoidCallback onRevert;

  /// 날짜 고르기의 가장 이른 날.
  static final _firstDate = DateTime(2000);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final when = l10n.walkDiaryEditorDateTime(
      DiaryFormat.dateWithWeekday(l10n, occurredAt, now),
      DiaryFormat.time(context, occurredAt),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppListTile(
          leading: const Icon(Icons.schedule),
          title: Text(
            !isEditing && !edited ? l10n.walkDiaryEditorTimeNow(when) : when,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pick(context),
        ),
        if (edited)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: AppButton.text(
              label: l10n.walkDiaryEditorRevertTime,
              onPressed: onRevert,
            ),
          ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final today = DateTime(now.year, now.month, now.day);
    final day = await showDatePicker(
      context: context,
      initialDate: occurredAt.isAfter(now) ? today : occurredAt,
      firstDate: _firstDate,
      lastDate: today,
    );
    if (day == null || !context.mounted) return;
    final isToday = DiaryFormat.sameDay(day, now);
    final max = isToday ? TimeOfDay.fromDateTime(now) : null;
    var initial = TimeOfDay.fromDateTime(occurredAt);
    if (max != null && _minutes(initial) > _minutes(max)) initial = max;
    final time = await EntryTimeSheet.show(
      context,
      initial: initial,
      maximum: max,
    );
    if (time == null) return;
    onPick(DateTime(day.year, day.month, day.day, time.hour, time.minute));
  }

  static int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;
}

/// 기록 시각을 알람 휠로 고르는 바텀시트. [maximum] 뒤 시각은 휠에서 막는다.
class EntryTimeSheet extends StatefulWidget {
  const EntryTimeSheet({required this.initial, this.maximum, super.key});

  final TimeOfDay initial;
  final TimeOfDay? maximum;

  /// 휠 높이 — 알람 시각 시트와 같은 크기. 여백 토큰이 아니라 휠 자체의 크기다.
  static const pickerHeight = 200.0;

  static Future<TimeOfDay?> show(
    BuildContext context, {
    required TimeOfDay initial,
    TimeOfDay? maximum,
  }) => showModalBottomSheet<TimeOfDay>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => EntryTimeSheet(initial: initial, maximum: maximum),
  );

  @override
  State<EntryTimeSheet> createState() => _EntryTimeSheetState();
}

class _EntryTimeSheetState extends State<EntryTimeSheet> {
  late TimeOfDay _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: EntryTimeSheet.pickerHeight,
              child: AlarmTimeWheel(
                initial: widget.initial,
                maximum: widget.maximum,
                onChanged: (time) => _value = time,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.primary(
              label: l10n.walkDiaryEditorPickTimeConfirm,
              onPressed: () => Navigator.of(context).pop(_value),
            ),
          ],
        ),
      ),
    );
  }
}
