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
      expect(AlarmFormat.duration(ko, const Duration(minutes: 5, seconds: 1)), '6분');
      expect(AlarmFormat.duration(ko, Duration.zero), '1분');
    });

    test('시간 · 분', () {
      expect(AlarmFormat.duration(ko, const Duration(hours: 7, minutes: 12)), '7시간 12분');
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
      expect(AlarmFormat.duration(en, const Duration(days: 1, hours: 1)), '1 day 1 hr');
    });
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
      expect(AlarmFormat.repeat(ko, const {Weekday.fri, Weekday.mon, Weekday.wed}), '월·수·금');
      expect(AlarmFormat.repeat(en, const {Weekday.sun, Weekday.tue}), 'Tue·Sun');
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
