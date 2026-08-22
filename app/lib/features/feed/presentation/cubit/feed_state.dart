import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../post/domain/entity/post.dart';

part 'feed_state.freezed.dart';

/// 피드 목록 화면의 상태.
@freezed
class FeedState with _$FeedState {
  const FeedState({
    this.status = FeedStatus.loading,
    this.posts = const [],
    this.isLoadingMore = false,
    this.nextCursor,
    this.failure,
  });

  @override
  final FeedStatus status;
  @override
  final List<Post> posts;
  @override
  final bool isLoadingMore;

  /// 다음 페이지 커서. null 이면 마지막 페이지까지 읽었다는 뜻이다.
  @override
  final String? nextCursor;
  @override
  final Failure? failure;

  bool get canLoadMore => nextCursor != null;
}

enum FeedStatus { loading, loaded, failure }
