import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/core/di/injection.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/auth/domain/entity/app_user.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_event.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_state.dart';
import 'package:daylog/features/profile/domain/entity/profile.dart';
import 'package:daylog/features/profile/domain/usecase/profile_use_case.dart';
import 'package:daylog/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:daylog/features/profile/presentation/page/edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileUseCase extends Mock implements ProfileUseCase {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

const _me = AppUser(id: 'me', email: 'me@example.test', nickname: '카르마');

final _profile = Profile(
  id: 'me',
  nickname: '카르마',
  createdAt: DateTime.utc(2026, 8, 22, 9),
  updatedAt: DateTime.utc(2026, 8, 22, 9),
);

void main() {
  late _MockProfileUseCase useCase;
  late _MockAuthBloc authBloc;

  setUp(() {
    useCase = _MockProfileUseCase();
    authBloc = _MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(_me),
    );
    when(useCase.getMyProfile).thenAnswer((_) async => Ok(_profile));

    getIt.registerFactory<ProfileCubit>(() => ProfileCubit(useCase));
  });

  tearDown(getIt.reset);

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const EditProfilePage(),
        ),
      ),
    );
    await tester.pump();
  }

  /// 디바운스가 지나 조회 결과가 화면에 닿을 때까지 민다.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(
      ProfileCubit.nicknameCheckDebounce + const Duration(milliseconds: 100),
    );
    await tester.pump();
  }

  testWidgets('닉네임을 바꾸면 사용 가능 여부를 미리 알려준다', (tester) async {
    when(
      () => useCase.isNicknameAvailable(any()),
    ).thenAnswer((_) async => const Ok(true));

    await pumpPage(tester);
    await tester.enterText(find.byType(TextFormField).first, '새이름');
    await settle(tester);

    expect(find.text('사용할 수 있는 닉네임입니다'), findsOneWidget);
    verify(() => useCase.isNicknameAvailable('새이름')).called(1);
  });

  testWidgets('이미 쓰이는 닉네임은 저장하기 전에 알려준다', (tester) async {
    when(
      () => useCase.isNicknameAvailable(any()),
    ).thenAnswer((_) async => const Ok(false));

    await pumpPage(tester);
    await tester.enterText(find.byType(TextFormField).first, '겹치는이름');
    await settle(tester);

    expect(find.text('이미 사용 중인 닉네임입니다'), findsOneWidget);
  });

  testWidgets('지금 쓰고 있는 닉네임은 확인하지 않는다', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextFormField).first, '카르마');
    await settle(tester);

    expect(find.text('사용할 수 있는 닉네임입니다'), findsNothing);
    expect(find.text('이미 사용 중인 닉네임입니다'), findsNothing);
    verifyNever(() => useCase.isNicknameAvailable(any()));
  });
}
