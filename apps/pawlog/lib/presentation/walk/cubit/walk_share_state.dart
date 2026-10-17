import 'package:freezed_annotation/freezed_annotation.dart';

part 'walk_share_state.freezed.dart';

/// 상세 더보기의 "모두에게 공유" ↔ "공유 취소" 항목 상태.
@freezed
sealed class WalkShareState with _$WalkShareState {
  /// 공유 여부를 읽는 중 — 틀린 라벨을 보이지 않게 항목을 숨긴다.
  const factory WalkShareState.checking() = WalkShareChecking;

  /// Supabase 를 쓸 수 없다 — 항목을 숨긴다.
  const factory WalkShareState.hidden() = WalkShareHidden;

  /// [busy] 는 공유 · 공유 취소를 보내는 중 — 다시 누른 것은 무시한다.
  const factory WalkShareState.ready({
    required bool shared,
    @Default(false) bool busy,
  }) = WalkShareReady;
}

/// 공유 · 공유 취소 한 번의 결과 — 스낵바 · 로그인 이동은 페이지가 정한다.
enum WalkShareOutcome { shared, unshared, signInRequired, failed, ignored }
