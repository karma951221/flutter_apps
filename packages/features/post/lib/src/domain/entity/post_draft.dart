import 'package:freezed_annotation/freezed_annotation.dart';

import 'post_image_draft.dart';

part 'post_draft.freezed.dart';

/// 새 게시물 작성에 필요한 입력값.
///
/// 작성자와 작성 시각은 DB 가 정한다 (`author_id default auth.uid()`).
/// 앱이 보내지 않으므로 위조할 경로가 없다.
@freezed
class PostDraft with _$PostDraft {
  const PostDraft({
    required this.content,
    this.images = const [],
    this.tradeSessionId,
  });

  @override
  final String content;
  @override
  final List<PostImageDraft> images;

  /// 함께 공유할 끝난 판의 id. 붙이지 않으면 null 이다.
  ///
  /// 끝난 내 판인지는 DB 가 판정한다 — `create_post_with_images()` 가 어긋난
  /// 판을 거부한다(apps/trader/docs/schema.md §5). 앱은 id 를 실어 나르기만 한다.
  @override
  final String? tradeSessionId;
}
