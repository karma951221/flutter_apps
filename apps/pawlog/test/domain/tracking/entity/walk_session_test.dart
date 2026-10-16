import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  DateTime at(int h, int m) => DateTime(2026, 10, 3, h, m);

  test('멈춤 없음: 시작부터 now 까지', () {
    expect(walkSession().elapsedAt(at(9, 30)), const Duration(minutes: 30));
  });

  test('지난 멈춤 합을 뺀다', () {
    final s = walkSession(pausedDuration: const Duration(minutes: 5));
    expect(s.elapsedAt(at(9, 30)), const Duration(minutes: 25));
  });

  test('지금 멈춤 중이면 멈춘 시각에서 시간이 멈춘다', () {
    final s = walkSession(
      pausedDuration: const Duration(minutes: 5),
      pausedAt: at(9, 20),
    );
    expect(s.elapsedAt(at(9, 30)), const Duration(minutes: 15));
    expect(s.elapsedAt(at(9, 40)), const Duration(minutes: 15));
  });

  test('끝난 세션은 now 와 무관하다', () {
    final s = walkSession(
      endedAt: at(9, 30),
      pausedDuration: const Duration(minutes: 5),
    );
    expect(s.elapsedAt(at(12, 0)), const Duration(minutes: 25));
  });

  test('끝났는데 pausedAt 이 남아 있으면 끝 시각까지 멈춘 것으로 센다', () {
    final s = walkSession(endedAt: at(9, 30), pausedAt: at(9, 25));
    expect(s.elapsedAt(at(12, 0)), const Duration(minutes: 25));
  });

  test('합이 전체보다 크면 0', () {
    final s = walkSession(pausedDuration: const Duration(hours: 2));
    expect(s.elapsedAt(at(9, 30)), Duration.zero);
  });

  test('isPaused 는 pausedAt != null', () {
    expect(walkSession().isPaused, isFalse);
    expect(walkSession(pausedAt: t0).isPaused, isTrue);
  });
}
