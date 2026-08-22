import '../../../../../core/error/failure.dart';
import '../../../../../core/result/result.dart';
import '../../repository/post_repository.dart';

class DeletePostScenario {
  const DeletePostScenario(this._repository);

  final PostRepository _repository;

  Future<Result<void>> call(String postId) {
    if (postId.trim().isEmpty) {
      return Future.value(
        const Err(Failure.validation(message: '게시물 식별자가 필요합니다')),
      );
    }
    return _repository.deletePost(postId);
  }
}
