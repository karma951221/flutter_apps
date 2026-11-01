import 'chat_model.dart';
import 'chat_vendor.dart';

/// 받아 둔 모델 목록(채팅용만 · 최신순) · 갱신 시각 · 본 id. 원문 키를 모른다.
///
/// 목록을 받아 오는 일은 하지 않는다 — `ChatModelChoice` 가 `ChatKeyVerifier.fetchStored`
/// 로 받아 [replace] 한다(원문 키를 읽는 곳을 둘로 두기 위해, 결정 G4).
abstract interface class ChatModelCatalog {
  /// 목록을 받은 벤더. 비어 있으면 null.
  ChatVendor? get vendor;

  List<ModelInfo> get models;

  DateTime? get fetchedAt;

  /// recommendedModelOf 결과.
  String? get recommended;

  ModelInfo? find(String id);

  /// [raw] 를 chatModelsOf 로 걸러 저장한다. 벤더가 바뀌었거나 처음이면 본 id = 전부(모두 NEW 가 되지 않게).
  Future<void> replace(ChatVendor vendor, List<ModelInfo> raw, DateTime at);

  Future<void> clear();

  /// 지금 목록의 id 를 모두 본 것으로.
  Future<void> markAllSeen();

  bool isNew(String id);

  /// [currentId] 보다 createdAt 이 늦고 아직 안 본 모델이 있는가(칩의 점).
  /// [currentId] 가 null 이거나 목록에 없으면 안 본 모델이 하나라도 있는가.
  bool hasUnseenNewer(String? currentId);

  /// 400 이미지 거절을 받은 모델을 "사진 못 봄"으로 기록(§6.4). 다음 replace 에도 유지.
  Future<void> markNoImages(String id);

  bool supportsImages(String id);
}
