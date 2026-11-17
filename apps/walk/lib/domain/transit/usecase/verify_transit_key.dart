import 'package:injectable/injectable.dart';

import '../repository/station_search.dart';
import '../repository/transit_key_store.dart';
import '../transit_failure.dart';

/// 입력한 ODsay 키를 역 검색 1회로 확인한다. 통과하면 저장하고 connected,
/// 거부되면 저장하지 않고 예외를 그대로 던진다. 네트워크 실패는
/// [saveIfUnverified] 일 때만 unverified 로 저장한다.
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
    } on TransitNetwork {
      if (!saveIfUnverified) rethrow;
      await _store.save(key, TransitKeyStatus.unverified);
      return TransitKeyStatus.unverified;
    }
    await _store.save(key, TransitKeyStatus.connected);
    return TransitKeyStatus.connected;
  }
}
