import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_author.freezed.dart';

/// 게시물 카드에 보이는 만큼의 작성자 정보.
///
/// profile feature 의 `Profile` 을 쓰지 않는 이유: 목록은 닉네임과 아바타만
/// 필요한데 `Profile` 은 `bio` · `createdAt` · `updatedAt` 까지 요구한다.
/// 목록 조회가 내려주지 않는 값을 채우려면 게시물마다 프로필을 다시 조회해야
/// 하고, 그게 이 조인으로 없애려던 N+1 이다.
///
/// post feature 가 소유한다. 작성자는 게시물의 성질이고, 이 타입을 쓰는
/// `PostTile` 도 post 가 가지고 있다. feed 와 profile 이 함께 참조한다
/// (아키텍처 규칙 ⑥ — feature 간 참조는 domain 까지).
@freezed
class PostAuthor with _$PostAuthor {
  const PostAuthor({
    required this.id,
    required this.nickname,
    this.avatarUrl,
  });

  @override
  final String id;
  @override
  final String nickname;
  @override
  final String? avatarUrl;
}
