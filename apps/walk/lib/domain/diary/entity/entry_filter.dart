import 'package:freezed_annotation/freezed_annotation.dart';

part 'entry_filter.freezed.dart';

@freezed
sealed class EntryFilter with _$EntryFilter {
  const factory EntryFilter.all() = AllEntries;
  const factory EntryFilter.story(String storyId) = StoryEntries;
  const factory EntryFilter.tag(String name) = TagEntries;
  const factory EntryFilter.place(String name) = PlaceEntries;
  const factory EntryFilter.body(String query) = BodyEntries;
}
