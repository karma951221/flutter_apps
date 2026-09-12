import 'package:daylog/core/data/nickname_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('escapeLikePattern', () {
    test('LIKE 메타문자를 리터럴로 바꾼다', () {
      expect(NicknameMatch.escapeLikePattern('a%'), r'a\%');
      expect(NicknameMatch.escapeLikePattern('a_ice'), r'a\_ice');
      expect(NicknameMatch.escapeLikePattern(r'a\b'), r'a\\b');
    });

    test('역슬래시를 먼저 바꿔서 이스케이프를 두 번 씌우지 않는다', () {
      // 순서가 반대면 `\%` 의 역슬래시까지 다시 이스케이프돼 `\\%` 가 된다.
      expect(NicknameMatch.escapeLikePattern(r'100\%'), r'100\\\%');
    });

    test('평범한 닉네임은 그대로 둔다', () {
      expect(NicknameMatch.escapeLikePattern('카르마'), '카르마');
      expect(NicknameMatch.escapeLikePattern('alice'), 'alice');
    });
  });

  group('isSameNickname', () {
    test('lower(nickname) 유일 인덱스와 같은 기준으로 견준다', () {
      expect(NicknameMatch.isSameNickname('Alice', 'alice'), isTrue);
      expect(NicknameMatch.isSameNickname('ALICE', 'aLiCe'), isTrue);
    });

    test('앞뒤 공백은 무시한다', () {
      expect(NicknameMatch.isSameNickname(' alice ', 'alice'), isTrue);
    });

    test('와일드카드는 리터럴로 견준다 — a_ice 는 alice 가 아니다', () {
      expect(NicknameMatch.isSameNickname('alice', 'a_ice'), isFalse);
      expect(NicknameMatch.isSameNickname('alice', 'a%'), isFalse);
      expect(NicknameMatch.isSameNickname('alpha', 'a*'), isFalse);
    });

    test('같은 와일드카드 문자를 쓰는 닉네임끼리는 매칭된다', () {
      expect(NicknameMatch.isSameNickname('a%', 'a%'), isTrue);
    });
  });
}
