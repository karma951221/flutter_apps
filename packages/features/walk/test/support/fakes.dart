import 'package:core/core.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:mocktail/mocktail.dart';

class MockWalkRepository extends Mock implements WalkRepository {}

class MockDogRepository extends Mock implements DogRepository {}

class MockWalkTracker extends Mock implements WalkTracker {}

class MockPhotoStorage extends Mock implements PhotoStorage {}

class MockIdGenerator extends Mock implements IdGenerator {}

final t0 = DateTime(2026, 10, 3, 9);
final t1 = DateTime(2026, 10, 3, 9, 30);

Dog dog(String id, {String? photoPath}) => Dog(
  id: id,
  name: '콩이$id',
  photoPath: photoPath,
  createdAt: t0,
  updatedAt: t0,
);

WalkTrackPoint trackPoint(double lat, {double? accuracy}) => WalkTrackPoint(
  point: GeoPoint(lat: lat, lng: 127),
  recordedAt: t0,
  accuracy: accuracy,
);

Walk walk({List<Dog>? dogs, List<WalkPhoto> photos = const []}) => Walk(
  id: 'w1',
  startedAt: t0,
  endedAt: t1,
  duration: const Duration(minutes: 30),
  distanceMeters: 1200,
  dogs: dogs ?? [dog('d1')],
  photos: photos,
  previewPoints: const [],
  createdAt: t0,
  updatedAt: t0,
);

void registerFallbacks() {
  registerFallbackValue(walk());
  registerFallbackValue(dog('fb'));
  registerFallbackValue(const TrackingNotice(title: '', text: ''));
}

WalkSession walkSession({
  List<WalkTrackPoint>? points,
  double distanceMeters = 0,
  DateTime? endedAt,
}) => WalkSession(
  dogIds: const ['d1'],
  startedAt: t0,
  endedAt: endedAt,
  points: points ?? const [],
  distanceMeters: distanceMeters,
);
