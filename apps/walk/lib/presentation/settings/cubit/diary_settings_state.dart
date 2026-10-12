import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/diary/entity/diary_usage.dart';
import '../../../domain/diary/entity/trash_retention.dart';
import '../../../domain/lock/lock_config.dart';

part 'diary_settings_state.freezed.dart';

/// 설정 탭 "일기" 섹션 — 잠금 설정 · 휴지통 보관 기간 · 저장 공간.
@freezed
class DiarySettingsState with _$DiarySettingsState {
  /// 잠금 설정. null = 아직 읽지 않음.
  @override
  final LockConfig? lock;

  @override
  final TrashRetention retention;

  /// 저장 공간. null = 아직 읽지 않음(또는 읽기 실패).
  @override
  final DiaryUsage? usage;

  const DiarySettingsState({
    this.lock,
    this.retention = TrashRetention.fallback,
    this.usage,
  });
}
