import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../domain/alarm/holiday/device_holiday_source.dart';

/// `HolidayCalendarChannel.kt`(`walk/holidays`)로 폰 캘린더의 휴일 캘린더를 읽는다.
/// 날짜는 `yyyy-MM-dd` 문자열로 주고받는다 — 종일 일정이라 시간대를 타지 않게.
/// 네이티브가 null 을 주거나(권한 없음 · 휴일 캘린더 없음) 실패 · 채널 없음이면 null.
@LazySingleton(as: DeviceHolidaySource)
class ChannelDeviceHolidaySource implements DeviceHolidaySource {
  const ChannelDeviceHolidaySource();

  static const channelName = 'walk/holidays';
  static const _channel = MethodChannel(channelName);

  @override
  Future<List<DeviceHoliday>?> read(DateTime from, DateTime to) async {
    final rows = await _invoke<List<Object?>>('read', {'from': _day(from), 'to': _day(to)});
    if (rows == null) return null;
    return [
      for (final row in rows)
        if (row case {'date': final String date, 'name': final String name})
          if (_parse(date) case final day?) (date: day, name: name),
    ];
  }

  @override
  Future<String?> calendarName() => _invoke<String>('calendarName');

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

  static String _two(int n) => n.toString().padLeft(2, '0');

  static DateTime? _parse(String text) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }
}
