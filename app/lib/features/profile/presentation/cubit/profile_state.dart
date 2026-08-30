import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entity/profile.dart';
import 'nickname_check.dart';

part 'profile_state.freezed.dart';

@freezed
class ProfileState with _$ProfileState {
  @override
  final Profile? profile;
  @override
  final Failure? failure;
  @override
  final bool isLoading;
  @override
  final bool isSaving;
  @override
  final NicknameCheck nicknameCheck;

  const ProfileState({
    this.profile,
    this.failure,
    this.isLoading = false,
    this.isSaving = false,
    this.nicknameCheck = const NicknameCheck.idle(),
  });
}
