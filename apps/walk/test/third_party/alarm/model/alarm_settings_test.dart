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
}
