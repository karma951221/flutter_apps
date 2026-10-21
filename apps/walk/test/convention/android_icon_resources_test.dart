import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/alarm/package_alarm_scheduler.dart';

/// 알람 알림 작은 아이콘이 실제 drawable · 축소 보존 규칙과 같은 이름인지 본다.
/// 포크는 이름을 `getIdentifier` 로 찾고 없으면 조용히 다른 아이콘으로 넘어가 빌드 · 테스트로는 드러나지 않는다.
/// 스펙: docs/superpowers/specs/2026-10-05-walk-app-face-design.md
const _res = 'android/app/src/main/res';

void main() {
  const icon = PackageAlarmScheduler.notificationIcon;

  test('알림 아이콘 이름의 drawable 이 있다', () {
    expect(
      File('$_res/drawable/$icon.xml').existsSync(),
      isTrue,
      reason: '$_res/drawable/$icon.xml',
    );
  });

  test('raw/keep.xml 이 릴리스 리소스 축소에서 그 drawable 을 남긴다', () {
    final keep = File('$_res/raw/keep.xml').readAsStringSync();
    final kept = RegExp(r'tools:keep="([^"]*)"').firstMatch(keep)?.group(1) ?? '';

    expect(kept.split(',').map((e) => e.trim()), contains('@drawable/$icon'));
  });
}
