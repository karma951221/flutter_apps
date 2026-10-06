import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/alarm/entity/alarm_sound.dart';
import 'package:walk/domain/alarm/sound/alarm_sound_source.dart';
import 'package:walk/presentation/alarm/page/alarm_sound_page.dart';

class _MockSoundSource extends Mock implements AlarmSoundSource {}

void main() {
  const bell = (title: 'Bell', uri: 'content://media/1');
  const dawn = (title: 'Dawn', uri: 'content://media/2');
  const copiedBell = AlarmSound.device(title: 'Bell', path: '/data/alarm_sounds/a.ogg');
  late _MockSoundSource source;

  setUpAll(() {
    registerFallbackValue(const AlarmSound.system());
    registerFallbackValue(bell);
  });
  setUp(() {
    source = _MockSoundSource();
    when(() => source.deviceRingtones()).thenAnswer((_) async => [bell, dawn]);
    when(() => source.preview(any(), uri: any(named: 'uri'))).thenAnswer((_) async {});
    when(() => source.stopPreview()).thenAnswer((_) async {});
    getIt.registerSingleton<AlarmSoundSource>(source);
  });
  tearDown(getIt.reset);

  /// 선택 화면을 띄우고, 닫힐 때의 결과를 모은다.
  Future<List<AlarmSound?>> pump(WidgetTester tester, AlarmSound initial) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final results = <AlarmSound?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await Navigator.of(context).push<AlarmSound>(
                MaterialPageRoute(builder: (_) => AlarmSoundPage(initial: initial)),
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

  /// [title] 줄에 선택 표시가 있는가.
  bool isChecked(WidgetTester tester, String title) {
    final row = find.ancestor(of: find.text(title), matching: find.byType(AppListTile));
    return tester.any(
      find.descendant(of: row, matching: find.byIcon(Icons.radio_button_checked)),
    );
  }

  testWidgets('세 구역: 시스템 기본 · 앱 소리 3줄 · 기기 알람음 목록', (tester) async {
    await pump(tester, const AlarmSound.system());

    expect(find.text('알람음'), findsOneWidget);
    expect(find.text('시스템 기본'), findsOneWidget);
    expect(find.text('앱 소리'), findsOneWidget);
    for (final name in ['비프', '차임', '점점 빠르게']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('기기 알람음'), findsOneWidget);
    expect(find.text('Bell'), findsOneWidget);
    expect(find.text('Dawn'), findsOneWidget);
    expect(isChecked(tester, '시스템 기본'), isTrue);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
  });

  testWidgets('처음 선택 표시: 복사해 둔 기기 소리는 같은 제목의 줄', (tester) async {
    await pump(tester, copiedBell);

    expect(isChecked(tester, 'Bell'), isTrue);
    expect(isChecked(tester, '시스템 기본'), isFalse);
  });

  testWidgets('기기 목록 읽기 실패면 그 구역에만 안내, 나머지는 쓸 수 있다', (tester) async {
    when(() => source.deviceRingtones()).thenThrow(const AlarmSoundException('list'));
    final results = await pump(tester, const AlarmSound.system());

    expect(find.text('기기 알람음을 불러오지 못했어요'), findsOneWidget);
    expect(find.byType(AppPlaceholder), findsOneWidget);
    await tester.tap(find.text('차임'));
    await tester.pump();
    await tester.tap(find.text('선택'));
    await tester.pumpAndSettle();

    expect(results, [const AlarmSound.bundled(BundledAlarmSounds.chime)]);
  });

  testWidgets('기기 목록이 비어도 같은 안내', (tester) async {
    when(() => source.deviceRingtones()).thenAnswer((_) async => []);
    await pump(tester, const AlarmSound.system());

    expect(find.text('기기 알람음을 불러오지 못했어요'), findsOneWidget);
  });

  testWidgets('줄을 누르면 선택 표시가 옮겨 가고 미리 듣는다 → 선택하면 그 소리로 닫힌다', (tester) async {
    final results = await pump(tester, const AlarmSound.system());

    await tester.tap(find.text('점점 빠르게'));
    await tester.pump();

    expect(isChecked(tester, '점점 빠르게'), isTrue);
    expect(isChecked(tester, '시스템 기본'), isFalse);
    verify(() => source.preview(const AlarmSound.bundled(BundledAlarmSounds.rising))).called(1);

    await tester.tap(find.text('선택'));
    await tester.pumpAndSettle();

    expect(results, [const AlarmSound.bundled(BundledAlarmSounds.rising)]);
    expect(find.byType(AlarmSoundPage), findsNothing);
    verify(() => source.stopPreview()).called(1);
  });

  testWidgets('기기 알람음: 복사하는 동안 버튼 로딩, 끝나면 복사본으로 닫힌다', (tester) async {
    final importing = Completer<AlarmSound>();
    when(() => source.import(bell)).thenAnswer((_) => importing.future);
    final results = await pump(tester, const AlarmSound.system());

    await tester.tap(find.text('Bell'));
    await tester.pump();
    verify(() => source.preview(any(), uri: bell.uri)).called(1);
    await tester.tap(find.text('선택'));
    await tester.pump();

    expect(tester.widget<AppButton>(find.byType(AppButton)).isLoading, isTrue);
    importing.complete(copiedBell);
    await tester.pumpAndSettle();

    expect(results, [copiedBell]);
  });

  testWidgets('복사가 실패하면 오류 스낵바를 띄우고 머문다', (tester) async {
    when(() => source.import(bell)).thenThrow(const AlarmSoundException('import'));
    final results = await pump(tester, const AlarmSound.system());

    await tester.tap(find.text('Bell'));
    await tester.pump();
    await tester.tap(find.text('선택'));
    await tester.pumpAndSettle();

    expect(find.text('이 알람음을 쓸 수 없어요'), findsOneWidget);
    expect(find.byType(AlarmSoundPage), findsOneWidget);
    expect(results, isEmpty);
    expect(tester.widget<AppButton>(find.byType(AppButton)).isLoading, isFalse);
  });

  testWidgets('뒤로 가면 결과 없이 닫히고 미리 듣기를 멈춘다', (tester) async {
    final results = await pump(tester, const AlarmSound.system());

    await tester.tap(find.text('차임'));
    await tester.pump();
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();

    expect(results, [null]);
    verify(() => source.stopPreview()).called(1);
  });
}
