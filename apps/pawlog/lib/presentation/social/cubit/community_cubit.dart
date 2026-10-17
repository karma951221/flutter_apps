import 'dart:async';
import 'dart:math';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/supabase/social_availability.dart';
import '../../../domain/social/entity/auth_session.dart';
import '../../../domain/social/entity/walk_post.dart';
import '../../../domain/social/usecase/social_use_case.dart';
import 'community_state.dart';

/// 모두의 산책 목록 — 첫 페이지 · 더 읽기 · 새로고침 · 좋아요(낙관적 갱신).
///
/// 로그인 상태가 바뀌면(다른 사용자 id) 목록을 다시 읽는다 — `liked_by_me` 가 사용자마다
/// 다르다. 같은 사용자의 세션이 다시 오는 것(프로필을 읽은 뒤 닉네임만 채워진 값)은 무시한다.
@injectable
class CommunityCubit extends Cubit<CommunityState> {
  CommunityCubit(this._useCase, this._social)
    : super(const CommunityState.loading(isSignedIn: false));

  final SocialUseCase _useCase;
  final SocialAvailability _social;

  StreamSubscription<AuthSession?>? _sessionSubscription;
  String? _userId;

  /// 첫 페이지를 새로 읽을 때마다 는다. 그 전에 시작한 읽기의 결과는 버린다.
  int _epoch = 0;

  /// 좋아요를 보내는 중인 글 — 다시 누른 것은 무시한다.
  final _likeBusy = <String>{};

  bool get _signedIn => _userId != null;

  Future<void> start() async {
    if (!_social.isAvailable) {
      emit(const CommunityState.unavailable());
      return;
    }
    _userId = _useCase.currentSession?.userId;
    await _sessionSubscription?.cancel();
    _sessionSubscription = _useCase.sessions.listen(_onSession);
    await retry();
  }

  /// 첫 페이지부터 다시 읽는다 — 화면을 로딩으로 비운다.
  Future<void> retry() async {
    if (isClosed || state is CommunityUnavailable) return;
    emit(CommunityState.loading(isSignedIn: _signedIn));
    await _fetchFirst();
  }

  /// 당겨서 새로고침 — 목록이 떠 있으면 그대로 두고 첫 페이지로 바꾼다.
  Future<void> refresh() async {
    if (isClosed || state is CommunityUnavailable) return;
    if (state is! CommunityLoaded) return retry();
    await _fetchFirst();
  }

  /// 다음 페이지. loaded 가 아니거나, 읽는 중이거나, 더 없으면 아무것도 하지 않는다.
  Future<void> loadMore() async {
    final current = state;
    if (isClosed ||
        current is! CommunityLoaded ||
        current.isLoadingMore ||
        current.nextCursor == null) {
      return;
    }
    final epoch = _epoch;
    emit(current.copyWith(isLoadingMore: true, failure: null));
    final result = await _useCase.fetchCommunityPage(after: current.nextCursor);
    if (isClosed || epoch != _epoch) return;
    final latest = state;
    if (latest is! CommunityLoaded) return;
    switch (result) {
      case Ok(value: final page):
        emit(
          latest.copyWith(
            posts: [...latest.posts, ...page.items],
            nextCursor: page.nextCursor,
            isLoadingMore: false,
          ),
        );
      case Err(:final failure):
        emit(latest.copyWith(isLoadingMore: false, failure: failure));
    }
  }

  /// 하트를 뒤집는다. 화면은 바로 바뀌고 실패하면 되돌린다. 로그인하지 않았으면 바꾸지
  /// 않고 [FailureCode.authenticationRequired] 를 돌려준다 — 페이지가 로그인 화면을 연다.
  Future<Result<void>> toggleLike(String postId) async {
    final current = state;
    if (current is! CommunityLoaded) return const Ok(null);
    if (_useCase.currentSession == null) {
      return const Err(
        Failure.auth(failureCode: FailureCode.authenticationRequired),
      );
    }
    final post = current.posts.where((p) => p.id == postId).firstOrNull;
    if (post == null || !_likeBusy.add(postId)) return const Ok(null);
    try {
      final like = !post.likedByMe;
      _updatePost(postId, (p) => _withLike(p, like));
      final result = like
          ? await _useCase.likePost(postId)
          : await _useCase.unlikePost(postId);
      if (result is Err && !isClosed) {
        // 그 사이 새로고침이 서버 값으로 바꿨으면 그대로 둔다.
        _updatePost(
          postId,
          (p) => p.likedByMe == like ? _withLike(p, !like) : p,
        );
      }
      return result;
    } finally {
      _likeBusy.remove(postId);
    }
  }

  Future<Result<void>> signOut() => _useCase.signOut();

  static WalkPost _withLike(WalkPost post, bool like) => post.copyWith(
    likedByMe: like,
    likeCount: max(0, post.likeCount + (like ? 1 : -1)),
  );

  void _updatePost(String postId, WalkPost Function(WalkPost) update) {
    final current = state;
    if (current is! CommunityLoaded) return;
    emit(
      current.copyWith(
        posts: [for (final p in current.posts) p.id == postId ? update(p) : p],
        failure: null,
      ),
    );
  }

  Future<void> _fetchFirst() async {
    final epoch = ++_epoch;
    final result = await _useCase.fetchCommunityPage();
    if (isClosed || epoch != _epoch) return;
    switch (result) {
      case Ok(value: final page):
        emit(
          CommunityState.loaded(
            posts: page.items,
            nextCursor: page.nextCursor,
            isSignedIn: _signedIn,
          ),
        );
      case Err(:final failure):
        final current = state;
        emit(
          current is CommunityLoaded
              ? current.copyWith(failure: failure, isSignedIn: _signedIn)
              : CommunityState.failure(failure, isSignedIn: _signedIn),
        );
    }
  }

  void _onSession(AuthSession? session) {
    if (isClosed) return;
    final userId = session?.userId;
    if (userId == _userId) return;
    _userId = userId;
    final current = state;
    // 더보기 라벨은 바로 바꾸고 목록은 이어서 다시 읽는다.
    switch (current) {
      case CommunityLoaded():
        emit(current.copyWith(isSignedIn: _signedIn, failure: null));
      case CommunityLoading():
        emit(CommunityState.loading(isSignedIn: _signedIn));
      case CommunityFailure(:final failure):
        emit(CommunityState.failure(failure, isSignedIn: _signedIn));
      case CommunityUnavailable():
        return;
    }
    unawaited(refresh());
  }

  @override
  Future<void> close() async {
    await _sessionSubscription?.cancel();
    return super.close();
  }
}
