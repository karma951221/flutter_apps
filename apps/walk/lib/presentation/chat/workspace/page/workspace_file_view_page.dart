import 'dart:convert';
import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../open_workspace.dart';

/// 보기 화면이 그리는 모양.
enum WorkspaceViewKind { text, image }

/// 작업 폴더 파일 하나를 앱 안에서 본다. 글은 마크다운을 그리지 않고 고를 수 있는 평문,
/// 사진은 확대할 수 있게 그린다 — 그리지 못하는 사진(일부 HEIC 등)은 공유를 권한다.
/// 앱바 [공유]는 공유 시트. `openWorkspaceFile` 이 잠금 아래로 연다.
class WorkspaceFileViewPage extends StatelessWidget {
  const WorkspaceFileViewPage({
    required this.path,
    required this.name,
    required this.bytes,
    required this.kind,
    super.key,
  });

  /// 작업 폴더 상대 경로.
  final String path;
  final String name;
  final Uint8List bytes;
  final WorkspaceViewKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void share() => shareWorkspaceFile(context, path, name);
    return Scaffold(
      appBar: AppBar(
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: l10n.walkWorkspaceShare,
            onPressed: share,
          ),
        ],
      ),
      body: switch (kind) {
        WorkspaceViewKind.text => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SelectableText(
            utf8.decode(bytes, allowMalformed: true),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        WorkspaceViewKind.image => InteractiveViewer(
          child: Center(
            child: Image.memory(
              bytes,
              // 원본을 그대로 풀면 큰 사진이 메모리를 크게 쓴다 — 화면 폭(물리 픽셀)으로 줄여
              // 푼다. 작은 사진은 키우지 않는다.
              cacheWidth:
                  (MediaQuery.sizeOf(context).width *
                          MediaQuery.devicePixelRatioOf(context))
                      .round(),
              errorBuilder: (context, _, _) => AppPlaceholder(
                icon: Icons.broken_image_outlined,
                message: l10n.walkWorkspaceImageUnreadable,
                actionLabel: l10n.walkWorkspaceShare,
                onAction: share,
              ),
            ),
          ),
        ),
      },
    );
  }
}
