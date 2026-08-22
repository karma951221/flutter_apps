import '../error/failure.dart';

/// 성공 또는 실패를 담는 반환 타입.
///
/// Repository 는 예외를 던지지 않고 이 타입을 돌려준다.
/// 호출부가 실패 처리를 빠뜨릴 수 없게 만드는 것이 목적이다.
sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) => switch (this) {
    Ok<T>(:final value) => ok(value),
    Err<T>(:final failure) => err(failure),
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
