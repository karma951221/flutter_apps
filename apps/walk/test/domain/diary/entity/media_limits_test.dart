import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/media_limits.dart';

void main() {
  test('canAdd 는 합이 10 이하일 때만 true', () {
    expect(MediaLimits.canAdd(9, 1), isTrue);
    expect(MediaLimits.canAdd(10, 1), isFalse);
    expect(MediaLimits.canAdd(3, 8), isFalse);
  });
  test('videoAllowed 는 30초까지', () {
    expect(MediaLimits.videoAllowed(const Duration(seconds: 30)), isTrue);
    expect(
      MediaLimits.videoAllowed(const Duration(milliseconds: 30001)),
      isFalse,
    );
  });
  test('상수', () {
    expect(MediaLimits.photoLongEdge, 1600);
    expect(MediaLimits.photoQuality, 85);
  });
}
