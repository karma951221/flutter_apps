/// 셸의 뒤로가기를 물어보기 탭에 먼저 묻는 연결. 셸이 만들어 [ChatTab] 에 넘기고, 탭이 붙는다.
///
/// [handleBack] 이 true 면 탭이 뒤로가기를 썼다(대화를 닫고 첫 화면으로). false 면 셸이 이어서 처리한다.
class ChatBackController {
  bool Function()? _handler;

  // ignore: use_setters_to_change_properties
  void attach(bool Function() handler) => _handler = handler;

  void detach(bool Function() handler) {
    // 메서드 tear-off 는 같은 객체여도 identical 이 아닐 수 있다 — == 로 비교한다.
    if (_handler == handler) _handler = null;
  }

  bool handleBack() => _handler?.call() ?? false;
}
