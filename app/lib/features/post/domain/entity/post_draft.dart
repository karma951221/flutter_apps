import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_draft.freezed.dart';

/// 새 게시물 작성에 필요한 입력값.
///
/// 작성자와 작성 시각은 DB 가 정한다 (`author_id default auth.uid()`).
/// 앱이 보내지 않으므로 위조할 경로가 없다.
@freezed
class PostDraft with _$PostDraft {
  const PostDraft({required this.content});

  @override
  final String content;
}
