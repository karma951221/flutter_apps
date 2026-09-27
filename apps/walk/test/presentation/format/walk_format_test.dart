import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:walk/presentation/format/walk_format.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  test('걸음은 천 단위 구분', () {
    expect(WalkFormat.steps('ko', 6240), '6,240');
  });

  test('거리는 km 소수 한 자리, 없으면 –', () {
    expect(WalkFormat.distance('ko', 4310.5), '4.3 km');
    expect(WalkFormat.distance('ko', null), '–');
  });

  test('칼로리는 반올림한 정수 kcal, 없으면 –', () {
    expect(WalkFormat.kcal('ko', 182.6), '183 kcal');
    expect(WalkFormat.kcal('ko', null), '–');
  });

  test('주 · 월 · 요일 · 일 라벨', () {
    expect(
      WalkFormat.weekRange('ko', DateTime(2026, 9, 21), DateTime(2026, 9, 27)),
      '9월 21일 – 9월 27일',
    );
    expect(WalkFormat.month('ko', DateTime(2026, 9)), '2026년 9월');
    expect(WalkFormat.weekday('ko', DateTime(2026, 9, 21)), '월');
    expect(WalkFormat.day(DateTime(2026, 9, 5)), '5');
  });
}
