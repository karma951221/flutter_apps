import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';
import '../../domain/entity/chat_room.dart';

part 'chat_explore_state.freezed.dart';

/// 공개방 탐색 화면의 상태.
@freezed
class ChatExploreState with _$ChatExploreState {
  const ChatExploreState({
    this.status = ChatExploreStatus.loading,
    this.items = const [],
    this.query = '',
    this.isLoadingMore = false,
    this.nextCursor,
    this.failure,
  });

  @override
  final ChatExploreStatus status;
  @override
  final List<ChatRoom> items;

  /// 지금 걸려 있는 검색어. 빈 문자열이면 전체 목록이다.
  @override
  final String query;
  @override
  final bool isLoadingMore;
  @override
  final String? nextCursor;
  @override
  final Failure? failure;

  bool get canLoadMore => nextCursor != null;
}

enum ChatExploreStatus { loading, loaded, failure }
