import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';
import '../../domain/entity/feed_post.dart';

part 'feed_state.freezed.dart';

/// 피드 목록 화면의 상태.
@freezed
class FeedState with _$FeedState {
  const FeedState({
    this.status = FeedStatus.loading,
    this.items = const [],
    this.isLoadingMore = false,
    this.nextCursor,
    this.failure,
  });

  @override
  final FeedStatus status;

  /// 게시물과 작성자를 함께 담은 목록. 화면이 작성자를 따로 조회하지 않는다.
  @override
  final List<FeedPost> items;
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
