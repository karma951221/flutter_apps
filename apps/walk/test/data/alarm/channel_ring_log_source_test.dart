import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/alarm/channel_ring_log_source.dart';
import 'package:walk/domain/alarm/entity/ring_log_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(ChannelRingLogSource.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  const source = ChannelRingLogSource();

  void answer(Object? Function(MethodCall call) reply) {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return reply(call);
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  final monday7 = DateTime(2026, 10, 5, 7);
  final ms = monday7.millisecondsSinceEpoch;

  test('채널 이름은 walk/ring_log', () {
    expect(ChannelRingLogSource.channelName, 'walk/ring_log');
  });

  group('read', () {
    test('JSON 줄을 기록으로 옮기고 since 이전은 뺀다', () async {
      answer(
        (_) => [
          '{"at":${ms - 1},"packageId":100,"kind":"rang"}',
          '{"at":$ms,"packageId":101,"kind":"rang"}',
          '{"at":${ms + 60000},"packageId":101,"kind":"snoozed"}',
          '{"at":${ms + 120000},"packageId":101,"kind":"autoStopped"}',
        ],
      );

      final entries = await source.read(since: monday7);

      expect(calls.single.method, 'read');
      expect(entries, [
        RingLogEntry(at: monday7, packageId: 101, kind: RingLogKind.rang),
        RingLogEntry(
          at: monday7.add(const Duration(minutes: 1)),
          packageId: 101,
          kind: RingLogKind.snoozed,
        ),
        RingLogEntry(
          at: monday7.add(const Duration(minutes: 2)),
          packageId: 101,
          kind: RingLogKind.autoStopped,
        ),
      ]);
    });

    test('깨진 줄 · 모르는 종류는 건너뛴다', () async {
      answer(
        (_) => [
          'nope',
          '{"at":$ms,"packageId":101}',
          '{"at":$ms,"packageId":101,"kind":"dropped"}',
          '{"at":$ms,"packageId":101,"kind":"stopped"}',
        ],
      );

      expect(await source.read(since: monday7), [
        RingLogEntry(at: monday7, packageId: 101, kind: RingLogKind.stopped),
      ]);
    });

    test('채널이 없으면 빈 목록, 네이티브 오류는 던진다', () async {
      expect(await source.read(since: monday7), isEmpty);

      answer((_) => throw PlatformException(code: 'failed'));
      await expectLater(
        source.read(since: monday7),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('append', () {
    test('at(epoch millis) · packageId · kind 이름을 넘긴다', () async {
      answer((_) => null);

      await source.append(
        RingLogEntry(at: monday7, packageId: 101, kind: RingLogKind.skipped),
      );

      expect(calls.single.method, 'append');
      expect(calls.single.arguments, {
        'at': ms,
        'packageId': 101,
        'kind': 'skipped',
      });
    });

    test('채널이 없으면 무시한다', () async {
      await source.append(
        RingLogEntry(at: monday7, packageId: 101, kind: RingLogKind.skipped),
      );
    });
  });
}
