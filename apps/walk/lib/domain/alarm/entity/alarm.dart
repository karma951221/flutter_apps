import 'package:freezed_annotation/freezed_annotation.dart';

part 'alarm.freezed.dart';

/// 반복 요일. 순서가 [DateTime.weekday] 1(월)..7(일)과 같다.
enum Weekday {
  mon,
  tue,
  wed,
  thu,
  fri,
  sat,
  sun;

  static Weekday of(DateTime date) => values[date.weekday - 1];
}

/// 알람 정의. 패키지에 거는 회차(`AlarmTrigger`)는 여기서 계산해 낸다.
@freezed
class Alarm with _$Alarm {
  /// 1..9999. 저장 전(새 알람)은 [unsavedId].
  @override
  final int id;

  /// 0..23
  @override
  final int hour;

  /// 0..59
  @override
  final int minute;

  /// 비면 1회성.
  @override
  final Set<Weekday> repeat;

  /// 빈 문자열이면 라벨 없음.
  @override
  final String label;
  @override
  final bool vibrate;
  @override
  final bool enabled;

  /// 1회성을 켤 때 정한 울릴 시각. 반복이면 null.
  @override
  final DateTime? oneShotAt;

  const Alarm({
    this.id = unsavedId,
    required this.hour,
    required this.minute,
    this.repeat = const {},
    this.label = '',
    this.vibrate = true,
    this.enabled = true,
    this.oneShotAt,
  });

  static const unsavedId = 0;
  static const maxId = 9999;

  bool get isOneShot => repeat.isEmpty;

  /// 새 알람의 기본값 — 07:00, 반복 없음, 진동 켬.
  static Alarm draft() => const Alarm(hour: 7, minute: 0);

  Map<String, Object?> toJson() => {
    'id': id,
    'hour': hour,
    'minute': minute,
    'repeat': [for (final day in Weekday.values) if (repeat.contains(day)) day.name],
    'label': label,
    'vibrate': vibrate,
    'enabled': enabled,
    'oneShotAt': oneShotAt?.toIso8601String(),
  };

  /// (Freezed 가 factory 를 union 으로 오해하지 않게 static 으로 둔다.)
  static Alarm fromJson(Map<String, Object?> json) {
    final oneShotAt = json['oneShotAt'] as String?;
    return Alarm(
      id: json['id']! as int,
      hour: json['hour']! as int,
      minute: json['minute']! as int,
      repeat: {
        for (final name in (json['repeat'] as List<Object?>? ?? const []))
          Weekday.values.byName(name! as String),
      },
      label: json['label'] as String? ?? '',
      vibrate: json['vibrate'] as bool? ?? true,
      enabled: json['enabled'] as bool? ?? false,
      oneShotAt: oneShotAt == null ? null : DateTime.parse(oneShotAt),
    );
  }
}
