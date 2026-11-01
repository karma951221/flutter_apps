import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/chat/chat_vendor.dart';

part 'model_picker_state.freezed.dart';

/// 모델 고르기 시트의 행 하나.
@freezed
class ModelPickerRow with _$ModelPickerRow {
  @override
  final String id;

  /// 표시 이름(벤더가 주지 않으면 id).
  @override
  final String label;
  @override
  final DateTime? createdAt;
  @override
  final bool recommended;

  /// 시트를 연 때 안 본 모델이었다. 열고 나면 본 것으로 기록돼 다음엔 false.
  @override
  final bool isNew;

  /// 지금 질문에 쓰는 모델(ChatModelChoice.currentModel).
  @override
  final bool inUse;

  /// 사진 입력을 받지 못한다(규칙 · 400 기록).
  @override
  final bool noImages;

  const ModelPickerRow({
    required this.id,
    required this.label,
    this.createdAt,
    this.recommended = false,
    this.isNew = false,
    this.inUse = false,
    this.noImages = false,
  });
}

/// 모델 고르기 시트.
@freezed
class ModelPickerState with _$ModelPickerState {
  /// 최신순.
  @override
  final List<ModelPickerRow> rows;

  /// 지금 모델이 빠른 출력을 지원한다(지원 표가 비면 늘 false).
  @override
  final bool fastModeAvailable;

  /// 저장된 빠른 출력 값(chat.fastMode).
  @override
  final bool fastMode;

  /// 빠른 출력 요금 배수. 지원하지 않으면 null.
  @override
  final double? fastModeFactor;

  /// 요금 안내 문구의 회사.
  @override
  final ChatVendor company;

  /// 시트를 연 뒤 모델 · 빠른 출력을 바꿨다.
  @override
  final bool changed;

  const ModelPickerState({
    this.rows = const [],
    this.fastModeAvailable = false,
    this.fastMode = false,
    this.fastModeFactor,
    this.company = ChatVendor.anthropic,
    this.changed = false,
  });
}
