import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/presentation/settings/widget/step_goal_sheet.dart';

void main() {
  testWidgets('슬라이더는 2,000~30,000 을 1,000 단위로 고르고 저장하면 값을 돌려준다', (
    tester,
  ) async {
    int? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await StepGoalSheet.show(context, initial: 10000),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final slider = tester.widget<Slider>(
      find.byKey(const Key('step-goal-slider')),
    );
    expect(slider.min, 2000);
    expect(slider.max, 30000);
    expect(slider.divisions, 28);
    expect(slider.value, 10000);

    slider.onChanged!(12000);
    await tester.pump();
    expect(find.text('12,000 걸음'), findsOneWidget);
    await tester.tap(find.byKey(const Key('step-goal-save')));
    await tester.pumpAndSettle();

    expect(result, 12000);
  });
}
