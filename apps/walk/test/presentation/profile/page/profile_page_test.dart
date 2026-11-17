import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/profile/profile.dart';
import 'package:walk/presentation/diary/media_picker.dart';
import 'package:walk/presentation/profile/cubit/profile_cubit.dart';
import 'package:walk/presentation/profile/page/profile_page.dart';

import '../../../support/fake_profile_repository.dart';

class _MockPicker extends Mock implements MediaPicker {}

void main() {
  late FakeProfileRepository repo;
  late ProfileCubit cubit;
  late _MockPicker picker;

  setUpAll(() => registerFallbackValue(<PickedMedia>[]));

  setUp(() {
    repo = FakeProfileRepository();
    cubit = ProfileCubit(repo);
    picker = _MockPicker();
    when(() => picker.release(any())).thenAnswer((_) async {});
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => ProfilePage.open(context, picker: picker),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder field(String key) => find.byKey(Key(key));

  testWidgets('이름 · 소개 · 이름 알려주기를 저장하고 닫는다', (tester) async {
    await open(tester);
    expect(find.text('프로필'), findsOneWidget);

    await tester.enterText(field('profile-name'), '하늘');
    await tester.enterText(field('profile-bio'), '걷는 사람');
    await tester.tap(field('profile-share-name'));
    await tester.pump();
    await tester.tap(field('profile-save'));
    await tester.pumpAndSettle();

    expect(
      repo.profile,
      const Profile(name: '하늘', bio: '걷는 사람', shareNameWithAi: true),
    );
    expect(find.text('open'), findsOneWidget);
    expect(find.text('프로필을 저장했어요'), findsOneWidget);
  });

  testWidgets('이름 알려주기는 기본 꺼짐이고 설명이 보인다', (tester) async {
    await open(tester);
    final tile = tester.widget<Switch>(
      find.descendant(
        of: field('profile-share-name'),
        matching: find.byType(Switch),
      ),
    );
    expect(tile.value, isFalse);
    expect(find.textContaining('Claude · GPT 로 전송'), findsOneWidget);
  });

  testWidgets('앨범에서 고른 사진은 저장할 때 바꾸고 캐시 사본을 지운다', (tester) async {
    when(
      () => picker.pickProfilePhoto(camera: false),
    ).thenAnswer((_) async => '/cache/me.jpg');
    await open(tester);

    await tester.tap(field('profile-photo'));
    await tester.pumpAndSettle();
    expect(find.text('사진 지우기'), findsNothing);
    await tester.tap(find.text('앨범에서 고르기'));
    await tester.pumpAndSettle();
    expect(repo.setPhotoCalls, isEmpty);

    await tester.tap(field('profile-save'));
    await tester.pumpAndSettle();

    expect(repo.setPhotoCalls, ['/cache/me.jpg']);
    expect(repo.profile.photo, 'me.jpg');
    final released =
        verify(() => picker.release(captureAny())).captured.single
            as List<PickedMedia>;
    expect(released.single.path, '/cache/me.jpg');
  });

  testWidgets('사진이 있으면 지우기를 고를 수 있다', (tester) async {
    repo.profile = const Profile(name: '하늘', photo: 'a.jpg');
    cubit.load();
    await open(tester);

    await tester.tap(field('profile-photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('사진 지우기'));
    await tester.pumpAndSettle();
    await tester.tap(field('profile-save'));
    await tester.pumpAndSettle();

    expect(repo.profile.photo, isNull);
  });

  testWidgets('사진 저장이 실패하면 화면에 남고 오류를 알린다', (tester) async {
    repo.failPhoto = true;
    when(
      () => picker.pickProfilePhoto(camera: true),
    ).thenAnswer((_) async => '/cache/shot.jpg');
    await open(tester);

    await tester.tap(field('profile-photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('사진 찍기'));
    await tester.pumpAndSettle();
    await tester.tap(field('profile-save'));
    await tester.pumpAndSettle();

    expect(find.text('프로필을 저장하지 못했어요'), findsOneWidget);
    expect(field('profile-save'), findsOneWidget);
  });

  testWidgets('바꾼 게 있으면 뒤로 갈 때 묻고, 버리면 저장하지 않는다', (tester) async {
    await open(tester);
    await tester.enterText(field('profile-name'), '바다');
    await tester.pump();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('바꾼 내용을 버릴까요?'), findsOneWidget);

    await tester.tap(find.text('버리기'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(repo.profile.name, '');
  });

  testWidgets('바꾼 게 없으면 바로 닫는다', (tester) async {
    await open(tester);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });
}
