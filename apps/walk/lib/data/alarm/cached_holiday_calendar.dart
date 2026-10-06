import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/alarm/holiday/device_holiday_source.dart';
import '../../domain/alarm/holiday/holiday_calendar.dart';
import '../../domain/alarm/holiday/korean_holidays.dart';

/// 폰 캘린더를 하루 한 번 읽어 [cacheKey] 에 두고 그것으로 답한다. 캐시가 없거나(권한 없음 ·
/// 휴일 캘린더 없음) 오래됐거나 날짜가 읽은 범위 밖이면 내장 표([KoreanHolidayCalendar]).
///
/// 알람 sync 는 캐시만 읽는다 — 헤드리스 엔진에서도 빠르고, 같은 저장소라 엔진끼리 공유된다.
/// 폰 캘린더에 휴일 캘린더가 있으면 그 범위 안에서는 그것만 본다(임시공휴일을 먼저 반영한다).
@lazySingleton
class CachedHolidayCalendar implements HolidayCalendar, HolidayRefresher {
  CachedHolidayCalendar(this._prefs, this._device, this._clock);

  final SharedPreferences _prefs;
  final DeviceHolidaySource _device;
  final Clock _clock;
  final HolidayCalendar _bundled = const KoreanHolidayCalendar();

  static const cacheKey = 'walk.holidays.cache';

  /// 오늘부터 읽는 날 수.
  static const rangeDays = 400;

  /// 이보다 오래된 캐시는 믿지 않는다(그동안 새로 못 읽었다).
  static const maxAge = Duration(days: 30);

  /// 마지막으로 푼 저장 문자열과 그 결과. 저장소가 바뀌면(다른 엔진이 썼을 때도) 다시 푼다.
  String? _parsedRaw;
  _Cache? _parsed;

  @override
  String? nameOf(DateTime date) {
    final cache = _validCache();
    final day = DateTime(date.year, date.month, date.day);
    if (cache == null || day.isBefore(cache.from) || day.isAfter(cache.to)) {
      return _bundled.nameOf(date);
    }
    return cache.days[_key(day)];
  }

  @override
  HolidaySource get source {
    final cache = _validCache();
    return cache == null ? _bundled.source : HolidaySource.device(calendarName: cache.calendarName);
  }

  @override
  Future<void> refresh({bool force = false}) async {
    try {
      final now = _clock.now();
      final today = DateTime(now.year, now.month, now.day);
      if (!force && _readOn() == today) return;
      final to = DateTime(today.year, today.month, today.day + rangeDays);
      final days = await _device.read(today, to);
      final name = days == null ? null : await _device.calendarName();
      await _prefs.setString(
        cacheKey,
        jsonEncode({
          'readAt': now.toIso8601String(),
          if (days != null) ...{
            'calendarName': name ?? '',
            'from': _key(today),
            'to': _key(to),
            'days': {for (final d in days) _key(d.date): d.name},
          },
        }),
      );
    } on Object catch (e) {
      // 읽기 실패는 지난 캐시(또는 내장 표)로 버틴다.
      debugPrint('holiday refresh failed: $e');
    }
  }

  /// 마지막으로 읽은 날(로컬 날짜). 폰 캘린더가 없었어도 기록한다 — 하루 한 번만 묻는다.
  DateTime? _readOn() {
    final raw = _prefs.get(cacheKey);
    if (raw is! String) return null;
    try {
      if (jsonDecode(raw) case {'readAt': final String at}) {
        final read = DateTime.tryParse(at);
        return read == null ? null : DateTime(read.year, read.month, read.day);
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  _Cache? _validCache() {
    final cache = _load();
    if (cache == null) return null;
    if (_clock.now().difference(cache.readAt) > maxAge) return null;
    return cache;
  }

  _Cache? _load() {
    final raw = _prefs.get(cacheKey);
    if (raw is! String) return null;
    if (raw == _parsedRaw) return _parsed;
    _parsedRaw = raw;
    return _parsed = _Cache.parse(raw);
  }

  static String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// 폰 캘린더를 읽은 결과. 휴일 캘린더가 없었던 기록은 null 로 푼다.
class _Cache {
  const _Cache(this.readAt, this.calendarName, this.from, this.to, this.days);

  final DateTime readAt;
  final String calendarName;
  final DateTime from;
  final DateTime to;
  final Map<String, String> days;

  static _Cache? parse(String raw) {
    try {
      if (jsonDecode(raw) case {
        'readAt': final String readAt,
        'calendarName': final String name,
        'from': final String from,
        'to': final String to,
        'days': final Map<String, Object?> days,
      }) {
        final read = DateTime.tryParse(readAt);
        final start = DateTime.tryParse(from);
        final end = DateTime.tryParse(to);
        if (read == null || start == null || end == null) return null;
        return _Cache(read, name, start, end, {
          for (final MapEntry(:key, :value) in days.entries)
            if (value is String) key: value,
        });
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}
