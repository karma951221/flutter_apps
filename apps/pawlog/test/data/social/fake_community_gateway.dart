import 'package:pawlog/data/social/supabase_community_gateway.dart';
import 'package:pawlog/data/social/walk_post_cursor.dart';

/// [SupabaseCommunityGateway] 의 손으로 짠 대역. 실패를 던지게 하려면 `*Error` 를 채운다.
class FakeCommunityGateway implements SupabaseCommunityGateway {
  FakeCommunityGateway({this.currentUserId = 'u1'});

  @override
  String? currentUserId;

  /// [fetchPosts] 가 돌려줄 행(이미 정렬된 것으로 본다). limit 만큼 자른다.
  List<Map<String, dynamic>> rows = [];
  final fetchCalls = <({int limit, WalkPostCursor? before})>[];

  final publishedParams = <Map<String, dynamic>>[];
  String publishedId = 'p1';
  bool unpublishResult = true;
  final unpublished = <String>[];

  /// `(authorId, localWalkId)` 로 살아 있는 글.
  final live = <(String, String)>{};

  final likes = <String>[];
  final unlikes = <({String postId, String userId})>[];

  Object? fetchError;
  Object? publishError;
  Object? likeError;

  @override
  Future<List<Map<String, dynamic>>> fetchPosts({
    required int limit,
    WalkPostCursor? before,
  }) async {
    fetchCalls.add((limit: limit, before: before));
    if (fetchError case final error?) throw error;
    return rows.take(limit).toList();
  }

  @override
  Future<bool> hasLivePost({
    required String authorId,
    required String localWalkId,
  }) async => live.contains((authorId, localWalkId));

  @override
  Future<String> publish(Map<String, dynamic> params) async {
    if (publishError case final error?) throw error;
    publishedParams.add(params);
    return publishedId;
  }

  @override
  Future<bool> unpublish(String localWalkId) async {
    unpublished.add(localWalkId);
    return unpublishResult;
  }

  @override
  Future<void> insertLike(String postId) async {
    if (likeError case final error?) throw error;
    likes.add(postId);
  }

  @override
  Future<void> deleteLike({
    required String postId,
    required String userId,
  }) async {
    unlikes.add((postId: postId, userId: userId));
  }
}
