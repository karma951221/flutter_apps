import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:pawlog/presentation/theme/pawlog_theme.dart';

/// [disableAnimations] 는 시스템 '애니메이션 줄이기' 를 흉내 낸다. 진행 배너의 점멸처럼
/// 끝없이 반복하는 연출이 있는 화면은 이것을 켜야 `pumpAndSettle` 이 끝난다.
Future<void> pumpApp(
  WidgetTester tester,
  Widget home, {
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PawlogTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: disableAnimations
          ? (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            )
          : null,
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}
