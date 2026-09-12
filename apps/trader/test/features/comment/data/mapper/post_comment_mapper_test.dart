import 'package:daylog/features/comment/data/dto/post_comment_dto.dart';
import 'package:daylog/features/comment/data/mapper/post_comment_mapper.dart';
import 'package:feature_reaction/feature_reaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('뷰 한 행을 댓글 엔티티로 옮긴다', () {
    final dto = PostCommentDto(
      id: 'comment-1',
      postId: 'post-1',
      authorId: 'author-1',
      authorNickname: '카르마',
      content: '첫 댓글',
      createdAt: DateTime.utc(2026, 8, 23, 9),
      replyCount: 2,
      reactionCounts: const {'like': 3},
      myReaction: 'like',
    );

    final comment = dto.toEntity();

    expect(comment.id, 'comment-1');
    expect(comment.author.nickname, '카르마');
    expect(comment.content, '첫 댓글');
    expect(comment.isDeleted, isFalse);
    expect(comment.isReply, isFalse);
    expect(comment.replyCount, 2);
    expect(comment.reactions.countOf(ReactionType.like), 3);
    expect(comment.reactions.mine, ReactionType.like);
  });

  test('삭제된 댓글은 본문이 없고 isDeleted 가 참이다', () {
    final dto = PostCommentDto(
      id: 'comment-1',
      postId: 'post-1',
      authorId: 'author-1',
      authorNickname: '카르마',
      createdAt: DateTime.utc(2026, 8, 23, 9),
      deletedAt: DateTime.utc(2026, 8, 23, 10),
      replyCount: 1,
    );

    final comment = dto.toEntity();

    expect(comment.content, isNull);
    expect(comment.isDeleted, isTrue);
  });

  test('답글은 parentId 를 갖는다', () {
    final dto = PostCommentDto(
      id: 'reply-1',
      postId: 'post-1',
      parentId: 'comment-1',
      authorId: 'author-1',
      authorNickname: '이웃',
      content: '답글',
      createdAt: DateTime.utc(2026, 8, 23, 9, 1),
    );

    expect(dto.toEntity().isReply, isTrue);
  });

  test('뷰 응답 JSON 의 스네이크 케이스 컬럼을 읽는다', () {
    final dto = PostCommentDto.fromJson(const {
      'id': 'comment-1',
      'post_id': 'post-1',
      'parent_id': null,
      'author_id': 'author-1',
      'content': '첫 댓글',
      'created_at': '2026-08-23T09:00:00Z',
      'deleted_at': null,
      'author_nickname': '카르마',
      'author_avatar_url': null,
      'reply_count': 2,
      'reaction_counts': {'like': 3},
      'my_reaction': 'like',
    });

    final comment = dto.toEntity();

    expect(comment.author.nickname, '카르마');
    expect(comment.author.avatarUrl, isNull);
    expect(comment.replyCount, 2);
    expect(comment.reactions.countOf(ReactionType.like), 3);
  });

  test('마지막 항목으로 다음 페이지 커서를 만든다', () {
    final dto = PostCommentDto(
      id: 'comment-9',
      postId: 'post-1',
      authorId: 'author-1',
      authorNickname: '카르마',
      content: '댓글',
      createdAt: DateTime.utc(2026, 8, 23, 9, 5),
    );

    final cursor = dto.toCursor();

    expect(cursor.id, 'comment-9');
    expect(cursor.createdAt, DateTime.utc(2026, 8, 23, 9, 5));
  });
}
