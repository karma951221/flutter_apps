import 'package:daylog/features/safety/domain/report_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportPolicy.normalizeDetail', () {
    test('null 은 null 로 남는다', () {
      expect(ReportPolicy.normalizeDetail(null), isNull);
    });

    test('빈 문자열은 null 이 된다', () {
      expect(ReportPolicy.normalizeDetail(''), isNull);
    });

    test('공백만 있으면 null 이 된다', () {
      expect(ReportPolicy.normalizeDetail('   '), isNull);
    });

    test('앞뒤 공백을 걷어낸다', () {
      expect(ReportPolicy.normalizeDetail(' 내용 '), '내용');
    });

    test('최대 길이 문자열은 그대로 유지된다', () {
      final detail = 'A' * ReportPolicy.maxDetailLength;
      expect(ReportPolicy.normalizeDetail(detail), detail);
    });
  });
}
