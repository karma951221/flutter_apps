import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/commute/subway_line_codes.dart';

void main() {
  test('maps ODsay lane codes to Seoul subway ids', () {
    for (var lane = 1; lane <= 9; lane++) {
      expect(seoulSubwayIdFor(lane), 1000 + lane);
    }
    expect(seoulSubwayIdFor(109), 1077);
    expect(seoulSubwayIdFor(116), 1075);
    expect(seoulSubwayIdFor(104), 1063);
    expect(seoulSubwayIdFor(101), 1065);
    expect(seoulSubwayIdFor(0), isNull);
    expect(seoulSubwayIdFor(10), isNull);
    expect(seoulSubwayIdFor(999), isNull);
  });

  test('normalizeStationName strips trailing 역 and trims', () {
    expect(normalizeStationName('장승배기역'), '장승배기');
    expect(normalizeStationName(' 신논현 '), '신논현');
    expect(normalizeStationName('서울역'), '서울');
    expect(normalizeStationName('역'), '역');
  });
}
