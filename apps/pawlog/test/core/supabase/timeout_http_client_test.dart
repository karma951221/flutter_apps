import 'dart:async';

import 'package:core/core.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pawlog/core/supabase/timeout_http_client.dart';

/// 응답을 [respond] 로 정하는 안쪽 클라이언트. 닫혔는지 적는다.
class _Inner extends http.BaseClient {
  _Inner(this.respond);

  final Future<http.StreamedResponse> Function() respond;
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => respond();

  @override
  void close() => closed = true;
}

http.Request _request() =>
    http.Request('GET', Uri.parse('http://127.0.0.1:54321/rest/v1/x'));

void main() {
  test('안쪽 클라이언트가 끝나지 않으면 시간 제한 뒤 TimeoutException 을 던진다', () {
    fakeAsync((async) {
      final client = TimeoutHttpClient(
        _Inner(() => Completer<http.StreamedResponse>().future),
        const Duration(seconds: 10),
      );
      Object? error;
      client.send(_request()).catchError((Object e) {
        error = e;
        return http.StreamedResponse(const Stream.empty(), 599);
      });

      async.elapse(const Duration(seconds: 9));
      expect(error, isNull);
      async.elapse(const Duration(seconds: 1));
      expect(error, isA<TimeoutException>());
    });
  });

  test('빠른 응답은 그대로 돌려준다', () async {
    final client = TimeoutHttpClient(
      _Inner(() async => http.StreamedResponse(Stream.value([111, 107]), 200)),
      const Duration(seconds: 10),
    );

    final response = await http.Response.fromStream(
      await client.send(_request()),
    );

    expect(response.statusCode, 200);
    expect(response.body, 'ok');
  });

  test('close 를 안쪽 클라이언트에 넘긴다', () {
    final inner = _Inner(() => Completer<http.StreamedResponse>().future);

    TimeoutHttpClient(inner, const Duration(seconds: 1)).close();

    expect(inner.closed, isTrue);
  });

  test('TimeoutException 은 core 오류 처리에서 네트워크 실패가 된다', () async {
    final result = await _Guard().guard<void>(
      () => Future.error(TimeoutException('slow')),
    );

    expect(switch (result) {
      Err(:final failure) => failure.failureCode,
      Ok() => null,
    }, FailureCode.networkUnavailable);
  });
}

class _Guard with RepositoryErrorHandler {}
