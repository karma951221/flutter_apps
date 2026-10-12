import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';

void main() {
  test('run 동안만 active 이고 결과를 돌려준다', () async {
    final guard = MediaPickGuard();
    final pick = Completer<String>();

    expect(guard.active, isFalse);
    final result = guard.run(() => pick.future);
    expect(guard.active, isTrue);

    pick.complete('photo');
    expect(await result, 'photo');
    expect(guard.active, isFalse);
  });

  test('겹쳐 부르면 마지막 것이 끝날 때까지 active', () async {
    final guard = MediaPickGuard();
    final first = Completer<void>();
    final second = Completer<void>();

    final a = guard.run(() => first.future);
    final b = guard.run(() => second.future);
    first.complete();
    await a;
    expect(guard.active, isTrue);

    second.complete();
    await b;
    expect(guard.active, isFalse);
  });

  test('pick 이 던져도 active 를 풀고 예외를 그대로 던진다', () async {
    final guard = MediaPickGuard();

    await expectLater(
      guard.run<void>(() async => throw StateError('x')),
      throwsStateError,
    );
    expect(guard.active, isFalse);
  });
}
