import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/entry_media.dart';
import '../../diary/widget/entry_media_view.dart';

/// 답이 근거로 쓴 기록 하나: 날짜(`M월 d일`) + 본문 앞 20자, 사진이 있으면 썸네일.
class CitedEntryChip extends StatelessWidget {
  const CitedEntryChip({required this.entry, required this.onOpen, super.key});

  final DiaryEntry entry;

  /// null 이면 누를 수 없는 칩(Chip) — 모양은 그대로다.
  final VoidCallback? onOpen;

  /// 칩에 보일 본문 글자 수.
  static const snippetLength = 20;

  /// 칩 라벨. 본문이 길면 말줄임표를 붙인다.
  static String label(DiaryEntry entry, String locale) {
    final date = DateFormat.MMMd(locale).format(entry.occurredAt);
    final body = entry.body.replaceAll(RegExp(r'\s+'), ' ').trim().characters;
    if (body.isEmpty) return date;
    final snippet = body.take(snippetLength).toString();
    return '$date · $snippet${body.length > snippetLength ? '…' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context).localeName;
    final photo = entry.media
        .where((m) => m.kind == MediaKind.photo)
        .firstOrNull;
    final avatar = photo == null
        ? null
        : ClipRRect(
            borderRadius: AppRadius.smAll,
            child: SizedBox.square(
              dimension: AppSpacing.lg,
              child: EntryMediaView(media: photo),
            ),
          );
    final text = Text(label(entry, locale));
    final open = onOpen;
    // 누를 수 없을 때도 흐리지 않는다(비활성 ActionChip 대신 Chip) — 흐림은 지워진 대상만.
    if (open == null) return Chip(avatar: avatar, label: text);
    return ActionChip(avatar: avatar, label: text, onPressed: open);
  }
}
