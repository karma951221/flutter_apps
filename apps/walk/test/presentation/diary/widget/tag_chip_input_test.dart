import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/diary/entity/named_count.dart';
import 'package:walk/domain/diary/entity/tag_name.dart';
import 'package:walk/presentation/diary/widget/tag_chip_input.dart';

import '../../../support/diary_fixtures.dart';

void main() {
  late List<String> tags;
  late List<String> added;
  late List<String> queries;
  late List<NamedCount> suggestions;

  setUp(() {
    tags = [];
    added = [];
    queries = [];
    suggestions = [
      NamedCount(name: '제주', count: 3, lastUsedAt: diaryT0),
      NamedCount(name: '바다', count: 1, lastUsedAt: diaryT0),
    ];
  });

  /// 부모(cubit) 처럼 정규화 · 중복 무시를 해 칩을 다시 그린다.
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => TagChipInput(
            tags: tags,
            onAdd: (raw) => setState(() {
              added.add(raw);
              final name = TagName.normalize(raw);
              if (name != null && !tags.contains(name)) tags = [...tags, name];
            }),
            onRemove: (name) => setState(
              () => tags = [
                for (final t in tags)
                  if (t != name) t,
              ],
            ),
            suggestionsFor: (query) {
              queries.add(query);
              return Stream.value([
                for (final s in suggestions)
                  if (s.name.contains(TagName.searchKey(query))) s,
              ]);
            },
          ),
        ),
      ),
    ),
  );

  Finder chip(String label) => find.widgetWithText(InputChip, label);

  testWidgets('입력 후 완료하면 칩이 되고 입력칸은 비워진다', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), '#Jeju');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(added, ['#Jeju']);
    expect(chip('#jeju'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets("띄어쓰기로도 칩을 만들고, '#Jeju' 뒤 'jeju ' 는 칩 하나", (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), '#Jeju ');
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'jeju ');
    await tester.pump();

    expect(added, ['#Jeju', 'jeju']);
    expect(find.byType(InputChip), findsOneWidget);
  });

  testWidgets('칩의 ✕ 를 누르면 사라진다', (tester) async {
    tags = ['제주', '바다'];
    await pump(tester);

    await tester.tap(
      find.descendant(of: chip('#제주'), matching: find.byIcon(Icons.close)),
    );
    await tester.pump();

    expect(chip('#제주'), findsNothing);
    expect(chip('#바다'), findsOneWidget);
  });

  testWidgets('입력칸을 누르면 기존 태그를 추천하고, 누르면 칩이 된다', (tester) async {
    tags = ['바다'];
    await pump(tester);
    expect(find.byType(ActionChip), findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    // 이미 칩인 '바다' 는 추천하지 않는다.
    expect(find.widgetWithText(ActionChip, '#제주 3'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '#바다 1'), findsNothing);

    await tester.tap(find.widgetWithText(ActionChip, '#제주 3'));
    await tester.pumpAndSettle();

    expect(added, ['제주']);
    expect(chip('#제주'), findsOneWidget);
  });

  testWidgets('입력하는 글자로 추천을 다시 찾는다', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '바');
    await tester.pumpAndSettle();

    expect(queries.last, '바');
    expect(find.widgetWithText(ActionChip, '#바다 1'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '#제주 3'), findsNothing);
  });
}
