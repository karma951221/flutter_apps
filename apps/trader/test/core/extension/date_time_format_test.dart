import 'package:daylog/core/extension/date_time_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // UTC 로 만들면 실행 환경의 시간대에 따라 결과가 달라진다. 표기는 항상
  // `toLocal()` 을 거치므로 로컬 시각으로 만들어 비교한다.
  final value = DateTime(2026, 8, 5, 9, 7);

  test('게시물 표기는 연도까지 보여주고 두 자리로 맞춘다', () {
    expect(value.displayDateTime('ko'), '2026.08.05 09:07');
  });

  test('댓글 표기는 연도를 생략한다', () {
    expect(value.displayShortDateTime('ko'), '08.05 09:07');
  });

  test('두 표기 모두 로컬 시각을 쓴다', () {
    final utc = DateTime.utc(2026, 8, 5, 9, 7);
    expect(utc.displayDateTime('ko'), utc.toLocal().displayDateTime('ko'));
    expect(
      utc.displayShortDateTime('ko'),
      utc.toLocal().displayShortDateTime('ko'),
    );
  });

  test('영어와 일본어는 locale의 날짜 순서와 시각 표기를 쓴다', () {
    expect(value.displayDateTime('en'), contains('8/5/2026'));
    expect(value.displayDateTime('en'), contains('AM'));
    expect(value.displayDateTime('ja'), startsWith('2026/8/5'));
    expect(value.displayTimeOnly('ja'), isNotEmpty);
  });
}
