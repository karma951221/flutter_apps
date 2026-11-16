import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/chat/chat_vendor.dart';
import '../../../domain/chat/usecase/chat_model_choice.dart';

part 'model_chip.freezed.dart';

/// 지금 모델 표시에 필요한 값 — 물어보기 앱바(모델 버튼 · 제목 아래 이름)와
/// 설정 연결 행이 같이 쓴다(ChatState · ChatSettingsState 가 같이 만든다).
@freezed
class ModelChipData with _$ModelChipData {
  @override
  final ChatVendor vendor;

  /// 표시 이름.
  @override
  final String label;

  /// 빠른 출력이 켜져 요청에 실린다(번개).
  @override
  final bool fastMode;

  /// 지금 모델보다 늦게 나온 안 본 모델이 있다(점).
  @override
  final bool hasNewer;

  const ModelChipData({
    required this.vendor,
    required this.label,
    this.fastMode = false,
    this.hasNewer = false,
  });

  /// [choice] 의 지금 모델로 만든 칩. 모델이 없으면(목록 없음 · 미연결) null.
  static ModelChipData? of(ChatModelChoice choice) {
    final vendor = choice.vendor;
    final info = choice.currentInfo;
    if (vendor == null || info == null) return null;
    return ModelChipData(
      vendor: vendor,
      label: info.displayName,
      fastMode: choice.fastModeOn,
      hasNewer: choice.hasUnseenNewer,
    );
  }
}
