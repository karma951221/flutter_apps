/// 휴지통 보관 기간.
enum TrashRetention {
  day1(Duration(days: 1)),
  day7(Duration(days: 7)),
  day30(Duration(days: 30)),
  never(null);

  const TrashRetention(this.period);

  /// null 이면 지우지 않는다.
  final Duration? period;

  static const fallback = TrashRetention.day7;

  /// deletedAt + period <= now. [never] 면 항상 false.
  bool expired(DateTime deletedAt, DateTime now) {
    final p = period;
    if (p == null) return false;
    return !deletedAt.add(p).isAfter(now);
  }
}
