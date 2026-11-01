import 'dart:async';
import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;

part 'sse_lines.freezed.dart';

/// SSE 이벤트 하나. `event:` 가 없거나 data 가 없는 덩어리는 내지 않는다.
@freezed
class SseEvent with _$SseEvent {
  @override
  final String event;

  /// 여러 `data:` 줄은 '\n' 으로 잇는다. 앞 공백 하나는 뗀다.
  @override
  final String data;

  const SseEvent({required this.event, required this.data});
}

/// UTF-8 → 줄 → 빈 줄마다 이벤트. 줄 사이가 [idleTimeout] 을 넘으면 TimeoutException.
/// 스트림 끝에 남은 덩어리도 낸다. `:` 로 시작하는 주석 줄은 버린다.
Stream<SseEvent> sseEvents(
  Stream<List<int>> bytes, {
  required Duration idleTimeout,
}) async* {
  String? event;
  final data = StringBuffer();
  var hasData = false;

  SseEvent? take() {
    final name = event;
    final payload = data.toString();
    final had = hasData;
    event = null;
    data.clear();
    hasData = false;
    if (name == null || !had) return null;
    return SseEvent(event: name, data: payload);
  }

  final lines = bytes
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .timeout(idleTimeout);

  await for (final line in lines) {
    if (line.isEmpty) {
      final e = take();
      if (e != null) yield e;
    } else if (line.startsWith('event:')) {
      event = line.substring(6).trim();
    } else if (line.startsWith('data:')) {
      if (hasData) data.write('\n');
      var value = line.substring(5);
      if (value.startsWith(' ')) value = value.substring(1);
      data.write(value);
      hasData = true;
    }
  }
  final last = take();
  if (last != null) yield last;
}

/// [abortTrigger] 가 끝나면 요청 · 응답 스트림을 닫는다(package:http AbortableRequest).
///
/// 이미 받은 응답의 바이트 스트림도 닫히며, 그때 [http.RequestAbortedException]
/// (= [http.ClientException]) 이 나올 수 있다.
Future<http.StreamedResponse> abortableSend(
  http.Client client, {
  required String method,
  required Uri url,
  required Map<String, String> headers,
  required String body,
  required Future<void> abortTrigger,
}) {
  final request = http.AbortableRequest(method, url, abortTrigger: abortTrigger)
    ..headers.addAll(headers)
    ..body = body;
  return client.send(request);
}
