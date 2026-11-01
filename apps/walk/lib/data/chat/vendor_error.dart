import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// 벤더 오류 본문에서 꺼낸 두 값. message 등 나머지는 담지 않는다.
typedef VendorError = ({String? type, String? code});

const VendorError _none = (type: null, code: null);

/// 오류 본문을 읽는 상한. 넘으면 읽지 않고 상태 코드로만 판정하게 한다.
const vendorErrorBodyLimit = 16 * 1024;
const vendorErrorBodyTimeout = Duration(seconds: 2);

/// 오류 응답 본문에서 `error.type` · `error.code` 만 꺼낸다(Anthropic · OpenAI 공통).
///
/// [vendorErrorBodyLimit] 을 넘거나 [vendorErrorBodyTimeout] 안에 끝나지 않거나
/// JSON 이 아니면 둘 다 null. [abort] 가 끝나면 읽기를 멈춘다. 던지지 않는다.
Future<VendorError> readVendorError(
  http.StreamedResponse response, [
  Future<void>? abort,
]) async {
  final buffer = BytesBuilder(copy: false);
  final done = Completer<bool>();
  void finish(bool complete) {
    if (!done.isCompleted) done.complete(complete);
  }

  late final StreamSubscription<List<int>> sub;
  sub = response.stream.listen(
    (chunk) {
      buffer.add(chunk);
      if (buffer.length > vendorErrorBodyLimit) {
        // 더 받지 않는다 — 넘친 본문은 바로 끊는다.
        unawaited(sub.cancel().catchError((_) {}));
        finish(false);
      }
    },
    onError: (Object _) => finish(false),
    onDone: () => finish(true),
    cancelOnError: true,
  );
  unawaited(abort?.whenComplete(() => finish(false)));
  final complete = await done.future.timeout(
    vendorErrorBodyTimeout,
    onTimeout: () => false,
  );
  unawaited(sub.cancel().catchError((_) {}));
  if (!complete) return _none;
  try {
    return vendorErrorOf(jsonDecode(utf8.decode(buffer.takeBytes())));
  } on FormatException {
    // JSON 이 아니다(UTF-8 이 아닌 것 포함) — 상태 코드로 판정한다.
    return _none;
  }
}

/// 디코드된 `{error: {type, code}}` 에서 두 값을 꺼낸다. String 이 아니면 null.
VendorError vendorErrorOf(Object? json) {
  if (json case {'error': final Map<Object?, Object?> error}) {
    return (
      type: switch (error['type']) {
        final String type => type,
        _ => null,
      },
      code: switch (error['code']) {
        final String code => code,
        _ => null,
      },
    );
  }
  return _none;
}
