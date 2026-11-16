import 'dart:io';

import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'backup_area_id.dart';
import 'backup_manifest.dart';
import 'restore_notice.dart';

part 'backup_service.freezed.dart';

/// 백업 파일 만들기 · 검사 · 복원 · 되돌리기. 실패는 `Failure.validation(field: BackupFailure.x.name)`.
abstract interface class BackupService {
  /// 영역마다 지금 개수와 대략의 크기(백업 시트).
  Future<Map<BackupAreaId, AreaPreview>> preview();

  /// 고른 영역을 담은 백업 파일을 앱 캐시에 만든다. [password] 가 있으면 암호화(`.lifelog`).
  /// 성공하면 마지막 백업 시각을 남긴다.
  Future<Result<File>> export(Set<BackupAreaId> areas, {String? password});

  /// [file] 을 작업 폴더에 풀고 검증한다. 지금 데이터에는 손대지 않는다.
  /// 암호화된 파일인데 [password] 가 없거나 틀리면 `wrongPasswordOrCorrupt`.
  Future<Result<InspectedBackup>> inspect(File file, {String? password});

  /// 고른 영역의 지금 데이터를 [b] 의 것으로 바꾼다. 바꾸기 전 데이터는 되돌리기 지점으로 남는다.
  /// 한 영역이라도 실패하면 고른 영역 모두를 되돌리고 원래 실패를 돌려준다(되돌리기마저 실패하면
  /// [needsRecovery] 가 참). 성공 · 실패 모두 [b] 의 작업 폴더를 지운다. [areas] 가 비면 아무것도
  /// 하지 않는다.
  Future<Result<Set<RestoreNotice>>> restore(
    InspectedBackup b,
    Set<BackupAreaId> areas,
  );

  /// "복원 전으로 되돌리기"를 할 수 있는가.
  Future<bool> hasUndoPoint();

  /// 복원 · 되돌리기가 끝나지 않은 채 남았는가(되돌리기 실패 등). 참이면 앱을 다시 시작하라고
  /// 안내한다 — 시작 때 [recoverIfInterrupted] 가 마저 되돌린다.
  Future<bool> needsRecovery();

  /// 마지막 복원 전 데이터로 되돌린다. 되돌리기 지점은 한 번 쓰면 없어진다.
  Future<Result<Set<RestoreNotice>>> undo();

  /// 앱 시작 때 가장 먼저 부른다. 복원 · 되돌리기 도중 죽었으면 되돌리기 지점으로 되돌리고
  /// 남은 작업 폴더를 지운다. 던지지 않는다.
  Future<void> recoverIfInterrupted();

  /// 복원하지 않고 닫을 때 [b] 의 작업 폴더를 지운다.
  Future<void> discard(InspectedBackup b);
}

/// 백업 시트의 영역 한 줄 — 개수와 내보내기에 드는 대략의 바이트.
@freezed
class AreaPreview with _$AreaPreview {
  @override
  final Map<String, int> counts;

  @override
  final int bytes;

  const AreaPreview({required this.counts, required this.bytes});
}

/// 검사를 마친 백업. [staging] 에 풀려 있고, 복원 · [BackupService.discard] 가 지운다.
@freezed
class InspectedBackup with _$InspectedBackup {
  @override
  final BackupManifest manifest;

  /// 영역 폴더(`<id>/`)들이 있는 작업 폴더.
  @override
  final Directory staging;

  /// 백업에 든 영역마다 복원할 수 있는지.
  @override
  final Map<BackupAreaId, AreaAvailability> areas;

  const InspectedBackup({
    required this.manifest,
    required this.staging,
    required this.areas,
  });
}

/// 백업에 든 영역을 이 앱이 복원할 수 있는가.
enum AreaAvailability {
  ok,

  /// 영역 스키마가 이 앱보다 새것이다 — 앱을 업데이트해야 한다.
  newerSchema,
}
