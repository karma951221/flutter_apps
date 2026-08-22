import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_post_draft.freezed.dart';

/// 새 피드 게시물 작성에 필요한 입력값.
///
/// 작성자와 작성 시각은 신뢰할 수 있는 서버 측에서 결정한다.
@freezed
class FeedPostDraft with _$FeedPostDraft {
  const FeedPostDraft({required this.content});

  @override
  final String content;
}
