import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/app_harness.dart';

/// 게시물 작성 → 피드 반영 → 삭제.
///
/// 작성 화면이 pop 하면서 넘긴 Post 를 피드가 받아 목록에 끼워 넣는 경로를
/// 실제로 태워본다. 이 연결은 단위 테스트로는 확인되지 않는다.
void main() {
  patrolTest('작성한 게시물이 피드에 바로 보이고 삭제하면 사라진다', ($) async {
    await launchApp($);
    await signUpNewAccount($);

    final content = 'E2E 기록 ${DateTime.now().millisecondsSinceEpoch}';

    // 작성
    await $('작성').tap();
    await $.waitUntilVisible(
      $(const Key('postEditor.content')),
      timeout: kWait,
    );
    await $(const Key('postEditor.content')).enterText(content);
    await $('올리기').tap();

    await $.waitUntilVisible($(content), timeout: kWait);

    // 삭제 — PopupMenuButton 은 기본 아이콘이 more_vert 다.
    await $(Icons.more_vert).tap();
    await $.waitUntilVisible($('삭제'), timeout: kWait);
    await $('삭제').tap();

    // 확인 다이얼로그. '삭제' 라벨이 다이얼로그 안에서 다시 나온다.
    await $.waitUntilVisible($('게시물을 삭제할까요?'), timeout: kWait);
    await $('삭제').tap();

    await $.waitUntilVisible($('게시물을 삭제했습니다.'), timeout: kWait);
    expect($(content), findsNothing);
  });
}
