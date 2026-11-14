import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/presentation/alarm/page/alarm_ringing_page.dart';

class _MockUseCase extends Mock implements AlarmUseCase {}

class _FixedClock extends Clock {
  @override
  DateTime now() => DateTime(2026, 9, 28, 7, 0, 5);
}

/// 파문이 영원히 반복하므로 `pumpAndSettle` 이 끝나도록 애니메이션을 끈다.
Widget _noAnimations(Widget child) => MediaQuery(
  data: const MediaQueryData(disableAnimations: true),
  child: child,
);

void main() {
  late _MockUseCase useCase;

  setUp(() {
    useCase = _MockUseCase();
    when(() => useCase.snooze(100)).thenAnswer((_) async {});
    when(() => useCase.stop(100)).thenAnswer((_) async {});
    when(() => useCase.canSnooze(100)).thenAnswer((_) async => true);
    getIt
      ..registerSingleton<AlarmUseCase>(useCase)
      ..registerSingleton<Clock>(_FixedClock());
  });
  tearDown(getIt.reset);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      _noAnimations(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AlarmRingingPage(packageId: 100),
                ),
              ),
              child: const Text('home'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
  }

  testWidgets('현재 시각과 라벨을 보이고, 뒤로가기로 닫히지 않는다', (tester) async {
    when(() => useCase.findByPackageId(100)).thenAnswer(
      (_) async => const Alarm(id: 1, hour: 7, minute: 0, label: '출근'),
    );
    await pump(tester);

    expect(find.text('오전 7:00'), findsOneWidget);
    expect(find.text('출근'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AlarmRingingPage), findsOneWidget);
  });

  testWidgets('초록 컨테이너 배경에 글자는 onPrimaryContainer', (tester) async {
    when(() => useCase.findByPackageId(100)).thenAnswer((_) async => null);
    await pump(tester);

    final scheme = Theme.of(
      tester.element(find.byType(AlarmRingingPage)),
    ).colorScheme;
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      scheme.primaryContainer,
    );
    expect(
      tester.widget<Text>(find.text('오전 7:00')).style?.color,
      scheme.onPrimaryContainer,
    );
    expect(
      tester.widget<Text>(find.text('알람')).style?.color,
      scheme.onPrimaryContainer,
    );
  });

  testWidgets('라벨이 없으면 기본 제목, 끄기는 stop 후 닫힌다', (tester) async {
    when(() => useCase.findByPackageId(100)).thenAnswer((_) async => null);
    await pump(tester);

    expect(find.text('알람'), findsOneWidget);
    await tester.tap(find.text('알람 끄기'));
    await tester.pumpAndSettle();

    verify(() => useCase.stop(100)).called(1);
    expect(find.byType(AlarmRingingPage), findsNothing);
  });

  testWidgets('5분 뒤 다시 울림은 snooze 후 닫힌다', (tester) async {
    when(() => useCase.findByPackageId(100)).thenAnswer((_) async => null);
    await pump(tester);

    await tester.tap(find.text('5분 뒤 다시 울림'));
    await tester.pumpAndSettle();

    verify(() => useCase.snooze(100)).called(1);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('스누즈 간격이 10분이면 10분 뒤 다시 울림', (tester) async {
    when(() => useCase.findByPackageId(100)).thenAnswer(
      (_) async => const Alarm(id: 1, hour: 7, minute: 0, snoozeMinutes: 10),
    );
    await pump(tester);

    expect(find.text('10분 뒤 다시 울림'), findsOneWidget);
  });

  testWidgets('스누즈 한도를 다 썼으면 스누즈 버튼이 없고 끄기가 전체 폭', (tester) async {
    when(() => useCase.findByPackageId(100)).thenAnswer(
      (_) async => const Alarm(id: 1, hour: 7, minute: 0, snoozeLimit: 3),
    );
    when(() => useCase.canSnooze(100)).thenAnswer((_) async => false);
    await pump(tester);

    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.textContaining('다시 울림'), findsNothing);
    final width = tester.getSize(find.byType(AlarmRingingPage)).width;
    expect(
      tester.getSize(find.byType(FilledButton)).width,
      width - AppSpacing.lg * 2,
    );
  });

  for (final (button, action) in [
    ('알람 끄기', 'stop'),
    ('5분 뒤 다시 울림', 'snooze'),
  ]) {
    testWidgets('$button 도중 리스너가 먼저 화면을 걷어도 아래 화면은 남는다', (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      final route = MaterialPageRoute<void>(
        builder: (_) => const AlarmRingingPage(packageId: 100),
      );
      // 알림 쪽에서 먼저 꺼져 AlarmRingListener 가 이 화면을 걷는 경우.
      Future<void> removedByListener(Invocation _) async =>
          navigator.currentState!.removeRoute(route);
      when(() => useCase.findByPackageId(100)).thenAnswer((_) async => null);
      when(() => useCase.stop(100)).thenAnswer(removedByListener);
      when(() => useCase.snooze(100)).thenAnswer(removedByListener);
      await tester.pumpWidget(
        _noAnimations(
          MaterialApp(
            navigatorKey: navigator,
            theme: AppTheme.light(),
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Text('home'),
          ),
        ),
      );
      unawaited(navigator.currentState!.push(route));
      await tester.pumpAndSettle();

      await tester.tap(find.text(button));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AlarmRingingPage), findsNothing);
      expect(find.text('home'), findsOneWidget);
      verify(
        () => action == 'stop' ? useCase.stop(100) : useCase.snooze(100),
      ).called(1);
    });
  }

  for (final locale in const [Locale('ko'), Locale('en'), Locale('ja')]) {
    testWidgets('320dp 폭에서도 버튼 문구가 잘리지 않는다 ($locale)', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // 스누즈 문구가 가장 긴 15분 간격으로 본다.
      when(() => useCase.findByPackageId(100)).thenAnswer(
        (_) async => const Alarm(id: 1, hour: 7, minute: 0, snoozeMinutes: 15),
      );
      final l10n = lookupAppLocalizations(locale);
      await tester.pumpWidget(
        _noAnimations(
          MaterialApp(
            theme: AppTheme.light(),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AlarmRingingPage(packageId: 100),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for (final (label, button) in [
        (l10n.walkAlarmSnooze(15), find.byType(OutlinedButton)),
        (l10n.walkAlarmStop, find.byType(FilledButton)),
      ]) {
        final text = find.text(label);
        final paragraph = tester.renderObject<RenderParagraph>(text);
        final lineHeight = paragraph.getFullHeightForCaret(
          const TextPosition(offset: 0),
        );
        expect(paragraph.didExceedMaxLines, isFalse, reason: label);
        expect(
          paragraph.size.height,
          lessThanOrEqualTo(lineHeight * 2 + 0.5),
          reason: label,
        );
        // 글자가 버튼 밖으로 나가지 않는다.
        final buttonRect = tester.getRect(button);
        final textRect = tester.getRect(text);
        expect(buttonRect.contains(textRect.topLeft), isTrue, reason: label);
        expect(
          buttonRect.contains(textRect.bottomRight - const Offset(1, 1)),
          isTrue,
          reason: label,
        );
        expect(tester.widget<Text>(text).textAlign, TextAlign.center);
      }
      // 두 버튼 높이가 같다.
      expect(
        tester.getSize(find.byType(OutlinedButton)).height,
        tester.getSize(find.byType(FilledButton)).height,
      );
    });
  }
}
