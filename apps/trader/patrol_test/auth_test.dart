import 'package:daylog/features/auth/presentation/widget/failure_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/app_harness.dart';

/// 인증 전체 왕복.
///
/// 단위 테스트는 Cubit 상태 전이까지만 본다. 여기서는 라우터 리다이렉트와
/// 세션 저장까지 포함해 "실제로 화면이 넘어가는가"를 검증한다.
void main() {
  patrolTest('회원가입하면 피드로 들어가고, 로그아웃 후 같은 계정으로 다시 로그인된다', ($) async {
    await launchApp($);

    final account = await signUpNewAccount($);
    expect($('daylog'), findsOneWidget);

    // 로그아웃은 설정 탭에 있다. 하단 내비게이션 → 설정 → 확인 다이얼로그.
    await $('설정').tap();
    await $.waitUntilVisible($('로그아웃'), timeout: kWait);
    await $('로그아웃').tap();
    await $.waitUntilVisible($('로그아웃할까요?'), timeout: kWait);
    await $(TextButton).containing('로그아웃').tap();
    await $.waitUntilVisible($(const Key('signIn.email')), timeout: kWait);

    await signIn($, account.email);
    expect($('daylog'), findsOneWidget);
  });

  patrolTest('잘못된 비밀번호로는 로그인되지 않는다', ($) async {
    await launchApp($);

    await $(const Key('signIn.email')).enterText('nobody@daylog.test');
    await $(const Key('signIn.password')).enterText('wrong-password');
    await $(FilledButton).tap();

    // 오류 문구가 뜨고, 화면은 로그인에 남아 있어야 한다.
    // 문구 내용은 Supabase 응답에 따라 달라지므로 위젯 타입으로 확인한다.
    await $.waitUntilVisible($(FailureText), timeout: kWait);
    expect($(const Key('signIn.email')), findsOneWidget);
    expect($('daylog'), findsNothing);
  });
}
