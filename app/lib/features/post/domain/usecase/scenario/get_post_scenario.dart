import '../../../../../core/error/failure.dart';
import '../../../../../core/result/result.dart';
import '../../entity/post.dart';
import '../../repository/post_repository.dart';

class GetPostScenario {
  const GetPostScenario(this._repository);

  final PostRepository _repository;

  Future<Result<Post>> call(String postId) {
    if (postId.trim().isEmpty) {
      return Future.value(
        const Err(Failure.validation(message: '게시물 식별자가 필요합니다')),
      );
    }
    return _repository.getPost(postId);
  }
}
