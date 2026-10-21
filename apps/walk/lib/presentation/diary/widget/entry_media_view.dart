import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:video_player/video_player.dart';

import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/media/media_store.dart';
import '../../theme/walk_theme.dart';

/// 기록의 사진 · 영상 한 장. 사진은 그릴 크기에 맞춰 줄여 읽고(`cacheWidth`),
/// 영상은 썸네일 + 재생 표시만 그린다. 재생은 뷰어의 [VideoSurface] 가 한다.
class EntryMediaView extends StatelessWidget {
  const EntryMediaView({
    required this.media,
    this.fit = BoxFit.cover,
    super.key,
  });

  final EntryMedia media;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final store = getIt<MediaStore>();
    final isVideo = media.kind == MediaKind.video;
    final imagePath = isVideo ? media.thumbPath : media.path;
    final image = imagePath == null
        ? const _Missing()
        : LayoutBuilder(
            builder: (context, constraints) => Image.file(
              store.resolve(imagePath),
              fit: fit,
              width: double.infinity,
              height: double.infinity,
              cacheWidth: _cacheWidth(context, constraints),
              errorBuilder: (_, _, _) => const _Missing(),
            ),
          );
    if (!isVideo) return image;
    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        const Center(child: _PlayBadge()),
      ],
    );
  }

  /// 그릴 너비(물리 픽셀)만큼만 디코딩한다. 너비가 정해지지 않았으면 원본 그대로.
  static int? _cacheWidth(BuildContext context, BoxConstraints constraints) {
    final width = constraints.maxWidth;
    if (!width.isFinite || width <= 0) return null;
    return (width * MediaQuery.devicePixelRatioOf(context)).round();
  }
}

/// 영상 썸네일 위 재생 표시. 밝은 사진 위에서도 보이게 테마와 상관없이 어두운 원에 밝은 ▶ 를 그린다.
class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  static const _scrimAlpha = 0.55;

  @override
  Widget build(BuildContext context) {
    // 어두운 테마의 글자색이 늘 밝다 — 뷰어처럼 어두운 바탕 위 표시라 그 색을 쓴다.
    final onDark = WalkTheme.dark().colorScheme.onSurface;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(
          context,
        ).colorScheme.scrim.withValues(alpha: _scrimAlpha),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(Icons.play_arrow_rounded, color: onDark),
      ),
    );
  }
}

/// 파일이 없거나 읽지 못한 미디어.
class _Missing extends StatelessWidget {
  const _Missing();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 한 기록의 미디어를 좌우로 넘긴다. 두 장 이상이면 `2/3` 처럼 순번을 보인다.
class MediaPager extends StatefulWidget {
  const MediaPager({required this.media, this.fit = BoxFit.cover, super.key});

  final List<EntryMedia> media;
  final BoxFit fit;

  @override
  State<MediaPager> createState() => _MediaPagerState();
}

class _MediaPagerState extends State<MediaPager> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: media.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) => EntryMediaView(
            key: ValueKey(media[i].id),
            media: media[i],
            fit: widget.fit,
          ),
        ),
        if (media.length > 1)
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.inverseSurface,
                borderRadius: AppRadius.smAll,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  AppLocalizations.of(
                    context,
                  ).walkDiaryMediaPosition(_index + 1, media.length),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onInverseSurface,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// `video_player` 로 [file] 을 한 번 재생한다. 트리에서 빠지면 컨트롤러를 버린다.
///
/// [playing] 이 false 면 멈춰 둔다. 준비되면 [onReady] 로 길이를, 끝까지
/// 재생하면 [onEnded] 를 한 번 알린다. 열지 못하거나 길이를 모르면(0) [onFailed] 를 부르고
/// 깨진 그림을 보인다.
class VideoSurface extends StatefulWidget {
  const VideoSurface({
    required this.file,
    this.playing = true,
    this.onReady,
    this.onEnded,
    this.onFailed,
    super.key,
  });

  final File file;
  final bool playing;
  final ValueChanged<Duration>? onReady;
  final VoidCallback? onEnded;
  final VoidCallback? onFailed;

  @override
  State<VideoSurface> createState() => _VideoSurfaceState();
}

class _VideoSurfaceState extends State<VideoSurface> {
  late final _controller = VideoPlayerController.file(widget.file);
  var _ready = false;
  var _failed = false;
  var _ended = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(false);
      if (widget.playing) await _controller.play();
    } on Object {
      if (!mounted) return;
      setState(() => _failed = true);
      widget.onFailed?.call();
      return;
    }
    if (!mounted) return;
    final length = _controller.value.duration;
    if (length <= Duration.zero) {
      // 끝을 알 수 없어 한 번 재생이 멈춰 버린다 — 실패로 다룬다.
      setState(() => _failed = true);
      widget.onFailed?.call();
      return;
    }
    _controller.addListener(_watchEnd);
    setState(() => _ready = true);
    widget.onReady?.call(length);
  }

  /// 끝까지 재생했으면 한 번 알린다.
  void _watchEnd() {
    final value = _controller.value;
    if (_ended) return;
    final atEnd =
        !value.isPlaying &&
        value.duration > Duration.zero &&
        value.position >= value.duration;
    if (value.isCompleted || atEnd) {
      _ended = true;
      widget.onEnded?.call();
    }
  }

  @override
  void didUpdateWidget(VideoSurface old) {
    super.didUpdateWidget(old);
    if (!_ready || old.playing == widget.playing) return;
    if (widget.playing) {
      _controller.play();
    } else {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_watchEnd)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const _Missing();
    if (!_ready) return const Center(child: CircularProgressIndicator());
    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }
}
