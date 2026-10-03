import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fakes.dart';
import '../../support/mock_walk_use_case.dart';

PreparedImage _image() => PreparedImage(
  bytes: Uint8List.fromList([1, 2, 3]),
  width: 10,
  height: 10,
  contentType: 'image/jpeg',
  extension: 'jpg',
);

WalkPhoto _photo(String path, int position) =>
    WalkPhoto(id: 'p$position', path: path, position: position);

void main() {
  late MockWalkUseCase useCase;
  late WalkSession session;

  setUpAll(() {
    registerFallbackValue(
      WalkDraft(
        startedAt: t0,
        endedAt: t1,
        distanceMeters: 0,
        points: const [],
        dogIds: const [],
        photoPaths: const [],
      ),
    );
    registerFallbackValue(
      const WalkUpdate(id: 'w1', dogIds: [], photoPaths: []),
    );
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    useCase = MockWalkUseCase();
    session = walkSession(
      points: [trackPoint(37.5)],
      distanceMeters: 800,
      endedAt: t1,
    );
    when(() => useCase.trackerState).thenReturn(TrackerState.finished(session));
    when(
      () => useCase.getDogs(),
    ).thenAnswer((_) async => Ok([dog('d1'), dog('d2')]));
    when(() => useCase.removePhoto(any())).thenAnswer((_) async {});
    when(
      () => useCase.discardWalk(photoPaths: any(named: 'photoPaths')),
    ).thenAnswer((_) async {});
  });

  void stubStore(List<String> paths) {
    final queue = [...paths];
    when(
      () => useCase.storePhoto(
        bytes: any(named: 'bytes'),
        extension: any(named: 'extension'),
      ),
    ).thenAnswer((_) async => Ok(queue.removeAt(0)));
  }

  WalkEditForm newForm({
    Set<String> selected = const {'d1'},
    String memo = '',
    List<String> photoPaths = const [],
  }) => WalkEditForm(
    dogs: [dog('d1'), dog('d2')],
    selectedDogIds: selected,
    memo: memo,
    photoPaths: photoPaths,
    session: session,
  );

  WalkEditForm formOf(WalkEditCubit cubit) =>
      (cubit.state as WalkEditEditing).form;

  blocTest<WalkEditCubit, WalkEditState>(
    'finished 세션에서 폼을 만든다',
    build: () => WalkEditCubit(useCase),
    act: (cubit) => cubit.loadNew(),
    expect: () => [
      const WalkEditState.loading(),
      WalkEditState.editing(form: newForm()),
    ],
  );

  blocTest<WalkEditCubit, WalkEditState>(
    '세션이 없으면 loadFailure',
    setUp: () =>
        when(() => useCase.trackerState).thenReturn(const TrackerState.idle()),
    build: () => WalkEditCubit(useCase),
    act: (cubit) => cubit.loadNew(),
    expect: () => [
      const WalkEditState.loading(),
      isA<WalkEditLoadFailure>().having(
        (s) => s.failure.failureCode,
        'failureCode',
        FailureCode.walkNotFound,
      ),
    ],
    verify: (_) => verifyNever(() => useCase.getDogs()),
  );

  blocTest<WalkEditCubit, WalkEditState>(
    '추적 중이어도 loadFailure',
    setUp: () => when(
      () => useCase.trackerState,
    ).thenReturn(TrackerState.tracking(session)),
    build: () => WalkEditCubit(useCase),
    act: (cubit) => cubit.loadNew(),
    expect: () => [const WalkEditState.loading(), isA<WalkEditLoadFailure>()],
  );

  blocTest<WalkEditCubit, WalkEditState>(
    '기존 산책을 불러온다',
    setUp: () => when(() => useCase.getWalk('w1')).thenAnswer(
      (_) async => Ok(walk(photos: [_photo('a.jpg', 0)]).copyWith(memo: '메모')),
    ),
    build: () => WalkEditCubit(useCase),
    act: (cubit) => cubit.loadExisting('w1'),
    expect: () => [
      const WalkEditState.loading(),
      isA<WalkEditEditing>().having(
        (s) => s.form,
        'form',
        WalkEditForm(
          dogs: [dog('d1'), dog('d2')],
          selectedDogIds: const {'d1'},
          memo: '메모',
          photoPaths: const ['a.jpg'],
          existing: walk(photos: [_photo('a.jpg', 0)]).copyWith(memo: '메모'),
        ),
      ),
    ],
  );

  blocTest<WalkEditCubit, WalkEditState>(
    '없는 산책이면 walkNotFound',
    setUp: () => when(
      () => useCase.getWalk('w1'),
    ).thenAnswer((_) async => const Ok(null)),
    build: () => WalkEditCubit(useCase),
    act: (cubit) => cubit.loadExisting('w1'),
    expect: () => [
      const WalkEditState.loading(),
      isA<WalkEditLoadFailure>().having(
        (s) => s.failure.failureCode,
        'failureCode',
        FailureCode.walkNotFound,
      ),
    ],
  );

  blocTest<WalkEditCubit, WalkEditState>(
    '강아지를 토글하고 메모를 바꾼다',
    build: () => WalkEditCubit(useCase),
    act: (cubit) async {
      await cubit.loadNew();
      cubit
        ..toggleDog('d2')
        ..toggleDog('d1')
        ..setMemo('  좋았다  ');
    },
    verify: (cubit) {
      expect(formOf(cubit).selectedDogIds, {'d2'});
      expect(formOf(cubit).memo, '  좋았다  ');
    },
  );

  blocTest<WalkEditCubit, WalkEditState>(
    '사진 추가가 storePhoto 를 부르고 경로를 쌓는다',
    setUp: () => stubStore(['n1.jpg', 'n2.jpg']),
    build: () => WalkEditCubit(useCase),
    act: (cubit) async {
      await cubit.loadNew();
      await cubit.addPhotos([_image(), _image()]);
    },
    verify: (cubit) {
      verify(
        () => useCase.storePhoto(
          bytes: Uint8List.fromList([1, 2, 3]),
          extension: 'jpg',
        ),
      ).called(2);
      expect(formOf(cubit).photoPaths, ['n1.jpg', 'n2.jpg']);
    },
  );

  test('10장 넘는 사진은 버린다', () async {
    when(() => useCase.getWalk('w1')).thenAnswer(
      (_) async =>
          Ok(walk(photos: [for (var i = 0; i < 9; i++) _photo('p$i.jpg', i)])),
    );
    stubStore(['n1.jpg']);
    final cubit = WalkEditCubit(useCase);
    await cubit.loadExisting('w1');
    await cubit.addPhotos([_image(), _image(), _image()]);

    verify(
      () => useCase.storePhoto(
        bytes: any(named: 'bytes'),
        extension: any(named: 'extension'),
      ),
    ).called(1);
    expect(formOf(cubit).photoPaths, hasLength(10));
    expect(formOf(cubit).isPhotoLimitReached, isTrue);
    await cubit.close();
  });

  blocTest<WalkEditCubit, WalkEditState>(
    '사진 저장이 실패하면 failure 를 싣고 나머지는 계속한다',
    setUp: () {
      final results = <Result<String>>[
        const Err(
          Failure.unknown(failureCode: FailureCode.walkPhotoSaveFailed),
        ),
        const Ok('n2.jpg'),
      ];
      when(
        () => useCase.storePhoto(
          bytes: any(named: 'bytes'),
          extension: any(named: 'extension'),
        ),
      ).thenAnswer((_) async => results.removeAt(0));
    },
    build: () => WalkEditCubit(useCase),
    act: (cubit) async {
      await cubit.loadNew();
      await cubit.addPhotos([_image(), _image()]);
    },
    expect: () => [
      const WalkEditState.loading(),
      isA<WalkEditEditing>(),
      isA<WalkEditEditing>().having(
        (s) => s.failure?.failureCode,
        'failureCode',
        FailureCode.walkPhotoSaveFailed,
      ),
      isA<WalkEditEditing>().having((s) => s.failure, 'failure', isNull).having(
        (s) => s.form.photoPaths,
        'photoPaths',
        ['n2.jpg'],
      ),
    ],
  );

  group('removePhoto', () {
    test('이번에 추가한 사진만 즉시 지운다', () async {
      when(
        () => useCase.getWalk('w1'),
      ).thenAnswer((_) async => Ok(walk(photos: [_photo('old.jpg', 0)])));
      stubStore(['new.jpg']);
      final cubit = WalkEditCubit(useCase);
      await cubit.loadExisting('w1');
      await cubit.addPhotos([_image()]);
      expect(formOf(cubit).photoPaths, ['old.jpg', 'new.jpg']);

      await cubit.removePhoto(0);
      verifyNever(() => useCase.removePhoto(any()));
      expect(formOf(cubit).photoPaths, ['new.jpg']);

      await cubit.removePhoto(0);
      verify(() => useCase.removePhoto('new.jpg')).called(1);
      expect(formOf(cubit).photoPaths, isEmpty);
      await cubit.close();
    });
  });

  group('save', () {
    blocTest<WalkEditCubit, WalkEditState>(
      '신규 저장 성공 → saveWalk(WalkDraft) → saved',
      setUp: () {
        stubStore(['n1.jpg']);
        when(() => useCase.saveWalk(any())).thenAnswer((_) async => Ok(walk()));
      },
      build: () => WalkEditCubit(useCase),
      act: (cubit) async {
        await cubit.loadNew();
        cubit.setMemo('  좋았다  ');
        await cubit.addPhotos([_image()]);
        await cubit.save();
      },
      verify: (_) {
        final draft =
            verify(() => useCase.saveWalk(captureAny())).captured.single
                as WalkDraft;
        expect(draft.dogIds, ['d1']);
        expect(draft.memo, '좋았다');
        expect(draft.photoPaths, ['n1.jpg']);
        expect(draft.points, session.points);
        expect(draft.distanceMeters, 800);
        expect(draft.startedAt, t0);
        expect(draft.endedAt, t1);
        verifyNever(() => useCase.updateWalk(any()));
      },
      expect: () => [
        const WalkEditState.loading(),
        isA<WalkEditEditing>(),
        isA<WalkEditEditing>(),
        isA<WalkEditEditing>(),
        isA<WalkEditEditing>().having((s) => s.isSaving, 'isSaving', true),
        const WalkEditState.saved('w1'),
      ],
    );

    blocTest<WalkEditCubit, WalkEditState>(
      '저장 실패 → editing.failure',
      setUp: () => when(() => useCase.saveWalk(any())).thenAnswer(
        (_) async => const Err(
          Failure.validation(failureCode: FailureCode.walkDogRequired),
        ),
      ),
      build: () => WalkEditCubit(useCase),
      act: (cubit) async {
        await cubit.loadNew();
        await cubit.save();
      },
      expect: () => [
        const WalkEditState.loading(),
        WalkEditState.editing(form: newForm()),
        WalkEditState.editing(form: newForm(), isSaving: true),
        WalkEditState.editing(
          form: newForm(),
          failure: const Failure.validation(
            failureCode: FailureCode.walkDogRequired,
          ),
        ),
      ],
    );

    blocTest<WalkEditCubit, WalkEditState>(
      '기존 산책 수정은 updateWalk 를 부른다',
      setUp: () {
        when(() => useCase.getWalk('w1')).thenAnswer(
          (_) async =>
              Ok(walk(photos: [_photo('old.jpg', 0)]).copyWith(memo: '전')),
        );
        when(
          () => useCase.updateWalk(any()),
        ).thenAnswer((_) async => Ok(walk()));
      },
      build: () => WalkEditCubit(useCase),
      act: (cubit) async {
        await cubit.loadExisting('w1');
        cubit
          ..setMemo('')
          ..toggleDog('d2');
        await cubit.save();
      },
      verify: (cubit) {
        verify(
          () => useCase.updateWalk(
            const WalkUpdate(
              id: 'w1',
              dogIds: ['d1', 'd2'],
              photoPaths: ['old.jpg'],
            ),
          ),
        ).called(1);
        verifyNever(() => useCase.saveWalk(any()));
        expect(cubit.state, const WalkEditState.saved('w1'));
      },
    );

    test('저장 중에 늦게 끝난 addPhotos 는 파일을 지운다', () async {
      final store = Completer<Result<String>>();
      when(
        () => useCase.storePhoto(
          bytes: any(named: 'bytes'),
          extension: any(named: 'extension'),
        ),
      ).thenAnswer((_) => store.future);
      final saving = Completer<Result<Walk>>();
      when(() => useCase.saveWalk(any())).thenAnswer((_) => saving.future);

      final cubit = WalkEditCubit(useCase);
      await cubit.loadNew();
      final adding = cubit.addPhotos([_image()]);
      final save = cubit.save();
      store.complete(const Ok('late.jpg'));
      await adding;
      saving.complete(Ok(walk()));
      await save;

      verify(() => useCase.removePhoto('late.jpg')).called(1);
      expect(cubit.state, const WalkEditState.saved('w1'));
      await cubit.close();
    });
  });

  blocTest<WalkEditCubit, WalkEditState>(
    '버리면 discardWalk 를 부르고 discarded',
    setUp: () => stubStore(['n1.jpg']),
    build: () => WalkEditCubit(useCase),
    act: (cubit) async {
      await cubit.loadNew();
      await cubit.addPhotos([_image()]);
      await cubit.discard();
    },
    verify: (cubit) {
      verify(() => useCase.discardWalk(photoPaths: ['n1.jpg'])).called(1);
      expect(cubit.state, const WalkEditState.discarded());
    },
  );

  test('수정 모드에서는 discard 가 discardWalk 를 부르지 않는다', () async {
    when(() => useCase.getWalk('w1')).thenAnswer((_) async => Ok(walk()));
    final cubit = WalkEditCubit(useCase);
    await cubit.loadExisting('w1');
    await cubit.discard();

    verifyNever(
      () => useCase.discardWalk(photoPaths: any(named: 'photoPaths')),
    );
    expect(cubit.state, isA<WalkEditEditing>());
    await cubit.close();
  });

  test('저장 안 하고 닫으면 새 사진을 지운다', () async {
    stubStore(['n1.jpg']);
    final cubit = WalkEditCubit(useCase);
    await cubit.loadNew();
    await cubit.addPhotos([_image()]);
    await cubit.close();

    verify(() => useCase.removePhoto('n1.jpg')).called(1);
    verifyNever(
      () => useCase.discardWalk(photoPaths: any(named: 'photoPaths')),
    );
  });

  test('수정 중 추가한 사진만 닫을 때 지우고 discardWalk 는 부르지 않는다', () async {
    when(
      () => useCase.getWalk('w1'),
    ).thenAnswer((_) async => Ok(walk(photos: [_photo('old.jpg', 0)])));
    stubStore(['n1.jpg']);
    final cubit = WalkEditCubit(useCase);
    await cubit.loadExisting('w1');
    await cubit.addPhotos([_image()]);
    await cubit.close();

    verify(() => useCase.removePhoto('n1.jpg')).called(1);
    verifyNever(() => useCase.removePhoto('old.jpg'));
    verifyNever(
      () => useCase.discardWalk(photoPaths: any(named: 'photoPaths')),
    );
  });

  test('저장했으면 닫아도 사진을 지우지 않는다', () async {
    stubStore(['n1.jpg']);
    when(() => useCase.saveWalk(any())).thenAnswer((_) async => Ok(walk()));
    final cubit = WalkEditCubit(useCase);
    await cubit.loadNew();
    await cubit.addPhotos([_image()]);
    await cubit.save();
    await cubit.close();

    verifyNever(() => useCase.removePhoto(any()));
  });

  test('addPhotos 도중 닫히면 방금 쓴 파일을 지운다', () async {
    final store = Completer<Result<String>>();
    when(
      () => useCase.storePhoto(
        bytes: any(named: 'bytes'),
        extension: any(named: 'extension'),
      ),
    ).thenAnswer((_) => store.future);
    final cubit = WalkEditCubit(useCase);
    await cubit.loadNew();
    final adding = cubit.addPhotos([_image()]);
    await cubit.close();
    store.complete(const Ok('late.jpg'));
    await adding;

    verify(() => useCase.removePhoto('late.jpg')).called(1);
  });
}
