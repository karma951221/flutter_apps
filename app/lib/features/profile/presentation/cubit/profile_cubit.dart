import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/profile_update.dart';
import '../../domain/usecase/profile_use_case.dart';
import 'profile_state.dart';

@injectable
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._useCase) : super(const ProfileState());

  final ProfileUseCase _useCase;

  Future<void> load({String? userId}) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, failure: null));

    final result = userId == null
        ? await _useCase.getMyProfile()
        : await _useCase.getProfile(userId);
    emit(
      result.when(
        ok: (profile) =>
            state.copyWith(profile: profile, isLoading: false, failure: null),
        err: (failure) => state.copyWith(isLoading: false, failure: failure),
      ),
    );
  }

  Future<void> save(ProfileUpdate update) async {
    if (state.isSaving) return;
    emit(state.copyWith(isSaving: true, failure: null));

    final result = await _useCase.updateMyProfile(update);
    emit(
      result.when(
        ok: (profile) =>
            state.copyWith(profile: profile, isSaving: false, failure: null),
        err: (failure) => state.copyWith(isSaving: false, failure: failure),
      ),
    );
  }
}
