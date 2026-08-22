import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/app_user.dart';
import '../../domain/usecase/auth_use_case.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// 전역 인증 상태를 들고 있는 유일한 주체.
///
/// 화면들은 이 상태를 읽기만 하고, 라우터가 이 상태를 보고 접근을 통제한다.
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._useCase) : super(const AuthState.unknown()) {
    on<AuthStarted>(_onStarted);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  final AuthUseCase _useCase;
  StreamSubscription<AppUser?>? _subscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _subscription?.cancel();
    _subscription = _useCase.authStateChanges().listen(
      (user) {
        debugPrint('[auth] bloc 수신: ${user?.nickname ?? "null"}');
        add(AuthEvent.userChanged(user));
      },
      // onError 가 없으면 스트림이 한 번 실패한 뒤 영구히 죽는다.
      onError: (Object e, StackTrace st) {
        debugPrint('[auth] 스트림 오류: $e');
        add(const AuthEvent.userChanged(null));
      },
    );
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    emit(
      event.user == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(event.user!),
    );
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _useCase.signOut();
    // 실패해도 로컬 세션은 정리된 것으로 본다. 로그아웃이 막히면 안 된다.
    emit(const AuthState.unauthenticated());
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
