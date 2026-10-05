import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:pawlog/presentation/theme/pawlog_theme.dart';

Future<void> pumpApp(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PawlogTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}
