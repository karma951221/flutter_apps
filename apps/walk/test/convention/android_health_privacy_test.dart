import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Health Connect 권한 창의 "개인정보처리방침"(VIEW_PERMISSION_USAGE) · 이유 보기
/// (ACTION_SHOW_PERMISSIONS_RATIONALE) 링크가 앱을 한 번 더 띄우지 않는지 본다.
/// 두 인텐트가 MainActivity(또는 그 별칭)로 가면 Health Connect 의 태스크 위에 Flutter 앱이
/// 새로 떠 권한 창이 겹친다(2026-10-21 QA ⑦, 에뮬레이터 API 37).
const _main = 'android/app/src/main';

final _manifest = File('$_main/AndroidManifest.xml').readAsStringSync();

/// [action] 을 받는 `<activity>` · `<activity-alias>` 블록들.
List<String> _handlers(String action) => RegExp(
  r'<(activity|activity-alias)\b.*?</\1>',
  dotAll: true,
).allMatches(_manifest).map((m) => m.group(0)!).where((block) {
  return block.contains('android:name="$action"');
}).toList();

String _attr(String block, String name) =>
    RegExp('android:$name="([^"]*)"').firstMatch(block)?.group(1) ?? '';

void main() {
  for (final action in [
    'android.intent.action.VIEW_PERMISSION_USAGE',
    'androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE',
  ]) {
    test('$action 은 MainActivity 가 아닌 개인정보 안내 화면이 받는다', () {
      final handlers = _handlers(action);

      expect(handlers, isNotEmpty, reason: '받는 화면이 없으면 링크가 죽는다');
      for (final block in handlers) {
        expect(_attr(block, 'targetActivity'), isNot('.MainActivity'));
        expect(
          RegExp(r'<activity\b[^>]*android:name="\.MainActivity"').hasMatch(block),
          isFalse,
        );
        final target = block.startsWith('<activity-alias')
            ? _attr(block, 'targetActivity')
            : _attr(block, 'name');
        expect(target, '.HealthPrivacyActivity');
      }
    });
  }

  test('개인정보 안내 문구가 세 언어에 있다', () {
    for (final dir in ['values', 'values-ko', 'values-ja']) {
      final strings = File('$_main/res/$dir/strings.xml').readAsStringSync();
      expect(strings, contains('name="health_privacy_title"'), reason: dir);
      expect(strings, contains('name="health_privacy_body"'), reason: dir);
    }
  });
}
