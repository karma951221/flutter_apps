import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:pawlog/presentation/theme/pawlog_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/domain/backup/entity/backup_import_result.dart';
import 'package:pawlog/domain/dog/entity/dog.dart';
import 'package:pawlog/domain/dog/entity/dog_draft.dart';
import 'package:pawlog/presentation/common/widget/pawlog_primary_button.dart';
import 'package:pawlog/presentation/dog/cubit/dog_edit_cubit.dart';
import 'package:pawlog/presentation/dog/page/dog_edit_page.dart';

import '../../../support/fakes.dart';
import '../../../support/mock_image_picker_service.dart';
import '../../../support/mock_walk_use_case.dart';
import '../../../support/pump_app.dart';

void main() {
  late MockWalkUseCase useCase;
  late MockImagePickerService picker;

  setUpAll(() {
    registerFallbackValue(const DogDraft(name: ''));
    registerFallbackValue(Uint8List(0));
  });
  setUp(() {
    useCase = MockWalkUseCase();
    picker = MockImagePickerService();
    when(() => useCase.removePhoto(any())).thenAnswer((_) async {});
    when(() => useCase.photoFile(any())).thenReturn(File('/no/such/photo.jpg'));
    getIt
      ..registerFactory<DogEditCubit>(() => DogEditCubit(useCase))
      ..registerSingleton<ImagePickerService>(picker);
  });
  tearDown(getIt.reset);

  testWidgets('신규는 메뉴 없이 등록 제목을 보인다', (tester) async {
    await pumpApp(tester, DogEditPage(onDone: () {}));

    expect(find.text('반려견 등록'), findsOneWidget);
    expect(find.byKey(const Key('walk-dog-menu')), findsNothing);
  });

  testWidgets('이름을 입력하고 저장하면 onDone 을 한 번 부른다', (tester) async {
    when(() => useCase.saveDog(any())).thenAnswer((_) async => Ok(dog('1')));
    var done = 0;
    await pumpApp(tester, DogEditPage(onDone: () => done++));

    await tester.enterText(find.byKey(const Key('walk-dog-name-field')), '콩이');
    await tester.tap(find.byKey(const Key('walk-dog-save-button')));
    await tester.pumpAndSettle();

    verify(() => useCase.saveDog(const DogDraft(name: '콩이'))).called(1);
    expect(done, 1);
  });

  testWidgets('이름이 비면 스낵바가 아니라 이름 입력칸 아래에 알린다(QA P3)', (tester) async {
    when(() => useCase.saveDog(any())).thenAnswer(
      (_) async => const Err(
        Failure.validation(failureCode: FailureCode.dogNameRequired),
      ),
    );
    var done = 0;
    await pumpApp(tester, DogEditPage(onDone: () => done++));

    await tester.tap(find.byKey(const Key('walk-dog-save-button')));
    await tester.pumpAndSettle();

    String? nameError() => tester
        .widget<TextField>(find.byKey(const Key('walk-dog-name-field')))
        .decoration
        ?.errorText;
    expect(nameError(), '반려견 이름을 입력해 주세요');
    expect(find.byType(SnackBar), findsNothing);
    expect(done, 0);

    // 이름을 고치면 안내가 사라진다.
    await tester.enterText(find.byKey(const Key('walk-dog-name-field')), '콩');
    await tester.pumpAndSettle();
    expect(nameError(), isNull);
  });

  testWidgets('이름 외의 저장 실패는 스낵바로 알린다', (tester) async {
    when(
      () => useCase.saveDog(any()),
    ).thenAnswer((_) async => const Err(Failure.unknown()));
    await pumpApp(tester, DogEditPage(onDone: () {}));

    await tester.enterText(find.byKey(const Key('walk-dog-name-field')), '콩이');
    await tester.tap(find.byKey(const Key('walk-dog-save-button')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  group('사진 변경', () {
    final image = PreparedImage(
      bytes: Uint8List.fromList([1]),
      width: 1,
      height: 1,
      contentType: 'image/jpeg',
      extension: 'jpg',
    );

    setUp(() {
      when(
        () => useCase.storePhoto(
          bytes: any(named: 'bytes'),
          extension: any(named: 'extension'),
        ),
      ).thenAnswer((_) async => const Ok('new.jpg'));
    });

    Future<void> chooseSource(WidgetTester tester, String key) async {
      await tester.tap(find.byKey(const Key('walk-dog-photo-button')));
      await tester.pumpAndSettle();
      // 산책 사진과 같은 출처 시트 — 앨범 · 카메라 둘 다 있다.
      expect(find.byKey(const Key('walk-edit-photo-gallery')), findsOneWidget);
      expect(find.byKey(const Key('walk-edit-photo-camera')), findsOneWidget);
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    testWidgets('카메라를 고르면 captureImage 로 찍어 저장한다', (tester) async {
      when(() => picker.captureImage()).thenAnswer((_) async => image);
      await pumpApp(tester, DogEditPage(onDone: () {}));

      await chooseSource(tester, 'walk-edit-photo-camera');

      verify(() => picker.captureImage()).called(1);
      verifyNever(() => picker.pickImage());
      verify(
        () => useCase.storePhoto(bytes: image.bytes, extension: 'jpg'),
      ).called(1);
    });

    testWidgets('앨범을 고르면 갤러리 선택(pickImage)으로 간다', (tester) async {
      // XFile 은 core 밖으로 내보내지 않는다 — 고르다 취소한 경우로 갈래만 본다.
      when(() => picker.pickImage()).thenAnswer((_) async => null);
      await pumpApp(tester, DogEditPage(onDone: () {}));

      await chooseSource(tester, 'walk-edit-photo-gallery');

      verify(() => picker.pickImage()).called(1);
      verifyNever(() => picker.captureImage());
      verifyNever(
        () => useCase.storePhoto(
          bytes: any(named: 'bytes'),
          extension: any(named: 'extension'),
        ),
      );
    });

    testWidgets('시트를 닫으면 아무것도 고르지 않는다', (tester) async {
      await pumpApp(tester, DogEditPage(onDone: () {}));

      await tester.tap(find.byKey(const Key('walk-dog-photo-button')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      verifyNever(() => picker.captureImage());
      verifyNever(() => picker.pickImage());
    });

    testWidgets('카메라로 찍고 저장하지 않고 나가면 새 사진 파일을 지운다', (tester) async {
      when(() => picker.captureImage()).thenAnswer((_) async => image);
      await pumpApp(tester, DogEditPage(onDone: () {}));
      await chooseSource(tester, 'walk-edit-photo-camera');

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      verify(() => useCase.removePhoto('new.jpg')).called(1);
    });
  });

  testWidgets('기존 반려견을 불러오는 동안에도 수정 제목을 보인다', (tester) async {
    final pending = Completer<Result<Dog?>>();
    when(() => useCase.getDog('1')).thenAnswer((_) => pending.future);
    // 스피너가 끝없이 돌아 pumpAndSettle 을 쓸 수 없다.
    await tester.pumpWidget(
      MaterialApp(
        theme: PawlogTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DogEditPage(dogId: '1', onDone: () {}),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('반려견 수정'), findsOneWidget);
    expect(find.text('반려견 등록'), findsNothing);
  });

  group('수정', () {
    setUp(() {
      when(() => useCase.getDog('1')).thenAnswer((_) async => Ok(dog('1')));
      when(
        () => useCase.deleteDog('1'),
      ).thenAnswer((_) async => const Ok(null));
    });

    Future<void> openDeleteDialog(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('walk-dog-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
    }

    testWidgets('메뉴에서 삭제를 확인하면 deleteDog 후 onDone 을 부른다', (tester) async {
      var done = 0;
      await pumpApp(tester, DogEditPage(dogId: '1', onDone: () => done++));

      expect(find.text('반려견 수정'), findsOneWidget);
      expect(find.widgetWithText(TextField, '콩이1'), findsOneWidget);

      await openDeleteDialog(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('삭제'),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => useCase.deleteDog('1')).called(1);
      expect(done, 1);
    });

    testWidgets('삭제를 취소하면 deleteDog 를 부르지 않는다', (tester) async {
      var done = 0;
      await pumpApp(tester, DogEditPage(dogId: '1', onDone: () => done++));

      await openDeleteDialog(tester);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      verifyNever(() => useCase.deleteDog(any()));
      expect(done, 0);
    });
  });

  group('백업에서 가져오기', () {
    const button = Key('dog-edit-import-backup');
    const save = Key('walk-dog-save-button');

    TextButton importButton(WidgetTester tester) => tester.widget<TextButton>(
      find.descendant(
        of: find.byKey(button),
        matching: find.byType(TextButton),
      ),
    );

    setUp(() {
      when(() => useCase.getDogs()).thenAnswer((_) async => const Ok([]));
    });

    testWidgets('첫 실행 등록 화면에만 버튼이 보인다', (tester) async {
      await pumpApp(tester, DogEditPage(onDone: () {}, showImportBackup: true));

      expect(find.byKey(button), findsOneWidget);
      expect(find.text('백업에서 가져오기'), findsOneWidget);
    });

    testWidgets('기본 등록 화면에는 버튼이 없다', (tester) async {
      await pumpApp(tester, DogEditPage(onDone: () {}));

      expect(find.byKey(button), findsNothing);
    });

    testWidgets('수정 화면에는 버튼이 없다', (tester) async {
      when(() => useCase.getDog('1')).thenAnswer((_) async => Ok(dog('1')));
      await pumpApp(
        tester,
        DogEditPage(dogId: '1', onDone: () {}, showImportBackup: true),
      );

      expect(find.byKey(button), findsNothing);
    });

    testWidgets('반려견을 가져오면 스낵바와 함께 onImported 를 부른다', (tester) async {
      when(
        () => useCase.importBackup(),
      ).thenAnswer((_) async => const BackupImportResult.imported(1, 2));
      when(() => useCase.getDogs()).thenAnswer((_) async => Ok([dog('1')]));
      var imported = 0;
      await pumpApp(
        tester,
        DogEditPage(
          onDone: () {},
          showImportBackup: true,
          onImported: () => imported++,
        ),
      );

      await tester.tap(find.byKey(button));
      await tester.pumpAndSettle();

      expect(imported, 1);
      expect(find.text('반려견 1마리 · 산책 2개를 가져왔어요'), findsOneWidget);
    });

    for (final result in [
      const BackupImportResult.nothingNew(),
      const BackupImportResult.invalid(),
      const BackupImportResult.cancelled(),
      const BackupImportResult.imported(0, 0),
    ]) {
      testWidgets('$result 이고 반려견이 없으면 onImported 를 부르지 않는다', (tester) async {
        when(() => useCase.importBackup()).thenAnswer((_) async => result);
        var imported = 0;
        await pumpApp(
          tester,
          DogEditPage(
            onDone: () {},
            showImportBackup: true,
            onImported: () => imported++,
          ),
        );

        await tester.tap(find.byKey(button));
        await tester.pumpAndSettle();

        expect(imported, 0);
      });
    }

    testWidgets('실패했어도 이미 반려견이 있으면 스낵바와 함께 onImported 를 부른다', (tester) async {
      when(() => useCase.importBackup()).thenAnswer(
        (_) async => const BackupImportResult.failed(Failure.unknown()),
      );
      when(() => useCase.getDogs()).thenAnswer((_) async => Ok([dog('1')]));
      var imported = 0;
      await pumpApp(
        tester,
        DogEditPage(
          onDone: () {},
          showImportBackup: true,
          onImported: () => imported++,
        ),
      );

      await tester.tap(find.byKey(button));
      await tester.pumpAndSettle();

      expect(imported, 1);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('가져오는 동안 저장과 가져오기 버튼을 막고 진행 표시를 보인다', (tester) async {
      final importing = Completer<BackupImportResult>();
      when(() => useCase.importBackup()).thenAnswer((_) => importing.future);
      await pumpApp(tester, DogEditPage(onDone: () {}, showImportBackup: true));

      await tester.tap(find.byKey(button));
      await tester.pump();

      expect(importButton(tester).onPressed, isNull);
      expect(
        tester.widget<PawlogPrimaryButton>(find.byKey(save)).onPressed,
        isNull,
      );
      expect(
        find.byKey(const Key('dog-edit-import-backup-progress')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(save), warnIfMissed: false);
      await tester.pump();
      verifyNever(() => useCase.saveDog(any()));

      importing.complete(const BackupImportResult.cancelled());
      await tester.pumpAndSettle();

      expect(importButton(tester).onPressed, isNotNull);
      expect(
        tester.widget<PawlogPrimaryButton>(find.byKey(save)).onPressed,
        isNotNull,
      );
      expect(
        find.byKey(const Key('dog-edit-import-backup-progress')),
        findsNothing,
      );
    });

    testWidgets('읽을 수 없는 파일은 스낵바로 알린다', (tester) async {
      when(
        () => useCase.importBackup(),
      ).thenAnswer((_) async => const BackupImportResult.invalid());
      await pumpApp(tester, DogEditPage(onDone: () {}, showImportBackup: true));

      await tester.tap(find.byKey(button));
      await tester.pumpAndSettle();

      expect(find.text('백업 파일을 읽지 못했어요'), findsOneWidget);
    });
  });
}
