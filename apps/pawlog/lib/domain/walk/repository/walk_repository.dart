import 'package:core/core.dart';

import '../entity/walk.dart';
import '../entity/walk_track_point.dart';

abstract interface class WalkRepository {
  /// 시작 시각 내림차순.
  Stream<Result<List<Walk>>> watchAll();

  /// 피드 한 화면 분량. [watchAll] 과 같은 순서로 최근 [limit] 개 산책(조인 행이 아니라
  /// 산책 수)을 낸다. [favoritesOnly] 면 즐겨찾기만 세어 자른다.
  Stream<Result<List<Walk>>> watchRecent({
    required int limit,
    bool favoritesOnly = false,
  });

  /// [from] 이후(같은 시각 포함)에 시작한 산책. 기간 요약을 페이지와 무관하게 셀 때 쓴다.
  Stream<Result<List<Walk>>> watchStartedSince(DateTime from);

  Future<Result<Walk?>> findById(String id);

  Future<Result<List<WalkTrackPoint>>> getTrack(String id);

  Future<Result<void>> insert(Walk walk, List<WalkTrackPoint> track);

  /// 반려견·메모·사진·updatedAt 만 바꾼다. 즐겨찾기는 그대로 둔다.
  Future<Result<void>> update(Walk walk);

  /// 즐겨찾기만 바꾼다(updatedAt 그대로). 없는 id 면 `walkNotFound`.
  Future<Result<void>> setFavorite(String id, bool value);

  Future<Result<void>> delete(String id);
}
