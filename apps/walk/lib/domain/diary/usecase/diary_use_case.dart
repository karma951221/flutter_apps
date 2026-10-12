import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../entity/diary_entry.dart';
import '../entity/entry_draft.dart';
import '../entity/entry_media.dart';
import '../location/place_lookup.dart';
import '../location/place_source.dart';
import '../media/media_store.dart';
import '../repository/diary_preferences.dart';
import '../repository/diary_repository.dart';

/// DB(저장소)와 파일(미디어 보관소)을 함께 바꾸는 일기 흐름.
///
/// 순서 규칙: 파일을 먼저 media/ 로 옮기고 DB 에 저장한다(실패하면 되돌린다).
/// 파일 삭제는 DB 가 Ok 를 돌려준 뒤에만 하고, 삭제 실패는 삼켜 [cleanOrphans] 가 회수한다.
@lazySingleton
class DiaryUseCase {
  DiaryUseCase(this._repo, this._media, this._places, this._prefs, this._clock);

  final DiaryRepository _repo;
  final MediaStore _media;
  final PlaceSource _places;
  final DiaryPreferences _prefs;
  final Clock _clock;

  /// draft.validate(now) → 새 미디어 promote → create/update → 실패 시 promote 한 것 demote.
  /// 수정이면 기존에 있었는데 draft 에 없는 미디어의 파일을 **DB 저장 성공 뒤** 지운다.
  Future<Result<DiaryEntry>> save(EntryDraft draft, {String? editingId}) async {
    if (draft.validate(_clock.now()) case Err(:final failure)) {
      return Err(failure);
    }

    List<String> previousFiles = const [];
    if (editingId != null) {
      switch (await _repo.entry(editingId)) {
        case Err(:final failure):
          return Err(failure);
        case Ok(value: final previous):
          previousFiles = _filesOf(previous.media);
      }
    }

    final promoted = <EntryMedia>[];
    final saved = <EntryMedia>[];
    try {
      for (final m in draft.media) {
        final moved = await _media.promote(m);
        if (moved.path != m.path) promoted.add(moved);
        saved.add(moved);
      }
    } catch (e) {
      await _demoteAll(promoted);
      return Err(Failure.unknown(message: '$e'));
    }

    final toSave = draft.copyWith(media: saved);
    final result = editingId == null
        ? await _repo.createEntry(toSave)
        : await _repo.updateEntry(editingId, toSave);
    switch (result) {
      case Err():
        await _demoteAll(promoted);
      case Ok():
        final kept = _filesOf(saved).toSet();
        await _deleteFiles([
          for (final path in previousFiles)
            if (!kept.contains(path)) path,
        ]);
    }
    return result;
  }

  /// 저장하지 않고 닫을 때 새로 가져온 사본(tmp)을 지운다.
  Future<void> cancelDraft(List<EntryMedia> newMedia) =>
      _media.discard(newMedia);

  Future<Result<void>> trash(String id) => _repo.trashEntry(id);

  Future<Result<DiaryEntry>> restore(String id) => _repo.restoreEntry(id);

  /// 휴지통 기록을 영구 삭제하고 그 파일을 지운다.
  Future<Result<void>> purge(List<String> ids) =>
      _thenDeleteFiles(_repo.purgeEntries(ids));

  Future<Result<void>> emptyTrash() => _thenDeleteFiles(_repo.purgeAllTrash());

  /// 기록은 휴지통으로 가고 파일은 남는다.
  Future<Result<void>> deleteStory(String id) => _repo.deleteStory(id);

  /// 일기 탭 진입 시: 기한 지난 휴지통 영구 삭제(+파일) → 장소 이름 채우기(네트워크 실패면 다음에).
  ///
  /// 이름 찾기는 네트워크를 기다리므로(호출당 수 초) 화면은 이것을 기다리지 말고
  /// 띄워만 둔다. 오프라인이면 남은 기록은 다음 호출로 미루고, 이 좌표에 붙일 이름이 없으면
  /// 그 기록만 건너뛴다(다음 호출에 다시 묻는다). 한 번에 [maxPlaceLookups] 번까지만 묻는다.
  /// 진행 중에 다시 부르면 새로 돌지 않고 진행 중인 작업을 돌려준다.
  Future<void> maintain() =>
      _maintaining ??= _maintain().whenComplete(() => _maintaining = null);

  Future<void>? _maintaining;

  /// [maintain] 한 번에 묻는 장소 이름의 최대 수.
  static const maxPlaceLookups = 20;

  Future<void> _maintain() async {
    final period = _prefs.trashRetention.period;
    if (period != null) {
      // TrashRetention.expired 와 같은 경계: deletedAt + period <= now.
      await _thenDeleteFiles(
        _repo.purgeTrashedBefore(_clock.now().subtract(period)),
      );
    }

    var lookups = 0;
    for (final entry in await _repo.entriesMissingPlaceName()) {
      final lat = entry.location?.lat;
      final lng = entry.location?.lng;
      if (lat == null || lng == null) continue;
      if (lookups++ >= maxPlaceLookups) break;
      switch (await _places.nameFor(lat, lng)) {
        case PlaceOffline():
          return;
        case PlaceNoName():
          continue;
        case PlaceNamed(:final name):
          await _repo.fillPlaceName(entry.id, name);
      }
    }
  }

  /// 앱 시작 시: DB 가 아는 경로(휴지통 포함, 원본 · 썸네일) 밖의 파일을 지운다.
  Future<void> cleanOrphans() async =>
      _media.cleanOrphans(await _repo.allMediaPaths(), _clock.now());

  Future<Result<void>> _thenDeleteFiles(
    Future<Result<List<String>>> purge,
  ) async {
    switch (await purge) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final paths):
        await _deleteFiles(paths);
        return const Ok(null);
    }
  }

  /// best-effort. 남은 파일은 [cleanOrphans] 가 회수한다.
  Future<void> _deleteFiles(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _media.deleteFiles(paths);
    } catch (_) {}
  }

  Future<void> _demoteAll(List<EntryMedia> promoted) async {
    for (final m in promoted) {
      try {
        await _media.demote(m);
      } catch (_) {
        // 되돌리지 못한 파일은 DB 에 없으므로 고아 청소가 회수한다.
      }
    }
  }

  static List<String> _filesOf(List<EntryMedia> media) => [
    for (final m in media) ...[m.path, ?m.thumbPath],
  ];
}
