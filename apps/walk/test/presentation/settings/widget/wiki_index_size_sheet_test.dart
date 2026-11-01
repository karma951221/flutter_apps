import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/chat_history_settings.dart';
import 'package:walk/presentation/settings/widget/wiki_index_size_sheet.dart';

void main() {
  final results = <WikiIndexSize?>[];

  setUp(results.clear);

  Future<void> open(
    WidgetTester tester, {
    WikiIndexSize current = WikiIndexSize.standard,
    int noteCount = 120,
    int indexChars = 5432,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
                onPressed: () async => results.add(
                  await showWikiIndexSizeSheet(
                    context,
                    current: current,
                    noteCount: noteCount,
                    indexChars: indexChars,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder row(WikiIndexSize size) => find.byKey(Key('wiki-size-${size.name}'));

  Finder inRow(WikiIndexSize size, Finder matching) =>
      find.descendant(of: row(size), matching: matching);

  testWidgets('네 단계와 상한 문구, 지금 단계 표시', (tester) async {
    await open(tester, current: WikiIndexSize.large);

    expect(find.text('위키 색인 크기'), findsOneWidget);
    expect(inRow(WikiIndexSize.small, find.text('작게')), findsOneWidget);
    expect(inRow(WikiIndexSize.standard, find.text('기본')), findsOneWidget);
    expect(inRow(WikiIndexSize.large, find.text('크게')), findsOneWidget);
    expect(inRow(WikiIndexSize.all, find.text('모두')), findsOneWidget);

    expect(
      inRow(
        WikiIndexSize.small,
        find.text('최근 50개 · 2,000자까지\n질문마다 보내는 양이 가장 적어요'),
      ),
      findsOneWidget,
    );
    expect(
      inRow(WikiIndexSize.standard, find.text('최근 150개 · 6,000자까지')),
      findsOneWidget,
    );
    expect(
      inRow(
        WikiIndexSize.large,
        find.text('최근 300개 · 12,000자까지\n메모가 많을 때. 질문마다 토큰이 늘어요'),
      ),
      findsOneWidget,
    );
    expect(
      inRow(
        WikiIndexSize.all,
        find.text('개수 제한 없음 · 30,000자까지\n안전 상한을 넘는 부분은 잘려요'),
      ),
      findsOneWidget,
    );

    expect(
      inRow(WikiIndexSize.large, find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('지금 위키 n개 · 색인 약 m자', (tester) async {
    await open(tester);

    expect(find.text('지금 위키 120개 · 색인 약 5,432자'), findsOneWidget);
  });

  testWidgets('고르면 그 값으로 닫힌다', (tester) async {
    await open(tester);

    await tester.tap(row(WikiIndexSize.all));
    await tester.pumpAndSettle();

    expect(results, [WikiIndexSize.all]);
    expect(row(WikiIndexSize.all), findsNothing);
  });
}
