import 'package:daylog/design_system/widget/app_list_footer.dart';
import 'package:daylog/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool isLoadingMore,
    required bool canLoadMore,
  }) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AppListFooter(
          isLoadingMore: isLoadingMore,
          canLoadMore: canLoadMore,
        ),
      ),
    ),
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
}
