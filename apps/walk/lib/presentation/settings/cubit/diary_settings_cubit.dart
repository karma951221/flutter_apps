import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/diary/draft/draft_style.dart';
import '../../../domain/diary/entity/diary_usage.dart';
import '../../../domain/diary/entity/trash_retention.dart';
import '../../../domain/diary/repository/diary_preferences.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/lock/lock_config.dart';
import '../../../domain/lock/lock_repository.dart';
import 'diary_settings_state.dart';

/// 잠금 · 휴지통 보관 기간 · 저장 공간(스펙 §8) · 자동 초안 기본값. 셸이 소유하고, 앱 설정 · 일기 설정 화면이
/// 열릴 때 [load] 한다. 잠금 켜기 · 끄기 · 방식 변경은 `LockSetupPage` 가 맡는다 — 그 뒤
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
    emit(_read(state.usage));
    DiaryUsage? usage;
    try {
      usage = await _repo.usage();
    } on Object {
      usage = state.usage;
    }
    if (isClosed) return;
    emit(_read(usage));
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

  /// 자동 초안의 문체 — 초안은 늘 이 문체로 쓴다(작성 화면에는 문체 칩이 없다).
  Future<void> setDraftStyle(DraftStyle style) async {
    await _prefs.setDraftStyle(style);
    if (!isClosed) emit(state.copyWith(draftStyle: style));
  }

  /// 사진 보여 주기(작성 화면 도구줄과 같은 값).
  Future<void> setDraftIncludePhotos(bool on) async {
    await _prefs.setDraftIncludePhotos(on);
    if (!isClosed) emit(state.copyWith(draftIncludePhotos: on));
  }

  DiarySettingsState _read(DiaryUsage? usage) => DiarySettingsState(
    lock: _lock.loadConfig(),
    retention: _prefs.trashRetention,
    usage: usage,
    draftStyle: _prefs.draftStyle,
    draftIncludePhotos: _prefs.draftIncludePhotos,
  );

  DiarySettingsState _with({LockConfig? lock, TrashRetention? retention}) =>
      state.copyWith(
        lock: lock ?? state.lock,
        retention: retention ?? state.retention,
      );
}
