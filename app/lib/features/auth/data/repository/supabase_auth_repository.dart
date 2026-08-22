import 'package:injectable/injectable.dart';

import '../../../../core/data/mapper/supabase_error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entity/app_user.dart';
import '../../domain/repository/auth_repository.dart';
import '../datasource/auth_data_source.dart';
import '../mapper/auth_user_mapper.dart';

@LazySingleton(as: AuthRepository)
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._dataSource);

  final AuthDataSource _dataSource;

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
  }) => _guard(() async {
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
  }) => _guard(() async {
    return (await _dataSource.signIn(
      email: email,
      password: password,
    )).toEntity();
  });

  @override
  Future<Result<void>> signOut() => _guard(_dataSource.signOut);

  @override
  Future<Result<bool>> isNicknameAvailable(String nickname) => _guard(() async {
    return _dataSource.isNicknameAvailable(nickname);
  });

  // ---------------------------------------------------------------- 비밀번호 재설정

  @override
  Future<Result<void>> sendPasswordResetCode(String email) =>
      _guard(() => _dataSource.sendPasswordResetCode(email));

  @override
  Future<Result<void>> verifyPasswordResetCode({
    required String email,
    required String code,
  }) => _guard(
    () => _dataSource.verifyPasswordResetCode(email: email, code: code),
  );

  @override
  Future<Result<void>> updatePassword(String newPassword) => _guard(() async {
    await _dataSource.updatePassword(newPassword);
  });

  // ---------------------------------------------------------------- 공통

  /// 예외를 Failure 로 바꿔 Result 에 담는다.
  /// 이 래퍼 덕분에 각 메서드가 try/catch 로 지저분해지지 않는다.
  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } catch (e) {
      return Err(SupabaseErrorMapper.map(e));
    }
  }
}
