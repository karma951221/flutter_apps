import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/draft/photo_place_names.dart';
import '../../../domain/diary/entity/media_limits.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/location/place_source.dart';
import '../../../domain/diary/media/media_store.dart';
import '../../../domain/diary/media/photo_meta_reader.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/diary/usecase/diary_use_case.dart';
import '../../../domain/diary/usecase/story_order.dart';
import '../../lock/cubit/diary_lock_cubit.dart';
import '../../lock/cubit/diary_lock_state.dart';
import '../../settings/open_settings.dart';
import '../cubit/entry_editor_cubit.dart';
import '../cubit/entry_editor_state.dart';
import '../draft/draft_sheet.dart';
import '../format/diary_format.dart';
import '../media_picker.dart';
import '../widget/composer_media_strip.dart';
import '../widget/composer_toolbar.dart';
import '../widget/media_source_sheet.dart';
import '../widget/place_input.dart';
import '../widget/story_avatar.dart';
import '../widget/story_picker_sheet.dart';
import '../widget/tag_chip_input.dart';
import '../widget/time_row.dart';
import 'all_stories_page.dart';
import 'diary_route.dart';

/// 작성 화면을 연다. [editingId] 가 있으면 그 기록을 고친다. 일기 잠금에 묶인
/// 화면([pushDiaryRoute])이라 다시 잠기면 가려지고, 쓰던 내용은 [EntryEditorScope] 가 들고 있다.
///
/// [initialPick] 이 있으면 열자마자 그 고르기를 **한 번** 실행한다 — 잠겼다 풀려 화면이 다시
/// 만들어져도 다시 열지 않는다. 고르기를 그만두면 글만 쓰는 작성 화면으로 남는다. 일기 ＋ 는
/// 넘기지 않는다(새 기록은 글 칸에 자동 포커스로 열린다).
Future<void> openEntryEditor(
  BuildContext context, {
  String? editingId,
  MediaSource? initialPick,
}) {
  final pending = InitialPick(initialPick);
  // 초안 시트의 "설정 열기" — 작성 화면 라우트에는 셸 cubit 이 없어 연 자리에서 미리 잡는다.
  final chatSettings = settingsOpener(
    context,
    SettingsTarget.chat,
    highlight: true,
  );
  return pushDiaryRoute<void>(
    context,
    scope: (context, gated) =>
        EntryEditorScope(editingId: editingId, child: gated),
    page: (_) => EntryEditorPage(
      initialPick: pending,
      autofocusBody: editingId == null && initialPick == null,
      onOpenChatSettings: chatSettings,
    ),
  );
}

/// 작성 화면을 열 때 한 번만 실행할 고르기. 꺼내면 비워진다.
class InitialPick {
  InitialPick(this._source);

  MediaSource? _source;

  MediaSource? take() {
    final source = _source;
    _source = null;
    return source;
  }
}

/// [EntryEditorCubit] 의 주인 — 잠금 게이트 **바깥**에 있어 잠겼다 풀려도 쓰던 기록이 남는다.
/// 만들 때 시작(새 기록 · 고치기)하고, 사라질 때 저장하지 않았으면 새로 가져온 임시 사본을
/// 지운 뒤 닫는다(✕ 없이 화면이 걷혀도 tmp 가 남지 않는다).
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

  @override
  void initState() {
    super.initState();
    final id = widget.editingId;
    unawaited(id == null ? _cubit.startNew() : _cubit.startEdit(id));
  }

  @override
  void dispose() {
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
  Widget build(BuildContext context) => PopScope(
    canPop: context.select<DiaryLockCubit, bool>(
      (c) => c.state is LockUnlocked,
    ),
    child: BlocProvider.value(value: _cubit, child: widget.child),
  );
}

/// 기록 작성 · 수정(스펙 §3.6). 위에서 [EntryEditorCubit] 를 받는다([EntryEditorScope]).
///
/// 배치(SNS 글쓰기, 스펙 2026-11-15 §3): 글 → 붙인 사진 줄 → 도구줄(앨범 · 사진 · 영상) →
/// 태그 → 장소 → 시각 → 스토리 행. 스토리 시트는 새 기록이면 진행 중 스토리만, 고치기는 지난
/// 스토리도 보인다(옮기기 허용).
///
/// 저장하면 닫히고, 새 기록이면 '올렸어요'(일상 밖이면 "'제주 여행'에 올렸어요") 스낵바를 띄운다. 바꾼 것이 있는데 닫으면
/// (✕ · 뒤로) 버릴지 묻고, 버리면 새로 가져온 임시 사본을 지운다. 잠겼다 풀려 다시 만들어지면
/// 입력칸을 cubit 의 내용으로 채운다.
class EntryEditorPage extends StatefulWidget {
  const EntryEditorPage({
    this.initialPick,
    this.autofocusBody = false,
    this.onOpenChatSettings,
    super.key,
  });

  /// 초안 시트의 "설정 열기"(키가 없을 때). null 이면 안내만.
  final VoidCallback? onOpenChatSettings;

  /// 열자마자 한 번 실행할 고르기([openEntryEditor]).
  final InitialPick? initialPick;

  /// 글 칸에 자동 포커스(새 기록이고 처음 고르기가 없을 때).
  final bool autofocusBody;

  @override
  State<EntryEditorPage> createState() => _EntryEditorPageState();
}

class _EntryEditorPageState extends State<EntryEditorPage> {
  final _repo = getIt<DiaryRepository>();
  final _picker = getIt<MediaPicker>();
  late final _cubit = context.read<EntryEditorCubit>();
  late final _body = TextEditingController(text: _cubit.state.draft.body);

  /// 본문 입력칸을 채운 기록 id.
  String? _bodyFilledFor;

  /// 앨범 · 카메라가 열려 있는 동안 다시 열지 않는다.
  bool _picking = false;

  final _tags = GlobalKey<TagChipInputState>();

  /// 초안 시트의 메모로 미리 채울 글 칸의 최대 길이 — 넘으면 이미 쓴 글이라 메모로 보지 않는다.
  static const _memoMaxLength = 100;

  /// 사진 촬영 장소 이름을 기다리는 한도. 넘으면 이름 없이 연다.
  static const _placeNamesTimeout = Duration(seconds: 2);

  /// ✨ — 메모 · 메타데이터로 초안을 받아 글 칸을 바꾼다(스펙 §4). 원래 글이 있었으면 되돌리기.
  Future<void> _draft() async {
    final current = _body.text.trim();
    final memo = current.length <= _memoMaxLength ? current : '';
    final names = await _photoPlaceNames();
    if (!mounted) return;
    final text = await showDraftSheet(
      context,
      initialMemo: memo,
      contextFor: (memo) => _cubit.draftContext(memo, photoPlaceNames: names),
      photos: _cubit.state.draft.media,
      onOpenChatSettings: widget.onOpenChatSettings,
    );
    if (text == null || !mounted) return;
    final previous = _body.text;
    _setBody(text);
    if (previous.trim().isEmpty) return;
    final l10n = AppLocalizations.of(context);
    AppSnackBar.show(
      context,
      message: l10n.walkDiaryComposerDraftApplied,
      actionLabel: l10n.walkDiaryComposerDraftUndo,
      onAction: () {
        if (mounted) _setBody(previous);
      },
    );
  }

  void _setBody(String text) {
    _body.text = text;
    _cubit.setBody(text);
  }

  /// 붙인 사진의 촬영 좌표 → 장소 이름. 못 구하면 빈 목록.
  Future<List<String>> _photoPlaceNames() async {
    final metas = _cubit.currentPhotoMetas;
    if (metas.every((m) => m.lat == null) ||
        !getIt.isRegistered<PhotoPlaceNames>()) {
      return const [];
    }
    try {
      return await getIt<PhotoPlaceNames>()
          .namesFor(metas)
          .timeout(_placeNamesTimeout);
    } catch (_) {
      return const [];
    }
  }

  /// 칩으로 만들지 않고 남긴 태그 글자도 함께 저장한다.
  void _save() {
    _tags.currentState?.commitPending();
    unawaited(_cubit.save());
  }

  @override
  void initState() {
    super.initState();
    _bodyFilledFor = _cubit.state.editingId;
    final pick = widget.initialPick?.take();
    if (pick != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_addMedia(pick, waitForDraft: true));
      });
    }
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

  /// 새 기록의 `startNew` 가 첫 draft 를 내보냈는지 — 그 전에 넣은 미디어는 그 draft 에 덮인다.
  /// 그 뒤로는 찾는 중(locating)이거나, 위치를 얻었거나 직접 입력으로 바뀐 상태다.
  static bool _draftReady(EntryEditorState s) =>
      s.isEditing || s.locating || s.manualPlace || s.draft.location != null;

  /// [waitForDraft] 면(열자마자 하는 처음 고르기) 고른 뒤 draft 가 준비될 때까지 기다렸다 넣는다.
  Future<void> _addMedia(
    MediaSource source, {
    bool waitForDraft = false,
  }) async {
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
        if (waitForDraft && picked.isNotEmpty && !_draftReady(_cubit.state)) {
          await _cubit.stream.firstWhere(_draftReady);
        }
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
      type: AppSnackBarType.error,
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
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<EntryEditorCubit, EntryEditorState>(
      listenWhen: (a, b) =>
          a.editingId != b.editingId ||
          (!a.saved && b.saved) ||
          (a.error == null && b.error != null) ||
          (!a.failed && b.failed),
      listener: _onState,
      builder: (context, state) {
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
            body: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: TextField(
                    controller: _body,
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
                ComposerToolbar(
                  count: state.draft.media.length,
                  importing: state.importing,
                  onAdd: _addMedia,
                  onDraft: () => unawaited(_draft()),
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
        );
      },
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
