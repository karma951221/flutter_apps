import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';
import 'package:l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import '../../../post/domain/entity/post.dart';
import '../../../post/presentation/cubit/post_cubit.dart';
import 'package:feature_reaction/feature_reaction.dart';
import 'package:feature_safety/feature_safety.dart';
import '../../domain/entity/feed_post.dart';
import '../cubit/feed_cubit.dart';

/// `PostTile` 의 동작을 화면에 잇는 공통 흐름.
///
/// 피드 화면과 프로필 화면은 둘 다 "목록은 [FeedCubit] 이, 게시물 변경은
/// [PostCubit] 이 소유한다"는 같은 구조 위에 서 있어서, 수정 · 댓글 · 감정 ·
/// 신고 · 삭제 다섯 흐름이 두 파일에 똑같이 복제돼 있었다. 실제로 갈라지기도
/// 했다 — 다국어 이행이 피드 쪽만 옮기는 바람에 같은 삭제 다이얼로그가 한쪽은
/// 번역되고 한쪽은 한국어로 고정돼 있었다 (2026-08-27 리뷰).
///
/// 차단은 여기 없다. 성공 뒤 목록 반영이 화면마다 다르기 때문이다 — 피드는
/// 그 작성자의 항목만 걷어내고(`removeAuthor`), 프로필은 그 작성자의 화면이라
/// 목록 전체를 다시 읽는다(`refresh`).
///
/// 호출하는 화면은 `FeedCubit` · `PostCubit` 을 제공하고 있어야 한다.
abstract final class PostTileActions {
  /// 수정 화면으로 보내고, 바뀐 게시물을 목록의 그 자리에 끼운다.
  static Future<void> edit(BuildContext context, Post post) async {
    final feed = context.read<FeedCubit>();
    final updated = await context.push<Post>(
      Routes.postEditPath(post.id),
      extra: post.toMap(),
    );
    if (updated != null) feed.replacePost(updated);
  }

  /// 댓글 화면은 나갈 때 최종 개수를 돌려준다. 목록을 다시 읽지 않고 그
  /// 항목의 수만 고친다.
  static Future<void> openComments(BuildContext context, FeedPost item) async {
    final feed = context.read<FeedCubit>();
    final count = await context.push<int>(
      Routes.postCommentsPath(item.id),
      extra: item.commentCount,
    );
    if (count != null) feed.applyCommentCount(item.id, count);
  }

  /// 감정은 목록이 저장하고 되돌린다. 화면은 실패만 알린다.
  static Future<void> react(
    BuildContext context,
    String postId,
    ReactionType type,
  ) async {
    final result = await context.read<FeedCubit>().toggleReaction(postId, type);
    if (!context.mounted) return;

    result.when(
      ok: (_) {},
      err: (failure) => AppSnackBar.show(
        context,
        message: failure.localizedMessage(context),
        type: AppSnackBarType.error,
      ),
    );
  }

  /// 신고 시트를 열고, 접수됐을 때만 스낵바를 띄운다.
  ///
  /// 시트의 `BuildContext` 는 닫히면서 함께 사라지므로 스낵바는 호출한 화면의
  /// context 로 띄운다.
  static Future<void> report(BuildContext context, ReportTarget target) async {
    final l10n = AppLocalizations.of(context);
    final filed = await ReportSheet.show(context, target);
    if (!context.mounted) return;
    if (filed) {
      AppSnackBar.show(
        context,
        message: l10n.safetyReportSubmitted,
        type: AppSnackBarType.success,
      );
    }
  }

  /// 삭제는 되돌릴 수 없으니 확인을 받는다.
  ///
  /// 확인 다이얼로그는 차단 · 탈퇴와 같은 [AppConfirmDialog] 를 쓴다 — 예전에는
  /// 두 화면이 각자 `AlertDialog` 를 쌓아서, 가장 되돌리기 어려운 동작인
  /// 삭제만 destructive 색을 못 받고 있었다.
  static Future<void> confirmDelete(BuildContext context, Post post) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.postDeleteConfirmTitle,
      content: l10n.postDeleteConfirmMessage,
      confirmLabel: l10n.commonDelete,
    );
    if (!confirmed || !context.mounted) return;

    final feed = context.read<FeedCubit>();
    final result = await context.read<PostCubit>().delete(post.id);
    if (!context.mounted) return;

    result.when(
      ok: (_) {
        feed.removePost(post.id);
        AppSnackBar.show(
          context,
          message: l10n.postDeleteSucceeded,
          type: AppSnackBarType.success,
        );
      },
      err: (failure) => AppSnackBar.show(
        context,
        message: failure.localizedMessage(context),
        type: AppSnackBarType.error,
      ),
    );
  }
}
