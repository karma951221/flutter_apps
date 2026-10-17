import 'package:freezed_annotation/freezed_annotation.dart';

import '../../walk/entity/geo_point.dart';

part 'walk_post.freezed.dart';

/// 모두의 산책 한 줄 — 누군가 공유한 산책(`walk_posts_with_author` 한 행).
///
/// 시각은 현지 시각이다. [routePreview] 는 앞뒤를 잘라 낸 경로이고, 경로 없이
/// 공유했거나 값이 깨졌으면 빈 목록이다.
@freezed
class WalkPost with _$WalkPost {
  @override
  final String id;
  @override
  final String authorId;
  @override
  final String authorNickname;
  @override
  final String? authorAvatarUrl;
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
  @override
  final List<GeoPoint> routePreview;
  @override
  final DateTime createdAt;
  @override
  final int likeCount;
  @override
  final bool likedByMe;

  const WalkPost({
    required this.id,
    required this.authorId,
    required this.authorNickname,
    this.authorAvatarUrl,
    required this.localWalkId,
    required this.startedAt,
    required this.duration,
    required this.distanceMeters,
    required this.dogNames,
    this.memo,
    required this.routePreview,
    required this.createdAt,
    required this.likeCount,
    required this.likedByMe,
  });
}
