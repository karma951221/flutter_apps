import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_pause.dart';
import 'package:walk/domain/alarm/entity/alarm_sound.dart';
import 'package:walk/domain/alarm/entity/alarm_reminder.dart';
import 'package:walk/domain/alarm/entity/alarm_trigger.dart';
import 'package:walk/domain/alarm/entity/ring_log_entry.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar.dart';
import 'package:walk/domain/alarm/repository/alarm_repository.dart';
import 'package:walk/domain/alarm/ring_log/ring_log_source.dart';
import 'package:walk/domain/alarm/scheduler/alarm_scheduler.dart';
import 'package:walk/domain/alarm/scheduler/reminder_scheduler.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/domain/settings/repository/settings_repository.dart';

class _MemoryRepository implements AlarmRepository {
  List<Alarm> alarms = [];

  @override
  Future<List<Alarm>> load() async => [...alarms];

  @override
  Future<void> save(List<Alarm> alarms) async => this.alarms = [...alarms];
}

/// 다음 저장 한 번만 실패한다.
class _FlakyRepository extends _MemoryRepository {
  bool failNextSave = false;

  @override
  Future<void> save(List<Alarm> alarms) async {
    if (failNextSave) {
      failNextSave = false;
      throw StateError('저장 실패');
    }
    await super.save(alarms);
  }
}

class _FakeScheduler implements AlarmScheduler {
  final Map<int, DateTime> entries = {};

  /// packageId → 걸 때 붙은 지문. 없으면 옛 payload(빈 지문)로 걸린 회차다.
  final Map<int, String> signatures = {};

  final Map<int, Alarm> alarms = {};
  final Set<int> ringing = {};
  final List<int> scheduleCalls = [];

  /// packageId → 걸 때 넘긴(또는 포크가 센) 스누즈 횟수.
  final Map<int, int> snoozeCounts = {};
  final List<int> cancelCalls = [];

  /// [rearmAll] 과 [schedule] 의 순서.
  final List<String> events = [];

  /// 패키지는 `stop` 안에서 울림 스트림을 비운다 — 그걸 보고 울림 화면이 걷히고 목록이
  /// 다시 읽는 순간을 흉내 낸다.
  void Function(int packageId)? onStop;

  @override
  Future<Map<int, ScheduledRing>> scheduled() async => {
    for (final MapEntry(key: id, value: at) in entries.entries)
      id: (at: at, signature: signatures[id] ?? ''),
  };

  @override
  String signatureOf(Alarm alarm) => '${alarm.label}|${alarm.silentWhenRingerMuted}|${alarm.sound}';

  @override
  Future<Set<int>> ringingIds() async => {...ringing};

  @override
  Future<void> schedule(int packageId, DateTime at, Alarm alarm, {int snoozeCount = 0}) async {
    scheduleCalls.add(packageId);
    snoozeCounts[packageId] = snoozeCount;
    events.add('schedule');
    entries[packageId] = at;
    signatures[packageId] = signatureOf(alarm);
    alarms[packageId] = alarm;
    ringing.remove(packageId);
  }

  @override
  Future<int> snoozeCountOf(int packageId) async => snoozeCounts[packageId] ?? 0;

  @override
  Future<void> cancel(int packageId) async {
    cancelCalls.add(packageId);
    entries.remove(packageId);
    ringing.remove(packageId);
  }

  @override
  Future<void> rearmAll() async => events.add('rearm');

  @override
  Future<void> stop(int packageId) async {
    entries.remove(packageId);
    ringing.remove(packageId);
    onStop?.call(packageId);
  }
}

class _FakeReminders implements ReminderScheduler {
  /// id → 띄울 시각(걸렸거나 떠 있는 것).
  final Map<int, DateTime> entries = {};

  /// id → 울릴 시각. [entries] 에 직접 넣을 때 함께 넣는다.
  final Map<int, DateTime> ringAts = {};
  final Map<int, AlarmReminder> reminders = {};
  final List<int> scheduleCalls = [];
  final List<int> cancelCalls = [];
  bool failScheduled = false;

  @override
  Future<Map<int, ScheduledReminder>> scheduled() async {
    if (failScheduled) throw StateError('채널 실패');
    return {
      for (final MapEntry(key: id, value: at) in entries.entries)
        id: (at: at, ringAt: ringAts[id]!),
    };
  }

  @override
  Future<void> schedule(AlarmReminder reminder, Alarm alarm) async {
    scheduleCalls.add(reminder.id);
    entries[reminder.id] = reminder.at;
    ringAts[reminder.id] = reminder.ringAt;
    reminders[reminder.id] = reminder;
  }

  @override
  Future<void> cancel(int reminderId) async {
    cancelCalls.add(reminderId);
    entries.remove(reminderId);
    ringAts.remove(reminderId);
    reminders.remove(reminderId);
  }
}

class _Holidays implements HolidayCalendar {
  final Map<DateTime, String> days = {};

  @override
  String? nameOf(DateTime date) => days[DateTime(date.year, date.month, date.day)];

  @override
  HolidaySource get source => const HolidaySource.bundled(firstYear: 2026, lastYear: 2027);
}

class _MemorySettings implements SettingsRepository {
  AppSettings value = const AppSettings();

  @override
  AppSettings load() => value;

  @override
  Future<void> save(AppSettings settings) async => value = settings;
}

class _MemoryRingLog implements RingLogSource {
  final List<RingLogEntry> entries = [];
  bool failAppend = false;

  @override
  Future<List<RingLogEntry>> read({required DateTime since}) async => [
    for (final e in entries)
      if (!e.at.isBefore(since)) e,
  ];

  @override
  Future<void> append(RingLogEntry entry) async {
    if (failAppend) throw StateError('기록 실패');
    entries.add(entry);
  }
}

class _MutableClock extends Clock {
  _MutableClock(this.current);
  DateTime current;
  @override
  DateTime now() => current;
}

const _everyDay = {...Weekday.values};

void main() {
  late _MemoryRepository repository;
  late _FakeScheduler scheduler;
  late _MutableClock clock;
  late _FakeReminders reminders;
  late _Holidays holidays;
  late _MemorySettings settings;
  late _MemoryRingLog ringLog;
  late AlarmUseCase useCase;

  // 2026-09-28 월요일 정오.
  final mondayNoon = DateTime(2026, 9, 28, 12);
  int pid(int alarmId, DateTime at) => packageId(alarmId, triggerIndex(at));

  setUp(() {
    repository = _MemoryRepository();
    scheduler = _FakeScheduler();
    clock = _MutableClock(mondayNoon);
    reminders = _FakeReminders();
    holidays = _Holidays();
    settings = _MemorySettings();
    ringLog = _MemoryRingLog();
    useCase = DefaultAlarmUseCase(
      repository,
      scheduler,
      clock,
      reminders,
      holidays,
      settings,
      ringLog,
    );
  });

  group('save', () {
    test('새 알람은 최대+1 id 를 받고 켜진 채 저장된다', () async {
      repository.alarms = [const Alarm(id: 4, hour: 6, minute: 0, enabled: false)];

      final saved = await useCase.save(const Alarm(hour: 8, minute: 0, repeat: _everyDay, enabled: false));

      expect(saved.id, 5);
      expect(saved.enabled, isTrue);
      expect(repository.alarms.map((a) => a.id), [4, 5]);
    });

    test('첫 알람은 id 1', () async {
      final saved = await useCase.save(Alarm.draft());
      expect(saved.id, 1);
    });

    test('1회성은 지금 기준 다음 시각을 oneShotAt 으로 정하고 예약한다', () async {
      final saved = await useCase.save(const Alarm(hour: 7, minute: 0));

      expect(saved.oneShotAt, DateTime(2026, 9, 29, 7));
      expect(scheduler.entries, {pid(1, DateTime(2026, 9, 29)): DateTime(2026, 9, 29, 7)});
    });

    test('1회성에 미래 oneShotAt 이 넘어오면 초까지 그대로 쓰고 hour · minute 를 맞춘다', () async {
      final at = DateTime(2026, 9, 28, 13, 25, 30); // 정오 + 1시간 25분 30초

      final saved = await useCase.save(Alarm(hour: 7, minute: 0, oneShotAt: at));

      expect(saved.oneShotAt, at);
      expect((saved.hour, saved.minute), (13, 25));
      expect(repository.alarms.single, saved);
      expect(scheduler.entries, {pid(1, at): at});
    });

    test('1회성에 지난 oneShotAt 이 넘어오면 hour:minute 의 다음 시각으로 정한다', () async {
      final saved = await useCase.save(
        Alarm(hour: 7, minute: 0, oneShotAt: DateTime(2026, 9, 28, 11, 59)),
      );

      expect(saved.oneShotAt, DateTime(2026, 9, 29, 7));
      expect((saved.hour, saved.minute), (7, 0));
    });

    test('1회성 oneShotAt 이 지금과 같으면 지난 것으로 본다', () async {
      final saved = await useCase.save(Alarm(hour: 12, minute: 0, oneShotAt: mondayNoon));

      expect(saved.oneShotAt, DateTime(2026, 9, 29, 12));
    });

    test('반복 알람은 넘어온 oneShotAt 을 버린다', () async {
      final saved = await useCase.save(
        Alarm(hour: 7, minute: 0, repeat: _everyDay, oneShotAt: DateTime(2026, 9, 28, 13)),
      );

      expect(saved.oneShotAt, isNull);
      expect((saved.hour, saved.minute), (7, 0));
    });

    test('반복 알람은 14일치 회차를 모두 예약한다', () async {
      await useCase.save(const Alarm(hour: 7, minute: 0, repeat: _everyDay));

      expect(scheduler.entries, hasLength(14));
      expect(scheduler.entries.values.first, DateTime(2026, 9, 29, 7));
    });

    test('수정하면 이 알람의 예전 회차를 지우고 새로 건다', () async {
      final saved = await useCase.save(const Alarm(hour: 7, minute: 0, repeat: {Weekday.tue}));
      final oldId = pid(saved.id, DateTime(2026, 9, 29));
      expect(scheduler.entries.keys, contains(oldId));

      await useCase.save(saved.copyWith(repeat: {Weekday.wed}, label: '회의'));

      expect(scheduler.entries.keys, isNot(contains(oldId)));
      expect(scheduler.entries.values, contains(DateTime(2026, 9, 30, 7)));
      expect(scheduler.alarms[pid(saved.id, DateTime(2026, 9, 30))]!.label, '회의');
      expect(repository.alarms, hasLength(1));
    });
  });

  test('list 는 시각순', () async {
    repository.alarms = [
      const Alarm(id: 1, hour: 9, minute: 0),
      const Alarm(id: 2, hour: 6, minute: 30),
      const Alarm(id: 3, hour: 6, minute: 30),
    ];
    expect((await useCase.list()).map((a) => a.id), [2, 3, 1]);
  });

  test('delete 는 정의와 예약을 모두 지운다', () async {
    final saved = await useCase.save(const Alarm(hour: 7, minute: 0, repeat: _everyDay));

    await useCase.delete(saved.id);

    expect(repository.alarms, isEmpty);
    expect(scheduler.entries, isEmpty);
  });

  group('toggle', () {
    test('끄면 예약을 지우고, 켜면 1회성 시각을 새로 정한다', () async {
      final saved = await useCase.save(const Alarm(hour: 7, minute: 0));

      final off = await useCase.toggle(saved.id, enabled: false);
      expect(off!.enabled, isFalse);
      expect(scheduler.entries, isEmpty);

      clock.current = DateTime(2026, 9, 29, 8); // 다음 날 7시가 지난 뒤
      final on = await useCase.toggle(saved.id, enabled: true);
      expect(on!.oneShotAt, DateTime(2026, 9, 30, 7));
      expect(scheduler.entries.values, [DateTime(2026, 9, 30, 7)]);
    });

    test('없는 id 는 null', () async {
      expect(await useCase.toggle(42, enabled: true), isNull);
    });
  });

  group('sync', () {
    test('저장된 정의에 없는 예약은 취소하고 빠진 회차는 건다', () async {
      repository.alarms = [const Alarm(id: 1, hour: 7, minute: 0, repeat: {Weekday.tue})];
      scheduler.entries[pid(9, DateTime(2026, 9, 30))] = DateTime(2026, 9, 30, 7); // 지워진 알람

      await useCase.sync();

      expect(scheduler.entries, {
        pid(1, DateTime(2026, 9, 29)): DateTime(2026, 9, 29, 7),
        pid(1, DateTime(2026, 10, 6)): DateTime(2026, 10, 6, 7),
      });
    });

    test('멱등이다 — 두 번째는 아무것도 바꾸지 않는다', () async {
      repository.alarms = [const Alarm(id: 1, hour: 7, minute: 0, repeat: _everyDay)];
      await useCase.sync();
      scheduler.scheduleCalls.clear();

      await useCase.sync();

      expect(scheduler.scheduleCalls, isEmpty);
      expect(scheduler.cancelCalls, isEmpty);
    });

    test('시각이 지난 1회성은 꺼진다', () async {
      repository.alarms = [Alarm(id: 1, hour: 7, minute: 0, oneShotAt: DateTime(2026, 9, 28, 7))];

      await useCase.sync();

      expect(repository.alarms.single.enabled, isFalse);
      expect(scheduler.entries, isEmpty);
    });

    test('스누즈 중인 1회성은 원래 시각이 지나도 켜진 채 둔다', () async {
      final at = DateTime(2026, 9, 28, 11, 58);
      final snoozedId = pid(1, at);
      repository.alarms = [Alarm(id: 1, hour: 11, minute: 58, oneShotAt: at)];
      scheduler.entries[snoozedId] = DateTime(2026, 9, 28, 12, 3);

      await useCase.sync();

      expect(repository.alarms.single.enabled, isTrue);
      expect(scheduler.entries, {snoozedId: DateTime(2026, 9, 28, 12, 3)});
      expect(await useCase.nextRings(), {1: DateTime(2026, 9, 28, 12, 3)});
    });

    test('스누즈가 울리고 끝나 예약이 모두 사라진 1회성은 꺼진다', () async {
      final at = DateTime(2026, 9, 28, 11, 58);
      final snoozedId = pid(1, at);
      repository.alarms = [Alarm(id: 1, hour: 11, minute: 58, oneShotAt: at)];
      scheduler.entries[snoozedId] = DateTime(2026, 9, 28, 12, 3);
      clock.current = DateTime(2026, 9, 28, 12, 3);
      scheduler.ringing.add(snoozedId);

      await useCase.stop(snoozedId);

      expect(repository.alarms.single.enabled, isFalse);
      expect(scheduler.entries, isEmpty);
    });

    test('울리는 중인 회차는 건드리지 않고, 그 1회성도 울림이 끝날 때까지 켜 둔다', () async {
      final ringingAt = DateTime(2026, 9, 28, 11, 59);
      final ringingId = pid(1, ringingAt);
      repository.alarms = [Alarm(id: 1, hour: 11, minute: 59, oneShotAt: ringingAt)];
      scheduler.entries[ringingId] = ringingAt;
      scheduler.ringing.add(ringingId);
      clock.current = DateTime(2026, 9, 28, 12, 30);

      await useCase.sync();

      expect(scheduler.entries.keys, contains(ringingId));
      expect(scheduler.cancelCalls, isEmpty);
      // 전체 화면 알림이 앱을 깨워 sync 가 돌아도, 스누즈하면 켜진 채 이어지게 남긴다.
      expect(repository.alarms.single.enabled, isTrue);
    });

    test('스누즈된 회차는 원하는 목록에 없어도 남긴다', () async {
      repository.alarms = [const Alarm(id: 1, hour: 11, minute: 58, repeat: _everyDay)];
      final todayId = pid(1, mondayNoon);
      // 11:58 에 울려 12:03 으로 스누즈됨
      scheduler.entries[todayId] = DateTime(2026, 9, 28, 12, 3);

      await useCase.sync();

      expect(scheduler.entries[todayId], DateTime(2026, 9, 28, 12, 3));
      expect(scheduler.entries, hasLength(15)); // 스누즈 1 + 내일부터 14회차
    });

    test('스누즈 간격보다 먼 원치 않는 회차는 취소한다', () async {
      repository.alarms = [const Alarm(id: 1, hour: 7, minute: 0, repeat: {Weekday.tue})];
      final staleId = pid(1, DateTime(2026, 9, 28));
      scheduler.entries[staleId] = DateTime(2026, 9, 28, 13);

      await useCase.sync();

      expect(scheduler.entries.keys, isNot(contains(staleId)));
    });
  });

  group('지문', () {
    const alarm = Alarm(id: 1, hour: 7, minute: 0, repeat: {Weekday.tue});
    final tuesdayId = pid(1, DateTime(2026, 9, 29));
    final tuesdayAt = DateTime(2026, 9, 29, 7);

    test('시각과 지문이 같으면 다시 걸지 않는다', () async {
      repository.alarms = [alarm];
      scheduler.entries[tuesdayId] = tuesdayAt;
      scheduler.signatures[tuesdayId] = scheduler.signatureOf(alarm);

      await useCase.sync();

      expect(scheduler.scheduleCalls, isNot(contains(tuesdayId)));
    });

    test('시각이 같아도 지문이 다르면 지금 설정으로 다시 건다', () async {
      final changed = alarm.copyWith(sound: const AlarmSound.bundled(BundledAlarmSounds.chime));
      repository.alarms = [changed];
      scheduler.entries[tuesdayId] = tuesdayAt;
      scheduler.signatures[tuesdayId] = scheduler.signatureOf(alarm);

      await useCase.sync();

      expect(scheduler.scheduleCalls, contains(tuesdayId));
      expect(scheduler.alarms[tuesdayId], changed);
      expect(scheduler.signatures[tuesdayId], scheduler.signatureOf(changed));
    });

    test('옛 payload(빈 지문)로 걸린 회차는 한 번 다시 건다', () async {
      repository.alarms = [alarm];
      scheduler.entries[tuesdayId] = tuesdayAt;

      await useCase.sync();
      expect(scheduler.scheduleCalls, contains(tuesdayId));

      scheduler.scheduleCalls.clear();
      await useCase.sync();
      expect(scheduler.scheduleCalls, isEmpty);
    });

    test('울리는 중인 회차는 지문이 달라도 건드리지 않는다', () async {
      repository.alarms = [alarm.copyWith(label: '새 라벨')];
      scheduler.entries[tuesdayId] = tuesdayAt;
      scheduler.signatures[tuesdayId] = scheduler.signatureOf(alarm);
      scheduler.ringing.add(tuesdayId);

      await useCase.sync();

      expect(scheduler.scheduleCalls, isNot(contains(tuesdayId)));
      expect(scheduler.cancelCalls, isEmpty);
      expect(scheduler.signatures[tuesdayId], scheduler.signatureOf(alarm));
    });
  });

  group('울림 처리', () {
    test('snooze 는 같은 id 를 5분 뒤로 다시 걸고 sync 뒤에도 남는다', () async {
      final saved = await useCase.save(const Alarm(hour: 12, minute: 0, repeat: _everyDay));
      final firstAt = DateTime(2026, 9, 29, 12);
      final ringingId = pid(saved.id, firstAt);
      clock.current = firstAt;
      scheduler.ringing.add(ringingId);

      await useCase.snooze(ringingId);

      expect(scheduler.entries[ringingId], firstAt.add(const Duration(minutes: 5)));
      expect(scheduler.ringing, isEmpty);
    });

    test('stop 은 그 회차를 끄고, 1회성이면 알람도 꺼진다', () async {
      final saved = await useCase.save(const Alarm(hour: 13, minute: 0));
      final at = DateTime(2026, 9, 28, 13);
      final ringingId = pid(saved.id, at);
      clock.current = at;
      scheduler.ringing.add(ringingId);

      await useCase.stop(ringingId);

      expect(scheduler.entries, isEmpty);
      expect(repository.alarms.single.enabled, isFalse);
    });

    test('stop 도중 목록을 다시 읽어도 꺼진 1회성을 본다', () async {
      final saved = await useCase.save(const Alarm(hour: 13, minute: 0));
      final at = DateTime(2026, 9, 28, 13);
      final ringingId = pid(saved.id, at);
      clock.current = at;
      scheduler.ringing.add(ringingId);
      late Future<List<Alarm>> listed;
      late Future<Map<int, DateTime>> next;
      scheduler.onStop = (_) {
        listed = useCase.list();
        next = useCase.nextRings();
      };

      await useCase.stop(ringingId);

      expect((await listed).single.enabled, isFalse);
      expect(await next, isEmpty);
    });

    test('stop 도중 다시 읽어도 반복 알람은 켜진 채 다음 회차가 남는다', () async {
      final saved = await useCase.save(const Alarm(hour: 13, minute: 0, repeat: _everyDay));
      final at = DateTime(2026, 9, 29, 13);
      final ringingId = pid(saved.id, at);
      clock.current = at;
      scheduler.ringing.add(ringingId);
      late Future<List<Alarm>> listed;
      late Future<Map<int, DateTime>> next;
      scheduler.onStop = (_) {
        listed = useCase.list();
        next = useCase.nextRings();
      };

      await useCase.stop(ringingId);

      expect((await listed).single.enabled, isTrue);
      expect(await next, {saved.id: DateTime(2026, 9, 30, 13)});
      expect(scheduler.entries.keys, isNot(contains(ringingId)));
    });

    test('findByPackageId 는 회차의 알람을 찾는다', () async {
      final saved = await useCase.save(const Alarm(hour: 13, minute: 0, label: '약'));
      final found = await useCase.findByPackageId(pid(saved.id, DateTime(2026, 9, 28)));
      expect(found?.label, '약');
    });
  });

  group('nextRings', () {
    test('알람별로 지금 뒤의 가장 이른 예약 시각', () async {
      await useCase.save(const Alarm(hour: 7, minute: 0, repeat: _everyDay));
      await useCase.save(const Alarm(hour: 18, minute: 0));

      expect(await useCase.nextRings(), {
        1: DateTime(2026, 9, 29, 7),
        2: DateTime(2026, 9, 28, 18),
      });
    });

    test('스누즈된 회차를 포함한다 — 원래 규칙보다 이르면 그것이 다음 울림', () async {
      repository.alarms = [const Alarm(id: 1, hour: 11, minute: 58, repeat: _everyDay)];
      await useCase.sync();
      // 11:58 에 울려 12:03 으로 스누즈됨
      scheduler.entries[pid(1, mondayNoon)] = DateTime(2026, 9, 28, 12, 3);

      expect(await useCase.nextRings(), {1: DateTime(2026, 9, 28, 12, 3)});
    });

    test('지금 이전(울리는 중 포함) 예약은 뺀다', () async {
      repository.alarms = [const Alarm(id: 1, hour: 11, minute: 59, repeat: _everyDay)];
      await useCase.sync();
      final ringingId = pid(1, mondayNoon);
      scheduler.entries[ringingId] = DateTime(2026, 9, 28, 11, 59);
      scheduler.ringing.add(ringingId);

      expect(await useCase.nextRings(), {1: DateTime(2026, 9, 29, 11, 59)});
    });

    test('꺼진 알람은 예약이 남아 있어도 키가 없다', () async {
      repository.alarms = [
        const Alarm(id: 1, hour: 7, minute: 0, repeat: _everyDay, enabled: false),
      ];
      scheduler.entries[pid(1, DateTime(2026, 9, 29))] = DateTime(2026, 9, 29, 7);

      expect(await useCase.nextRings(), isEmpty);
    });

    test('예약이 없으면(권한 문제 등) 켜진 알람도 키가 없다', () async {
      repository.alarms = [const Alarm(id: 1, hour: 7, minute: 0, repeat: _everyDay)];

      expect(await useCase.nextRings(), isEmpty);
    });
  });

  group('save · 예전 회차 정리', () {
    test('곧(5분 안) 울릴 예전 회차도 수정하면 지운다', () async {
      final saved = await useCase.save(const Alarm(hour: 12, minute: 3, repeat: {Weekday.mon}));
      final soonId = pid(saved.id, mondayNoon);
      expect(scheduler.entries[soonId], DateTime(2026, 9, 28, 12, 3));

      await useCase.save(saved.copyWith(minute: 30, repeat: {Weekday.tue}));

      expect(scheduler.entries.keys, isNot(contains(soonId)));
      expect(scheduler.entries.values, isNot(contains(DateTime(2026, 9, 28, 12, 3))));
      expect(scheduler.entries[pid(saved.id, DateTime(2026, 9, 29))], DateTime(2026, 9, 29, 12, 30));
    });

    test('스누즈 중인 알람을 수정하면 스누즈 회차도 지운다', () async {
      const alarm = Alarm(id: 1, hour: 11, minute: 58, repeat: _everyDay);
      repository.alarms = [alarm];
      final snoozedId = pid(1, mondayNoon);
      scheduler.entries[snoozedId] = DateTime(2026, 9, 28, 12, 3); // 11:58 → 12:03 스누즈

      await useCase.save(alarm.copyWith(hour: 7, minute: 0));

      expect(scheduler.entries.keys, isNot(contains(snoozedId)));
      expect(await useCase.nextRings(), {1: DateTime(2026, 9, 29, 7)});
    });
  });

  group('새 id', () {
    test('최대 id(9999)를 쓰고 있으면 비어 있는 가장 작은 id 를 준다', () async {
      repository.alarms = [
        const Alarm(id: 1, hour: 6, minute: 0, enabled: false),
        const Alarm(id: Alarm.maxId, hour: 6, minute: 0, enabled: false),
      ];

      final saved = await useCase.save(Alarm.draft());

      expect(saved.id, 2);
    });

    test('9999개가 모두 차면 StateError', () async {
      repository.alarms = [
        for (var id = 1; id <= Alarm.maxId; id++) Alarm(id: id, hour: 6, minute: 0, enabled: false),
      ];

      await expectLater(useCase.save(Alarm.draft()), throwsStateError);
      expect(repository.alarms, hasLength(Alarm.maxId));
    });
  });

  group('울리는 중 끄기 · 지우기', () {
    test('울리는 중에 끄거나 지워도 울리는 회차는 cancel 하지 않는다', () async {
      repository.alarms = [
        const Alarm(id: 1, hour: 11, minute: 59, repeat: _everyDay),
        const Alarm(id: 2, hour: 11, minute: 59, repeat: _everyDay),
      ];
      final ringing1 = pid(1, mondayNoon);
      final ringing2 = pid(2, mondayNoon);
      scheduler.entries[ringing1] = DateTime(2026, 9, 28, 11, 59);
      scheduler.entries[ringing2] = DateTime(2026, 9, 28, 11, 59);
      scheduler.ringing.addAll({ringing1, ringing2});

      await useCase.toggle(1, enabled: false);
      await useCase.delete(2);

      expect(scheduler.cancelCalls, isNot(contains(ringing1)));
      expect(scheduler.cancelCalls, isNot(contains(ringing2)));
      expect(scheduler.ringing, {ringing1, ringing2});
      // 다른 회차는 모두 지워졌다.
      expect(scheduler.entries.keys.toSet(), {ringing1, ringing2});
    });

    test('지워진 알람의 울림을 snooze 하면 다시 걸지 않고 멈춘다', () async {
      final ringingId = pid(1, mondayNoon);
      scheduler.entries[ringingId] = DateTime(2026, 9, 28, 11, 59);
      scheduler.ringing.add(ringingId);

      await useCase.snooze(ringingId);

      expect(scheduler.ringing, isEmpty);
      expect(scheduler.entries, isEmpty);
      expect(scheduler.scheduleCalls, isEmpty);
    });

    test('꺼진 알람의 울리는 회차를 snooze 하면 다시 걸지 않고 멈춘다', () async {
      repository.alarms = [
        const Alarm(id: 1, hour: 11, minute: 59, repeat: _everyDay, enabled: false),
      ];
      final ringingId = pid(1, mondayNoon);
      scheduler.entries[ringingId] = DateTime(2026, 9, 28, 11, 59);
      scheduler.ringing.add(ringingId);

      await useCase.snooze(ringingId);

      expect(scheduler.ringing, isEmpty);
      expect(scheduler.entries, isEmpty);
      expect(scheduler.scheduleCalls, isEmpty);
      expect(await useCase.nextRings(), isEmpty);
    });
  });

  group('sync 경계', () {
    test('울릴 시각이 막 됐지만 아직 울림으로 잡히기 전이면 1회성을 끄지 않는다', () async {
      final at = DateTime(2026, 9, 28, 12);
      final dueId = pid(1, at);
      repository.alarms = [Alarm(id: 1, hour: 12, minute: 0, oneShotAt: at)];
      scheduler.entries[dueId] = at;

      for (final now in [at, at.add(const Duration(seconds: 30))]) {
        clock.current = now;
        await useCase.sync();

        expect(repository.alarms.single.enabled, isTrue, reason: '$now');
        expect(scheduler.entries, {dueId: at}, reason: '$now');
      }

      // 이제 울림으로 잡혔고, 스누즈하면 켜진 채 다음 울림이 보인다.
      scheduler.ringing.add(dueId);
      await useCase.snooze(dueId);

      expect(repository.alarms.single.enabled, isTrue);
      expect(await useCase.nextRings(), {1: DateTime(2026, 9, 28, 12, 5, 30)});
    });

    test('꺼진 알람의 곧 울릴 예약(5분 안)도 취소한다', () async {
      repository.alarms = [
        const Alarm(id: 1, hour: 12, minute: 3, repeat: _everyDay, enabled: false),
      ];
      final soonId = pid(1, mondayNoon);
      scheduler.entries[soonId] = DateTime(2026, 9, 28, 12, 3);

      await useCase.sync();

      expect(scheduler.cancelCalls, contains(soonId));
      expect(scheduler.entries, isEmpty);
    });

    test('스누즈 보존 창 경계: now+5분은 남기고 넘으면 취소, now-1분(dueGrace)은 취소하고 그 안은 남긴다', () async {
      final staleId = pid(1, mondayNoon);
      final cases = {
        DateTime(2026, 9, 28, 12, 5): true,
        DateTime(2026, 9, 28, 12, 5, 1): false,
        DateTime(2026, 9, 28, 11, 59): false,
        DateTime(2026, 9, 28, 11, 59, 1): true,
      };
      for (final MapEntry(key: at, value: kept) in cases.entries) {
        repository.alarms = [const Alarm(id: 1, hour: 11, minute: 58, repeat: _everyDay)];
        scheduler.entries
          ..clear()
          ..[staleId] = at;

        await useCase.sync();

        expect(scheduler.entries[staleId], kept ? at : isNull, reason: '$at');
      }
    });

    test('같은 id 가 다른 시각으로 걸려 있으면 원하는 시각으로 다시 건다(시간대 변경)', () async {
      repository.alarms = [const Alarm(id: 1, hour: 7, minute: 0, repeat: _everyDay)];
      final tomorrowId = pid(1, DateTime(2026, 9, 29));
      scheduler.entries[tomorrowId] = DateTime(2026, 9, 29, 8); // 한 시간 밀린 채 걸림

      await useCase.sync();

      expect(scheduler.entries[tomorrowId], DateTime(2026, 9, 29, 7));
      expect(scheduler.scheduleCalls, contains(tomorrowId));
    });

    // 테스트 안에서 기기 시간대를 바꿀 수 없어 절대 시각으로 흉내 낸다 — 서울에서 걸어 둔
    // 내일 07:00(서울) 은 파리의 00:00 이다. 파리로 옮긴 뒤의 규칙은 파리 07:00 을 원한다.
    test('시간대가 바뀌면 옛 시간대의 절대 시각으로 걸린 회차를 같은 id 로 새 벽시계에 다시 건다', () async {
      repository.alarms = [const Alarm(id: 1, hour: 7, minute: 0, repeat: _everyDay)];
      final wanted = DateTime(2026, 9, 29, 7);
      final tomorrowId = pid(1, wanted);
      const seoulMinusParis = Duration(hours: 7);
      scheduler.entries[tomorrowId] = wanted.subtract(seoulMinusParis).toUtc();

      await useCase.sync();

      expect(scheduler.scheduleCalls, contains(tomorrowId));
      expect(scheduler.entries[tomorrowId], wanted);
      expect(scheduler.entries[tomorrowId]!.hour, 7);
    });

    test('1회성 oneShotAt 은 오프셋 없이 저장돼 읽은 곳의 같은 벽시계 시각으로 걸린다', () async {
      final json = Alarm(id: 1, hour: 7, minute: 0, oneShotAt: DateTime(2026, 9, 29, 7)).toJson();
      expect(json['oneShotAt'], '2026-09-29T07:00:00.000');
      repository.alarms = [Alarm.fromJson(json)];

      await useCase.sync();

      final at = scheduler.entries[pid(1, DateTime(2026, 9, 29))];
      expect(at, DateTime(2026, 9, 29, 7));
      expect(at!.isUtc, isFalse);
    });

    test('timeZoneChanged 는 패키지 예약을 지금 시간대로 옮겨 건 뒤 sync 한다', () async {
      repository.alarms = [const Alarm(id: 1, hour: 7, minute: 0, repeat: _everyDay)];

      await useCase.timeZoneChanged();

      expect(scheduler.events.first, 'rearm');
      expect(scheduler.events.where((e) => e == 'rearm'), hasLength(1));
      expect(scheduler.entries[pid(1, DateTime(2026, 9, 29))], DateTime(2026, 9, 29, 7));
    });

    test('스누즈 · 울리는 회차가 있어도 두 번째 sync 는 아무것도 바꾸지 않는다', () async {
      repository.alarms = [
        const Alarm(id: 1, hour: 11, minute: 58, repeat: _everyDay),
        const Alarm(id: 2, hour: 11, minute: 50, repeat: _everyDay),
      ];
      final snoozedId = pid(1, mondayNoon);
      final ringingId = pid(2, mondayNoon);
      scheduler.entries[snoozedId] = DateTime(2026, 9, 28, 12, 3);
      scheduler.entries[ringingId] = DateTime(2026, 9, 28, 11, 50);
      scheduler.ringing.add(ringingId);

      await useCase.sync();
      final afterFirst = {...scheduler.entries};
      scheduler.scheduleCalls.clear();
      scheduler.cancelCalls.clear();

      await useCase.sync();

      expect(scheduler.scheduleCalls, isEmpty);
      expect(scheduler.cancelCalls, isEmpty);
      expect(scheduler.entries, afterFirst);
      expect(afterFirst[snoozedId], DateTime(2026, 9, 28, 12, 3));
      expect(afterFirst[ringingId], DateTime(2026, 9, 28, 11, 50));
    });

    test('자정을 넘긴 스누즈 회차는 남기고, 오늘 회차는 다른 id 로 건다', () async {
      repository.alarms = [const Alarm(id: 1, hour: 23, minute: 58, repeat: _everyDay)];
      clock.current = DateTime(2026, 9, 29, 0, 1);
      final yesterdayId = pid(1, DateTime(2026, 9, 28));
      final todayId = pid(1, DateTime(2026, 9, 29));
      scheduler.entries[yesterdayId] = DateTime(2026, 9, 29, 0, 3); // 어제 23:58 → 00:03 스누즈

      await useCase.sync();

      expect(yesterdayId, isNot(todayId));
      expect(scheduler.entries[yesterdayId], DateTime(2026, 9, 29, 0, 3));
      expect(scheduler.entries[todayId], DateTime(2026, 9, 29, 23, 58));
      expect(await useCase.nextRings(), {1: DateTime(2026, 9, 29, 0, 3)});
    });
  });

  group('스누즈 세부', () {
    // 화요일 12:00 회차가 울리는 중.
    final firstAt = DateTime(2026, 9, 29, 12);
    late int ringingId;

    Future<void> ring(Alarm alarm, {int count = 0}) async {
      repository.alarms = [alarm];
      ringingId = pid(alarm.id, firstAt);
      clock.current = firstAt;
      scheduler.entries[ringingId] = firstAt;
      scheduler.snoozeCounts[ringingId] = count;
      scheduler.ringing.add(ringingId);
    }

    test('snooze 는 알람의 스누즈 간격 뒤로 다시 건다', () async {
      await ring(const Alarm(id: 1, hour: 12, minute: 0, repeat: _everyDay, snoozeMinutes: 15));

      await useCase.snooze(ringingId);

      expect(scheduler.entries[ringingId], DateTime(2026, 9, 29, 12, 15));
    });

    test('snooze 는 지금까지 센 횟수 + 1 을 넘긴다', () async {
      await ring(const Alarm(id: 1, hour: 12, minute: 0, repeat: _everyDay, snoozeLimit: 3), count: 1);

      await useCase.snooze(ringingId);

      expect(scheduler.snoozeCounts[ringingId], 2);
    });

    test('한도를 다 쓴 회차는 snooze 해도 다시 걸지 않고 멈춘다', () async {
      await ring(const Alarm(id: 1, hour: 12, minute: 0, repeat: _everyDay, snoozeLimit: 3), count: 3);

      await useCase.snooze(ringingId);

      expect(scheduler.entries.keys, isNot(contains(ringingId)));
      expect(scheduler.ringing, isEmpty);
    });

    test('canSnooze — 무제한이면 true, 한도 전이면 true, 한도에 닿으면 false', () async {
      await ring(const Alarm(id: 1, hour: 12, minute: 0, repeat: _everyDay), count: 50);
      expect(await useCase.canSnooze(ringingId), isTrue);

      await ring(const Alarm(id: 1, hour: 12, minute: 0, repeat: _everyDay, snoozeLimit: 3), count: 2);
      expect(await useCase.canSnooze(ringingId), isTrue);

      scheduler.snoozeCounts[ringingId] = 3;
      expect(await useCase.canSnooze(ringingId), isFalse);
    });

    test('canSnooze — 지워졌거나 꺼진 알람은 false', () async {
      await ring(const Alarm(id: 1, hour: 12, minute: 0, repeat: _everyDay, enabled: false));
      expect(await useCase.canSnooze(ringingId), isFalse);

      repository.alarms = [];
      expect(await useCase.canSnooze(ringingId), isFalse);
    });

    test('스누즈 보존 창은 알람의 스누즈 간격 — 15분이면 now+15분까지 남긴다', () async {
      final staleId = pid(1, mondayNoon);
      final cases = {
        DateTime(2026, 9, 28, 12, 15): true,
        DateTime(2026, 9, 28, 12, 15, 1): false,
      };
      for (final MapEntry(key: at, value: kept) in cases.entries) {
        repository.alarms = [
          const Alarm(id: 1, hour: 11, minute: 58, repeat: _everyDay, snoozeMinutes: 15),
        ];
        scheduler.entries
          ..clear()
          ..[staleId] = at;

        await useCase.sync();

        expect(scheduler.entries[staleId], kept ? at : isNull, reason: '$at');
      }
    });

    test('sync 가 새로 거는 회차는 스누즈 횟수 0 으로 건다', () async {
      repository.alarms = [const Alarm(id: 1, hour: 7, minute: 0, repeat: _everyDay, snoozeLimit: 3)];

      await useCase.sync();

      expect(scheduler.snoozeCounts.values.toSet(), {0});
    });
  });

  group('건너뛰기', () {
    // 월요일 정오 기준 다음 회차는 화요일 07:00.
    final tuesday7 = DateTime(2026, 9, 29, 7);
    const daily = Alarm(id: 1, hour: 7, minute: 0, repeat: _everyDay);

    test('skipNext 는 다음 회차를 skippedAt 으로 저장하고 그 예약을 지운다', () async {
      repository.alarms = [daily];
      await useCase.sync();
      expect(scheduler.entries, contains(pid(1, tuesday7)));

      final skipped = await useCase.skipNext(1);

      expect(skipped!.skippedAt, tuesday7);
      expect(repository.alarms.single.skippedAt, tuesday7);
      expect(scheduler.entries.keys, isNot(contains(pid(1, tuesday7))));
      expect(scheduler.entries, contains(pid(1, DateTime(2026, 9, 30))));
      expect(await useCase.nextRings(), {1: DateTime(2026, 9, 30, 7)});
    });

    test('skipNext 는 스누즈 보존 창 안의 곧 울릴 회차도 지운다', () async {
      repository.alarms = [const Alarm(id: 1, hour: 12, minute: 3, repeat: _everyDay)];
      await useCase.sync();
      final soon = pid(1, mondayNoon);
      expect(scheduler.entries[soon], DateTime(2026, 9, 28, 12, 3));

      await useCase.skipNext(1);

      expect(scheduler.entries.keys, isNot(contains(soon)));
      expect(repository.alarms.single.skippedAt, DateTime(2026, 9, 28, 12, 3));
    });

    test('skipNext 를 두 번 불러도 같은 다음 회차 하나만 건너뛴다', () async {
      repository.alarms = [daily];

      await useCase.skipNext(1);
      await useCase.skipNext(1);

      expect(repository.alarms.single.skippedAt, tuesday7);
    });

    test('skipNext 는 1회성 · 꺼진 알람을 바꾸지 않고, 없는 id 는 null', () async {
      final oneShot = Alarm(id: 1, hour: 7, minute: 0, oneShotAt: tuesday7);
      const off = Alarm(id: 2, hour: 7, minute: 0, repeat: _everyDay, enabled: false);
      repository.alarms = [oneShot, off];

      expect(await useCase.skipNext(1), oneShot);
      expect(await useCase.skipNext(2), off);
      expect(await useCase.skipNext(3), isNull);
      expect(repository.alarms, [oneShot, off]);
    });

    test('unskip 은 skippedAt 을 지우고 그 회차를 다시 건다', () async {
      repository.alarms = [daily.copyWith(skippedAt: tuesday7)];
      await useCase.sync();
      expect(scheduler.entries.keys, isNot(contains(pid(1, tuesday7))));

      final unskipped = await useCase.unskip(1);

      expect(unskipped!.skippedAt, isNull);
      expect(repository.alarms.single.skippedAt, isNull);
      expect(scheduler.entries[pid(1, tuesday7)], tuesday7);
      expect(await useCase.unskip(9), isNull);
    });

    test('skipOccurrence — 반복이면 그 회차를 skippedAt 으로, 30분 안 회차도 지운다', () async {
      repository.alarms = [const Alarm(id: 1, hour: 12, minute: 20, repeat: _everyDay)];
      await useCase.sync();
      final todayId = pid(1, mondayNoon);
      // 울리기 3분 전 — 스누즈 보존 창(5분) 안이라 sync 만으로는 지우지 않는다.
      clock.current = DateTime(2026, 9, 28, 12, 17);

      await useCase.skipOccurrence(todayId);

      expect(repository.alarms.single.skippedAt, DateTime(2026, 9, 28, 12, 20));
      expect(repository.alarms.single.enabled, isTrue);
      expect(scheduler.entries.keys, isNot(contains(todayId)));
      expect(scheduler.entries, contains(pid(1, DateTime(2026, 9, 29))));
    });

    test('skipOccurrence — 다음이 아닌 회차(공휴일)도 그 회차만 건너뛴다', () async {
      repository.alarms = [daily];
      await useCase.sync();
      final thursdayId = pid(1, DateTime(2026, 10, 1));

      await useCase.skipOccurrence(thursdayId);

      expect(repository.alarms.single.skippedAt, DateTime(2026, 10, 1, 7));
      expect(scheduler.entries.keys, isNot(contains(thursdayId)));
      expect(scheduler.entries, contains(pid(1, tuesday7)));
    });

    test('skipOccurrence — 1회성이면 알람을 끄고 예약을 지운다', () async {
      final at = DateTime(2026, 9, 28, 12, 20);
      repository.alarms = [Alarm(id: 1, hour: 12, minute: 20, oneShotAt: at)];
      await useCase.sync();
      clock.current = DateTime(2026, 9, 28, 12, 18);

      await useCase.skipOccurrence(pid(1, at));

      expect(repository.alarms.single.enabled, isFalse);
      expect(repository.alarms.single.skippedAt, isNull);
      expect(scheduler.entries, isEmpty);
    });

    test('skipOccurrence — 지워진 알람의 회차는 예약만 지운다', () async {
      final orphan = pid(4, tuesday7);
      scheduler.entries[orphan] = tuesday7;

      await useCase.skipOccurrence(orphan);

      expect(scheduler.entries, isEmpty);
      expect(repository.alarms, isEmpty);
    });

    test('건너뛴 알람의 시각을 바꿔 저장하면 건너뛰기를 지운다(옛 회차는 더 없다)', () async {
      repository.alarms = [daily];
      final skipped = await useCase.skipNext(1);

      final saved = await useCase.save(skipped!.copyWith(hour: 8));

      final tuesday8 = DateTime(2026, 9, 29, 8);
      expect(saved.skippedAt, isNull);
      expect(repository.alarms.single.skippedAt, isNull);
      expect(scheduler.entries[pid(1, tuesday8)], tuesday8);
    });

    test('건너뛴 회차의 요일을 반복에서 빼고 저장해도 건너뛰기를 지운다', () async {
      repository.alarms = [daily];
      final skipped = await useCase.skipNext(1);

      final saved = await useCase.save(
        skipped!.copyWith(repeat: {..._everyDay}..remove(Weekday.tue)),
      );

      expect(saved.skippedAt, isNull);
    });

    test('건너뛴 회차가 그대로 있으면(라벨만 바꿈) 건너뛰기를 둔다', () async {
      repository.alarms = [daily];
      final skipped = await useCase.skipNext(1);

      final saved = await useCase.save(skipped!.copyWith(label: '출근'));

      expect(saved.skippedAt, tuesday7);
      expect(scheduler.entries.keys, isNot(contains(pid(1, tuesday7))));
    });

    test('시각을 바꿨다 되돌려도 지운 건너뛰기가 살아나지 않는다', () async {
      repository.alarms = [daily];
      final skipped = await useCase.skipNext(1);
      final moved = await useCase.save(skipped!.copyWith(hour: 8));

      final back = await useCase.save(moved.copyWith(hour: 7));

      expect(back.skippedAt, isNull);
      expect(scheduler.entries[pid(1, tuesday7)], tuesday7);
    });

    test('sync 는 지난 skippedAt 을 지워 저장하고, 남은 것은 둔다', () async {
      repository.alarms = [
        daily.copyWith(skippedAt: DateTime(2026, 9, 28, 7)),
        daily.copyWith(id: 2, skippedAt: tuesday7),
      ];

      await useCase.sync();

      expect(repository.alarms[0].skippedAt, isNull);
      expect(repository.alarms[1].skippedAt, tuesday7);
      expect(scheduler.entries, contains(pid(1, tuesday7)));
      expect(scheduler.entries.keys, isNot(contains(pid(2, tuesday7))));
    });
  });

  group('미리 알림', () {
    // 화 9-29 07:00 · 수 9-30 07:00 … (월 정오 기준)
    final tuesday7 = DateTime(2026, 9, 29, 7);
    final wednesday7 = DateTime(2026, 9, 30, 7);
    int soonId(int alarmId, DateTime at) => reminderId(pid(alarmId, at), ReminderKind.soon);
    int holidayId(int alarmId, DateTime at) => reminderId(pid(alarmId, at), ReminderKind.holiday);
    const weekdays = {Weekday.tue, Weekday.wed};

    test('remindBefore 알람은 회차마다 30분 전 미리 알림을 건다', () async {
      await useCase.save(const Alarm(hour: 7, minute: 0, repeat: weekdays, remindBefore: true));

      expect(reminders.entries, {
        soonId(1, tuesday7): DateTime(2026, 9, 29, 6, 30),
        soonId(1, wednesday7): DateTime(2026, 9, 30, 6, 30),
        soonId(1, DateTime(2026, 10, 6, 7)): DateTime(2026, 10, 6, 6, 30),
        soonId(1, DateTime(2026, 10, 7, 7)): DateTime(2026, 10, 7, 6, 30),
      });
      expect(reminders.reminders[soonId(1, tuesday7)]!.packageId, pid(1, tuesday7));
    });

    test('remindBefore 가 꺼진 알람은 걸지 않는다', () async {
      await useCase.save(const Alarm(hour: 7, minute: 0, repeat: weekdays));
      expect(reminders.entries, isEmpty);
    });

    test('멱등이다 — 같은 시각이면 다시 걸지 않는다', () async {
      repository.alarms = [const Alarm(id: 1, hour: 7, minute: 0, repeat: weekdays, remindBefore: true)];
      await useCase.sync();
      reminders.scheduleCalls.clear();

      await useCase.sync();

      expect(reminders.scheduleCalls, isEmpty);
      expect(reminders.cancelCalls, isEmpty);
    });

    test('끄면 미리 알림도 지운다', () async {
      final saved = await useCase.save(
        const Alarm(hour: 7, minute: 0, repeat: weekdays, remindBefore: true),
      );

      await useCase.toggle(saved.id, enabled: false);

      expect(reminders.entries, isEmpty);
    });

    test('시각을 바꾸면 띄울 시각도 바꿔 건다', () async {
      final saved = await useCase.save(
        const Alarm(hour: 7, minute: 0, repeat: {Weekday.tue}, remindBefore: true),
      );

      await useCase.save(saved.copyWith(minute: 20));

      expect(reminders.entries, {
        soonId(1, tuesday7): DateTime(2026, 9, 29, 6, 50),
        soonId(1, DateTime(2026, 10, 6)): DateTime(2026, 10, 6, 6, 50),
      });
    });

    test('정의에 없는 미리 알림은 지운다', () async {
      reminders.entries[soonId(9, tuesday7)] = DateTime(2026, 9, 29, 6, 30); // 지워진 알람
      reminders.ringAts[soonId(9, tuesday7)] = tuesday7;

      await useCase.sync();

      expect(reminders.cancelCalls, [soonId(9, tuesday7)]);
    });

    test('떠 있는(띄울 시각이 지난) 미리 알림은 다시 걸지도 지우지도 않는다', () async {
      repository.alarms = [const Alarm(id: 1, hour: 7, minute: 0, repeat: weekdays, remindBefore: true)];
      await useCase.sync();
      clock.current = DateTime(2026, 9, 29, 6, 40); // 화 6:30 미리 알림이 떠 있다
      reminders.scheduleCalls.clear();

      await useCase.sync();

      expect(reminders.entries[soonId(1, tuesday7)], DateTime(2026, 9, 29, 6, 30));
      expect(reminders.scheduleCalls, isEmpty);
      expect(reminders.cancelCalls, isEmpty);
    });

    test('떠 있는 미리 알림도 울릴 시각이 바뀌면 새 시각으로 다시 건다', () async {
      final saved = await useCase.save(
        const Alarm(hour: 7, minute: 0, repeat: weekdays, remindBefore: true),
      );
      clock.current = DateTime(2026, 9, 29, 6, 40); // 화 6:30 미리 알림("7:00")이 떠 있다

      await useCase.save(saved.copyWith(hour: 8));

      expect(reminders.entries[soonId(1, tuesday7)], DateTime(2026, 9, 29, 7, 30));
      expect(reminders.reminders[soonId(1, tuesday7)]!.ringAt, DateTime(2026, 9, 29, 8));
    });

    test('떠 있는 미리 알림은 새 시각이 리드 안이면 지운다(옛 시각을 보여 주지 않는다)', () async {
      final saved = await useCase.save(
        const Alarm(hour: 7, minute: 0, repeat: weekdays, remindBefore: true),
      );
      clock.current = DateTime(2026, 9, 29, 6, 40);

      await useCase.save(saved.copyWith(minute: 5));

      expect(reminders.entries.keys, isNot(contains(soonId(1, tuesday7))));
      expect(reminders.cancelCalls, contains(soonId(1, tuesday7)));
    });

    test('떠 있는 미리 알림도 그 회차를 건너뛰면 지운다', () async {
      repository.alarms = [const Alarm(id: 1, hour: 7, minute: 0, repeat: weekdays, remindBefore: true)];
      await useCase.sync();
      clock.current = DateTime(2026, 9, 29, 6, 40);

      await useCase.skipOccurrence(pid(1, tuesday7));

      expect(reminders.entries.keys, isNot(contains(soonId(1, tuesday7))));
      expect(reminders.entries.keys, contains(soonId(1, wednesday7)));
    });

    test('떠 있는 미리 알림도 remindBefore 를 끄면 지운다', () async {
      final saved = await useCase.save(
        const Alarm(hour: 7, minute: 0, repeat: weekdays, remindBefore: true),
      );
      clock.current = DateTime(2026, 9, 29, 6, 40);

      await useCase.save(saved.copyWith(remindBefore: false));

      expect(reminders.entries, isEmpty);
    });

    group('공휴일', () {
      setUp(() => holidays.days[DateTime(2026, 9, 30)] = '테스트휴일');

      test('반복 알람의 공휴일 회차는 24시간 전에 이름과 함께 건다', () async {
        await useCase.save(const Alarm(hour: 7, minute: 0, repeat: weekdays));

        expect(reminders.entries, {holidayId(1, wednesday7): tuesday7});
        expect(reminders.reminders.values.single.holidayName, '테스트휴일');
      });

      test('설정을 끄면 걸지 않고, 걸린 것도 지운다', () async {
        await useCase.save(const Alarm(hour: 7, minute: 0, repeat: weekdays));
        settings.value = const AppSettings(holidayReminder: false);

        await useCase.sync();

        expect(reminders.entries, isEmpty);
      });

      test('24시간 전이 지났으면 지금 띄우고, 다음 sync 에서 다시 띄우지 않는다', () async {
        clock.current = DateTime(2026, 9, 29, 9);
        await useCase.save(const Alarm(hour: 7, minute: 0, repeat: weekdays));
        expect(reminders.entries, {holidayId(1, wednesday7): DateTime(2026, 9, 29, 9)});

        clock.current = DateTime(2026, 9, 29, 9, 5);
        reminders.scheduleCalls.clear();
        await useCase.sync();

        expect(reminders.scheduleCalls, isEmpty);
        expect(reminders.entries, {holidayId(1, wednesday7): DateTime(2026, 9, 29, 9)});
      });

      test('떠 있는 공휴일 알림도 울릴 시각이 바뀌면 새 문구로 다시 띄운다', () async {
        clock.current = DateTime(2026, 9, 29, 9);
        final saved = await useCase.save(const Alarm(hour: 7, minute: 0, repeat: weekdays));

        clock.current = DateTime(2026, 9, 29, 10);
        await useCase.save(saved.copyWith(hour: 8));

        final wednesday8 = DateTime(2026, 9, 30, 8);
        expect(reminders.entries, {holidayId(1, wednesday8): DateTime(2026, 9, 29, 10)});
        expect(reminders.reminders.values.single.ringAt, wednesday8);
      });

      test('1회성은 걸지 않는다', () async {
        await useCase.save(Alarm(hour: 7, minute: 0, oneShotAt: wednesday7));
        expect(reminders.entries, isEmpty);
      });
    });

    test('미리 알림이 실패해도 알람 예약은 끝난다', () async {
      reminders.failScheduled = true;

      final saved = await useCase.save(
        const Alarm(hour: 7, minute: 0, repeat: weekdays, remindBefore: true),
      );

      expect(saved.id, 1);
      expect(scheduler.entries, hasLength(4));
    });
  });

  group('쉬는 기간', () {
    // 월 9-28 정오 기준. 화 9-29 ~ 수 9-30 을 쉰다.
    final pause = AlarmPause(from: DateTime(2026, 9, 29), until: DateTime(2026, 9, 30));
    final tuesday7 = DateTime(2026, 9, 29, 7);
    final wednesday7 = DateTime(2026, 9, 30, 7);
    final thursday7 = DateTime(2026, 10, 1, 7);

    test('setPause 는 설정에 저장하고 기간 안 회차의 예약을 지운다', () async {
      await useCase.save(const Alarm(hour: 7, minute: 0, repeat: _everyDay));
      expect(scheduler.entries, contains(pid(1, tuesday7)));

      await useCase.setPause(pause);

      expect(settings.value.pause, pause);
      expect(scheduler.entries, isNot(contains(pid(1, tuesday7))));
      expect(scheduler.entries, isNot(contains(pid(1, wednesday7))));
      expect(scheduler.entries[pid(1, thursday7)], thursday7);
      expect(scheduler.entries, hasLength(12));
      // 스위치는 그대로다.
      expect(repository.alarms.single.enabled, isTrue);
    });

    test('1회성도 기간 안이면 예약하지 않고 켜 둔다', () async {
      final saved = await useCase.save(Alarm(hour: 7, minute: 0, oneShotAt: tuesday7));

      await useCase.setPause(pause);

      expect(scheduler.entries, isEmpty);
      expect(repository.alarms.single, saved);
    });

    test('곧 울릴 참인(스누즈 보존 창 안) 기간 회차도 지운다', () async {
      clock.current = DateTime(2026, 9, 29, 6, 58);
      await useCase.save(const Alarm(hour: 7, minute: 0, repeat: _everyDay));
      expect(scheduler.entries, contains(pid(1, tuesday7)));

      await useCase.setPause(pause);

      expect(scheduler.entries, isNot(contains(pid(1, tuesday7))));
    });

    test('울리는 중인 회차는 두고, 기간 밖 회차는 건드리지 않는다', () async {
      await useCase.save(const Alarm(hour: 7, minute: 0, repeat: _everyDay));
      clock.current = DateTime(2026, 9, 29, 7);
      scheduler.ringing.add(pid(1, tuesday7));
      scheduler.cancelCalls.clear();

      await useCase.setPause(pause);

      expect(scheduler.entries, contains(pid(1, tuesday7)));
      expect(scheduler.cancelCalls, [pid(1, wednesday7)]);
    });

    test('기간 회차의 미리 알림도 지운다', () async {
      await useCase.save(
        const Alarm(hour: 7, minute: 0, repeat: {Weekday.tue, Weekday.thu}, remindBefore: true),
      );
      final soonTuesday = reminderId(pid(1, tuesday7), ReminderKind.soon);
      expect(reminders.entries, contains(soonTuesday));

      await useCase.setPause(pause);

      expect(reminders.entries, isNot(contains(soonTuesday)));
      expect(reminders.entries, contains(reminderId(pid(1, thursday7), ReminderKind.soon)));
    });

    test('setPause(null) 이면 기간 회차를 다시 건다', () async {
      await useCase.save(const Alarm(hour: 7, minute: 0, repeat: _everyDay));
      await useCase.setPause(pause);

      await useCase.setPause(null);

      expect(settings.value.pause, isNull);
      expect(scheduler.entries[pid(1, tuesday7)], tuesday7);
      expect(scheduler.entries, hasLength(14));
    });

    test('sync 는 설정의 기간을 따른다(다른 엔진이 저장한 경우)', () async {
      repository.alarms = [const Alarm(id: 1, hour: 7, minute: 0, repeat: _everyDay)];
      settings.value = AppSettings(pause: pause);

      await useCase.sync();

      expect(scheduler.entries, isNot(contains(pid(1, tuesday7))));
      expect(scheduler.entries, hasLength(12));
    });

    test('끝 날이 지난 기간은 sync 가 지운다', () async {
      settings.value = AppSettings(
        stepGoal: 8000,
        pause: AlarmPause(from: DateTime(2026, 9, 26), until: DateTime(2026, 9, 27)),
      );

      await useCase.sync();

      expect(settings.value, const AppSettings(stepGoal: 8000));
    });

    test('끝 날이 오늘인 기간은 남긴다', () async {
      final today = AlarmPause(from: DateTime(2026, 9, 28), until: DateTime(2026, 9, 28));
      settings.value = AppSettings(pause: today);

      await useCase.sync();

      expect(settings.value.pause, today);
    });

    test('쉬는 중의 skipNext 는 기간 뒤 실제로 울릴 첫 회차를 건너뛴다', () async {
      repository.alarms = [const Alarm(id: 1, hour: 7, minute: 0, repeat: _everyDay)];
      settings.value = AppSettings(pause: pause);
      await useCase.sync();
      expect(scheduler.entries[pid(1, thursday7)], thursday7);

      final skipped = await useCase.skipNext(1);

      expect(skipped!.skippedAt, thursday7);
      expect(scheduler.entries, isNot(contains(pid(1, thursday7))));
      expect(await useCase.nextRings(), {1: DateTime(2026, 10, 2, 7)});
    });

    test('pause 는 저장된 기간을, 지났으면 null 을 돌려준다', () async {
      settings.value = AppSettings(pause: pause);
      expect(await useCase.pause(), pause);

      settings.value = AppSettings(
        pause: AlarmPause(from: DateTime(2026, 9, 26), until: DateTime(2026, 9, 27)),
      );
      expect(await useCase.pause(), isNull);
    });
  });

  group('건너뛰기 기록', () {
    final tuesday7 = DateTime(2026, 9, 29, 7);
    const daily = Alarm(id: 1, hour: 7, minute: 0, repeat: _everyDay);
    RingLogEntry skipped(int packageId, DateTime at) =>
        RingLogEntry(at: at, packageId: packageId, kind: RingLogKind.skipped);

    test('skipNext 는 건너뛴 회차(시각 · packageId)를 기록한다', () async {
      repository.alarms = [daily];

      await useCase.skipNext(1);

      expect(ringLog.entries, [skipped(pid(1, tuesday7), tuesday7)]);
    });

    test('skipNext 가 바꾸지 않은 알람(1회성 · 꺼짐)은 기록하지 않는다', () async {
      repository.alarms = [
        Alarm(id: 1, hour: 7, minute: 0, oneShotAt: tuesday7),
        const Alarm(id: 2, hour: 7, minute: 0, repeat: _everyDay, enabled: false),
      ];

      await useCase.skipNext(1);
      await useCase.skipNext(2);

      expect(ringLog.entries, isEmpty);
    });

    test('skipOccurrence(헤드리스 미리 알림 버튼) — 반복은 그 회차를 기록한다', () async {
      repository.alarms = [daily];
      await useCase.sync();
      final thursday7 = DateTime(2026, 10, 1, 7);

      await useCase.skipOccurrence(pid(1, thursday7));

      expect(ringLog.entries, [skipped(pid(1, thursday7), thursday7)]);
    });

    test('skipOccurrence — 1회성은 끈 회차를 기록한다', () async {
      final at = DateTime(2026, 9, 28, 12, 20);
      repository.alarms = [Alarm(id: 1, hour: 12, minute: 20, oneShotAt: at)];
      await useCase.sync();

      await useCase.skipOccurrence(pid(1, at));

      expect(ringLog.entries, [skipped(pid(1, at), at)]);
    });

    test('skipOccurrence — 지워진 알람의 회차는 기록하지 않는다', () async {
      final orphan = pid(4, tuesday7);
      scheduler.entries[orphan] = tuesday7;

      await useCase.skipOccurrence(orphan);

      expect(ringLog.entries, isEmpty);
    });

    test('기록이 실패해도 건너뛰기는 된다', () async {
      repository.alarms = [daily];
      ringLog.failAppend = true;

      final result = await useCase.skipNext(1);

      expect(result!.skippedAt, tuesday7);
      expect(repository.alarms.single.skippedAt, tuesday7);
    });
  });

  group('직렬 줄', () {
    test('저장이 한 번 실패해도 다음 호출은 끝난다', () async {
      final flaky = _FlakyRepository()..failNextSave = true;
      useCase = DefaultAlarmUseCase(
        flaky,
        scheduler,
        clock,
        reminders,
        holidays,
        settings,
        ringLog,
      );

      await expectLater(useCase.save(Alarm.draft()), throwsStateError);

      expect(await useCase.list().timeout(const Duration(seconds: 1)), isEmpty);
      final saved = await useCase.save(Alarm.draft()).timeout(const Duration(seconds: 1));
      expect(saved.id, 1);
    });
  });
}
