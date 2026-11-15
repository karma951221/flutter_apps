import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/diary/prefs_diary_preferences.dart';
import 'package:walk/domain/chat/chat_settings.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/diary/draft/draft_context.dart';
import 'package:walk/domain/diary/draft/draft_style.dart';
import 'package:walk/domain/diary/draft/draft_writer.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/repository/diary_preferences.dart';
import 'package:walk/presentation/diary/draft/draft_sheet.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_chat_settings.dart';

class _Writer extends Mock implements DraftWriter {}

void main() {
  late _Writer writer;
  late PrefsDiaryPreferences prefs;
  late FakeChatSettings settings;

  /// 시트가 닫히며 돌려준 값. 아직 안 닫혔으면 [open] 그대로.
  late Object? result;
  const open = #open;
  late int settingsOpened;
  final contexts = <String>[];

  setUpAll(() {
    registerFallbackValue(DraftContext(memo: '', occurredAt: DateTime(2026)));
    registerFallbackValue(DraftStyle.diary);
  });

  setUp(() async {
    result = open;
    settingsOpened = 0;
    contexts.clear();
    writer = _Writer();
    SharedPreferences.setMockInitialValues({});
    prefs = PrefsDiaryPreferences(await SharedPreferences.getInstance());
    await prefs.setDraftStyle(DraftStyle.polite);
    settings = FakeChatSettings('sk-ant-test')
      ..consentedVendor = ChatVendor.anthropic;
    when(writer.availability).thenAnswer(
      (_) async => const DraftAvailability.ready(ChatVendor.anthropic),
    );
    when(writer.cancel).thenAnswer((_) {});
    getIt
      ..registerSingleton<DraftWriter>(writer)
      ..registerSingleton<DiaryPreferences>(prefs)
      ..registerSingleton<ChatSettings>(settings);
  });
  tearDown(() => getIt.reset());

  void answer(Future<DraftResult> Function() result) => when(
    () => writer.write(
      any(),
      style: any(named: 'style'),
      photos: any(named: 'photos'),
      includePhotos: any(named: 'includePhotos'),
    ),
  ).thenAnswer((_) => result());

  Future<void> show(
    WidgetTester tester, {
    String memo = '산책',
    List<EntryMedia> photos = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDraftSheet(
                  context,
                  initialMemo: memo,
                  contextFor: (memo) {
                    contexts.add(memo);
                    return DraftContext(
                      memo: memo,
                      occurredAt: DateTime(2026, 11, 15),
                    );
                  },
                  photos: photos,
                  onOpenChatSettings: () => settingsOpened++,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  bool chipSelected(WidgetTester tester, DraftStyle style) => tester
      .widget<ChoiceChip>(find.byKey(Key('draft-style-${style.name}')))
      .selected;

  Finder photoSwitch() => find.descendant(
    of: find.byKey(const Key('draft-photos')),
    matching: find.byType(Switch),
  );

  testWidgets('메모는 넘겨준 글로 채운다', (tester) async {
    await show(tester, memo: '성수동 카페');

    final field = tester.widget<TextField>(find.byKey(const Key('draft-memo')));
    expect(field.controller?.text, '성수동 카페');
  });

  testWidgets('문체 칩은 설정의 기본값으로 시작하고 바꿔도 설정은 그대로', (tester) async {
    await show(tester);

    expect(chipSelected(tester, DraftStyle.polite), isTrue);
    expect(chipSelected(tester, DraftStyle.diary), isFalse);

    await tester.tap(find.byKey(const Key('draft-style-memo')));
    await tester.pumpAndSettle();

    expect(chipSelected(tester, DraftStyle.memo), isTrue);
    expect(chipSelected(tester, DraftStyle.polite), isFalse);
    expect(prefs.draftStyle, DraftStyle.polite);
  });

  testWidgets('사진이 없으면 사진 스위치가 없다', (tester) async {
    await show(tester, photos: [videoMedia('v1')]);

    expect(find.byKey(const Key('draft-photos')), findsNothing);
  });

  testWidgets('사진이 있으면 스위치는 설정 기본값으로 시작하고, 바꿔도 설정은 그대로', (tester) async {
    await prefs.setDraftIncludePhotos(true);
    await show(tester, photos: [photoMedia('p1')]);

    expect(tester.widget<Switch>(photoSwitch()).value, isTrue);
    expect(find.text('메모 · 시각 · 장소 이름과 사진이 Claude로 보내져요.'), findsOneWidget);

    await tester.tap(photoSwitch());
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(photoSwitch()).value, isFalse);
    expect(find.text('메모 · 시각 · 장소 이름이 Claude로 보내져요.'), findsOneWidget);
    expect(prefs.draftIncludePhotos, isTrue);
  });

  testWidgets('키가 없으면 안내와 설정 열기 — 초안 쓰기 버튼이 없다', (tester) async {
    when(
      writer.availability,
    ).thenAnswer((_) async => const DraftAvailability.noKey());
    await show(tester);

    expect(find.text('물어보기 설정에서 키를 넣으면 쓸 수 있어요.'), findsOneWidget);
    expect(find.byKey(const Key('draft-write')), findsNothing);

    await tester.tap(find.text('설정 열기'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(settingsOpened, 1);
  });

  testWidgets('성공하면 고친 메모로 부르고 초안을 들고 닫힌다', (tester) async {
    answer(() async => const DraftResult.text('성수동 카페에서 책을 읽었어요.'));
    await show(tester);

    await tester.enterText(find.byKey(const Key('draft-memo')), '성수동 카페 독서');
    await tester.tap(find.byKey(const Key('draft-write')));
    await tester.pumpAndSettle();

    expect(contexts, ['성수동 카페 독서']);
    expect(result, '성수동 카페에서 책을 읽었어요.');
    verify(
      () => writer.write(
        any(),
        style: DraftStyle.polite,
        photos: const [],
        includePhotos: false,
      ),
    ).called(1);
  });

  testWidgets('실패하면 시트에 이유를 보이고 닫히지 않는다', (tester) async {
    answer(() async => const DraftResult.failed(ChatFailure.network));
    await show(tester);

    await tester.tap(find.byKey(const Key('draft-write')));
    await tester.pumpAndSettle();

    expect(result, open);
    expect(find.text('연결이 끊겼어요. 다시 물어봐 주세요'), findsOneWidget);
    expect(find.text('닫고 직접 써도 돼요.'), findsOneWidget);
    expect(find.byKey(const Key('draft-write')), findsOneWidget);
  });

  testWidgets('쓰는 중에는 진행 표시와 멈추기 — 누르면 멈춘다', (tester) async {
    final pending = Completer<DraftResult>();
    answer(() => pending.future);
    when(writer.cancel).thenAnswer((_) {
      if (!pending.isCompleted) pending.complete(const DraftResult.cancelled());
    });
    await show(tester);

    await tester.tap(find.byKey(const Key('draft-write')));
    await tester.pump();

    expect(find.text('초안을 쓰는 중이에요…'), findsOneWidget);
    expect(find.byKey(const Key('draft-write')), findsNothing);

    await tester.tap(find.text('멈추기'));
    await tester.pumpAndSettle();

    verify(writer.cancel).called(1);
    expect(result, open);
    expect(find.byKey(const Key('draft-write')), findsOneWidget);
  });

  testWidgets('동의가 없으면 전송 동의를 묻고, 동의하면 기록하고 쓴다', (tester) async {
    settings.consentedVendor = null;
    when(writer.availability).thenAnswer(
      (_) async => settings.consentedVendor == ChatVendor.anthropic
          ? const DraftAvailability.ready(ChatVendor.anthropic)
          : const DraftAvailability.needsConsent(ChatVendor.anthropic),
    );
    answer(() async => const DraftResult.text('글'));
    await show(tester);

    await tester.tap(find.byKey(const Key('draft-write')));
    await tester.pumpAndSettle();
    expect(find.textContaining('연결한 AI(Claude)로 전송돼요'), findsOneWidget);

    await tester.tap(find.text('동의하고 시작'));
    await tester.pumpAndSettle();

    expect(settings.consentedVendor, ChatVendor.anthropic);
    expect(result, '글');
  });

  testWidgets('동의를 취소하면 쓰지 않고 시트에 남는다', (tester) async {
    settings.consentedVendor = null;
    when(writer.availability).thenAnswer(
      (_) async => const DraftAvailability.needsConsent(ChatVendor.anthropic),
    );
    await show(tester);

    await tester.tap(find.byKey(const Key('draft-write')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(settings.consentedVendor, isNull);
    expect(result, open);
    verifyNever(
      () => writer.write(
        any(),
        style: any(named: 'style'),
        photos: any(named: 'photos'),
        includePhotos: any(named: 'includePhotos'),
      ),
    );
  });
}
