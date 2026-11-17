import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/transit/repository/transit_key_store.dart';

part 'transit_key_state.freezed.dart';

/// 길찾기 키 설정 화면 상태 — 저장된 키(가린 모양) · 확인 상태 · 진행 중 · 거절 문구.
@freezed
class TransitKeyState with _$TransitKeyState {
  /// 저장소를 읽는 중.
  @override
  final bool loading;

  /// 저장된 키를 가린 모양. 키가 없으면 null.
  @override
  final String? keyPreview;

  /// 저장된 키의 확인 상태. 키가 없으면 null.
  @override
  final TransitKeyStatus? status;

  /// 확인 · 저장 · 삭제 중.
  @override
  final bool busy;

  /// 서버가 키를 거절하며 보낸 원문. 입력을 고치면 지운다.
  @override
  final String? rejectedMessage;

  const TransitKeyState({
    this.loading = true,
    this.keyPreview,
    this.status,
    this.busy = false,
    this.rejectedMessage,
  });
}
