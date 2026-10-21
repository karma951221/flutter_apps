import 'package:freezed_annotation/freezed_annotation.dart';

part 'commute_failure.freezed.dart';

/// 통근 조회가 실패한 이유. 화면은 종류만 보고 문구를 고른다.
@freezed
sealed class CommuteFailure with _$CommuteFailure {
  const factory CommuteFailure.missingPlaces() = CommuteMissingPlaces;
  const factory CommuteFailure.missingKey() = CommuteMissingKey;
  const factory CommuteFailure.network() = CommuteNetwork;
  const factory CommuteFailure.noRoute() = CommuteNoRoute;
  const factory CommuteFailure.server(String message) = CommuteServer;
}
