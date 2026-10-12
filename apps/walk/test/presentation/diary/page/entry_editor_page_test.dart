import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/diary_failure.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_draft.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/entity/named_count.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/location/place_source.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/diary/usecase/diary_use_case.dart';
import 'package:walk/presentation/diary/media_picker.dart';
import 'package:walk/presentation/diary/page/entry_editor_page.dart';
import 'package:walk/presentation/diary/widget/time_row.dart';

import '../../../support/diary_fixtures.dart';

class _MockRepo extends Mock implements DiaryRepository {}

class _MockUseCase extends Mock implements DiaryUseCase {}

class _MockStore extends Mock implements MediaStore {}

class _MockPicker extends Mock implements MediaPicker {}

class _FakePlaces implements PlaceSource {
  EntryLocation? location;

  @override
  Future<EntryLocation?> current() async => location;

  @override
  Future<String?> nameFor(double lat, double lng) async => null;
}

Story _story(String id, String title, {bool closed = false}) => Story(
  id: id,
  title: title,
  status: closed ? StoryStatus.closed : StoryStatus.open,
  startedAt: DateTime(2026, 10, 1),
  endedAt: closed ? DateTime(2026, 10, 3) : null,
  createdAt: DateTime(2026, 10, 1),
);

const _aewol = EntryLocation(placeName: '애월읍', lat: 33.46, lng: 126.33);

void main() {
  late _MockRepo repo;
  late _MockUseCase useCase;
  late _MockStore store;
  late _MockPicker picker;
  late _FakePlaces places;
  late List<Story> stories;

  setUpAll(() {
    registerFallbackValue(entryDraft());
    registerFallbackValue(<EntryMedia>[]);
  });

  setUp(() {
    stories = [
      _story(Story.dailyId, ''),
      _story('jeju', '제주 여행'),
      _story('busan', '부산 출장', closed: true),
    ];
    repo = _MockRepo();
    when(repo.watchStories).thenAnswer((_) => Stream.value(stories));
    when(() => repo.watchTagCounts(query: any(named: 'query'))).thenAnswer(
      (_) =>
          Stream.value([NamedCount(name: '제주', count: 2, lastUsedAt: diaryT0)]),
    );
    when(() => repo.watchPlaceCounts(query: any(named: 'query'))).thenAnswer(
      (_) => Stream.value([
        NamedCount(name: '협재 해변', count: 4, lastUsedAt: diaryT0),
      ]),
    );
    useCase = _MockUseCase();
    when(() => useCase.cancelDraft(any())).thenAnswer((_) async {});
    store = _MockStore();
    when(() => store.resolve(any())).thenAnswer((_) => File('/missing'));
    picker = _MockPicker();
    places = _FakePlaces()..location = _aewol;
    getIt
      ..registerSingleton<DiaryRepository>(repo)
      ..registerSingleton<DiaryUseCase>(useCase)
      ..registerSingleton<MediaStore>(store)
      ..registerSingleton<PlaceSource>(places)
      ..registerSingleton<MediaPicker>(picker)
      ..registerSingleton<Clock>(MutableClock(diaryT0));
  });

  tearDown(() => getIt.reset());

  /// 첫 화면 위에 작성 화면을 띄운다. 닫히면 'home' 이 보인다.
  Future<void> pump(WidgetTester tester, {String? editingId}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EntryEditorPage(editingId: editingId),
                  ),
                ),
                child: const Text('home'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
  }

  Finder timeRow() => find.byType(TimeRow);

  String timeText(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(of: timeRow(), matching: find.byType(Text)),
      )
      .map((t) => t.data)
      .join(' | ');

  testWidgets("시각 행은 '지금', 날짜를 바꾸면 날짜 문구 + 되돌리기, 되돌리면 다시 '지금'", (tester) async {
    await pump(tester);

    expect(timeText(tester), contains('지금 · 10월 10일 (토) 오전 9:00'));
    expect(find.text('올린 시각으로 되돌리기'), findsNothing);

    await tester.tap(timeRow());
    await tester.pumpAndSettle();
    await tester.tap(find.text('9'));
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    // 시각 휠 시트 — 그대로 확인.
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(timeText(tester), contains('10월 9일 (금) 오전 9:00'));
    expect(timeText(tester), isNot(contains('지금')));
    expect(find.text('올린 시각으로 되돌리기'), findsOneWidget);
    // 과거 시각 → 지금 위치 대신 장소 직접 입력칸.
    expect(find.text('애월읍'), findsNothing);
    expect(find.widgetWithText(TextField, '장소 이름'), findsOneWidget);

    await tester.tap(find.text('올린 시각으로 되돌리기'));
    await tester.pumpAndSettle();

    expect(timeText(tester), contains('지금 · 10월 10일 (토)'));
    expect(find.text('올린 시각으로 되돌리기'), findsNothing);
  });

  testWidgets('스토리 시트에는 열린 스토리만, 고르면 행이 바뀐다', (tester) async {
    await pump(tester);
    expect(find.text('스토리: 일상'), findsOneWidget);

    await tester.tap(find.text('스토리: 일상'));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('일상')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('제주 여행')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('부산 출장')),
      findsNothing,
    );

    await tester.tap(find.descendant(of: sheet, matching: find.text('제주 여행')));
    await tester.pumpAndSettle();

    expect(find.text('스토리: 제주 여행'), findsOneWidget);
  });

  testWidgets('태그 칩 추가 · 삭제 · 추천', (tester) async {
    await pump(tester);
    final tagField = find.widgetWithText(TextField, '태그 추가');

    await tester.enterText(tagField, '#Jeju ');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, '#jeju'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(InputChip, '#jeju'),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsNothing);

    await tester.tap(tagField);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ActionChip, '#제주 2'));
    await tester.tap(find.widgetWithText(ActionChip, '#제주 2'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(InputChip, '#제주'), findsOneWidget);
  });

  testWidgets('위치 ✕ 를 누르면 사라지고 장소 직접 입력, 추천을 누르면 그 이름', (tester) async {
    await pump(tester);
    expect(find.text('애월읍'), findsOneWidget);

    await tester.tap(find.byTooltip('위치 빼기'));
    await tester.pumpAndSettle();

    expect(find.text('애월읍'), findsNothing);
    final placeField = find.widgetWithText(TextField, '장소 이름');
    expect(placeField, findsOneWidget);

    await tester.tap(placeField);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, '협재 해변 4'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '협재 해변'), findsOneWidget);
  });

  testWidgets('올리기 → 입력한 기록으로 저장하고 닫힌다', (tester) async {
    when(
      () => useCase.save(any(), editingId: any(named: 'editingId')),
    ).thenAnswer(
      (inv) async => Ok(
        DiaryEntry(
          id: 'e1',
          storyId: Story.dailyId,
          body: '바다',
          occurredAt: diaryT0,
          createdAt: diaryT0,
          updatedAt: diaryT0,
          media: const [],
          tags: const [],
        ),
      ),
    );
    await pump(tester);

    await tester.enterText(
      find.widgetWithText(TextField, '오늘 있었던 일을 적어 보세요'),
      '바다',
    );
    await tester.tap(find.text('올리기'));
    await tester.pumpAndSettle();

    final draft =
        verify(
              () => useCase.save(captureAny(), editingId: null),
            ).captured.single
            as EntryDraft;
    expect(draft.body, '바다');
    expect(draft.location, _aewol);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('저장이 규칙에 걸리면 안내하고 화면에 남는다', (tester) async {
    when(
      () => useCase.save(any(), editingId: any(named: 'editingId')),
    ).thenAnswer((_) async => Err(DiaryFailure.emptyEntry.toFailure()));
    await pump(tester);

    await tester.tap(find.text('올리기'));
    await tester.pump();

    expect(find.text('글이나 사진·영상을 넣어 주세요'), findsOneWidget);
    expect(find.text('올리기'), findsOneWidget);
  });

  testWidgets('쓴 내용이 있으면 닫기 전에 묻고, 그만두면 임시 사본을 지운다', (tester) async {
    await pump(tester);
    await tester.enterText(
      find.widgetWithText(TextField, '오늘 있었던 일을 적어 보세요'),
      '쓰다 만 글',
    );

    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('작성을 그만둘까요?'), findsOneWidget);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('쓰다 만 글'), findsOneWidget);

    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('그만두기'));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    verify(() => useCase.cancelDraft(any())).called(1);
  });

  testWidgets('아무것도 안 바꿨으면 묻지 않고 닫는다', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();

    expect(find.text('작성을 그만둘까요?'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('사진·영상 추가 → 앨범에서 고른 것을 남은 칸만큼 가져온다', (tester) async {
    when(
      () => picker.pickGallery(limit: any(named: 'limit')),
    ).thenAnswer((_) async => [(path: '/picked/a.jpg', kind: MediaKind.photo)]);
    when(
      () => store.importPhoto('/picked/a.jpg'),
    ).thenAnswer((_) async => Ok(photoMedia('m1', path: 'tmp/m1.jpg')));
    await pump(tester);

    await tester.tap(find.text('사진·영상 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('앨범에서 고르기'));
    await tester.pumpAndSettle();

    verify(() => picker.pickGallery(limit: 10)).called(1);
    expect(find.byTooltip('빼기'), findsOneWidget);
  });

  testWidgets('고치기: 기록 내용을 채우고 저장 버튼', (tester) async {
    when(() => repo.entry('e1')).thenAnswer(
      (_) async => Ok(
        DiaryEntry(
          id: 'e1',
          storyId: 'jeju',
          body: '옛 글',
          occurredAt: DateTime(2026, 10, 8, 18),
          createdAt: DateTime(2026, 10, 8, 18),
          updatedAt: DateTime(2026, 10, 8, 18),
          location: const EntryLocation(placeName: '협재'),
          media: const [],
          tags: const ['바다'],
        ),
      ),
    );
    await pump(tester, editingId: 'e1');

    expect(find.text('기록 고치기'), findsOneWidget);
    expect(find.text('저장'), findsOneWidget);
    expect(find.text('옛 글'), findsOneWidget);
    expect(find.text('스토리: 제주 여행'), findsOneWidget);
    expect(find.widgetWithText(TextField, '협재'), findsOneWidget);
    expect(find.widgetWithText(InputChip, '#바다'), findsOneWidget);
    expect(timeText(tester), contains('10월 8일 (목) 오후 6:00'));
    expect(timeText(tester), isNot(contains('지금')));
  });
}
