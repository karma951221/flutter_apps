import 'package:freezed_annotation/freezed_annotation.dart';

import 'walk_track_point.dart';

part 'walk_draft.freezed.dart';

@freezed
class WalkDraft with _$WalkDraft {
  @override
  final DateTime startedAt;
  @override
  final DateTime endedAt;
  @override
  final double distanceMeters;
  @override
  final List<WalkTrackPoint> points;
  @override
  final List<String> dogIds;
  @override
  final String? memo;
  @override
  final List<String> photoPaths;

  const WalkDraft({
    required this.startedAt,
    required this.endedAt,
    required this.distanceMeters,
    required this.points,
    required this.dogIds,
    this.memo,
    required this.photoPaths,
  });
}
