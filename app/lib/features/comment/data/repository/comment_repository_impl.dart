import 'package:injectable/injectable.dart';

import '../../../../core/data/repository/repository_error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_code.dart';
import '../../../../core/pagination/cursor_page.dart';
import '../../../../core/result/result.dart';
import '../../../post/domain/entity/post_author.dart';
import '../../domain/entity/post_comment.dart';
import '../../domain/repository/comment_repository.dart';
import '../cursor/comment_cursor.dart';
import '../datasource/comment_data_source.dart';
import '../dto/post_comment_dto.dart';
import '../mapper/post_comment_mapper.dart';

@LazySingleton(as: CommentRepository)
class CommentRepositoryImpl
    with RepositoryErrorHandler
    implements CommentRepository {
  CommentRepositoryImpl(this._dataSource);

  final CommentDataSource _dataSource;

  @override
  Future<Result<CursorPage<PostComment>>> getComments({
    required String postId,
    required int limit,
    String? cursor,
  }) => guard(() async {
    final rows = await _dataSource.getComments(
      postId: postId,
      // 한 개를 더 요청해서 다음 페이지 존재 여부를 알아낸다.
      limit: limit + 1,
      cursor: CommentCursor.decode(cursor),
    );
    return _toPage(rows, limit);
  });

  @override
  Future<Result<CursorPage<PostComment>>> getReplies({
    required String parentId,
    required int limit,
    String? cursor,
  }) => guard(() async {
    final rows = await _dataSource.getReplies(
      parentId: parentId,
      limit: limit + 1,
      cursor: CommentCursor.decode(cursor),
    );
    return _toPage(rows, limit);
  });

  CursorPage<PostComment> _toPage(List<PostCommentDto> rows, int limit) {
    final hasMore = rows.length > limit;
    final page = hasMore ? rows.take(limit).toList() : rows;

    return CursorPage<PostComment>(
      items: page.map((dto) => dto.toEntity()).toList(),
      // 다음 커서는 잘라낸 뒤 실제로 돌려주는 마지막 항목 기준이다.
      nextCursor: hasMore ? page.last.toCursor().encode() : null,
    );
  }

  @override
  Future<Result<PostComment>> addComment({
    required String postId,
    String? parentId,
    required String content,
    required PostAuthor author,
  }) => guard(() async {
    final created = await _dataSource.addComment(
      postId: postId,
      parentId: parentId,
      content: content,
    );
    if (created == null) {
      throw const Failure.auth(
        message: '로그인이 필요합니다',
        failureCode: FailureCode.authenticationRequired,
      );
    }

    // 서버가 정하는 값은 id 와 시각뿐이다. 본문과 작성자는 호출부가 이미 알고
    // 있으므로 방금 쓴 댓글을 다시 조회하지 않는다. 피드의 prependPost 와 같다.
    return PostComment(
      id: created.id,
      postId: postId,
      parentId: parentId,
      author: author,
      content: content,
      createdAt: created.createdAt,
    );
  });

  @override
  Future<Result<bool>> deleteComment(String commentId) => guard(() async {
    final deleted = await _dataSource.deleteComment(commentId);
    if (deleted == null) {
      throw const Failure.auth(
        message: '로그인이 필요합니다',
        failureCode: FailureCode.authenticationRequired,
      );
    }
    return deleted;
  });
}
