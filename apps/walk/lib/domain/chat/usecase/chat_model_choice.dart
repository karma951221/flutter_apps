import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../chat_connection.dart';
import '../chat_model.dart';
import '../chat_model_catalog.dart';
import '../chat_model_rules.dart';
import '../chat_model_rules.dart' as rules show fastModeSpecs;
import '../chat_settings.dart';
import '../chat_vendor.dart';
import 'chat_key_verifier.dart';

part 'chat_model_choice.freezed.dart';

/// [ChatModelChoice.refresh] 의 결과.
@freezed
sealed class ModelsRefresh with _$ModelsRefresh {
  /// 24시간 안 · 미연결(받는 동안 끊긴 경우 포함).
  const factory ModelsRefresh.skipped() = ModelsSkipped;

  /// 새 목록을 넣었다. [replacedSelection] 이면 고른 모델이 없어져 추천으로 되돌렸다.
  const factory ModelsRefresh.updated({required bool replacedSelection}) =
      ModelsUpdated;

  const factory ModelsRefresh.invalidKey() = ModelsInvalidKey;

  /// 받지 못했다(또는 쓸 모델이 하나도 없었다). 캐시는 그대로.
  const factory ModelsRefresh.unreachable() = ModelsUnreachable;
}

/// 고른 모델 · 빠른 출력 · 목록 갱신을 묶는다. 키를 모른다(ChatKeyVerifier 를 거친다, 결정 G4).
///
/// 싱글턴 — "고른 모델이 없어져 추천으로 바꿨어요" 알림 표시는 메모리에만 둔다(결정 G8).
@lazySingleton
class ChatModelChoice {
  ChatModelChoice(
    this._settings,
    this._catalog,
    this._verifier,
    this._clock, {
    @ignoreParam
    @visibleForTesting
    Map<ChatVendor, List<FastModeSpec>>? fastModeSpecs,
  }) : _fastModeSpecs = fastModeSpecs ?? rules.fastModeSpecs;

  final ChatSettings _settings;
  final ChatModelCatalog _catalog;
  final ChatKeyVerifier _verifier;
  final Clock _clock;
  final Map<ChatVendor, List<FastModeSpec>> _fastModeSpecs;

  static const maxAge = Duration(hours: 24);

  bool _selectionReplacedNotice = false;

  /// 연결 벤더와 목록 벤더가 같을 때 그 벤더. 아니면 null.
  ChatVendor? get _listedVendor {
    final vendor = _settings.connectedVendor;
    return vendor != null && _catalog.vendor == vendor ? vendor : null;
  }

  /// 지금 모델의 벤더(연결 벤더와 목록 벤더가 같을 때). 칩의 벤더 로고에 쓴다.
  ChatVendor? get vendor => _listedVendor;

  /// 다음 질문에 쓸 모델: 고른 모델이 목록에 있으면 그것, 아니면 추천. 목록이 없거나 벤더가 다르면 null.
  String? get currentModel {
    if (_listedVendor == null) return null;
    final selected = _settings.selectedModel;
    if (selected != null && _catalog.find(selected) != null) return selected;
    return _catalog.recommended;
  }

  ModelInfo? get currentInfo {
    final id = currentModel;
    return id == null ? null : _catalog.find(id);
  }

  bool get usingRecommended {
    final id = currentModel;
    return id != null && id == _catalog.recommended;
  }

  FastModeSpec? get fastModeSpec {
    final vendor = _listedVendor;
    final id = currentModel;
    if (vendor == null || id == null) return null;
    return fastModeOf(vendor, id, specs: _fastModeSpecs);
  }

  /// 지금 모델이 빠른 출력을 지원하는가(fastModeOf != null).
  bool get fastModeAvailable => fastModeSpec != null;

  /// 요청에 실을 값 = settings.fastMode && fastModeAvailable.
  bool get fastModeOn => _settings.fastMode && fastModeAvailable;

  /// 지금 모델보다 늦게 나온 안 본 모델이 있는가(칩의 점).
  bool get hasUnseenNewer =>
      _listedVendor != null && _catalog.hasUnseenNewer(currentModel);

  /// 지금 모델 기준. 모델이 없으면 true(보낼 요청도 없다).
  bool get supportsImages {
    final id = currentModel;
    return id == null || _catalog.supportsImages(id);
  }

  /// force 거나 fetchedAt 이 maxAge 를 넘었거나 · 목록 벤더가 연결 벤더와 다르거나 · 키 상태가 unverified 면 받는다.
  /// 실패는 조용히(캐시 유지). 거른 목록이 비면 unreachable(캐시 · fetchedAt 그대로). 받은 목록에 selectedModel 이 없으면 selectModel(null) + 알림 표시를 세운다.
  /// 던지지 않는다.
  Future<ModelsRefresh> refresh({bool force = false}) async {
    try {
      // 연결을 먼저 읽는다 — 옛 설정(복원 · 이전 버전)을 옮긴 뒤 동기 값을 본다.
      final connection = await _settings.connection();
      final vendor = _settings.connectedVendor;
      if (connection == null || vendor == null) {
        return const ModelsRefresh.skipped();
      }
      if (!force && !_due(vendor, connection.status)) {
        return const ModelsRefresh.skipped();
      }

      final fetched = await _verifier.fetchStored();
      if (fetched == null) return const ModelsRefresh.skipped();
      final (listed, result) = fetched;
      switch (result) {
        case ModelListInvalidKey():
          return const ModelsRefresh.invalidKey();
        case ModelListUnreachable():
          return const ModelsRefresh.unreachable();
        case ModelListOk(:final models):
          // 거른 목록이 비면(본문을 못 읽은 경우 등) 받지 못한 것으로 본다 — 쓰던 목록을
          // 지우지 않고, fetchedAt 을 찍지 않아 다음에 다시 받는다.
          if (chatModelsOf(listed, models).isEmpty) {
            return const ModelsRefresh.unreachable();
          }
          await _catalog.replace(listed, models, _clock.now());
          final selected = _settings.selectedModel;
          final replaced = selected != null && _catalog.find(selected) == null;
          if (replaced) {
            await _settings.selectModel(null);
            _selectionReplacedNotice = true;
          }
          return ModelsRefresh.updated(replacedSelection: replaced);
      }
    } catch (_) {
      return const ModelsRefresh.unreachable();
    }
  }

  bool _due(ChatVendor vendor, ChatKeyStatus status) {
    if (_catalog.vendor != vendor) return true;
    final fetchedAt = _catalog.fetchedAt;
    if (fetchedAt == null) return true;
    final age = _clock.now().difference(fetchedAt);
    // 시계를 되돌렸으면(받은 시각이 미래) 오래된 것으로 본다.
    if (age.isNegative || age >= maxAge) return true;
    return status == ChatKeyStatus.unverified;
  }

  /// 키 저장 직후 check 결과 목록을 그대로 넣는다(§4 한 번 호출로 두 가지, 결정 G5).
  Future<void> adopt(ChatVendor vendor, List<ModelInfo> raw) =>
      _catalog.replace(vendor, raw, _clock.now());

  /// 끊기 → 목록을 비운다.
  Future<void> forget() => _catalog.clear();

  /// 추천과 같으면 null 로 저장한다 — 추천이 새 모델로 바뀌면 따라간다(결정 G6).
  Future<void> select(String id) =>
      _settings.selectModel(id == _catalog.recommended ? null : id);

  Future<void> setFastMode(bool on) => _settings.setFastMode(on);

  /// 대화 중 modelUnavailable(§6.3 끝): 강제 갱신 뒤 지금 모델이 바뀌었으면 true.
  Future<bool> recoverFromUnavailable(String failedModel) async {
    await refresh(force: true);
    final now = currentModel;
    return now != null && now != failedModel;
  }

  Future<void> markNoImages(String id) => _catalog.markNoImages(id);

  /// "고른 모델이 없어져 추천으로 바꿨어요" 를 한 번 보일 차례인가. 메모리(앱을 다시 켜면 사라진다).
  bool get selectionReplacedNotice => _selectionReplacedNotice;

  void consumeSelectionReplacedNotice() => _selectionReplacedNotice = false;
}
