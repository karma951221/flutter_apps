import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../format/diary_format.dart';

/// 새 스토리 입력값. [startedAt] 은 그날 0시, [endedAt] 은 그날 끝(오늘이면 지금).
typedef NewStory = ({String title, DateTime startedAt, DateTime? endedAt});

/// 스토리 만들기(제목 · 시작일 · 종료일) · 이름 바꾸기 바텀시트(스펙 §6.3).
///
/// 시작일 기본은 오늘이고 과거를 고를 수 있다. 종료일은 선택 — 넣으면 닫힌 스토리가 된다.
/// 날짜는 하루 단위로 고르므로 시작일은 그날 0시, 종료일은 그날 끝으로 바꿔 그날 기록이 기간에 들게 한다.
class StoryFormSheet extends StatefulWidget {
  const StoryFormSheet._({
    required this.now,
    required this.withDates,
    this.initialTitle = '',
    this.allowEmpty = false,
  });

  final DateTime? now;
  final bool withDates;
  final String initialTitle;
  final bool allowEmpty;

  /// 고를 수 있는 가장 이른 날 — 작성 화면의 시각 고르기와 같다.
  static final firstDate = DateTime(2000);

  static Future<NewStory?> create(
    BuildContext context, {
    required DateTime now,
  }) => _show<NewStory>(context, StoryFormSheet._(now: now, withDates: true));

  /// 새 이름(앞뒤 공백을 떼지 않은 입력 그대로)을 돌려준다. [allowEmpty] 면 비워도 된다
  /// (기본 스토리 — 비우면 기본 이름으로 돌아간다).
  static Future<String?> rename(
    BuildContext context, {
    required String initialTitle,
    bool allowEmpty = false,
  }) => _show<String>(
    context,
    StoryFormSheet._(
      now: null,
      withDates: false,
      initialTitle: initialTitle,
      allowEmpty: allowEmpty,
    ),
  );

  static Future<T?> _show<T>(BuildContext context, Widget sheet) =>
      showModalBottomSheet<T>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => sheet,
      );

  /// [day] 의 끝(23:59:59.999). 지금보다 늦으면 지금 — 앞으로의 종료일은 두지 않는다.
  static DateTime endOfDay(DateTime day, DateTime now) {
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
    return end.isAfter(now) ? now : end;
  }

  static DateTime _day(DateTime at) => DateTime(at.year, at.month, at.day);

  @override
  State<StoryFormSheet> createState() => _StoryFormSheetState();
}

class _StoryFormSheetState extends State<StoryFormSheet> {
  late final _title = TextEditingController(text: widget.initialTitle);

  /// 이름 바꾸기(날짜 없음)에서는 쓰지 않는다.
  late DateTime _start = StoryFormSheet._day(
    widget.now ?? StoryFormSheet.firstDate,
  );
  DateTime? _end;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  bool get _valid => widget.allowEmpty || _title.text.trim().isNotEmpty;

  DateTime get _today => StoryFormSheet._day(widget.now!);

  Future<void> _pickStart() async {
    final day = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: StoryFormSheet.firstDate,
      lastDate: _today,
    );
    if (day == null) return;
    setState(() {
      _start = day;
      final end = _end;
      if (end != null && end.isBefore(day)) _end = null;
    });
  }

  Future<void> _pickEnd() async {
    final day = await showDatePicker(
      context: context,
      initialDate: _end ?? _today,
      firstDate: _start,
      lastDate: _today,
    );
    if (day != null) setState(() => _end = day);
  }

  void _submit() {
    if (!widget.withDates) {
      Navigator.of(context).pop(_title.text);
      return;
    }
    final end = _end;
    final NewStory result = (
      title: _title.text.trim(),
      startedAt: _start,
      endedAt: end == null ? null : StoryFormSheet.endOfDay(end, widget.now!),
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = widget.now;
    final end = _end;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                widget.withDates
                    ? l10n.walkDiaryStoryNew
                    : l10n.walkDiaryStoryRename,
                style: theme.textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: _title,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.walkDiaryStoryTitleLabel,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (widget.withDates && now != null) ...[
              AppListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text(
                  l10n.walkDiaryStoryStart(DiaryFormat.date(l10n, _start, now)),
                ),
                onTap: _pickStart,
              ),
              AppListTile(
                leading: const Icon(Icons.event_available_outlined),
                title: Text(
                  end == null
                      ? l10n.walkDiaryStoryNoEnd
                      : l10n.walkDiaryStoryEnd(
                          DiaryFormat.date(l10n, end, now),
                        ),
                ),
                trailing: end == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: l10n.walkDiaryStoryClearEnd,
                        onPressed: () => setState(() => _end = null),
                      ),
                onTap: _pickEnd,
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: AppButton.primary(
                label: widget.withDates
                    ? l10n.walkDiaryStoryCreate
                    : l10n.walkDiaryStorySave,
                onPressed: _valid ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
