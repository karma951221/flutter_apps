import 'package:freezed_annotation/freezed_annotation.dart';

import 'feed_post_image_dto.dart';

part 'feed_post_dto.freezed.dart';
part 'feed_post_dto.g.dart';

/// 피드가 조회하는 `posts_with_author` 뷰 한 행의 전송 형식.
///
/// post feature 의 `PostDto` 와 겹쳐 보이지만 소유자도 원천도 다르다. 이쪽은
/// 게시물 테이블이 아니라 작성자를 조인한 뷰를 읽고, 앞으로 반응 수 · 댓글 수
/// 컬럼이 여기에만 더해진다. 게시물 단건 조회는 그 값들이 필요 없다.
/// feature 의 data 계층은 서로 참조하지 않는다 (아키텍처 규칙 ⑤·⑥).
@freezed
@JsonSerializable()
class FeedPostDto with _$FeedPostDto {
  const FeedPostDto({
    required this.id,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.authorNickname,
    this.authorAvatarUrl,
    this.images = const [],
  });

  @override
  final String id;
  @override
  @JsonKey(name: 'author_id')
  final String authorId;
  @override
  final String content;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  /// 뷰가 조인해 내려주는 작성자 닉네임. `profiles.nickname` 은 not null 이고
  /// 뷰가 inner join 이므로 항상 값이 있다.
  @override
  @JsonKey(name: 'author_nickname')
  final String authorNickname;

  /// 아바타는 아직 올리지 않은 사용자가 있어 null 일 수 있다.
  @override
  @JsonKey(name: 'author_avatar_url')
  final String? authorAvatarUrl;
  @override
  @JsonKey(defaultValue: [])
  final List<FeedPostImageDto> images;

  factory FeedPostDto.fromJson(Map<String, dynamic> json) =>
      _$FeedPostDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FeedPostDtoToJson(this);
}
