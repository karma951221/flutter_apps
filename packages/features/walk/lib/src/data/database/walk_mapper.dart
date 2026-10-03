import 'package:drift/drift.dart';

import '../../domain/entity/dog.dart';
import '../../domain/entity/geo_point.dart';
import '../../domain/entity/walk.dart';
import '../../domain/entity/walk_photo.dart';
import '../../domain/entity/walk_track_point.dart';
import '../../domain/policy/route_preview.dart';
import 'walk_database.dart';

/// 조인 한 행. 왼쪽 조인이라 [dog] · [photo] 는 없을 수 있다.
typedef WalkJoinRow = ({WalkRow walk, DogRow? dog, WalkPhotoRow? photo});

String _formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

Dog dogFromRow(DogRow row) => Dog(
  id: row.id,
  name: row.name,
  breed: row.breed,
  birthday: row.birthday == null ? null : DateTime.parse(row.birthday!),
  photoPath: row.photoPath,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
);

DogsCompanion dogToCompanion(Dog dog) => DogsCompanion.insert(
  id: dog.id,
  name: dog.name,
  breed: Value(dog.breed),
  birthday: Value(dog.birthday == null ? null : _formatDate(dog.birthday!)),
  photoPath: Value(dog.photoPath),
  createdAt: dog.createdAt,
  updatedAt: dog.updatedAt,
);

WalkTrackPoint trackPointFromRow(WalkPointRow row) => WalkTrackPoint(
  point: GeoPoint(lat: row.lat, lng: row.lng),
  recordedAt: row.recordedAt,
  accuracy: row.accuracy,
);

WalkPointsCompanion trackPointToCompanion(
  String walkId,
  int seq,
  WalkTrackPoint point,
) => WalkPointsCompanion.insert(
  walkId: walkId,
  seq: seq,
  lat: point.point.lat,
  lng: point.point.lng,
  recordedAt: point.recordedAt,
  accuracy: Value(point.accuracy),
);

WalksCompanion walkToCompanion(Walk walk) => WalksCompanion.insert(
  id: walk.id,
  startedAt: walk.startedAt,
  endedAt: walk.endedAt,
  durationSeconds: walk.duration.inSeconds,
  distanceMeters: walk.distanceMeters,
  memo: Value(walk.memo),
  routePreview: Value(RoutePreview.encode(walk.previewPoints)),
  createdAt: walk.createdAt,
  updatedAt: walk.updatedAt,
);

WalkPhotosCompanion photoToCompanion(
  String walkId,
  WalkPhoto photo,
  DateTime createdAt,
) => WalkPhotosCompanion.insert(
  id: photo.id,
  walkId: walkId,
  path: photo.path,
  position: photo.position,
  createdAt: createdAt,
);

/// 곱으로 늘어난 조인 행을 산책별로 묶는다. 입력 순서(= 쿼리의 정렬)를 지키고,
/// 반려견은 이름순, 사진은 position 순으로 정렬하며 id 로 중복을 없앤다.
List<Walk> walksFromJoinRows(Iterable<WalkJoinRow> rows) {
  final walks = <String, WalkRow>{};
  final dogs = <String, Map<String, DogRow>>{};
  final photos = <String, Map<String, WalkPhotoRow>>{};

  for (final row in rows) {
    final id = row.walk.id;
    walks.putIfAbsent(id, () => row.walk);
    final dogMap = dogs.putIfAbsent(id, () => {});
    final photoMap = photos.putIfAbsent(id, () => {});
    final dog = row.dog;
    if (dog != null) dogMap[dog.id] = dog;
    final photo = row.photo;
    if (photo != null) photoMap[photo.id] = photo;
  }

  return [
    for (final entry in walks.entries)
      Walk(
        id: entry.key,
        startedAt: entry.value.startedAt,
        endedAt: entry.value.endedAt,
        duration: Duration(seconds: entry.value.durationSeconds),
        distanceMeters: entry.value.distanceMeters,
        memo: entry.value.memo,
        dogs: [
          for (final d
              in dogs[entry.key]!.values.toList()
                ..sort((a, b) => a.name.compareTo(b.name)))
            dogFromRow(d),
        ],
        photos: [
          for (final p
              in photos[entry.key]!.values.toList()
                ..sort((a, b) => a.position.compareTo(b.position)))
            WalkPhoto(id: p.id, path: p.path, position: p.position),
        ],
        previewPoints: RoutePreview.decode(entry.value.routePreview),
        createdAt: entry.value.createdAt,
        updatedAt: entry.value.updatedAt,
      ),
  ];
}
