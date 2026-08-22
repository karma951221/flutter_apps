import '../../../../core/data/mapper/supabase_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';

/// profile data 저장소의 예외를 Result로 변환하는 공통 처리.
///
/// profile feature 안에서만 쓰므로 core가 아니라 repository 가까이에 둔다.
mixin ProfileRepositoryErrorHandler {
  Future<Result<T>> guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Failure catch (failure) {
      // data source가 이미 앱 오류로 변환한 경우에는 그대로 전달한다.
      return Err(failure);
    } catch (error) {
      return Err(SupabaseErrorMapper.map(error));
    }
  }
}
