import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/draft/draft_length.dart';

void main() {
  String memo(int chars) => '가' * chars;

  group('DraftLength.of', () {
    test('기본은 2~4문장', () {
      final length = DraftLength.of(memo: memo(40), photoCount: 2);

      expect((length.min, length.max), (2, 4));
      expect(length.polishMemo, isFalse);
    });

    test('메모가 20자 이하이고 사진이 1장 이하면 1~2문장', () {
      for (final photos in [0, 1]) {
        final length = DraftLength.of(memo: memo(20), photoCount: photos);
        expect((length.min, length.max), (1, 2), reason: '사진 $photos');
      }
    });

    test('짧은 메모라도 사진이 2장이면 기본', () {
      final length = DraftLength.of(memo: memo(20), photoCount: 2);

      expect((length.min, length.max), (2, 4));
    });

    test('메모가 21자면 사진이 없어도 기본', () {
      final length = DraftLength.of(memo: memo(21), photoCount: 0);

      expect((length.min, length.max), (2, 4));
    });

    test('메모 앞뒤 공백은 세지 않는다', () {
      final length = DraftLength.of(memo: '  ${memo(20)}  ', photoCount: 0);

      expect((length.min, length.max), (1, 2));
    });

    test('사진이 4장 이상이면 최대 6문장, 메모를 다듬으라고 하지는 않는다', () {
      final three = DraftLength.of(memo: memo(5), photoCount: 3);
      final four = DraftLength.of(memo: memo(5), photoCount: 4);

      expect((three.min, three.max), (2, 4));
      expect((four.min, four.max), (3, 6));
      expect(four.polishMemo, isFalse);
    });

    test('메모가 100자 이상이면 최대 6문장이고 메모를 다듬는다', () {
      final under = DraftLength.of(memo: memo(99), photoCount: 0);
      final at = DraftLength.of(memo: memo(100), photoCount: 0);

      expect((under.min, under.max), (2, 4));
      expect(under.polishMemo, isFalse);
      expect((at.min, at.max), (3, 6));
      expect(at.polishMemo, isTrue);
    });
  });
}
