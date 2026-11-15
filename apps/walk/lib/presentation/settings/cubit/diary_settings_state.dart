import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/diary/draft/draft_style.dart';
import '../../../domain/diary/entity/diary_usage.dart';
import '../../../domain/diary/entity/trash_retention.dart';
import '../../../domain/lock/lock_config.dart';

part 'diary_settings_state.freezed.dart';

/// 일기 관련 설정 — 잠금 설정 · 휴지통 보관 기간 · 저장 공간 · 자동 초안 기본값.
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

  /// 자동 초안의 기본 문체.
  @override
  final DraftStyle draftStyle;

  /// 사진 보여 주기(작성 화면 도구줄과 같은 값).
  @override
  final bool draftIncludePhotos;

  const DiarySettingsState({
    this.lock,
    this.retention = TrashRetention.fallback,
    this.usage,
    this.draftStyle = DraftStyle.fallback,
    this.draftIncludePhotos = false,
  });
}
