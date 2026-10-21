import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/alarm/entity/alarm_pause.dart';

void main() {
  // 2026-10-07 은 수요일.
  final wednesdayNoon = DateTime(2026, 10, 7, 12);

  group('contains', () {
    final pause = AlarmPause(from: DateTime(2026, 10, 8), until: DateTime(2026, 10, 10));

    test('시작 날 0시 · 끝 날 23:59 는 포함한다', () {
      expect(pause.contains(DateTime(2026, 10, 8)), isTrue);
      expect(pause.contains(DateTime(2026, 10, 9, 7)), isTrue);
      expect(pause.contains(DateTime(2026, 10, 10, 23, 59)), isTrue);
    });

    test('시작 전날 · 끝 다음 날은 뺀다', () {
      expect(pause.contains(DateTime(2026, 10, 7, 23, 59)), isFalse);
      expect(pause.contains(DateTime(2026, 10, 11)), isFalse);
    });

    test('시각이 붙은 from · until 도 날짜로 본다', () {
      final timed = AlarmPause(from: DateTime(2026, 10, 8, 15), until: DateTime(2026, 10, 8, 9));
      expect(timed.contains(DateTime(2026, 10, 8, 7)), isTrue);
      expect(timed.contains(DateTime(2026, 10, 8, 20)), isTrue);
    });
  });

  group('isOver', () {
    final pause = AlarmPause(from: DateTime(2026, 10, 6), until: DateTime(2026, 10, 7));

    test('끝 날이 오늘이면 아직이다', () {
      expect(pause.isOver(DateTime(2026, 10, 7, 23, 59)), isFalse);
    });

    test('끝 날이 어제면 지났다', () {
      expect(pause.isOver(DateTime(2026, 10, 8)), isTrue);
    });
  });

  group('빠른 기간', () {
    test('오늘만', () {
      expect(
        AlarmPause.today(wednesdayNoon),
        AlarmPause(from: DateTime(2026, 10, 7), until: DateTime(2026, 10, 7)),
      );
    });

    test('내일까지', () {
      expect(
        AlarmPause.untilTomorrow(wednesdayNoon),
        AlarmPause(from: DateTime(2026, 10, 7), until: DateTime(2026, 10, 8)),
      );
    });

    test('이번 주말 — 평일이면 다가오는 토 · 일', () {
      expect(
        AlarmPause.weekend(wednesdayNoon),
        AlarmPause(from: DateTime(2026, 10, 10), until: DateTime(2026, 10, 11)),
      );
    });

    test('이번 주말 — 토요일이면 오늘 · 내일, 일요일이면 오늘만', () {
      expect(
        AlarmPause.weekend(DateTime(2026, 10, 10, 9)),
        AlarmPause(from: DateTime(2026, 10, 10), until: DateTime(2026, 10, 11)),
      );
      expect(
        AlarmPause.weekend(DateTime(2026, 10, 11, 9)),
        AlarmPause(from: DateTime(2026, 10, 11), until: DateTime(2026, 10, 11)),
      );
    });

    test('달이 넘어가도 날짜 생성자로 센다', () {
      // 2026-10-30 은 금요일.
      expect(
        AlarmPause.weekend(DateTime(2026, 10, 30, 9)),
        AlarmPause(from: DateTime(2026, 10, 31), until: DateTime(2026, 11, 1)),
      );
      expect(
        AlarmPause.untilTomorrow(DateTime(2026, 12, 31, 9)),
        AlarmPause(from: DateTime(2026, 12, 31), until: DateTime(2027, 1, 1)),
      );
    });
  });
}
