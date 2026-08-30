import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_code.dart';
import '../../../../core/result/result.dart';
import '../../domain/entity/post.dart';
import '../../domain/entity/post_draft.dart';
import '../../domain/entity/post_image_draft.dart';
import '../../domain/entity/post_update.dart';
import '../../domain/usecase/post_use_case.dart';
import 'post_state.dart';

/// 게시물 하나에 대한 변경(작성·수정·삭제)을 담당한다.
///
/// 목록 상태는 feed 가 소유한다. 이 cubit 은 결과를 Result 로 돌려주고,
/// 화면이 그 결과를 feed 에 반영한다.
@injectable
class PostCubit extends Cubit<PostState> {
  PostCubit(this._useCase) : super(const PostState());

  final PostUseCase _useCase;

  Future<Result<Post>> create(
    String content, {
    List<PostImageDraft> images = const [],
  }) => _submit(
    () => _useCase.createPost(PostDraft(content: content, images: images)),
  );

  Future<Result<Post>> update(String postId, String content) =>
      _submit(() => _useCase.updatePost(postId, PostUpdate(content: content)));

  Future<Result<void>> delete(String postId) =>
      _submit(() => _useCase.deletePost(postId));

  Future<Result<T>> _submit<T>(Future<Result<T>> Function() action) async {
    if (state.isSubmitting) {
      return const Err(
        Failure.validation(
          message: '이미 처리 중입니다',
          failureCode: FailureCode.operationInProgress,
        ),
      );
    }

    emit(const PostState(isSubmitting: true));
    final result = await action();
    if (isClosed) return result;

    emit(
      result.when(
        ok: (_) => const PostState(),
        err: (failure) => PostState(failure: failure),
      ),
    );
    return result;
  }
}
