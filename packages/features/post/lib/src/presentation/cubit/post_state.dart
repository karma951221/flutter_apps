import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';

part 'post_state.freezed.dart';

/// 게시물 작성·수정·삭제의 진행 상태.
@freezed
class PostState with _$PostState {
  const PostState({this.isSubmitting = false, this.failure});

  @override
  final bool isSubmitting;
  @override
  final Failure? failure;
}
