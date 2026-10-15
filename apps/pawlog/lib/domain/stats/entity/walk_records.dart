import 'package:freezed_annotation/freezed_annotation.dart';

import '../../walk/entity/walk.dart';

part 'walk_records.freezed.dart';

/// 전체 기간의 기록. 산책이 없으면 [farthest] · [longest] 가 null 이다.
@freezed
class WalkRecords with _$WalkRecords {
  @override
  final int currentStreakDays;
  @override
  final int longestStreakDays;
  @override
  final Walk? farthest;
  @override
  final Walk? longest;

  const WalkRecords({
    required this.currentStreakDays,
    required this.longestStreakDays,
    this.farthest,
    this.longest,
  });

  static const empty = WalkRecords(currentStreakDays: 0, longestStreakDays: 0);
}
