/// 백업에 담을 수 있는 영역. `name` 이 manifest 의 `areas` 키이고 zip 안 폴더 이름이다.
enum BackupAreaId {
  diary,
  chat,
  wiki,
  alarm,
  settings,
  location;

  /// 백업 화면에서 처음부터 체크돼 있는지. 위치 기록은 민감해서 직접 켜야 한다.
  bool get defaultSelected => this != location;
}
