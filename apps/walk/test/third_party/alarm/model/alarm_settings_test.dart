import 'package:alarm/alarm.dart';
import 'package:flutter_test/flutter_test.dart';

/// 포크(`third_party/alarm/lib/model/alarm_settings.dart`)에서 바꾼 필드.
/// 포크 자체의 `flutter test` 는 돌리지 않으므로 앱 테스트에서 확인한다(FORK.md).
void main() {
  const beep = 'assets/alarm/default.wav';

  AlarmSettings settings({String? fallback}) => AlarmSettings(
    id: 312,
    dateTime: DateTime(2026, 10, 6, 7, 5),
    assetAudioPath: '/data/user/0/app/app_flutter/alarm_sounds/abc.ogg',
    volumeSettings: VolumeSettings.fade(
      volume: 0.8,
      fadeDuration: const Duration(seconds: 3),
    ),
    notificationSettings: const NotificationSettings(
      title: '알람',
      body: '오전 7:05',
    ),
    androidFallbackAudioPath: fallback,
  );

  group('androidFallbackAudioPath', () {
    test('기본은 null', () {
      final plain = AlarmSettings(
        id: 312,
        dateTime: DateTime(2026, 10, 6, 7, 5),
        volumeSettings: VolumeSettings.fixed(),
        notificationSettings: const NotificationSettings(
          title: '알람',
          body: '오전 7:05',
        ),
      );

      expect(plain.androidFallbackAudioPath, isNull);
    });

    test('json 왕복', () {
      final original = settings(fallback: beep);

      final restored = AlarmSettings.fromJson(original.toJson());

      expect(restored.androidFallbackAudioPath, beep);
      expect(restored, original);
    });

    test('null 도 json 왕복', () {
      final original = settings();

      final restored = AlarmSettings.fromJson(original.toJson());

      expect(restored.androidFallbackAudioPath, isNull);
      expect(restored, original);
    });

    test('키가 없는 옛 json 은 null', () {
      final json = settings(fallback: beep).toJson()
        ..remove('androidFallbackAudioPath');

      expect(AlarmSettings.fromJson(json).androidFallbackAudioPath, isNull);
    });

    test('값이 다르면 다른 설정', () {
      expect(settings(fallback: beep), isNot(settings()));
    });

    test('네이티브로 넘긴다', () {
      expect(settings(fallback: beep).toWire().androidFallbackAudioPath, beep);
    });

    test('copyWith 로 바꾸고 지운다', () {
      final withFallback = settings().copyWith(
        androidFallbackAudioPath: () => beep,
      );

      expect(withFallback.androidFallbackAudioPath, beep);
      expect(withFallback.copyWith().androidFallbackAudioPath, beep);
      expect(
        withFallback
            .copyWith(androidFallbackAudioPath: () => null)
            .androidFallbackAudioPath,
        isNull,
      );
    });
  });

  group('androidSilentWhenRingerMuted', () {
    test('기본은 false', () {
      expect(settings().androidSilentWhenRingerMuted, isFalse);
    });

    test('json 왕복', () {
      final original = settings().copyWith(androidSilentWhenRingerMuted: true);

      final restored = AlarmSettings.fromJson(original.toJson());

      expect(restored.androidSilentWhenRingerMuted, isTrue);
      expect(restored, original);
    });

    test('키가 없는 옛 json 은 false', () {
      final json =
          settings().copyWith(androidSilentWhenRingerMuted: true).toJson()
            ..remove('androidSilentWhenRingerMuted');

      expect(
        AlarmSettings.fromJson(json).androidSilentWhenRingerMuted,
        isFalse,
      );
    });

    test('값이 다르면 다른 설정', () {
      expect(
        settings().copyWith(androidSilentWhenRingerMuted: true),
        isNot(settings()),
      );
    });

    test('네이티브로 넘긴다', () {
      final on = settings().copyWith(androidSilentWhenRingerMuted: true);

      expect(on.toWire().androidSilentWhenRingerMuted, isTrue);
      expect(settings().toWire().androidSilentWhenRingerMuted, isFalse);
    });

    test('copyWith 는 주지 않으면 유지한다', () {
      final on = settings().copyWith(androidSilentWhenRingerMuted: true);

      expect(on.copyWith().androidSilentWhenRingerMuted, isTrue);
      expect(
        on
            .copyWith(androidSilentWhenRingerMuted: false)
            .androidSilentWhenRingerMuted,
        isFalse,
      );
    });
  });

  group('스누즈 횟수', () {
    AlarmSettings snoozable({int? limit, int count = 0}) => settings().copyWith(
      androidSnoozeDuration: () => const Duration(minutes: 5),
      notificationSettings: const NotificationSettings(
        title: '알람',
        body: '오전 7:05',
        androidSnoozeButton: '5분 뒤',
      ),
      androidSnoozeLimit: () => limit,
      snoozeCount: count,
    );

    test('기본은 0회 · 한도 없음', () {
      expect(settings().snoozeCount, 0);
      expect(settings().androidSnoozeLimit, isNull);
    });

    test('스누즈하면 시각을 옮기고 하나 센다', () {
      final next = DateTime(2026, 10, 6, 7, 10);

      final snoozed = snoozable().nextAfterSnooze(next);

      expect(snoozed.dateTime, next);
      expect(snoozed.snoozeCount, 1);
    });

    test('한도가 없으면 계속 스누즈할 수 있다', () {
      var current = snoozable();
      for (var i = 0; i < 10; i++) {
        current = current.nextAfterSnooze(
          current.dateTime.add(const Duration(minutes: 5)),
        );
      }

      expect(current.snoozeCount, 10);
      expect(current.androidSnoozeDuration, const Duration(minutes: 5));
      expect(current.notificationSettings.androidSnoozeButton, '5분 뒤');
    });

    test('한도 3 이면 두 번째 스누즈 뒤에도 스누즈가 남는다', () {
      final second = snoozable(limit: 3)
          .nextAfterSnooze(DateTime(2026, 10, 6, 7, 10))
          .nextAfterSnooze(DateTime(2026, 10, 6, 7, 15));

      expect(second.snoozeCount, 2);
      expect(second.androidSnoozeDuration, const Duration(minutes: 5));
      expect(second.notificationSettings.androidSnoozeButton, '5분 뒤');
    });

    test('한도 3 이면 세 번째 스누즈 뒤 설정에 스누즈가 없다', () {
      final third = snoozable(
        limit: 3,
        count: 2,
      ).nextAfterSnooze(DateTime(2026, 10, 6, 7, 20));

      expect(third.snoozeCount, 3);
      expect(third.androidSnoozeLimit, 3);
      expect(third.androidSnoozeDuration, isNull);
      expect(third.notificationSettings.androidSnoozeButton, isNull);
    });

    test('json 왕복', () {
      final original = snoozable(limit: 3, count: 2);

      final restored = AlarmSettings.fromJson(original.toJson());

      expect(restored.snoozeCount, 2);
      expect(restored.androidSnoozeLimit, 3);
      expect(restored, original);
    });

    test('키가 없는 옛 json 은 0회 · 한도 없음', () {
      final json = snoozable(limit: 3, count: 2).toJson()
        ..remove('snoozeCount')
        ..remove('androidSnoozeLimit');

      final restored = AlarmSettings.fromJson(json);

      expect(restored.snoozeCount, 0);
      expect(restored.androidSnoozeLimit, isNull);
    });

    test('값이 다르면 다른 설정', () {
      expect(snoozable(count: 1), isNot(snoozable()));
      expect(snoozable(limit: 3), isNot(snoozable()));
    });

    test('네이티브로 넘긴다', () {
      final wire = snoozable(limit: 3, count: 2).toWire();

      expect(wire.snoozeCount, 2);
      expect(wire.androidSnoozeLimit, 3);
      expect(snoozable().toWire().androidSnoozeLimit, isNull);
    });

    test('copyWith 로 한도를 지운다', () {
      final limited = snoozable(limit: 3);

      expect(limited.copyWith().androidSnoozeLimit, 3);
      expect(
        limited.copyWith(androidSnoozeLimit: () => null).androidSnoozeLimit,
        isNull,
      );
    });
  });

  group('androidAutoStopAfter', () {
    const tenMinutes = Duration(minutes: 10);

    test('기본은 null', () {
      expect(settings().androidAutoStopAfter, isNull);
    });

    test('json 왕복', () {
      final original = settings().copyWith(
        androidAutoStopAfter: () => tenMinutes,
      );

      final restored = AlarmSettings.fromJson(original.toJson());

      expect(restored.androidAutoStopAfter, tenMinutes);
      expect(restored, original);
    });

    test('키가 없는 옛 json 은 null', () {
      final json = settings()
          .copyWith(androidAutoStopAfter: () => tenMinutes)
          .toJson()
        ..remove('androidAutoStopAfter');

      expect(AlarmSettings.fromJson(json).androidAutoStopAfter, isNull);
    });

    test('값이 다르면 다른 설정', () {
      expect(
        settings().copyWith(androidAutoStopAfter: () => tenMinutes),
        isNot(settings()),
      );
    });

    test('네이티브로 밀리초를 넘긴다', () {
      final on = settings().copyWith(androidAutoStopAfter: () => tenMinutes);

      expect(on.toWire().androidAutoStopAfterMillis, 600000);
      expect(settings().toWire().androidAutoStopAfterMillis, isNull);
    });

    test('copyWith 로 바꾸고 지운다', () {
      final on = settings().copyWith(androidAutoStopAfter: () => tenMinutes);

      expect(on.copyWith().androidAutoStopAfter, tenMinutes);
      expect(
        on.copyWith(androidAutoStopAfter: () => null).androidAutoStopAfter,
        isNull,
      );
    });
  });
}
