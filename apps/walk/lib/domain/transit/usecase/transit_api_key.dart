import '../repository/transit_key_store.dart';

/// 지금 쓸 ODsay 키. 출처 순서는 보안 저장소 → 빌드에 주입한 [fallback] → 없음.
/// 비었거나 공백뿐인 값은 없는 것으로 본다.
class TransitApiKey {
  TransitApiKey(this._store, {required String fallback})
    : _fallback = fallback.trim();

  final TransitKeyStore _store;
  final String _fallback;

  Future<String?> current() async {
    final saved = (await _store.read())?.trim();
    if (saved != null && saved.isNotEmpty) return saved;
    return _fallback.isEmpty ? null : _fallback;
  }
}
