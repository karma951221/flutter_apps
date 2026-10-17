import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/domain/tracking/entity/tracker_state.dart';
import 'package:pawlog/domain/walk/entity/walk_draft.dart';
import 'package:pawlog/domain/walk/entity/walk_photo.dart';
import 'package:pawlog/domain/walk/entity/walk_update.dart';
import 'package:pawlog/presentation/theme/pawlog_theme.dart';
import 'package:pawlog/presentation/walk/cubit/walk_edit_cubit.dart';
import 'package:pawlog/presentation/walk/page/walk_edit_page.dart';

import '../../../support/fakes.dart';
import '../../../support/mock_image_picker_service.dart';
import '../../../support/mock_social_use_case.dart';
import '../../../support/mock_walk_use_case.dart';
import '../../../support/pump_app.dart';

void main() {
  late MockWalkUseCase useCase;
  late MockImagePickerService picker;
  late MockSocialUseCase social;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(
      WalkDraft(
        startedAt: t0,
        endedAt: t1,
        duration: const Duration(minutes: 30),
        distanceMeters: 0,
        points: const [],
        dogIds: const [],
        photoPaths: const [],
      ),
    );
    registerFallbackValue(
      const WalkUpdate(id: 'w1', dogIds: [], photoPaths: []),
    );
  });

  setUp(() {
    useCase = MockWalkUseCase();
    picker = MockImagePickerService();
    social = MockSocialUseCase();
    when(
      () => social.updateSharedWalk(any()),
    ).thenAnswer((_) async => const Ok(null));
    when(() => useCase.trackerState).thenReturn(
      TrackerState.finished(
        walkSession(
          points: [trackPoint(37.5)],
          distanceMeters: 800,
          endedAt: t1,
        ),
      ),
    );
    when(
      () => useCase.getDogs(),
    ).thenAnswer((_) async => Ok([dog('d1'), dog('d2')]));
    when(() => useCase.removePhoto(any())).thenAnswer((_) async {});
    when(() => useCase.photoFile(any())).thenReturn(File('/no/such/photo.jpg'));
    when(
      () => useCase.discardWalk(photoPaths: any(named: 'photoPaths')),
    ).thenAnswer((_) async {});
    getIt
      ..registerFactory<WalkEditCubit>(() => WalkEditCubit(useCase, social))
      ..registerSingleton<ImagePickerService>(picker);
  });
  tearDown(getIt.reset);

  /// 저장 · 버리기 버튼까지 한 화면에 그려지도록 세로로 긴 화면을 쓴다.
  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('신규', () {
    testWidgets('요약에 경로 그림이 있고 메모 입력은 손글씨다', (tester) async {
      useTallScreen(tester);
      await pumpApp(tester, WalkEditPage(onSaved: (_) {}, onDiscarded: () {}));

      expect(find.byKey(const Key('walk-edit-route')), findsOneWidget);
      final memo = tester.widget<TextField>(
        find.byKey(const Key('walk-edit-memo-field')),
      );
      expect(memo.style?.fontFamily, PawlogFonts.memo);
    });

    testWidgets('반려견 없이 저장하면 스낵바를 보인다', (tester) async {
      useTallScreen(tester);
      when(() => useCase.saveWalk(any())).thenAnswer(
        (_) async => const Err(
          Failure.validation(failureCode: FailureCode.walkDogRequired),
        ),
      );
      var saved = 0;
      await pumpApp(
        tester,
        WalkEditPage(onSaved: (_) => saved++, onDiscarded: () {}),
      );

      await tester.tap(find.byKey(const Key('walk-edit-dog-chip-d1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('walk-edit-save-button')));
      await tester.pumpAndSettle();

      expect(find.text('함께 산책한 반려견을 선택해 주세요'), findsOneWidget);
      expect(saved, 0);
    });

    testWidgets('저장하면 onSaved(id) 를 한 번 부른다', (tester) async {
      useTallScreen(tester);
      when(() => useCase.saveWalk(any())).thenAnswer((_) async => Ok(walk()));
      final saved = <String>[];
      await pumpApp(
        tester,
        WalkEditPage(onSaved: saved.add, onDiscarded: () {}),
      );

      await tester.enterText(
        find.byKey(const Key('walk-edit-memo-field')),
        '  즐거웠다 ',
      );
      await tester.tap(find.byKey(const Key('walk-edit-save-button')));
      await tester.pumpAndSettle();

      final draft =
          verify(() => useCase.saveWalk(captureAny())).captured.single
              as WalkDraft;
      expect(draft.memo, '즐거웠다');
      expect(draft.dogIds, ['d1']);
      expect(saved, ['w1']);
    });

    testWidgets('앨범에서 사진을 고르면 썸네일이 생기고 저장에 실린다', (tester) async {
      useTallScreen(tester);
      when(() => picker.pickImages(limit: any(named: 'limit'))).thenAnswer(
        (_) async => [
          PreparedImage(
            bytes: Uint8List.fromList([1]),
            width: 1,
            height: 1,
            contentType: 'image/jpeg',
            extension: 'jpg',
          ),
        ],
      );
      when(
        () => useCase.storePhoto(
          bytes: any(named: 'bytes'),
          extension: any(named: 'extension'),
        ),
      ).thenAnswer((_) async => const Ok('n1.jpg'));
      await pumpApp(tester, WalkEditPage(onSaved: (_) {}, onDiscarded: () {}));

      await tester.tap(find.byKey(const Key('walk-edit-add-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('앨범에서 고르기'));
      await tester.pumpAndSettle();

      verify(() => picker.pickImages(limit: 10)).called(1);
      expect(find.byKey(const Key('walk-edit-photo-0')), findsOneWidget);
      expect(find.byKey(const Key('walk-edit-remove-photo-0')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      verify(() => useCase.removePhoto('n1.jpg')).called(1);
    });

    testWidgets('뒤로 가기는 버리기 확인을 띄우고, 취소하면 아무 일도 없다', (tester) async {
      useTallScreen(tester);
      var discarded = 0;
      await pumpApp(
        tester,
        WalkEditPage(onSaved: (_) {}, onDiscarded: () => discarded++),
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('이 산책을 버릴까요?'), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      verifyNever(
        () => useCase.discardWalk(photoPaths: any(named: 'photoPaths')),
      );
      expect(discarded, 0);
    });

    testWidgets('뒤로 가기 확인에서 버리면 discardWalk 후 onDiscarded', (tester) async {
      useTallScreen(tester);
      var discarded = 0;
      await pumpApp(
        tester,
        WalkEditPage(onSaved: (_) {}, onDiscarded: () => discarded++),
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('버리기'),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => useCase.discardWalk(photoPaths: [])).called(1);
      expect(discarded, 1);
    });

    testWidgets('버리기 버튼도 같은 확인을 거친다', (tester) async {
      useTallScreen(tester);
      await pumpApp(tester, WalkEditPage(onSaved: (_) {}, onDiscarded: () {}));

      await tester.tap(find.byKey(const Key('walk-edit-discard-button')));
      await tester.pumpAndSettle();

      expect(find.text('이 산책을 버릴까요?'), findsOneWidget);
    });

    testWidgets('세션이 없으면 안내와 피드로 돌아가기 버튼을 보인다', (tester) async {
      useTallScreen(tester);
      when(() => useCase.trackerState).thenReturn(const TrackerState.idle());
      var discarded = 0;
      await pumpApp(
        tester,
        WalkEditPage(onSaved: (_) {}, onDiscarded: () => discarded++),
      );

      expect(find.text('저장할 산책이 없습니다'), findsOneWidget);
      await tester.tap(find.text('피드로 돌아가기'));
      await tester.pumpAndSettle();

      expect(discarded, 1);
    });
  });

  group('수정', () {
    setUp(() {
      when(() => useCase.getWalk('w1')).thenAnswer(
        (_) async => Ok(
          walk(
            photos: const [WalkPhoto(id: 'p0', path: 'old.jpg', position: 0)],
          ).copyWith(memo: '전 메모'),
        ),
      );
    });

    testWidgets('수정 모드에는 버리기 버튼이 없고 기존 값이 채워진다', (tester) async {
      useTallScreen(tester);
      await pumpApp(
        tester,
        WalkEditPage(walkId: 'w1', onSaved: (_) {}, onDiscarded: () {}),
      );

      expect(find.text('산책 수정'), findsOneWidget);
      expect(find.byKey(const Key('walk-edit-discard-button')), findsNothing);
      expect(find.widgetWithText(TextField, '전 메모'), findsOneWidget);
      expect(find.byKey(const Key('walk-edit-photo-0')), findsOneWidget);
    });

    testWidgets('저장하면 updateWalk 후 onSaved(id)', (tester) async {
      useTallScreen(tester);
      when(() => useCase.updateWalk(any())).thenAnswer((_) async => Ok(walk()));
      final saved = <String>[];
      await pumpApp(
        tester,
        WalkEditPage(walkId: 'w1', onSaved: saved.add, onDiscarded: () {}),
      );

      await tester.tap(find.byKey(const Key('walk-edit-save-button')));
      await tester.pumpAndSettle();

      verify(() => useCase.updateWalk(any())).called(1);
      expect(saved, ['w1']);
    });

    group('공유한 글 고치기', () {
      const failedMessage = '기록은 고쳤지만 공유한 글은 바꾸지 못했어요';

      /// 상세에서 수정 화면을 올리고, 저장하면 닫는다(라우터와 같은 흐름).
      Future<void> openEditFromHost(WidgetTester tester) async {
        useTallScreen(tester);
        when(
          () => useCase.updateWalk(any()),
        ).thenAnswer((_) async => Ok(walk()));
        await pumpApp(
          tester,
          Builder(
            builder: (host) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(host).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WalkEditPage(
                      walkId: 'w1',
                      onSaved: (_) => Navigator.of(host).pop(),
                      onDiscarded: () {},
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
      }

      testWidgets('실패해도 기록은 저장되고 화면이 닫힌 뒤 스낵바를 보인다', (tester) async {
        final server = Completer<Result<void>>();
        when(
          () => social.updateSharedWalk('w1'),
        ).thenAnswer((_) => server.future);
        await openEditFromHost(tester);

        await tester.tap(find.byKey(const Key('walk-edit-save-button')));
        await tester.pumpAndSettle();

        // 서버를 기다리지 않고 닫힌다.
        verify(() => useCase.updateWalk(any())).called(1);
        expect(find.byType(WalkEditPage), findsNothing);
        expect(find.text(failedMessage), findsNothing);

        server.complete(
          const Err(
            Failure.network(failureCode: FailureCode.networkUnavailable),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(failedMessage), findsOneWidget);
      });

      testWidgets('성공하면 스낵바가 없다', (tester) async {
        await openEditFromHost(tester);

        await tester.tap(find.byKey(const Key('walk-edit-save-button')));
        await tester.pumpAndSettle();

        verify(() => social.updateSharedWalk('w1')).called(1);
        expect(find.byType(WalkEditPage), findsNothing);
        expect(find.text(failedMessage), findsNothing);
      });
    });

    testWidgets('기존 사진을 빼도 파일은 지우지 않는다', (tester) async {
      useTallScreen(tester);
      await pumpApp(
        tester,
        WalkEditPage(walkId: 'w1', onSaved: (_) {}, onDiscarded: () {}),
      );

      await tester.tap(find.byKey(const Key('walk-edit-remove-photo-0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('walk-edit-photo-0')), findsNothing);
      verifyNever(() => useCase.removePhoto(any()));
    });
  });
}
