import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../../domain/diary/entity/diary_entry.dart';
import '../../../../domain/diary/repository/diary_repository.dart';

/// 일기 고르기. 위쪽 = [suggested](출처 대화의 근거 일기, 휴지통 · 없는 기록 제외), 아래 = 날짜를
/// 골라 [DiaryRepository.searchEntries](그날 00:00 ~ 그날 끝) 결과. 고른 entryId 또는 null.
Future<String?> showDiaryEntryPicker(
  BuildContext context, {
  required List<String> suggested,
}) => showModalBottomSheet<String>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _DiaryEntryPicker(suggested: suggested),
);

class _DiaryEntryPicker extends StatefulWidget {
  const _DiaryEntryPicker({required this.suggested});

  final List<String> suggested;

  @override
  State<_DiaryEntryPicker> createState() => _DiaryEntryPickerState();
}

class _DiaryEntryPickerState extends State<_DiaryEntryPicker> {
  final _diary = getIt<DiaryRepository>();
  final _clock = getIt<Clock>();

  late final Future<List<DiaryEntry>> _suggested = _loadSuggested();

  /// 고른 날. 고르기 전 null.
  DateTime? _day;

  /// 고른 날의 기록. 읽는 중이면 null.
  List<DiaryEntry>? _dayEntries;

  Future<List<DiaryEntry>> _loadSuggested() async {
    final entries = <DiaryEntry>[];
    for (final id in widget.suggested) {
      if (await _diary.entry(id) case Ok(
        :final value,
      ) when value.deletedAt == null) {
        entries.add(value);
      }
    }
    return entries;
  }

  Future<void> _pickDay() async {
    final now = _clock.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = await showDatePicker(
      context: context,
      initialDate: _day ?? today,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (day == null || !mounted) return;
    setState(() {
      _day = day;
      _dayEntries = null;
    });
    final from = DateTime(day.year, day.month, day.day);
    final to = DateTime(
      day.year,
      day.month,
      day.day + 1,
    ).subtract(const Duration(microseconds: 1));
    final List<DiaryEntry> found;
    try {
      found = await _diary.searchEntries(from: from, to: to);
    } on Object {
      if (mounted && _day == day) setState(() => _dayEntries = const []);
      return;
    }
    if (mounted && _day == day) setState(() => _dayEntries = found);
  }

  Widget _row(DiaryEntry entry, String locale) {
    final body = entry.body.replaceAll(RegExp(r'\s+'), ' ').trim();
    final date = DateFormat.yMMMd(locale).add_jm().format(entry.occurredAt);
    return AppListTile(
      key: Key('wiki-pick-entry-${entry.id}'),
      title: Text(
        body.isEmpty ? date : body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: body.isEmpty ? null : Text(date),
      onTap: () => Navigator.pop(context, entry.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = l10n.localeName;
    final header = theme.textTheme.titleSmall;
    final dayEntries = _dayEntries;
    return FractionallySizedBox(
      heightFactor: 0.75,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              l10n.walkChatWikiPickEntryTitle,
              style: theme.textTheme.titleMedium,
            ),
          ),
          FutureBuilder<List<DiaryEntry>>(
            future: _suggested,
            builder: (context, snapshot) {
              final entries = snapshot.data ?? const <DiaryEntry>[];
              if (entries.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xs,
                    ),
                    child: Text(
                      l10n.walkChatWikiPickEntrySuggested,
                      style: header,
                    ),
                  ),
                  for (final e in entries) _row(e, locale),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppButton.secondary(
              key: const Key('wiki-pick-entry-date'),
              label: switch (_day) {
                final day? => DateFormat.yMMMd(locale).format(day),
                null => l10n.walkChatWikiPickEntryByDate,
              },
              onPressed: () => unawaited(_pickDay()),
            ),
          ),
          if (_day != null)
            if (dayEntries == null)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (dayEntries.isEmpty)
              AppPlaceholder(
                icon: Icons.event_busy_outlined,
                message: l10n.walkChatWikiPickEntryNone,
              )
            else
              for (final e in dayEntries) _row(e, locale),
        ],
      ),
    );
  }
}
