import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/validation/nickname_check.dart';
import '../../../../core/validation/validators.dart';
import '../../domain/entity/avatar_image_draft.dart';
import '../../domain/entity/profile_update.dart';
import '../../domain/usecase/profile_use_case.dart';
import 'profile_state.dart';

@injectable
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._useCase) : super(const ProfileState());

  final ProfileUseCase _useCase;

  Timer? _nicknameDebounce;

  /// 늦게 도착한 옛 응답이 새 결과를 덮어쓰지 않게 하는 표식.
  int _nicknameRequest = 0;

  Future<void> load({String? userId}) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, failure: null));

    final result = userId == null
        ? await _useCase.getMyProfile()
        : await _useCase.getProfile(userId);
    // 조회 중에 화면을 떠나면 cubit 이 먼저 닫힌다. 늦게 온 결과로 emit 하면
    // bloc 이 예외를 던지므로 여기서 접는다.
    if (isClosed) return;

    emit(
      result.when(
        ok: (profile) =>
            state.copyWith(profile: profile, isLoading: false, failure: null),
        err: (failure) => state.copyWith(isLoading: false, failure: failure),
      ),
    );
  }

  /// 닉네임 입력이 바뀔 때마다 부른다.
  ///
  /// 형식이 어긋난 값과 지금 쓰고 있는 닉네임은 조회하지 않는다 — 앞은 폼 검증이
  /// 이미 말해주고, 뒤는 자기 자신이라 언제나 중복으로 나온다.
  void checkNickname(String nickname) {
    _nicknameDebounce?.cancel();
    _nicknameRequest++;

    final trimmed = nickname.trim();
    if (Validators.nickname(trimmed) != null ||
        trimmed == state.profile?.nickname) {
      emit(state.copyWith(nicknameCheck: const NicknameCheck.idle()));
      return;
    }

    emit(state.copyWith(nicknameCheck: const NicknameCheck.checking()));
    _nicknameDebounce = Timer(
      nicknameCheckDebounce,
      () => _runNicknameCheck(trimmed, _nicknameRequest),
    );
  }

  Future<void> _runNicknameCheck(String nickname, int request) async {
    final result = await _useCase.isNicknameAvailable(nickname);
    if (isClosed || request != _nicknameRequest) return;

    emit(
      state.copyWith(
        nicknameCheck: result.when(
          ok: (available) => available
              ? const NicknameCheck.available()
              : const NicknameCheck.taken(),
          // 확인에 실패하면 조용히 접는다. 저장할 때 DB 가 최종 판정을 한다.
          err: (_) => const NicknameCheck.idle(),
        ),
      ),
    );
  }

  /// 프로필을 저장한다.
  ///
  /// [newAvatar] 가 있으면 업로드·정리까지 usecase 한 번으로 끝난다. 화면은
  /// 순서를 알지 않는다.
  Future<void> save(ProfileUpdate update, {AvatarImageDraft? newAvatar}) async {
    if (state.isSaving) return;
    emit(state.copyWith(isSaving: true, failure: null));

    final result = await _useCase.updateMyProfile(update, newAvatar: newAvatar);
    // 저장 도중 화면이 사라졌을 수 있다. 닫힌 뒤의 emit 은 예외가 된다.
    if (isClosed) return;

    emit(
      result.when(
        ok: (profile) => state.copyWith(
          profile: profile,
          isSaving: false,
          failure: null,
          nicknameCheck: const NicknameCheck.idle(),
        ),
        err: (failure) => state.copyWith(isSaving: false, failure: failure),
      ),
    );
  }

  @override
  Future<void> close() {
    _nicknameDebounce?.cancel();
    return super.close();
  }
}
