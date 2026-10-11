import 'package:drift/drift.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/entry_location.dart';
import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/entity/story.dart';
import 'diary_database.dart';

Story storyFromRow(StoryRow row) => Story(
  id: row.id,
  title: row.title,
  status: row.status,
  startedAt: row.startedAt,
  endedAt: row.endedAt,
  coverMediaId: row.coverMediaId,
  lastPostedAt: row.lastPostedAt,
  createdAt: row.createdAt,
);

EntryMedia mediaFromRow(MediaRow row) => EntryMedia(
  id: row.id,
  kind: row.kind,
  path: row.path,
  thumbPath: row.thumbPath,
  width: row.width,
  height: row.height,
  durationMs: row.durationMs,
  bytes: row.bytes,
);

MediaCompanion mediaToCompanion(
  String entryId,
  int sortOrder,
  EntryMedia media,
) => MediaCompanion.insert(
  id: media.id,
  entryId: entryId,
  kind: media.kind,
  path: media.path,
  thumbPath: Value(media.thumbPath),
  sortOrder: sortOrder,
  width: media.width,
  height: media.height,
  durationMs: Value(media.durationMs),
  bytes: media.bytes,
);

/// 기록 행에 [media](sortOrder 순) · [tags](입력 순) · [placeName] 을 붙인다.
/// 장소 이름도 좌표도 없으면 location 은 null.
DiaryEntry entryFromRow(
  EntryRow row, {
  required List<EntryMedia> media,
  required List<String> tags,
  String? placeName,
}) => DiaryEntry(
  id: row.id,
  storyId: row.storyId,
  body: row.body,
  occurredAt: row.occurredAt,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
  deletedAt: row.deletedAt,
  location: placeName == null && row.lat == null && row.lng == null
      ? null
      : EntryLocation(placeName: placeName, lat: row.lat, lng: row.lng),
  media: media,
  tags: tags,
);
