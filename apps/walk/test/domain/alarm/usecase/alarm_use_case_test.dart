import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_trigger.dart';
import 'package:walk/domain/alarm/repository/alarm_repository.dart';
import 'package:walk/domain/alarm/scheduler/alarm_scheduler.dart';
import 'package:walk/domain/alarm/upcoming_triggers.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/clock.dart';

class _MemoryRepository implements AlarmRepository {
  List<Alarm> alarms = [];

  @override
  Future<List<Alarm>> load() async => [...alarms];

  @override
  Future<void> save(List<Alarm> alarms) async => this.alarms = [...alarms];
}

class _FakeScheduler implements AlarmScheduler {
  final Map<int, DateTime> entries = {};
  final Map<int, Alarm> alarms = {};
  final Set<int> ringing = {};
  final List<int> scheduleCalls = [];
  final List<int> cancelCalls = [];

  @override
  Future<Map<int, DateTime>> scheduled() async => {...entries};

  @override
  Future<Set<int>> ringingIds() async => {...ringing};

  @override
  Future<void> schedule(int packageId, DateTime at, Alarm alarm) async {
    scheduleCalls.add(packageId);
    entries[packageId] = at;
    alarms[packageId] = alarm;
    ringing.remove(packageId);
  }

  @override
  Future<void> cancel(int packageId) async {
    cancelCalls.add(packageId);
    entries.remove(packageId);
    ringing.remove(packageId);
  }

  @override
  Future<void> stop(int packageId) async {
    entries.remove(packageId);
    ringing.remove(packageId);
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
  late AlarmUseCase useCase;

  // 2026-09-28 월요일 정오.
  final mondayNoon = DateTime(2026, 9, 28, 12);
  int pid(int alarmId, DateTime at) => packageId(alarmId, triggerIndex(at));

  setUp(() {
    repository = _MemoryRepository();
    scheduler = _FakeScheduler();
    clock = _MutableClock(mondayNoon);
    useCase = DefaultAlarmUseCase(repository, scheduler, clock);
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

  group('울림 처리', () {
    test('snooze 는 같은 id 를 5분 뒤로 다시 걸고 sync 뒤에도 남는다', () async {
      final saved = await useCase.save(const Alarm(hour: 12, minute: 0, repeat: _everyDay));
      final firstAt = DateTime(2026, 9, 29, 12);
      final ringingId = pid(saved.id, firstAt);
      clock.current = firstAt;
      scheduler.ringing.add(ringingId);

      await useCase.snooze(ringingId);

      expect(scheduler.entries[ringingId], firstAt.add(alarmSnoozeDuration));
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
}
