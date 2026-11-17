import 'package:flutter_test/flutter_test.dart';
import 'package:walk/core/config/commute_api_keys.dart';

void main() {
  test('둘 다 채워지면 isComplete', () {
    expect(const CommuteApiKeys(odsay: 'a', seoulSubway: 'b').isComplete, isTrue);
  });

  test('하나라도 비거나 공백이면 isComplete 가 아니다', () {
    expect(const CommuteApiKeys(odsay: '', seoulSubway: 'b').isComplete, isFalse);
    expect(const CommuteApiKeys(odsay: 'a', seoulSubway: '  ').isComplete, isFalse);
  });

  test('dart-define 이 없으면 fromEnvironment 는 빈 키', () {
    final keys = CommuteApiKeys.fromEnvironment();
    expect(keys.odsay, isEmpty);
    expect(keys.seoulSubway, isEmpty);
    expect(keys.isComplete, isFalse);
  });
}
