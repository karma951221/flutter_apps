import '../../error/failure.dart';
import '../../result/result.dart';
import '../mapper/supabase_error_mapper.dart';

/// data 저장소의 예외를 [Result] 로 바꾸는 공통 처리 (아키텍처 규칙 ④).
///
/// feature 마다 같은 mixin 을 하나씩 두던 것을 여기로 합쳤다 — 일곱 벌의 본문이
/// 주석을 빼면 완전히 같았고, 여덟 번째였던 `SupabaseAuthRepository._guard` 는
/// `on Failure` 통과가 빠져 있어 이미 동작이 갈라져 있었다 (2026-08-27 리뷰).
/// 변환 규칙이 바뀔 때 고칠 곳이 하나여야 한다.
mixin RepositoryErrorHandler {
  Future<Result<T>> guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Failure catch (failure) {
      // datasource 나 공용 인프라(`ImageStorage`)가 이미 앱 오류로 바꿔 던진
      // 경우다. 다시 매핑하면 `Failure.unknown(toString())` 으로 뭉개진다.
      return Err(failure);
    } catch (error) {
      return Err(SupabaseErrorMapper.map(error));
    }
  }
}
