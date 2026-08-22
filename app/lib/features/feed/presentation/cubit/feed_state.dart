import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entity/feed_post.dart';

part 'feed_state.freezed.dart';

/// 피드 목록 화면의 상태.
@freezed
class FeedState with _$FeedState {
  const FeedState({
    this.status = FeedStatus.loading,
    this.posts = const [],
    this.isLoadingMore = false,
    this.canLoadMore = true,
    this.failure,
  });

  @override
  final FeedStatus status;
  @override
  final List<FeedPost> posts;
  @override
  final bool isLoadingMore;
  @override
  final bool canLoadMore;
  @override
  final Failure? failure;
}

enum FeedStatus { loading, loaded, failure }
