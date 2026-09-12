import '../../domain/entity/post_draft.dart';
import '../../domain/entity/post_update.dart';
import '../dto/post_dto.dart';

/// 게시물 원격 데이터 원천의 계약.
///
/// 미인증 상태는 `null` 로 알린다. 인증 판단은 repository 가 `Failure` 로 옮긴다.
abstract interface class PostDataSource {
  Future<PostDto> getPost(String postId);

  Future<PostDto?> createPost(PostDraft draft);

  Future<PostDto?> updatePost(String postId, PostUpdate update);

  /// 소프트 삭제. 삭제된 행이 있으면 true, 없거나 남의 글이면 false.
  Future<bool?> deletePost(String postId);
}
