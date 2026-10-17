import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/social/entity/walk_post.dart';

part 'community_state.freezed.dart';

@freezed
sealed class CommunityState with _$CommunityState {
  /// Supabase 초기화가 실패했다 — 안내만 하고 다시 시도는 없다(앱을 다시 열어야 한다).
  const factory CommunityState.unavailable() = CommunityUnavailable;

  /// 첫 페이지를 읽는 중. [isSignedIn] 으로 앱바 더보기(로그인 · 로그아웃)를 정한다.
  const factory CommunityState.loading({required bool isSignedIn}) =
      CommunityLoading;

  /// [posts] 는 지금까지 읽은 페이지(최신순). [nextCursor] 가 있으면 더 읽을 수 있다.
  /// [failure] 는 목록을 둔 채 실패한 새로고침 · 더 읽기 — 스낵바로 한 번 알린다.
  /// [loadMoreFailed] 면 더 읽기가 실패한 뒤다 — 스크롤로는 다시 부르지 않고(요청 폭주를
  /// 막는다) 목록 끝의 "다시 시도" 나 새로고침을 기다린다.
  const factory CommunityState.loaded({
    required List<WalkPost> posts,
    required bool isSignedIn,
    String? nextCursor,
    @Default(false) bool isLoadingMore,
    @Default(false) bool loadMoreFailed,
    Failure? failure,
  }) = CommunityLoaded;

  /// 첫 페이지를 못 읽었다 — 안내 + 다시 시도.
  const factory CommunityState.failure(
    Failure failure, {
    required bool isSignedIn,
  }) = CommunityFailure;
}
