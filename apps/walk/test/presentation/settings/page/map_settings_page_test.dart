import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/data/location/background_location_access.dart';
import 'package:walk/domain/location/entity/record_mode.dart';
import 'package:walk/domain/location/entity/record_retention.dart';
import 'package:walk/domain/location/recorder/location_recorder.dart';
import 'package:walk/domain/location/recorder/recorder_status.dart';
import 'package:walk/domain/location/repository/location_preferences.dart';
import 'package:walk/domain/location/repository/location_repository.dart';
import 'package:walk/presentation/map/cubit/map_record_cubit.dart';
import 'package:walk/presentation/settings/page/map_settings_page.dart';

import '../settings_harness.dart';

class _MockRecorder extends Mock implements LocationRecorder {}

class _MockAccess extends Mock implements BackgroundLocationAccess {}

class _MockPrefs extends Mock implements LocationPreferences {}

class _MockRepository extends Mock implements LocationRepository {}

void main() {
  final h = SettingsHarness();
  late _MockRecorder recorder;
  late _MockAccess access;
  late _MockPrefs prefs;
  late _MockRepository repository;
  late MapRecordCubit cubit;

  setUpAll(() {
    SettingsHarness.registerFallbacks();
    registerFallbackValue(RecordMode.normal);
    registerFallbackValue(RecordRetention.never);
  });

  setUp(() async {
    await h.setUp();
    recorder = _MockRecorder();
    access = _MockAccess();
    prefs = _MockPrefs();
    repository = _MockRepository();
    when(() => prefs.retention).thenReturn(RecordRetention.never);
    when(() => prefs.setRetention(any())).thenAnswer((_) async {});
    when(recorder.status).thenAnswer((_) async => const RecorderStatus.off());
    when(() => recorder.start(any())).thenAnswer((_) async {});
    when(recorder.stop).thenAnswer((_) async {});
    when(() => recorder.setMode(any())).thenAnswer((_) async {});
    when(access.check).thenAnswer((_) async => AlwaysAccess.denied);
    when(recorder.openBatterySettings).thenAnswer((_) async {});
    when(access.request).thenAnswer((_) async => AlwaysAccess.granted);
    when(access.hasActivityRecognition).thenAnswer((_) async => true);
    when(access.hasNotification).thenAnswer((_) async => true);
    when(access.openAppSettings).thenAnswer((_) async {});
    when(repository.deleteAll).thenAnswer((_) async {});
    when(recorder.clearInbox).thenAnswer((_) async {});
    when(repository.hasAnyPoint).thenAnswer((_) async => true);
    cubit = MapRecordCubit(recorder, access, prefs, repository);
  });

  tearDown(() async {
    await cubit.close();
    await h.tearDown();
  });

  Future<void> pump(WidgetTester tester) => h.pump(
    tester,
    BlocProvider.value(value: cubit, child: const MapSettingsPage()),
  );

  Switch switchOf(WidgetTester tester, String key) =>
      tester.widget<Switch>(find.byKey(Key(key)));

  testWidgets('기본 상태: 기록 꺼짐, 촘촘 비활성, 보관 기간 지우지 않음', (tester) async {
    await pump(tester);

    expect(switchOf(tester, 'map-settings-record-switch').value, isFalse);
    expect(switchOf(tester, 'map-settings-dense-switch').onChanged, isNull);
    expect(find.text('지우지 않음'), findsOneWidget);
  });

  testWidgets('기록 스위치를 켜면 평소 모드로 시작한다', (tester) async {
    await pump(tester);
    when(recorder.status).thenAnswer(
      (_) async =>
          const RecorderStatus.running(RecordMode.normal, stillDetection: true),
    );

    await tester.tap(find.byKey(const Key('map-settings-record-switch')));
    await tester.pumpAndSettle();

    verify(() => recorder.start(RecordMode.normal)).called(1);
    expect(switchOf(tester, 'map-settings-record-switch').value, isTrue);
    expect(switchOf(tester, 'map-settings-dense-switch').onChanged, isNotNull);
  });

  testWidgets('항상 허용을 대화상자로 못 받으면 켜지 않고 안내한다', (tester) async {
    when(access.request).thenAnswer((_) async => AlwaysAccess.needsSettings);
    await pump(tester);

    await tester.tap(find.byKey(const Key('map-settings-record-switch')));
    await tester.pumpAndSettle();

    verifyNever(() => recorder.start(any()));
    expect(switchOf(tester, 'map-settings-record-switch').value, isFalse);
    expect(find.textContaining('항상 허용'), findsWidgets);
  });

  testWidgets('촘촘 스위치는 setMode(dense) 를 부른다', (tester) async {
    when(recorder.status).thenAnswer(
      (_) async =>
          const RecorderStatus.running(RecordMode.normal, stillDetection: true),
    );
    await pump(tester);

    await tester.tap(find.byKey(const Key('map-settings-dense-switch')));
    await tester.pumpAndSettle();

    verify(() => recorder.setMode(RecordMode.dense)).called(1);
  });

  testWidgets('보관 기간 시트에서 1년을 고르면 저장한다', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('map-settings-retention')));
    await tester.pumpAndSettle();
    expect(find.text('3개월'), findsOneWidget);
    await tester.tap(find.text('1년'));
    await tester.pumpAndSettle();

    verify(() => prefs.setRetention(RecordRetention.oneYear)).called(1);
    expect(find.text('1년'), findsOneWidget);
  });

  testWidgets('신체 활동 권한이 없으면 정지 감지 꺼짐을 보이고 누르면 설정을 연다', (tester) async {
    when(access.hasActivityRecognition).thenAnswer((_) async => false);
    await pump(tester);

    expect(find.text('정지 감지 꺼짐 ›'), findsOneWidget);
    await tester.tap(find.byKey(const Key('map-settings-permission-activity')));
    await tester.pumpAndSettle();

    verify(access.openAppSettings).called(1);
  });

  testWidgets('권한을 잃어 blocked 면 켜 둔 채로 권한 필요를 보인다', (tester) async {
    when(
      recorder.status,
    ).thenAnswer((_) async => const RecorderStatus.blocked(RecordMode.normal));
    await pump(tester);

    expect(switchOf(tester, 'map-settings-record-switch').value, isTrue);
    expect(find.text('권한이 필요해 기록이 꺼져 있어요'), findsOneWidget);
    expect(find.text('허용 필요 ›'), findsOneWidget);
  });

  testWidgets('항상 허용 행은 실제 권한을 읽어 보인다', (tester) async {
    when(access.check).thenAnswer((_) async => AlwaysAccess.granted);
    await pump(tester);

    expect(find.text('허용됨'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const Key('map-settings-permission-always')),
        matching: find.text('허용됨'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('권한이 거부되면 켜지 못했다는 안내를 보인다', (tester) async {
    when(access.request).thenAnswer((_) async => AlwaysAccess.denied);
    await pump(tester);

    await tester.tap(find.byKey(const Key('map-settings-record-switch')));
    await tester.pumpAndSettle();

    expect(find.text('위치 권한이 없어 기록을 켜지 못했어요'), findsOneWidget);
  });

  testWidgets('배터리 행은 배터리 설정을 연다', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('map-settings-battery')));
    await tester.pumpAndSettle();

    verify(recorder.openBatterySettings).called(1);
  });

  testWidgets('모두 지우기: 확인해야 지운다', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('map-settings-delete-all')));
    await tester.pumpAndSettle();
    expect(find.text('위치 기록을 모두 지울까요?'), findsOneWidget);
    verifyNever(repository.deleteAll);

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    verifyInOrder([recorder.clearInbox, repository.deleteAll]);
    expect(find.text('위치 기록을 지웠어요'), findsOneWidget);
  });

  testWidgets('모두 지우기: 취소하면 지우지 않는다', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('map-settings-delete-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    verifyNever(repository.deleteAll);
  });
}
