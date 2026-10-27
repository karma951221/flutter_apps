import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/archived_ring.dart';
import 'package:walk/domain/alarm/entity/ring_log_entry.dart';
import 'package:walk/domain/alarm/ring_log/ring_archive.dart';
import 'package:walk/domain/alarm/ring_log/ring_log_source.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/alarm/usecase/ring_archiver.dart';

class _MockRingLog extends Mock implements RingLogSource {}

class _MockAlarms extends Mock implements AlarmUseCase {}

class _MemoryArchive implements RingArchive {
  final saved = <ArchivedRing>[];

  @override
  Future<void> saveAll(List<ArchivedRing> rings) async => saved.addAll(rings);

  @override
  Future<List<ArchivedRing>> read({required DateTime from, required DateTime to}) async => saved;
}

void main() {
  late _MockRingLog ringLog;
  late _MockAlarms alarms;
  late _MemoryArchive archive;
  late RingArchiver archiver;

  setUpAll(() => registerFallbackValue(DateTime(2000)));

  setUp(() {
    ringLog = _MockRingLog();
    alarms = _MockAlarms();
    archive = _MemoryArchive();
    archiver = RingArchiver(ringLog, archive, alarms);
    when(() => alarms.list()).thenAnswer((_) async => const [Alarm(id: 3, hour: 7, minute: 0, label: '출근')]);
  });

  test('네이티브 기록을 알람 라벨 · 시각과 함께 옮긴다', () async {
    final entry = RingLogEntry(at: DateTime(2026, 10, 2, 7), packageId: 305, kind: RingLogKind.stopped);
    when(() => ringLog.read(since: any(named: 'since'))).thenAnswer((_) async => [entry]);

    await archiver.archive();

    verify(() => ringLog.read(since: DateTime.fromMillisecondsSinceEpoch(0))).called(1);
    expect(archive.saved, hasLength(1));
    expect(archive.saved.single.entry, entry);
    expect(archive.saved.single.label, '출근');
    expect(archive.saved.single.hour, 7);
    expect(archive.saved.single.minute, 0);
  });

  test('알람이 없으면 label · hour · minute 이 null', () async {
    final entry = RingLogEntry(at: DateTime(2026, 10, 2, 7), packageId: 905, kind: RingLogKind.rang);
    when(() => ringLog.read(since: any(named: 'since'))).thenAnswer((_) async => [entry]);

    await archiver.archive();

    expect(archive.saved.single.label, isNull);
    expect(archive.saved.single.hour, isNull);
    expect(archive.saved.single.minute, isNull);
  });

  test('동시에 두 번 부르면 차례로 돈다', () async {
    final gate = Completer<List<RingLogEntry>>();
    when(() => ringLog.read(since: any(named: 'since'))).thenAnswer((_) => gate.future);

    final first = archiver.archive();
    final second = archiver.archive();
    await Future<void>.delayed(Duration.zero);
    verify(() => ringLog.read(since: any(named: 'since'))).called(1);

    gate.complete(const []);
    await Future.wait([first, second]);
    verify(() => ringLog.read(since: any(named: 'since'))).called(1);
  });
}
