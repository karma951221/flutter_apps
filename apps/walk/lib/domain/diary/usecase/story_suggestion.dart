import '../entity/story.dart';
import 'story_order.dart';

/// 작성 화면이 고를 스토리.
abstract final class StorySuggestion {
  /// 작성 기본값: open 중 lastPostedAt 최신(null 은 createdAt), 같으면 최근에 만든 것.
  /// 없으면 'daily'.
  static String defaultFor(List<Story> stories) =>
      StoryOrder.split(stories).open.firstOrNull?.id ?? Story.dailyId;

  /// 시각 변경 제안: covers(at) 인 open 스토리 중 기본 스토리를 뺀 것의 lastPostedAt 최신,
  /// 없으면 'daily'.
  static String forTime(List<Story> stories, DateTime at) =>
      StoryOrder.split([
        for (final s in stories)
          if (!s.isDefault && s.covers(at)) s,
      ]).open.firstOrNull?.id ??
      Story.dailyId;
}
