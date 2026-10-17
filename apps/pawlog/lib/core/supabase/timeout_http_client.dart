import 'dart:async';

import 'package:http/http.dart' as http;

/// 모든 요청에 시간 제한을 거는 http 클라이언트.
///
/// supabase 클라이언트는 기본으로 시간 제한이 없다. 서버가 응답 없이 멈추면(에뮬레이터 QA 에서
/// API 컨테이너를 멈췄을 때) 모두의 산책이 끝없이 돈다. 제한을 넘으면 [TimeoutException] 을
/// 던지고, core `SupabaseErrorMapper` 가 네트워크 실패로 바꾼다.
class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient(this._inner, this.timeout);

  final http.Client _inner;
  final Duration timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request).timeout(timeout);

  @override
  void close() => _inner.close();
}
