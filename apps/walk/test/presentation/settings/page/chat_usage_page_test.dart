import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/chat_usage_log.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/entity/chat_usage_summary.dart';
import 'package:walk/domain/chat/repository/chat_usage_repository.dart';
import 'package:walk/presentation/settings/page/chat_usage_page.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_chat_history.dart';

final _november = ChatUsageMonth(
  year: 2026,
  month: 11,
  totals: const ChatUsageTotals(
    questions: 12,
    inputTokens: 123456,
    outputTokens: 7890,
    cacheReadTokens: 1234,
  ),
  rows: [
    ChatUsageModelRow(
      vendor: ChatVendor.values.first,
      model: 'model-a',
      purpose: ChatUsagePurpose.chat,
      questions: 12,
      inputTokens: 120000,
      outputTokens: 7000,
    ),
    ChatUsageModelRow(
      vendor: ChatVendor.values.first,
      model: 'model-b',
      purpose: ChatUsagePurpose.wikiDistill,
      questions: 0,
      inputTokens: 3456,
      outputTokens: 890,
    ),
  ],
  wiki: const ChatUsageWikiStats(
    questions: 12,
    avgIndexNotes: 23.5,
    avgIndexChars: 1234.4,
    questionsWithReadWiki: 5,
  ),
);

final _october = ChatUsageMonth(
  year: 2026,
  month: 10,
  totals: const ChatUsageTotals(
    questions: 5,
    inputTokens: 5555,
    outputTokens: 444,
    cacheReadTokens: 0,
  ),
  rows: [
    ChatUsageModelRow(
      vendor: ChatVendor.values.first,
      model: 'model-a',
      purpose: ChatUsagePurpose.chat,
      questions: 5,
      inputTokens: 5555,
      outputTokens: 444,
    ),
  ],
);

void main() {
  late FakeChatUsageRepository usage;

  setUp(() {
    usage = FakeChatUsageRepository({
      (2026, 11): _november,
      (2026, 10): _october,
    });
    getIt
      ..registerSingleton<Clock>(MutableClock(DateTime(2026, 11, 15)))
      ..registerSingleton<ChatUsageRepository>(usage);
  });
  tearDown(() => getIt.reset());

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ChatUsagePage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  String trailingOf(WidgetTester tester, String key) {
    final tile = tester.widget<AppListTile>(find.byKey(Key('chat-usage-$key')));
    return (tile.trailing! as Text).data!;
  }

  testWidgets('이번 달 합계 네 줄과 모델별 줄(1,234 처럼 자리 구분)', (tester) async {
    await pump(tester);

    expect(find.text('2026년 11월'), findsOneWidget);
    expect(trailingOf(tester, 'questions'), '12');
    expect(trailingOf(tester, 'input'), '123,456');
    expect(trailingOf(tester, 'output'), '7,890');
    expect(trailingOf(tester, 'cache-read'), '1,234');
    expect(find.text('모델별'), findsOneWidget);
    expect(find.textContaining('model-a'), findsOneWidget);
    expect(find.text('질문 12 · 입력 120,000 · 출력 7,000'), findsOneWidget);
  });

  testWidgets("wikiDistill 줄은 '위키 정리'가 붙는다", (tester) async {
    await pump(tester);

    final wiki = find.textContaining('model-b');
    expect(wiki, findsOneWidget);
    expect((tester.widget<Text>(wiki).data!).endsWith(' · 위키 정리'), isTrue);
    expect(find.textContaining('model-a · 위키 정리'), findsNothing);
  });

  testWidgets('‹ 를 누르면 지난 달 숫자', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip('지난 달'));
    await tester.pumpAndSettle();

    expect(find.text('2026년 10월'), findsOneWidget);
    expect(trailingOf(tester, 'input'), '5,555');
    final next = tester.widget<IconButton>(
      find.byKey(const Key('chat-usage-next')),
    );
    expect(next.onPressed, isNotNull);
  });

  testWidgets('빈 달이면 빈 안내와 달 줄', (tester) async {
    usage.months.remove((2026, 11));
    await pump(tester);

    expect(find.text('이 달에는 사용 기록이 없어요'), findsOneWidget);
    expect(find.text('2026년 11월'), findsOneWidget);
    expect(find.byTooltip('지난 달'), findsOneWidget);
    expect(find.byKey(const Key('chat-usage-input')), findsNothing);
  });

  testWidgets('금액 문구 없이 콘솔 안내 한 줄', (tester) async {
    await pump(tester);

    expect(find.textContaining('콘솔에서 확인'), findsOneWidget);
    expect(find.textContaining(r'$'), findsNothing);
    expect(find.textContaining('원'), findsNothing);
  });

  testWidgets('사용량 기록 지우기는 확인 뒤에만', (tester) async {
    await pump(tester);

    Future<void> openClear() async {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('사용량 기록 지우기'));
      await tester.pumpAndSettle();
    }

    await openClear();
    expect(find.text('사용량 기록을 모두 지울까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(usage.deleteAllCalls, 0);
    expect(trailingOf(tester, 'input'), '123,456');

    await openClear();
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('삭제')),
    );
    await tester.pumpAndSettle();
    expect(usage.deleteAllCalls, 1);
    expect(find.text('이 달에는 사용 기록이 없어요'), findsOneWidget);
  });

  testWidgets('지우기가 실패하면 오류 스낵바', (tester) async {
    usage.failDeleteAll = true;
    await pump(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('사용량 기록 지우기'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('삭제')),
    );
    await tester.pumpAndSettle();

    expect(find.text('사용량 기록을 지우지 못했어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets("위키 절에 평균 색인 · 'n / m'", (tester) async {
    await pump(tester);

    expect(find.text('위키'), findsOneWidget);
    expect(find.text('질문당 평균 색인'), findsOneWidget);
    expect(trailingOf(tester, 'wiki-index'), '23.5개 · 1,234자');
    expect(find.text('read_wiki 를 부른 질문'), findsOneWidget);
    expect(trailingOf(tester, 'wiki-read'), '5 / 12');
  });

  testWidgets('질문이 없으면 위키 절이 없다', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('chat-usage-prev')));
    await tester.pumpAndSettle();

    expect(find.text('2026년 10월'), findsOneWidget);
    expect(find.text('위키'), findsNothing);
    expect(find.byKey(const Key('chat-usage-wiki-index')), findsNothing);
    expect(find.byKey(const Key('chat-usage-wiki-read')), findsNothing);
  });
}
