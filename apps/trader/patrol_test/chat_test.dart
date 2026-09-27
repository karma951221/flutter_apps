import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/app_harness.dart';

/// 방 개설 → 입장 → 전송 → 수신.
///
/// 여기서만 확인되는 것은 **실시간 왕복**이다. 보낸 메시지가 서버를 돌아
/// Postgres Changes 로 되돌아오고, 앱이 낙관적 버블을 그 페이로드로 확정하는
/// 경로는 mock 으로는 확인되지 않는다 — 단위 테스트는 스트림을 직접 밀어넣기
/// 때문에 publication 이 빠져도 통과한다.
void main() {
  patrolTest('방을 만들어 메시지를 보내면 실시간으로 되돌아와 확정된다', ($) async {
    await launchApp($);
    final account = await signUpNewAccount($);

    final roomName = 'E2E 방 ${DateTime.now().millisecondsSinceEpoch}';
    final message = 'E2E 메시지 ${DateTime.now().millisecondsSinceEpoch}';

    // 채팅 탭으로. 라벨을 텍스트로 찾는 것은 탭 하나뿐이라 안전하다.
    await $('채팅').tap();
    await $.waitUntilVisible($(const Key('chatList.create')), timeout: kWait);

    // 방 개설 — 개설자는 곧바로 그 방에 들어간다.
    //
    // 화면 도착 판정과 입력은 Key 로 한다. `labelText` 는 autofocus 로 라벨이
    // 떠오르면 보이기 판정이 흔들리고, 'FAB 라벨'과 '화면 제목'처럼 같은 문구가
    // 여럿일 때도 어느 것을 잡았는지 알 수 없다 (post_test 의 postEditor.* 와
    // 같은 규칙).
    await $(const Key('chatList.create')).tap();
    await $.waitUntilVisible($(const Key('createRoom.title')), timeout: kWait);
    await $(const Key('createRoom.title')).enterText(roomName);
    await $(const Key('createRoom.submit')).tap();

    // 개설자의 입장 시스템 메시지가 방에 남는다. DB 는 'join' 키와 닉네임만
    // 저장하고 문장은 앱이 만든다 — 이 문구가 보이면 그 경로가 이어진 것이다.
    //
    // 방에서 쓸 이름의 기본값이 프로필 닉네임이라 둘이 같다. finder 가 정확히
    // 일치를 보므로 접미사만 적으면 찾지 못한다.
    await $.waitUntilVisible(
      $('${account.nickname} 님이 들어왔습니다'),
      timeout: kWait,
    );

    // 전송. 버블이 먼저 뜨고(낙관적) 서버를 돌아온 뒤 확정된다.
    await $(const Key('chatRoom.composer')).enterText(message);
    await $(const Key('chatRoom.send')).tap();
    await $.waitUntilVisible($(message), timeout: kWait);

    // 낙관적 버블은 '보내는 중' 으로 먼저 뜨고, 실시간 페이로드가 돌아오면
    // 그 표시가 사라진다. **이 전이가 이 테스트의 핵심**이다 — publication 이
    // 빠졌거나 구독이 끊겨 있으면 영원히 '보내는 중' 으로 남는다.
    //
    // `pumpAndSettle` 을 쓰지 않는다. 이 앱에는 끝나지 않는 애니메이션이 있어
    // settle 되지 않고 타임아웃한다(`launchApp` 의 주석과 같은 이유). 대신
    // 상한을 둔 폴링으로 사라지기를 기다린다.
    var confirmed = false;
    for (var i = 0; i < 60; i++) {
      await $.pump(const Duration(milliseconds: 500));
      if ($('보내는 중').evaluate().isEmpty) {
        confirmed = true;
        break;
      }
    }
    expect(confirmed, isTrue, reason: '실시간으로 되돌아와 확정되지 않았다');

    // 여기서 끝낸다. 방을 나가 목록으로 돌아가는 흐름은 위젯 테스트가 덮고
    // 있고(`ChatRoomListPage` 의 '방 열기'), 이 테스트가 확인하려는 것은
    // 실시간 왕복 하나다. 뒤로가기까지 태웠더니 테스트 본문이 끝난 **뒤에**
    // 비동기 오류가 하나 더 올라와 실패로 잡혔는데, 그 오류는 harness 가
    // 원문을 가려 원인을 짚지 못했다 — auth_test 에 이미 있는 같은 증상이다
    // (apps/trader/docs/audits/audit-2026-08-27.md).
  });
}
