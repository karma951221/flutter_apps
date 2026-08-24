import '../../../../core/data/mapper/supabase_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';

/// comment data 저장소의 예외를 Result 로 변환하는 공통 처리.
mixin CommentRepositoryErrorHandler {
  Future<Result<T>> guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Failure catch (failure) {
      return Err(failure);
    } catch (error) {
      return Err(SupabaseErrorMapper.map(error));
    }
  }
}
