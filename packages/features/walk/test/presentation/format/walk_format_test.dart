import 'package:flutter/widgets.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

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
