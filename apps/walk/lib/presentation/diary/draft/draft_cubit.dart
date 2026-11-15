import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/chat_settings.dart';
import '../../../domain/chat/usecase/chat_session.dart';
import '../../../domain/diary/draft/draft_context.dart';
import '../../../domain/diary/draft/draft_style.dart';
import '../../../domain/diary/draft/draft_writer.dart';
import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/repository/diary_preferences.dart';
import 'draft_state.dart';

/// 초안 시트 하나의 상태(스펙 §4 흐름). 시트가 만들고 닫을 때 닫는다.
///
/// 문체 · 사진 스위치는 [DiaryPreferences] 의 기본값으로 시작하고, 바꿔도 설정에 쓰지 않는다.
class DraftCubit extends Cubit<DraftState> {
  DraftCubit(this._writer, DiaryPreferences prefs, this._settings)
    : super(
        DraftState(
          style: prefs.draftStyle,
          includePhotos: prefs.draftIncludePhotos,
        ),
      );

  final DraftWriter _writer;
  final ChatSettings _settings;

  /// 키 · 동의 상태를 다시 읽는다.
  Future<void> load() async {
    final availability = await _writer.availability();
    if (!isClosed) emit(state.copyWith(availability: availability));
  }

  void setStyle(DraftStyle style) => emit(state.copyWith(style: style));

  void setIncludePhotos(bool on) => emit(state.copyWith(includePhotos: on));

  /// 지금 연결 벤더로의 전송 동의를 기록한다(물어보기와 같은 `consentedVendor`).
  Future<void> consent() async {
    if (state.availability case DraftConsentNeeded(:final vendor)) {
      await _settings.setConsented(vendor);
    }
    await load();
  }

  /// 쓰는 중이면 무시한다. 사진이 없으면 스위치와 상관없이 사진을 보내지 않는다.
  Future<void> write(DraftContext context, List<EntryMedia> photos) async {
    if (state.run is DraftRunWriting) return;
    emit(state.copyWith(run: const DraftRun.writing()));
    final result = await _writer.write(
      context,
      style: state.style,
      photos: photos,
      includePhotos: state.includePhotos && photos.isNotEmpty,
    );
    if (isClosed) return;
    switch (result) {
      case DraftText(:final text):
        emit(state.copyWith(run: DraftRun.done(text)));
      case DraftFailed(:final failure):
        emit(state.copyWith(run: DraftRun.failed(failure)));
        if (failure == ChatFailure.noKey) await load();
      case DraftNeedsConsent():
        emit(state.copyWith(run: const DraftRun.idle()));
        await load();
      case DraftCancelled():
        emit(state.copyWith(run: const DraftRun.idle()));
    }
  }

  /// [멈추기]. 진행 중인 [write] 는 cancelled 로 끝나 idle 이 된다.
  void stop() => _writer.cancel();

  @override
  Future<void> close() {
    if (state.run is DraftRunWriting) _writer.cancel();
    return super.close();
  }
}
