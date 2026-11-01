import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_model_catalog.dart';
import 'package:walk/domain/chat/chat_model_rules.dart';
import 'package:walk/domain/chat/chat_vendor.dart';

/// 메모리 위 [ChatModelCatalog]. 거르기 · 추천 · 사진 규칙은 실제 규칙 함수를 쓴다.
/// 테스트가 [vendor] · [models] · [fetchedAt] · [seen] 을 직접 바꿀 수 있다.
class FakeChatModelCatalog implements ChatModelCatalog {
  @override
  ChatVendor? vendor;

  @override
  List<ModelInfo> models = const [];

  @override
  DateTime? fetchedAt;

  final seen = <String>{};
  final noImages = <String>{};

  /// [replace] 로 받은 (벤더, 원본 개수)(부른 순서대로).
  final replaceCalls = <(ChatVendor, int)>[];

  int clearCalls = 0;

  @override
  String? get recommended {
    final v = vendor;
    return v == null ? null : recommendedModelOf(v, models);
  }

  @override
  ModelInfo? find(String id) {
    for (final m in models) {
      if (m.id == id) return m;
    }
    return null;
  }

  @override
  Future<void> replace(
    ChatVendor vendor,
    List<ModelInfo> raw,
    DateTime at,
  ) async {
    replaceCalls.add((vendor, raw.length));
    final fresh = this.vendor != vendor;
    models = chatModelsOf(vendor, raw);
    this.vendor = vendor;
    fetchedAt = at;
    if (fresh) {
      seen
        ..clear()
        ..addAll(models.map((m) => m.id));
    }
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    vendor = null;
    models = const [];
    fetchedAt = null;
    seen.clear();
    noImages.clear();
  }

  @override
  Future<void> markAllSeen() async => seen.addAll(models.map((m) => m.id));

  @override
  bool isNew(String id) => find(id) != null && !seen.contains(id);

  @override
  bool hasUnseenNewer(String? currentId) {
    final current = currentId == null ? null : find(currentId);
    final cutoff = current?.createdAt;
    if (current != null && cutoff == null) return false;
    return models.any((m) {
      if (seen.contains(m.id) || m.id == currentId) return false;
      if (cutoff == null) return true;
      final created = m.createdAt;
      return created != null && created.isAfter(cutoff);
    });
  }

  /// 있으면 [markNoImages] 가 이것을 던진다(저장 실패 흉내).
  Object? markNoImagesError;

  @override
  Future<void> markNoImages(String id) async {
    if (markNoImagesError case final e?) throw e;
    noImages.add(id);
  }

  @override
  bool supportsImages(String id) {
    if (noImages.contains(id)) return false;
    final v = vendor;
    if (v == null) return true;
    return supportsImagesOf(v, find(id) ?? ModelInfo(id: id, displayName: id));
  }
}
