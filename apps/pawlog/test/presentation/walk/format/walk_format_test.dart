import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:pawlog/presentation/walk/format/walk_format.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('ko'));

  group('distance', () {
    test('1 km 미만은 반올림한 미터로 쓴다', () {
      expect(WalkFormat.distance(l10n, 999), '999 m');
      expect(WalkFormat.distance(l10n, 850.4), '850 m');
    });

    test('1 km 이상은 소수 1자리 km 로 쓴다', () {
      expect(WalkFormat.distance(l10n, 1000), '1.0 km');
      expect(WalkFormat.distance(l10n, 1250), '1.3 km');
    });

    test('반올림해서 1000 m 가 되면 km 로 쓴다', () {
      expect(WalkFormat.distance(l10n, 999.6), '1.0 km');
    });
  });

  group('duration', () {
    test('1시간 미만은 분만 쓴다', () {
      expect(WalkFormat.duration(l10n, const Duration(minutes: 59)), '59분');
      expect(WalkFormat.duration(l10n, const Duration(minutes: 23)), '23분');
    });

    test('1시간 이상은 시간과 분을 쓴다', () {
      expect(WalkFormat.duration(l10n, const Duration(minutes: 65)), '1시간 5분');
    });

    test('1분 미만은 0분 대신 1분 미만이라고 쓴다(⑤ I2)', () {
      expect(WalkFormat.duration(l10n, const Duration(seconds: 58)), '1분 미만');
      expect(WalkFormat.duration(l10n, Duration.zero), '1분 미만');
      expect(WalkFormat.duration(l10n, const Duration(seconds: 60)), '1분');
    });

    test('정확히 몇 시간이면 0분을 붙이지 않는다(⑤ I2)', () {
      expect(WalkFormat.duration(l10n, const Duration(minutes: 60)), '1시간');
      expect(
        WalkFormat.duration(l10n, const Duration(hours: 2, seconds: 30)),
        '2시간',
      );
    });

    test('영어 · 일본어도 같은 경계를 따른다', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final ja = lookupAppLocalizations(const Locale('ja'));
      expect(WalkFormat.duration(en, const Duration(seconds: 58)), '< 1 min');
      expect(WalkFormat.duration(en, const Duration(hours: 1)), '1 h');
      expect(WalkFormat.duration(ja, const Duration(seconds: 58)), '1分未満');
      expect(WalkFormat.duration(ja, const Duration(hours: 1)), '1時間');
    });
  });

  group('clock', () {
    test('1시간 미만은 mm:ss', () {
      expect(WalkFormat.clock(const Duration(minutes: 7, seconds: 5)), '07:05');
      expect(WalkFormat.clock(Duration.zero), '00:00');
    });

    test('1시간 이상은 h:mm:ss', () {
      expect(
        WalkFormat.clock(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });
  });
}
