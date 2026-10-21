import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 통근 탭이 쓰는 네트워크 설정(인터넷 권한 · 서울 실시간 API 평문 허용 · 키 파일 무시)이 빠지지 않았는지 본다.
/// 서울 실시간 API 는 http 만 열려 있어 빠지면 릴리스에서만 조용히 실패한다.
const _main = 'android/app/src/main';

void main() {
  test('매니페스트가 INTERNET 권한과 networkSecurityConfig 를 선언한다', () {
    final manifest = File('$_main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android.permission.INTERNET'));
    expect(manifest, contains('@xml/network_security_config'));
  });

  test('평문 http 는 서울 실시간 API 도메인 하나만 허용한다', () {
    final xml = File('$_main/res/xml/network_security_config.xml').readAsStringSync();
    final block = RegExp(
      r'<domain-config cleartextTrafficPermitted="true">(.*?)</domain-config>',
      dotAll: true,
    ).firstMatch(xml);
    expect(block, isNotNull);
    expect(
      block!.group(1),
      contains('<domain includeSubdomains="false">swopenapi.seoul.go.kr</domain>'),
    );
    expect('<domain '.allMatches(xml).length, 1);
  });

  test('키 파일은 gitignore 된다', () {
    expect(File('.gitignore').readAsStringSync(), contains('/config/commute_keys.json'));
  });
}
