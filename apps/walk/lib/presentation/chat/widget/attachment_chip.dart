import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/attachment/chat_attachment.dart';

/// 첨부 하나: 종류 아이콘 + 이름. [onRemove] 가 있으면 ✕(입력칸), [onTap] 이 있으면 눌러 연다
/// (말풍선). [missing] 이면 작업 폴더에 없는 파일 — 회색 + '지운 파일' 이고 눌리지 않는다.
class AttachmentChip extends StatelessWidget {
  const AttachmentChip({
    required this.name,
    required this.kind,
    this.onRemove,
    this.onTap,
    this.missing = false,
    super.key,
  });

  AttachmentChip.of(
    ChatAttachmentRef ref, {
    VoidCallback? onRemove,
    VoidCallback? onTap,
    bool missing = false,
    Key? key,
  }) : this(
         name: ref.name,
         kind: ref.kind,
         onRemove: onRemove,
         onTap: onTap,
         missing: missing,
         key: key,
       );

  final String name;
  final AttachmentKind kind;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  final bool missing;

  static IconData iconOf(AttachmentKind kind) => switch (kind) {
    AttachmentKind.image => Icons.image_outlined,
    AttachmentKind.pdf => Icons.picture_as_pdf_outlined,
    AttachmentKind.text => Icons.description_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InputChip(
      avatar: Icon(iconOf(kind)),
      label: Text(
        missing ? '$name · ${l10n.walkWorkspaceDeletedChip}' : name,
        overflow: TextOverflow.ellipsis,
      ),
      isEnabled: !missing,
      onPressed: missing ? null : onTap,
      onDeleted: onRemove,
      deleteButtonTooltipMessage: l10n.walkChatAttachRemove,
    );
  }
}
