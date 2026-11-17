import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/chat/api_key_mask.dart';
import '../../../domain/transit/repository/transit_key_store.dart';
import '../../../domain/transit/transit_failure.dart';
import '../../../domain/transit/usecase/verify_transit_key.dart';
import 'transit_key_state.dart';

/// 키를 저장하려던 결과. 화면이 스낵바 · 확인 창을 고른다.
enum TransitKeySave {
  connected,
  unverified,

  /// 서버가 키를 거절했다 — 저장하지 않았고 문구는 상태의 `rejectedMessage`.
  rejected,

  /// 확인하지 못했다(네트워크) — 저장하지 않았다. 그래도 저장할지는 화면이 묻는다.
  network,

  /// 그 밖의 실패(한도 초과 · 서버 오류 · 저장 실패) — 저장하지 않았다.
  failed,
}

/// 길찾기(ODsay) 키 설정. 저장은 [VerifyTransitKey] 를 거친다.
@injectable
class TransitKeyCubit extends Cubit<TransitKeyState> {
  TransitKeyCubit(this._store, this._verify) : super(const TransitKeyState());

  final TransitKeyStore _store;
  final VerifyTransitKey _verify;

  Future<void> load() async {
    final key = await _store.read();
    final status = key == null ? null : await _store.status();
    if (isClosed) return;
    emit(
      TransitKeyState(
        loading: false,
        keyPreview: key == null ? null : _mask(key),
        status: key == null ? null : status,
      ),
    );
  }

  /// [key] 를 확인해 저장한다. 확인 못 한 채로 저장하려면 [saveIfUnverified].
  Future<TransitKeySave> save(
    String key, {
    bool saveIfUnverified = false,
  }) async {
    final trimmed = key.trim();
    emit(state.copyWith(busy: true));
    try {
      final status = await _verify(trimmed, saveIfUnverified: saveIfUnverified);
      _emitSettled(preview: _mask(trimmed), status: status);
      return status == TransitKeyStatus.connected
          ? TransitKeySave.connected
          : TransitKeySave.unverified;
    } on TransitKeyRejected catch (e) {
      _emitSettled(rejectedMessage: e.message);
      return TransitKeySave.rejected;
    } on TransitNetwork {
      _emitSettled();
      return TransitKeySave.network;
    } on Object {
      _emitSettled();
      return TransitKeySave.failed;
    }
  }

  /// 저장된 키를 지운다. 지우지 못하면 false.
  Future<bool> delete() async {
    emit(state.copyWith(busy: true));
    try {
      await _store.delete();
    } on Object {
      _emitSettled();
      return false;
    }
    _emitSettled(preview: null, status: null);
    return true;
  }

  void clearRejection() {
    if (state.rejectedMessage == null) return;
    emit(state.copyWith(rejectedMessage: null));
  }

  /// busy 를 풀며 상태를 정한다. 넘기지 않은 값은 지금 값을 둔다.
  void _emitSettled({
    Object? preview = _keep,
    Object? status = _keep,
    String? rejectedMessage,
  }) {
    if (isClosed) return;
    emit(
      TransitKeyState(
        loading: false,
        keyPreview: identical(preview, _keep)
            ? state.keyPreview
            : preview as String?,
        status: identical(status, _keep)
            ? state.status
            : status as TransitKeyStatus?,
        rejectedMessage: rejectedMessage,
      ),
    );
  }

  static const Object _keep = Object();

  /// ODsay 키는 모르는 접두사라 앞 4글자 + `••••`(8글자 미만이면 `••••`)만 보인다.
  String _mask(String key) => maskOpaqueKey(key);
}
