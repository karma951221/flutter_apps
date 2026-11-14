import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/weather/entity/forecast.dart';
import '../../../domain/weather/rain_summary.dart';
import '../../../domain/weather/weather_problem.dart';
import '../cubit/weather_cubit.dart';
import '../cubit/weather_state.dart';
import '../format/weather_format.dart';
import '../widget/daily_list.dart';
import '../widget/hourly_strip.dart';
import '../widget/rain_summary_card.dart';
import '../widget/weather_details_row.dart';
import '../widget/weather_footer.dart';
import '../widget/weather_now_header.dart';
import '../widget/weather_problem_banner.dart';

/// 날씨 상단 탭 — 지금 → 비 요약 → 시간별 → 일별을 위에서 아래로 훑는다.
///
/// cubit 은 셸 위에 있어(앱이 떠 있는 동안 하나) 여기서는 읽기만 한다.
class WeatherPage extends StatefulWidget {
  const WeatherPage({required this.active, super.key});

  /// 셸에서 이 화면이 보이는지 — 도구 탭 › 날씨가 골라져 있고 셸 위에 다른 라우트가
  /// 얹혀 있지 않을 때. 처음 보일 때와 false → true 로 바뀔 때 cubit 에 알린다
  /// (10분 규칙은 cubit 이 판단한다).
  final bool active;

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _clock = getIt<Clock>();

  /// 당겨서 새로고침 중. 그동안은 위쪽 가는 진행 막대를 겹쳐 그리지 않는다.
  bool _pulling = false;

  WeatherCubit get _cubit => context.read<WeatherCubit>();

  @override
  void initState() {
    super.initState();
    if (widget.active) _cubit.shown();
  }

  @override
  void didUpdateWidget(WeatherPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) _cubit.shown();
  }

  Future<void> _refresh() async {
    setState(() => _pulling = true);
    try {
      await _cubit.refresh();
    } finally {
      if (mounted) setState(() => _pulling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 앱바는 도구 탭이 그린다.
    return Scaffold(
      body: BlocBuilder<WeatherCubit, WeatherState>(
        builder: (context, state) => switch (state) {
          WeatherLoading() => const Center(child: CircularProgressIndicator()),
          WeatherEmpty(:final problem) => _empty(problem),
          final WeatherLoaded loaded => _loaded(loaded),
        },
      ),
    );
  }

  /// 쓸 수 있는 예보가 없다. 당겨서 새로고침이 되도록 스크롤 안에 둔다.
  Widget _empty(WeatherProblem problem) {
    final l10n = AppLocalizations.of(context);
    final (message, description, actionLabel, onAction) = switch (problem) {
      WeatherProblem.locationDenied => (
        l10n.walkWeatherEmptyLocationDenied,
        l10n.walkWeatherEmptyLocationDescription,
        l10n.walkWeatherGrantPermission,
        () => _cubit.resolve(problem),
      ),
      WeatherProblem.locationServiceOff => (
        l10n.walkWeatherEmptyLocationOff,
        l10n.walkWeatherEmptyLocationDescription,
        l10n.walkWeatherTurnOnLocation,
        () => _cubit.resolve(problem),
      ),
      WeatherProblem.locationUnavailable => (
        l10n.walkWeatherEmptyLocationUnavailable,
        null,
        l10n.commonRetry,
        _cubit.refresh,
      ),
      WeatherProblem.offline => (
        l10n.walkWeatherEmptyOffline,
        null,
        l10n.commonRetry,
        _cubit.refresh,
      ),
      WeatherProblem.server => (
        l10n.walkWeatherEmptyServer,
        null,
        l10n.commonRetry,
        _cubit.refresh,
      ),
    };
    return RefreshIndicator(
      onRefresh: _refresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: AppPlaceholder(
                icon: Icons.cloud_off_outlined,
                message: message,
                description: description,
                actionLabel: actionLabel,
                onAction: onAction,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loaded(WeatherLoaded state) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = _clock.now();
    final forecast = state.forecast;
    final today = _today(forecast, now);
    final problem = state.problem;
    final sectionStyle = theme.textTheme.titleSmall;
    return Column(
      children: [
        // 뒤에서 다시 읽는 중(탭 전환 · 복귀). 높이를 늘 잡아 두어 화면이 출렁이지 않게 한다.
        SizedBox(
          height: AppSpacing.xs,
          child: state.refreshing && !_pulling
              ? const LinearProgressIndicator()
              : null,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (problem != null) ...[
                  WeatherProblemBanner(
                    message: WeatherFormat.problem(
                      l10n,
                      problem,
                      stale: state.stale,
                      placeName: state.placeName,
                      fetchedAt: state.fetchedAt,
                      now: now,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                WeatherNowHeader(
                  current: forecast.current,
                  today: today,
                  placeName: state.placeName,
                  lastPlace: switch (problem) {
                    WeatherProblem.locationServiceOff ||
                    WeatherProblem.locationDenied ||
                    WeatherProblem.locationUnavailable => true,
                    _ => false,
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                RainSummaryCard(
                  forecast: forecast,
                  summary: summarizeRain(forecast, now),
                  now: now,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.walkWeatherHourly, style: sectionStyle),
                const SizedBox(height: AppSpacing.sm),
                HourlyStrip(forecast: forecast, now: now),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.walkWeatherDaily, style: sectionStyle),
                const SizedBox(height: AppSpacing.xs),
                DailyList(forecast: forecast, now: now),
                const SizedBox(height: AppSpacing.md),
                WeatherDetailsRow(forecast: forecast, today: today),
                const SizedBox(height: AppSpacing.sm),
                WeatherFooter(forecast: forecast, fetchedAt: state.fetchedAt),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 예보 지역 달력으로 오늘인 일별. 없으면(오래된 캐시 끝자락) null.
  DailyWeather? _today(Forecast forecast, DateTime now) {
    final wall = forecast.wallClock(now);
    for (final day in forecast.daily) {
      final date = forecast.wallClock(day.date);
      if (date.year == wall.year &&
          date.month == wall.month &&
          date.day == wall.day) {
        return day;
      }
    }
    return null;
  }
}
