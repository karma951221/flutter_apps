import 'package:core/core.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:walk/data/diary/database/diary_database.dart';
import 'package:walk/data/diary/drift_diary_repository.dart';
import 'package:walk/domain/diary/entity/entry_draft.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/entity/named_count.dart';
import 'package:walk/domain/diary/entity/story.dart';

/// 일기 테스트 공용 시각.
final diaryT0 = DateTime(2026, 10, 10, 9);

/// 테스트가 직접 움직이는 시계.
class MutableClock extends Clock {
  MutableClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;

  void advance(Duration by) => value = value.add(by);
}

/// 메모리 DB 위의 저장소 묶음. [close] 로 닫는다.
class DiaryHarness {
  DiaryHarness._(this.db, this.repository, this.clock);

  factory DiaryHarness({DateTime? now}) {
    final clock = MutableClock(now ?? diaryT0);
    final db = DiaryDatabase(NativeDatabase.memory(), now: clock.now);
    return DiaryHarness._(
      db,
      DriftDiaryRepository(db, const IdGenerator(Uuid()), clock),
      clock,
    );
  }

  final DiaryDatabase db;
  final DriftDiaryRepository repository;
  final MutableClock clock;

  Future<void> close() => db.close();

  /// 휴지통 기능(T5) 없이 `deletedAt` 만 채운다.
  Future<void> trashDirectly(String entryId) =>
      (db.update(db.entries)..where((e) => e.id.equals(entryId))).write(
        EntriesCompanion(deletedAt: Value(clock.now())),
      );
}

EntryMedia photoMedia(String id, {String? path}) => EntryMedia(
  id: id,
  kind: MediaKind.photo,
  path: path ?? 'media/$id.jpg',
  thumbPath: null,
  width: 1600,
  height: 1200,
  bytes: 1000,
);

EntryMedia videoMedia(String id) => EntryMedia(
  id: id,
  kind: MediaKind.video,
  path: 'media/$id.mp4',
  thumbPath: 'media/$id.thumb.jpg',
  width: 1280,
  height: 720,
  durationMs: 12000,
  bytes: 50000,
);

EntryDraft entryDraft({
  String storyId = Story.dailyId,
  String body = '본문',
  DateTime? occurredAt,
  EntryLocation? location,
  List<EntryMedia> media = const [],
  List<String> tags = const [],
}) => EntryDraft(
  storyId: storyId,
  body: body,
  occurredAt: occurredAt ?? diaryT0,
  location: location,
  media: media,
  tags: tags,
);

/// [Ok] 의 값을 꺼낸다. [Err] 면 테스트 실패.
T okValue<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => fail('Ok 여야 하는데 $failure'),
};

/// [Err] 의 실패를 꺼낸다. [Ok] 면 테스트 실패.
Failure errFailure<T>(Result<T> result) => switch (result) {
  Err(:final failure) => failure,
  Ok(:final value) => fail('Err 여야 하는데 Ok($value)'),
};

/// `Failure.validation(field: name)` 인지 확인한다.
Matcher isDiaryFailure(String name) =>
    isA<ValidationFailure>().having((f) => f.field, 'field', name);

/// [stream] 을 지금 구독해 이벤트를 모두 모은다. 첫 이벤트까지 기다리고,
/// 구독은 테스트가 끝날 때 취소한다. 같은 구독의 연속 이벤트로 반영을 확인할 때 쓴다.
Future<List<T>> recordEvents<T>(Stream<T> stream) async {
  final events = <T>[];
  final sub = stream.listen(events.add);
  addTearDown(sub.cancel);
  await pumpEventQueue();
  return events;
}

/// 집계를 `'이름 개수'` 로 펼친다(순서 유지).
List<String> namedCounts(List<NamedCount> counts) => [
  for (final c in counts) '${c.name} ${c.count}',
];
