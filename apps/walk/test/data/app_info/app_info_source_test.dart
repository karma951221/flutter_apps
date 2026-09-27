import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:walk/data/app_info/app_info_source.dart';

void main() {
  test('버전은 "이름 (빌드번호)"', () async {
    PackageInfo.setMockInitialValues(
      appName: 'walk',
      packageName: 'com.karma.walk',
      version: '1.0.0',
      buildNumber: '7',
      buildSignature: '',
    );

    expect(await PackageInfoAppInfoSource().version(), '1.0.0 (7)');
  });
}
