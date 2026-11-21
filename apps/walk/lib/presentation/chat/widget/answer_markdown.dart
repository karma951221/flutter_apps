import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/answer/answer_segments.dart';

/// 답 글을 마크다운으로 그린다. 닫힌 ```svg 블록은 그림으로, 작업 폴더 그림
/// (`![설명](out/…png)`)은 [readImage] 로 읽어 그림으로 보인다.
///
/// 고르기는 부모의 [SelectionArea] 가 맡는다(여러 문단을 한 번에 고른다). [streaming] 이면
/// 마지막 조각 끝에 커서 `▍` 를 붙여 그린다 — 원문([text])에는 넣지 않으므로 [글 복사]에
/// 딸려 오지 않는다.
class AnswerMarkdown extends StatelessWidget {
  const AnswerMarkdown({
    required this.text,
    required this.style,
    this.streaming = false,
    this.readImage,
    this.onOpenImage,
    super.key,
  });

  final String text;

  /// 본문 글 모양(말풍선 bodyLarge).
  final TextStyle? style;
  final bool streaming;

  /// 작업 폴더 상대 경로의 그림 바이트. 없으면(지운 파일) null. null 이면 그림 대신 설명 글.
  final Future<Uint8List?> Function(String path)? readImage;

  /// 그림을 눌렀다 — 작업 폴더 상대 경로(크게 보기 · 공유).
  final ValueChanged<String>? onOpenImage;

  /// 흐르는 중 글 끝 커서.
  static const cursor = '▍';

  /// 그림 · SVG 의 최대 높이.
  static const maxFigureHeight = 360.0;

  /// 작업 폴더 그림으로 보는 경로 앞부분.
  static const _workspaceAreas = ['out/', 'inbox/'];

  /// [segments] 마지막에 커서를 붙인다. 표 줄(`|` 로 시작) 끝이면 표가 깨지지 않게 새 문단으로.
  static List<AnswerSegment> withCursor(List<AnswerSegment> segments) {
    final last = segments.lastOrNull;
    if (last is! MarkdownSegment) {
      return [...segments, const AnswerSegment.markdown(cursor)];
    }
    final lastLine = last.text.trimRight().split('\n').last.trimLeft();
    final joined = lastLine.startsWith('|')
        ? '${last.text}\n\n$cursor'
        : '${last.text}$cursor';
    return [
      ...segments.sublist(0, segments.length - 1),
      AnswerSegment.markdown(joined),
    ];
  }

  /// 마크다운 그림 주소 → 작업 폴더 상대 경로. 작업 폴더 그림이 아니면 null.
  static String? workspacePathOf(Uri uri) {
    if (uri.hasScheme || uri.hasAuthority) return null;
    final String path;
    try {
      path = Uri.decodeFull(uri.path);
    } on ArgumentError {
      return null;
    }
    if (path.contains('..')) return null;
    return _workspaceAreas.any(path.startsWith) ? path : null;
  }

  @override
  Widget build(BuildContext context) {
    var segments = AnswerSegments.parse(text);
    if (streaming) segments = withCursor(segments);
    final sheet = _styleSheet(Theme.of(context), style);
    final children = <Widget>[
      for (final segment in segments)
        switch (segment) {
          MarkdownSegment(:final text) => _markdown(text, sheet),
          SvgSegment(:final svg, :final source) => _SvgFigure(
            svg: svg,
            fallback: _markdown(source, sheet),
          ),
        },
    ];
    if (children.length == 1) return children.single;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ],
    );
  }

  Widget _markdown(String data, MarkdownStyleSheet sheet) => MarkdownBody(
    data: data,
    styleSheet: sheet,
    // 모델은 줄바꿈 하나로 줄을 나누는 일이 많다 — 평문 때처럼 줄을 지킨다.
    softLineBreak: true,
    imageBuilder: (uri, title, alt) => _image(uri, alt),
  );

  Widget _image(Uri uri, String? alt) {
    final path = workspacePathOf(uri);
    final read = readImage;
    // 작업 폴더 밖(웹 주소 등)은 불러오지 않는다 — 설명 글만.
    if (path == null || read == null) {
      return Text(alt ?? '', style: style);
    }
    return _WorkspaceImage(
      key: ValueKey('answer-image-$path'),
      path: path,
      alt: alt ?? '',
      read: read,
      onOpen: onOpenImage,
    );
  }

  static MarkdownStyleSheet _styleSheet(ThemeData theme, TextStyle? body) {
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final code = text.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      color: scheme.onSurface,
      backgroundColor: scheme.surfaceContainerHighest,
    );
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: body,
      listBullet: body,
      tableBody: body,
      tableHead: body?.copyWith(fontWeight: FontWeight.w600),
      h1: text.titleLarge?.copyWith(color: body?.color),
      h2: text.titleMedium?.copyWith(color: body?.color),
      h3: text.titleSmall?.copyWith(color: body?.color),
      h4: body?.copyWith(fontWeight: FontWeight.w600),
      h5: body?.copyWith(fontWeight: FontWeight.w600),
      h6: body?.copyWith(fontWeight: FontWeight.w600),
      blockSpacing: AppSpacing.sm,
      code: code,
      codeblockPadding: const EdgeInsets.all(AppSpacing.sm),
      codeblockDecoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.smAll,
      ),
      blockquote: body?.copyWith(color: scheme.onSurfaceVariant),
      blockquotePadding: const EdgeInsets.only(left: AppSpacing.sm),
      blockquoteDecoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(color: scheme.outlineVariant, width: 3),
        ),
      ),
      tableBorder: TableBorder.all(color: scheme.outlineVariant),
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      a: body?.copyWith(
        color: scheme.primary,
        decoration: TextDecoration.underline,
      ),
    );
  }
}

/// SVG 코드 블록을 그림으로. 그리지 못하면 [fallback](원래 코드 블록).
class _SvgFigure extends StatelessWidget {
  const _SvgFigure({required this.svg, required this.fallback});

  final String svg;
  final Widget fallback;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(
      maxHeight: AnswerMarkdown.maxFigureHeight,
    ),
    child: ClipRRect(
      borderRadius: AppRadius.smAll,
      child: SvgPicture.string(
        svg,
        key: const Key('answer-svg'),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => fallback,
      ),
    ),
  );
}

/// 작업 폴더 그림. 읽는 동안은 자리만, 없으면 '그림을 찾을 수 없어요'.
class _WorkspaceImage extends StatefulWidget {
  const _WorkspaceImage({
    required this.path,
    required this.alt,
    required this.read,
    required this.onOpen,
    super.key,
  });

  final String path;
  final String alt;
  final Future<Uint8List?> Function(String path) read;
  final ValueChanged<String>? onOpen;

  @override
  State<_WorkspaceImage> createState() => _WorkspaceImageState();
}

class _WorkspaceImageState extends State<_WorkspaceImage> {
  /// 최근 읽은 그림 — 흐르는 글로 말풍선이 다시 그려질 때 다시 읽어 깜빡이지 않게.
  static final _recent = <String, Uint8List>{};
  static const _recentMax = 8;

  late Future<Uint8List?> _bytes = _load();

  @override
  void didUpdateWidget(_WorkspaceImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _bytes = _load();
  }

  Future<Uint8List?> _load() async {
    final cached = _recent[widget.path];
    if (cached != null) return cached;
    try {
      final bytes = await widget.read(widget.path);
      if (bytes != null) {
        if (_recent.length >= _recentMax) _recent.remove(_recent.keys.first);
        _recent[widget.path] = bytes;
      }
      return bytes;
    } on Object {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      initialData: _recent[widget.path],
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            !snapshot.hasData) {
          return const SizedBox.square(
            dimension: AnswerMarkdown.maxFigureHeight / 2,
            child: AppLoading(delayed: true),
          );
        }
        final bytes = snapshot.data;
        if (bytes == null) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.broken_image_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  l10n.walkChatImageMissing,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
        }
        final open = widget.onOpen;
        return Semantics(
          image: true,
          label: widget.alt,
          button: open != null,
          child: GestureDetector(
            onTap: open == null ? null : () => open(widget.path),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: AnswerMarkdown.maxFigureHeight,
              ),
              child: ClipRRect(
                borderRadius: AppRadius.smAll,
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stack) =>
                      Text(widget.alt, style: theme.textTheme.bodySmall),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
