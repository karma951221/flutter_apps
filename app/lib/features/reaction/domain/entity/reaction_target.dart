import 'package:freezed_annotation/freezed_annotation.dart';

part 'reaction_target.freezed.dart';

/// 감정을 남길 대상.
///
/// 이 타입이 재사용의 축이다. 대상이 늘어나면 여기에 변형을 하나 더하고,
/// data 계층의 테이블 매핑 한 줄과 마이그레이션만 는다. domain 과
/// presentation 의 다른 코드는 그대로다.
@freezed
sealed class ReactionTarget with _$ReactionTarget {
  const factory ReactionTarget.post(String id) = ReactionPostTarget;
  const factory ReactionTarget.comment(String id) = ReactionCommentTarget;
}
