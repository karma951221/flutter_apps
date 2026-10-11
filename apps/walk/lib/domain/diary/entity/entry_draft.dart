import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../diary_failure.dart';
import 'entry_location.dart';
import 'entry_media.dart';
import 'media_limits.dart';

part 'entry_draft.freezed.dart';

/// 작성 · 수정 입력.
@freezed
class EntryDraft with _$EntryDraft {
  @override
  final String storyId;

  @override
  final String body;

  @override
  final DateTime occurredAt;

  @override
  final EntryLocation? location;

  @override
  final List<EntryMedia> media;

  @override
  final List<String> tags;

  const EntryDraft({
    required this.storyId,
    required this.body,
    required this.occurredAt,
    this.location,
    required this.media,
    required this.tags,
  });

  /// 미래 시각 → 빈 기록 → 미디어 개수 → 영상 길이 순으로 검사해 처음 걸린 것을 돌려준다.
  Result<EntryDraft> validate(DateTime now) {
    if (occurredAt.isAfter(now)) {
      return Err(DiaryFailure.futureTime.toFailure());
    }
    if (body.trim().isEmpty && media.isEmpty) {
      return Err(DiaryFailure.emptyEntry.toFailure());
    }
    if (!MediaLimits.canAdd(0, media.length)) {
      return Err(DiaryFailure.tooManyMedia.toFailure());
    }
    final tooLong = media.any(
      (m) =>
          m.kind == MediaKind.video &&
          !MediaLimits.videoAllowed(Duration(milliseconds: m.durationMs ?? 0)),
    );
    if (tooLong) return Err(DiaryFailure.videoTooLong.toFailure());
    return Ok(this);
  }
}
