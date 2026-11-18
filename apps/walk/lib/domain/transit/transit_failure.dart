import 'package:freezed_annotation/freezed_annotation.dart';

part 'transit_failure.freezed.dart';

/// 길찾기가 실패한 이유. 화면은 종류로 문구를 고르고, [TransitFailureDetail.detail]
/// 로 원인 원문(예외 타입 · HTTP 상태 · ODsay code · msg)을 함께 보인다.
/// 상세에는 키 값이 들어가지 않는다 — 만드는 쪽이 [maskTransitKey] 를 거친다.
@freezed
sealed class TransitFailure with _$TransitFailure implements Exception {
  const factory TransitFailure.missingKey() = TransitMissingKey;

  /// [message] 는 ODsay 가 보낸 `code · msg` 원문.
  const factory TransitFailure.keyRejected(String message) = TransitKeyRejected;
  const factory TransitFailure.quotaExceeded([@Default('') String detail]) =
      TransitQuotaExceeded;

  /// [detail] 은 예외 타입과 메시지(예: `SocketException: Failed host lookup`).
  const factory TransitFailure.network([@Default('') String detail]) =
      TransitNetwork;
  const factory TransitFailure.noRoute() = TransitNoRoute;
  const factory TransitFailure.tooClose() = TransitTooClose;

  /// [message] 는 HTTP 상태와 ODsay code · msg 원문.
  const factory TransitFailure.server(String message) = TransitServer;

  /// 그 밖의 예외(저장소 실패 등). [detail] 은 `runtimeType: message`.
  const factory TransitFailure.unexpected(String detail) = TransitUnexpected;
}

extension TransitFailureDetail on TransitFailure {
  /// 원인 원문. 없으면 빈 문자열.
  String get detail => switch (this) {
    TransitMissingKey() || TransitNoRoute() || TransitTooClose() => '',
    TransitKeyRejected(:final message) => message,
    TransitQuotaExceeded(:final detail) => detail,
    TransitNetwork(:final detail) => detail,
    TransitServer(:final message) => message,
    TransitUnexpected(:final detail) => detail,
  };
}

/// [error] 를 `타입: 메시지` 로 적는다. toString 이 이미 타입으로 시작하면 한 번만.
String describeError(Object error) {
  final type = '${error.runtimeType}';
  final text = '$error';
  return text.startsWith(type) ? text : '$type: $text';
}

const _minRawKeyLength = 6;

final _apiKeyQuery = RegExp(r'(apiKey=)[^&\s"#]*', caseSensitive: false);

/// [text] 에서 `apiKey=` 쿼리 값과 [key] 원문 · URL 인코딩 모양을 `••••` 로 가린다.
/// 원문 치환은 [key] 가 [_minRawKeyLength] 글자 이상일 때만 — 짧은 값은 키일 리 없고
/// 평범한 글자까지 가려 원인을 읽을 수 없게 된다.
String maskTransitKey(String text, {String? key}) {
  var masked = text.replaceAllMapped(_apiKeyQuery, (m) => '${m[1]}••••');
  if (key != null && key.length >= _minRawKeyLength) {
    masked = masked
        .replaceAll(key, '••••')
        .replaceAll(Uri.encodeComponent(key), '••••')
        .replaceAll(Uri.encodeQueryComponent(key), '••••');
  }
  return masked;
}
