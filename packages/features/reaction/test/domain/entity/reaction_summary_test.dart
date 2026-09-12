import 'package:feature_reaction/feature_reaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('처음 누르면 개수가 늘고 내 반응이 된다', () {
    const summary = ReactionSummary();

    final next = summary.toggled(ReactionType.like);

    expect(next.countOf(ReactionType.like), 1);
    expect(next.mine, ReactionType.like);
    expect(next.isMine(ReactionType.like), isTrue);
  });

  test('같은 것을 다시 누르면 취소된다', () {
    const summary = ReactionSummary(
      counts: {ReactionType.like: 3},
      mine: ReactionType.like,
    );

    final next = summary.toggled(ReactionType.like);

    expect(next.countOf(ReactionType.like), 2);
    expect(next.mine, isNull);
  });

  test('취소로 0이 되면 항목 자체가 사라진다', () {
    const summary = ReactionSummary(
      counts: {ReactionType.like: 1},
      mine: ReactionType.like,
    );

    final next = summary.toggled(ReactionType.like);

    expect(next.counts.containsKey(ReactionType.like), isFalse);
    expect(next.mine, isNull);
  });

  test('다른 것을 누르면 이전 반응이 해제되고 새 반응이 선다', () {
    const summary = ReactionSummary(
      counts: {ReactionType.like: 2, ReactionType.dislike: 1},
      mine: ReactionType.like,
    );

    final next = summary.toggled(ReactionType.dislike);

    expect(next.countOf(ReactionType.like), 1);
    expect(next.countOf(ReactionType.dislike), 2);
    expect(next.mine, ReactionType.dislike);
  });

  test('내 반응이 없으면 남의 개수를 줄이지 않는다', () {
    const summary = ReactionSummary(counts: {ReactionType.like: 5});

    final next = summary.toggled(ReactionType.dislike);

    expect(next.countOf(ReactionType.like), 5);
    expect(next.countOf(ReactionType.dislike), 1);
  });

  test('fromRaw 는 뷰가 내려준 문자열을 엔티티로 옮긴다', () {
    final summary = ReactionSummary.fromRaw(const {
      'like': 4,
      'dislike': 1,
    }, 'like');

    expect(summary.countOf(ReactionType.like), 4);
    expect(summary.countOf(ReactionType.dislike), 1);
    expect(summary.mine, ReactionType.like);
  });

  test('앱이 모르는 감정 코드는 무시한다', () {
    // 감정을 DB 에 먼저 추가하고 앱을 나중에 배포해도 목록이 깨지지 않아야 한다.
    final summary = ReactionSummary.fromRaw(const {
      'like': 2,
      'love': 9,
    }, 'love');

    expect(summary.countOf(ReactionType.like), 2);
    expect(summary.counts.length, 1);
    expect(summary.mine, isNull);
  });
}
