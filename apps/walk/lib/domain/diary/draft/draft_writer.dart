import 'dart:async';

import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../chat/attachment/chat_attachment.dart';
import '../../chat/chat_connection.dart';
import '../../chat/chat_model.dart';
import '../../chat/chat_settings.dart';
import '../../chat/chat_usage_log.dart';
import '../../chat/chat_vendor.dart';
import '../../chat/tool/chat_image_source.dart';
import '../../chat/tool/tool_result.dart';
import '../../chat/usecase/chat_model_choice.dart';
import '../../chat/usecase/chat_session.dart';
import '../entity/entry_media.dart';
import 'draft_context.dart';
import 'draft_length.dart';
import 'draft_prompt.dart';
import 'draft_style.dart';

part 'draft_writer.freezed.dart';

/// [DraftWriter.write] 의 결과. 글을 담으므로 생성 toString 을 끈다.
@Freezed(toStringOverride: false)
sealed class DraftResult with _$DraftResult {
  /// 앞뒤 공백을 뺀 초안.
  const factory DraftResult.text(String text) = DraftText;

  /// 키 없음 · 잘못된 키 · 네트워크 · 거절 등 — 물어보기와 같은 실패 종류.
  const factory DraftResult.failed(ChatFailure failure) = DraftFailed;

  /// 연결 벤더로의 전송 동의가 없다 — 요청하지 않았다.
  const factory DraftResult.needsConsent() = DraftNeedsConsent;

  /// [DraftWriter.cancel] 로 멈췄다.
  const factory DraftResult.cancelled() = DraftCancelled;

  @override
  String toString() => switch (this) {
    DraftText(:final text) => 'DraftResult.text(length: ${text.length})',
    DraftFailed(:final failure) => 'DraftResult.failed($failure)',
    DraftNeedsConsent() => 'DraftResult.needsConsent()',
    DraftCancelled() => 'DraftResult.cancelled()',
  };
}

/// 초안 시트가 [초안 쓰기] 를 보일지 — 키 · 동의 상태.
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

/// 메모 · 맥락(· 사진)으로 일기 초안을 쓰는 한 번의 요청(스펙 §4 A1~A3).
///
/// [WikiDistiller] 처럼 세션과 따로 돈다 — 원문 키를 직접 읽고 연결 벤더 ·
/// [ChatModelChoice.currentModel] 로 보낸다. 도구 · 웹 검색 없이 한 라운드.
@lazySingleton
class DraftWriter {
  DraftWriter(
    this._registry,
    this._settings,
    this._choice,
    this._images,
    this._usage,
    this._ids,
    this._clock,
  );

  final ChatModelRegistry _registry;
  final ChatSettings _settings;
  final ChatModelChoice _choice;
  final ChatImageSource _images;
  final ChatUsageLog _usage;
  final IdGenerator _ids;
  final Clock _clock;

  /// 켜도 이만큼만 붙인다.
  static const maxPhotos = 4;

  final _runs = <_Run>{};

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
    if (_settings.consentedVendor != vendor) {
      return DraftAvailability.needsConsent(vendor);
    }
    return DraftAvailability.ready(vendor);
  }

  /// 진행 중인 요청을 모두 멈춘다(초안 시트는 하나뿐이라 고르지 않는다).
  void cancel() {
    for (final run in [..._runs]) {
      run.cancel();
    }
  }

  /// [includePhotos] 면 [photos] 중 사진 앞 [maxPhotos] 장을 줄인 JPEG 로 붙인다. 끄면 읽지도 않는다.
  Future<DraftResult> write(
    DraftContext context, {
    required DraftStyle style,
    List<EntryMedia> photos = const [],
    bool includePhotos = false,
  }) async {
    final run = _Run();
    _runs.add(run);
    try {
      return await _write(context, style, photos, includePhotos, run);
    } on ChatModelException catch (e) {
      if (run.cancelled) return const DraftResult.cancelled();
      var failure = chatFailureOf(e.kind);
      final key = run.apiKey;
      final model = run.model;
      if (failure == ChatFailure.invalidKey && key != null) {
        _recordInvalidKey(key);
      } else if (failure == ChatFailure.modelUnavailable && model != null) {
        final replaced = await _recoverFromUnavailable(model);
        if (run.cancelled) return const DraftResult.cancelled();
        if (replaced) failure = ChatFailure.modelReplaced;
      }
      return DraftResult.failed(failure);
    } catch (_) {
      if (run.cancelled) return const DraftResult.cancelled();
      return const DraftResult.failed(ChatFailure.unknown);
    } finally {
      _runs.remove(run);
    }
  }

  Future<DraftResult> _write(
    DraftContext context,
    DraftStyle style,
    List<EntryMedia> photos,
    bool includePhotos,
    _Run run,
  ) async {
    const cancelled = DraftResult.cancelled();
    final apiKey = await _settings.apiKey();
    if (run.cancelled) return cancelled;
    final vendor = _settings.connectedVendor;
    if (apiKey == null || vendor == null) {
      return const DraftResult.failed(ChatFailure.noKey);
    }
    if (_settings.consentedVendor != vendor) {
      return const DraftResult.needsConsent();
    }
    final modelId = _choice.currentModel;
    if (modelId == null) return const DraftResult.failed(ChatFailure.noModels);
    run
      ..apiKey = apiKey
      ..model = modelId;

    final attachments = includePhotos
        ? await _attachments(photos)
        : const <ChatAttachment>[];
    if (run.cancelled) return cancelled;

    final fastMode = _choice.fastModeOn;
    final request = ModelRequest(
      apiKey: apiKey,
      model: modelId,
      fastMode: fastMode,
      system: DraftPrompt.system(
        style: style,
        length: DraftLength.of(
          memo: context.memo,
          photoCount: context.photoCount,
        ),
        withPhotos: attachments.isNotEmpty,
      ),
      messages: [
        ChatMessage.user(DraftPrompt.user(context), attachments: attachments),
      ],
      tools: const [],
      webSearch: false,
    );
    final questionKey = _ids.newId();
    final done = await _round(_registry.of(vendor), request, run, (event) {
      _recordUsage(questionKey, vendor, modelId, fastMode, event);
    });
    if (run.cancelled) return cancelled;
    if (done == null) {
      throw const ChatModelException(ChatModelErrorKind.network);
    }
    if (done.stop == StopKind.refusal) {
      return const DraftResult.failed(ChatFailure.refused);
    }
    final text = done.message.parts
        .whereType<TextPart>()
        .map((p) => p.text)
        .join()
        .trim();
    if (text.isEmpty) return const DraftResult.failed(ChatFailure.unknown);
    return DraftResult.text(text);
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

  /// 완료 이벤트(없으면 null)를 돌려준다. [run] 을 멈추면 구독을 끊고 null.
  Future<ModelCompleted?> _round(
    ChatModel model,
    ModelRequest request,
    _Run run,
    void Function(ModelCompleted event) onCompleted,
  ) {
    final completer = Completer<ModelCompleted?>();
    ModelCompleted? done;
    final sub = model
        .stream(request)
        .listen(
          (event) {
            if (event is ModelCompleted) {
              done = event;
              onCompleted(event);
            }
          },
          onError: (Object e, StackTrace s) {
            if (!completer.isCompleted) completer.completeError(e, s);
          },
          onDone: () {
            if (!completer.isCompleted) completer.complete(done);
          },
          cancelOnError: true,
        );
    run.onCancel = () {
      sub.cancel().ignore();
      if (!completer.isCompleted) completer.complete(null);
    };
    return completer.future.whenComplete(() => run.onCancel = null);
  }

  void _recordInvalidKey(String usedKey) {
    unawaited(
      Future.sync(
        () => _settings.setKeyStatus(ChatKeyStatus.invalid, forKey: usedKey),
      ).catchError((Object _) {}),
    );
  }

  Future<bool> _recoverFromUnavailable(String model) async {
    try {
      return await _choice.recoverFromUnavailable(model);
    } catch (_) {
      return false;
    }
  }

  /// 기다리지 않고 오류를 삼킨다.
  void _recordUsage(
    String questionKey,
    ChatVendor vendor,
    String model,
    bool fastMode,
    ModelCompleted event,
  ) {
    final usage = event.usage;
    if (usage == null) return;
    final record = ChatUsageRecord(
      at: _clock.now(),
      questionKey: questionKey,
      vendor: vendor,
      model: model,
      fastMode: fastMode,
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

/// 진행 중인 [DraftWriter.write] 하나.
class _Run {
  bool cancelled = false;

  /// 오류 처리(키 상태 · 모델 복구)만 쓴다. 어디에도 싣지 않는다.
  String? apiKey;
  String? model;

  void Function()? onCancel;

  void cancel() {
    cancelled = true;
    onCancel?.call();
  }
}
