import 'package:flutter/material.dart';

import '../cubit/feed_cubit.dart';

/// 세로 목록이 끝에 가까워지면 다음 페이지를 요청한다.
///
/// 게시물 안의 가로 사진 목록도 같은 트리를 타고 스크롤 알림을 올려 보낸다.
/// 알림을 그대로 받으면 사진을 옆으로 끝까지 넘긴 것만으로 `extentAfter` 가
/// 0 이 되어, 세로 목록은 첫 화면인데도 다음 페이지를 읽었다. 그래서 이
/// listener 는 **세로 축이고 depth 0**(바로 아래 스크롤 뷰)인 알림만 본다.
///
/// "더 읽을 게 남았는지"(`canLoadMore` · `isLoadingMore`)는 화면마다 상태를
/// 읽는 시점이 달라 [onLoadMore] 쪽에 남겨 둔다. 여기서는 위치만 판단한다.
class FeedLoadMoreListener extends StatelessWidget {
  const FeedLoadMoreListener({
    required this.onLoadMore,
    required this.child,
    super.key,
  });

  /// 세로 목록이 끝 [FeedCubit.loadMoreExtent] 안으로 들어왔을 때만 불린다.
  final VoidCallback onLoadMore;

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0 &&
              notification.metrics.axis == Axis.vertical &&
              notification.metrics.extentAfter < FeedCubit.loadMoreExtent) {
            onLoadMore();
          }
          return false;
        },
        child: child,
      );
}
