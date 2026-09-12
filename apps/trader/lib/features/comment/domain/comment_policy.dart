/// 댓글 domain 정책 상수.
///
/// DB 의 post_comments_content_length CHECK 와 같은 값을 쓴다. 앱 검증은 UX 이고
/// 최종 판정은 DB 가 하지만, 두 값이 어긋나면 사용자에게 날것의 DB 오류가 간다.
abstract final class CommentPolicy {
  /// 본문 최대 길이. docs/schema.md 의 post_comments_content_length 와 같아야 한다.
  static const maxContentLength = 300;

  /// 한 번에 가져올 수 있는 최대 개수.
  static const maxPageSize = 50;
}
