import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/diary_failure.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_draft.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';

final _now = DateTime(2026, 10, 10, 12);

EntryMedia _media({MediaKind kind = MediaKind.photo, int? durationMs}) =>
    EntryMedia(
      id: 'm',
      kind: kind,
      path: 'p',
      width: 1,
      height: 1,
      durationMs: durationMs,
      bytes: 1,
    );

EntryDraft _draft({
  String body = '오늘',
  DateTime? occurredAt,
  List<EntryMedia> media = const [],
}) => EntryDraft(
  storyId: 'daily',
  body: body,
  occurredAt: occurredAt ?? _now,
  media: media,
  tags: const [],
);

void _expectFailure(EntryDraft d, DiaryFailure f) {
  switch (d.validate(_now)) {
    case Err(:final failure):
      expect((failure as ValidationFailure).field, f.name);
    case Ok():
      fail('Err 여야 한다');
  }
}

void main() {
  group('EntryDraft.validate', () {
    test('now 와 같은 시각은 OK', () {
      expect(_draft().validate(_now), isA<Ok<EntryDraft>>());
    });
    test('now + 1초는 futureTime', () {
      _expectFailure(
        _draft(occurredAt: _now.add(const Duration(seconds: 1))),
        DiaryFailure.futureTime,
      );
    });
    test('빈 글 + 미디어 0 은 emptyEntry', () {
      _expectFailure(_draft(body: ''), DiaryFailure.emptyEntry);
    });
    test('공백만 글도 emptyEntry', () {
      _expectFailure(_draft(body: ' \n\t '), DiaryFailure.emptyEntry);
    });
    test('미디어만 있으면 OK', () {
      expect(
        _draft(body: '', media: [_media()]).validate(_now),
        isA<Ok<EntryDraft>>(),
      );
    });
    test('미디어 11개는 tooManyMedia, 10개는 OK', () {
      _expectFailure(
        _draft(media: List.generate(11, (_) => _media())),
        DiaryFailure.tooManyMedia,
      );
      expect(
        _draft(media: List.generate(10, (_) => _media())).validate(_now),
        isA<Ok<EntryDraft>>(),
      );
    });
    test('영상 30_001ms 는 videoTooLong, 30_000ms 는 OK', () {
      _expectFailure(
        _draft(media: [_media(kind: MediaKind.video, durationMs: 30001)]),
        DiaryFailure.videoTooLong,
      );
      expect(
        _draft(
          media: [_media(kind: MediaKind.video, durationMs: 30000)],
        ).validate(_now),
        isA<Ok<EntryDraft>>(),
      );
    });
    test('검사 순서: futureTime 이 emptyEntry 보다 먼저', () {
      _expectFailure(
        _draft(body: '', occurredAt: _now.add(const Duration(minutes: 1))),
        DiaryFailure.futureTime,
      );
    });
    test('검사 순서: tooManyMedia 가 videoTooLong 보다 먼저', () {
      final media = [
        ...List.generate(10, (_) => _media()),
        _media(kind: MediaKind.video, durationMs: 99999),
      ];
      _expectFailure(_draft(media: media), DiaryFailure.tooManyMedia);
    });
  });

  group('DiaryEntry', () {
    DiaryEntry entry(DateTime occurredAt, {DateTime? deletedAt}) => DiaryEntry(
      id: 'e',
      storyId: 'daily',
      body: 'b',
      occurredAt: occurredAt,
      createdAt: _now,
      updatedAt: _now,
      deletedAt: deletedAt,
      media: const [],
      tags: const [],
    );
    test('timeEdited: occurredAt 이 createdAt 과 다르면 true', () {
      expect(entry(_now.subtract(const Duration(hours: 1))).timeEdited, isTrue);
    });
    test('timeEdited: 같으면 false', () {
      expect(entry(_now).timeEdited, isFalse);
    });
    test('isTrashed', () {
      expect(entry(_now).isTrashed, isFalse);
      expect(entry(_now, deletedAt: _now).isTrashed, isTrue);
    });
  });
}
