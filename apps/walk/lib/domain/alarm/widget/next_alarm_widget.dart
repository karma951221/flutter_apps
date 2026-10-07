/// 홈 화면 위젯이 보일 예약 한 회차 — 울릴 시각과 제목(알람 라벨, 비면 제목 줄 없음).
typedef WidgetRing = ({DateTime at, String title});

/// 홈 화면 "다음 알람" 위젯(네이티브 `NextAlarmWidgetProvider`).
///
/// 위젯은 넘겨받은 회차 중 **그릴 때** 기기 시각보다 뒤인 첫 회차를 보인다 — 앱이 꺼진 채 울리고
/// 알림으로 꺼서 sync 가 돌지 않아도, 지난 회차 대신 다음 회차로 넘어간다. 오늘 · 내일 문구도
/// 그릴 때 계산한다.
abstract interface class NextAlarmWidget {
  /// 위젯에 실을 회차 수 상한. 하루 sync 가 매일 다시 채우므로 하루 이틀 치면 된다.
  static const maxRings = 20;

  /// 실제로 걸린 예약 중 지금 뒤의 회차들(이른 순, 최대 [maxRings]). 비면 "예정된 알람 없음".
  Future<void> show(List<WidgetRing> upcoming);

  /// 위젯을 눌러 앱을 열었는가. 한 번 읽으면 지운다(알람 탭을 연다).
  Future<bool> takeLaunch();
}
