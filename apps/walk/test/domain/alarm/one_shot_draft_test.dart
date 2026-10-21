import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/one_shot_draft.dart';

void main() {
  // 2026-09-28 월요일 15:25:30.
  final now = DateTime(2026, 9, 28, 15, 25, 30);

  test('버튼 상수 · 상한', () {
    expect(oneShotSteps, const [
      Duration(hours: 1),
      Duration(minutes: 10),
      Duration(minutes: 5),
      Duration(minutes: 1),
    ]);
    expect(oneShotMaxOffset, const Duration(hours: 23, minutes: 59));
  });

  test('처음은 상대 모드 0', () {
    const draft = OneShotDraft();
    expect(draft.offset, Duration.zero);
    expect(draft.fixedAt, isNull);
    expect(draft.ringAt(now), DateTime(2026, 9, 28, 15, 25));
    expect(draft.remaining(now), Duration.zero);
    expect(draft.canSave(now), isFalse);
  });

  group('add', () {
    test('상대 모드면 offset 에 쌓는다', () {
      final draft = const OneShotDraft()
          .add(const Duration(hours: 1))
          .add(const Duration(minutes: 10))
          .add(const Duration(minutes: 10))
          .add(const Duration(minutes: 5));

      expect(
        draft,
        const OneShotDraft(offset: Duration(hours: 1, minutes: 25)),
      );
      expect(draft.ringAt(now), DateTime(2026, 9, 28, 16, 50));
    });

    test('상대 모드 상한 23시간 59분에서 멈춘다', () {
      var draft = const OneShotDraft();
      for (var i = 0; i < 30; i++) {
        draft = draft.add(const Duration(hours: 1));
      }
      expect(draft.offset, oneShotMaxOffset);
      expect(
        const OneShotDraft(
          offset: Duration(hours: 23, minutes: 58),
        ).add(const Duration(minutes: 5)).offset,
        oneShotMaxOffset,
      );
    });

    test('고정 모드면 fixedAt 에 더한다(offset 은 그대로)', () {
      final fixed = OneShotDraft(fixedAt: DateTime(2026, 9, 28, 16, 50));

      final added = fixed
          .add(const Duration(hours: 1))
          .add(const Duration(minutes: 5));

      expect(added.fixedAt, DateTime(2026, 9, 28, 17, 55));
      expect(added.offset, Duration.zero);
    });

    test('고정 모드에서 자정을 넘기면 다음 날 시각', () {
      final fixed = OneShotDraft(fixedAt: DateTime(2026, 9, 28, 23, 30));

      expect(
        fixed.add(const Duration(hours: 1)).fixedAt,
        DateTime(2026, 9, 29, 0, 30),
      );
    });
  });

  test('reset 은 상대 모드 0 으로', () {
    expect(
      const OneShotDraft(offset: Duration(minutes: 10)).reset(),
      const OneShotDraft(),
    );
    expect(
      OneShotDraft(fixedAt: DateTime(2026, 9, 28, 16)).reset(),
      const OneShotDraft(),
    );
  });

  group('fixAt', () {
    test('오늘 아직 안 지난 시각이면 오늘', () {
      expect(
        const OneShotDraft(offset: Duration(minutes: 5)).fixAt(16, 50, now),
        OneShotDraft(fixedAt: DateTime(2026, 9, 28, 16, 50)),
      );
    });

    test('지났거나 지금과 같은 분이면 내일(초는 0)', () {
      expect(
        const OneShotDraft().fixAt(9, 0, now).fixedAt,
        DateTime(2026, 9, 29, 9),
      );
      expect(
        const OneShotDraft().fixAt(15, 25, now).fixedAt,
        DateTime(2026, 9, 29, 15, 25),
      );
    });
  });

  group('ringAt · remaining', () {
    test('상대 모드는 지금이 든 분(초 0) + offset — 칩에 보인 분에 울린다', () {
      const draft = OneShotDraft(offset: Duration(minutes: 10));
      final later = now.add(const Duration(minutes: 3)); // 15:28:30

      expect(draft.ringAt(later), DateTime(2026, 9, 28, 15, 38));
      expect(draft.remaining(later), const Duration(minutes: 9, seconds: 30));
    });

    test('상대 모드 — 같은 분 안이면 몇 초에 저장해도 같은 시각', () {
      const draft = OneShotDraft(offset: Duration(minutes: 10));

      for (final second in [0, 1, 30, 59]) {
        expect(
          draft.ringAt(DateTime(2026, 9, 28, 15, 25, second, 999)),
          DateTime(2026, 9, 28, 15, 35),
          reason: '15:25:$second',
        );
      }
    });

    test('상대 모드 — 내림해서 1분 미만이 되면 한 분 미룬다', () {
      const draft = OneShotDraft(offset: Duration(minutes: 1));

      // 15:25:30 + 1분 → 15:26 은 30초 뒤라 15:27.
      expect(draft.ringAt(now), DateTime(2026, 9, 28, 15, 27));
      expect(
        draft.remaining(now),
        greaterThanOrEqualTo(const Duration(minutes: 1)),
      );
      // 정각이면 그대로 1분 뒤.
      expect(
        draft.ringAt(DateTime(2026, 9, 28, 15, 25)),
        DateTime(2026, 9, 28, 15, 26),
      );
    });

    test('상대 모드 — 자정을 넘기면 다음 날 시각', () {
      const draft = OneShotDraft(offset: Duration(minutes: 40));

      expect(
        draft.ringAt(DateTime(2026, 9, 28, 23, 50, 12)),
        DateTime(2026, 9, 29, 0, 30),
      );
    });

    test('고정 모드는 fixedAt, 남은 시간은 줄어든다', () {
      final draft = OneShotDraft(fixedAt: DateTime(2026, 9, 28, 16, 50));

      expect(draft.ringAt(now), DateTime(2026, 9, 28, 16, 50));
      expect(
        draft.remaining(now),
        const Duration(hours: 1, minutes: 24, seconds: 30),
      );
    });

    test('지난 fixedAt 이면 남은 시간 0', () {
      final draft = OneShotDraft(fixedAt: DateTime(2026, 9, 28, 15));

      expect(draft.remaining(now), Duration.zero);
    });
  });

  group('canSave — 1분 경계', () {
    test('상대 모드: 1분이면 되고 그 아래는 안 된다', () {
      expect(
        const OneShotDraft(offset: Duration(minutes: 1)).canSave(now),
        isTrue,
      );
      expect(
        const OneShotDraft(offset: Duration(seconds: 59)).canSave(now),
        isFalse,
      );
      expect(const OneShotDraft().canSave(now), isFalse);
    });

    test('고정 모드: 남은 시간이 1분 이상이어야 한다', () {
      final draft = OneShotDraft(fixedAt: DateTime(2026, 9, 28, 15, 27));

      expect(draft.canSave(DateTime(2026, 9, 28, 15, 26)), isTrue);
      expect(draft.canSave(DateTime(2026, 9, 28, 15, 26, 1)), isFalse);
    });
  });

  group('fromAlarm', () {
    test('oneShotAt 이 미래면 고정 모드', () {
      final at = DateTime(2026, 9, 28, 16, 50, 30);
      final alarm = Alarm(id: 1, hour: 16, minute: 50, oneShotAt: at);

      expect(OneShotDraft.fromAlarm(alarm, now), OneShotDraft(fixedAt: at));
    });

    test('oneShotAt 이 지났거나 지금이면 상대 모드 0', () {
      for (final at in [DateTime(2026, 9, 28, 7), now]) {
        final alarm = Alarm(
          id: 1,
          hour: at.hour,
          minute: at.minute,
          oneShotAt: at,
        );
        expect(
          OneShotDraft.fromAlarm(alarm, now),
          const OneShotDraft(),
          reason: '$at',
        );
      }
    });

    test('oneShotAt 이 없으면(새 알람) 상대 모드 0', () {
      expect(OneShotDraft.fromAlarm(Alarm.draft(), now), const OneShotDraft());
    });
  });
}
