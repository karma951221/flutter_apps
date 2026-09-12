import 'package:injectable/injectable.dart';

import 'package:core/core.dart';
import 'package:feature_post/feature_post.dart';
import '../entity/post_comment.dart';
import '../repository/comment_repository.dart';
import 'scenario/add_comment_scenario.dart';
import 'scenario/delete_comment_scenario.dart';
import 'scenario/get_comments_scenario.dart';
import 'scenario/get_replies_scenario.dart';

/// 댓글 feature 의 presentation 진입점.
abstract interface class CommentUseCase {
  Future<Result<CursorPage<PostComment>>> getComments({
    required String postId,
    int limit,
    String? cursor,
  });

  Future<Result<CursorPage<PostComment>>> getReplies({
    required String parentId,
    int limit,
    String? cursor,
  });

  Future<Result<PostComment>> addComment({
    required String postId,
    String? parentId,
    required String content,
    required PostAuthor author,
  });

  Future<Result<bool>> deleteComment(String commentId);
}

@LazySingleton(as: CommentUseCase)
class DefaultCommentUseCase implements CommentUseCase {
  DefaultCommentUseCase(this._repository);

  final CommentRepository _repository;

  @override
  Future<Result<CursorPage<PostComment>>> getComments({
    required String postId,
    int limit = 20,
    String? cursor,
  }) => GetCommentsScenario(
    _repository,
  )(postId: postId, limit: limit, cursor: cursor);

  @override
  Future<Result<CursorPage<PostComment>>> getReplies({
    required String parentId,
    int limit = 20,
    String? cursor,
  }) => GetRepliesScenario(
    _repository,
  )(parentId: parentId, limit: limit, cursor: cursor);

  @override
  Future<Result<PostComment>> addComment({
    required String postId,
    String? parentId,
    required String content,
    required PostAuthor author,
  }) => AddCommentScenario(
    _repository,
  )(postId: postId, parentId: parentId, content: content, author: author);

  @override
  Future<Result<bool>> deleteComment(String commentId) =>
      DeleteCommentScenario(_repository)(commentId);
}
