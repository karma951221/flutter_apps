import 'package:freezed_annotation/freezed_annotation.dart';

import '../../walk/entity/geo_point.dart';
import '../../walk/entity/walk.dart';
import '../../walk/entity/walk_track_point.dart';
import '../policy/route_privacy.dart';

part 'walk_post_draft.freezed.dart';

/// 공유하려고 서버에 보내는 산책 한 건. [fromWalk] 가 서버 제약에 맞게 다듬는다.
@freezed
class WalkPostDraft with _$WalkPostDraft {
  @override
  final String localWalkId;
  @override
  final DateTime startedAt;
  @override
  final Duration duration;
  @override
  final double distanceMeters;
  @override
  final List<String> dogNames;
  @override
  final String? memo;

  /// 앞뒤를 잘라 낸 경로. 비었으면 경로 없이 공유한다.
  @override
  final List<GeoPoint> routePreview;

  const WalkPostDraft({
    required this.localWalkId,
    required this.startedAt,
    required this.duration,
    required this.distanceMeters,
    required this.dogNames,
    this.memo,
    required this.routePreview,
  });

  /// 서버 제약(`walk_posts`): 메모 500자, 반려견 이름 1~30자 · 1~10마리.
  /// 글자 수는 Postgres `char_length` 처럼 코드 포인트로 센다.
  static const maxMemoLength = 500;
  static const maxDogNameLength = 30;
  static const maxDogs = 10;

  /// 산책 [walk] 와 그 전체 경로 [track] 으로 만든다. 경로는 [RoutePrivacy.trim] 으로
  /// 앞뒤를 자른다. 트랙이 없으면(오래된 기록 · 백업) 목록용 미리보기 점을 대신 자른다.
  ///
  /// 넘치는 메모 · 이름은 거절하지 않고 자른다 — 공유는 기록을 고치는 일이 아니다.
  /// 반려견이 하나도 없는지는 부르는 쪽이 먼저 본다.
  static WalkPostDraft fromWalk(Walk walk, List<WalkTrackPoint> track) {
    final route = track.isNotEmpty
        ? [for (final p in track) p.point]
        : walk.previewPoints;
    final memo = walk.memo?.trim();
    return WalkPostDraft(
      localWalkId: walk.id,
      startedAt: walk.startedAt,
      duration: walk.duration,
      distanceMeters: walk.distanceMeters,
      dogNames: walk.dogs
          .map((dog) => _cut(dog.name.trim(), maxDogNameLength))
          .where((name) => name.isNotEmpty)
          .take(maxDogs)
          .toList(),
      memo: memo == null || memo.isEmpty ? null : _cut(memo, maxMemoLength),
      routePreview: RoutePrivacy.trim(route),
    );
  }

  static String _cut(String value, int max) => value.runes.length <= max
      ? value
      : String.fromCharCodes(value.runes.take(max));
}
