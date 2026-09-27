/// 게시물 domain 정책 상수.
///
/// DB 의 posts_content_length CHECK 와 같은 값을 쓴다. 앱 검증은 UX 이고 최종
/// 판정은 DB 가 하지만, 두 값이 어긋나면 사용자에게 날것의 DB 오류가 노출된다.
abstract final class PostPolicy {
  /// 본문 최대 길이. apps/trader/docs/schema.md 의 posts_content_length 와 일치해야 한다.
  static const maxContentLength = 500;

  /// 첨부할 수 있는 사진의 최대 장수.
  ///
  /// apps/trader/docs/schema.md §7 의 `post_images_sort_order_range`(sort_order 0..4)와 같은
  /// 값이다. 화면이 5 를 직접 적으면 제약이 바뀔 때 한쪽만 남는다.
  static const maxImageCount = 5;
}
