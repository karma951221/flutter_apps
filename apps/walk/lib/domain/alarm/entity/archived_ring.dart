import 'package:freezed_annotation/freezed_annotation.dart';

import 'ring_log_entry.dart';

part 'archived_ring.freezed.dart';

/// 앱 DB 에 오래 남긴 울림 기록 한 줄. 네이티브 기록은 200줄만 남으므로 옮겨 담을 때
/// 그 알람의 라벨 · 시각을 함께 적는다(알람을 지워도 기록은 읽힌다).
@freezed
class ArchivedRing with _$ArchivedRing {
  @override
  final RingLogEntry entry;

  /// 옮겨 담을 때 그 알람의 라벨. 지운 알람이면 null.
  @override
  final String? label;
  @override
  final int? hour;
  @override
  final int? minute;

  const ArchivedRing({required this.entry, this.label, this.hour, this.minute});
}
