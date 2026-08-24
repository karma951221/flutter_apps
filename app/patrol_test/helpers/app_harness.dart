import 'package:daylog/app/app.dart';
import 'package:daylog/bootstrap.dart';
import 'package:daylog/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// E2E 공통 준비 코드.
///
/// 여기 있는 것들은 "테스트가 무엇을 검증하는가"와 무관한 배선이다.
/// 검증 내용은 각 *_test.dart 에만 둔다.

/// 실기기에서는 Supabase 왕복이 끼므로 위젯 테스트보다 넉넉히 기다린다.
const kWait = Duration(seconds: 30);

const kTestPassword = 'daylog-e2e-1234';

/// 매 실행마다 새 계정을 만든다.
///
/// 고정 계정을 쓰면 이전 실행이 남긴 게시물 때문에 다음 실행이 흔들린다.
/// 로컬 DB 를 비우려면 `supabase db reset`.
String uniqueEmail() =>
    'e2e.${DateTime.now().microsecondsSinceEpoch}@daylog.test';

String uniqueNickname() =>
    'e2e${DateTime.now().microsecondsSinceEpoch % 100000}';

/// 실제 부팅 경로(Supabase 초기화 → DI → 위젯)로 앱을 띄운다.
///
/// 여기서 pumpAndSettle 을 쓰면 안 된다. SplashPage 의
/// CircularProgressIndicator 는 끝나지 않는 애니메이션이라 영원히 settle 되지
/// 않고 타임아웃한다. 대신 "다음 화면이 보일 때까지" 기다린다.
Future<void> launchApp(PatrolIntegrationTester $) async {
  await getIt.reset();
  await initializeApp();
  await _signOutQuietly();

  await $.tester.pumpWidget(const DaylogApp());
  await $.waitUntilVisible($(const Key('signIn.email')), timeout: kWait);
}

/// 세션이 없을 때 signOut 은 예외를 던진다. 여기서는 정리 목적이라 무시한다.
Future<void> _signOutQuietly() async {
  try {
    await Supabase.instance.client.auth.signOut();
  } on Exception {
    // 로그인된 적이 없으면 지울 세션도 없다.
  }
}

/// 로그인 화면에서 시작해 새 계정을 만들고 피드까지 들어간다.
///
/// 반환값은 만들어진 계정. 이어지는 로그인 검증에 쓴다.
Future<({String email, String nickname})> signUpNewAccount(
  PatrolIntegrationTester $,
) async {
  final email = uniqueEmail();
  final nickname = uniqueNickname();

  await $('회원가입').tap();
  await $.waitUntilVisible($(const Key('signUp.email')), timeout: kWait);

  await $(const Key('signUp.email')).enterText(email);
  await $(const Key('signUp.nickname')).enterText(nickname);
  await $(const Key('signUp.password')).enterText(kTestPassword);
  await $(const Key('signUp.passwordConfirm')).enterText(kTestPassword);

  // 라벨 '가입하기' 는 이 화면에서 버튼에만 있다.
  await $('가입하기').tap();
  await waitForFeed($);

  return (email: email, nickname: nickname);
}

/// 로그인 화면에서 기존 계정으로 들어간다.
Future<void> signIn(PatrolIntegrationTester $, String email) async {
  await $(const Key('signIn.email')).enterText(email);
  await $(const Key('signIn.password')).enterText(kTestPassword);

  // '로그인' 은 AppBar 제목과 버튼 라벨 양쪽에 있어 텍스트로 찾으면 2개가 잡힌다.
  // AppButton.primary 는 FilledButton 으로 그려지고 이 화면엔 하나뿐이다.
  await $(FilledButton).tap();
  await waitForFeed($);
}

/// 피드(홈)에 도착할 때까지 기다린다. AppBar 제목 'daylog' 가 표식이다.
Future<void> waitForFeed(PatrolIntegrationTester $) =>
    $.waitUntilVisible($('daylog'), timeout: kWait);
