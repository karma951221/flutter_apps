import 'dart:async';

import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../chat/attachment/chat_attachment.dart';
import '../../chat/chat_connection.dart';
import '../../chat/chat_model.dart';
import '../../chat/chat_model_catalog.dart';
import '../../chat/chat_model_rules.dart';
import '../../chat/chat_settings.dart';
import '../../chat/chat_usage_log.dart';
import '../../chat/chat_vendor.dart';
import '../../chat/tool/chat_image_source.dart';
import '../../chat/tool/tool_result.dart';
import '../../chat/usecase/chat_session.dart';
import '../entity/entry_media.dart';
import 'draft_context.dart';
import 'draft_length.dart';
import 'draft_prompt.dart';
import 'draft_style.dart';

part 'draft_writer.freezed.dart';

/// [DraftWriter.write] 가 흘리는 이벤트. 글을 담으므로 생성 toString 을 끈다.
/// 멈추기는 구독을 끊는 것이다 — 따로 이벤트가 없다.
@Freezed(toStringOverride: false)
sealed class DraftEvent with _$DraftEvent {
  /// 글 조각(받은 그대로). 이어 붙이면 지금까지의 글.
  const factory DraftEvent.delta(String text) = DraftDelta;

  /// 앞뒤 공백을 뺀 전체 초안. 마지막 이벤트.
  const factory DraftEvent.done(String text) = DraftDone;

  /// 키 없음 · 잘못된 키 · 네트워크 · 거절 · 빈 응답 등 — 물어보기와 같은 실패 종류. 마지막 이벤트.
  const factory DraftEvent.failed(ChatFailure failure) = DraftFailed;

  /// 연결 벤더로의 전송 동의가 없다 — 요청하지 않았다. 마지막 이벤트.
  const factory DraftEvent.needsConsent() = DraftNeedsConsent;

  @override
  String toString() => switch (this) {
    DraftDelta(:final text) => 'DraftEvent.delta(length: ${text.length})',
    DraftDone(:final text) => 'DraftEvent.done(length: ${text.length})',
    DraftFailed(:final failure) => 'DraftEvent.failed($failure)',
    DraftNeedsConsent() => 'DraftEvent.needsConsent()',
  };
}

/// ✨ 를 눌렀을 때 바로 쓸지, 안내 · 동의를 먼저 보일지 — 키 · 동의 상태.
@freezed
sealed class DraftAvailability with _$DraftAvailability {
  /// 키가 없다(또는 읽지 못했다) — 물어보기 설정으로 안내한다.
  const factory DraftAvailability.noKey() = DraftNoKey;

  /// [vendor] 로의 전송 동의가 없다 — 한 번 묻고 기록한다.
  const factory DraftAvailability.needsConsent(ChatVendor vendor) =
      DraftConsentNeeded;

  /// [vendor] 로 보낼 수 있다.
  const factory DraftAvailability.ready(ChatVendor vendor) = DraftReady;
}

/// 메모 · 맥락(· 사진)으로 일기 초안을 쓴다(스펙 2026-11-15 §4).
///
/// [WikiDistiller] 처럼 세션과 따로 돈다 — 원문 키를 직접 읽고 연결 벤더의 **초안 모델**
/// ([draftModelOf], 물어보기에서 고른 모델이 아니다)로 보낸다. 도구 · 웹 검색 · 생각 없이 한 라운드,
/// 출력은 [maxOutputTokens] 까지.
@lazySingleton
class DraftWriter {
  DraftWriter(
    this._registry,
    this._settings,
    this._catalog,
    this._images,
    this._usage,
    this._ids,
    this._clock,
  );

  final ChatModelRegistry _registry;
  final ChatSettings _settings;
  final ChatModelCatalog _catalog;
  final ChatImageSource _images;
  final ChatUsageLog _usage;
  final IdGenerator _ids;
  final Clock _clock;

  /// 켜도 이만큼만 붙인다.
  static const maxPhotos = 4;

  /// 초안 한 번의 출력 토큰 상한(길이 규칙 최대 6문장에 넉넉히).
  static const maxOutputTokens = 600;

  /// 키 · 동의 상태. 던지지 않는다 — 키 저장소를 읽지 못하면 noKey.
  Future<DraftAvailability> availability() async {
    final bool hasKey;
    try {
      hasKey = await _settings.hasApiKey();
    } catch (_) {
      return const DraftAvailability.noKey();
    }
    final vendor = _settings.connectedVendor;
    if (!hasKey || vendor == null) return const DraftAvailability.noKey();
    if (_settings.draftConsentedVendor != vendor) {
      return DraftAvailability.needsConsent(vendor);
    }
    return DraftAvailability.ready(vendor);
  }

  /// 연결 벤더의 초안 모델. 모델 목록이 그 벤더 것이 아니면 상수. 연결이 없으면 null.
  String? get draftModel {
    final vendor = _settings.connectedVendor;
    if (vendor == null) return null;
    final models = _catalog.vendor == vendor ? _catalog.models : <ModelInfo>[];
    return draftModelOf(vendor, models);
  }

  /// 초안 모델이 사진을 볼 수 있는가(모델 목록의 이미지 지원). 연결이 없으면 true.
  bool get canSeePhotos {
    final model = draftModel;
    return model == null || _catalog.supportsImages(model);
  }

  /// 초안을 쓴다. 글 조각([DraftDelta])을 흘리고 [DraftDone] · [DraftFailed] ·
  /// [DraftNeedsConsent] 중 하나로 끝난다. 던지지 않는다. 구독을 끊으면 요청도 끊는다.
  ///
  /// [includePhotos] 이고 초안 모델이 사진을 볼 수 있으면 [photos] 중 사진 앞 [maxPhotos] 장을
  /// 줄인 JPEG 로 붙인다. 아니면 읽지도 않는다. [polish] 면 메모(= 지금 글)를 새 사실 없이 다듬는다.
  Stream<DraftEvent> write(
    DraftContext context, {
    required DraftStyle style,
    List<EntryMedia> photos = const [],
    bool includePhotos = false,
    bool polish = false,
  }) async* {
    final String? apiKey;
    try {
      apiKey = await _settings.apiKey();
    } catch (_) {
      yield const DraftEvent.failed(ChatFailure.noKey);
      return;
    }
    final vendor = _settings.connectedVendor;
    final modelId = draftModel;
    if (apiKey == null || vendor == null || modelId == null) {
      yield const DraftEvent.failed(ChatFailure.noKey);
      return;
    }
    if (_settings.draftConsentedVendor != vendor) {
      yield const DraftEvent.needsConsent();
      return;
    }

    final attachments = includePhotos && canSeePhotos
        ? await _attachments(photos)
        : const <ChatAttachment>[];
    final request = ModelRequest(
      apiKey: apiKey,
      model: modelId,
      system: DraftPrompt.system(
        style: style,
        length: DraftLength.of(
          memo: context.memo,
          photoCount: context.photoCount,
        ),
        withPhotos: attachments.isNotEmpty,
        polish: polish,
        memo: context.memo,
        locale: context.locale,
      ),
      messages: [
        ChatMessage.user(DraftPrompt.user(context), attachments: attachments),
      ],
      tools: const [],
      maxOutputTokens: maxOutputTokens,
      thinking: false,
    );

    // yield* 라야 구독을 끊을 때 모델 스트림(HTTP)도 바로 끊긴다 — await for 는 다음 yield 까지 기다린다.
    yield* _registry
        .of(vendor)
        .stream(request)
        .transform(_DraftEvents(this, apiKey, vendor, modelId, _ids.newId()));
  }

  Future<List<ChatAttachment>> _attachments(List<EntryMedia> media) async {
    final result = <ChatAttachment>[];
    final photos = media.where((m) => m.kind == MediaKind.photo);
    for (final photo in photos.take(maxPhotos)) {
      final ToolImage? image;
      try {
        image = await _images.load(photo);
      } catch (_) {
        continue;
      }
      if (image == null) continue;
      result.add(
        ChatAttachment.image(
          name: 'photo-${result.length + 1}.jpg',
          mediaType: image.mediaType,
          bytes: image.bytes,
        ),
      );
    }
    return result;
  }

  void _recordInvalidKey(String usedKey) {
    unawaited(
      Future.sync(
        () => _settings.setKeyStatus(ChatKeyStatus.invalid, forKey: usedKey),
      ).catchError((Object _) {}),
    );
  }

  /// 기다리지 않고 오류를 삼킨다.
  void _recordUsage(
    String questionKey,
    ChatVendor vendor,
    String model,
    ModelCompleted event,
  ) {
    final usage = event.usage;
    if (usage == null) return;
    final record = ChatUsageRecord(
      at: _clock.now(),
      questionKey: questionKey,
      vendor: vendor,
      model: model,
      fastMode: false,
      purpose: ChatUsagePurpose.diaryDraft,
      round: 1,
      temporary: false,
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
      cacheReadTokens: usage.cacheReadTokens,
      cacheWriteTokens: usage.cacheWriteTokens,
      reasoningTokens: usage.reasoningTokens,
    );
    unawaited(
      Future.sync(() => _usage.record(record)).catchError((Object _) {}),
    );
  }
}

/// 모델 이벤트 → 초안 이벤트. 끝(완료 · 오류 · 완료 없는 끝)에서 마지막 이벤트 하나를 낸다.
class _DraftEvents extends StreamTransformerBase<ModelEvent, DraftEvent> {
  _DraftEvents(
    this._writer,
    this._apiKey,
    this._vendor,
    this._model,
    this._questionKey,
  );

  final DraftWriter _writer;
  final String _apiKey;
  final ChatVendor _vendor;
  final String _model;
  final String _questionKey;

  @override
  Stream<DraftEvent> bind(Stream<ModelEvent> stream) {
    ModelCompleted? done;
    var finished = false;
    return stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (event, sink) {
          if (finished) return;
          switch (event) {
            case ModelTextDelta(:final text) when text.isNotEmpty:
              sink.add(DraftEvent.delta(text));
            case ModelCompleted():
              done = event;
              _writer._recordUsage(_questionKey, _vendor, _model, event);
            default:
              break;
          }
        },
        handleError: (error, _, sink) {
          if (finished) return;
          finished = true;
          var failure = ChatFailure.unknown;
          if (error is ChatModelException) {
            failure = chatFailureOf(error.kind);
            if (failure == ChatFailure.invalidKey) {
              _writer._recordInvalidKey(_apiKey);
            }
          }
          sink
            ..add(DraftEvent.failed(failure))
            ..close();
        },
        handleDone: (sink) {
          if (!finished) {
            finished = true;
            sink.add(_last(done));
          }
          sink.close();
        },
      ),
    );
  }

  static DraftEvent _last(ModelCompleted? done) {
    if (done == null) return const DraftEvent.failed(ChatFailure.network);
    if (done.stop == StopKind.refusal) {
      return const DraftEvent.failed(ChatFailure.refused);
    }
    final text = done.message.parts
        .whereType<TextPart>()
        .map((p) => p.text)
        .join()
        .trim();
    return text.isEmpty
        ? const DraftEvent.failed(ChatFailure.unknown)
        : DraftEvent.done(text);
  }
}
