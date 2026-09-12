import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daylog/design_system/widget/app_overflow_menu.dart';
import 'package:daylog/l10n/app_localizations.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('항목이 없으면 아무것도 그리지 않는다', (tester) async {
    await tester.pumpWidget(
      wrap(AppOverflowMenu<String>(items: const [], onSelected: (_) {})),
    );

    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('탭하면 항목이 뜬다', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppOverflowMenu<String>(
          items: const [
            AppOverflowMenuItem(value: 'edit', label: '수정'),
            AppOverflowMenuItem(value: 'delete', label: '삭제'),
          ],
          onSelected: (_) {},
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('수정'), findsOneWidget);
    expect(find.text('삭제'), findsOneWidget);
  });

  testWidgets('선택하면 값이 온다', (tester) async {
    String? selected;

    await tester.pumpWidget(
      wrap(
        AppOverflowMenu<String>(
          items: const [
            AppOverflowMenuItem(value: 'edit', label: '수정'),
            AppOverflowMenuItem(value: 'delete', label: '삭제'),
          ],
          onSelected: (value) => selected = value,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(selected, 'delete');
  });

  testWidgets('enabled 가 false 면 탭해도 메뉴가 열리지 않는다', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppOverflowMenu<String>(
          enabled: false,
          items: const [
            AppOverflowMenuItem(value: 'edit', label: '수정'),
            AppOverflowMenuItem(value: 'delete', label: '삭제'),
          ],
          onSelected: (_) {},
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('수정'), findsNothing);
    expect(find.text('삭제'), findsNothing);
  });

  testWidgets('destructive 항목은 error 색으로 그린다', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppOverflowMenu<String>(
          items: const [
            AppOverflowMenuItem(value: 'edit', label: '수정'),
            AppOverflowMenuItem(
              value: 'delete',
              label: '삭제',
              isDestructive: true,
            ),
          ],
          onSelected: (_) {},
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    final context = tester.element(find.byIcon(Icons.more_vert));
    final scheme = Theme.of(context).colorScheme;

    final deleteText = tester.widget<Text>(find.text('삭제'));
    expect(deleteText.style?.color, scheme.error);

    final editText = tester.widget<Text>(find.text('수정'));
    expect(editText.style?.color, isNot(scheme.error));
  });
}
