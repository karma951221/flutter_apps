import 'package:pawlog/domain/social/entity/auth_session.dart';
import 'package:pawlog/domain/social/entity/walk_post.dart';
import 'package:pawlog/domain/walk/entity/geo_point.dart';

const alice = AuthSession(userId: 'u1', nickname: '앨리스');
const bob = AuthSession(userId: 'u2', nickname: '밥');

/// 모두의 산책 한 줄. 기본은 경로 · 메모가 있고 좋아요 3, 내가 누르지 않은 글.
WalkPost walkPost(
  String id, {
  int likeCount = 3,
  bool likedByMe = false,
  String? memo = '공원 한 바퀴',
  List<GeoPoint> routePreview = const [
    GeoPoint(lat: 37.5, lng: 127),
    GeoPoint(lat: 37.501, lng: 127.001),
  ],
}) => WalkPost(
  id: id,
  authorId: 'u9',
  authorNickname: '산책러$id',
  localWalkId: 'lw-$id',
  startedAt: DateTime(2026, 10, 3, 9),
  duration: const Duration(minutes: 30),
  distanceMeters: 1200,
  dogNames: const ['콩이', '보리'],
  memo: memo,
  routePreview: routePreview,
  createdAt: DateTime(2026, 10, 3, 10),
  likeCount: likeCount,
  likedByMe: likedByMe,
);
