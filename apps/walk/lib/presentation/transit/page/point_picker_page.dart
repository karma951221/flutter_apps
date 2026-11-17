import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/commute/entity/place.dart';
import '../../../domain/diary/location/place_source.dart';
import '../../../domain/transit/entity/station_hit.dart';
import '../../../domain/transit/entity/transit_point.dart';
import '../../../domain/transit/usecase/transit_point_suggestions.dart';
import '../cubit/point_picker_cubit.dart';
import '../open_transit_key_settings.dart';
import '../cubit/point_picker_state.dart';
import '../widget/point_fields.dart';
import '../widget/transit_failure_view.dart';

/// 장소 고르기(전체 화면). 고른 지점을 돌려주며 닫힌다. 그냥 닫으면 null.
class PointPickerPage extends StatelessWidget {
  const PointPickerPage({this.current, super.key});

  /// 지금 그 칸에 들어 있는 지점 — 집 · 회사를 길게 눌러 저장할 때 쓴다.
  final TransitPoint? current;

  static Future<TransitPoint?> open(
    BuildContext context, {
    TransitPoint? current,
  }) => Navigator.of(context).push<TransitPoint>(
    MaterialPageRoute(builder: (_) => PointPickerPage(current: current)),
  );

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<PointPickerCubit>()..load(),
    child: PointPickerView(
      suggestions: getIt<TransitPointSuggestions>(),
      current: current,
      locate: _locate,
    ),
  );

  static Future<TransitPoint?> _locate() async {
    final loc = await getIt<PlaceSource>().current();
    final lat = loc?.lat;
    final lng = loc?.lng;
    if (lat == null || lng == null) return null;
    return TransitPoint(
      lat: lat,
      lng: lng,
      label: loc?.placeName ?? '',
      source: TransitPointSource.currentLocation,
    );
  }
}

/// [PointPickerPage] 의 본문. 위쪽 [PointPickerCubit] 을 읽는다.
///
/// 검색어가 비면 후보(현재 위치 · 집 · 회사 · 자주 간 곳 · 최근), 검색어가 있으면 역 · 정류장
/// 결과와 "주소로 찾기" 줄을 보인다.
class PointPickerView extends StatefulWidget {
  const PointPickerView({
    required this.suggestions,
    required this.locate,
    this.current,
    super.key,
  });

  /// 집 · 회사 저장에 쓴다.
  final TransitPointSuggestions suggestions;

  /// 현재 위치를 얻는다. 못 얻으면 null.
  final Future<TransitPoint?> Function() locate;

  final TransitPoint? current;

  @override
  State<PointPickerView> createState() => _PointPickerViewState();
}

class _PointPickerViewState extends State<PointPickerView> {
  final _controller = TextEditingController();

  /// 마지막으로 cubit 에 알린 입력 — 커서만 움직였을 때는 다시 알리지 않는다.
  ({String text, bool composing}) _last = (text: '', composing: false);

  bool _locating = false;

  PointPickerCubit get _cubit => context.read<PointPickerCubit>();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// IME 조합이 끝나면 글자는 같아도 조합 여부가 바뀌므로 그때 검색이 시작된다.
  void _onChanged() {
    final value = _controller.value;
    final next = (text: value.text, composing: value.isComposingRangeValid);
    if (next == _last) return;
    _last = next;
    _cubit.queryChanged(next.text, composing: next.composing);
  }

  void _done(TransitPoint point) => Navigator.of(context).pop(point);

  Future<void> _pickCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    TransitPoint? point;
    try {
      point = await widget.locate();
    } on Object {
      point = null;
    }
    if (!mounted) return;
    setState(() => _locating = false);
    if (point == null) {
      AppSnackBar.warning(
        context,
        message: AppLocalizations.of(context).walkTransitLocateFailed,
      );
      return;
    }
    _done(point);
  }

  /// 지금 그 칸의 지점을 집 · 회사로 저장한다.
  Future<void> _saveAs(PlaceKind kind) async {
    final l10n = AppLocalizations.of(context);
    final current = widget.current;
    if (current == null) {
      AppSnackBar.info(context, message: l10n.walkTransitSaveNothing);
      return;
    }
    // 현재 위치는 이름이 없을 수 있다 — 얻어 둔 장소 이름, 없으면 "현재 위치"로 저장한다.
    final toSave =
        current.source == TransitPointSource.currentLocation &&
            current.label.trim().isEmpty
        ? current.copyWith(label: l10n.walkTransitCurrentLocation)
        : current;
    try {
      await widget.suggestions.saveAs(kind, toSave);
    } on Object {
      if (mounted) {
        AppSnackBar.error(context, message: l10n.walkTransitSaveFailed);
      }
      return;
    }
    if (!mounted) return;
    unawaited(_cubit.load());
    AppSnackBar.success(
      context,
      message: kind == PlaceKind.home
          ? l10n.walkTransitSavedHome
          : l10n.walkTransitSavedWork,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration.collapsed(
            hintText: l10n.walkTransitSearchHint,
          ),
          onSubmitted: _cubit.submitted,
        ),
      ),
      body: BlocBuilder<PointPickerCubit, PointPickerState>(
        builder: (context, state) => ListView(
          children: state.query.trim().isEmpty
              ? _suggestionRows(state)
              : _resultRows(state),
        ),
      ),
    );
  }

  List<Widget> _suggestionRows(PointPickerState state) {
    final l10n = AppLocalizations.of(context);
    final suggestions = state.suggestions;
    final home = suggestions?.home;
    final work = suggestions?.work;
    final frequent = suggestions?.frequent ?? const <TransitPoint>[];
    final recent = suggestions?.recent ?? const <TransitPoint>[];
    return [
      AppListTile(
        leading: const Icon(Icons.my_location),
        title: Text(l10n.walkTransitCurrentLocation),
        trailing: _locating ? const _SmallProgress() : null,
        onTap: () => unawaited(_pickCurrentLocation()),
      ),
      _SavedPlaceTile(
        icon: Icons.home_outlined,
        name: l10n.walkTransitHome,
        unsetLabel: l10n.walkTransitSetHome,
        point: home,
        onPick: _done,
        onSave: () => unawaited(_saveAs(PlaceKind.home)),
      ),
      _SavedPlaceTile(
        icon: Icons.work_outline,
        name: l10n.walkTransitWork,
        unsetLabel: l10n.walkTransitSetWork,
        point: work,
        onPick: _done,
        onSave: () => unawaited(_saveAs(PlaceKind.work)),
      ),
      if (frequent.isNotEmpty) ...[
        _SectionHeader(l10n.walkTransitFrequent),
        for (final p in frequent) _pointTile(Icons.star_outline, p),
      ],
      if (recent.isNotEmpty) ...[
        _SectionHeader(l10n.walkTransitRecent),
        for (final p in recent) _pointTile(Icons.history, p),
      ],
    ];
  }

  Widget _pointTile(IconData icon, TransitPoint point) => AppListTile(
    leading: Icon(icon),
    title: Text(transitPointLabel(AppLocalizations.of(context), point)),
    onTap: () => _done(point),
  );

  List<Widget> _resultRows(PointPickerState state) {
    final l10n = AppLocalizations.of(context);
    final failure = state.stationFailure;
    return [
      _SectionHeader(l10n.walkTransitResults),
      if (state.searching) const LinearProgressIndicator(),
      if (failure != null)
        TransitFailureView(
          failure: failure,
          onOpenKeySettings: () => unawaited(openTransitKeySettings(context)),
          onRetry: () => _cubit.queryChanged(state.query),
        ),
      for (final hit in state.stations)
        AppListTile(
          leading: Icon(
            hit.kind == StationKind.subway
                ? Icons.subway_outlined
                : Icons.directions_bus_outlined,
          ),
          title: Text(hit.name),
          subtitle: hit.detail.isEmpty ? null : Text(hit.detail),
          onTap: () => _done(
            TransitPoint(
              lat: hit.lat,
              lng: hit.lng,
              label: hit.name,
              source: TransitPointSource.station,
            ),
          ),
        ),
      for (final address in state.addresses)
        AppListTile(
          leading: const Icon(Icons.place_outlined),
          title: Text(address.label),
          onTap: () => _done(
            TransitPoint(
              lat: address.lat,
              lng: address.lng,
              label: address.label,
              source: TransitPointSource.address,
            ),
          ),
        ),
      if (state.addresses.isEmpty)
        AppListTile(
          leading: const Icon(Icons.search),
          title: Text(l10n.walkTransitFindAddress(state.query.trim())),
          trailing: state.addressSearching ? const _SmallProgress() : null,
          onTap: state.addressSearching
              ? null
              : () => unawaited(_cubit.searchAddress()),
        ),
    ];
  }
}

/// 집 · 회사 행. 정해 두었으면 눌러 고르고, 길게 누르면 지금 고른 곳으로 저장한다.
/// 정해 두지 않았으면 "집 정하기" — 눌러도 길게 눌러도 저장한다.
class _SavedPlaceTile extends StatelessWidget {
  const _SavedPlaceTile({
    required this.icon,
    required this.name,
    required this.unsetLabel,
    required this.point,
    required this.onPick,
    required this.onSave,
  });

  final IconData icon;
  final String name;
  final String unsetLabel;
  final TransitPoint? point;
  final ValueChanged<TransitPoint> onPick;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final point = this.point;
    final label = point?.label.trim() ?? '';
    // AppListTile 에는 길게 누르기가 없어 감싼다 — 짧게 누르기는 안쪽 InkWell 이 받는다.
    return GestureDetector(
      onLongPress: onSave,
      child: AppListTile(
        leading: Icon(icon),
        title: Text(point == null ? unsetLabel : name),
        subtitle: Text(
          point == null || label.isEmpty ? l10n.walkTransitSaveHint : label,
        ),
        onTap: point == null ? onSave : () => onPick(point),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// 행 끝의 작은 진행 표시.
class _SmallProgress extends StatelessWidget {
  const _SmallProgress();

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: Theme.of(context).iconTheme.size ?? AppSpacing.lg,
    child: const CircularProgressIndicator(strokeWidth: 2),
  );
}
