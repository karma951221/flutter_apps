import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/diary_failure.dart';
import '../../../domain/diary/entity/media_limits.dart';
import '../../../domain/diary/entity/story.dart';

/// 일기 화면의 날짜 머리 · 기록 시각 · 스토리 기간 표기.
abstract final class DiaryFormat {
  /// 이보다 최근이면 시각 대신 "지금".
  static const nowWindow = Duration(minutes: 1);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 줄글의 날짜 머리 — `오늘`, `어제`, `10월 7일 (수)`, 지난해면 `2025년 12월 31일 (수)`.
  static String dayHeader(AppLocalizations l10n, DateTime at, DateTime now) {
    if (sameDay(at, now)) return l10n.walkDiaryToday;
    if (sameDay(at, DateTime(now.year, now.month, now.day - 1))) {
      return l10n.walkDiaryYesterday;
    }
    return dateWithWeekday(l10n, at, now);
  }

  /// `10월 7일 (수)`, 지난해면 `2025년 12월 31일 (수)` — 오늘이어도 날짜로.
  static String dateWithWeekday(
    AppLocalizations l10n,
    DateTime at,
    DateTime now,
  ) => '${date(l10n, at, now)} (${DateFormat.E(l10n.localeName).format(at)})';

  /// `10월 7일`, 지난해면 `2025년 10월 7일`.
  static String date(AppLocalizations l10n, DateTime at, DateTime now) {
    final locale = l10n.localeName;
    return at.year == now.year
        ? DateFormat.MMMd(locale).format(at)
        : DateFormat.yMMMd(locale).format(at);
  }

  /// 기기 언어 · 24시간제 설정을 따른다 — `오후 3:24`.
  static String time(BuildContext context, DateTime at) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(at),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );

  /// 기록 시각 — [nowWindow] 안이면 `지금`, 아니면 [time].
  static String stamp(BuildContext context, DateTime at, DateTime now) {
    final ago = now.difference(at);
    if (!ago.isNegative && ago < nowWindow) {
      return AppLocalizations.of(context).walkDiaryNow;
    }
    return time(context, at);
  }

  /// 스토리 머리의 기간 — `10월 7일 ~ 진행 중`, `10월 7일 ~ 10월 9일`.
  static String storyPeriod(AppLocalizations l10n, Story story, DateTime now) {
    final end = story.endedAt;
    return l10n.walkDiaryStoryPeriod(
      date(l10n, story.startedAt, now),
      end == null ? l10n.walkDiaryOngoing : date(l10n, end, now),
    );
  }

  /// 일기 규칙 위반 안내.
  static String failure(AppLocalizations l10n, DiaryFailure failure) =>
      switch (failure) {
        DiaryFailure.emptyEntry => l10n.walkDiaryErrorEmptyEntry,
        DiaryFailure.futureTime => l10n.walkDiaryErrorFutureTime,
        DiaryFailure.tooManyMedia => l10n.walkDiaryErrorTooManyMedia(
          MediaLimits.maxItems,
        ),
        DiaryFailure.videoTooLong => l10n.walkDiaryErrorVideoTooLong(
          MediaLimits.maxVideo.inSeconds,
        ),
        DiaryFailure.storyClosed => l10n.walkDiaryErrorStoryClosed,
        DiaryFailure.notFound => l10n.walkDiaryErrorNotFound,
        DiaryFailure.mediaProcessing => l10n.walkDiaryErrorMediaProcessing,
        DiaryFailure.defaultStoryLocked =>
          l10n.walkDiaryErrorDefaultStoryLocked,
        DiaryFailure.endBeforeStart => l10n.walkDiaryErrorEndBeforeStart,
      };
}
