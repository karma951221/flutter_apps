import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_comment_dto.freezed.dart';
part 'post_comment_dto.g.dart';

/// `post_comments_visible` 뷰 한 행의 전송 형식.
///
/// 이 뷰는 security_invoker = off 라서 조회 권한 경계가 뷰의 where 에 있다.
/// 삭제된 댓글의 [content] 는 뷰가 null 로 지워서 내려준다.
@freezed
@JsonSerializable()
class PostCommentDto with _$PostCommentDto {
  const PostCommentDto({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorNickname,
    required this.createdAt,
    this.parentId,
    this.content,
    this.deletedAt,
    this.authorAvatarUrl,
    this.replyCount = 0,
    this.reactionCounts = const {},
    this.myReaction,
  });

  @override
  final String id;
  @override
  @JsonKey(name: 'post_id')
  final String postId;
  @override
  @JsonKey(name: 'parent_id')
  final String? parentId;
  @override
  @JsonKey(name: 'author_id')
  final String authorId;

  /// 삭제된 댓글은 뷰가 null 로 내려준다.
  @override
  final String? content;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;
  @override
  @JsonKey(name: 'author_nickname')
  final String authorNickname;
  @override
  @JsonKey(name: 'author_avatar_url')
  final String? authorAvatarUrl;

  /// 살아 있는 답글 수.
  @override
  @JsonKey(name: 'reply_count', defaultValue: 0)
  final int replyCount;

  /// 감정별 개수. 개수를 컬럼이 아니라 map 으로 받으므로 감정이 늘어도
  /// DTO 를 고치지 않는다.
  @override
  @JsonKey(name: 'reaction_counts', defaultValue: <String, int>{})
  final Map<String, int> reactionCounts;
  @override
  @JsonKey(name: 'my_reaction')
  final String? myReaction;

  factory PostCommentDto.fromJson(Map<String, dynamic> json) =>
      _$PostCommentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PostCommentDtoToJson(this);
}
