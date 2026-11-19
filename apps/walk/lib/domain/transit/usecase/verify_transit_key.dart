import 'package:injectable/injectable.dart';

import '../repository/station_search.dart';
import '../repository/transit_key_store.dart';
import '../transit_failure.dart';

/// 입력한 ODsay 키를 역 검색 1회로 확인한다(결과가 없어도 통과).
///
/// - 통과 → connected 로 저장
/// - 인증 실패([TransitKeyRejected]) · 한도 초과 → 저장하지 않고 그대로 던진다
/// - 네트워크 · 서버 오류(파라미터 형식 `-8` 처럼 키와 무관한 code 포함) →
///   키를 판정하지 못한 것. [saveIfUnverified] 일 때만 unverified 로 저장하고,
///   아니면 그대로 던져 화면이 '그래도 저장할지' 묻게 한다.
@injectable
class VerifyTransitKey {
  VerifyTransitKey(this._search, this._store);

  final StationSearch _search;
  final TransitKeyStore _store;

  Future<TransitKeyStatus> call(
    String key, {
    bool saveIfUnverified = false,
  }) async {
    try {
      await _search.search('서울역', apiKey: key);
    } on TransitFailure catch (e) {
      if (!isUnverifiable(e) || !saveIfUnverified) rethrow;
      await _store.save(key, TransitKeyStatus.unverified);
      return TransitKeyStatus.unverified;
    }
    await _store.save(key, TransitKeyStatus.connected);
    return TransitKeyStatus.connected;
  }
}

/// 키를 맞다 · 틀리다 판정하지 못한 실패인가. 네트워크 실패와, ODsay 가
/// 인증 실패가 아닌 오류로 답한 경우(서버 오류 · 파라미터 형식 등)가 해당한다.
bool isUnverifiable(TransitFailure failure) =>
    failure is TransitNetwork || failure is TransitServer;
