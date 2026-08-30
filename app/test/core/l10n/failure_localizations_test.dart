import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/error/failure_code.dart';
import 'package:daylog/core/l10n/failure_localizations.dart';
import 'package:daylog/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpFailure(
    WidgetTester tester,
    Failure failure, {
    Locale locale = const Locale('en'),
  }) => tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Text(failure.localizedMessage(context)),
      ),
    ),
  );

  testWidgets('failureCode가 있으면 선택 언어의 문구를 쓴다', (tester) async {
    await pumpFailure(
      tester,
      const Failure.validation(
        message: '이미 신고한 항목입니다',
        failureCode: FailureCode.reportAlreadySubmitted,
      ),
    );

    expect(find.text("You've already reported this item"), findsOneWidget);
  });

  testWidgets('코드가 없는 서버 원문은 그대로 보여준다', (tester) async {
    await pumpFailure(
      tester,
      const Failure.server(message: 'upstream diagnostic'),
    );

    expect(find.text('upstream diagnostic'), findsOneWidget);
  });

  testWidgets('코드와 원문이 없으면 실패 종류의 공통 문구를 쓴다', (tester) async {
    await pumpFailure(tester, const Failure.network());

    expect(find.text("Can't connect to the network"), findsOneWidget);
  });
}
