import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/data/alarm/channel_reminder_scheduler.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_reminder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(ChannelReminderScheduler.channelName);
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  void answer(Object? Function(MethodCall call) reply) {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return reply(call);
    });
  }

  setUpAll(() async {
    await initializeDateFormatting('ko');
    await initializeDateFormatting('en');
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  final ko = lookupAppLocalizations(const Locale('ko'));
  final en = lookupAppLocalizations(const Locale('en'));
  final ringAt = DateTime(2026, 10, 9, 7);
  const alarm = Alarm(id: 4, hour: 7, minute: 0, repeat: {Weekday.fri}, label: '출근');
  final soon = AlarmReminder(
    id: reminderId(412, ReminderKind.soon),
    packageId: 412,
    alarmId: 4,
    kind: ReminderKind.soon,
    at: DateTime(2026, 10, 9, 6, 30),
    ringAt: ringAt,
  );
  final holiday = AlarmReminder(
    id: reminderId(412, ReminderKind.holiday),
    packageId: 412,
    alarmId: 4,
    kind: ReminderKind.holiday,
    at: DateTime(2026, 10, 8, 7),
    ringAt: ringAt,
    holidayName: '한글날',
  );

  test('채널 이름은 walk/reminders', () {
    expect(ChannelReminderScheduler.channelName, 'walk/reminders');
  });

  group('argumentsFor', () {
    test('soon: 시각은 epoch millis, 문구 · [이번만 끄기]', () {
      expect(ChannelReminderScheduler.argumentsFor(soon, alarm, ko), {
        'id': soon.id,
        'packageId': 412,
        'alarmId': 4,
        'kind': 'soon',
        'at': DateTime(2026, 10, 9, 6, 30).millisecondsSinceEpoch,
        'ringAt': ringAt.millisecondsSinceEpoch,
        'title': '곧 알람이 울려요',
        'body': '오전 7:00 출근',
        'actions': [
          {'action': 'skip', 'label': '이번만 끄기'},
        ],
      });
    });

    test('soon: 라벨이 없으면 기본 제목', () {
      final args = ChannelReminderScheduler.argumentsFor(soon, alarm.copyWith(label: ''), ko);
      expect(args['body'], '오전 7:00 알람');
    });

    test('holiday: 날짜 · 이름 · 시각과 [다음 알람 건너뛰기] · [울리기]', () {
      final args = ChannelReminderScheduler.argumentsFor(holiday, alarm, ko);
      expect(args['kind'], 'holiday');
      expect(args['title'], '공휴일에 울리는 알람');
      expect(args['body'], '10월 9일(한글날) 오전 7:00 알람이 공휴일에 울려요');
      expect(args['actions'], [
        {'action': 'skip', 'label': '다음 알람 건너뛰기'},
        {'action': 'dismiss', 'label': '울리기'},
      ]);
    });

    test('holiday: 이름이 없으면 날짜만', () {
      final args = ChannelReminderScheduler.argumentsFor(
        holiday.copyWith(holidayName: null),
        alarm,
        ko,
      );
      expect(args['body'], '10월 9일 오전 7:00 알람이 공휴일에 울려요');
    });

    test('holiday: 영어는 이름 없이 날짜만', () {
      final args = ChannelReminderScheduler.argumentsFor(holiday, alarm, en);
      expect(args['body'], 'Your 7:00 AM alarm on Oct 9 falls on a holiday');
    });
  });

  group('scheduled', () {
    test('id · 띄울 시각 · 울릴 시각(epoch millis)을 맵으로', () async {
      final ring = ringAt.millisecondsSinceEpoch;
      answer(
        (_) => [
          {
            'id': 1000824,
            'at': DateTime(2026, 10, 9, 6, 30).millisecondsSinceEpoch,
            'ringAt': ring,
          },
          {'id': 1000825, 'at': DateTime(2026, 10, 8, 7).millisecondsSinceEpoch, 'ringAt': ring},
          {'id': 1000826, 'at': DateTime(2026, 10, 8, 7).millisecondsSinceEpoch}, // ringAt 없음
          {'id': 'broken'},
        ],
      );

      expect(await const ChannelReminderScheduler().scheduled(), {
        1000824: (at: DateTime(2026, 10, 9, 6, 30), ringAt: ringAt),
        1000825: (at: DateTime(2026, 10, 8, 7), ringAt: ringAt),
      });
      expect(calls.single.method, 'scheduled');
    });

    test('채널이 없으면 빈 맵', () async {
      expect(await const ChannelReminderScheduler().scheduled(), isEmpty);
    });
  });

  group('schedule', () {
    test('argumentsFor 를 기기 언어 문구로 넘긴다', () async {
      answer((_) => null);

      await const ChannelReminderScheduler().schedule(soon, alarm);

      expect(calls.single.method, 'schedule');
      final args = calls.single.arguments as Map<Object?, Object?>;
      expect(args['id'], soon.id);
      expect(args['at'], soon.at.millisecondsSinceEpoch);
      expect(args['title'], isA<String>());
    });

    test('채널이 없으면 무시한다', () async {
      await const ChannelReminderScheduler().schedule(soon, alarm);
    });
  });

  group('cancel', () {
    test('id 를 넘긴다', () async {
      answer((_) => null);
      await const ChannelReminderScheduler().cancel(1000824);
      expect(calls.single.method, 'cancel');
      expect(calls.single.arguments, {'id': 1000824});
    });

    test('채널이 없으면 무시한다', () async {
      await const ChannelReminderScheduler().cancel(1000824);
    });
  });
}
