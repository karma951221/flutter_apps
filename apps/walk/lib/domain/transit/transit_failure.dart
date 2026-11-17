import 'package:freezed_annotation/freezed_annotation.dart';

part 'transit_failure.freezed.dart';

/// 길찾기가 실패한 이유. 화면은 종류만 보고 문구를 고른다.
@freezed
sealed class TransitFailure with _$TransitFailure implements Exception {
  const factory TransitFailure.missingKey() = TransitMissingKey;
  const factory TransitFailure.keyRejected(String message) = TransitKeyRejected;
  const factory TransitFailure.quotaExceeded() = TransitQuotaExceeded;
  const factory TransitFailure.network() = TransitNetwork;
  const factory TransitFailure.noRoute() = TransitNoRoute;
  const factory TransitFailure.tooClose() = TransitTooClose;
  const factory TransitFailure.server(String message) = TransitServer;
}
