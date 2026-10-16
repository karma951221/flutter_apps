import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'walk_export_result.freezed.dart';

/// 상세 화면의 "GPX로 내보내기" 결과. 상태가 아니라 한 번 쓰고 버리는 값이다.
@freezed
sealed class WalkExportResult with _$WalkExportResult {
  /// 공유 시트가 열렸다(공유 · 취소 모두).
  const factory WalkExportResult.shared() = WalkExportShared;

  /// 경로 점이 없어 내보낼 것이 없다.
  const factory WalkExportResult.noRoute() = WalkExportNoRoute;

  const factory WalkExportResult.failed(Failure failure) = WalkExportFailed;
}
