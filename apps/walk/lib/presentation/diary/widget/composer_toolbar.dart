import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/media_limits.dart';
import 'media_source_sheet.dart';

/// 작성 화면 도구줄(스펙 2026-11-15 §3): 앨범 · 사진 찍기 · 영상 찍기, 오른쪽 끝에 ✨ 초안.
///
/// 미디어 한도([MediaLimits.maxItems])를 다 채웠거나 가져오는 중이면 고르기 버튼이 꺼진다.
/// [onDraft] 가 null 이면 초안 버튼을 두지 않는다.
class ComposerToolbar extends StatelessWidget {
  const ComposerToolbar({
    required this.count,
    required this.importing,
    required this.onAdd,
    this.onDraft,
    super.key,
  });

  /// 지금 붙인 미디어 개수.
  final int count;
  final bool importing;
  final ValueChanged<MediaSource> onAdd;

  /// ✨ 초안. null 이면 버튼이 없다.
  final VoidCallback? onDraft;

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
          if (onDraft != null)
            IconButton(
              icon: const Icon(Icons.auto_awesome_outlined),
              tooltip: l10n.walkDiaryComposerDraft,
              onPressed: onDraft,
            ),
        ],
      ),
    );
  }
}
