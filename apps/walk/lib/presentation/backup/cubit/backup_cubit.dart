import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/backup/backup_area_id.dart';
import '../../../domain/backup/backup_failure.dart';
import '../../../domain/backup/backup_file_probe.dart';
import '../../../domain/backup/backup_files.dart';
import '../../../domain/backup/backup_preferences.dart';
import '../../../domain/backup/backup_service.dart';
import '../../../domain/backup/restore_notice.dart';
import '../../lock/media_pick_guard.dart';
import 'backup_state.dart';

/// 백업 화면 — 내보내기(만들기 → 저장 위치) · 복원(고르기 → 비밀번호 → 검사 → 영역 → 복원) ·
/// 되돌리기. 실패 · 저장 완료는 알린 뒤 [load] 로 idle 에 돌아간다. 복원을 마치면 앱을 다시
/// 시작해야 하므로(prefs 를 읽어 둔 cubit · DB 싱글턴) [BackupRestored] 에 머문다.
@injectable
class BackupCubit extends Cubit<BackupState> {
  BackupCubit(
    this._service,
    this._files,
    this._probe,
    this._preferences,
    this._clock,
    this._pickGuard,
  ) : super(const BackupState.idle());

  /// 마지막 백업이 이보다 오래되면 "오래됨".
  static const staleAfterDays = 30;

  final BackupService _service;
  final BackupFiles _files;
  final BackupFileProbe _probe;
  final BackupPreferences _preferences;
  final Clock _clock;

  /// 저장 위치 · 문서 고르기 창으로 앱을 떠나 있는 동안 일기를 다시 잠그지 않게 한다 —
  /// 잠기면 화면이 고른 것을 버려 내보내기 · 복원을 끝낼 수 없다.
  final MediaPickGuard _pickGuard;

  /// 고른 백업 파일의 앱 캐시 사본. 검사가 끝나거나 그만두면 지운다.
  File? _opened;

  /// 마지막 백업 시각 · 되돌리기 지점을 다시 읽는다.
  Future<void> load() async {
    final lastAt = _preferences.lastAt;
    final hasUndo = await _service.hasUndoPoint();
    if (isClosed) return;
    final days = lastAt == null ? null : _daysBetween(lastAt, _clock.now());
    emit(
      BackupState.idle(
        lastAt: lastAt,
        daysAgo: days,
        stale: days != null && days > staleAfterDays,
        hasUndo: hasUndo,
      ),
    );
  }

  /// 내보내기 시트의 영역별 개수 · 크기. 읽지 못하면 빈 값(시트는 개수 없이 그린다).
  Future<Map<BackupAreaId, AreaPreview>> preview() async {
    try {
      return await _service.preview();
    } on Object {
      return const {};
    }
  }

  /// 고른 영역으로 백업 파일을 만들고 저장 위치를 고르게 한다. 저장을 취소하면 알리지 않는다.
  /// 마지막 백업 시각은 저장까지 마쳤을 때만 남긴다.
  Future<void> export(Set<BackupAreaId> areas, {String? password}) async {
    emit(const BackupState.working(BackupStep.exporting));
    final made = await _service.export(areas, password: password);
    switch (made) {
      case Err(:final failure):
        await _fail(failure);
        return;
      case Ok(value: final file):
        try {
          emit(const BackupState.working(BackupStep.saving));
          final bytes = await file.length();
          final saved = await _pickGuard.run(
            () => _files.saveAs(file, _basename(file)),
          );
          if (saved) {
            await _preferences.setLastAt(_clock.now());
            emit(BackupState.exported(bytes));
          }
        } on BackupException catch (e) {
          emit(BackupState.failed(e.failure));
        } on Object {
          emit(const BackupState.failed(BackupFailure.io));
        } finally {
          await _deleteQuietly(file);
        }
        await load();
    }
  }

  /// 문서 고르기 창으로 백업 파일을 고른다. 암호화면 비밀번호를 묻고, 아니면 바로 검사한다.
  Future<void> openBackup() async {
    final File? file;
    try {
      file = await _pickGuard.run(_files.open);
    } on Object catch (e) {
      emit(
        BackupState.failed(e is BackupException ? e.failure : BackupFailure.io),
      );
      await load();
      return;
    }
    if (file == null) return;
    _opened = file;
    final bool encrypted;
    try {
      encrypted = await _probe.isEncrypted(file);
    } on Object {
      await _closeOpened();
      emit(const BackupState.failed(BackupFailure.io));
      await load();
      return;
    }
    if (encrypted) {
      emit(const BackupState.passwordNeeded());
    } else {
      await _inspect(null);
    }
  }

  /// 비밀번호로 고른 파일을 검사한다. 틀리면 다시 묻는다.
  Future<void> submitPassword(String password) => _inspect(password);

  /// 비밀번호를 묻다가 그만둔다.
  Future<void> cancelOpen() async {
    await _closeOpened();
    await load();
  }

  Future<void> _inspect(String? password) async {
    final file = _opened;
    if (file == null) return;
    emit(const BackupState.working(BackupStep.inspecting));
    final result = await _service.inspect(file, password: password);
    switch (result) {
      case Ok(value: final backup):
        await _closeOpened();
        emit(BackupState.inspected(backup));
      case Err(:final failure)
          when password != null &&
              _backupFailureOf(failure) == BackupFailure.wrongPasswordOrCorrupt:
        emit(const BackupState.passwordNeeded(wrong: true));
      case Err(:final failure):
        await _closeOpened();
        await _fail(failure);
    }
  }

  /// 검사한 백업에서 [areas] 를 복원한다. [BackupInspected] 일 때만.
  Future<void> restore(Set<BackupAreaId> areas) async {
    final current = state;
    if (current is! BackupInspected) return;
    emit(const BackupState.working(BackupStep.restoring));
    await _finish(await _service.restore(current.backup, areas));
  }

  /// 영역 고르기 · 확인에서 그만둔다 — 작업 폴더를 지운다.
  Future<void> discard() async {
    final current = state;
    if (current is BackupInspected) await _service.discard(current.backup);
    await load();
  }

  /// 마지막 복원 전으로 되돌린다.
  Future<void> undo() async {
    emit(const BackupState.working(BackupStep.undoing));
    await _finish(await _service.undo());
  }

  /// 복원한 데이터로 처음부터 시작한다.
  Future<void> restartApp() => _files.restartApp();

  Future<void> _finish(Result<Set<RestoreNotice>> result) async {
    switch (result) {
      case Ok(value: final notices):
        emit(BackupState.restored(notices));
      case Err(:final failure):
        await _fail(failure);
    }
  }

  /// 실패를 알린다. 복원 · 되돌리기가 끝나지 않은 채 남았으면 다시 시작 안내에서 멈춘다.
  Future<void> _fail(Failure failure) async {
    final needsRestart = await _service.needsRecovery();
    if (isClosed) return;
    emit(
      BackupState.failed(_backupFailureOf(failure), needsRestart: needsRestart),
    );
    if (!needsRestart) await load();
  }

  Future<void> _closeOpened() async {
    final file = _opened;
    _opened = null;
    if (file != null) await _deleteQuietly(file);
  }

  @override
  Future<void> close() async {
    await _closeOpened();
    return super.close();
  }
}

/// 서비스가 실어 보낸 [BackupFailure]. 그 밖의 실패(예: 되돌리기 지점 없음)는 io.
BackupFailure _backupFailureOf(Failure failure) => switch (failure) {
  ValidationFailure(:final field?) => BackupFailure.values.firstWhere(
    (f) => f.name == field,
    orElse: () => BackupFailure.io,
  ),
  _ => BackupFailure.io,
};

/// 달력 날짜로 센 [from] 부터 [to] 까지의 날 수(시각 · 서머타임 무시). 시계가 뒤로 갔으면 0.
int _daysBetween(DateTime from, DateTime to) {
  final days = DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
  return days < 0 ? 0 : days;
}

String _basename(File file) => file.uri.pathSegments.last;

Future<void> _deleteQuietly(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } on FileSystemException {
    // 캐시 사본이라 남아도 다음 내보내기 · OS 가 지운다.
  }
}
