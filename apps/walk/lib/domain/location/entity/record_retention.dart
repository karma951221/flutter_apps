/// 위치 기록 보관 기간.
enum RecordRetention {
  threeMonths(3),
  oneYear(12),
  never(null);

  const RecordRetention(this.months);

  /// null 이면 지우지 않는다.
  final int? months;

  static const fallback = RecordRetention.never;

  /// 이보다 오래된 점을 지운다. [never] 면 null. 말일은 그 달 말일로 맞춘다.
  DateTime? cutoff(DateTime now) {
    final m = months;
    if (m == null) return null;
    final total = now.year * 12 + (now.month - 1) - m;
    final year = total ~/ 12;
    final month = total % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = now.day > lastDay ? lastDay : now.day;
    return DateTime(
      year,
      month,
      day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
      now.microsecond,
    );
  }
}
