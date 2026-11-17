import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/transit/transit_failure.dart';
import '../../../domain/transit/usecase/find_transit_routes.dart';
import '../../../domain/transit/usecase/transit_point_suggestions.dart';
import '../../settings/page/transit_settings_page.dart';
import '../cubit/transit_cubit.dart';
import '../cubit/transit_state.dart';
import '../widget/point_fields.dart';
import '../widget/quick_point_chips.dart';
import '../widget/transit_failure_view.dart';
import '../widget/transit_path_tile.dart';
import 'point_picker_page.dart';
import 'transit_path_detail_page.dart';

/// 길찾기 상단 탭 — 출발 · 도착 · 빠른 칩 · 결과 목록. 앱바는 도구 탭이 그린다.
///
/// [TransitCubit] 을 만들고 현재 위치로 출발을 채우기 시작한다. 탭을 넘겨도 상태를 지키려면
/// 도구 탭이 `TabKeepAlive` 로 감싼다.
class TransitPage extends StatelessWidget {
  const TransitPage({super.key});

  /// 길찾기 키 설정 화면을 연다 — 도구 앱바 ⋮ "길찾기 키 설정"(`walkTransitMenuKeySettings`)이 부른다.
  static Future<void> openKeySettings(BuildContext context) => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => const TransitSettingsPage()));

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<TransitCubit>()..start(),
    child: TransitView(suggestions: getIt<TransitPointSuggestions>()),
  );
}

/// [TransitPage] 의 본문. 위쪽 [TransitCubit] 을 읽는다.
class TransitView extends StatefulWidget {
  const TransitView({required this.suggestions, super.key});

  /// 빠른 칩(집 · 회사 · 자주 간 곳)을 읽는다.
  final TransitPointSuggestions suggestions;

  @override
  State<TransitView> createState() => _TransitViewState();
}

class _TransitViewState extends State<TransitView> {
  TransitSuggestions _suggestions = const TransitSuggestions();

  TransitCubit get _cubit => context.read<TransitCubit>();

  @override
  void initState() {
    super.initState();
    unawaited(_loadSuggestions());
  }

  Future<void> _loadSuggestions() async {
    TransitSuggestions loaded;
    try {
      loaded = await widget.suggestions.load();
    } on Object {
      return;
    }
    if (mounted) setState(() => _suggestions = loaded);
  }

  Future<void> _pick({required bool from}) async {
    final state = _cubit.state;
    final point = await PointPickerPage.open(
      context,
      current: from ? state.from : state.to,
    );
    if (!mounted) return;
    // 장소 고르기에서 집 · 회사를 바꿨을 수 있다.
    unawaited(_loadSuggestions());
    if (point == null) return;
    if (from) {
      unawaited(_cubit.setFrom(point));
    } else {
      unawaited(_cubit.setTo(point));
    }
  }

  Future<void> _openKeySettings() async {
    await TransitPage.openKeySettings(context);
    if (mounted) _cubit.refresh();
  }

  void _openPath(int index, TransitRoutesResult result) => unawaited(
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TransitPathDetailPage(path: result.paths[index]),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<TransitCubit, TransitState>(
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                0,
                AppSpacing.xs,
              ),
              child: PointFields(
                from: state.from,
                to: state.to,
                locating: state.locating,
                locationFailed: state.locationFailed,
                onTapFrom: () => _pick(from: true),
                onTapTo: () => _pick(from: false),
                onSwap: _cubit.swap,
              ),
            ),
            QuickPointChips(
              suggestions: _suggestions,
              onSelected: (point) => unawaited(_cubit.fillEmpty(point)),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            Expanded(child: _body(state.status)),
          ],
        ),
      ),
    );
  }

  Widget _body(TransitStatus status) {
    final l10n = AppLocalizations.of(context);
    return switch (status) {
      TransitIdle() => Center(
        child: AppPlaceholder(
          icon: Icons.directions_transit_outlined,
          message: l10n.walkTransitIdle,
          description: l10n.walkTransitIdleBody,
        ),
      ),
      TransitLoading() => const AppLoading(),
      TransitFailed(:final failure) => _failure(failure),
      TransitLoaded(:final result) when result.paths.isEmpty => _failure(
        const TransitFailure.noRoute(),
      ),
      TransitLoaded(:final result) => _results(result),
    };
  }

  Widget _failure(TransitFailure failure) => Center(
    child: SingleChildScrollView(
      child: TransitFailureView(
        failure: failure,
        onOpenKeySettings: () => unawaited(_openKeySettings()),
        onRetry: _cubit.refresh,
      ),
    ),
  );

  Widget _results(TransitRoutesResult result) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final minutes = getIt<Clock>().now().difference(result.fetchedAt).inMinutes;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  minutes < 1
                      ? l10n.walkTransitFetchedJustNow
                      : l10n.walkTransitFetchedAgo(minutes),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              AppButton.text(
                // 앱 테마 버튼은 폭을 가득 채운다(`Size.fromHeight`) — 줄 끝이라 최소 크기만 푼다.
                style: const ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(Size.zero),
                ),
                label: l10n.walkTransitRefresh,
                onPressed: _cubit.refresh,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(l10n.walkTransitNote, style: muted),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var i = 0; i < result.paths.length; i++)
          TransitPathTile(
            path: result.paths[i],
            onTap: () => _openPath(i, result),
          ),
      ],
    );
  }
}
