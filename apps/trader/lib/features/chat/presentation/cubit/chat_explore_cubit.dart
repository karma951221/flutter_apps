import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/chat_policy.dart';
import '../../domain/usecase/chat_use_case.dart';
import 'chat_explore_state.dart';

/// 공개방 탐색 목록을 소유한다.
///
/// 검색은 디바운스한다 — 글자마다 조회하면 대부분이 버려지는 요청이 된다.
/// 닉네임 사전 확인(`ProfileCubit.checkNickname`)과 같은 방식이고, 늦게 도착한
/// 옛 응답이 새 결과를 덮지 않도록 요청 번호로 막는 것도 같다.
@injectable
class ChatExploreCubit extends Cubit<ChatExploreState> {
  ChatExploreCubit(this._useCase) : super(const ChatExploreState());

  static const searchDebounce = Duration(milliseconds: 350);

  final ChatUseCase _useCase;

  Timer? _debounce;
  int _request = 0;

  Future<void> load() => _fetch(state.query, ++_request);

  /// 입력이 바뀔 때마다 부른다.
  void search(String query) {
    _debounce?.cancel();
    final next = query.trim();
    if (next == state.query) return;

    final request = ++_request;
    _debounce = Timer(searchDebounce, () => _fetch(next, request));
  }

  Future<void> refresh() => _fetch(state.query, ++_request);

  Future<void> _fetch(String query, int request) async {
    final result = await _useCase.getOpenRooms(
      limit: ChatPolicy.roomPageSize,
      query: query.isEmpty ? null : query,
    );
    if (isClosed || request != _request) return;

    emit(
      result.when(
        ok: (page) => ChatExploreState(
          status: ChatExploreStatus.loaded,
          items: page.items,
          query: query,
          nextCursor: page.nextCursor,
        ),
        err: (failure) => ChatExploreState(
          status: ChatExploreStatus.failure,
          query: query,
          failure: failure,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current.status != ChatExploreStatus.loaded ||
        current.isLoadingMore ||
        !current.canLoadMore) {
      return;
    }

    final request = _request;
    emit(
      ChatExploreState(
        status: current.status,
        items: current.items,
        query: current.query,
        isLoadingMore: true,
        nextCursor: current.nextCursor,
      ),
    );

    final result = await _useCase.getOpenRooms(
      limit: ChatPolicy.roomPageSize,
      cursor: current.nextCursor,
      query: current.query.isEmpty ? null : current.query,
    );
    // 더 읽는 동안 검색어가 바뀌었으면 이 페이지는 버린다. 붙이면 다른
    // 검색의 결과가 섞인다.
    if (isClosed || request != _request) return;

    emit(
      result.when(
        ok: (page) => ChatExploreState(
          status: ChatExploreStatus.loaded,
          items: [...current.items, ...page.items],
          query: current.query,
          nextCursor: page.nextCursor,
        ),
        // 더 읽기 실패는 이미 읽은 목록을 지우지 않는다. 커서를 그대로 두어
        // 다시 시도할 수 있게 한다.
        err: (_) => ChatExploreState(
          status: ChatExploreStatus.loaded,
          items: current.items,
          query: current.query,
          nextCursor: current.nextCursor,
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
