import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/draft/photo_meta.dart';

void main() {
  group('takenRange', () {
    test('촬영 시각이 없으면 null', () {
      expect(<PhotoMeta?>[].takenRange, isNull);
      expect([null, const PhotoMeta(lat: 37.5, lng: 127.0)].takenRange, isNull);
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

  test('toString 에 좌표를 찍지 않는다', () {
    const meta = PhotoMeta(lat: 37.54321, lng: 127.04567);

    expect(meta.toString(), isNot(contains('37.54321')));
    expect(meta.toString(), isNot(contains('127.04567')));
  });

  test('hasLocation 은 위도 · 경도가 둘 다 있을 때만', () {
    expect(const PhotoMeta(lat: 1, lng: 2).hasLocation, isTrue);
    expect(const PhotoMeta(lat: 1).hasLocation, isFalse);
    expect(const PhotoMeta().hasLocation, isFalse);
  });
}
