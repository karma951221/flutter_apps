import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/draft/draft_style.dart';
import 'package:walk/domain/diary/entity/diary_usage.dart';
import 'package:walk/domain/diary/entity/trash_retention.dart';
import 'package:walk/domain/diary/repository/diary_preferences.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/presentation/settings/cubit/diary_settings_cubit.dart';
import 'package:walk/presentation/settings/cubit/diary_settings_state.dart';

class _MockLock extends Mock implements LockRepository {}

class _MockPrefs extends Mock implements DiaryPreferences {}

class _MockRepo extends Mock implements DiaryRepository {}

void main() {
  late _MockLock lock;
  late _MockPrefs prefs;
  late _MockRepo repo;
  late DiarySettingsCubit cubit;
  const usage = DiaryUsage(photos: 3, videos: 1, bytes: 1000, trashBytes: 100);

  setUpAll(() {
    registerFallbackValue(const LockConfig());
    registerFallbackValue(TrashRetention.day7);
    registerFallbackValue(DraftStyle.diary);
  });
  setUp(() {
    lock = _MockLock();
    prefs = _MockPrefs();
    repo = _MockRepo();
    when(lock.loadConfig).thenReturn(const LockConfig());
    when(() => lock.saveConfig(any())).thenAnswer((_) async {});
    when(() => prefs.trashRetention).thenReturn(TrashRetention.day7);
    when(() => prefs.setTrashRetention(any())).thenAnswer((_) async {});
    when(() => prefs.draftStyle).thenReturn(DraftStyle.diary);
    when(() => prefs.draftIncludePhotos).thenReturn(false);
    when(() => prefs.setDraftStyle(any())).thenAnswer((_) async {});
    when(() => prefs.setDraftIncludePhotos(any())).thenAnswer((_) async {});
    when(repo.usage).thenAnswer((_) async => usage);
    cubit = DiarySettingsCubit(lock, prefs, repo);
  });
  tearDown(() => cubit.close());

  test('처음에는 아무것도 읽지 않았다', () {
    expect(cubit.state.lock, isNull);
    expect(cubit.state.usage, isNull);
  });

  test('load: 잠금 설정 · 보관 기간 · 저장 공간을 읽는다', () async {
    when(
      lock.loadConfig,
    ).thenReturn(const LockConfig(enabled: true, method: LockMethod.pattern));
    when(() => prefs.trashRetention).thenReturn(TrashRetention.day30);

    await cubit.load();

    expect(
      cubit.state,
      const DiarySettingsState(
        lock: LockConfig(enabled: true, method: LockMethod.pattern),
        retention: TrashRetention.day30,
        usage: usage,
      ),
    );
  });

  test('load: 저장 공간을 못 읽어도 나머지는 보이고 이전 값을 둔다', () async {
    await cubit.load();
    when(repo.usage).thenThrow(Exception('io'));

    await cubit.load();

    expect(cubit.state.usage, usage);
    expect(cubit.state.lock, const LockConfig());
  });

  test('setRelockDelay: 저장소에서 방금 읽은 설정에 얹어 저장한다', () async {
    await cubit.load();
    // 화면이 읽은 뒤 잠금 설정이 바뀌었다(LockSetupPage).
    when(
      lock.loadConfig,
    ).thenReturn(const LockConfig(enabled: true, method: LockMethod.pattern));

    await cubit.setRelockDelay(RelockDelay.minutes5);

    verify(
      () => lock.saveConfig(
        const LockConfig(
          enabled: true,
          method: LockMethod.pattern,
          relockDelay: RelockDelay.minutes5,
        ),
      ),
    ).called(1);
    expect(cubit.state.lock?.relockDelay, RelockDelay.minutes5);
    expect(cubit.state.lock?.enabled, isTrue);
  });

  test('setRetention: 저장하고 상태에 반영한다', () async {
    await cubit.load();

    await cubit.setRetention(TrashRetention.never);

    verify(() => prefs.setTrashRetention(TrashRetention.never)).called(1);
    expect(cubit.state.retention, TrashRetention.never);
    expect(cubit.state.usage, usage);
  });

  test('load: 자동 초안 기본 문체 · 사진 기본값을 읽는다', () async {
    when(() => prefs.draftStyle).thenReturn(DraftStyle.polite);
    when(() => prefs.draftIncludePhotos).thenReturn(true);

    await cubit.load();

    expect(cubit.state.draftStyle, DraftStyle.polite);
    expect(cubit.state.draftIncludePhotos, isTrue);
  });

  test('처음 상태의 자동 초안은 일기체 · 사진 끔', () {
    expect(cubit.state.draftStyle, DraftStyle.diary);
    expect(cubit.state.draftIncludePhotos, isFalse);
  });

  test('setDraftStyle: 저장하고 상태에 반영한다(다른 값은 그대로)', () async {
    await cubit.load();

    await cubit.setDraftStyle(DraftStyle.sns);

    verify(() => prefs.setDraftStyle(DraftStyle.sns)).called(1);
    expect(cubit.state.draftStyle, DraftStyle.sns);
    expect(cubit.state.usage, usage);
    expect(cubit.state.retention, TrashRetention.day7);
  });

  test('setDraftIncludePhotos: 저장하고 상태에 반영한다', () async {
    await cubit.load();

    await cubit.setDraftIncludePhotos(true);

    verify(() => prefs.setDraftIncludePhotos(true)).called(1);
    expect(cubit.state.draftIncludePhotos, isTrue);
  });

  test('setRetention 뒤에도 자동 초안 값은 그대로', () async {
    when(() => prefs.draftStyle).thenReturn(DraftStyle.memo);
    await cubit.load();

    await cubit.setRetention(TrashRetention.never);

    expect(cubit.state.draftStyle, DraftStyle.memo);
  });
}
