import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/chat/usecase/chat_session.dart';

part 'draft_state.freezed.dart';

/// 초안 요청 한 번의 진행.
@freezed
sealed class DraftRun with _$DraftRun {
  const factory DraftRun.idle() = DraftRunIdle;

  /// 글 칸에 흘려 넣는 중 — 글 칸은 읽기 전용, ✨ 자리는 멈추기.
  const factory DraftRun.writing() = DraftRunWriting;

  /// 끝까지 받았다 — 화면이 [되돌리기] 스낵바를 띄운다.
  const factory DraftRun.done() = DraftRunDone;

  /// 글 칸을 원래 메모로 되돌렸다 — 화면이 이유를 알린다.
  const factory DraftRun.failed(ChatFailure failure) = DraftRunFailed;
}

/// 작성 화면의 자동 초안 상태(스펙 2026-11-15 §4 R-A1 · R-A3). 글을 담으므로 생성 toString 을 끈다.
@Freezed(toStringOverride: false)
class DraftState with _$DraftState {
  @override
  final DraftRun run;

  /// 초안이 글 칸에 넣은 글(쓰는 중이면 지금까지의 조각).
  @override
  final String text;

  /// 마지막 요청의 메모 — 되돌리기 · 실패 때 돌아갈 글, 고치지 않고 다시 쓸 때의 재료.
  @override
  final String? memo;

  /// 마지막 요청이 다듬기였는가.
  @override
  final bool polish;

  /// 마지막으로 받은 초안(멈췄으면 그때까지의 글). null 이면 아직 없다 — ✨ 는 처음 쓰기.
  @override
  final String? lastDraft;

  /// 사진 보여 주기(R-A4). 설정에 기억된 값으로 시작한다.
  @override
  final bool includePhotos;

  const DraftState({
    this.run = const DraftRun.idle(),
    this.text = '',
    this.memo,
    this.polish = false,
    this.lastDraft,
    this.includePhotos = false,
  });

  bool get writing => run is DraftRunWriting;

  @override
  String toString() =>
      'DraftState(run: $run, text: ${text.length}, '
      'lastDraft: ${lastDraft != null}, includePhotos: $includePhotos)';
}
