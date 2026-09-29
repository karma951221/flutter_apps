import 'package:injectable/injectable.dart';

import '../../clock.dart';
import '../entity/alarm.dart';
import '../entity/alarm_trigger.dart';
import '../repository/alarm_repository.dart';
import '../scheduler/alarm_scheduler.dart';
import '../upcoming_triggers.dart';

/// 알람 정의와 패키지 예약을 함께 다룬다. 바꾸는 동작은 모두 끝에 [sync] 한다.
/// 권한 확인은 여기서 하지 않는다 — 화면이 `AlarmPermissions` 로 한다.
abstract interface class AlarmUseCase {
  /// 시각순(같으면 id 순).
  Future<List<Alarm>> list();

  Future<Alarm?> find(int alarmId);

  /// 울리는 회차의 알람(울림 화면 라벨용). 지워졌으면 null.
  Future<Alarm?> findByPackageId(int packageId);

  /// 켠 상태로 저장한다. `id == Alarm.unsavedId` 면 새 id(최대+1)를 준다.
  /// 1회성이면 지금 기준 다음 `hour:minute` 을 `oneShotAt` 으로 정한다.
  Future<Alarm> save(Alarm alarm);

  Future<void> delete(int alarmId);

  /// 없는 id 면 null.
  Future<Alarm?> toggle(int alarmId, {required bool enabled});

  /// 저장된 정의에 맞춰 패키지 예약을 채우고 지운다. 멱등이다.
  /// 앱 시작 · 복귀 · 울림 처리 뒤에 부른다.
  Future<void> sync();

  /// 울리는 회차를 [alarmSnoozeDuration] 뒤로 다시 건다.
  Future<void> snooze(int packageId);

  /// 울리는 회차를 끈다.
  Future<void> stop(int packageId);

  /// 켜진 알람마다 실제로 다음에 울릴 시각(알람 id → 시각). 규칙이 아니라 **패키지에 걸린
  /// 예약**에서 지금보다 뒤인 가장 이른 것을 고른다 — 스누즈된 회차가 들어가고, 권한 문제로
  /// 예약이 빠진 알람은 키가 없다.
  Future<Map<int, DateTime>> nextRings();
}

@LazySingleton(as: AlarmUseCase)
class DefaultAlarmUseCase implements AlarmUseCase {
  DefaultAlarmUseCase(this._repository, this._scheduler, this._clock);

  final AlarmRepository _repository;
  final AlarmScheduler _scheduler;
  final Clock _clock;

  /// 방금 울릴 때가 됐지만 아직 울림으로 잡히지 않은 회차를 지우지 않는 여유.
  /// (패키지 `checkAlarm` 의 30초 유예와 같은 이유 — 곧 울릴 알람을 지우는 쪽이 훨씬 나쁘다.)
  static const dueGrace = Duration(minutes: 1);

  /// 시작 · 복귀 · 저장이 겹쳐 부를 수 있어 한 번에 하나씩 돈다. 읽기([list] · [find] ·
  /// [nextRings])도 같은 줄에 선다 — 바꾸는 도중에 읽으면 패키지 예약은 이미 바뀌었는데
  /// 저장소는 아직인 순간을 본다. (울림 화면에서 끄면 패키지가 울림 스트림을 먼저 비워
  /// 화면이 걷히고, 목록이 `stop` 의 sync 가 1회성을 끄기 전에 다시 읽는다.)
  Future<void> _tail = Future.value();

  Future<T> _serial<T>(Future<T> Function() body) {
    final result = _tail.then((_) => body());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  @override
  Future<List<Alarm>> list() => _serial(() async => _sorted(await _repository.load()));

  @override
  Future<Alarm?> find(int alarmId) => _serial(() async => _byId(await _repository.load(), alarmId));

  @override
  Future<Alarm?> findByPackageId(int packageId) => find(alarmIdOf(packageId));

  @override
  Future<Alarm> save(Alarm alarm) => _serial(() async {
    final now = _clock.now();
    final alarms = await _repository.load();
    final id = alarm.id == Alarm.unsavedId ? _newId(alarms) : alarm.id;
    final saved = alarm.copyWith(
      id: id,
      enabled: true,
      oneShotAt: alarm.isOneShot ? nextOccurrence(alarm.hour, alarm.minute, now) : null,
    );
    final index = alarms.indexWhere((a) => a.id == id);
    await _repository.save([
      if (index < 0) ...[...alarms, saved] else
        for (final a in alarms) a.id == id ? saved : a,
    ]);
    // 시각 · 요일 · 라벨이 바뀌었을 수 있으니 이 알람의 예약을 비우고 다시 건다.
    await _cancelAll(id);
    await _sync();
    return saved;
  });

  @override
  Future<void> delete(int alarmId) => _serial(() async {
    final alarms = await _repository.load();
    await _repository.save([for (final a in alarms) if (a.id != alarmId) a]);
    await _cancelAll(alarmId);
    await _sync();
  });

  @override
  Future<Alarm?> toggle(int alarmId, {required bool enabled}) => _serial(() async {
    final alarms = await _repository.load();
    final alarm = _byId(alarms, alarmId);
    if (alarm == null) return null;
    final toggled = alarm.copyWith(
      enabled: enabled,
      oneShotAt: enabled && alarm.isOneShot
          ? nextOccurrence(alarm.hour, alarm.minute, _clock.now())
          : alarm.oneShotAt,
    );
    await _repository.save([for (final a in alarms) a.id == alarmId ? toggled : a]);
    // 끌 때는 스누즈된 회차까지 지운다. sync 는 스누즈 회차를 남기기 때문이다.
    await _cancelAll(alarmId);
    await _sync();
    return toggled;
  });

  @override
  Future<void> sync() => _serial(_sync);

  @override
  Future<void> snooze(int packageId) => _serial(() async {
    final alarm = _byId(await _repository.load(), alarmIdOf(packageId));
    if (alarm == null) {
      await _scheduler.stop(packageId);
    } else {
      await _scheduler.schedule(packageId, _clock.now().add(alarmSnoozeDuration), alarm);
    }
    await _sync();
  });

  @override
  Future<void> stop(int packageId) => _serial(() async {
    await _scheduler.stop(packageId);
    await _sync();
  });

  @override
  Future<Map<int, DateTime>> nextRings() => _serial(() async {
    final now = _clock.now();
    final enabled = {for (final a in await _repository.load()) if (a.enabled) a.id};
    final next = <int, DateTime>{};
    for (final MapEntry(key: id, value: at) in (await _scheduler.scheduled()).entries) {
      final alarmId = alarmIdOf(id);
      if (!enabled.contains(alarmId) || !at.isAfter(now)) continue;
      final earliest = next[alarmId];
      if (earliest == null || at.isBefore(earliest)) next[alarmId] = at;
    }
    return next;
  });

  Future<void> _sync() async {
    final now = _clock.now();
    // 1회성을 끌지는 남은 예약(스누즈)을 보고 정하므로 예약부터 읽는다.
    final scheduled = await _scheduler.scheduled();
    final ringing = await _scheduler.ringingIds();
    final alarms = await _expireOneShots(await _repository.load(), now, scheduled, ringing);

    final desired = {
      for (final alarm in alarms)
        for (final trigger in triggersOf(alarm, now)) trigger.packageId: (trigger, alarm),
    };
    // 꺼진 알람의 회차는 곧 울릴 참이어도 남기지 않는다 — 꺼 둔 알람이 울리면 안 된다.
    final enabledIds = {for (final a in alarms) if (a.enabled) a.id};

    for (final MapEntry(key: id, value: at) in scheduled.entries) {
      if (desired.containsKey(id) || ringing.contains(id)) continue;
      // 스누즈된 회차(또는 막 울릴 참인 회차)는 원래 회차가 지나 원하는 목록에 없다.
      // 알람이 켜져 있고 시각이 스누즈 간격 안이면 둔다. 끄기 · 삭제 · 수정은 [_cancelAll] 로 지운다.
      final snoozedOrDue =
          at.isAfter(now.subtract(dueGrace)) && !at.isAfter(now.add(alarmSnoozeDuration));
      if (enabledIds.contains(alarmIdOf(id)) && snoozedOrDue) continue;
      await _scheduler.cancel(id);
    }
    for (final MapEntry(key: id, value: (trigger, alarm)) in desired.entries) {
      if (ringing.contains(id) || scheduled[id] == trigger.at) continue;
      await _scheduler.schedule(id, trigger.at, alarm);
    }
  }

  /// 시각이 지난 1회성은 끈다. 단, 그 알람의 회차가 아직 울리는 중이거나 지금 뒤에 걸려
  /// 있으면(스누즈) 둔다 — 스누즈 중에 스위치가 꺼지고 요약 카드에서 사라지지 않게.
  /// 울림이 끝나(끄기) 남은 예약이 없어진 뒤의 sync 에서 꺼진다.
  Future<List<Alarm>> _expireOneShots(
    List<Alarm> alarms,
    DateTime now,
    Map<int, DateTime> scheduled,
    Set<int> ringing,
  ) async {
    final pending = {
      for (final MapEntry(key: id, value: at) in scheduled.entries)
        if (at.isAfter(now) || ringing.contains(id)) alarmIdOf(id),
    };
    bool expired(Alarm a) =>
        a.enabled &&
        a.isOneShot &&
        !(a.oneShotAt?.isAfter(now) ?? false) &&
        !pending.contains(a.id);
    if (!alarms.any(expired)) return alarms;
    final updated = [for (final a in alarms) expired(a) ? a.copyWith(enabled: false) : a];
    await _repository.save(updated);
    return updated;
  }

  /// 이 알람의 패키지 예약을 모두 지운다. 울리는 중인 회차는 둔다.
  Future<void> _cancelAll(int alarmId) async {
    final scheduled = await _scheduler.scheduled();
    final ringing = await _scheduler.ringingIds();
    for (final id in scheduled.keys) {
      if (alarmIdOf(id) == alarmId && !ringing.contains(id)) await _scheduler.cancel(id);
    }
  }

  int _newId(List<Alarm> alarms) {
    final used = {for (final a in alarms) a.id};
    final max = used.fold(0, (m, id) => id > m ? id : m);
    if (max < Alarm.maxId) return max + 1;
    for (var id = 1; id <= Alarm.maxId; id++) {
      if (!used.contains(id)) return id;
    }
    throw StateError('알람은 ${Alarm.maxId}개까지 만들 수 있다');
  }

  static Alarm? _byId(List<Alarm> alarms, int id) {
    for (final a in alarms) {
      if (a.id == id) return a;
    }
    return null;
  }

  static List<Alarm> _sorted(List<Alarm> alarms) => [...alarms]
    ..sort((a, b) {
      final byTime = (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
}
