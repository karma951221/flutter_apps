import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/repository/diary_preferences.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/diary/usecase/diary_use_case.dart';
import 'trash_state.dart';

/// 휴지통(스펙 §5.1 · §6.5): 목록(남은 일수) · 복원 · 영구 삭제 · 비우기.
///
/// 확인 다이얼로그는 화면이 띄운다. 동작이 실패하면 [TrashState.actionFailed] 에 남기고,
/// 다음 동작을 시작할 때 비운다 — 화면은 동작을 기다린 뒤 이것으로 성공을 판단한다.
class TrashCubit extends Cubit<TrashState> {
  TrashCubit(this._repo, this._useCase, this._prefs, this._clock)
    : super(const TrashState());

  final DiaryRepository _repo;
  final DiaryUseCase _useCase;
  final DiaryPreferences _prefs;
  final Clock _clock;

  StreamSubscription<List<DiaryEntry>>? _trash;

  void start() {
    unawaited(_trash?.cancel());
    _trash = _repo.watchTrash().listen(
      (entries) => emit(
        state.copyWith(
          items: _items(entries),
          loading: false,
          failed: false,
        ),
      ),
      onError: (Object _) => emit(state.copyWith(loading: false, failed: true)),
    );
  }

  Future<void> restore(String id) async {
    emit(state.copyWith(actionFailed: false));
    _settle(await _useCase.restore(id));
  }

  Future<void> purge(String id) async {
    emit(state.copyWith(actionFailed: false));
    _settle(await _useCase.purge([id]));
  }

  Future<void> emptyAll() async {
    emit(state.copyWith(actionFailed: false));
    _settle(await _useCase.emptyTrash());
  }

  void _settle<T>(Result<T> result) {
    if (result is Err<T>) emit(state.copyWith(actionFailed: true));
  }

  List<TrashItem> _items(List<DiaryEntry> entries) {
    final period = _prefs.trashRetention.period;
    final now = _clock.now();
    return [
      for (final entry in entries)
        (entry: entry, daysLeft: _daysLeft(entry, period, now)),
    ];
  }

  /// ceil((deletedAt + period − now) / 1일), 0 아래로는 내려가지 않는다. 안 함이면 null.
  static int? _daysLeft(DiaryEntry entry, Duration? period, DateTime now) {
    final deletedAt = entry.deletedAt;
    if (period == null || deletedAt == null) return null;
    final left = deletedAt.add(period).difference(now);
    if (left <= Duration.zero) return 0;
    return (left.inMicroseconds / Duration.microsecondsPerDay).ceil();
  }

  @override
  Future<void> close() async {
    await _trash?.cancel();
    return super.close();
  }
}
