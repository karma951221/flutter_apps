import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/location/entity/location_point.dart';
import 'package:walk/domain/location/entity/record_mode.dart';
import 'package:walk/domain/location/recorder/recorder_status.dart';
import 'package:walk/domain/location/usecase/open_end.dart';

LocationPoint _p(DateTime at, {bool still = false}) => LocationPoint(
  recordedAt: at,
  lat: 37.5,
  lng: 127,
  mode: RecordMode.normal,
  stillStart: still,
);

void main() {
  final now = DateTime.utc(2026, 11, 16, 12);
  final since = DateTime.utc(2026, 11, 16, 8);

  test('기록 중 · 마지막 점이 정지 감지 점 · since 이후면 지금까지 잇는다', () {
    final end = stayOpenEnd(
      [_p(DateTime.utc(2026, 11, 16, 9), still: true)],
      RecorderStatus.running(
        RecordMode.normal,
        stillDetection: true,
        recordingSince: since,
      ),
      now,
    );
    expect(end, now);
  });

  test('정지 감지가 켜져 있는데 마지막 점이 정지 감지 점이 아니면 잇지 않는다', () {
    expect(
      stayOpenEnd(
        [_p(DateTime.utc(2026, 11, 16, 9))],
        RecorderStatus.running(
          RecordMode.normal,
          stillDetection: true,
          recordingSince: since,
        ),
        now,
      ),
      isNull,
    );
  });

  test('정지 감지가 꺼져 있으면 마지막 점이 보통 점이어도 잇는다', () {
    expect(
      stayOpenEnd(
        [_p(DateTime.utc(2026, 11, 16, 9))],
        RecorderStatus.running(
          RecordMode.normal,
          stillDetection: false,
          recordingSince: since,
        ),
        now,
      ),
      now,
    );
  });

  test('마지막 점이 since 보다 5분 넘게 앞서면 잇지 않는다', () {
    expect(
      stayOpenEnd(
        [_p(since.subtract(const Duration(minutes: 6)), still: true)],
        RecorderStatus.running(
          RecordMode.normal,
          stillDetection: true,
          recordingSince: since,
        ),
        now,
      ),
      isNull,
    );
  });

  test('꺼짐 · since 없음 · 점 없음은 null', () {
    final pts = [_p(DateTime.utc(2026, 11, 16, 9), still: true)];
    expect(stayOpenEnd(pts, const RecorderStatus.off(), now), isNull);
    expect(
      stayOpenEnd(
        pts,
        const RecorderStatus.running(RecordMode.normal, stillDetection: true),
        now,
      ),
      isNull,
    );
    expect(
      stayOpenEnd(
        const [],
        RecorderStatus.running(
          RecordMode.normal,
          stillDetection: true,
          recordingSince: since,
        ),
        now,
      ),
      isNull,
    );
  });
}
