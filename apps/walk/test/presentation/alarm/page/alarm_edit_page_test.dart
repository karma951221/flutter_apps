import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/clock.dart';
import 'package:walk/presentation/alarm/page/alarm_edit_page.dart';

class _MockUseCase extends Mock implements AlarmUseCase {}

class _MockRequester extends Mock implements PermissionRequester {}

class _FixedClock extends Clock {
  @override
  DateTime now() => DateTime(2026, 9, 27, 23, 48);
}

void main() {
  late _MockUseCase useCase;
  late _MockRequester notification;
  late _MockRequester exactAlarm;

  setUpAll(() => registerFallbackValue(Alarm.draft()));
  setUp(() {
    useCase = _MockUseCase();
    notification = _MockRequester();
    exactAlarm = _MockRequester();
    when(notification.ensure).thenAnswer((_) async => PermissionStatus.granted);
    when(exactAlarm.ensure).thenAnswer((_) async => PermissionStatus.granted);
    getIt
      ..registerSingleton<AlarmUseCase>(useCase)
      ..registerSingleton<AlarmPermissions>(
        AlarmPermissions(
          notification: notification,
          exactAlarm: exactAlarm,
          fullScreenIntent: _MockRequester(),
        ),
      )
      ..registerSingleton<Clock>(_FixedClock());
  });
  tearDown(getIt.reset);

  /// 편집 화면을 띄우고, 닫힐 때의 결과를 [results] 에 모은다.
  Future<List<Duration?>> pump(WidgetTester tester, Alarm initial) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final results = <Duration?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await Navigator.of(context).push<Duration>(
                MaterialPageRoute(builder: (_) => AlarmEditPage(initial: initial)),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('새 알람: 요일 · 라벨을 고르고 저장하면 use case → 권한 → 남은 시간으로 닫힌다', (
    tester,
  ) async {
    when(() => useCase.save(any())).thenAnswer(
      (i) async => (i.positionalArguments.single as Alarm).copyWith(id: 1),
    );
    final results = await pump(tester, Alarm.draft());

    expect(find.text('새 알람'), findsOneWidget);
    expect(find.text('삭제'), findsNothing);
    await tester.tap(find.text('월'));
    await tester.enterText(find.byType(TextField), '출근');
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final saved = verify(() => useCase.save(captureAny())).captured.single as Alarm;
    expect(saved.repeat, {Weekday.mon});
    expect(saved.label, '출근');
    expect(saved.hour, 7);
    verifyInOrder([notification.ensure, exactAlarm.ensure]);
    // 일요일 23:48 → 월요일 07:00
    expect(results, [const Duration(hours: 7, minutes: 12)]);
    expect(find.byType(AlarmEditPage), findsNothing);
  });

  testWidgets('저장이 실패하면 머물고 오류 스낵바', (tester) async {
    when(() => useCase.save(any())).thenThrow(StateError('full'));
    await pump(tester, Alarm.draft());

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.byType(AlarmEditPage), findsOneWidget);
    expect(find.text('알람을 저장하지 못했어요'), findsOneWidget);
  });

  testWidgets('편집: 삭제는 확인 뒤 지우고 결과 없이 닫힌다', (tester) async {
    when(() => useCase.delete(3)).thenAnswer((_) async {});
    final results = await pump(tester, const Alarm(id: 3, hour: 6, minute: 30));

    expect(find.text('알람 편집'), findsOneWidget);
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(find.text('알람을 삭제할까요?'), findsOneWidget);
    await tester.tap(find.text('삭제').last);
    await tester.pumpAndSettle();

    verify(() => useCase.delete(3)).called(1);
    expect(results, [null]);
  });
}
