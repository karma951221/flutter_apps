import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/chat_model_catalog.dart';
import '../../../domain/chat/chat_settings.dart';
import '../../../domain/chat/usecase/chat_model_choice.dart';
import 'model_picker_state.dart';

/// [ModelPickerCubit.toggleFastMode] 의 결과.
enum FastModeToggle {
  /// 바꿨다.
  done,

  /// 처음 켜는 것 — 요금 확인을 받은 뒤 [ModelPickerCubit.confirmFastMode].
  needsAck,
}

/// 모델 고르기 시트(키 입력 기획 §6.2). 목록은 [ChatModelCatalog] 에서 읽고, 고르기 ·
/// 빠른 출력은 [ChatModelChoice] 로 저장한다. 키를 모른다.
class ModelPickerCubit extends Cubit<ModelPickerState> {
  ModelPickerCubit(this._choice, this._catalog, this._settings)
    : super(const ModelPickerState());

  final ChatModelChoice _choice;
  final ChatModelCatalog _catalog;
  final ChatSettings _settings;

  /// 행을 만들고 **그 뒤** catalog.markAllSeen() — 이번 시트에서는 NEW 가 보이고 다음부터 사라진다.
  Future<void> load() async {
    _emitFrom(_choice.currentModel);
    await _catalog.markAllSeen();
  }

  /// 저장한다. 추천과 같으면 null 로 저장된다(ChatModelChoice.select).
  Future<void> select(String id) async {
    final before = _choice.currentModel;
    await _choice.select(id);
    if (isClosed) return;
    final changed = state.changed || before != _choice.currentModel;
    _emitFrom(_choice.currentModel, changed: changed, keepNew: true);
  }

  /// 처음 켤 때는 needsAck 를 돌려주고 켜지 않는다. 확인 뒤 [confirmFastMode].
  Future<FastModeToggle> toggleFastMode(bool on) async {
    if (on && !_settings.fastModeAcknowledged) return FastModeToggle.needsAck;
    await _setFastMode(on);
    return FastModeToggle.done;
  }

  /// acknowledgeFastMode + setFastMode(true).
  Future<void> confirmFastMode() async {
    await _settings.acknowledgeFastMode();
    await _setFastMode(true);
  }

  Future<void> _setFastMode(bool on) async {
    final changed = state.changed || on != _settings.fastMode;
    await _choice.setFastMode(on);
    if (isClosed) return;
    emit(state.copyWith(fastMode: _settings.fastMode, changed: changed));
  }

  /// [keepNew] 면 NEW 표시는 처음 load 때 값을 그대로 둔다.
  void _emitFrom(String? current, {bool? changed, bool keepNew = false}) {
    final recommended = _catalog.recommended;
    final wasNew = {
      for (final row in state.rows)
        if (row.isNew) row.id,
    };
    final rows = [
      for (final m in _catalog.models)
        ModelPickerRow(
          id: m.id,
          label: m.displayName,
          createdAt: m.createdAt,
          recommended: m.id == recommended,
          isNew: keepNew ? wasNew.contains(m.id) : _catalog.isNew(m.id),
          inUse: m.id == current,
          noImages: !_catalog.supportsImages(m.id),
        ),
    ];
    emit(
      state.copyWith(
        rows: rows,
        fastModeAvailable: _choice.fastModeAvailable,
        fastMode: _settings.fastMode,
        fastModeFactor: _choice.fastModeSpec?.priceFactor,
        company: _catalog.vendor ?? _settings.connectedVendor ?? state.company,
        changed: changed ?? state.changed,
      ),
    );
  }
}
