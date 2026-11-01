import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/chat/chat_model.dart';
import '../../domain/chat/chat_model_catalog.dart';
import '../../domain/chat/chat_model_rules.dart';
import '../../domain/chat/chat_vendor.dart';

/// SharedPreferences 위 모델 목록. 키는 없고 목록 · 시각 · 본 id · 사진 거절 기록만 둔다.
///
/// 읽기는 prefs 를 그때그때 본다(동기). `chat.models` 가 깨졌으면 빈 목록으로 본다.
@LazySingleton(as: ChatModelCatalog)
class PrefsChatModelCatalog implements ChatModelCatalog {
  PrefsChatModelCatalog(this._prefs);

  final SharedPreferences _prefs;

  static const modelsKey = 'chat.models';
  static const vendorKey = 'chat.models.vendor';
  static const fetchedAtKey = 'chat.models.fetchedAt';
  static const seenKey = 'chat.models.seen';
  static const noImagesKey = 'chat.models.noImages';

  /// [modelsKey] 의 원문과 그 해석. 같은 원문이면 다시 해석하지 않는다.
  String? _decodedFrom;
  List<ModelInfo> _decoded = const [];

  @override
  ChatVendor? get vendor =>
      ChatVendor.values.asNameMap()[_prefs.getString(vendorKey)];

  @override
  List<ModelInfo> get models {
    final raw = _prefs.getString(modelsKey);
    if (raw == null) return const [];
    if (raw != _decodedFrom) {
      _decoded = List.unmodifiable(_decode(raw));
      _decodedFrom = raw;
    }
    return _decoded;
  }

  static List<ModelInfo> _decode(String raw) {
    Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (json is! List) return const [];
    return [
      for (final item in json)
        if (item is Map && item['id'] is String)
          ModelInfo(
            id: item['id'] as String,
            displayName: switch (item['name']) {
              final String name => name,
              _ => item['id'] as String,
            },
            createdAt: switch (item['created']) {
              final int ms => DateTime.fromMillisecondsSinceEpoch(
                ms,
                isUtc: true,
              ),
              _ => null,
            },
            supportsTools: switch (item['tools']) {
              final bool b => b,
              _ => null,
            },
            supportsImages: switch (item['images']) {
              final bool b => b,
              _ => null,
            },
          ),
    ];
  }

  static Map<String, Object?> _encode(ModelInfo m) => {
    'id': m.id,
    'name': m.displayName,
    'created': m.createdAt?.millisecondsSinceEpoch,
    'tools': m.supportsTools,
    'images': m.supportsImages,
  };

  @override
  DateTime? get fetchedAt => switch (_prefs.get(fetchedAtKey)) {
    final int ms => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
    _ => null,
  };

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

  Set<String> _stringSet(String key) {
    final value = _prefs.get(key);
    return value is List ? {...value.whereType<String>()} : {};
  }

  Set<String> get _seen => _stringSet(seenKey);

  @override
  Future<void> replace(
    ChatVendor vendor,
    List<ModelInfo> raw,
    DateTime at,
  ) async {
    final filtered = chatModelsOf(vendor, raw);
    final ids = [for (final m in filtered) m.id];
    final fresh = this.vendor != vendor;
    await _prefs.setString(
      modelsKey,
      jsonEncode([for (final m in filtered) _encode(m)]),
    );
    await _prefs.setString(vendorKey, vendor.name);
    await _prefs.setInt(fetchedAtKey, at.millisecondsSinceEpoch);
    if (fresh) {
      await _prefs.setStringList(seenKey, ids);
    }
  }

  @override
  Future<void> clear() async {
    for (final key in [
      modelsKey,
      vendorKey,
      fetchedAtKey,
      seenKey,
      noImagesKey,
    ]) {
      await _prefs.remove(key);
    }
  }

  @override
  Future<void> markAllSeen() => _prefs.setStringList(seenKey, [
    ...{..._seen, for (final m in models) m.id},
  ]);

  @override
  bool isNew(String id) => find(id) != null && !_seen.contains(id);

  @override
  bool hasUnseenNewer(String? currentId) {
    final seen = _seen;
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

  @override
  Future<void> markNoImages(String id) async {
    final noImages = _stringSet(noImagesKey);
    if (!noImages.add(id)) return;
    await _prefs.setStringList(noImagesKey, [...noImages]);
  }

  @override
  bool supportsImages(String id) {
    if (_stringSet(noImagesKey).contains(id)) return false;
    final v = vendor;
    if (v == null) return true;
    return supportsImagesOf(v, find(id) ?? ModelInfo(id: id, displayName: id));
  }
}
