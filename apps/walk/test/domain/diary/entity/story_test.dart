import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/diary_failure.dart';
import 'package:walk/domain/diary/entity/story.dart';

Story _story({
  String id = 's1',
  StoryStatus status = StoryStatus.open,
  DateTime? endedAt,
}) => Story(
  id: id,
  title: '제주',
  status: status,
  startedAt: DateTime(2026, 10, 1),
  endedAt: endedAt,
  createdAt: DateTime(2026, 10, 1),
);

void _expectFailure(Result<Story> r, DiaryFailure f) {
  switch (r) {
    case Err(:final failure):
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).field, f.name);
    case Ok():
      fail('Err 여야 한다');
  }
}

void main() {
  group('close', () {
    test('닫으면 closed + endedAt', () {
      final at = DateTime(2026, 10, 5);
      switch (_story().close(at)) {
        case Ok(:final value):
          expect(value.status, StoryStatus.closed);
          expect(value.endedAt, at);
          expect(value.isOpen, isFalse);
        case Err():
          fail('Ok 여야 한다');
      }
    });
    test('기본 스토리는 거절', () {
      _expectFailure(
        _story(id: Story.dailyId).close(DateTime(2026, 10, 5)),
        DiaryFailure.defaultStoryLocked,
      );
    });
    test('시작 전 시각은 거절', () {
      _expectFailure(
        _story().close(DateTime(2026, 9, 30)),
        DiaryFailure.endBeforeStart,
      );
    });
    test('시작과 같은 시각은 허용', () {
      expect(_story().close(DateTime(2026, 10, 1)), isA<Ok<Story>>());
    });
  });

  test('reopen 은 endedAt 을 지우고 연다', () {
    final closed = _story(
      status: StoryStatus.closed,
      endedAt: DateTime(2026, 10, 5),
    );
    switch (closed.reopen()) {
      case Ok(:final value):
        expect(value.endedAt, isNull);
        expect(value.isOpen, isTrue);
      case Err():
        fail('Ok 여야 한다');
    }
  });

  group('covers', () {
    final s = _story(endedAt: DateTime(2026, 10, 5));
    test('경계 포함', () {
      expect(s.covers(DateTime(2026, 10, 1)), isTrue);
      expect(s.covers(DateTime(2026, 10, 5)), isTrue);
    });
    test('범위 밖', () {
      expect(s.covers(DateTime(2026, 9, 30, 23, 59, 59)), isFalse);
      expect(s.covers(DateTime(2026, 10, 5, 0, 0, 1)), isFalse);
    });
    test('endedAt 이 없으면 미래 전부', () {
      expect(_story().covers(DateTime(2030)), isTrue);
    });
  });

  test('isDefault', () {
    expect(_story(id: Story.dailyId).isDefault, isTrue);
    expect(_story().isDefault, isFalse);
  });
}
