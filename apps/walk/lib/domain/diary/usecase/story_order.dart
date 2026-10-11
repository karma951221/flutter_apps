import '../entity/story.dart';

/// 스토리 바 순서.
abstract final class StoryOrder {
  /// open(기본 스토리 포함): lastPostedAt 내림차순(없으면 createdAt 으로 비교),
  /// 같으면 createdAt 내림차순. closed: 보관함, endedAt 내림차순.
  static ({List<Story> open, List<Story> archived}) split(List<Story> stories) {
    int byCreated(Story a, Story b) => b.createdAt.compareTo(a.createdAt);

    final open =
        [
          for (final s in stories)
            if (s.isOpen) s,
        ]..sort((a, b) {
          final byPosted = (b.lastPostedAt ?? b.createdAt).compareTo(
            a.lastPostedAt ?? a.createdAt,
          );
          return byPosted != 0 ? byPosted : byCreated(a, b);
        });
    final archived =
        [
          for (final s in stories)
            if (!s.isOpen) s,
        ]..sort((a, b) {
          final byEnded = (b.endedAt ?? b.createdAt).compareTo(
            a.endedAt ?? a.createdAt,
          );
          return byEnded != 0 ? byEnded : byCreated(a, b);
        });
    return (open: open, archived: archived);
  }
}
