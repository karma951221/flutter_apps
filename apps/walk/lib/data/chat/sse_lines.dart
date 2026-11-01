import 'dart:async';
import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;

import '../../domain/chat/chat_trace.dart';

part 'sse_lines.freezed.dart';

/// SSE 이벤트 하나. `event:` 가 없거나 data 가 없는 덩어리는 내지 않는다.
/// toString 에 payload 를 남기지 않는다.
@Freezed(toStringOverride: false)
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
///
/// [typeFallback] 이면 `event:` 줄이 없는 덩어리의 이름을 data JSON 의 `type`
/// (String)으로 삼는다(OpenAI Responses). 그것도 없으면 내지 않는다.
Stream<SseEvent> sseEvents(
  Stream<List<int>> bytes, {
  required Duration idleTimeout,
  bool typeFallback = false,
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
    if (!had) return null;
    final resolved = name ?? (typeFallback ? _typeOf(payload) : null);
    if (resolved == null) return null;
    return SseEvent(event: resolved, data: payload);
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

/// data JSON 의 최상위 `type`. JSON 이 아니거나 String 이 아니면 null.
String? _typeOf(String payload) {
  try {
    if (jsonDecode(payload) case {'type': final String type}) return type;
  } on FormatException {
    // 이름을 정할 수 없다 — 버린다.
  }
  return null;
}

/// [abort] 가 끝나면 바이트 구독을 끊고 스트림을 닫는다. `async*` 는 `await for`
/// 로 다음 바이트를 기다리는 동안 취소를 알아채지 못하므로, 클라이언트가
/// abortTrigger 를 따르지 않아도 여기서 끊는다.
Stream<List<int>> untilAbort(Stream<List<int>> bytes, Future<void> abort) {
  StreamSubscription<List<int>>? sub;
  late final StreamController<List<int>> out;
  out = StreamController<List<int>>(
    sync: true,
    onListen: () {
      sub = bytes.listen(out.add, onError: out.addError, onDone: out.close);
      unawaited(
        abort.whenComplete(() {
          if (out.isClosed) return;
          sub?.cancel().ignore();
          unawaited(out.close());
        }),
      );
    },
    onPause: () => sub?.pause(),
    onResume: () => sub?.resume(),
    onCancel: () => sub?.cancel(),
  );
  return out.stream;
}

/// 어댑터 `stream()` 의 취소 계약을 한 곳에서 지킨다.
///
/// [run] 은 요청 하나를 돌리는 스트림이고 받은 [Completer] 를 끝내면 HTTP 요청 ·
/// 응답이 닫혀야 한다(abortTrigger). 구독을 끊으면 아직 끝나지 않은 요청을 abort
/// 하고 [trace] 에 `abort` 를 찍으며, 그 뒤 이벤트 · 오류를 내지 않는다. 정상 ·
/// 오류 종료 뒤의 취소는 abort 가 아니다. [run] 이 시간 초과 등으로 직접 끝내도
/// 된다(이미 끝났으면 다시 끝내지 않는다).
///
/// `async*` 의 `finally` 에서 abort 하지 않는 까닭 — `async*` 는 취소돼도 `send`
/// 를 기다리는 동안 `finally` 에 닿지 않는다.
Stream<T> abortableStream<T>(
  Stream<T> Function(Completer<void> abort) run, {
  required ChatTrace trace,
}) {
  final abort = Completer<void>();
  var cancelled = false;
  var settled = false;
  StreamSubscription<T>? inner;
  late final StreamController<T> out;
  out = StreamController<T>(
    onListen: () => inner = run(abort).listen(
      (e) {
        if (!cancelled) out.add(e);
      },
      onError: (Object e, StackTrace s) {
        // run 의 오류는 마지막이다 — 요청은 이미 끝났다.
        settled = true;
        if (!cancelled) out.addError(e, s);
      },
      onDone: () {
        settled = true;
        if (!cancelled) unawaited(out.close());
      },
    ),
    onCancel: () {
      cancelled = true;
      if (!settled && !abort.isCompleted) {
        abort.complete();
        if (trace.enabled) trace.mark(ChatTraceMark.abort);
      }
      // 기다리지 않는다 — 구독자 cancel 이 묶이지 않게. 취소 뒤 run 이 던지는
      // 오류(RequestAbortedException 등)는 버린다.
      inner?.cancel().ignore();
    },
  );
  return out.stream;
}
