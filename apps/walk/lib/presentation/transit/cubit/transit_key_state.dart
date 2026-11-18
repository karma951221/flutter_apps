import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/transit/repository/transit_key_store.dart';
import '../../../domain/transit/transit_failure.dart';

part 'transit_key_state.freezed.dart';

/// 길찾기 키 설정 화면 상태 — 저장된 키(가린 모양) · 확인 상태 · 진행 중 · 마지막 실패.
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

  /// 마지막 저장 시도가 실패한 이유. 화면이 입력칸 아래에 요약과 원인 원문을
  /// 보인다. 입력을 고치거나 저장에 성공하면 지운다.
  @override
  final TransitFailure? failure;

  const TransitKeyState({
    this.loading = true,
    this.keyPreview,
    this.status,
    this.busy = false,
    this.failure,
  });
}
