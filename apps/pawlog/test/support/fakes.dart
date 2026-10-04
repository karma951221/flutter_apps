import 'package:core/core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/domain/dog/entity/dog.dart';
import 'package:pawlog/domain/dog/repository/dog_repository.dart';
import 'package:pawlog/domain/photo/repository/photo_storage.dart';
import 'package:pawlog/domain/tracking/entity/tracking_notice.dart';
import 'package:pawlog/domain/tracking/entity/walk_session.dart';
import 'package:pawlog/domain/tracking/repository/walk_tracker.dart';
import 'package:pawlog/domain/walk/entity/geo_point.dart';
import 'package:pawlog/domain/walk/entity/walk.dart';
import 'package:pawlog/domain/walk/entity/walk_photo.dart';
import 'package:pawlog/domain/walk/entity/walk_track_point.dart';
import 'package:pawlog/domain/walk/repository/walk_repository.dart';

class MockWalkRepository extends Mock implements WalkRepository {}

class MockDogRepository extends Mock implements DogRepository {}

class MockWalkTracker extends Mock implements WalkTracker {}

class MockPhotoStorage extends Mock implements PhotoStorage {}

class MockIdGenerator extends Mock implements IdGenerator {}

/// 시각을 고정하거나(`FakeClock.fixed`) 바깥 함수로 읽는(`FakeClock`, fake_async) 시계.
class FakeClock extends Clock {
  FakeClock(this._now);

  FakeClock.fixed(DateTime value) : this(() => value);

  final DateTime Function() _now;

  @override
  DateTime now() => _now();
}

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
