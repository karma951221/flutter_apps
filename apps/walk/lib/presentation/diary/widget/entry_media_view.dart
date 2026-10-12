import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:video_player/video_player.dart';

import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/media/media_store.dart';

/// 재생 중인 영상 자리. 테스트는 `video_player` 대신 가짜 위젯을 넣는다.
typedef VideoSurfaceBuilder = Widget Function(BuildContext context, File file);

/// 기본 영상 자리 — [VideoSurface].
Widget videoSurface(BuildContext context, File file) =>
    VideoSurface(file: file);

/// 기록의 사진 · 영상 한 장. 사진은 그릴 크기에 맞춰 줄여 읽고(`cacheWidth`),
/// 영상은 [play] 일 때만 [videoBuilder] 로 재생하고 아니면 썸네일 + 재생 표시.
///
/// [play] 가 false 로 바뀌면 영상 자리가 트리에서 빠져 컨트롤러가 버려진다.
class EntryMediaView extends StatelessWidget {
  const EntryMediaView({
    required this.media,
    this.play = false,
    this.fit = BoxFit.cover,
    this.videoBuilder = videoSurface,
    super.key,
  });

  final EntryMedia media;
  final bool play;
  final BoxFit fit;
  final VideoSurfaceBuilder videoBuilder;

  @override
  Widget build(BuildContext context) {
    final store = getIt<MediaStore>();
    final isVideo = media.kind == MediaKind.video;
    if (isVideo && play) {
      return videoBuilder(context, store.resolve(media.path));
    }
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
        Center(
          child: Icon(
            Icons.play_circle_outline,
            color: Theme.of(context).colorScheme.onInverseSurface,
          ),
        ),
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
/// [playing] 이면 지금 보이는 장의 영상만 재생한다.
class MediaPager extends StatefulWidget {
  const MediaPager({
    required this.media,
    this.playing = false,
    this.fit = BoxFit.cover,
    this.videoBuilder = videoSurface,
    super.key,
  });

  final List<EntryMedia> media;
  final bool playing;
  final BoxFit fit;
  final VideoSurfaceBuilder videoBuilder;

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
            play: widget.playing && i == _index,
            fit: widget.fit,
            videoBuilder: widget.videoBuilder,
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

/// `video_player` 로 [file] 을 반복 재생한다. 트리에서 빠지면 컨트롤러를 버린다.
class VideoSurface extends StatefulWidget {
  const VideoSurface({required this.file, super.key});

  final File file;

  @override
  State<VideoSurface> createState() => _VideoSurfaceState();
}

class _VideoSurfaceState extends State<VideoSurface> {
  late final _controller = VideoPlayerController.file(widget.file);
  var _ready = false;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.play();
    } on Object {
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _controller.dispose();
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
