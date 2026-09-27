import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/clock.dart';
import 'package:walk/presentation/alarm/page/alarm_ringing_page.dart';

class _MockUseCase extends Mock implements AlarmUseCase {}

class _FixedClock extends Clock {
  @override
  DateTime now() => DateTime(2026, 9, 28, 7, 0, 5);
}

void main() {
  late _MockUseCase useCase;

  setUp(() {
    useCase = _MockUseCase();
    when(() => useCase.snooze(100)).thenAnswer((_) async {});
    when(() => useCase.stop(100)).thenAnswer((_) async {});
    getIt
      ..registerSingleton<AlarmUseCase>(useCase)
      ..registerSingleton<Clock>(_FixedClock());
  });
  tearDown(getIt.reset);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AlarmRingingPage(packageId: 100)),
            ),
            child: const Text('home'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
  }

  testWidgets('현재 시각과 라벨을 보이고, 뒤로가기로 닫히지 않는다', (tester) async {
    when(() => useCase.findByPackageId(100))
        .thenAnswer((_) async => const Alarm(id: 1, hour: 7, minute: 0, label: '출근'));
    await pump(tester);

    expect(find.text('오전 7:00'), findsOneWidget);
    expect(find.text('출근'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AlarmRingingPage), findsOneWidget);
  });

  testWidgets('라벨이 없으면 기본 제목, 끄기는 stop 후 닫힌다', (tester) async {
    when(() => useCase.findByPackageId(100)).thenAnswer((_) async => null);
    await pump(tester);

    expect(find.text('알람'), findsOneWidget);
    await tester.tap(find.text('끄기'));
    await tester.pumpAndSettle();

    verify(() => useCase.stop(100)).called(1);
    expect(find.byType(AlarmRingingPage), findsNothing);
  });

  testWidgets('5분 뒤는 snooze 후 닫힌다', (tester) async {
    when(() => useCase.findByPackageId(100)).thenAnswer((_) async => null);
    await pump(tester);

    await tester.tap(find.text('5분 뒤'));
    await tester.pumpAndSettle();

    verify(() => useCase.snooze(100)).called(1);
    expect(find.text('home'), findsOneWidget);
  });
}
