import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 어디서 사진 · 영상을 가져올지.
enum MediaSource { gallery, photo, video }

/// 고르기 시트에서 고른 것. [textOnly] 는 일기 ＋ 시트에만 있다(미디어 없이 쓰기).
enum MediaSourceChoice {
  gallery(MediaSource.gallery),
  photo(MediaSource.photo),
  video(MediaSource.video),
  textOnly(null);

  const MediaSourceChoice(this.source);

  /// 가져올 곳. 글만 쓰기면 null.
  final MediaSource? source;
}

/// 사진 · 영상 고르기 시트(앨범에서 · 사진 찍기 · 영상 찍기, [textOnly] 면 + 글만 쓰기).
/// 일기 ＋ 와 작성 화면의 ＋ 칸이 함께 쓴다. 닫으면 null.
Future<MediaSourceChoice?> showMediaSourceSheet(
  BuildContext context, {
  bool textOnly = false,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<MediaSourceChoice>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (choice, icon, label) in [
            (
              MediaSourceChoice.gallery,
              Icons.photo_library_outlined,
              l10n.walkDiaryEditorPickGallery,
            ),
            (
              MediaSourceChoice.photo,
              Icons.photo_camera_outlined,
              l10n.walkDiaryEditorTakePhoto,
            ),
            (
              MediaSourceChoice.video,
              Icons.videocam_outlined,
              l10n.walkDiaryEditorTakeVideo,
            ),
            if (textOnly)
              (
                MediaSourceChoice.textOnly,
                Icons.edit_note_outlined,
                l10n.walkDiaryTextOnly,
              ),
          ])
            AppListTile(
              leading: Icon(icon),
              title: Text(label),
              onTap: () => Navigator.of(sheetContext).pop(choice),
            ),
        ],
      ),
    ),
  );
}
