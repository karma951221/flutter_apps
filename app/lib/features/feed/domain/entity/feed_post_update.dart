import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_post_update.freezed.dart';

/// 기존 피드 게시물 수정에 필요한 입력값.
@freezed
class FeedPostUpdate with _$FeedPostUpdate {
  const FeedPostUpdate({required this.content});

  @override
  final String content;
}
