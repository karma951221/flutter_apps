import 'package:injectable/injectable.dart';

import '../../../../core/data/repository/repository_error_handler.dart';
import '../../../../core/media/image_storage.dart';
import '../../../../core/result/result.dart';
import '../../domain/entity/app_user.dart';
import '../../domain/repository/auth_repository.dart';
import '../datasource/auth_data_source.dart';
import '../mapper/auth_user_mapper.dart';

@LazySingleton(as: AuthRepository)
class SupabaseAuthRepository
    with RepositoryErrorHandler
    implements AuthRepository {
  SupabaseAuthRepository(this._dataSource, this._imageStorage);

  final AuthDataSource _dataSource;

  /// 탈퇴 때 내 Storage 객체를 치우는 데만 쓴다. 버킷 이름이 domain 으로
  /// 새지 않도록 여기(데이터 계층)서 조합한다.
  final ImageStorage _imageStorage;

  // ---------------------------------------------------------------- 상태

  @override
  Stream<AppUser?> authStateChanges() =>
      _dataSource.authStateChanges().map((user) => user?.toEntity());

  @override
  Future<AppUser?> currentUser() async {
    try {
      return (await _dataSource.currentUser())?.toEntity();
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------- 가입 / 로그인

  @override
  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
    required String nickname,
  }) => guard(() async {
    return (await _dataSource.signUp(
      email: email,
      password: password,
      nickname: nickname,
    )).toEntity();
  });

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) => guard(() async {
    return (await _dataSource.signIn(
      email: email,
      password: password,
    )).toEntity();
  });

  @override
  Future<Result<void>> signOut() => guard(_dataSource.signOut);

  @override
  Future<Result<void>> deleteAccount() => guard(() async {
    // 순서가 중요하다. 계정을 먼저 지우면 세션이 사라져 Storage 삭제 정책을
    // 통과할 수 없다. 정리는 best-effort 라 실패해도 탈퇴를 막지 않는다 —
    // DB 함수가 storage.objects 를 지울 수 없는 이유는 마이그레이션 주석에 있다.
    await _imageStorage.removeAllForCurrentUser(bucket: 'avatars');
    await _imageStorage.removeAllForCurrentUser(bucket: 'post-images');
    await _dataSource.deleteAccount();
  });

  @override
  Future<Result<bool>> isNicknameAvailable(String nickname) => guard(() async {
    return _dataSource.isNicknameAvailable(nickname);
  });

  // ---------------------------------------------------------------- 비밀번호 재설정

  @override
  Future<Result<void>> sendPasswordResetCode(String email) =>
      guard(() => _dataSource.sendPasswordResetCode(email));

  @override
  Future<Result<void>> verifyPasswordResetCode({
    required String email,
    required String code,
  }) => guard(
    () => _dataSource.verifyPasswordResetCode(email: email, code: code),
  );

  @override
  Future<Result<void>> updatePassword(String newPassword) => guard(() async {
    await _dataSource.updatePassword(newPassword);
  });

}
