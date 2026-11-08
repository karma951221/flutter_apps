import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/location/entity/location_point.dart';
import 'package:walk/domain/location/entity/record_mode.dart';
import 'package:walk/domain/location/entity/record_retention.dart';
import 'package:walk/domain/location/recorder/location_recorder.dart';
import 'package:walk/domain/location/recorder/recorder_status.dart';
import 'package:walk/domain/location/repository/location_preferences.dart';
import 'package:walk/domain/location/repository/location_repository.dart';
import 'package:walk/domain/location/usecase/location_sync.dart';

class _Clock extends Clock {
  const _Clock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

class _Prefs implements LocationPreferences {
  _Prefs(this.retention);
  @override
  RecordRetention retention;
  @override
  Future<void> setRetention(RecordRetention value) async => retention = value;
}

class _Recorder implements LocationRecorder {
  _Recorder(int count) {
    for (var i = 1; i <= count; i++) {
      inbox[i] = LocationPoint(
        recordedAt: DateTime.utc(2026, 1, 1).add(Duration(seconds: i)),
        lat: 37 + i * 0.0001,
        lng: 127,
        mode: RecordMode.normal,
      );
    }
  }

  final inbox = <int, LocationPoint>{};
  int drains = 0;
  final acked = <int>[];
  bool failNextAck = false;

  @override
  Future<List<({int id, LocationPoint point})>> drain({
    int limit = 2000,
  }) async {
    drains++;
    await Future<void>.delayed(Duration.zero);
    final ids = inbox.keys.toList()..sort();
    return [for (final id in ids.take(limit)) (id: id, point: inbox[id]!)];
  }

  @override
  Future<void> clearInbox() async => inbox.clear();

  @override
  Future<void> ack(int upToId) async {
    if (failNextAck) {
      failNextAck = false;
      throw StateError('ack failed');
    }
    acked.add(upToId);
    inbox.removeWhere((id, _) => id <= upToId);
  }

  @override
  Future<RecorderStatus> status() async => const RecorderStatus.off();
  @override
  Future<void> start(RecordMode mode) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> setMode(RecordMode mode) async {}
  @override
  Future<void> openBatterySettings() async {}
}

class _Repo implements LocationRepository {
  final stored = <(DateTime, double, double)>{};
  int insertCalls = 0;
  final purges = <DateTime>[];

  @override
  Future<int> insertAll(List<LocationPoint> points) async {
    insertCalls++;
    var added = 0;
    for (final p in points) {
      if (stored.add((p.recordedAt, p.lat, p.lng))) added++;
    }
    return added;
  }

  @override
  Future<int> purgeBefore(DateTime cutoff) async {
    purges.add(cutoff);
    return 0;
  }

  @override
  Future<List<LocationPoint>> pointsBetween(DateTime from, DateTime to) async =>
      const [];
  @override
  Future<bool> hasAnyPoint() async => stored.isNotEmpty;
  @override
  Future<void> deleteAll() async {}
  @override
  Future<String?> placeName(String gridKey) async => null;
  @override
  Future<void> savePlaceName(String gridKey, String name) async {}
}

void main() {
  final now = DateTime(2026, 11, 8, 12);
  late _Repo repo;

  LocationSync sync(
    _Recorder recorder, [
    RecordRetention retention = RecordRetention.never,
  ]) {
    repo = _Repo();
    return LocationSync(recorder, repo, _Prefs(retention), _Clock(now));
  }

  test('drains until empty and acks last id', () async {
    final recorder = _Recorder(2500);
    final s = sync(recorder);

    final added = await s.run();

    expect(added, 2500);
    expect(repo.insertCalls, 2);
    expect(recorder.acked, [2000, 2500]);
    expect(recorder.inbox, isEmpty);
  });

  test('sync is idempotent when ack fails', () async {
    final recorder = _Recorder(10)..failNextAck = true;
    final s = sync(recorder);

    await expectLater(s.run(), throwsStateError);
    expect(repo.stored.length, 10);
    expect(recorder.inbox.length, 10);

    final added = await s.run();

    expect(added, 0);
    expect(repo.stored.length, 10);
    expect(recorder.inbox, isEmpty);
  });

  test('purges by retention after drain', () async {
    final s = sync(_Recorder(1), RecordRetention.oneYear);
    await s.run();
    expect(repo.purges, [DateTime(2025, 11, 8, 12)]);

    final never = sync(_Recorder(1));
    await never.run();
    expect(repo.purges, isEmpty);
  });

  test('concurrent run shares one pass', () async {
    final recorder = _Recorder(5);
    final s = sync(recorder);

    final results = await Future.wait([s.run(), s.run()]);

    expect(results, [5, 5]);
    expect(recorder.drains, 1);
    expect(repo.insertCalls, 1);
  });
}
