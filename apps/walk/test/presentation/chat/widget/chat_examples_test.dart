import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/suggest/chat_suggester.dart';
import 'package:walk/domain/chat/suggest/chat_suggestions.dart';
import 'package:walk/presentation/chat/widget/chat_examples.dart';

import '../../../support/fake_chat_suggester.dart';

ChatSuggestions _suggestions(List<String> questions) => ChatSuggestions(
  questions: questions,
  generatedAt: DateTime(2026, 11, 17),
  basedOnAskedAt: DateTime(2026, 11, 17),
);

void main() {
  late FakeChatSuggester suggester;
  late List<String> asked;

  setUp(() {
    suggester = FakeChatSuggester();
    asked = [];
    getIt.registerSingleton<ChatSuggester>(suggester);
  });
  tearDown(() => getIt.reset());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ChatSuggestionArea(onAsk: asked.add)),
      ),
    );
    await tester.pump();
  }

  testWidgets('추천이 없으면 기본 예시 질문 3개, 안내 없음', (tester) async {
    await pump(tester);

    expect(find.byType(ActionChip), findsNWidgets(3));
    expect(find.text('어제 뭐 했어?'), findsOneWidget);
    expect(find.text('최근 질문으로 만든 추천'), findsNothing);
  });

  testWidgets('추천이 있으면 그 질문들과 안내, 누르면 바로 보낸다', (tester) async {
    suggester.current = _suggestions([
      '지난주 걸음 수는?',
      '이번 달 일기 요약',
      '요즘 몇 시에 자?',
      '어제 간 곳?',
    ]);
    await pump(tester);

    expect(find.byType(ActionChip), findsNWidgets(4));
    expect(find.text('최근 질문으로 만든 추천'), findsOneWidget);
    await tester.tap(find.text('이번 달 일기 요약'));
    expect(asked, ['이번 달 일기 요약']);
  });

  testWidgets('대화를 모두 지웠으면 지난 추천 대신 기본 질문, 새로 만들기 없음', (tester) async {
    suggester
      ..questions = false
      ..current = _suggestions(['지운 대화 추천?', '둘?', '셋?']);
    await pump(tester);

    expect(find.text('지운 대화 추천?'), findsNothing);
    expect(find.text('어제 뭐 했어?'), findsOneWidget);
    expect(find.byTooltip('추천 질문 새로 만들기'), findsNothing);
  });

  testWidgets('만들 수 없으면(키 · 동의 없음) 새로 만들기를 숨긴다', (tester) async {
    suggester.ready = false;
    await pump(tester);

    expect(find.byTooltip('추천 질문 새로 만들기'), findsNothing);
  });

  testWidgets('새로 만들기: 도는 동안 진행 표시, 끝나면 새 추천', (tester) async {
    suggester
      ..next = _suggestions(['새 하나?', '새 둘?', '새 셋?'])
      ..pending = Completer();
    await pump(tester);

    await tester.tap(find.byTooltip('추천 질문 새로 만들기'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(suggester.refreshCalls, 1);

    suggester.pending!.complete(SuggestOutcome.generated);
    await tester.pump();
    await tester.pump();
    expect(find.text('새 둘?'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('새로 만들기가 실패하면 스낵바로 알린다', (tester) async {
    suggester.refreshOutcome = SuggestOutcome.failed;
    await pump(tester);

    await tester.tap(find.byTooltip('추천 질문 새로 만들기'));
    await tester.pump();
    await tester.pump();

    expect(find.text('추천 질문을 만들지 못했어요'), findsOneWidget);
  });
}
