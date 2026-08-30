/// 피드가 읽는 대상.
///
/// 팔로잉 피드는 새 화면이 아니라 같은 목록의 두 번째 소스다. 커서 계약과
/// 화면 구성이 같아서 앱은 읽는 대상만 바꾼다 — DB 쪽도 마찬가지로
/// `following_posts_with_author` 가 `posts_with_author` 를 감싼 뷰다
/// (docs/features/follow/plan.md).
enum FeedSource {
  /// 전체 공개 피드.
  all,

  /// 내가 팔로우한 사람들의 글만.
  following,
}
