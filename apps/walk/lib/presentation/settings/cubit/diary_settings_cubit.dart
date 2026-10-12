import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/diary/entity/diary_usage.dart';
import '../../../domain/diary/entity/trash_retention.dart';
import '../../../domain/diary/repository/diary_preferences.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/lock/lock_config.dart';
import '../../../domain/lock/lock_repository.dart';
import 'diary_settings_state.dart';

/// 설정 탭 "일기" 섹션(스펙 §8). 셸이 소유하고, 섹션이 처음 그려질 때와 설정 탭이 다시
/// 보일 때 [load] 한다. 잠금 켜기 · 끄기 · 방식 변경은 `LockSetupPage` 가 맡는다 — 그 뒤
/// 부르는 쪽이 [load] 로 다시 읽는다.
class DiarySettingsCubit extends Cubit<DiarySettingsState> {
  DiarySettingsCubit(this._lock, this._prefs, this._repo)
    : super(const DiarySettingsState());

  final LockRepository _lock;
  final DiaryPreferences _prefs;
  final DiaryRepository _repo;

  /// 잠금 설정 · 보관 기간 · 저장 공간을 다시 읽는다. 저장 공간 계산이 실패하면 이전 값을 둔다.
  /// 설정은 먼저 내보내고(저장 공간 계산을 기다리지 않는다) 저장 공간이 끝나면 한 번 더 낸다.
  Future<void> load() async {
    emit(
      DiarySettingsState(
        lock: _lock.loadConfig(),
        retention: _prefs.trashRetention,
        usage: state.usage,
      ),
    );
    DiaryUsage? usage;
    try {
      usage = await _repo.usage();
    } on Object {
      usage = state.usage;
    }
    if (isClosed) return;
    emit(
      DiarySettingsState(
        lock: _lock.loadConfig(),
        retention: _prefs.trashRetention,
        usage: usage,
      ),
    );
  }

  /// 다시 잠기는 시간을 바꾼다. 화면이 들고 있던 설정이 아니라 저장소에서 방금 읽은 설정에
  /// 얹어 저장한다(그 사이 잠금 설정이 바뀌었을 수 있다).
  Future<void> setRelockDelay(RelockDelay delay) async {
    final next = _lock.loadConfig().copyWith(relockDelay: delay);
    await _lock.saveConfig(next);
    if (!isClosed) emit(_with(lock: next));
  }

  Future<void> setRetention(TrashRetention retention) async {
    await _prefs.setTrashRetention(retention);
    if (!isClosed) emit(_with(retention: retention));
  }

  DiarySettingsState _with({LockConfig? lock, TrashRetention? retention}) =>
      DiarySettingsState(
        lock: lock ?? state.lock,
        retention: retention ?? state.retention,
        usage: state.usage,
      );
}
