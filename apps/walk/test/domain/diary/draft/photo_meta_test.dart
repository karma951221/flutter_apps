import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/draft/photo_meta.dart';

void main() {
  group('takenRange', () {
    test('촬영 시각이 없으면 null', () {
      expect(<PhotoMeta?>[].takenRange, isNull);
      expect([null, const PhotoMeta()].takenRange, isNull);
    });

    test('가장 이른 · 늦은 촬영 시각(순서 무관, 시각 없는 사진은 건너뛴다)', () {
      final range = [
        PhotoMeta(takenAt: DateTime(2026, 11, 15, 15)),
        null,
        const PhotoMeta(),
        PhotoMeta(takenAt: DateTime(2026, 11, 15, 9)),
        PhotoMeta(takenAt: DateTime(2026, 11, 15, 12)),
      ].takenRange;

      expect(range, (
        from: DateTime(2026, 11, 15, 9),
        to: DateTime(2026, 11, 15, 15),
      ));
    });

    test('하나면 둘이 같다', () {
      final at = DateTime(2026, 11, 15, 9);

      expect([PhotoMeta(takenAt: at)].takenRange, (from: at, to: at));
    });
  });

  group('takenFarFromNow', () {
    final now = DateTime(2026, 11, 15, 15);

    test('3시간 넘게 다르면 참(앞 · 뒤 모두)', () {
      expect(
        takenFarFromNow(
          now.subtract(const Duration(hours: 3, minutes: 1)),
          now,
        ),
        isTrue,
      );
      expect(
        takenFarFromNow(now.add(const Duration(hours: 3, minutes: 1)), now),
        isTrue,
      );
    });

    test('3시간까지는 거짓', () {
      expect(
        takenFarFromNow(now.subtract(const Duration(hours: 3)), now),
        isFalse,
      );
      expect(takenFarFromNow(now, now), isFalse);
    });
  });
}
