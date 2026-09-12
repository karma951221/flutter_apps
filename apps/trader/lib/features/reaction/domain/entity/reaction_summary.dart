import 'package:freezed_annotation/freezed_annotation.dart';

import 'reaction_type.dart';

part 'reaction_summary.freezed.dart';

/// 한 대상의 감정 집계와 내 반응.
///
/// 목록 항목 안에 산다 (`FeedPost.reactions` · `PostComment.reactions`).
/// 감정 전용 Bloc 을 두지 않는 이유는 목록 상태를 목록이 소유하기 때문이다
/// (아키텍처 규칙 ⑥).
@freezed
class ReactionSummary with _$ReactionSummary {
  const ReactionSummary({this.counts = const {}, this.mine});

  @override
  final Map<ReactionType, int> counts;

  /// 내가 남긴 감정. 대상당 하나다.
  @override
  final ReactionType? mine;

  int countOf(ReactionType type) => counts[type] ?? 0;

  bool isMine(ReactionType type) => mine == type;

  /// [tapped] 를 눌렀을 때의 다음 상태.
  ///
  /// 낙관적 업데이트의 계산이 여기 한 곳에 있다. 게시물이든 댓글이든 같은
  /// 함수를 쓴다. 같은 것을 다시 누르면 취소이고, 다른 것을 누르면 이전 반응이
  /// 해제되면서 새 반응이 선다 — 대상당 감정은 하나다.
  ReactionSummary toggled(ReactionType tapped) {
    final next = Map<ReactionType, int>.from(counts);

    final previous = mine;
    if (previous != null) {
      final decreased = (next[previous] ?? 0) - 1;
      if (decreased > 0) {
        next[previous] = decreased;
      } else {
        next.remove(previous);
      }
    }

    if (previous == tapped) {
      return ReactionSummary(counts: next);
    }

    next[tapped] = (next[tapped] ?? 0) + 1;
    return ReactionSummary(counts: next, mine: tapped);
  }

  /// 목록 뷰가 내려준 `reaction_counts` · `my_reaction` 을 엔티티로 옮긴다.
  ///
  /// JSON 파싱은 각 feature 의 DTO 가 하고, 문자열 → 감정 변환만 여기서 한다.
  /// feature 의 data 계층끼리 참조하지 않으면서도 이 규칙이 한 곳에 있다.
  static ReactionSummary fromRaw(Map<String, int> counts, String? mine) {
    final parsed = <ReactionType, int>{};
    for (final entry in counts.entries) {
      final type = ReactionType.fromCode(entry.key);
      if (type != null) parsed[type] = entry.value;
    }
    return ReactionSummary(counts: parsed, mine: ReactionType.fromCode(mine));
  }
}
