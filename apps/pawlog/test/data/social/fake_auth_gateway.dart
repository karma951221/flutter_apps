import 'dart:async';

import 'package:pawlog/data/social/supabase_auth_gateway.dart';

/// [SupabaseAuthGateway] 의 손으로 짠 대역. 실패를 던지게 하려면 `*Error` 를 채운다.
class FakeAuthGateway implements SupabaseAuthGateway {
  FakeAuthGateway({this.currentUserId});

  @override
  String? currentUserId;

  final userIds = StreamController<String?>.broadcast();
  final nicknames = <String, String>{};
  Object? signInError;
  Object? signUpError;
  Object? nicknameError;
  Object? nicknameCheckError;
  final calls = <String>[];

  @override
  Stream<String?> get userIdChanges => userIds.stream;

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    calls.add('signIn $email');
    if (signInError case final error?) throw error;
    return currentUserId = 'u1';
  }

  @override
  Future<String> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    calls.add('signUp $email $nickname');
    if (signUpError case final error?) throw error;
    nicknames['u1'] = nickname;
    return currentUserId = 'u1';
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    currentUserId = null;
  }

  @override
  Future<String?> fetchNickname(String userId) async {
    if (nicknameError case final error?) throw error;
    return nicknames[userId];
  }

  @override
  Future<bool> isNicknameTaken(String nickname) async {
    calls.add('check $nickname');
    if (nicknameCheckError case final error?) throw error;
    return nicknames.values.any(
      (taken) => taken.toLowerCase() == nickname.trim().toLowerCase(),
    );
  }
}
