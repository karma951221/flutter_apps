import 'package:commute/app/router/settings_redirect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('설정이 미완성이면 홈에서 설정으로 보낸다', () {
    final redirect = SettingsRedirect(settingsComplete: false);

    expect(redirect.resolve(CommutePaths.home), CommutePaths.settings);
    expect(redirect.resolve(CommutePaths.settings), isNull);
  });

  test('설정이 완성되어 있으면 홈과 설정을 모두 허용한다', () {
    final redirect = SettingsRedirect(settingsComplete: true);

    expect(redirect.resolve(CommutePaths.home), isNull);
    expect(redirect.resolve(CommutePaths.settings), isNull);
  });

  test('설정을 마치면 홈 이동을 허용한다', () {
    final redirect = SettingsRedirect(settingsComplete: false);

    redirect.markComplete();

    expect(redirect.resolve(CommutePaths.home), isNull);
  });
}
