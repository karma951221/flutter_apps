import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/domain/export/policy/gpx_encoder.dart';
import 'package:pawlog/presentation/walk/cubit/walk_detail_cubit.dart';
import 'package:pawlog/presentation/walk/cubit/walk_export_result.dart';
import 'package:pawlog/presentation/walk/cubit/walk_detail_state.dart';

import '../../../support/fakes.dart';
import '../../../support/mock_walk_file_sharer.dart';
import '../../../support/mock_walk_use_case.dart';

void main() {
  late MockWalkUseCase useCase;
  late MockWalkFileSharer sharer;
  final track = [trackPoint(37.5), trackPoint(37.501)];

  setUp(() {
    useCase = MockWalkUseCase();
    sharer = MockWalkFileSharer();
    when(() => useCase.getWalk('w1')).thenAnswer((_) async => Ok(walk()));
    when(() => useCase.getWalkTrack('w1')).thenAnswer((_) async => Ok(track));
  });

  blocTest<WalkDetailCubit, WalkDetailState>(
    'load 가 walk 와 track 을 함께 읽는다',
    build: () => WalkDetailCubit(useCase, sharer),
    act: (cubit) => cubit.load('w1'),
    expect: () => [
      const WalkDetailState.loading(),
      WalkDetailState.loaded(walk: walk(), track: track),
    ],
    verify: (_) {
      verify(() => useCase.getWalk('w1')).called(1);
      verify(() => useCase.getWalkTrack('w1')).called(1);
    },
  );

  blocTest<WalkDetailCubit, WalkDetailState>(
    '없는 산책이면 failure walkNotFound',
    setUp: () => when(
      () => useCase.getWalk('w1'),
    ).thenAnswer((_) async => const Ok(null)),
    build: () => WalkDetailCubit(useCase, sharer),
    act: (cubit) => cubit.load('w1'),
    expect: () => [
      const WalkDetailState.loading(),
      isA<WalkDetailFailure>().having(
        (s) => s.failure.failureCode,
        'failureCode',
        FailureCode.walkNotFound,
      ),
    ],
  );

  blocTest<WalkDetailCubit, WalkDetailState>(
    '읽기가 실패하면 failure',
    setUp: () => when(
      () => useCase.getWalkTrack('w1'),
    ).thenAnswer((_) async => const Err(Failure.network())),
    build: () => WalkDetailCubit(useCase, sharer),
    act: (cubit) => cubit.load('w1'),
    expect: () => [
      const WalkDetailState.loading(),
      const WalkDetailState.failure(Failure.network()),
    ],
  );

  blocTest<WalkDetailCubit, WalkDetailState>(
    '다시 읽을 때는 loading 으로 화면을 비우지 않는다',
    build: () => WalkDetailCubit(useCase, sharer),
    act: (cubit) async {
      await cubit.load('w1');
      await cubit.load('w1');
    },
    expect: () => [
      const WalkDetailState.loading(),
      WalkDetailState.loaded(walk: walk(), track: track),
    ],
    verify: (_) => verify(() => useCase.getWalk('w1')).called(2),
  );

  blocTest<WalkDetailCubit, WalkDetailState>(
    '삭제 → deleting → deleted',
    setUp: () => when(
      () => useCase.deleteWalk('w1'),
    ).thenAnswer((_) async => const Ok(null)),
    build: () => WalkDetailCubit(useCase, sharer),
    act: (cubit) async {
      await cubit.load('w1');
      await cubit.delete();
    },
    skip: 2,
    expect: () => [
      WalkDetailState.deleting(walk: walk(), track: track),
      const WalkDetailState.deleted(),
    ],
  );

  blocTest<WalkDetailCubit, WalkDetailState>(
    '삭제 실패 → loaded 에 failure',
    setUp: () => when(
      () => useCase.deleteWalk('w1'),
    ).thenAnswer((_) async => const Err(Failure.network())),
    build: () => WalkDetailCubit(useCase, sharer),
    act: (cubit) async {
      await cubit.load('w1');
      await cubit.delete();
    },
    skip: 2,
    expect: () => [
      WalkDetailState.deleting(walk: walk(), track: track),
      WalkDetailState.loaded(
        walk: walk(),
        track: track,
        failure: const Failure.network(),
      ),
    ],
  );

  group('exportGpx', () {
    void stubSharer(Result<void> result) => when(
      () => sharer.shareFile(
        fileName: any(named: 'fileName'),
        contents: any(named: 'contents'),
        mimeType: any(named: 'mimeType'),
      ),
    ).thenAnswer((_) async => result);

    test('불러오기 전에는 failed', () async {
      final cubit = WalkDetailCubit(useCase, sharer);
      addTearDown(cubit.close);

      expect(await cubit.exportGpx(), isA<WalkExportFailed>());
      verifyZeroInteractions(sharer);
    });

    test('경로 점이 없으면 noRoute 이고 공유하지 않는다', () async {
      when(
        () => useCase.getWalkTrack('w1'),
      ).thenAnswer((_) async => const Ok([]));
      final cubit = WalkDetailCubit(useCase, sharer);
      addTearDown(cubit.close);
      await cubit.load('w1');
      final before = cubit.state;

      expect(await cubit.exportGpx(), const WalkExportResult.noRoute());
      verifyZeroInteractions(sharer);
      expect(cubit.state, before);
    });

    test('GPX 파일 이름 · 내용 · MIME 으로 공유하면 shared', () async {
      final memoWalk = walk(
        dogs: [dog('d1'), dog('d2')],
      ).copyWith(memo: '공원 한 바퀴');
      when(
        () => useCase.getWalk('w1'),
      ).thenAnswer((_) async => Ok(memoWalk));
      stubSharer(const Ok(null));
      final cubit = WalkDetailCubit(useCase, sharer);
      addTearDown(cubit.close);
      await cubit.load('w1');
      final before = cubit.state;

      expect(await cubit.exportGpx(), const WalkExportResult.shared());
      verify(
        () => sharer.shareFile(
          fileName: GpxEncoder.fileName(memoWalk.startedAt),
          contents: GpxEncoder.encode(
            name: '콩이d1, 콩이d2',
            description: '공원 한 바퀴',
            startedAt: memoWalk.startedAt,
            points: track,
          ),
          mimeType: 'application/gpx+xml',
        ),
      ).called(1);
      expect(cubit.state, before);
    });

    test('공유가 실패하면 failed 에 그 failure', () async {
      stubSharer(const Err(Failure.unknown(message: 'io')));
      final cubit = WalkDetailCubit(useCase, sharer);
      addTearDown(cubit.close);
      await cubit.load('w1');
      final before = cubit.state;

      expect(
        await cubit.exportGpx(),
        const WalkExportResult.failed(Failure.unknown(message: 'io')),
      );
      expect(cubit.state, before);
    });
  });
}
