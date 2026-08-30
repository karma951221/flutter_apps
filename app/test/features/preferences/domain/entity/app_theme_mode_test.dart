import 'package:daylog/features/preferences/domain/entity/app_theme_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppThemeMode.fromCode', () {
    test('세 코드는 각각의 모드로 읽힌다', () {
      expect(AppThemeMode.fromCode('system'), AppThemeMode.system);
      expect(AppThemeMode.fromCode('light'), AppThemeMode.light);
      expect(AppThemeMode.fromCode('dark'), AppThemeMode.dark);
    });

    test('모르는 코드는 시스템으로 읽는다', () {
      // 선택지가 늘어난 버전에서 되돌아와도 앱이 죽지 않아야 한다.
      expect(AppThemeMode.fromCode('sepia'), AppThemeMode.system);
      expect(AppThemeMode.fromCode(''), AppThemeMode.system);
    });

    test('값이 없으면 시스템으로 읽는다', () {
      expect(AppThemeMode.fromCode(null), AppThemeMode.system);
    });
  });

  test('code 는 저장 형식과 같다', () {
    // 표시 이름은 domain 이 갖지 않는다 — ARB 에서 오므로 presentation 확장
    // AppThemeModeX.label(context) 의 몫이다.
    expect(AppThemeMode.system.code, 'system');
    expect(AppThemeMode.light.code, 'light');
    expect(AppThemeMode.dark.code, 'dark');
  });
}
