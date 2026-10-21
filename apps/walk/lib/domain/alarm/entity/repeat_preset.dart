import 'alarm.dart';

/// 반복 알람의 빠른 묶음 — 매일 · 평일 · 주말.
enum RepeatPreset {
  everyday({
    Weekday.mon,
    Weekday.tue,
    Weekday.wed,
    Weekday.thu,
    Weekday.fri,
    Weekday.sat,
    Weekday.sun,
  }),
  weekdays({Weekday.mon, Weekday.tue, Weekday.wed, Weekday.thu, Weekday.fri}),
  weekend({Weekday.sat, Weekday.sun});

  const RepeatPreset(this.days);

  final Set<Weekday> days;

  /// [repeat] 가 어느 묶음과 같으면 그 묶음, 아니면 null.
  static RepeatPreset? of(Set<Weekday> repeat) {
    for (final preset in values) {
      if (preset.days.length == repeat.length && preset.days.containsAll(repeat)) return preset;
    }
    return null;
  }
}
