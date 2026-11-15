import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/chat/usecase/chat_session.dart';
import '../../../domain/diary/draft/draft_style.dart';
import '../../../domain/diary/draft/draft_writer.dart';

part 'draft_state.freezed.dart';

/// 초안 요청 한 번의 진행. 글을 담으므로 생성 toString 을 끈다.
@Freezed(toStringOverride: false)
sealed class DraftRun with _$DraftRun {
  const factory DraftRun.idle() = DraftRunIdle;
  const factory DraftRun.writing() = DraftRunWriting;

  /// 시트가 이 글을 들고 닫힌다.
  const factory DraftRun.done(String text) = DraftRunDone;

  /// 시트에 이유를 보이고 남는다 — 닫고 손으로 써도 된다.
  const factory DraftRun.failed(ChatFailure failure) = DraftRunFailed;
}

/// 초안 시트 상태. 문체 · 사진 스위치는 이번 한 번만(설정은 그대로).
@freezed
class DraftState with _$DraftState {
  /// 키 · 동의 상태. null = 아직 읽지 않음.
  @override
  final DraftAvailability? availability;
  @override
  final DraftStyle style;
  @override
  final bool includePhotos;
  @override
  final DraftRun run;

  const DraftState({
    this.availability,
    this.style = DraftStyle.fallback,
    this.includePhotos = false,
    this.run = const DraftRun.idle(),
  });
}
