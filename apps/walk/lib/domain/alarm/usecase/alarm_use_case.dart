import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../entity/alarm.dart';
import '../entity/alarm_pause.dart';
import '../../settings/repository/settings_repository.dart';
import '../entity/alarm_reminder.dart';
import '../entity/alarm_trigger.dart';
import '../holiday/holiday_calendar.dart';
import '../repository/alarm_repository.dart';
import '../scheduler/alarm_scheduler.dart';
import '../scheduler/reminder_scheduler.dart';
import '../reminders.dart';
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
  /// 1회성이면 넘어온 `oneShotAt` 이 미래면 그대로 쓰고, 없거나 지났으면 지금 기준 다음
  /// `hour:minute` 으로 정한다. `hour` · `minute` 는 정한 `oneShotAt` 에 맞춘다.
  /// `skippedAt` 은 저장한 정의에도 그 회차가 있을 때만 남긴다(시각 · 요일을 바꾸면 지운다).
  Future<Alarm> save(Alarm alarm);

  Future<void> delete(int alarmId);

  /// 없는 id 면 null.
  Future<Alarm?> toggle(int alarmId, {required bool enabled});

  /// 저장된 정의에 맞춰 패키지 예약을 채우고 지운다. 멱등이다.
  /// 앱 시작 · 복귀 · 울림 처리 뒤에 부른다.
  Future<void> sync();

  /// 기기 시간대가 바뀌었다. 패키지 예약을 새 시간대의 벽시계로 옮겨 건 뒤 [sync] 한다.
  Future<void> timeZoneChanged();

  /// 울리는 회차를 알람의 스누즈 간격(`Alarm.snoozeMinutes`) 뒤로, 스누즈 횟수를 하나 올려
  /// 다시 건다. 알람이 지워졌거나 꺼졌거나 스누즈 한도를 다 썼으면([canSnooze] 가 false) 멈춘다.
  Future<void> snooze(int packageId);

  /// 울리는 회차를 지금 스누즈할 수 있는가(울림 화면 버튼 표시용). 알람이 켜져 있고
  /// 스누즈 한도가 없거나 그 회차가 센 횟수가 한도보다 적어야 한다.
  Future<bool> canSnooze(int packageId);

  /// 반복 알람의 다음 회차 하나를 건너뛴다(`Alarm.skippedAt`). 이미 건너뛴 것이 있으면 그것을
  /// 다음 회차로 바꾼다. 1회성 · 꺼진 알람은 그대로 돌려준다. 없는 id 면 null.
  Future<Alarm?> skipNext(int alarmId);

  /// 건너뛰기를 취소한다. 없는 id 면 null.
  Future<Alarm?> unskip(int alarmId);

  /// 회차 하나를 쉰다(미리 알림의 [이번만 끄기] · [다음 알람 건너뛰기]). 반복이면 그 회차를
  /// `skippedAt` 으로, 1회성이면 알람을 끈다. 그 회차의 예약은 곧 울릴 참이어도 지운다.
  Future<void> skipOccurrence(int packageId);

  /// 울리는 회차를 끈다.
  Future<void> stop(int packageId);

  /// 모든 알람을 쉬는 기간(`AppSettings.pause`). 쉬지 않거나 끝 날이 지났으면 null.
  Future<AlarmPause?> pause();

  /// 쉬는 기간을 정한다(null 이면 그만 쉰다). 저장한 뒤 그 기간 회차의 예약을 — 곧 울릴 참이어도 —
  /// 지우고 sync 한다. 울리는 중인 회차는 둔다. 스위치는 건드리지 않는다.
  Future<void> setPause(AlarmPause? pause);

  /// 켜진 알람마다 실제로 다음에 울릴 시각(알람 id → 시각). 규칙이 아니라 **패키지에 걸린
  /// 예약**에서 지금보다 뒤인 가장 이른 것을 고른다 — 스누즈된 회차가 들어가고, 권한 문제로
  /// 예약이 빠진 알람은 키가 없다.
  Future<Map<int, DateTime>> nextRings();
}

@LazySingleton(as: AlarmUseCase)
class DefaultAlarmUseCase implements AlarmUseCase {
  DefaultAlarmUseCase(
    this._repository,
    this._scheduler,
    this._clock,
    this._reminders,
    this._holidays,
    this._settings,
  );

  final AlarmRepository _repository;
  final AlarmScheduler _scheduler;
  final Clock _clock;
  final ReminderScheduler _reminders;
  final HolidayCalendar _holidays;

  /// 공휴일 미리 알림 설정(`AppSettings.holidayReminder`) · 쉬는 기간(`AppSettings.pause`)을 읽는다.
  final SettingsRepository _settings;

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
    // 1회성: 화면이 정한 oneShotAt 이 미래면 그대로(초까지), 없거나 지났으면 다음 hour:minute.
    // hour · minute 는 정해진 시각에 맞춘다(목록 표시용).
    final given = alarm.oneShotAt;
    final oneShotAt = !alarm.isOneShot
        ? null
        : given != null && given.isAfter(now)
        ? given
        : nextOccurrence(alarm.hour, alarm.minute, now);
    final defined = alarm.copyWith(
      id: id,
      hour: oneShotAt?.hour ?? alarm.hour,
      minute: oneShotAt?.minute ?? alarm.minute,
      enabled: true,
      oneShotAt: oneShotAt,
      skippedAt: null,
    );
    // 건너뛰기는 새 정의에도 그 회차가 있을 때만 남긴다. 시각 · 요일을 바꿔 옛 회차가 없어지면
    // 지운다 — 남기면 아무것도 건너뛰지 않으면서 "건너뜀" 으로 보이고, 시각을 되돌리면 되살아난다.
    final skippedAt = alarm.skippedAt;
    final saved = skippedAt != null &&
            !defined.isOneShot &&
            upcomingTriggers(defined, now).any(skippedAt.isAtSameMomentAs)
        ? defined.copyWith(skippedAt: skippedAt)
        : defined;
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
  Future<void> timeZoneChanged() => _serial(() async {
    await _scheduler.rearmAll();
    await _sync();
  });

  @override
  Future<void> snooze(int packageId) => _serial(() async {
    final alarm = _byId(await _repository.load(), alarmIdOf(packageId));
    final count = await _scheduler.snoozeCountOf(packageId);
    // 지워졌거나 꺼진 알람은 다시 걸지 않고 멈춘다 — 꺼 둔 알람이 5분 뒤에 또 울리면 안 된다.
    // 한도를 다 쓴 회차도 멈춘다(울림 화면은 버튼을 숨기지만 늦게 눌린 경우).
    if (alarm == null || !_snoozable(alarm, count)) {
      await _scheduler.stop(packageId);
    } else {
      await _scheduler.schedule(
        packageId,
        _clock.now().add(Duration(minutes: alarm.snoozeMinutes)),
        alarm,
        snoozeCount: count + 1,
      );
    }
    await _sync();
  });

  @override
  Future<bool> canSnooze(int packageId) => _serial(() async {
    final alarm = _byId(await _repository.load(), alarmIdOf(packageId));
    return alarm != null && _snoozable(alarm, await _scheduler.snoozeCountOf(packageId));
  });

  static bool _snoozable(Alarm alarm, int count) {
    final limit = alarm.snoozeLimit;
    return alarm.enabled && (limit == null || count < limit);
  }

  @override
  Future<Alarm?> skipNext(int alarmId) => _serial(() async {
    final alarm = _byId(await _repository.load(), alarmId);
    if (alarm == null || alarm.isOneShot || !alarm.enabled) return alarm;
    final next = upcomingTriggers(alarm.copyWith(skippedAt: null), _clock.now()).firstOrNull;
    if (next == null) return alarm;
    return _skip(alarm, next);
  });

  @override
  Future<Alarm?> unskip(int alarmId) => _serial(() async {
    final alarm = _byId(await _repository.load(), alarmId);
    if (alarm == null) return null;
    final updated = alarm.copyWith(skippedAt: null);
    await _put(updated);
    await _sync();
    return updated;
  });

  @override
  Future<void> skipOccurrence(int packageId) => _serial(() async {
    final alarm = _byId(await _repository.load(), alarmIdOf(packageId));
    if (alarm == null) {
      await _cancelUnlessRinging(packageId);
      await _sync();
      return;
    }
    if (alarm.isOneShot) {
      await _put(alarm.copyWith(enabled: false));
      await _cancelUnlessRinging(packageId);
      await _sync();
      return;
    }
    // 규칙의 회차 시각. 이미 규칙에 없으면(건너뛴 뒤 · 지난 회차) 걸린 예약의 시각을 쓴다.
    final now = _clock.now();
    final at =
        triggersOf(alarm.copyWith(skippedAt: null), now)
            .where((t) => t.packageId == packageId)
            .firstOrNull
            ?.at ??
        (await _scheduler.scheduled())[packageId]?.at;
    if (at == null || !at.isAfter(now)) {
      await _cancelUnlessRinging(packageId);
      await _sync();
      return;
    }
    await _skip(alarm, at);
  });

  /// [alarm] 의 [at] 회차를 건너뛰어 저장하고, 그 회차의 예약을 지운 뒤 sync 한다.
  /// sync 는 스누즈 보존 창 안의 회차를 남기므로 명시적으로 지운다.
  Future<Alarm> _skip(Alarm alarm, DateTime at) async {
    final updated = alarm.copyWith(skippedAt: at);
    await _put(updated);
    await _cancelUnlessRinging(packageId(alarm.id, triggerIndex(at)));
    await _sync();
    return updated;
  }

  /// 저장소의 같은 id 알람을 [alarm] 으로 바꾼다.
  Future<void> _put(Alarm alarm) async {
    final alarms = await _repository.load();
    await _repository.save([for (final a in alarms) a.id == alarm.id ? alarm : a]);
  }

  Future<void> _cancelUnlessRinging(int packageId) async {
    if ((await _scheduler.ringingIds()).contains(packageId)) return;
    if ((await _scheduler.scheduled()).containsKey(packageId)) await _scheduler.cancel(packageId);
  }

  @override
  Future<void> stop(int packageId) => _serial(() async {
    await _scheduler.stop(packageId);
    await _sync();
  });

  @override
  Future<AlarmPause?> pause() => _serial(() async {
    final pause = _settings.load().pause;
    return pause == null || pause.isOver(_clock.now()) ? null : pause;
  });

  @override
  Future<void> setPause(AlarmPause? pause) => _serial(() async {
    await _settings.save(_settings.load().copyWith(pause: pause));
    if (pause != null) {
      // sync 는 스누즈 보존 창 안의 회차를 남기므로 기간 회차를 명시적으로 지운다.
      final ringing = await _scheduler.ringingIds();
      for (final MapEntry(key: id, value: (:at, signature: _)) in (await _scheduler.scheduled()).entries) {
        if (pause.contains(at) && !ringing.contains(id)) await _scheduler.cancel(id);
      }
    }
    await _sync();
  });

  @override
  Future<Map<int, DateTime>> nextRings() => _serial(() async {
    final now = _clock.now();
    final enabled = {for (final a in await _repository.load()) if (a.enabled) a.id};
    final next = <int, DateTime>{};
    for (final MapEntry(key: id, value: (:at, signature: _)) in (await _scheduler.scheduled()).entries) {
      final alarmId = alarmIdOf(id);
      if (!enabled.contains(alarmId) || !at.isAfter(now)) continue;
      final earliest = next[alarmId];
      if (earliest == null || at.isBefore(earliest)) next[alarmId] = at;
    }
    return next;
  });

  Future<void> _sync() async {
    final now = _clock.now();
    final pause = await _currentPause(now);
    // 1회성을 끌지는 남은 예약(스누즈)을 보고 정하므로 예약부터 읽는다.
    final scheduled = await _scheduler.scheduled();
    final ringing = await _scheduler.ringingIds();
    final alarms = await _expireOneShots(
      await _clearPastSkips(await _repository.load(), now),
      now,
      scheduled,
      ringing,
    );

    final desired = {
      for (final alarm in alarms)
        for (final trigger in triggersOf(alarm, now, pause: pause))
          trigger.packageId: (trigger, alarm),
    };
    // 꺼진 알람의 회차는 곧 울릴 참이어도 남기지 않는다 — 꺼 둔 알람이 울리면 안 된다.
    // 켜진 알람은 스누즈 보존 창을 알람의 스누즈 간격으로 잡는다.
    final enabled = {for (final a in alarms) if (a.enabled) a.id: a};

    for (final MapEntry(key: id, value: (:at, signature: _)) in scheduled.entries) {
      if (desired.containsKey(id) || ringing.contains(id)) continue;
      // 스누즈된 회차(또는 막 울릴 참인 회차)는 원래 회차가 지나 원하는 목록에 없다.
      // 알람이 켜져 있고 시각이 스누즈 간격 안이면 둔다. 끄기 · 삭제 · 수정은 [_cancelAll] 로 지운다.
      final alarm = enabled[alarmIdOf(id)];
      final snoozedOrDue =
          alarm != null &&
          at.isAfter(now.subtract(dueGrace)) &&
          !at.isAfter(now.add(Duration(minutes: alarm.snoozeMinutes)));
      if (snoozedOrDue) continue;
      await _scheduler.cancel(id);
    }
    // 시각이 같아도 지문이 다르면(설정이 바뀌었거나 지문 없는 옛 회차) 지금 설정으로 다시 건다.
    for (final MapEntry(key: id, value: (trigger, alarm)) in desired.entries) {
      if (ringing.contains(id)) continue;
      if (scheduled[id] == (at: trigger.at, signature: _scheduler.signatureOf(alarm))) continue;
      await _scheduler.schedule(id, trigger.at, alarm);
    }
    await _syncReminders(alarms, now, pause);
  }

  /// 설정의 쉬는 기간. 끝 날이 지났으면 설정에서 지우고 null.
  Future<AlarmPause?> _currentPause(DateTime now) async {
    final settings = _settings.load();
    final pause = settings.pause;
    if (pause == null || !pause.isOver(now)) return pause;
    await _settings.save(settings.copyWith(pause: null));
    return null;
  }

  /// 미리 알림을 알람 정의에 맞춘다(웨이브 3 스펙 §3.3). 실패는 삼킨다 — 미리 알림 때문에
  /// 알람 예약이 실패하면 안 된다.
  ///
  /// 이미 떠 있는(띄울 시각이 지난) 미리 알림은 그 회차가 아직 있고 종류가 여전히 켜져 있으며
  /// 울릴 시각이 그대로면 둔다 — 원하는 목록은 "아직 띄울 것"만 담아(soon 은 리드 안이면 만들지
  /// 않는다) 거기서 빠지지만 지우면 사용자가 보던 알림이 사라진다. 다시 걸지도 않는다(같은 알림이
  /// 또 뜬다). id 는 회차(날짜)로만 정해지므로 알람 시각을 바꾸면 울릴 시각으로 가린다: 바뀌었으면
  /// 옛 시각을 보여 주는 알림을 지금 정의로 다시 걸거나(원하는 목록에 있을 때) 지운다.
  Future<void> _syncReminders(List<Alarm> alarms, DateTime now, AlarmPause? pause) async {
    try {
      final holidayReminder = _settings.load().holidayReminder;
      final desired = <int, (AlarmReminder, Alarm)>{};
      // id → 울릴 시각.
      final alive = <int, DateTime>{};
      for (final alarm in alarms) {
        final triggers = triggersOf(alarm, now, pause: pause);
        List<AlarmReminder> of({Duration soonLead = alarmSoonLead}) => remindersOf(
          alarm,
          triggers,
          now,
          holidays: _holidays,
          holidayReminder: holidayReminder,
          soonLead: soonLead,
        );
        for (final reminder in of()) {
          desired[reminder.id] = (reminder, alarm);
        }
        // 리드를 0 으로 두면 울릴 시각 전인 모든 회차 — 떠 있어도 되는 것.
        alive.addAll({
          for (final reminder in of(soonLead: Duration.zero)) reminder.id: reminder.ringAt,
        });
      }

      final scheduled = await _reminders.scheduled();
      // 원하는 것은 아래에서 같은 id 로 덮어쓴다.
      for (final MapEntry(key: id, value: (:at, :ringAt)) in scheduled.entries) {
        final shown = !at.isAfter(now);
        if (desired.containsKey(id) || (shown && alive[id] == ringAt)) continue;
        await _reminders.cancel(id);
      }
      for (final MapEntry(key: id, value: (reminder, alarm)) in desired.entries) {
        if (scheduled[id] case (:final at, :final ringAt)
            when ringAt == reminder.ringAt && (at == reminder.at || !at.isAfter(now))) {
          continue;
        }
        await _reminders.schedule(reminder, alarm);
      }
    } on Object {
      // 다음 sync 에서 다시 맞춘다.
    }
  }

  /// 시각이 지난 1회성은 끈다. 단, 그 알람의 회차가 아직 울리는 중이거나 지금 뒤에 걸려
  /// 있으면(스누즈) 둔다 — 스누즈 중에 스위치가 꺼지고 요약 카드에서 사라지지 않게.
  /// 울림이 끝나(끄기) 남은 예약이 없어진 뒤의 sync 에서 꺼진다.
  Future<List<Alarm>> _expireOneShots(
    List<Alarm> alarms,
    DateTime now,
    Map<int, ScheduledRing> scheduled,
    Set<int> ringing,
  ) async {
    // 울릴 시각이 막 됐지만 아직 울림으로 잡히지 않은 회차도 남은 예약으로 본다 — 예약
    // 정리가 지우지 않고 두는 [dueGrace] 창과 같다. 여기서 끄면 울리는 동안 스위치가 꺼지고,
    // 스누즈한 뒤 다음 울림에서도 빠진다.
    final pending = {
      for (final MapEntry(key: id, value: (:at, signature: _)) in scheduled.entries)
        if (at.isAfter(now.subtract(dueGrace)) || ringing.contains(id)) alarmIdOf(id),
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

  /// 지난(지금 이전) `skippedAt` 을 지워 저장한다. 바뀐 것이 없으면 저장하지 않는다.
  Future<List<Alarm>> _clearPastSkips(List<Alarm> alarms, DateTime now) async {
    bool past(Alarm a) => !(a.skippedAt?.isAfter(now) ?? true);
    if (!alarms.any(past)) return alarms;
    final updated = [for (final a in alarms) past(a) ? a.copyWith(skippedAt: null) : a];
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
