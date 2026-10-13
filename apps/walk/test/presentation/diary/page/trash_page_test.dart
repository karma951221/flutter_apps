import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/diary/prefs_diary_preferences.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/entity/trash_retention.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/domain/diary/repository/diary_preferences.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/diary/usecase/diary_use_case.dart';
import 'package:walk/presentation/diary/page/trash_page.dart';

import '../../../support/diary_fixtures.dart';

class _MockRepo extends Mock implements DiaryRepository {}

class _MockUseCase extends Mock implements DiaryUseCase {}

class _MockStore extends Mock implements MediaStore {}

DiaryEntry _entry(
  String body, {
  required DateTime deletedAt,
  List<EntryMedia> media = const [],
}) => DiaryEntry(
  id: body,
  storyId: Story.dailyId,
  body: body,
  occurredAt: diaryT0,
  createdAt: diaryT0,
  updatedAt: diaryT0,
  deletedAt: deletedAt,
  media: media,
  tags: const [],
);

void main() {
  late _MockRepo repo;
  late _MockUseCase useCase;
  late StreamController<List<DiaryEntry>> trash;
  late PrefsDiaryPreferences prefs;
  late MutableClock clock;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PrefsDiaryPreferences(await SharedPreferences.getInstance());
    clock = MutableClock(diaryT0);
    trash = StreamController<List<DiaryEntry>>.broadcast();
    repo = _MockRepo();
    when(repo.watchTrash).thenAnswer(
      (_) => Stream.multi((c) {
        c.add([
          _entry('어제 글', deletedAt: diaryT0.subtract(const Duration(days: 1))),
          _entry('오래된 글', deletedAt: diaryT0.subtract(const Duration(days: 2))),
        ]);
        final sub = trash.stream.listen(c.add);
        c.onCancel = sub.cancel;
      }),
    );
    useCase = _MockUseCase();
    when(() => useCase.restore(any())).thenAnswer(
      (inv) async => Ok(
        _entry(inv.positionalArguments.single as String, deletedAt: diaryT0),
      ),
    );
    when(() => useCase.purge(any())).thenAnswer((_) async => const Ok(null));
    when(useCase.emptyTrash).thenAnswer((_) async => const Ok(null));
    final store = _MockStore();
    when(
      () => store.resolve(any()),
    ).thenAnswer((inv) => File('/diary/${inv.positionalArguments.single}'));
    getIt
      ..registerSingleton<MediaStore>(store)
      ..registerSingleton<DiaryRepository>(repo)
      ..registerSingleton<DiaryUseCase>(useCase)
      ..registerSingleton<DiaryPreferences>(prefs)
      ..registerSingleton<Clock>(clock);
  });

  tearDown(() async {
    await trash.close();
    await getIt.reset();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TrashPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String row, String item) async {
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(AppListTile, row),
        matching: find.byIcon(Icons.more_vert),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(item).last);
    await tester.pumpAndSettle();
  }

  testWidgets('지운 기록과 남은 일수를 보인다(7일 보관, 2일 전 → 5일 남음)', (tester) async {
    await pump(tester);

    expect(find.text('휴지통'), findsOneWidget);
    expect(find.widgetWithText(AppListTile, '어제 글'), findsOneWidget);
    expect(find.textContaining('6일 남음'), findsOneWidget);
    expect(find.textContaining('5일 남음'), findsOneWidget);
  });

  testWidgets('행 앞에 첫 미디어 썸네일(사진 · 영상 썸네일), 없으면 아이콘', (tester) async {
    when(repo.watchTrash).thenAnswer(
      (_) => Stream.value([
        _entry(
          '사진 글',
          deletedAt: diaryT0,
          media: [photoMedia('p1'), videoMedia('v1')],
        ),
        _entry('영상 글', deletedAt: diaryT0, media: [videoMedia('v2')]),
        _entry('글만', deletedAt: diaryT0),
      ]),
    );
    await pump(tester);

    Finder leadingOf(String row) => find.descendant(
      of: find.widgetWithText(AppListTile, row),
      matching: find.byType(Image),
    );
    String imagePath(String row) =>
        ((tester.widget<Image>(leadingOf(row)).image as ResizeImage)
                    .imageProvider
                as FileImage)
            .file
            .path;

    expect(imagePath('사진 글'), '/diary/media/p1.jpg');
    expect(imagePath('영상 글'), '/diary/media/v2.thumb.jpg');
    expect(leadingOf('글만'), findsNothing);
    expect(
      find.descendant(
        of: find.widgetWithText(AppListTile, '글만'),
        matching: find.byIcon(Icons.notes_outlined),
      ),
      findsOneWidget,
    );
  });

  testWidgets('보관 기간이 안 함이면 남은 일수를 보이지 않는다', (tester) async {
    await prefs.setTrashRetention(TrashRetention.never);
    await pump(tester);

    expect(find.textContaining('남음'), findsNothing);
    expect(find.widgetWithText(AppListTile, '어제 글'), findsOneWidget);
  });

  testWidgets('기한이 오늘이면 오늘 삭제돼요', (tester) async {
    await prefs.setTrashRetention(TrashRetention.day1);
    when(repo.watchTrash).thenAnswer(
      (_) => Stream.value([
        _entry('아슬', deletedAt: diaryT0.subtract(const Duration(days: 1))),
      ]),
    );
    await pump(tester);

    expect(find.textContaining('오늘 삭제돼요'), findsOneWidget);
  });

  testWidgets('복원은 확인 없이 하고 알린다', (tester) async {
    await pump(tester);

    await choose(tester, '어제 글', '복원');

    verify(() => useCase.restore('어제 글')).called(1);
    expect(find.text('기록을 복원했어요'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('영구 삭제는 확인을 받고, 취소하면 지우지 않는다', (tester) async {
    await pump(tester);

    await choose(tester, '어제 글', '영구 삭제');
    expect(find.text('영구 삭제할까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    verifyNever(() => useCase.purge(any()));

    await choose(tester, '어제 글', '영구 삭제');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('영구 삭제'),
      ),
    );
    await tester.pumpAndSettle();

    verify(() => useCase.purge(['어제 글'])).called(1);
    expect(find.text('기록을 영구 삭제했어요'), findsOneWidget);
  });

  testWidgets('비우기는 개수를 알리고 확인을 받는다', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip('휴지통 비우기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2개가 영구 삭제돼요'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('휴지통 비우기'),
      ),
    );
    await tester.pumpAndSettle();

    verify(useCase.emptyTrash).called(1);
    expect(find.text('휴지통을 비웠어요'), findsOneWidget);
  });

  testWidgets('동작이 실패하면 오류를 알린다', (tester) async {
    when(
      () => useCase.restore(any()),
    ).thenAnswer((_) async => const Err(Failure.unknown()));
    await pump(tester);

    await choose(tester, '어제 글', '복원');

    expect(find.text('기록을 복원했어요'), findsNothing);
    expect(find.text('복원하지 못했어요. 다시 시도해 주세요'), findsOneWidget);
  });

  testWidgets('영구 삭제가 실패하면 삭제 오류를 알린다', (tester) async {
    when(
      () => useCase.purge(any()),
    ).thenAnswer((_) async => const Err(Failure.unknown()));
    await pump(tester);

    await choose(tester, '어제 글', '영구 삭제');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('영구 삭제'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('삭제하지 못했어요. 다시 시도해 주세요'), findsOneWidget);
  });

  testWidgets('비어 있으면 빈 상태 안내, 비우기는 못 누른다', (tester) async {
    when(repo.watchTrash).thenAnswer((_) => Stream.value(const []));
    await pump(tester);

    expect(find.widgetWithText(AppPlaceholder, '휴지통이 비어 있어요'), findsOneWidget);
    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.delete_sweep_outlined),
    );
    expect(button.onPressed, isNull);
  });
}
