/// 게시물 domain 정책 상수.
///
/// DB 의 posts_content_length CHECK 와 같은 값을 쓴다. 앱 검증은 UX 이고 최종
/// 판정은 DB 가 하지만, 두 값이 어긋나면 사용자에게 날것의 DB 오류가 노출된다.
abstract final class PostPolicy {
  /// 본문 최대 길이. docs/schema.md 의 posts_content_length 와 일치해야 한다.
  static const maxContentLength = 500;
}
