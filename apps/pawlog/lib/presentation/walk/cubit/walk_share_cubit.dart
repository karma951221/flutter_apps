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
@injectable
class WalkShareCubit extends Cubit<WalkShareState> {
  WalkShareCubit(this._useCase, this._social)
    : super(const WalkShareState.checking());

  final SocialUseCase _useCase;
  final SocialAvailability _social;

  StreamSubscription<AuthSession?>? _sessionSubscription;
  String? _walkId;
  String? _userId;

  /// 공유 여부를 새로 읽을 때마다 는다 — 앞선 읽기의 결과는 버린다.
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
    emit(current.copyWith(busy: true));
    final Result<void> result = share
        ? await _useCase.shareWalk(walkId)
        : await _useCase.unshareWalk(walkId);
    if (isClosed) return WalkShareOutcome.ignored;

    switch (result) {
      case Ok():
        emit(WalkShareState.ready(shared: share));
        return share ? WalkShareOutcome.shared : WalkShareOutcome.unshared;
      case Err(:final failure):
        emit(current.copyWith(busy: false));
        return failure.failureCode == FailureCode.authenticationRequired
            ? WalkShareOutcome.signInRequired
            : WalkShareOutcome.failed;
    }
  }

  /// 읽기가 실패하면 공유 안 됨으로 둔다 — 다시 공유해도 서버가 같은 글을 되살린다.
  Future<void> _check() async {
    final walkId = _walkId;
    if (walkId == null) return;
    final epoch = ++_epoch;
    final result = await _useCase.isWalkShared(walkId);
    if (isClosed || epoch != _epoch) return;
    emit(WalkShareState.ready(shared: result is Ok<bool> && result.value));
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
