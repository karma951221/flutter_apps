import 'package:design_system/design_system.dart';
import 'package:l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool isLoadingMore,
    required bool canLoadMore,
    bool animate = false,
    bool disableAnimations = false,
  }) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: ListView(
            children: [
              AppListFooter(
                isLoadingMore: isLoadingMore,
                canLoadMore: canLoadMore,
                animate: animate,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Finder inFooter(Type type) => find.descendant(
    of: find.byType(AppListFooter),
    matching: find.byType(type),
  );

  testWidgets('다음 페이지를 읽는 동안 진행 표시를 보여준다', (tester) async {
    await pump(tester, isLoadingMore: true, canLoadMore: true);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('모두 확인했습니다'), findsNothing);
  });

  testWidgets('다음 페이지가 남아 있으면 아무것도 그리지 않는다', (tester) async {
    await pump(tester, isLoadingMore: false, canLoadMore: true);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('모두 확인했습니다'), findsNothing);
  });

  testWidgets('마지막 페이지면 목록의 끝을 알린다', (tester) async {
    await pump(tester, isLoadingMore: false, canLoadMore: false);

    expect(find.text('모두 확인했습니다'), findsOneWidget);
  });

  testWidgets('기본값이면 전환 위젯 없이 바로 바뀐다', (tester) async {
    await pump(tester, isLoadingMore: true, canLoadMore: true);
    await pump(tester, isLoadingMore: false, canLoadMore: false);

    expect(inFooter(AnimatedSwitcher), findsNothing);
    expect(inFooter(AnimatedSize), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('모두 확인했습니다'), findsOneWidget);
  });

  testWidgets('animate 면 상태 사이를 크로스페이드하고 끝나면 새 상태만 남는다', (tester) async {
    await pump(tester, isLoadingMore: true, canLoadMore: true, animate: true);
    await pump(tester, isLoadingMore: false, canLoadMore: false, animate: true);

    expect(inFooter(AnimatedSize), findsOneWidget);
    expect(inFooter(AnimatedSwitcher), findsOneWidget);
    // 전환 중에는 나가는 스피너와 들어오는 끝 안내가 함께 있다.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('모두 확인했습니다'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('모두 확인했습니다'), findsOneWidget);
  });

  testWidgets('animate 면 빈 칸으로 갈 때 높이가 0 까지 줄어든다', (tester) async {
    await pump(tester, isLoadingMore: false, canLoadMore: false, animate: true);
    final before = tester.getSize(find.byType(AppListFooter)).height;
    expect(before, greaterThan(0));

    await pump(tester, isLoadingMore: false, canLoadMore: true, animate: true);
    await tester.pumpAndSettle();

    // 높이가 0 이면 목록이 화면 밖으로 보므로 skipOffstage 를 끈다.
    final footer = find.byType(AppListFooter, skipOffstage: false);
    expect(tester.getSize(footer).height, 0);
    expect(find.text('모두 확인했습니다'), findsNothing);
  });

  testWidgets('애니메이션 줄이기면 animate 여도 바로 바뀐다', (tester) async {
    await pump(
      tester,
      isLoadingMore: true,
      canLoadMore: true,
      animate: true,
      disableAnimations: true,
    );
    await pump(
      tester,
      isLoadingMore: false,
      canLoadMore: false,
      animate: true,
      disableAnimations: true,
    );

    expect(inFooter(AnimatedSwitcher), findsNothing);
    expect(inFooter(AnimatedSize), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('모두 확인했습니다'), findsOneWidget);
  });
}
