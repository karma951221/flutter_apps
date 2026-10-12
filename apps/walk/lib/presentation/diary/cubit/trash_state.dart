import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/diary/entity/diary_entry.dart';

part 'trash_state.freezed.dart';

/// 휴지통 한 줄: 기록과 영구 삭제까지 남은 일수.
typedef TrashItem = ({DiaryEntry entry, int? daysLeft});

/// 휴지통 화면(스펙 §5.1 · §6.5).
@freezed
class TrashState with _$TrashState {
  /// 휴지통에 간 시각 최신순.
  @override
  final List<TrashItem> items;

  /// 첫 목록을 아직 받지 못했다.
  @override
  final bool loading;

  /// 목록을 읽지 못했다.
  @override
  final bool failed;

  /// 마지막 동작이 실패했다. 동작을 시작할 때 비운다.
  @override
  final bool actionFailed;

  const TrashState({
    this.items = const [],
    this.loading = true,
    this.failed = false,
    this.actionFailed = false,
  });
}
