import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:walk/data/chat/vendor_error.dart';

http.StreamedResponse _response(String body, [int status = 400]) =>
    http.StreamedResponse(Stream.value(utf8.encode(body)), status);

void main() {
  test('type · code 를 읽고 message 는 버린다', () async {
    final error = await readVendorError(
      _response(
        jsonEncode({
          'error': {
            'type': 'insufficient_quota',
            'code': 'insufficient_quota',
            'message': 'sk-secret 크레딧 없음',
          },
        }),
      ),
    );
    expect(error.type, 'insufficient_quota');
    expect(error.code, 'insufficient_quota');
    expect(error.toString(), isNot(contains('secret')));
  });

  test('type 만 있으면 code 는 null', () async {
    final error = await readVendorError(
      _response(
        jsonEncode({
          'type': 'error',
          'error': {'type': 'billing_error', 'message': 'm'},
        }),
      ),
    );
    expect(error.type, 'billing_error');
    expect(error.code, isNull);
  });

  test('문자열이 아닌 type · code 는 null', () async {
    final error = await readVendorError(
      _response(
        jsonEncode({
          'error': {'type': 3, 'code': null},
        }),
      ),
    );
    expect(error.type, isNull);
    expect(error.code, isNull);
  });

  test('16KB 넘으면 null 둘', () async {
    final error = await readVendorError(
      _response(
        jsonEncode({
          'error': {
            'type': 'insufficient_quota',
            'code': 'insufficient_quota',
            'message': 'x' * (17 * 1024),
          },
        }),
      ),
    );
    expect(error.type, isNull);
    expect(error.code, isNull);
  });

  test('JSON 아니면 null 둘', () async {
    for (final body in ['', 'not json', '[1]', '{"error":"x"}']) {
      final error = await readVendorError(_response(body));
      expect(error.type, isNull, reason: body);
      expect(error.code, isNull, reason: body);
    }
  });

  test('본문이 2초 안에 끝나지 않으면 null 둘', () {
    fakeAsync((async) {
      final bytes = StreamController<List<int>>();
      ({String? type, String? code})? got;
      unawaited(
        readVendorError(
          http.StreamedResponse(bytes.stream, 429),
        ).then((e) => got = e),
      );
      bytes.add(utf8.encode('{"error":{"type":"x","code":"y"}}'));
      async.elapse(const Duration(milliseconds: 1900));
      expect(got, isNull);
      async.elapse(const Duration(milliseconds: 200));
      expect(got, (type: null, code: null));
      bytes.close();
      async.flushMicrotasks();
    });
  });

  test('abort 가 끝나면 읽기를 멈추고 null 둘', () async {
    final bytes = StreamController<List<int>>();
    addTearDown(bytes.close);
    final abort = Completer<void>();
    final future = readVendorError(
      http.StreamedResponse(bytes.stream, 429),
      abort.future,
    );
    bytes.add(utf8.encode('{"error":{"type":"x"'));
    abort.complete();
    expect(await future, (type: null, code: null));
  });

  test('vendorErrorOf 는 디코드된 맵에서 error.type · code 를 꺼낸다', () {
    expect(
      vendorErrorOf({
        'error': {'type': 't', 'code': 'c', 'message': 'm'},
      }),
      (type: 't', code: 'c'),
    );
    expect(vendorErrorOf('x'), (type: null, code: null));
    expect(vendorErrorOf({'code': 'c'}), (type: null, code: null));
  });
}
