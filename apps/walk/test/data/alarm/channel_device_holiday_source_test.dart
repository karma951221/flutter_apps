import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/alarm/channel_device_holiday_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(ChannelDeviceHolidaySource.channelName);
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  void answer(Object? Function(MethodCall call) reply) {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return reply(call);
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('채널 이름은 walk/holidays', () {
    expect(ChannelDeviceHolidaySource.channelName, 'walk/holidays');
  });

  group('read', () {
    test('범위를 날짜 문자열로 넘기고 응답을 날짜 · 이름으로 옮긴다', () async {
      answer(
        (_) => [
          {'date': '2026-10-09', 'name': '한글날'},
          {'date': '2026-12-25', 'name': '기독탄신일'},
        ],
      );

      final days = await const ChannelDeviceHolidaySource().read(
        DateTime(2026, 10, 7, 13, 5),
        DateTime(2027, 11, 11),
      );

      expect(calls.single.method, 'read');
      expect(calls.single.arguments, {'from': '2026-10-07', 'to': '2027-11-11'});
      expect(days, [
        (date: DateTime(2026, 10, 9), name: '한글날'),
        (date: DateTime(2026, 12, 25), name: '기독탄신일'),
      ]);
    });

    test('깨진 행은 건너뛴다', () async {
      answer(
        (_) => [
          {'date': 'nope', 'name': 'x'},
          {'date': '2026-10-09'},
          {'date': '2026-10-09', 'name': '한글날'},
        ],
      );
      final days = await const ChannelDeviceHolidaySource().read(
        DateTime(2026, 10, 7),
        DateTime(2026, 12, 31),
      );
      expect(days, [(date: DateTime(2026, 10, 9), name: '한글날')]);
    });

    test('권한 없음 · 휴일 캘린더 없음(null 응답)은 null', () async {
      answer((_) => null);
      expect(await const ChannelDeviceHolidaySource().read(DateTime(2026), DateTime(2027)), isNull);
    });

    test('오류는 null', () async {
      answer((_) => throw PlatformException(code: 'failed'));
      expect(await const ChannelDeviceHolidaySource().read(DateTime(2026), DateTime(2027)), isNull);
    });

    test('채널이 없으면 null', () async {
      expect(await const ChannelDeviceHolidaySource().read(DateTime(2026), DateTime(2027)), isNull);
    });
  });

  group('calendarName', () {
    test('이름을 그대로 돌려준다', () async {
      answer((_) => '대한민국의 휴일');
      expect(await const ChannelDeviceHolidaySource().calendarName(), '대한민국의 휴일');
      expect(calls.single.method, 'calendarName');
    });

    test('오류 · 채널 없음은 null', () async {
      answer((_) => throw PlatformException(code: 'failed'));
      expect(await const ChannelDeviceHolidaySource().calendarName(), isNull);
      messenger.setMockMethodCallHandler(channel, null);
      expect(await const ChannelDeviceHolidaySource().calendarName(), isNull);
    });
  });
}
