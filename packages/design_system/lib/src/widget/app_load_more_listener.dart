import 'package:flutter/material.dart';

/// 세로 목록이 끝에 가까워지면 다음 페이지를 요청한다.
///
/// 목록 안의 가로 스크롤이나 중첩 목록이 올린 알림은 무시하고, 바로 아래의
/// 세로 스크롤만 본다. 다음 페이지 유무와 요청 중 여부는 목록 상태를 소유한
/// feature 가 [onLoadMore] 안에서 판단한다.
class AppLoadMoreListener extends StatelessWidget {
  const AppLoadMoreListener({
    required this.onLoadMore,
    required this.child,
    super.key,
  });

  /// 목록 끝에서 이 거리(논리 픽셀) 안에 오면 [onLoadMore]를 부른다.
  static const loadMoreExtent = 240.0;

  final VoidCallback onLoadMore;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0 &&
              notification.metrics.axis == Axis.vertical &&
              notification.metrics.extentAfter < loadMoreExtent) {
            onLoadMore();
          }
          return false;
        },
        child: child,
      );
}
