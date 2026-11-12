import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/attachment/chat_attachment.dart';

/// 첨부 하나: 종류 아이콘 + 이름. [onRemove] 가 있으면 ✕(입력칸), 없으면 표시만(말풍선).
class AttachmentChip extends StatelessWidget {
  const AttachmentChip({
    required this.name,
    required this.kind,
    this.onRemove,
    super.key,
  });

  AttachmentChip.of(ChatAttachmentRef ref, {VoidCallback? onRemove, Key? key})
    : this(name: ref.name, kind: ref.kind, onRemove: onRemove, key: key);

  final String name;
  final AttachmentKind kind;
  final VoidCallback? onRemove;

  static IconData iconOf(AttachmentKind kind) => switch (kind) {
    AttachmentKind.image => Icons.image_outlined,
    AttachmentKind.pdf => Icons.picture_as_pdf_outlined,
    AttachmentKind.text => Icons.description_outlined,
  };

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(iconOf(kind)),
    label: Text(name, overflow: TextOverflow.ellipsis),
    onDeleted: onRemove,
    deleteButtonTooltipMessage: AppLocalizations.of(
      context,
    ).walkChatAttachRemove,
  );
}
