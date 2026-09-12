import 'package:injectable/injectable.dart';

import 'package:core/core.dart';
import '../../domain/entity/post.dart';
import '../../domain/entity/post_draft.dart';
import '../../domain/entity/post_update.dart';
import '../../domain/repository/post_repository.dart';
import '../datasource/post_data_source.dart';
import '../mapper/post_mapper.dart';

/// PostDataSource 를 domain Repository 계약으로 변환하는 구현체.
@LazySingleton(as: PostRepository)
class PostRepositoryImpl with RepositoryErrorHandler implements PostRepository {
  PostRepositoryImpl(this._dataSource);

  final PostDataSource _dataSource;

  @override
  Future<Result<Post>> getPost(String postId) =>
      guard(() async => (await _dataSource.getPost(postId)).toEntity());

  @override
  Future<Result<Post>> createPost(PostDraft draft) => guard(() async {
    final post = await _dataSource.createPost(draft);
    return post?.toEntity() ?? _throwNotAuthenticated();
  });

  @override
  Future<Result<Post>> updatePost(String postId, PostUpdate update) =>
      guard(() async {
        final post = await _dataSource.updatePost(postId, update);
        return post?.toEntity() ?? _throwNotAuthenticated();
      });

  @override
  Future<Result<void>> deletePost(String postId) => guard(() async {
    final deleted = await _dataSource.deletePost(postId);
    if (deleted == null) _throwNotAuthenticated();

    // 함수가 false 를 돌려주는 경우는 둘 뿐이다: 이미 삭제됐거나, 남의 글이거나.
    // 어느 쪽인지 구분해 알려주면 남의 게시물 존재 여부가 새어나간다.
    if (deleted == false) {
      throw const Failure.notFound(
        message: '게시물을 찾을 수 없습니다',
        failureCode: FailureCode.postNotFound,
      );
    }
  });

  Never _throwNotAuthenticated() => throw const Failure.auth(
    message: '로그인이 필요합니다',
    code: 'not_authenticated',
    failureCode: FailureCode.authenticationRequired,
  );
}
