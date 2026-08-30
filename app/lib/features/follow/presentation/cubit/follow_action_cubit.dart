import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/follow_relation.dart';
import '../../domain/usecase/follow_use_case.dart';
import 'follow_action_state.dart';

/// 프로필의 팔로우 버튼을 소유한다.
///
/// 관계는 프로필 조회(`profile_details`)가 함께 내려주므로 여기서 다시 묻지
/// 않는다 — 화면이 [seed] 로 심어 준다. `BlockActionCubit` 이 상태를 따로
/// 조회하는 것과 다른 점이고, 이유는 차단이 프로필 응답에 들어 있지 않기
/// 때문이다.
///
/// 낙관적 업데이트는 여기서 한다. 누르는 즉시 관계와 팔로워 수를 바꾸고,
/// 실패하면 눌렀을 때의 값으로 되돌린다. 목록·수를 소유한 쪽이 낙관적 갱신을
/// 한다는 F5 의 결정과 같은 자리다.
///
/// `BuildContext` 를 알지 못한다 — 스낵바는 호출한 화면의 몫이다.
@injectable
class FollowActionCubit extends Cubit<FollowActionState> {
  FollowActionCubit(this._useCase) : super(const FollowActionState());

  final FollowUseCase _useCase;

  /// 프로필 조회 결과를 초기 상태로 심는다.
  void seed({required FollowRelation relation, required int followerCount}) {
    emit(
      FollowActionState(relation: relation, followerCount: followerCount),
    );
  }

  /// 팔로우 상태를 뒤집는다. 성공하면 `true`.
  ///
  /// 진행 중이면 아무것도 하지 않는다 — 연타로 팔로우와 해제가 엇갈려 도착하면
  /// 마지막 응답이 화면을 결정해 버린다.
  Future<bool> toggle(String userId) async {
    final before = state;
    if (before.isSubmitting) return false;

    final willFollow = !before.relation.isFollowing;
    emit(
      before.copyWith(
        relation: FollowRelation(
          isFollowing: willFollow,
          isFollowedBy: before.relation.isFollowedBy,
        ),
        followerCount: (before.followerCount + (willFollow ? 1 : -1))
            .clamp(0, 1 << 31),
        isSubmitting: true,
        failure: null,
      ),
    );

    final result = willFollow
        ? await _useCase.followUser(userId)
        : await _useCase.unfollowUser(userId);
    if (isClosed) return false;

    return result.when(
      ok: (_) {
        emit(state.copyWith(isSubmitting: false));
        return true;
      },
      err: (failure) {
        // 눌렀을 때의 값으로 되돌린다. 그 사이 다른 것이 상태를 바꾸지
        // 않는다 — toggle 은 진행 중이면 다시 들어오지 않는다.
        emit(before.copyWith(isSubmitting: false, failure: failure));
        return false;
      },
    );
  }
}
