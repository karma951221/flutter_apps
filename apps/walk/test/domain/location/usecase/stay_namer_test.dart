import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/location/place_lookup.dart';
import 'package:walk/domain/diary/location/place_source.dart';
import 'package:walk/domain/location/repository/location_repository.dart';
import 'package:walk/domain/location/usecase/stay_namer.dart';

class _MockRepo extends Mock implements LocationRepository {}

class _MockNamer extends Mock implements PlaceNamer {}

void main() {
  late _MockRepo repo;
  late _MockNamer namer;
  late StayNamer stayNamer;

  setUp(() {
    repo = _MockRepo();
    namer = _MockNamer();
    stayNamer = StayNamer(repo, namer);
    when(() => repo.placeName(any())).thenAnswer((_) async => null);
    when(() => repo.savePlaceName(any(), any())).thenAnswer((_) async {});
  });

  test('cache hit does not call PlaceNamer', () async {
    when(() => repo.placeName('37.500,127.000')).thenAnswer((_) async => '집');
    expect(await stayNamer.nameFor(37.5001, 127.0001), '집');
    verifyNever(() => namer.nameFor(any(), any()));
  });

  test('named result is saved under the grid key', () async {
    when(
      () => namer.nameFor(37.5001, 127.0001),
    ).thenAnswer((_) async => const PlaceLookup.named('회사'));
    expect(await stayNamer.nameFor(37.5001, 127.0001), '회사');
    verify(() => repo.savePlaceName('37.500,127.000', '회사')).called(1);
  });

  test('offline returns null and saves nothing', () async {
    when(
      () => namer.nameFor(any(), any()),
    ).thenAnswer((_) async => const PlaceLookup.offline());
    expect(await stayNamer.nameFor(37.5, 127.0), isNull);
    verifyNever(() => repo.savePlaceName(any(), any()));
  });

  test('noName returns null and saves nothing', () async {
    when(
      () => namer.nameFor(any(), any()),
    ).thenAnswer((_) async => const PlaceLookup.noName());
    expect(await stayNamer.nameFor(37.5, 127.0), isNull);
    verifyNever(() => repo.savePlaceName(any(), any()));
  });
}
