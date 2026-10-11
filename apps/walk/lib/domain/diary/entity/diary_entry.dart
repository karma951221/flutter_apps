import 'package:freezed_annotation/freezed_annotation.dart';

import 'entry_location.dart';
import 'entry_media.dart';

part 'diary_entry.freezed.dart';

@freezed
class DiaryEntry with _$DiaryEntry {
  @override
  final String id;

  @override
  final String storyId;

  @override
  final String body;

  /// 기록이 가리키는 시각(사용자가 고칠 수 있다).
  @override
  final DateTime occurredAt;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  /// 휴지통에 넣은 시각. null 이면 살아 있다.
  @override
  final DateTime? deletedAt;

  @override
  final EntryLocation? location;

  @override
  final List<EntryMedia> media;

  /// 정규화된 이름, 입력 순.
  @override
  final List<String> tags;

  const DiaryEntry({
    required this.id,
    required this.storyId,
    required this.body,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.location,
    required this.media,
    required this.tags,
  });

  bool get isTrashed => deletedAt != null;

  /// 사용자가 시각을 직접 바꿨는지.
  bool get timeEdited => occurredAt != createdAt;
}
