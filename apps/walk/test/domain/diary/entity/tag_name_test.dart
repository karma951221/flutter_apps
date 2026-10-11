import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/tag_name.dart';

void main() {
  group('TagName.normalize', () {
    test('앞뒤 공백 · # 를 지우고 소문자로 만든다', () {
      expect(TagName.normalize('  #Jeju '), 'jeju');
    });
    test('# 여러 개와 안쪽 공백을 지운다', () {
      expect(TagName.normalize('##제 주'), '제주');
    });
    test('# 뿐이거나 빈 문자열은 null', () {
      expect(TagName.normalize('#'), isNull);
      expect(TagName.normalize(''), isNull);
      expect(TagName.normalize('   '), isNull);
    });
    test('30자는 되고 31자는 null', () {
      expect(TagName.normalize('a' * 30), 'a' * 30);
      expect(TagName.normalize('a' * 31), isNull);
    });
    test('대소문자만 다른 입력은 같은 값', () {
      expect(TagName.normalize('#JEJU'), TagName.normalize('jeju'));
    });
    test('이모지는 그대로 둔다', () {
      expect(TagName.normalize('#🍊귤'), '🍊귤');
    });
  });
}
