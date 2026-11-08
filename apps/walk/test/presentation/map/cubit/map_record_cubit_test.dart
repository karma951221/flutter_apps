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

class _MockRecorder extends Mock implements LocationRecorder {}

class _MockAccess extends Mock implements BackgroundLocationAccess {}

class _MockPrefs extends Mock implements LocationPreferences {}

class _MockRepository extends Mock implements LocationRepository {}

void main() {
  late _MockRecorder recorder;
  late _MockAccess access;
  late _MockPrefs prefs;
  late _MockRepository repository;
  late MapRecordCubit cubit;

  setUpAll(() {
    registerFallbackValue(RecordMode.normal);
    registerFallbackValue(RecordRetention.never);
  });

  setUp(() {
    recorder = _MockRecorder();
    access = _MockAccess();
    prefs = _MockPrefs();
    repository = _MockRepository();
    when(() => prefs.retention).thenReturn(RecordRetention.never);
    when(() => prefs.setRetention(any())).thenAnswer((_) async {});
    when(
      () => recorder.status(),
    ).thenAnswer((_) async => const RecorderStatus.off());
    when(() => recorder.start(any())).thenAnswer((_) async {});
    when(() => recorder.stop()).thenAnswer((_) async {});
    when(() => recorder.setMode(any())).thenAnswer((_) async {});
    when(() => access.request()).thenAnswer((_) async => AlwaysAccess.granted);
    when(() => access.hasActivityRecognition()).thenAnswer((_) async => true);
    when(() => access.hasNotification()).thenAnswer((_) async => true);
    when(() => repository.deleteAll()).thenAnswer((_) async {});
    cubit = MapRecordCubit(recorder, access, prefs, repository);
  });

  tearDown(() => cubit.close());

  test('enable starts normal when always granted', () async {
    when(() => recorder.status()).thenAnswer(
      (_) async =>
          const RecorderStatus.running(RecordMode.normal, stillDetection: true),
    );

    await cubit.enable();

    verify(() => recorder.start(RecordMode.normal)).called(1);
    expect(
      cubit.state.status,
      const RecorderStatus.running(RecordMode.normal, stillDetection: true),
    );
    expect(cubit.state.access, AlwaysAccess.granted);
    expect(cubit.state.busy, isFalse);
  });

  test('enable does not start when needsSettings', () async {
    when(
      () => access.request(),
    ).thenAnswer((_) async => AlwaysAccess.needsSettings);

    await cubit.enable();

    verifyNever(() => recorder.start(any()));
    expect(cubit.state.access, AlwaysAccess.needsSettings);
    expect(cubit.state.status, const RecorderStatus.off());
  });

  test('enable starts even when activity recognition denied', () async {
    when(() => access.hasActivityRecognition()).thenAnswer((_) async => false);
    when(() => recorder.status()).thenAnswer(
      (_) async => const RecorderStatus.running(
        RecordMode.normal,
        stillDetection: false,
      ),
    );

    await cubit.enable();

    verify(() => recorder.start(RecordMode.normal)).called(1);
    expect(
      cubit.state.status,
      const RecorderStatus.running(RecordMode.normal, stillDetection: false),
    );
    expect(cubit.state.activityRecognition, isFalse);
  });

  test('setDense switches mode', () async {
    when(() => recorder.status()).thenAnswer(
      (_) async =>
          const RecorderStatus.running(RecordMode.dense, stillDetection: true),
    );
    await cubit.load();

    await cubit.setDense(true);

    verify(() => recorder.setMode(RecordMode.dense)).called(1);
    expect(
      cubit.state.status,
      const RecorderStatus.running(RecordMode.dense, stillDetection: true),
    );
  });

  test('setDense does nothing while off', () async {
    await cubit.setDense(true);

    verifyNever(() => recorder.setMode(any()));
  });

  test('disable stops and goes off', () async {
    when(() => recorder.status()).thenAnswer(
      (_) async =>
          const RecorderStatus.running(RecordMode.normal, stillDetection: true),
    );
    await cubit.load();

    await cubit.disable();

    verify(() => recorder.stop()).called(1);
    expect(cubit.state.status, const RecorderStatus.off());
  });

  test('load reports blocked when always permission revoked', () async {
    when(
      () => recorder.status(),
    ).thenAnswer((_) async => const RecorderStatus.blocked(RecordMode.normal));

    await cubit.load();

    expect(cubit.state.status, const RecorderStatus.blocked(RecordMode.normal));
  });

  test('setRetention saves and updates state', () async {
    await cubit.setRetention(RecordRetention.oneYear);

    verify(() => prefs.setRetention(RecordRetention.oneYear)).called(1);
    expect(cubit.state.retention, RecordRetention.oneYear);
  });

  test('deleteAll clears the repository', () async {
    await cubit.deleteAll();

    verify(() => repository.deleteAll()).called(1);
    expect(cubit.state.busy, isFalse);
  });
}
