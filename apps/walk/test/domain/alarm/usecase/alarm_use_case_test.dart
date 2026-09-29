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
  final Map<int, Alarm> alarms = {};
  final Set<int> ringing = {};
  final List<int> scheduleCalls = [];
  final List<int> cancelCalls = [];

  /// 패키지는 `stop` 안에서 울림 스트림을 비운다 — 그걸 보고 울림 화면이 걷히고 목록이
  /// 다시 읽는 순간을 흉내 낸다.
  void Function(int packageId)? onStop;

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
    onStop?.call(packageId);
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

  group('직렬 줄', () {
    test('저장이 한 번 실패해도 다음 호출은 끝난다', () async {
      final flaky = _FlakyRepository()..failNextSave = true;
      useCase = DefaultAlarmUseCase(flaky, scheduler, clock);

      await expectLater(useCase.save(Alarm.draft()), throwsStateError);

      expect(await useCase.list().timeout(const Duration(seconds: 1)), isEmpty);
      final saved = await useCase.save(Alarm.draft()).timeout(const Duration(seconds: 1));
      expect(saved.id, 1);
    });
  });
}
