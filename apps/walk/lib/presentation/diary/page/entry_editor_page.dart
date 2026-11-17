import 'dart:async';
import 'dart:math';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/chat_settings.dart';
import '../../../domain/diary/draft/draft_writer.dart';
import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/entity/media_limits.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/location/place_source.dart';
import '../../../domain/diary/media/media_store.dart';
import '../../../domain/diary/media/photo_meta_reader.dart';
import '../../../domain/diary/repository/diary_preferences.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/diary/usecase/diary_use_case.dart';
import '../../../domain/diary/usecase/story_order.dart';
import '../../chat/widget/chat_failure_text.dart';
import '../../chat/widget/chat_vendor_icon.dart';
import '../../lock/cubit/diary_lock_cubit.dart';
import '../../lock/cubit/diary_lock_state.dart';
import '../../settings/open_settings.dart';
import '../cubit/entry_editor_cubit.dart';
import '../cubit/entry_editor_state.dart';
import '../draft/draft_cubit.dart';
import '../draft/draft_state.dart';
import '../format/diary_format.dart';
import '../media_picker.dart';
import '../widget/composer_media_strip.dart';
import '../widget/composer_toolbar.dart';
import '../widget/place_input.dart';
import '../widget/story_avatar.dart';
import '../widget/story_picker_sheet.dart';
import '../widget/tag_chip_input.dart';
import '../widget/time_row.dart';
import 'all_stories_page.dart';
import 'diary_route.dart';

/// 작성 화면을 연다. [editingId] 가 있으면 그 기록을 고친다. 일기 잠금에 묶인
/// 화면([pushDiaryRoute])이라 다시 잠기면 가려지고, 쓰던 내용은 [EntryEditorScope] 가 들고 있다.
/// 새 기록은 글 칸에 자동 포커스로 열린다. 사진은 작성 화면 도구줄에서 붙인다.
///
/// [onOpenChatSettings] 를 주지 않으면 셸의 물어보기 설정 열기를 쓴다(테스트가 바꿔 넣는다).
Future<void> openEntryEditor(
  BuildContext context, {
  String? editingId,
  VoidCallback? onOpenChatSettings,
}) {
  // 키 없음 다이얼로그의 "설정 열기" — 작성 화면 라우트에는 셸 cubit 이 없어 연 자리에서 미리 잡는다.
  final chatSettings =
      onOpenChatSettings ??
      settingsOpener(context, SettingsTarget.chat, highlight: true);
  return pushDiaryRoute<void>(
    context,
    scope: (context, gated) =>
        EntryEditorScope(editingId: editingId, child: gated),
    page: (_) => EntryEditorPage(
      autofocusBody: editingId == null,
      onOpenChatSettings: chatSettings,
    ),
  );
}

/// [EntryEditorCubit] · [DraftCubit] 의 주인 — 잠금 게이트 **바깥**에 있어 잠겼다 풀려도 쓰던 기록이 남는다.
/// 만들 때 시작(새 기록 · 고치기)하고, 사라질 때 저장하지 않았으면 새로 가져온 임시 사본을
/// 지운 뒤 닫는다(✕ 없이 화면이 걷혀도 tmp 가 남지 않는다).
///
/// 초안을 쓰는 중에 일기가 다시 잠기면 초안을 멈춘다(R-A9) — 그때까지의 글이 쓰던 기록에 남는다.
/// 초안에 필요한 것([DraftWriter] 등)이 등록돼 있지 않으면 [DraftCubit] 없이 연다(✨ 없음).
class EntryEditorScope extends StatefulWidget {
  const EntryEditorScope({required this.child, this.editingId, super.key});

  final String? editingId;
  final Widget child;

  @override
  State<EntryEditorScope> createState() => _EntryEditorScopeState();
}

class _EntryEditorScopeState extends State<EntryEditorScope> {
  late final _cubit = EntryEditorCubit(
    getIt<DiaryUseCase>(),
    getIt<DiaryRepository>(),
    getIt<MediaStore>(),
    getIt<PlaceSource>(),
    getIt<Clock>(),
    photoMeta: getIt.isRegistered<PhotoMetaReader>()
        ? getIt<PhotoMetaReader>()
        : null,
  );

  late final DraftCubit? _draft =
      getIt.isRegistered<DraftWriter>() &&
          getIt.isRegistered<DiaryPreferences>() &&
          getIt.isRegistered<ChatSettings>()
      ? DraftCubit(
          getIt<DraftWriter>(),
          getIt<DiaryPreferences>(),
          getIt<ChatSettings>(),
          onBody: _cubit.setBody,
        )
      : null;

  @override
  void initState() {
    super.initState();
    final id = widget.editingId;
    unawaited(id == null ? _cubit.startNew() : _cubit.startEdit(id));
  }

  @override
  void dispose() {
    unawaited(_draft?.close());
    final cubit = _cubit;
    if (cubit.state.saved || cubit.state.newMedia.isEmpty) {
      // 가져오는 중이던 것은 닫힌 뒤 끝나면 cubit 이 지운다.
      unawaited(cubit.close());
    } else {
      unawaited(cubit.cancel().whenComplete(cubit.close));
    }
    super.dispose();
  }

  /// 잠긴 동안(게이트가 작성 화면 대신 잠금 화면을 보일 때) 뒤로 가기는 무시한다 — 쓰던 글을
  /// 묻지 않고 버리지 않는다. 풀려 있으면 작성 화면이 버릴지 묻는다.
  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    return PopScope(
      canPop: context.select<DiaryLockCubit, bool>(
        (c) => c.state is LockUnlocked,
      ),
      child: BlocListener<DiaryLockCubit, DiaryLockState>(
        listenWhen: (a, b) => a is LockUnlocked && b is! LockUnlocked,
        listener: (_, _) => unawaited(draft?.stop()),
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: _cubit),
            if (draft != null) BlocProvider.value(value: draft),
          ],
          child: widget.child,
        ),
      ),
    );
  }
}

/// 기록 작성 · 수정(스펙 §3.6). 위에서 [EntryEditorCubit] 를 받는다([EntryEditorScope]).
///
/// 배치(SNS 글쓰기, 스펙 2026-11-15 §3): 글 → 붙인 사진 줄 → 태그 → 장소 → 시각 → 스토리 행.
/// 도구줄(앨범 · 사진 · 영상 · ✨)은 목록 밖 화면 맨 아래, 키보드 바로 위에 고정한다.
/// 스토리 시트는 새 기록이면 진행 중 스토리만, 고치기는 지난 스토리도 보인다(옮기기 허용).
///
/// 저장하면 닫히고, 새 기록이면 '올렸어요'(일상 밖이면 "'제주 여행'에 올렸어요") 스낵바를
/// 띄운다. 바꾼 것이 있는데 닫으면(✕ · 뒤로) 버릴지 묻고, 버리면 새로 가져온 임시 사본을
/// 지운다. 잠겼다 풀려 다시 만들어지면 입력칸을 cubit 의 내용으로 채운다.
class EntryEditorPage extends StatefulWidget {
  const EntryEditorPage({
    this.autofocusBody = false,
    this.onOpenChatSettings,
    super.key,
  });

  /// 키 없음 다이얼로그의 "설정 열기". null 이면 스낵바로 안내만.
  final VoidCallback? onOpenChatSettings;

  /// 글 칸에 자동 포커스(새 기록).
  final bool autofocusBody;

  @override
  State<EntryEditorPage> createState() => _EntryEditorPageState();
}

class _EntryEditorPageState extends State<EntryEditorPage> {
  final _repo = getIt<DiaryRepository>();
  final _picker = getIt<MediaPicker>();
  late final _cubit = context.read<EntryEditorCubit>();
  late final _body = TextEditingController(text: _cubit.state.draft.body);

  /// 자동 초안. 위([EntryEditorScope])에 없으면 null — ✨ 를 두지 않는다.
  late final DraftCubit? _draftCubit = context.read<DraftCubit?>();

  /// [_onDraftState] 가 마지막으로 본 초안 상태(끝 · 실패 전환을 가린다).
  late DraftState? _shownDraft = _draftCubit?.state;

  /// 본문 입력칸을 채운 기록 id.
  String? _bodyFilledFor;

  /// 앨범 · 카메라가 열려 있는 동안 다시 열지 않는다.
  bool _picking = false;

  final _tags = GlobalKey<TagChipInputState>();

  /// ✨ — 글 칸의 글을 메모로 바로 쓴다(스펙 2026-11-15 §4 R-A1). 다이얼로그는 키 없음 ·
  /// 첫 사용 동의만. 초안은 글 칸에 흘러 들어온다([_onDraftState]).
  Future<void> _startDraft() async {
    final draft = _draftCubit;
    if (draft == null) return;
    final l10n = AppLocalizations.of(context);
    switch (await draft.availability()) {
      case DraftNoKey():
        if (!mounted) return;
        final open = widget.onOpenChatSettings;
        if (open == null) {
          AppSnackBar.show(context, message: l10n.walkDiaryDraftNoKey, type: AppSnackBarType.warning);
          return;
        }
        final go = await AppConfirmDialog.show(
          context,
          title: l10n.walkDiaryDraftTitle,
          content: l10n.walkDiaryDraftNoKey,
          confirmLabel: l10n.walkDiaryDraftOpenSettings,
          isDestructive: false,
        );
        if (go) open();
        return;
      case DraftConsentNeeded(:final vendor):
        if (!mounted) return;
        final accepted = await AppConfirmDialog.show(
          context,
          title: l10n.walkDiaryDraftConsentTitle,
          content: l10n.walkDiaryDraftConsentNotice(chatVendorName(l10n, vendor)),
          confirmLabel: l10n.walkChatConsentAccept,
          isDestructive: false,
        );
        if (!accepted || !mounted) return;
        await draft.consent(vendor);
      case DraftReady():
        break;
    }
    if (!mounted) return;
    final locale = Localizations.localeOf(context).languageCode;
    draft.generate(
      body: _body.text,
      contextFor: (memo) => _cubit.draftContext(memo, locale: locale),
      photos: _cubit.state.draft.media,
    );
  }

  /// 사진 보여 주기. 켜는 순간 한 번 묻고(사진 n장까지 ○○로), 끌 때는 묻지 않는다(R-A4).
  Future<void> _setIncludePhotos(bool on) async {
    final draft = _draftCubit;
    if (draft == null) return;
    if (!on) {
      await draft.setIncludePhotos(false);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final count = min(_photoCount(_cubit.state), DraftWriter.maxPhotos);
    final vendor = draft.vendor;
    final accepted = await AppConfirmDialog.show(
      context,
      title: l10n.walkDiaryDraftIncludePhotos,
      content: vendor == null
          ? l10n.walkDiaryDraftPhotosConfirmNoVendor(count)
          : l10n.walkDiaryDraftPhotosConfirm(
              count,
              chatVendorName(l10n, vendor),
            ),
      confirmLabel: l10n.walkDiaryDraftPhotosConfirmAccept,
      isDestructive: false,
    );
    if (accepted) await draft.setIncludePhotos(true);
  }

  /// 초안이 글 칸을 바꾸면 입력칸을 맞추고, 끝 · 실패를 알린다.
  void _onDraftState(DraftState previous, DraftState state) {
    if (_body.text != state.text) _body.text = state.text;
    if (!previous.writing) return;
    final l10n = AppLocalizations.of(context);
    switch (state.run) {
      case DraftRunDone():
        AppSnackBar.show(
          context,
          message: l10n.walkDiaryComposerDraftApplied,
          type: AppSnackBarType.success,
          actionLabel: l10n.walkDiaryComposerDraftUndo,
          onAction: () => _draftCubit?.undo(),
        );
      case DraftRunFailed(:final failure):
        AppSnackBar.show(
          context,
          message: chatFailureText(l10n, failure),
          type: AppSnackBarType.error,
        );
      case DraftRunIdle() || DraftRunWriting():
        break;
    }
  }

  static int _photoCount(EntryEditorState state) =>
      state.draft.media.where((m) => m.kind == MediaKind.photo).length;

  /// 칩으로 만들지 않고 남긴 태그 글자도 함께 저장한다.
  void _save() {
    _tags.currentState?.commitPending();
    unawaited(_cubit.save());
  }

  @override
  void initState() {
    super.initState();
    _bodyFilledFor = _cubit.state.editingId;
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_cubit.state.saving) return;
    if (_cubit.hasChanges) {
      final l10n = AppLocalizations.of(context);
      final discard = await AppConfirmDialog.show(
        context,
        title: l10n.walkDiaryEditorDiscardTitle,
        content: l10n.walkDiaryEditorDiscardContent,
        confirmLabel: l10n.walkDiaryEditorDiscardConfirm,
      );
      if (!discard) return;
    }
    await _cubit.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _addMedia(MediaSource source) async {
    if (_picking) return;
    _picking = true;
    try {
      final left = MediaLimits.maxItems - _cubit.state.draft.media.length;
      if (left <= 0) return;
      final picked = await switch (source) {
        MediaSource.gallery => _picker.pickGallery(limit: left),
        MediaSource.photo => _picker.takePhoto(),
        MediaSource.video => _picker.recordVideo(),
      };
      try {
        await _cubit.addMedia(picked);
      } finally {
        // 압축 사본을 만들었든 못 만들었든, 피커가 캐시에 남긴 원본 복사본(GPS 포함)을 지운다.
        await _picker.release(picked);
      }
    } catch (_) {
      // 권한 거부 · 카메라 없음 등 — 가져오지 못한 것으로 알린다.
      if (mounted) {
        AppSnackBar.show(
          context,
          message: AppLocalizations.of(context).walkDiaryErrorMediaProcessing,
          type: AppSnackBarType.error,
        );
      }
    } finally {
      _picking = false;
    }
  }

  /// 스토리 행 — 고르기 시트. 새 기록은 진행 중 스토리만, 고치기는 지난 스토리도
  /// (옮기기 허용 규칙 그대로 — 고친 기록은 닫힌 스토리로도 옮길 수 있다).
  Future<void> _pickStory() async {
    final state = _cubit.state;
    final picked = await StoryPickerSheet.show(
      context,
      stories: [
        ...state.openStories,
        if (state.isEditing) ...StoryOrder.split(state.stories).archived,
      ],
      selectedId: state.draft.storyId,
      allowCreate: true,
    );
    if (picked == null || !mounted) return;
    if (picked == StoryPickerSheet.createNew) {
      await _createStory();
    } else {
      _cubit.setStory(picked);
    }
  }

  /// `＋새` — 만들기 시트로 만들고 그 스토리를 고른다. 새 기록은 진행 중 스토리만 고른다.
  Future<void> _createStory() async {
    final created = await createStory(context, suggestMove: false);
    if (created == null || !mounted) return;
    if (created.isOpen || _cubit.state.isEditing) {
      _cubit.setStory(created.id);
      return;
    }
    AppSnackBar.show(
      context,
      message: AppLocalizations.of(context).walkDiaryStoryEndedNotSelectable,
      type: AppSnackBarType.warning,
    );
  }

  void _onState(BuildContext context, EntryEditorState state) {
    // 고치기: 기록을 읽어 오면 본문 입력칸을 채운다.
    if (state.isEditing && _bodyFilledFor != state.editingId) {
      _bodyFilledFor = state.editingId;
      _body.text = state.draft.body;
    }
    final l10n = AppLocalizations.of(context);
    if (state.saved) {
      if (!state.isEditing) {
        AppSnackBar.show(
          context,
          message: state.draft.storyId == Story.dailyId
              ? l10n.walkDiaryComposerPosted
              : l10n.walkDiaryComposerPostedTo(_storyTitle(l10n, state)),
          type: AppSnackBarType.success,
        );
      }
      Navigator.of(context).pop();
      return;
    }
    final message = switch (state) {
      EntryEditorState(:final error?) => DiaryFormat.failure(l10n, error),
      EntryEditorState(failed: true) => l10n.walkDiaryErrorSave,
      _ => null,
    };
    if (message != null) {
      AppSnackBar.show(context, message: message, type: AppSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EntryEditorCubit, EntryEditorState>(
      listenWhen: (a, b) =>
          a.editingId != b.editingId ||
          (!a.saved && b.saved) ||
          (a.error == null && b.error != null) ||
          (!a.failed && b.failed),
      listener: _onState,
      builder: (context, state) {
        final draft = _draftCubit;
        if (draft == null) return _scaffold(context, state, null);
        return BlocConsumer<DraftCubit, DraftState>(
          bloc: draft,
          listenWhen: (a, b) => a.text != b.text || a.run != b.run,
          listener: (_, d) {
            final previous = _shownDraft ?? d;
            _shownDraft = d;
            _onDraftState(previous, d);
          },
          builder: (context, d) => _scaffold(context, state, d),
        );
      },
    );
  }

  Widget _scaffold(
    BuildContext context,
    EntryEditorState state,
    DraftState? draft,
  ) {
    final l10n = AppLocalizations.of(context);
    final writing = draft?.writing ?? false;
    final hasPhotos = _photoCount(state) > 0;
    final canSeePhotos = _draftCubit?.canSeePhotos ?? true;
    final sendsPhotos =
        hasPhotos && canSeePhotos && (draft?.includePhotos ?? false);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_close());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.walkDiaryEditorClose,
            onPressed: _close,
          ),
          title: Text(
            state.isEditing
                ? l10n.walkDiaryEditorEditTitle
                : l10n.walkDiaryEditorNewTitle,
          ),
          actions: [
            AppButton.text(
              // 앱 테마 버튼은 폭을 가득 채운다(`Size.fromHeight`) — 폭이 정해지지 않은 자리라 최소 크기만 푼다.
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll(Size.zero),
              ),
              label: state.isEditing
                  ? l10n.walkDiaryEditorSave
                  : l10n.walkDiaryEditorPost,
              onPressed: state.saving || state.importing ? null : _save,
            ),
          ],
        ),
        // 도구줄은 목록 밖 화면 맨 아래 — Scaffold 가 키보드만큼 body 를 줄이니 키보드 바로 위에 붙는다(R-F2).
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: TextField(
                      controller: _body,
                      readOnly: writing,
                      autofocus: widget.autofocusBody,
                      minLines: 4,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: l10n.walkDiaryEditorBodyHint,
                      ),
                      onChanged: _cubit.setBody,
                    ),
                  ),
                  ComposerMediaStrip(
                    media: state.draft.media,
                    importing: state.importing,
                    onRemove: _cubit.removeMedia,
                    onReorder: _cubit.reorderMedia,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: TagChipInput(
                      key: _tags,
                      tags: state.draft.tags,
                      onAdd: _cubit.addTag,
                      onRemove: _cubit.removeTag,
                      suggestionsFor: (q) => _repo.watchTagCounts(query: q),
                    ),
                  ),
                  PlaceInput(
                    location: state.draft.location,
                    locating: state.locating,
                    manualPlace: state.manualPlace,
                    onClear: _cubit.clearLocation,
                    onName: _cubit.setPlaceName,
                    suggestionsFor: (q) => _repo.watchPlaceCounts(query: q),
                  ),
                  TimeRow(
                    photoTakenAt: _cubit.photoTakenAt,
                    occurredAt: state.draft.occurredAt,
                    edited: state.timeEdited,
                    isEditing: state.isEditing,
                    now: getIt<Clock>().now(),
                    onPick: _cubit.setTime,
                    onRevert: _cubit.revertTime,
                  ),
                  AppListTile(
                    leading: const Icon(Icons.auto_stories_outlined),
                    title: Text(l10n.walkDiaryComposerStory),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_storyTitle(l10n, state)),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => unawaited(_pickStory()),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: ComposerToolbar(
                count: state.draft.media.length,
                importing: state.importing,
                onAdd: _addMedia,
                onDraft: draft == null ? null : () => unawaited(_startDraft()),
                drafting: writing,
                onStopDraft: () => unawaited(_draftCubit?.stop()),
                canRewrite: draft?.lastDraft != null,
                draftEnabled: state.draft.body.trim().isNotEmpty || sendsPhotos,
                photosOn: hasPhotos ? draft?.includePhotos ?? false : null,
                photosSupported: canSeePhotos,
                onPhotosChanged: (on) => unawaited(_setIncludePhotos(on)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 고친 기록이 닫힌 스토리에 있어도 이름을 보인다. 목록이 아직 없으면 '일상' 이름.
  static String _storyTitle(AppLocalizations l10n, EntryEditorState state) {
    final story = state.stories
        .where((s) => s.id == state.draft.storyId)
        .firstOrNull;
    return story == null
        ? (state.draft.storyId == Story.dailyId
              ? l10n.walkDiaryDailyStoryTitle
              : '')
        : storyDisplayTitle(l10n, story);
  }
}
