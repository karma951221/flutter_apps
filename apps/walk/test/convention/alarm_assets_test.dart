import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/alarm/entity/alarm_sound.dart';

/// 내장 알람음 경로가 실제 에셋 파일을 가리키는지 본다.
/// 경로가 틀리면 포크가 조용히 대체음(비프)으로 넘어가 빌드 · 단위 테스트로는 드러나지 않는다.
/// 스펙: docs/superpowers/specs/2026-11-16-walk-alarm-ringtone-design.md §5
void main() {
  test('목록의 모든 알람음 파일이 있다', () {
    for (final path in BundledAlarmSounds.all) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('ogg 알람음은 Ogg 컨테이너이고 합계 500KB 미만이다', () {
    final oggs = BundledAlarmSounds.all.where((p) => p.endsWith('.ogg')).toList();
    expect(oggs, hasLength(4));

    var total = 0;
    for (final path in oggs) {
      final bytes = File(path).readAsBytesSync();
      expect(String.fromCharCodes(bytes.take(4)), 'OggS', reason: path);
      total += bytes.length;
    }
    expect(total, lessThan(500 * 1024));
  });

  test('목록의 첫 소리는 아침 차임이다', () {
    expect(BundledAlarmSounds.all.first, BundledAlarmSounds.morning);
  });

  test('이미 걸린 회차가 가리키는 옛 wav 는 목록에 없어도 파일은 남아 있다', () {
    for (final path in [BundledAlarmSounds.legacyChime, BundledAlarmSounds.legacyRising]) {
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(BundledAlarmSounds.all, isNot(contains(path)));
    }
  });
}
