import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/trash_retention.dart';

void main() {
  final deletedAt = DateTime(2026, 10, 1, 12);
  test('day7: 6일 23:59:59 는 아직', () {
    final now = deletedAt.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );
    expect(TrashRetention.day7.expired(deletedAt, now), isFalse);
  });
  test('day7: 정확히 7일이면 만료', () {
    expect(
      TrashRetention.day7.expired(
        deletedAt,
        deletedAt.add(const Duration(days: 7)),
      ),
      isTrue,
    );
  });
  test('never 는 1000일이 지나도 만료 아님', () {
    expect(
      TrashRetention.never.expired(
        deletedAt,
        deletedAt.add(const Duration(days: 1000)),
      ),
      isFalse,
    );
  });
  test('fallback 은 day7', () {
    expect(TrashRetention.fallback, TrashRetention.day7);
  });
}
