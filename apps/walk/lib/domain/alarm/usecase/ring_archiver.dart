import 'package:injectable/injectable.dart';

import '../entity/alarm.dart';
import '../entity/alarm_trigger.dart';
import '../entity/archived_ring.dart';
import '../ring_log/ring_archive.dart';
import '../ring_log/ring_log_source.dart';
import 'alarm_use_case.dart';

/// 네이티브 울림 기록을 그 알람의 라벨 · 시각과 함께 [RingArchive] 로 옮긴다.
@lazySingleton
class RingArchiver {
  RingArchiver(this._ringLog, this._archive, this._alarms);

  final RingLogSource _ringLog;
  final RingArchive _archive;
  final AlarmUseCase _alarms;

  /// 겹쳐 부르면 한 번에 하나씩 돈다([DefaultAlarmUseCase] 의 `_serial` 과 같은 패턴).
  Future<void> _tail = Future.value();

  Future<T> _serial<T>(Future<T> Function() body) {
    final result = _tail.then((_) => body());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<void> archive() => _serial(() async {
    final entries = await _ringLog.read(since: DateTime.fromMillisecondsSinceEpoch(0));
    final byId = <int, Alarm>{for (final a in await _alarms.list()) a.id: a};
    await _archive.saveAll([
      for (final e in entries)
        ArchivedRing(
          entry: e,
          label: byId[alarmIdOf(e.packageId)]?.label,
          hour: byId[alarmIdOf(e.packageId)]?.hour,
          minute: byId[alarmIdOf(e.packageId)]?.minute,
        ),
    ]);
  });
}
