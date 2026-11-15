import 'package:l10n/l10n.dart';

import '../../../domain/diary/draft/draft_style.dart';

/// 문체 이름(일기 설정 행).
String draftStyleName(AppLocalizations l10n, DraftStyle style) =>
    switch (style) {
      DraftStyle.diary => l10n.walkDiaryDraftStyleDiary,
      DraftStyle.polite => l10n.walkDiaryDraftStylePolite,
      DraftStyle.sns => l10n.walkDiaryDraftStyleSns,
      DraftStyle.memo => l10n.walkDiaryDraftStyleMemo,
    };

/// 문체 예문(스펙 §4 문체 표).
String draftStyleExample(AppLocalizations l10n, DraftStyle style) =>
    switch (style) {
      DraftStyle.diary => l10n.walkDiaryDraftStyleDiaryExample,
      DraftStyle.polite => l10n.walkDiaryDraftStylePoliteExample,
      DraftStyle.sns => l10n.walkDiaryDraftStyleSnsExample,
      DraftStyle.memo => l10n.walkDiaryDraftStyleMemoExample,
    };
