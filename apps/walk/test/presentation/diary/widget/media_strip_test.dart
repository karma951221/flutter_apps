import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/presentation/diary/widget/media_strip.dart';

void main() {
  Widget app({required bool importing}) => MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MediaStrip(
        media: const [],
        importing: importing,
        onAdd: (_) {},
        onRemove: (_) {},
        onReorder: (_, _) {},
      ),
    ),
  );

  /// 보이는 버튼(가져오는 중이면 진행 표시를 품은 것)의 몸통 — 테두리가 그려지는 Material.
  Rect buttonBody(WidgetTester tester, {required bool importing}) {
    final button = importing
        ? find.ancestor(
            of: find.byType(CircularProgressIndicator),
            matching: find.byType(OutlinedButton),
          )
        : find.byType(OutlinedButton);
    return tester.getRect(
      find.descendant(of: button, matching: find.byType(Material)).first,
    );
  }

  testWidgets('가져오는 중: 진행 표시가 버튼 안에 다 들어가고 버튼 크기는 그대로', (tester) async {
    await tester.pumpWidget(app(importing: false));
    final idle = buttonBody(tester, importing: false);

    await tester.pumpWidget(app(importing: true));
    final busy = buttonBody(tester, importing: true);
    final spinner = tester.getRect(find.byType(CircularProgressIndicator));

    expect(busy.size, idle.size);
    expect(busy.contains(spinner.topLeft), isTrue, reason: '$busy ⊉ $spinner');
    expect(
      busy.contains(spinner.bottomRight - const Offset(0.01, 0.01)),
      isTrue,
      reason: '$busy ⊉ $spinner',
    );
    // 테두리에 붙지 않게 위아래로 여백이 있다.
    expect(spinner.top - busy.top, greaterThan(0));
    expect(busy.bottom - spinner.bottom, greaterThan(0));
  });
}
