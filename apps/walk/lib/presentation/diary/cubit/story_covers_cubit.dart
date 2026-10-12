import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/entry_filter.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/diary/usecase/story_cover.dart';

/// 스토리 id → 표지(스펙 §5 표지). 스토리 · 기록(휴지통 제외)이 바뀔 때마다
/// [StoryCoverRule.pick] 으로 다시 고른다. 읽지 못하면 마지막 표지를 그대로 둔다(이니셜이 기본).
class StoryCoversCubit extends Cubit<Map<String, StoryCover>> {
  StoryCoversCubit(this._repo) : super(const {});

  final DiaryRepository _repo;

  StreamSubscription<List<Story>>? _storySub;
  StreamSubscription<List<DiaryEntry>>? _entrySub;
  List<Story> _stories = const [];
  List<DiaryEntry> _entries = const [];

  void start() {
    unawaited(_storySub?.cancel());
    unawaited(_entrySub?.cancel());
    _storySub = _repo.watchStories().listen((stories) {
      _stories = stories;
      _pick();
    }, onError: (Object _) {});
    _entrySub = _repo.watchEntries(const EntryFilter.all()).listen((entries) {
      _entries = entries;
      _pick();
    }, onError: (Object _) {});
  }

  void _pick() {
    final byStory = <String, List<DiaryEntry>>{};
    for (final e in _entries) {
      (byStory[e.storyId] ??= []).add(e);
    }
    emit({
      for (final s in _stories)
        s.id: StoryCoverRule.pick(s, byStory[s.id] ?? const []),
    });
  }

  @override
  Future<void> close() async {
    await _storySub?.cancel();
    await _entrySub?.cancel();
    return super.close();
  }
}
