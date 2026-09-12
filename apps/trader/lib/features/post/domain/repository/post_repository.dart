import '../../../../core/result/result.dart';
import '../entity/post.dart';
import '../entity/post_draft.dart';
import '../entity/post_update.dart';

/// 게시물 저장소.
///
/// 로그인한 사용자의 식별은 구현체가 처리하므로 호출부가 인증 SDK 를 알 필요가 없다.
abstract interface class PostRepository {
  /// 게시물 하나를 조회한다.
  Future<Result<Post>> getPost(String postId);

  /// 로그인한 사용자의 새 게시물을 작성한다.
  Future<Result<Post>> createPost(PostDraft draft);

  /// 로그인한 사용자가 작성한 게시물을 수정한다.
  Future<Result<Post>> updatePost(String postId, PostUpdate update);

  /// 로그인한 사용자가 작성한 게시물을 소프트 삭제한다.
  Future<Result<void>> deletePost(String postId);
}
