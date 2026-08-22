import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_update.freezed.dart';

/// 기존 게시물 수정에 필요한 입력값.
@freezed
class PostUpdate with _$PostUpdate {
  const PostUpdate({required this.content});

  @override
  final String content;
}
