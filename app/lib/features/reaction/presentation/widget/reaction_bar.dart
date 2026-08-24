import 'package:flutter/material.dart';

import '../../../../design_system/widget/app_count_action.dart';
import '../../domain/entity/reaction_summary.dart';
import '../../domain/entity/reaction_type.dart';

/// 감정 버튼 줄. 게시물 카드와 댓글 목록이 같은 것을 쓴다.
///
/// 이 위젯은 상태를 갖지 않는다. 누른 결과를 계산하고 반영하는 일은 목록을
/// 소유한 쪽(`FeedCubit` · `CommentCubit`)이 한다 — 감정 전용 Bloc 을 두지
/// 않는 이유는 docs/features/reaction/plan.md 에 있다.
///
/// 보여줄 감정을 [types] 로 받는 이유: "싫어요 노출을 백엔드 변경 없이 되돌릴
/// 수 있게" 가 이 feature 의 요구사항이다. 응답은 모든 종류를 담고, 무엇을
/// 그릴지는 화면이 고른다.
class ReactionBar extends StatelessWidget {
  const ReactionBar({
    required this.summary,
    required this.onTap,
    this.types = const [ReactionType.like, ReactionType.dislike],
    super.key,
  });

  final ReactionSummary summary;
  final ValueChanged<ReactionType>? onTap;
  final List<ReactionType> types;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final type in types)
        AppCountAction(
          icon: _iconOf(type, isActive: summary.isMine(type)),
          count: summary.countOf(type),
          tooltip: _tooltipOf(type),
          isActive: summary.isMine(type),
          onPressed: onTap == null ? null : () => onTap!(type),
        ),
    ],
  );

  IconData _iconOf(ReactionType type, {required bool isActive}) =>
      switch (type) {
        ReactionType.like => isActive
            ? Icons.thumb_up
            : Icons.thumb_up_outlined,
        ReactionType.dislike => isActive
            ? Icons.thumb_down
            : Icons.thumb_down_outlined,
      };

  String _tooltipOf(ReactionType type) => switch (type) {
    ReactionType.like => '좋아요',
    ReactionType.dislike => '싫어요',
  };
}
