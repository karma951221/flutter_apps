import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/alarm/cached_holiday_calendar.dart';
import 'package:walk/domain/alarm/holiday/device_holiday_source.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar.dart';

class _MutableClock extends Clock {
  _MutableClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

class _FakeDevice implements DeviceHolidaySource {
  List<DeviceHoliday>? days;
  String? name = '대한민국의 휴일';
  Object? error;
  final reads = <(DateTime, DateTime)>[];

  @override
  Future<List<DeviceHoliday>?> read(DateTime from, DateTime to) async {
    reads.add((from, to));
    if (error case final e?) throw e;
    return days;
  }

  @override
  Future<String?> calendarName() async => name;
}

void main() {
  late SharedPreferences prefs;
  late _FakeDevice device;
  late _MutableClock clock;

  CachedHolidayCalendar calendar() => CachedHolidayCalendar(prefs, device, clock);

  const bundled = HolidaySource.bundled(firstYear: 2026, lastYear: 2027);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    device = _FakeDevice()
      ..days = [
        // 폰 캘린더에만 있는 임시공휴일. 한글날은 일부러 뺐다 — 폰 캘린더가 있으면 그것만 본다.
        (date: DateTime(2026, 11, 2), name: '임시공휴일'),
        (date: DateTime(2026, 12, 25), name: '기독탄신일'),
      ];
    clock = _MutableClock(DateTime(2026, 10, 7, 9, 30));
  });

  test('캐시가 없으면 내장 표', () {
    final c = calendar();
    expect(c.source, bundled);
    expect(c.nameOf(DateTime(2026, 10, 9)), '한글날');
    expect(c.nameOf(DateTime(2026, 11, 2)), isNull);
  });

  test('refresh 는 오늘부터 400일을 읽어 캐시하고, 이후 폰 캘린더로 답한다', () async {
    final c = calendar();
    await c.refresh();

    expect(device.reads.single, (DateTime(2026, 10, 7), DateTime(2027, 11, 11)));
    expect(c.source, const HolidaySource.device(calendarName: '대한민국의 휴일'));
    expect(c.nameOf(DateTime(2026, 11, 2, 7)), '임시공휴일');
    expect(c.nameOf(DateTime(2026, 12, 25)), '기독탄신일');
    expect(c.nameOf(DateTime(2026, 10, 9)), isNull);
    expect(prefs.getString(CachedHolidayCalendar.cacheKey), isNotNull);
  });

  test('캐시는 새 인스턴스(헤드리스 엔진)에서도 읽힌다', () async {
    await calendar().refresh();

    final fresh = calendar();
    expect(fresh.source, const HolidaySource.device(calendarName: '대한민국의 휴일'));
    expect(fresh.nameOf(DateTime(2026, 11, 2)), '임시공휴일');
  });

  test('하루 한 번만 읽는다 — 같은 날은 건너뛰고, 다음 날이나 force 면 다시 읽는다', () async {
    final c = calendar();
    await c.refresh();
    clock.value = DateTime(2026, 10, 7, 23, 59);
    await c.refresh();
    expect(device.reads, hasLength(1));

    await c.refresh(force: true);
    expect(device.reads, hasLength(2));

    clock.value = DateTime(2026, 10, 8, 0, 1);
    await c.refresh();
    expect(device.reads, hasLength(3));
  });

  test('폰 캘린더가 없으면(null) 내장 표로 돌아가고, 그날은 다시 읽지 않는다', () async {
    final c = calendar();
    await c.refresh();
    expect(c.source, isA<DeviceCalendarHolidays>());

    device.days = null;
    clock.value = DateTime(2026, 10, 8, 8);
    await c.refresh();

    expect(c.source, bundled);
    expect(c.nameOf(DateTime(2026, 10, 9)), '한글날');
    expect(c.nameOf(DateTime(2026, 11, 2)), isNull);

    await c.refresh();
    expect(device.reads, hasLength(2));
  });

  test('캘린더 이름이 없어도 폰 캘린더 출처', () async {
    device.name = null;
    final c = calendar();
    await c.refresh();
    expect(c.source, const HolidaySource.device(calendarName: ''));
  });

  test('읽기가 던져도 refresh 는 끝나고 캐시는 그대로', () async {
    final c = calendar();
    await c.refresh();
    device.error = StateError('boom');

    await c.refresh(force: true);

    expect(c.source, const HolidaySource.device(calendarName: '대한민국의 휴일'));
  });

  test('캐시가 오래되면(maxAge 넘음) 내장 표', () async {
    final c = calendar();
    await c.refresh();

    clock.value = DateTime(2026, 10, 7).add(CachedHolidayCalendar.maxAge + const Duration(days: 1));
    expect(c.source, bundled);
    expect(c.nameOf(DateTime(2026, 12, 25)), '성탄절');
  });

  test('캐시 범위 밖 날짜는 내장 표로 답한다', () async {
    final c = calendar();
    await c.refresh();

    expect(c.nameOf(DateTime(2027, 12, 27)), '성탄절 대체공휴일');
    expect(c.nameOf(DateTime(2026, 10, 5)), '개천절 대체공휴일');
  });

  test('깨진 캐시는 내장 표', () async {
    SharedPreferences.setMockInitialValues({CachedHolidayCalendar.cacheKey: '{oops'});
    prefs = await SharedPreferences.getInstance();
    final c = calendar();
    expect(c.source, bundled);
    expect(c.nameOf(DateTime(2026, 10, 9)), '한글날');
  });
}
