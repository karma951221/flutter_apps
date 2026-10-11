import 'package:freezed_annotation/freezed_annotation.dart';

import '../entity/diary_entry.dart';
import '../entity/entry_media.dart';
import '../entity/story.dart';

part 'story_cover.freezed.dart';

/// 스토리 표지: 미디어(영상이면 썸네일을 그린다) 또는 제목 이니셜.
@freezed
sealed class StoryCover with _$StoryCover {
  const factory StoryCover.media(EntryMedia media) = CoverMedia;

  /// [title] 이 빈 문자열이면 화면이 l10n 기본 제목으로 이니셜을 만든다.
  const factory StoryCover.initial(String title) = CoverInitial;
}

abstract final class StoryCoverRule {
  /// coverMediaId 가 살아 있는(휴지통 아닌) 기록의 미디어면 그것, 아니면 occurredAt 최신 기록의 첫 photo,
  /// 없으면 첫 video(썸네일), 없으면 CoverInitial.
  ///
  /// [liveEntries] 는 그 스토리의 휴지통 아닌 기록. 휴지통 기록이 섞여 와도 무시한다.
  static StoryCover pick(Story story, List<DiaryEntry> liveEntries) {
    final live = [
      for (final e in liveEntries)
        if (!e.isTrashed) e,
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    final chosenId = story.coverMediaId;
    if (chosenId != null) {
      for (final e in live) {
        for (final m in e.media) {
          if (m.id == chosenId) return StoryCover.media(m);
        }
      }
    }
    for (final kind in [MediaKind.photo, MediaKind.video]) {
      for (final e in live) {
        for (final m in e.media) {
          if (m.kind == kind) return StoryCover.media(m);
        }
      }
    }
    return StoryCover.initial(story.title);
  }
}
