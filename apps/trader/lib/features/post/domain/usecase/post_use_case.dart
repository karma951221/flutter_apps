import 'dart:async';

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
  /// 이 세션에서 방금 만들어진 게시물이 흐른다.
  ///
  /// 작성 화면은 반환값으로 결과를 돌려주지만, 그 화면을 띄운 곳이 목록을 들고
  /// 있는 화면이 아닐 때가 있다 — 예를 들어 매매 결과 화면에서 공유하면
  /// 홈 셸 안에 살아 있는 피드·프로필 목록은 새 글을 모른 채 남는다. 이미
  /// 만들어진 목록들이 스스로 듣게 하려고 생성 사실을 여기서 알린다.
  Stream<Post> get createdPosts;

  Future<Result<Post>> getPost(String postId);

  Future<Result<Post>> createPost(PostDraft draft);

  Future<Result<Post>> updatePost(String postId, PostUpdate update);

  Future<Result<void>> deletePost(String postId);

  /// [createdPosts] 를 닫는다. 부르는 것은 DI 컨테이너뿐이다(`@disposeMethod`)
  /// — 화면은 이 facade 의 수명을 소유하지 않는다. 인터페이스에 두는 이유는
  /// injectable 이 등록된 타입(= 이 인터페이스)으로 dispose 를 부르기 때문이다.
  Future<void> dispose();
}

@LazySingleton(as: PostUseCase)
class DefaultPostUseCase implements PostUseCase {
  DefaultPostUseCase(this._repository);

  final PostRepository _repository;

  /// 듣는 쪽이 여럿이다(피드 탭 · 프로필 탭). 늦게 붙는 구독자도 있으므로
  /// broadcast 다 — 지난 이벤트는 흘려보낸다.
  final _createdPosts = StreamController<Post>.broadcast();

  @override
  Stream<Post> get createdPosts => _createdPosts.stream;

  @override
  Future<Result<Post>> getPost(String postId) =>
      GetPostScenario(_repository)(postId);

  @override
  Future<Result<Post>> createPost(PostDraft draft) async {
    final result = await CreatePostScenario(_repository)(draft);
    // 저장에 성공한 것만 알린다. 실패는 목록에 없어야 한다.
    switch (result) {
      case Ok(:final value):
        _createdPosts.add(value);
      case Err():
        break;
    }
    return result;
  }

  @override
  Future<Result<Post>> updatePost(String postId, PostUpdate update) =>
      UpdatePostScenario(_repository)(postId, update);

  @override
  Future<Result<void>> deletePost(String postId) =>
      DeletePostScenario(_repository)(postId);

  /// 앱 수명과 같은 LazySingleton 이라 평소에는 닫힐 일이 없지만, 테스트처럼
  /// 컨테이너를 리셋하는 자리에서 컨트롤러가 남지 않게 한다.
  @override
  @disposeMethod
  Future<void> dispose() => _createdPosts.close();
}
