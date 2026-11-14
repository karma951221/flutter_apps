import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/presentation/alarm/format/alarm_format.dart';

void main() {
  final ko = lookupAppLocalizations(const Locale('ko'));
  final en = lookupAppLocalizations(const Locale('en'));

  setUpAll(() async {
    await initializeDateFormatting('ko');
    await initializeDateFormatting('en');
  });

  group('duration', () {
    test('분은 올림한다', () {
      expect(AlarmFormat.duration(ko, const Duration(seconds: 10)), '1분');
      expect(
        AlarmFormat.duration(ko, const Duration(minutes: 5, seconds: 1)),
        '6분',
      );
      expect(AlarmFormat.duration(ko, Duration.zero), '1분');
    });

    test('시간 · 분', () {
      expect(
        AlarmFormat.duration(ko, const Duration(hours: 7, minutes: 12)),
        '7시간 12분',
      );
      expect(AlarmFormat.duration(ko, const Duration(hours: 2)), '2시간');
      expect(
        AlarmFormat.duration(en, const Duration(hours: 7, minutes: 12)),
        '7 hr 12 min',
      );
    });

    test('하루가 넘으면 일 · 시간(분 생략)', () {
      expect(
        AlarmFormat.duration(ko, const Duration(days: 2, hours: 3, minutes: 4)),
        '2일 3시간',
      );
      expect(AlarmFormat.duration(ko, const Duration(days: 1)), '1일');
      expect(
        AlarmFormat.duration(en, const Duration(days: 1, hours: 1)),
        '1 day 1 hr',
      );
    });
  });

  group('remaining', () {
    test('스펙 §4.3 표 — duration 에 "뒤"를 붙인다', () {
      const table = [
        (Duration(seconds: 1), '1분 뒤'),
        (Duration(minutes: 1), '1분 뒤'),
        (Duration(minutes: 1, seconds: 30), '2분 뒤'),
        (Duration(hours: 3), '3시간 뒤'),
        (Duration(hours: 3, minutes: 5), '3시간 5분 뒤'),
        (Duration(days: 1, hours: 3, minutes: 20), '1일 3시간 뒤'),
        (Duration(days: 2), '2일 뒤'),
      ];
      for (final (remaining, text) in table) {
        expect(
          AlarmFormat.remaining(ko, remaining),
          text,
          reason: '$remaining',
        );
      }
      expect(
        AlarmFormat.remaining(en, const Duration(hours: 3, minutes: 5)),
        'in 3 hr 5 min',
      );
    });

    test('단위가 올라가는 경계 — 올림한 분으로 시간 · 일을 다시 센다', () {
      const table = [
        (Duration(minutes: 60), '1시간 뒤'),
        (Duration(minutes: 59, seconds: 30), '1시간 뒤'),
        (Duration(hours: 23, minutes: 59, seconds: 30), '1일 뒤'),
        (Duration(hours: 24), '1일 뒤'),
        (Duration(days: 1, minutes: 30), '1일 뒤'),
      ];
      for (final (remaining, text) in table) {
        expect(
          AlarmFormat.remaining(ko, remaining),
          text,
          reason: '$remaining',
        );
      }
    });

    test('음수(막 지남)는 1분 뒤', () {
      expect(AlarmFormat.remaining(ko, const Duration(seconds: -30)), '1분 뒤');
      expect(AlarmFormat.remaining(ko, const Duration(minutes: -3)), '1분 뒤');
    });

    test('1초 미만 자투리도 올림한다 — 1분 0.5초는 2분 뒤', () {
      expect(
        AlarmFormat.remaining(
          ko,
          const Duration(minutes: 1, milliseconds: 500),
        ),
        '2분 뒤',
      );
      expect(
        AlarmFormat.remaining(ko, const Duration(microseconds: 1)),
        '1분 뒤',
      );
    });
  });

  group('day', () {
    final mondayEvening = DateTime(2026, 9, 28, 21); // 월요일

    test('오늘 · 내일 · 그 뒤는 월일, 뒤에 요일', () {
      expect(
        AlarmFormat.day(ko, DateTime(2026, 9, 28, 21, 45), mondayEvening),
        '오늘 (월)',
      );
      expect(
        AlarmFormat.day(ko, DateTime(2026, 9, 29, 7), mondayEvening),
        '내일 (화)',
      );
      expect(
        AlarmFormat.day(ko, DateTime(2026, 10, 3, 7), mondayEvening),
        '10월 3일 (토)',
      );
      expect(
        AlarmFormat.day(en, DateTime(2026, 9, 29, 7), mondayEvening),
        'Tomorrow (Tue)',
      );
      expect(
        AlarmFormat.day(en, DateTime(2026, 10, 3, 7), mondayEvening),
        'Oct 3 (Sat)',
      );
    });

    test('자정 직전에는 내일, 자정이 지나면 같은 시각이 오늘', () {
      final at = DateTime(2026, 9, 29, 7);
      expect(AlarmFormat.day(ko, at, DateTime(2026, 9, 28, 23, 59)), '내일 (화)');
      expect(AlarmFormat.day(ko, at, DateTime(2026, 9, 29)), '오늘 (화)');
    });

    test('달 · 해가 바뀌어도 내일을 알아본다', () {
      expect(
        AlarmFormat.day(
          ko,
          DateTime(2027, 1, 1, 7),
          DateTime(2026, 12, 31, 22),
        ),
        '내일 (금)',
      );
    });
  });

  test('earliest 는 가장 이른 시각, 같으면 id 가 작은 것', () {
    final seven = DateTime(2026, 9, 29, 7);
    expect(AlarmFormat.earliest({}), isNull);
    expect(AlarmFormat.earliest({3: DateTime(2026, 9, 29, 8), 5: seven}), 5);
    expect(
      AlarmFormat.earliest({5: seven, 2: seven, 9: DateTime(2026, 9, 30)}),
      2,
    );
  });

  group('repeat', () {
    test('요약', () {
      expect(AlarmFormat.repeat(ko, const {}), '1회');
      expect(AlarmFormat.repeat(ko, Weekday.values.toSet()), '매일');
      expect(
        AlarmFormat.repeat(ko, const {
          Weekday.mon,
          Weekday.tue,
          Weekday.wed,
          Weekday.thu,
          Weekday.fri,
        }),
        '평일',
      );
      expect(AlarmFormat.repeat(ko, const {Weekday.sun, Weekday.sat}), '주말');
    });

    test('그 밖은 월요일부터 요일을 잇는다', () {
      expect(
        AlarmFormat.repeat(ko, const {Weekday.fri, Weekday.mon, Weekday.wed}),
        '월·수·금',
      );
      expect(
        AlarmFormat.repeat(en, const {Weekday.sun, Weekday.tue}),
        'Tue·Sun',
      );
    });
  });

  testWidgets('time 은 기기 언어 형식', (tester) async {
    late String formatted;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            formatted = AlarmFormat.time(context, 7, 0);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(formatted, '오전 7:00');
  });
}
