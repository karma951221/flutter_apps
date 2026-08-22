import 'package:injectable/injectable.dart';

import '../../../../core/result/result.dart';
import '../entity/post.dart';
import '../entity/post_draft.dart';
import '../entity/post_update.dart';
import '../repository/post_repository.dart';
import 'scenario/create_post_scenario.dart';
import 'scenario/delete_post_scenario.dart';
import 'scenario/get_post_scenario.dart';
import 'scenario/update_post_scenario.dart';

/// 게시물 feature 의 presentation 진입점.
abstract interface class PostUseCase {
  Future<Result<Post>> getPost(String postId);

  Future<Result<Post>> createPost(PostDraft draft);

  Future<Result<Post>> updatePost(String postId, PostUpdate update);

  Future<Result<void>> deletePost(String postId);
}

@LazySingleton(as: PostUseCase)
class DefaultPostUseCase implements PostUseCase {
  DefaultPostUseCase(this._repository);

  final PostRepository _repository;

  @override
  Future<Result<Post>> getPost(String postId) =>
      GetPostScenario(_repository)(postId);

  @override
  Future<Result<Post>> createPost(PostDraft draft) =>
      CreatePostScenario(_repository)(draft);

  @override
  Future<Result<Post>> updatePost(String postId, PostUpdate update) =>
      UpdatePostScenario(_repository)(postId, update);

  @override
  Future<Result<void>> deletePost(String postId) =>
      DeletePostScenario(_repository)(postId);
}
