import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:daylog/features/auth/domain/entity/app_user.dart';
import 'package:daylog/features/auth/domain/usecase/auth_use_case.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_event.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthUseCase extends Mock implements AuthUseCase {}

const _user = AppUser(id: 'u1', email: 'a@b.com', nickname: '테스터');

void main() {
  late _MockAuthUseCase useCase;
  late StreamController<AppUser?> controller;

  setUp(() {
    useCase = _MockAuthUseCase();
    // broadcast 를 쓴다. 단일 구독 컨트롤러는 리스너가 한 번도 없으면
    // close() 의 Future 가 완료되지 않아 tearDown 이 멈춘다.
    controller = StreamController<AppUser?>.broadcast();
    when(useCase.authStateChanges).thenAnswer((_) => controller.stream);
  });

  tearDown(() => controller.close());

  test('초기 상태는 unknown 이다', () {
    // unknown 이 없으면 앱 시작 시 로그인 화면이 번쩍였다가 홈으로 넘어간다.
    expect(AuthBloc(useCase).state, const AuthState.unknown());
  });

  blocTest<AuthBloc, AuthState>(
    '사용자가 흘러오면 authenticated 가 된다',
    build: () => AuthBloc(useCase),
    act: (bloc) async {
      bloc.add(const AuthEvent.started());
      await Future<void>.delayed(Duration.zero);
      controller.add(_user);
    },
    expect: () => [const AuthState.authenticated(_user)],
  );

  blocTest<AuthBloc, AuthState>(
    'null 이 흘러오면 unauthenticated 가 된다',
    build: () => AuthBloc(useCase),
    act: (bloc) async {
      bloc.add(const AuthEvent.started());
      await Future<void>.delayed(Duration.zero);
      controller.add(null);
    },
    expect: () => [const AuthState.unauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    '스트림이 실패해도 죽지 않고 unauthenticated 로 떨어진다',
    // onError 가 없으면 스트림이 한 번 실패한 뒤 영구히 죽어
    // 이후 로그인이 영영 반영되지 않는다.
    build: () => AuthBloc(useCase),
    act: (bloc) async {
      bloc.add(const AuthEvent.started());
      await Future<void>.delayed(Duration.zero);
      controller.addError(Exception('boom'));
    },
    expect: () => [const AuthState.unauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    '갱신 요청을 받으면 사용자를 다시 읽어 authenticated 를 다시 낸다',
    // 프로필을 고쳐도 로그인 때의 스냅샷이 그대로면 방금 쓴 글에 옛 닉네임이 붙는다.
    build: () {
      when(useCase.currentUser).thenAnswer(
        (_) async =>
            const AppUser(id: 'u1', email: 'a@b.com', nickname: '바뀐이름'),
      );
      return AuthBloc(useCase);
    },
    act: (bloc) => bloc.add(const AuthEvent.userRefreshRequested()),
    expect: () => [
      const AuthState.authenticated(
        AppUser(id: 'u1', email: 'a@b.com', nickname: '바뀐이름'),
      ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    '갱신이 실패해도 상태를 바꾸지 않는다',
    // 갱신 실패로 로그인 상태를 잃게 만들 이유는 없다.
    build: () {
      when(useCase.currentUser).thenThrow(Exception('network'));
      return AuthBloc(useCase);
    },
    act: (bloc) => bloc.add(const AuthEvent.userRefreshRequested()),
    expect: () => <AuthState>[],
  );

  blocTest<AuthBloc, AuthState>(
    '로그아웃하면 저장소를 호출하고 unauthenticated 가 된다',
    build: () {
      when(useCase.signOut).thenAnswer((_) async => const Ok(null));
      return AuthBloc(useCase);
    },
    act: (bloc) => bloc.add(const AuthEvent.signOutRequested()),
    expect: () => [const AuthState.unauthenticated()],
    verify: (_) => verify(useCase.signOut).called(1),
  );

  blocTest<AuthBloc, AuthState>(
    '로그아웃 요청이 실패해도 unauthenticated 로 만든다',
    // 서버가 응답하지 않는다고 로그아웃이 막히면 안 된다.
    build: () {
      when(useCase.signOut).thenThrow(Exception('network'));
      return AuthBloc(useCase);
    },
    act: (bloc) => bloc.add(const AuthEvent.signOutRequested()),
    errors: () => [isA<Exception>()],
  );
}
