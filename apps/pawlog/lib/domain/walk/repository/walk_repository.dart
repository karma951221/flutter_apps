import 'package:core/core.dart';

import '../entity/walk.dart';
import '../entity/walk_track_point.dart';

abstract interface class WalkRepository {
  /// 시작 시각 내림차순.
  Stream<Result<List<Walk>>> watchAll();

  Future<Result<Walk?>> findById(String id);

  Future<Result<List<WalkTrackPoint>>> getTrack(String id);

  Future<Result<void>> insert(Walk walk, List<WalkTrackPoint> track);

  /// 반려견·메모·사진·updatedAt 만 바꾼다.
  Future<Result<void>> update(Walk walk);

  Future<Result<void>> delete(String id);
}
