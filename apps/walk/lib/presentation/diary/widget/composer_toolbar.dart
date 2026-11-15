import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/media_limits.dart';

/// 어디서 사진 · 영상을 가져올지.
enum MediaSource { gallery, photo, video }

/// 작성 화면 도구줄(스펙 2026-11-15 §3 · §4): 앨범 · 사진 찍기 · 영상 찍기, 오른쪽에
/// 사진 보여 주기 토글과 ✨ 초안.
///
/// 미디어 한도([MediaLimits.maxItems])를 다 채웠거나 가져오는 중이면 고르기 버튼이 꺼진다.
/// [onDraft] 가 null 이면 초안 버튼 · 토글을 두지 않는다. ✨ 자리는 쓰는 중이면 멈추기,
/// 초안을 받은 뒤면 다시 쓰기(툴팁만 바뀐다).
class ComposerToolbar extends StatelessWidget {
  const ComposerToolbar({
    required this.count,
    required this.importing,
    required this.onAdd,
    this.onDraft,
    this.drafting = false,
    this.onStopDraft,
    this.canRewrite = false,
    this.draftEnabled = true,
    this.photosOn,
    this.photosSupported = true,
    this.onPhotosChanged,
    super.key,
  });

  /// 지금 붙인 미디어 개수.
  final int count;
  final bool importing;
  final ValueChanged<MediaSource> onAdd;

  /// ✨ 초안(처음 쓰기 · 다시 쓰기). null 이면 버튼 · 토글이 없다.
  final VoidCallback? onDraft;

  /// 초안을 쓰는 중 — ✨ 자리가 멈추기([onStopDraft])가 된다.
  final bool drafting;
  final VoidCallback? onStopDraft;

  /// 초안을 받은 뒤 — 툴팁이 다시 쓰기.
  final bool canRewrite;

  /// false 면 ✨ 를 끄고 툴팁으로 이유를 보인다(재료 없음, R-A4).
  final bool draftEnabled;

  /// 사진 보여 주기. null 이면 토글을 두지 않는다(붙인 사진이 없다).
  final bool? photosOn;

  /// 초안 모델이 사진을 볼 수 있는가. false 면 토글이 꺼지고 이유를 보인다.
  final bool photosSupported;
  final ValueChanged<bool>? onPhotosChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canAdd = !importing && MediaLimits.canAdd(count, 1);
    final onDraft = this.onDraft;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          for (final (source, icon, label) in [
            (
              MediaSource.gallery,
              Icons.photo_library_outlined,
              l10n.walkDiaryEditorPickGallery,
            ),
            (
              MediaSource.photo,
              Icons.photo_camera_outlined,
              l10n.walkDiaryEditorTakePhoto,
            ),
            (
              MediaSource.video,
              Icons.videocam_outlined,
              l10n.walkDiaryEditorTakeVideo,
            ),
          ])
            IconButton(
              icon: Icon(icon),
              tooltip: label,
              onPressed: canAdd ? () => onAdd(source) : null,
            ),
          const Spacer(),
          if (onDraft != null) ...[
            if (photosOn case final on?) _photosToggle(l10n, on),
            _draftButton(l10n, onDraft),
          ],
        ],
      ),
    );
  }

  Widget _photosToggle(AppLocalizations l10n, bool on) {
    final chip = FilterChip(
      label: Text(l10n.walkDiaryDraftIncludePhotos),
      selected: on && photosSupported,
      onSelected: photosSupported && !drafting
          ? (value) => onPhotosChanged?.call(value)
          : null,
    );
    return photosSupported
        ? chip
        : Tooltip(
            message: l10n.walkDiaryComposerPhotosUnsupported,
            child: chip,
          );
  }

  Widget _draftButton(AppLocalizations l10n, VoidCallback onDraft) {
    if (drafting) {
      return IconButton(
        icon: const Icon(Icons.stop_rounded),
        tooltip: l10n.walkDiaryDraftStop,
        onPressed: onStopDraft,
      );
    }
    return IconButton(
      icon: const Icon(Icons.auto_awesome_outlined),
      tooltip: !draftEnabled
          ? l10n.walkDiaryComposerDraftNeedsInput
          : canRewrite
          ? l10n.walkDiaryComposerDraftRewrite
          : l10n.walkDiaryComposerDraft,
      onPressed: draftEnabled ? onDraft : null,
    );
  }
}
