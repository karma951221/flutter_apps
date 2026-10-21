import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/presentation/alarm/widget/alarm_kind_sheet.dart';

void main() {
  /// 시트를 띄우고, 닫힐 때의 결과를 [results] 에 모은다.
  Future<List<AlarmKind?>> pump(
    WidgetTester tester, {
    Locale locale = const Locale('ko'),
    Size size = const Size(800, 1600),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final results = <AlarmKind?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                results.add(await AlarmKindSheet.show(context)),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('손잡이 · 제목 · 두 행(제목 · 설명)', (tester) async {
    await pump(tester);

    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle,
      isTrue,
    );
    expect(find.text('어떤 알람을 만들까요'), findsOneWidget);
    expect(find.text('한 번'), findsOneWidget);
    expect(find.text('지금부터 얼마 뒤에 울려요'), findsOneWidget);
    expect(find.text('반복'), findsOneWidget);
    expect(find.text('정한 요일마다 울려요'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('한 번')).dy,
      lessThan(tester.getTopLeft(find.text('반복')).dy),
    );
  });

  testWidgets('한 번을 고르면 oneShot 으로 닫힌다', (tester) async {
    final results = await pump(tester);

    await tester.tap(find.text('한 번'));
    await tester.pumpAndSettle();

    expect(results, [AlarmKind.oneShot]);
    expect(find.text('어떤 알람을 만들까요'), findsNothing);
  });

  testWidgets('반복을 고르면 repeating 으로 닫힌다', (tester) async {
    final results = await pump(tester);

    await tester.tap(find.text('정한 요일마다 울려요'));
    await tester.pumpAndSettle();

    expect(results, [AlarmKind.repeating]);
  });

  testWidgets('그냥 닫으면 null', (tester) async {
    final results = await pump(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(results, [null]);
  });

  for (final locale in const [Locale('ko'), Locale('en'), Locale('ja')]) {
    testWidgets('320dp 에서 넘치지 않는다 ($locale)', (tester) async {
      await pump(tester, locale: locale, size: const Size(320, 640));

      expect(tester.takeException(), isNull);
    });
  }
}
