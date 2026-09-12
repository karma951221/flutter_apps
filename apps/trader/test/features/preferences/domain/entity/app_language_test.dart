import 'package:daylog/features/preferences/domain/entity/app_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLanguage.fromCode', () {
    test('네 코드는 각각의 언어로 읽힌다', () {
      expect(AppLanguage.fromCode('system'), AppLanguage.system);
      expect(AppLanguage.fromCode('ko'), AppLanguage.korean);
      expect(AppLanguage.fromCode('en'), AppLanguage.english);
      expect(AppLanguage.fromCode('ja'), AppLanguage.japanese);
    });

    test('모르는 코드는 시스템으로 읽는다', () {
      // 지원 언어가 늘어난 버전에서 되돌아와도 앱이 죽지 않아야 한다.
      expect(AppLanguage.fromCode('fr'), AppLanguage.system);
      expect(AppLanguage.fromCode(''), AppLanguage.system);
    });

    test('값이 없으면 시스템으로 읽는다', () {
      expect(AppLanguage.fromCode(null), AppLanguage.system);
    });
  });

  test('code 는 저장 형식과 같다', () {
    // 표시 이름은 domain 이 갖지 않는다 — presentation 확장 AppLanguageX 의 몫이다.
    expect(AppLanguage.system.code, 'system');
    expect(AppLanguage.korean.code, 'ko');
    expect(AppLanguage.english.code, 'en');
    expect(AppLanguage.japanese.code, 'ja');
  });
}
