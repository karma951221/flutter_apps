import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../../domain/entity/avatar_image_draft.dart';
import '../../domain/entity/profile.dart';
import '../../domain/entity/profile_update.dart';
import '../../domain/repository/profile_repository.dart';
import '../datasource/profile_data_source.dart';
import '../mapper/profile_mapper.dart';
import 'profile_repository_error_handler.dart';

/// ProfileDataSource를 domain Repository 계약으로 변환하는 구현체.
///
/// Supabase 의존성은 data source에서 끝난다. 이 클래스는 특정 백엔드 기술을 알지
/// 않으므로 이름에도 구현 기술을 드러내지 않는다.
@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl
    with ProfileRepositoryErrorHandler
    implements ProfileRepository {
  ProfileRepositoryImpl(this._dataSource);

  final ProfileDataSource _dataSource;

  @override
  Future<Result<Profile>> getProfile(String userId) => guard(() async {
    return (await _dataSource.getProfile(userId)).toEntity();
  });

  @override
  Future<Result<Profile>> getMyProfile() {
    return guard(() async {
      final profile = await _dataSource.getMyProfile();
      return profile?.toEntity() ?? _throwNotAuthenticated();
    });
  }

  @override
  Future<Result<Profile>> updateMyProfile(ProfileUpdate update) {
    return guard(() async {
      final profile = await _dataSource.updateMyProfile(update);
      return profile?.toEntity() ?? _throwNotAuthenticated();
    });
  }

  @override
  Future<Result<bool>> isNicknameAvailable(String nickname) => guard(() async {
    return _dataSource.isNicknameAvailable(nickname);
  });

  @override
  Future<Result<String>> uploadAvatar(AvatarImageDraft image) =>
      guard(() => _dataSource.uploadAvatar(image));

  @override
  Future<void> removeAvatar(String? publicUrl) =>
      _dataSource.removeAvatar(publicUrl);

  Never _throwNotAuthenticated() => throw const Failure.auth(
    message: '로그인이 필요합니다',
    code: 'not_authenticated',
  );
}
