import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

void main() {
  testWidgets('가려서 시작하고 눈 아이콘으로 보기 · 가리기를 바꾼다', (tester) async {
    final controller = TextEditingController(text: 'sk-secret');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ObscuredKeyField(
            controller: controller,
            toggleKey: const Key('toggle'),
          ),
        ),
      ),
    );

    EditableText field() => tester.widget(find.byType(EditableText));
    expect(field().obscureText, isTrue);
    expect(field().autocorrect, isFalse);
    expect(find.byTooltip('보기'), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggle')));
    await tester.pump();
    expect(field().obscureText, isFalse);
    expect(find.byTooltip('숨기기'), findsOneWidget);
  });
}
