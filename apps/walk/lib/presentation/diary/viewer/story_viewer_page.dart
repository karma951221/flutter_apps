import 'dart:async';
import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/entry_filter.dart';
import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../theme/walk_theme.dart';
import '../page/diary_route.dart';
import '../page/entry_actions.dart';
import '../page/story_page.dart';
import 'viewer_model.dart';
import 'viewer_slide_view.dart';

part 'story_viewer_page.freezed.dart';

/// 뷰어가 무엇을 넘겨 보는지.
@freezed
sealed class ViewerSource with _$ViewerSource {
  /// 링 순서의 스토리들 — 가로로 스토리를 넘긴다.
  const factory ViewerSource.stories(List<String> storyIds) = StoriesSource;

  /// 모아보기(태그 · 장소) 그룹 하나. [title] 은 머리에 그대로 쓴다(`#제주`).
  const factory ViewerSource.filter(EntryFilter filter, String title) =
      FilterSource;
}

/// 스토리 뷰어를 페이드로 연다(스펙 §3.2). 일기 잠금에 묶인 화면([pushDiaryRoute])이다.
///
/// [group] 은 [ViewerSource.stories] 의 몇 번째 스토리에서 시작할지, [entryId] 는 그 기록의
/// 첫 조각에서, [fromStart] 면 첫날 첫 조각에서 시작한다.
Future<void> openStoryViewer(
  BuildContext context,
  ViewerSource source, {
  int group = 0,
  String? entryId,
  bool fromStart = false,
  ViewerVideoBuilder videoBuilder = viewerVideoSurface,
}) {
  // 경로가 들고 있어(게이트 바깥) 다시 잠겼다 풀려도 같은 조각에서 이어 간다.
  final resume = ViewerResume();
  return pushDiaryRoute<void>(
    context,
    fade: true,
    page: (_) => StoryViewerPage(
      source: source,
      group: group,
      entryId: entryId,
      fromStart: fromStart,
      videoBuilder: videoBuilder,
      resume: resume,
    ),
  );
}

/// 뷰어가 트리에서 빠졌다(잠김) 다시 만들어질 때 이어 볼 조각.
class ViewerResume {
  String? entryId;
  String? mediaId;
}

/// 조각의 정체 — 데이터가 바뀌어 인덱스가 밀려도 다시 찾는다.
typedef _SlideKey = ({String entry, String? media});

/// 인스타 스토리식 일기 뷰어(스펙 §3.2). 한 페이지 = 한 그룹(스토리)의 하루.
///
/// 조각 길이(사진 5초 · 글 6초 · 영상 자기 길이)만큼 [AnimationController] 를 돌리고 끝나면
/// 다음 조각이다. 길게 누르기 · 글 펼치기 · 위에 화면이 얹힘 · 백그라운드 · 끌기 동안 멈춘다.
class StoryViewerPage extends StatefulWidget {
  const StoryViewerPage({
    required this.source,
    this.group = 0,
    this.entryId,
    this.fromStart = false,
    this.videoBuilder = viewerVideoSurface,
    this.resume,
    super.key,
  });

  final ViewerSource source;
  final int group;
  final String? entryId;
  final bool fromStart;
  final ViewerVideoBuilder videoBuilder;
  final ViewerResume? resume;

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with SingleTickerProviderStateMixin, RouteAware {
  static const _photo = Duration(seconds: 5);
  static const _text = Duration(seconds: 6);

  /// 아래로 이만큼(논리 픽셀) 끌거나 이 속도로 놓으면 닫는다.
  static const _closeDistance = 120.0;
  static const _closeVelocity = 700.0;

  final _repo = getIt<DiaryRepository>();
  late final _progress = AnimationController(vsync: this)
    ..addStatusListener(_onStatus);
  late final AppLifecycleListener _life;
  final _subs = <StreamSubscription<Object?>>[];

  List<Story>? _stories;
  List<DiaryEntry>? _entries;
  List<ViewerGroup> _groups = const [];
  ViewerPos? _pos;
  PageController? _pages;

  /// 지금 조각이 사라지면(휴지통 · 옮김) 갈 곳.
  _SlideKey? _fallback;

  var _holding = false;
  var _covered = false;
  var _background = false;
  var _expanded = false;
  var _dragging = false;
  var _swiping = false;
  var _closing = false;

  /// 처음 데이터가 오기 전에 읽기가 실패했다.
  var _loadFailed = false;

  /// 같은 조각을 처음부터 다시 볼 때마다 늘려 영상 자리를 새로 만든다.
  var _restarts = 0;
  double _dragDy = 0;

  /// 지금 조각 길이를 안다(영상은 준비 전엔 모른다).
  var _timed = false;
  var _videoFailed = false;
  ModalRoute<void>? _route;

  bool get _paused =>
      _holding ||
      _covered ||
      _background ||
      _expanded ||
      _dragging ||
      _swiping ||
      _closing;

  ViewerSlide _slideAt(List<ViewerGroup> g, ViewerPos p) =>
      g[p.group].days[p.day].slides[p.slide];

  _SlideKey _keyAt(List<ViewerGroup> g, ViewerPos p) {
    final s = _slideAt(g, p);
    return (entry: s.entry.id, media: s.media?.id);
  }

  _SlideKey? get _currentKey {
    final pos = _pos;
    return pos == null ? null : _keyAt(_groups, pos);
  }

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(
      onStateChange: (state) =>
          _update(() => _background = state != AppLifecycleState.resumed),
    );
    switch (widget.source) {
      case StoriesSource():
        _subs
          ..add(
            _repo.watchStories().listen((stories) {
              _stories = stories;
              _rebuild();
            }, onError: _onError),
          )
          ..add(
            _repo.watchEntries(const EntryFilter.all()).listen((entries) {
              _entries = entries;
              _rebuild();
            }, onError: _onError),
          );
      case FilterSource(:final filter):
        _subs.add(
          _repo.watchEntries(filter).listen((entries) {
            _entries = entries;
            _rebuild();
          }, onError: _onError),
        );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    // 위에 화면이 얹힌 채 새로 만들어질 수 있다(다시 잠겼다 위 화면에서 풀림) — 릴스와 같다.
    _covered = !(route?.isCurrent ?? true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync();
    });
    if (route == _route) return;
    if (_route != null) appRouteObserver.unsubscribe(this);
    _route = route;
    if (route != null) appRouteObserver.subscribe(this, route);
  }

  @override
  void didPushNext() => _update(() => _covered = true);

  @override
  void didPopNext() => _update(() => _covered = false);

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _life.dispose();
    _progress.dispose();
    _pages?.dispose();
    super.dispose();
  }

  // 데이터

  /// 처음 데이터 전 실패면 오류 안내(닫기 있음)를 보인다. 그 뒤 실패는 마지막 데이터를 그대로 둔다.
  void _onError(Object _) {
    if (!mounted || _pos != null) return;
    _update(() => _loadFailed = true);
  }

  void _rebuild() {
    final entries = _entries;
    if (entries == null || !mounted) return;
    final List<ViewerGroup> all;
    switch (widget.source) {
      case StoriesSource(:final storyIds):
        final stories = _stories;
        if (stories == null) return;
        final byId = {for (final s in stories) s.id: s};
        final byStory = <String, List<DiaryEntry>>{};
        for (final e in entries) {
          (byStory[e.storyId] ??= []).add(e);
        }
        all = [
          for (final id in storyIds)
            if (byId[id] case final story?)
              buildViewerGroup(
                id: id,
                title: story.title,
                story: story,
                entries: byStory[id] ?? const [],
              ),
        ];
      case FilterSource(:final title):
        all = [buildViewerGroup(id: '', title: title, entries: entries)];
    }
    final groups = [
      for (final g in all)
        if (g.days.isNotEmpty) g,
    ];
    if (groups.isEmpty) {
      setState(() => _groups = groups);
      _close();
      return;
    }
    final before = _currentKey;
    final first = _pos == null;
    final pos = first
        ? _initialPos(groups)
        : _find(groups, before) ??
              _find(groups, _fallback) ??
              _clamp(groups, _pos!);
    final groupChanged = !first && pos.group != _pos!.group;
    setState(() {
      _groups = groups;
      _pos = pos;
    });
    if (first) {
      _pages = PageController(initialPage: pos.group);
      _startSlide();
      return;
    }
    if (_keyAt(groups, pos) != before) _startSlide();
    if (groupChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pages = _pages;
        if (mounted && pages != null && pages.hasClients) {
          pages.jumpToPage(pos.group);
        }
      });
    }
  }

  ViewerPos _initialPos(List<ViewerGroup> groups) {
    final resume = widget.resume;
    if (resume?.entryId case final entry?) {
      final found = _find(groups, (entry: entry, media: resume?.mediaId));
      if (found != null) return found;
    }
    var index = 0;
    if (widget.source case StoriesSource(
      :final storyIds,
    ) when storyIds.isNotEmpty) {
      final start = widget.group.clamp(0, storyIds.length - 1);
      // 고른 스토리가 비었으면 줄 뒤쪽 → 앞쪽으로 가장 가까운 것.
      final order = [
        for (var i = start; i < storyIds.length; i++) storyIds[i],
        for (var i = start - 1; i >= 0; i--) storyIds[i],
      ];
      for (final id in order) {
        final i = groups.indexWhere((g) => g.id == id);
        if (i >= 0) {
          index = i;
          break;
        }
      }
    }
    return startPos(
      groups,
      index,
      entryId: widget.entryId,
      fromStart: widget.fromStart,
    )!;
  }

  /// [key] 의 조각, 없으면 그 기록의 첫 조각.
  ViewerPos? _find(List<ViewerGroup> groups, _SlideKey? key) {
    if (key == null) return null;
    ViewerPos? sameEntry;
    for (var g = 0; g < groups.length; g++) {
      final days = groups[g].days;
      for (var d = 0; d < days.length; d++) {
        final slides = days[d].slides;
        for (var s = 0; s < slides.length; s++) {
          if (slides[s].entry.id != key.entry) continue;
          if (slides[s].media?.id == key.media) return ViewerPos(g, d, s);
          sameEntry ??= ViewerPos(g, d, s);
        }
      }
    }
    return sameEntry;
  }

  ViewerPos _clamp(List<ViewerGroup> groups, ViewerPos p) {
    final g = math.min(p.group, groups.length - 1);
    final days = groups[g].days;
    final d = math.min(p.day, days.length - 1);
    final s = math.min(p.slide, days[d].slides.length - 1);
    return ViewerPos(g, d, s);
  }

  // 재생

  void _update(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
    _sync();
  }

  /// 멈춤 조건에 맞춰 막대를 돌리거나 세운다.
  void _sync() {
    if (_timed && !_paused) {
      if (!_progress.isAnimating && _progress.value < 1) {
        unawaited(_progress.forward());
      }
    } else if (_progress.isAnimating) {
      _progress.stop();
    }
  }

  void _startSlide() {
    final pos = _pos;
    if (pos == null) return;
    final slide = _slideAt(_groups, pos);
    _progress
      ..stop()
      ..value = 0;
    _expanded = false;
    _videoFailed = false;
    final media = slide.media;
    if (media != null && media.kind == MediaKind.video) {
      // 준비되면 [_onVideoReady] 가 길이를 정한다.
      _timed = false;
    } else {
      _progress.duration = media == null ? _text : _photo;
      _timed = true;
    }
    widget.resume
      ?..entryId = slide.entry.id
      ..mediaId = slide.media?.id;
    _sync();
  }

  bool get _advanceOnTimer {
    final pos = _pos;
    if (pos == null) return false;
    final media = _slideAt(_groups, pos).media;
    return media == null || media.kind != MediaKind.video || _videoFailed;
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _advanceOnTimer) _next();
  }

  void _onVideoReady(_SlideKey key, Duration length) {
    if (key != _currentKey || _videoFailed) return;
    if (length <= Duration.zero) {
      // 길이를 모르면 끝도 알 수 없다 — 실패처럼 사진 길이 뒤 넘어간다.
      _onVideoFailed(key);
      return;
    }
    _progress.duration = length;
    _timed = true;
    _sync();
  }

  void _onVideoEnded(_SlideKey key) {
    if (key != _currentKey || _videoFailed) return;
    _next();
  }

  void _onVideoFailed(_SlideKey key) {
    if (key != _currentKey) return;
    _update(() {
      _videoFailed = true;
      _progress
        ..stop()
        ..value = 0
        ..duration = _photo;
      _timed = true;
    });
  }

  // 이동

  void _next() {
    final pos = _pos;
    if (pos == null || _closing) return;
    final next = nextPos(_groups, pos);
    if (next == null) {
      _close();
    } else {
      _goTo(next);
    }
  }

  void _prev() {
    final pos = _pos;
    if (pos == null || _closing) return;
    final prev = prevPos(_groups, pos);
    if (prev == pos) {
      // 맨 처음 조각: 처음부터 다시(영상이면 자리를 새로 만들어 되감고 다시 준비를 기다린다).
      setState(() => _restarts++);
      _startSlide();
    } else {
      _goTo(prev);
    }
  }

  void _goTo(ViewerPos p, {bool showPage = true}) {
    final groupChanged = p.group != _pos?.group;
    setState(() {
      _pos = p;
      _fallback = null;
    });
    _startSlide();
    if (!groupChanged || !showPage) return;
    final pages = _pages;
    if (pages == null || !pages.hasClients) return;
    if (AppMotion.enabled(context)) {
      unawaited(
        pages.animateToPage(
          p.group,
          duration: AppMotion.medium,
          curve: AppMotion.standard,
        ),
      );
    } else {
      pages.jumpToPage(p.group);
    }
  }

  void _onPageChanged(int index) {
    final pos = _pos;
    // 넘김이 코드에서 온 것(다음 조각이 다음 스토리)이면 이미 그 자리다.
    if (pos == null || index == pos.group) return;
    final start = startPos(_groups, index);
    if (start != null) _goTo(start, showPage: false);
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    _progress.stop();
    final route = _route;
    if (route == null) return;
    final navigator = Navigator.of(context);
    if (route.isCurrent) {
      navigator.pop();
    } else if (route.isActive) {
      // 위에 화면이 얹혀 있으면 그 화면을 닫지 않고 뷰어만 뺀다.
      navigator.removeRoute(route);
    }
  }

  /// 지금 기록이 아닌 첫 다음 조각(같은 기록의 다른 미디어는 건너뛴다).
  ViewerPos? _nextOutside(String entryId) {
    var p = _pos;
    while (p != null) {
      p = nextPos(_groups, p);
      if (p != null && _slideAt(_groups, p).entry.id != entryId) return p;
    }
    return null;
  }

  Future<void> _onAction(ViewerEntryAction action) async {
    final pos = _pos;
    if (pos == null) return;
    final entry = _slideAt(_groups, pos).entry;
    final next = _nextOutside(entry.id);
    _fallback = next == null ? null : _keyAt(_groups, next);
    switch (action) {
      case ViewerEntryAction.edit:
        await editEntry(context, entry);
      case ViewerEntryAction.move:
        await moveEntry(context, entry);
      case ViewerEntryAction.trash:
        final trashed = await trashEntry(context, entry, confirm: false);
        if (!trashed || !mounted) return;
        if (next == null) {
          _close();
          return;
        }
        // 목록이 아직 갱신되지 않았으면 직접 넘어간다(갱신되면 같은 조각을 다시 찾는다).
        if (_currentKey?.entry == entry.id) {
          final target = _find(_groups, _fallback);
          if (target != null) _goTo(target);
        }
    }
  }

  // 그리기

  @override
  Widget build(BuildContext context) => Theme(
    data: WalkTheme.dark(),
    child: Builder(
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        final pos = _pos;
        return Scaffold(
          backgroundColor: colors.surfaceContainerLowest,
          body: _loadFailed
              ? _failure(context)
              : pos == null || _groups.isEmpty
              ? const SizedBox.expand()
              : GestureDetector(
                  onVerticalDragStart: (_) => _update(() => _dragging = true),
                  onVerticalDragUpdate: (d) => setState(
                    () => _dragDy = math.max(0, _dragDy + d.delta.dy),
                  ),
                  onVerticalDragEnd: (d) {
                    final velocity = d.primaryVelocity ?? 0;
                    if (_dragDy > _closeDistance || velocity > _closeVelocity) {
                      _close();
                    } else {
                      _update(() {
                        _dragging = false;
                        _dragDy = 0;
                      });
                    }
                  },
                  onVerticalDragCancel: () => _update(() {
                    _dragging = false;
                    _dragDy = 0;
                  }),
                  child: Transform.translate(
                    offset: Offset(0, _dragDy),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _onScroll,
                      child: PageView.builder(
                        controller: _pages,
                        itemCount: _groups.length,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, i) => i == pos.group
                            ? _current(context, pos)
                            : _preview(i),
                      ),
                    ),
                  ),
                ),
        );
      },
    ),
  );

  /// 처음 읽기 실패: 머리가 없으니 닫기를 따로 둔다.
  Widget _failure(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Stack(
        children: [
          AppPlaceholder(
            icon: Icons.error_outline,
            message: l10n.walkDiaryLoadError,
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.walkDiaryViewerClose,
              onPressed: _close,
            ),
          ),
        ],
      ),
    );
  }

  bool _onScroll(ScrollNotification n) {
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _update(() => _swiping = true);
    } else if (n is ScrollEndNotification && _swiping) {
      _update(() => _swiping = false);
    }
    return false;
  }

  /// 옆 그룹: 그 시작 조각만 멈춰 그린다.
  Widget _preview(int group) {
    final start = startPos(_groups, group);
    if (start == null) return const SizedBox.shrink();
    return ViewerSlideView(
      slide: _slideAt(_groups, start),
      active: false,
      video: (_) => throw StateError('옆 그룹은 영상을 재생하지 않는다'),
    );
  }

  Widget _current(BuildContext context, ViewerPos pos) {
    final group = _groups[pos.group];
    final day = group.days[pos.day];
    final slide = day.slides[pos.slide];
    final key = (entry: slide.entry.id, media: slide.media?.id);
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => d.localPosition.dx < constraints.maxWidth / 3
                ? _prev()
                : _next(),
            onLongPressStart: (_) => _update(() => _holding = true),
            onLongPressEnd: (_) => _update(() => _holding = false),
            onLongPressCancel: () => _update(() => _holding = false),
            child: ViewerSlideView(
              key: ValueKey((key, _restarts)),
              slide: slide,
              active: true,
              videoBuilder: widget.videoBuilder,
              video: (file) => ViewerVideo(
                file: file,
                playing: !_paused,
                onReady: (length) => _onVideoReady(key, length),
                onEnded: () => _onVideoEnded(key),
                onFailed: () => _onVideoFailed(key),
              ),
            ),
          ),
          if (!_holding) ...[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ViewerHeader(
                group: group,
                day: day,
                index: pos.slide,
                progress: _progress,
                icon: switch (widget.source) {
                  FilterSource(filter: PlaceEntries()) => Icons.place_outlined,
                  FilterSource() => Icons.tag,
                  StoriesSource() => null,
                },
                onAction: _onAction,
                onClose: _close,
                onTitleTap: switch (group.story) {
                  final story? => () => openStoryPage(context, story.id),
                  null => null,
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ViewerCaption(
                slide: slide,
                expanded: _expanded,
                onToggle: () => _update(() => _expanded = !_expanded),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
