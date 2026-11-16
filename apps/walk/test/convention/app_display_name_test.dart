import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

/// 앱 표시 이름은 런처(AndroidManifest `android:label`) · 앱 안 제목(l10n `walkAppTitle`) ·
/// 건강 데이터 안내 문구가 같은 이름을 쓴다. 모든 언어에서 영문 그대로다(2026-11-16 사용자 결정).
const _name = 'Life Log';
const _oldName = 'Life Tool';
const _main = 'android/app/src/main';

void main() {
  test('런처 라벨이 앱 이름이다', () {
    final manifest = File('$_main/AndroidManifest.xml').readAsStringSync();
    final label = RegExp(
      r'<application\b[^>]*android:label="([^"]*)"',
      dotAll: true,
    ).firstMatch(manifest)?.group(1);

    expect(label, _name);
  });

  test('앱 안 제목이 세 언어 모두 앱 이름이다', () {
    for (final locale in AppLocalizations.supportedLocales) {
      expect(
        lookupAppLocalizations(locale).walkAppTitle,
        _name,
        reason: '$locale',
      );
    }
  });

  test('건강 데이터 안내 문구가 앱 이름을 쓴다', () {
    for (final dir in ['values', 'values-ko', 'values-ja']) {
      final strings = File('$_main/res/$dir/strings.xml').readAsStringSync();
      expect(strings, contains(_name), reason: dir);
      expect(strings, isNot(contains(_oldName)), reason: dir);
    }
  });
}
