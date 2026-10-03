import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

enum PhotoSource { gallery, camera }

/// 사진을 어디서 가져올지 고르는 하단 시트. 닫으면 null.
abstract final class PhotoSourceSheet {
  static Future<PhotoSource?> show(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<PhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppListTile(
              key: const Key('walk-edit-photo-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.walkAddPhotoFromGallery),
              onTap: () => Navigator.of(sheetContext).pop(PhotoSource.gallery),
            ),
            AppListTile(
              key: const Key('walk-edit-photo-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.walkAddPhotoFromCamera),
              onTap: () => Navigator.of(sheetContext).pop(PhotoSource.camera),
            ),
          ],
        ),
      ),
    );
  }
}
