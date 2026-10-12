import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/diary/prefs_diary_preferences.dart';
import 'package:walk/domain/diary/entity/diary_view_mode.dart';
import 'package:walk/domain/diary/entity/trash_retention.dart';

Future<PrefsDiaryPreferences> _prefs([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return PrefsDiaryPreferences(await SharedPreferences.getInstance());
}

void main() {
  test('저장한 적이 없으면 7일 · 전체 · 줄글', () async {
    final prefs = await _prefs();

    expect(prefs.trashRetention, TrashRetention.day7);
    expect(prefs.lastViewedStoryId, isNull);
    expect(prefs.viewMode, DiaryViewMode.prose);
  });

  test('저장한 값을 새 인스턴스에서 다시 읽는다', () async {
    final writer = await _prefs();

    await writer.setTrashRetention(TrashRetention.never);
    await writer.setLastViewedStoryId('jeju');
    await writer.setViewMode(DiaryViewMode.reels);

    final reader = PrefsDiaryPreferences(await SharedPreferences.getInstance());
    expect(reader.trashRetention, TrashRetention.never);
    expect(reader.lastViewedStoryId, 'jeju');
    expect(reader.viewMode, DiaryViewMode.reels);
  });

  test('마지막 스토리를 null 로 저장하면 "전체"', () async {
    final prefs = await _prefs({
      PrefsDiaryPreferences.lastViewedStoryKey: 'jeju',
    });

    await prefs.setLastViewedStoryId(null);

    expect(prefs.lastViewedStoryId, isNull);
    expect(
      (await SharedPreferences.getInstance()).containsKey(
        PrefsDiaryPreferences.lastViewedStoryKey,
      ),
      isFalse,
    );
  });

  test('타입이 다른 값이면 기본값', () async {
    final prefs = await _prefs({
      PrefsDiaryPreferences.trashRetentionKey: 7,
      PrefsDiaryPreferences.lastViewedStoryKey: 3,
      PrefsDiaryPreferences.viewModeKey: true,
    });

    expect(prefs.trashRetention, TrashRetention.day7);
    expect(prefs.lastViewedStoryId, isNull);
    expect(prefs.viewMode, DiaryViewMode.prose);
  });

  test('모르는 이름이면 기본값', () async {
    final prefs = await _prefs({
      PrefsDiaryPreferences.trashRetentionKey: 'day365',
      PrefsDiaryPreferences.viewModeKey: 'grid',
    });

    expect(prefs.trashRetention, TrashRetention.day7);
    expect(prefs.viewMode, DiaryViewMode.prose);
  });
}
