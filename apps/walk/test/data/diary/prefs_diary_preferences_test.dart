import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/diary/prefs_diary_preferences.dart';
import 'package:walk/domain/diary/draft/draft_style.dart';
import 'package:walk/domain/diary/entity/trash_retention.dart';

Future<PrefsDiaryPreferences> _prefs([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return PrefsDiaryPreferences(await SharedPreferences.getInstance());
}

void main() {
  test('저장한 적이 없으면 7일', () async {
    final prefs = await _prefs();

    expect(prefs.trashRetention, TrashRetention.day7);
  });

  test('저장한 값을 새 인스턴스에서 다시 읽는다', () async {
    final writer = await _prefs();

    await writer.setTrashRetention(TrashRetention.never);

    final reader = PrefsDiaryPreferences(await SharedPreferences.getInstance());
    expect(reader.trashRetention, TrashRetention.never);
  });

  test('타입이 다른 값이면 기본값', () async {
    final prefs = await _prefs({PrefsDiaryPreferences.trashRetentionKey: 7});

    expect(prefs.trashRetention, TrashRetention.day7);
  });

  test('모르는 이름이면 기본값', () async {
    final prefs = await _prefs({
      PrefsDiaryPreferences.trashRetentionKey: 'day365',
    });

    expect(prefs.trashRetention, TrashRetention.day7);
  });

  group('자동 초안', () {
    test('저장한 적이 없으면 일기체 · 사진 보내지 않음', () async {
      final prefs = await _prefs();

      expect(prefs.draftStyle, DraftStyle.diary);
      expect(prefs.draftIncludePhotos, isFalse);
    });

    test('문체 · 사진 기본값을 저장하고 새 인스턴스에서 다시 읽는다', () async {
      final writer = await _prefs();

      await writer.setDraftStyle(DraftStyle.memo);
      await writer.setDraftIncludePhotos(true);

      final reader = PrefsDiaryPreferences(
        await SharedPreferences.getInstance(),
      );
      expect(reader.draftStyle, DraftStyle.memo);
      expect(reader.draftIncludePhotos, isTrue);
    });

    test('키는 diary.draft.style · diary.draft.includePhotos', () async {
      final prefs = await _prefs({
        'diary.draft.style': 'sns',
        'diary.draft.includePhotos': true,
      });

      expect(prefs.draftStyle, DraftStyle.sns);
      expect(prefs.draftIncludePhotos, isTrue);
    });

    test('모르는 문체 · 타입이 다른 값이면 기본값', () async {
      final unknown = await _prefs({
        PrefsDiaryPreferences.draftStyleKey: 'haiku',
        PrefsDiaryPreferences.draftIncludePhotosKey: 'yes',
      });
      expect(unknown.draftStyle, DraftStyle.diary);
      expect(unknown.draftIncludePhotos, isFalse);

      final wrongType = await _prefs({PrefsDiaryPreferences.draftStyleKey: 3});
      expect(wrongType.draftStyle, DraftStyle.diary);
    });
  });
}
