import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/supabase/social_availability.dart';
import '../../../domain/social/entity/auth_session.dart';
import '../../../domain/social/usecase/social_use_case.dart';
import 'walk_share_state.dart';

/// 상세 화면의 "모두에게 공유" ↔ "공유 취소"(plan W5 social 결정 3).
///
/// `WalkDetailCubit` 과 나눠 둔다 — 상세의 읽기 · 삭제 · 즐겨찾기는 로컬이고, 이것만 서버를
/// 부른다. 로그인 사용자가 바뀌면(로그인 화면에서 돌아오면) 공유 여부를 다시 읽는다.
///
/// 산책을 지우기 전에는 [unshareForDelete] 로 공유를 먼저 거둔다 — 지운 산책이 모두의 산책에
/// 남지 않게. 순서는 상세 페이지가 정한다(이것 → `WalkDetailCubit.delete`).
@injectable
class WalkShareCubit extends Cubit<WalkShareState> {
  WalkShareCubit(this._useCase, this._social)
    : super(const WalkShareState.checking());

  final SocialUseCase _useCase;
  final SocialAvailability _social;

  StreamSubscription<AuthSession?>? _sessionSubscription;
  String? _walkId;
  String? _userId;

  /// 공유 여부를 새로 읽을 때마다(로그인 변화 포함) 는다 — 앞선 읽기 · 보내기의 결과로
  /// 상태를 덮어쓰지 않는다.
  int _epoch = 0;

  Future<void> load(String walkId) async {
    if (!_social.isAvailable) {
      emit(const WalkShareState.hidden());
      return;
    }
    _walkId = walkId;
    _userId = _useCase.currentSession?.userId;
    await _sessionSubscription?.cancel();
    _sessionSubscription = _useCase.sessions.listen(_onSession);
    await _check();
  }

  /// 공유 중이면 공유 취소, 아니면 공유한다. 읽는 중 · 보내는 중이면 [WalkShareOutcome.ignored].
  Future<WalkShareOutcome> toggle() async {
    final current = state;
    final walkId = _walkId;
    if (current is! WalkShareReady || current.busy || walkId == null) {
      return WalkShareOutcome.ignored;
    }
    if (_useCase.currentSession == null) return WalkShareOutcome.signInRequired;

    final share = !current.shared;
    final epoch = _epoch;
    emit(current.copyWith(busy: true));
    final Result<void> result = share
        ? await _useCase.shareWalk(walkId)
        : await _useCase.unshareWalk(walkId);
    if (isClosed) return WalkShareOutcome.ignored;
    // 보내는 사이 로그인이 바뀌었으면 새 사용자의 공유 여부를 다시 읽는 중이다 — 덮어쓰지
    // 않고 결과만 알린다.
    final fresh = epoch == _epoch;

    switch (result) {
      case Ok():
        if (fresh) emit(WalkShareState.ready(shared: share));
        return share ? WalkShareOutcome.shared : WalkShareOutcome.unshared;
      case Err(:final failure):
        if (fresh) emit(current.copyWith(busy: false));
        return failure.failureCode == FailureCode.authenticationRequired
            ? WalkShareOutcome.signInRequired
            : WalkShareOutcome.failed;
    }
  }

  /// 산책을 지우기 전에 공유를 거둔다(가능한 만큼만). 거둘 것이 없거나 거뒀으면 true,
  /// 서버에 못 닿았으면 false — 그래도 산책은 지운다(로컬 우선). 로그인하지 않았거나
  /// Supabase 를 쓸 수 없으면 서버에 묻지 않는다.
  ///
  /// 공유 안 됨을 확인했으면 부르지 않는다. 공유 중이거나 여부를 모르면(읽는 중 · 읽기 실패)
  /// 공유 취소를 보낸다 — 공유하지 않은 산책의 공유 취소도 성공으로 끝난다.
  Future<bool> unshareForDelete() async {
    final walkId = _walkId;
    if (!_social.isAvailable ||
        walkId == null ||
        _useCase.currentSession == null) {
      return true;
    }
    if (state case WalkShareReady(shared: false, busy: false)) return true;
    final result = await _useCase.unshareWalk(walkId);
    return result is Ok;
  }

  /// 읽기가 실패하면 항목을 숨긴다 — 짐작으로 "모두에게 공유" 를 보이지 않는다.
  Future<void> _check() async {
    final walkId = _walkId;
    if (walkId == null) return;
    final epoch = ++_epoch;
    final result = await _useCase.isWalkShared(walkId);
    if (isClosed || epoch != _epoch) return;
    emit(switch (result) {
      Ok(:final value) => WalkShareState.ready(shared: value),
      Err() => const WalkShareState.hidden(),
    });
  }

  void _onSession(AuthSession? session) {
    if (isClosed) return;
    final userId = session?.userId;
    if (userId == _userId) return;
    _userId = userId;
    emit(const WalkShareState.checking());
    unawaited(_check());
  }

  @override
  Future<void> close() async {
    await _sessionSubscription?.cancel();
    return super.close();
  }
}
