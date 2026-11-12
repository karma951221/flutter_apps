import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:l10n/l10n.dart';
import 'package:path/path.dart' as p;

import '../../../domain/chat/attachment/attachment_rules.dart';
import '../../../domain/chat/attachment/chat_attachment.dart';
import '../../../domain/chat/workspace/workspace.dart';
import '../../diary/page/diary_route.dart';
import 'page/workspace_file_view_page.dart';
import 'page/workspace_page.dart';
import 'workspace_share.dart';

/// 작업 폴더 화면을 잠금 아래로 연다. [물어보기에 첨부]를 고르면 그 파일로 끝난다 —
/// 여는 쪽(ChatTab)이 입력칸에 담는다.
Future<WorkspaceFile?> openWorkspace(BuildContext context) =>
    pushDiaryRoute<WorkspaceFile>(context, page: (_) => const WorkspacePage());

/// 작업 폴더의 [path](상대 경로) 파일을 연다. 글(md · txt · csv · json · log)과 사진은 잠금 아래
/// 보기 화면, 그 밖(PDF 등)은 공유 시트로 다른 앱에 넘긴다. 없으면(지웠거나 경계 밖) 열지 않고
/// '지운 파일이에요' 스낵바.
Future<void> openWorkspaceFile(BuildContext context, String path) async {
  final workspace = getIt<Workspace>();
  final name = p.basename(path);
  final view = switch (AttachmentRules.kindOf(name)) {
    AttachmentKind.text => WorkspaceViewKind.text,
    AttachmentKind.image => WorkspaceViewKind.image,
    AttachmentKind.pdf || null => null,
  };
  if (view == null) {
    final there = await _attempt(() => workspace.exists(path)) ?? false;
    if (!context.mounted) return;
    if (!there) return _showMissing(context);
    return shareWorkspaceFile(context, path, name);
  }
  final bytes = await _attempt(() => workspace.readBytes(path));
  if (!context.mounted) return;
  if (bytes == null) return _showMissing(context);
  await pushDiaryRoute<void>(
    context,
    page: (_) =>
        WorkspaceFileViewPage(path: path, name: name, bytes: bytes, kind: view),
  );
}

/// 작업 폴더의 [path] 파일을 공유 시트로 내보낸다. 실패하면 스낵바로 알린다.
Future<void> shareWorkspaceFile(
  BuildContext context,
  String path,
  String name,
) async {
  final l10n = AppLocalizations.of(context);
  try {
    final absolute = await getIt<Workspace>().absolutePath(path);
    await getIt<WorkspaceShare>().share(absolute, name);
  } on Object {
    if (!context.mounted) return;
    AppSnackBar.show(
      context,
      message: l10n.walkWorkspaceShareFailed,
      type: AppSnackBarType.error,
    );
  }
}

void _showMissing(BuildContext context) => AppSnackBar.show(
  context,
  message: AppLocalizations.of(context).walkWorkspaceFileMissing,
);

/// 경계 밖 경로(WorkspacePathException) · 읽기 실패는 없는 파일로 본다.
Future<T?> _attempt<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on Object {
    return null;
  }
}
