import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/location/entity/record_interval.dart';
import 'package:walk/domain/location/entity/record_mode.dart';
import 'package:walk/domain/location/recorder/recorder_status.dart';

void main() {
  test('평소는 normal 모드, 고정 주기는 dense 모드', () {
    expect(RecordInterval.normal.mode, RecordMode.normal);
    expect(RecordInterval.normal.seconds, isNull);
    for (final i in RecordInterval.values.skip(1)) {
      expect(i.mode, RecordMode.dense);
      expect(i.seconds, greaterThanOrEqualTo(RecordInterval.minSeconds));
    }
  });

  test('예전 설정 이전: normal → 평소, dense(주기 없음 = 5초) → 5초', () {
    expect(
      recordIntervalOf(
        const RecorderStatus.running(RecordMode.normal, stillDetection: true),
      ),
      RecordInterval.normal,
    );
    expect(
      recordIntervalOf(
        const RecorderStatus.running(RecordMode.dense, stillDetection: false),
      ),
      RecordInterval.s5,
    );
    expect(
      recordIntervalOf(const RecorderStatus.blocked(RecordMode.dense)),
      RecordInterval.s5,
    );
    expect(recordIntervalOf(const RecorderStatus.off()), isNull);
  });

  test('프리셋에 없는 초는 가장 가까운 프리셋', () {
    expect(RecordInterval.of(RecordMode.dense, 10), RecordInterval.s10);
    expect(RecordInterval.of(RecordMode.dense, 20), RecordInterval.s10);
    expect(RecordInterval.of(RecordMode.dense, 45), RecordInterval.s30);
    expect(RecordInterval.of(RecordMode.dense, 600), RecordInterval.m1);
    // 평소 모드면 저장된 주기와 상관없이 평소.
    expect(RecordInterval.of(RecordMode.normal, 30), RecordInterval.normal);
  });
}
