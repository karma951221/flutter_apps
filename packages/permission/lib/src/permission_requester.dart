import 'permission_source.dart';
import 'permission_status.dart';

/// 세션당 한 번만 묻는 요청 정책. Android 는 첫 거부 뒤에도 `denied` 를
/// 돌려주므로, 기억해 두지 않으면 새로고침마다 시스템 다이얼로그가 다시 뜬다.
/// 인스턴스가 기억을 가지므로 앱 수명 동안 하나만 둔다.
class PermissionRequester {
  PermissionRequester(this._source);

  final PermissionSource _source;
  bool _declined = false;

  /// 이번 세션에서 요청 결과가 허용이 아니었는지.
  bool get declinedThisSession => _declined;

  Future<PermissionStatus> check() => _source.check();

  /// 거부 상태이고 이번 세션에 아직 거부하지 않았으면 한 번 요청한다.
  Future<PermissionStatus> ensure() async {
    final status = await _source.check();
    if (status != PermissionStatus.denied || _declined) return status;
    return _request();
  }

  /// 사용자가 직접 허용을 눌렀을 때. 세션 기억과 무관하게 요청한다.
  Future<PermissionStatus> requestAgain() => _request();

  Future<void> openSettings() => _source.openSettings();

  Future<PermissionStatus> _request() async {
    final status = await _source.request();
    _declined = status != PermissionStatus.granted;
    return status;
  }
}
