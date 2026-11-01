import 'dart:async';

import 'package:walk/domain/chat/chat_connection.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/usecase/chat_key_verifier.dart';

/// 결과를 테스트가 정하는 [ChatKeyVerifier]. 받은 (벤더, 키) 를 기록한다.
class FakeChatKeyVerifier implements ChatKeyVerifier {
  /// [verify] 가 돌려줄 결과. 기본은 정상(빈 목록).
  ModelListResult result = const ModelListResult.ok([]);

  /// null 이 아니면 [verify] 가 이것이 끝날 때까지 기다린다(로딩 중 화면 확인용).
  Completer<ModelListResult>? pending;

  /// [verify] 로 받은 값들(부른 순서대로).
  final calls = <(ChatVendor, String)>[];

  @override
  Future<ModelListResult> verify(ChatVendor vendor, String key) {
    calls.add((vendor, key));
    return pending?.future ?? Future.value(result);
  }

  @override
  Future<ChatKeyStatus?> recheckIfUnverified() async => null;
}
