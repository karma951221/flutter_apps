import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

void main() {
  test('자주 간 곳 방문 횟수는 영어에서 단수 · 복수를 가른다', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.walkMapFrequentVisits(1, '11 min'), '1 visit · 11 min');
    expect(en.walkMapFrequentVisits(3, '1 h'), '3 visits · 1 h');
  });

  test('한국어 · 일본어는 그대로', () {
    expect(
      lookupAppLocalizations(
        const Locale('ko'),
      ).walkMapFrequentVisits(1, '11분'),
      '1번 · 11분',
    );
    expect(
      lookupAppLocalizations(const Locale('ja')).walkMapFrequentVisits(2, '5分'),
      '2回・5分',
    );
  });
}
